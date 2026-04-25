# Employee invitation flow — design spec

**Date :** 2026-04-24
**Branche cible :** `feat/owner-employee-ui` (mobile) + nouvelle branche backend
**Repos concernés :** `hairspot_mobile` (Flutter) + `Lagedi/backend` (Laravel)

## 1. Contexte & problème

Aujourd'hui, le flow d'ajout d'employé sur une company de type individuelle a deux failles :

1. `POST /my-company/employees/create` exige un mot de passe que le owner tape lui-même. L'employé ne reçoit jamais ce mot de passe → il ne peut pas se connecter. Et comme l'email est `unique:users,email`, il ne peut pas non plus créer son compte plus tard avec sa propre inscription (« email déjà utilisé »).
2. Aucune notion d'acceptation : `inviteEmployee` (pour user existant) crée immédiatement le pivot `company_user.is_active = true`. L'employé est ajouté sans son consentement.

**Objectif :** introduire un système d'invitation propre avec états (pending / accepted / refused / expired / revoked), notifications cross-repo, et un flow de signup-via-lien sécurisé qui auto-vérifie l'email sans introduire de paramètre client falsifiable.

## 2. Décisions architecturales

### 2.1 Approche choisie : table `employee_invitations` séparée

L'invitation est un objet de 1ère classe, distinct de `users` et `company_user`.

- **Pas de stub User** créé à l'invitation. Le `User` n'apparaît qu'au moment d'un signup réel (via le lien ou en signup classique).
- Le pivot `company_user` n'apparaît qu'à l'acceptation effective.
- Avantages : zéro pollution dans `users`, aucun edge case `unique:users,email` à contourner, l'invitation est traçable et expirable indépendamment.

### 2.2 Token

- Format : 32 octets random URL-safe base64 (`Str::random(43)`).
- Stockage : seulement le hash SHA-256 en DB (`token_hash`). Le plaintext n'est dans l'URL email qu'une seule fois.
- Lookup : par `token_hash`, comparaison constant-time.
- Durée de vie : **7 jours**.
- Single-use : oui, `accepted` / `refused` / `expired` / `revoked` invalident le token.
- Throttle anti-bruteforce : `60/min` par IP sur `/api/invitations/{token}`.

### 2.3 Politique de réinvitation

- Ré-inviter un email **pending** : régénère le token, reset `expires_at`, renvoie l'email/notif. L'ancien token devient invalide. Throttle : 3 resends/heure par invitation.
- Ré-inviter un email **refused** ou **expired** : crée une nouvelle ligne `employee_invitations` (l'historique est conservé).
- Ré-inviter un email déjà membre confirmé : 422 « déjà membre ».

### 2.4 Sécurité de l'auto-vérification email

L'auto-vérification de `email_verified_at` est **dérivée du token**, jamais d'un paramètre client.

```
POST /api/auth/register { email, password, …, invitation_token? }

if invitation_token présent:
    inv = lookup par sha256(invitation_token)
    if !inv || inv.status != 'pending' || inv.expires_at < now() → 410
    if inv.email != lower(input.email) → 422
    → email_verified_at = now()    // dérivé du token, pas du client
    → register continue normalement
    → après création : auto-accept atomique de l'invite
else:
    flow OTP classique
```

Un attaquant ne peut pas valider un email arbitraire : il faudrait un token valide (256 bits d'entropie) ET correspondant à l'email cible.

### 2.5 Scope

- **Companies type individuelle (`booking_mode = employee_based`)** principalement, mais le modèle de données et les endpoints sont indépendants du booking_mode — le système marche aussi pour `capacity_based` sans changement.
- **Aucune migration de données existantes :** les pivots `company_user` actuels ne sont pas touchés (ils sont implicitement `confirmed` puisque `is_active=true`).

## 3. Modèle de données

### 3.1 Nouvelle table `employee_invitations`

```sql
CREATE TABLE employee_invitations (
    id                  BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    company_id          BIGINT UNSIGNED NOT NULL,
    invited_by_user_id  BIGINT UNSIGNED NOT NULL,
    email               VARCHAR(255) NOT NULL,           -- toujours lower()
    first_name          VARCHAR(100) NULL,
    last_name           VARCHAR(100) NULL,
    specialties         JSON NOT NULL DEFAULT ('[]'),
    role                ENUM('employee','owner') NOT NULL DEFAULT 'employee',
    token_hash          CHAR(64) NOT NULL,
    status              ENUM('pending','accepted','refused','expired','revoked')
                        NOT NULL DEFAULT 'pending',
    expires_at          TIMESTAMP NOT NULL,
    accepted_at         TIMESTAMP NULL,
    refused_at          TIMESTAMP NULL,
    resulting_user_id   BIGINT UNSIGNED NULL,
    created_at          TIMESTAMP NULL,
    updated_at          TIMESTAMP NULL,

    CONSTRAINT fk_invitations_company FOREIGN KEY (company_id)
        REFERENCES companies(id) ON DELETE CASCADE,
    CONSTRAINT fk_invitations_owner FOREIGN KEY (invited_by_user_id)
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_invitations_user FOREIGN KEY (resulting_user_id)
        REFERENCES users(id) ON DELETE SET NULL,

    INDEX idx_token_hash (token_hash),
    INDEX idx_email_status (email, status),
    INDEX idx_company_status (company_id, status)
);

-- Note : MySQL ne supporte pas les index partiels. L'unicité « une seule
-- pending par (company, email) » est enforcée côté application dans une
-- transaction (SELECT … FOR UPDATE puis check + insert). Un index non-unique
-- sur (company_id, email, status) accélère le check.
CREATE INDEX idx_company_email_status
    ON employee_invitations (company_id, email, status);
```

### 3.2 Aucune modification de `users` ni `company_user`

- `company_user.is_active` reste utilisé pour la désactivation post-acceptation (déjà en place).
- Nouveau pivot créé à l'acceptation avec `is_active=true`.

## 4. Contrat API

### 4.1 Owner-side (préfixe `/api/my-company`, middleware `auth:sanctum` + ownsCompany)

| Méthode | Route | Description |
|---|---|---|
| `POST` | `/employees/invite` | **Modifié.** Crée une `employee_invitations`. Body : `email` (req), `first_name`, `last_name`, `specialties`, `role`. Si user existe → push + in-app inbox. Si user n'existe pas → email avec lien. Réponse 201 avec la ressource invitation. |
| `POST` | `/employees/invitations/{id}/resend` | Régénère token + reset `expires_at`. Throttle `3,60`. Renvoie l'email/notif. |
| `DELETE` | `/employees/invitations/{id}` | Révoque (status → `revoked`). |
| `GET` | `/employees` | **Modifié.** Renvoie un payload mixte : `[{ kind:'member', …pivot }, { kind:'invitation', status, expiresAt, … }]`. Par défaut exclut `refused`/`expired`/`revoked`. Query param `?include=history` pour le journal. |
| `POST` | `/employees/create` | **SUPPRIMÉ.** Toute création d'employé passe désormais par invite. |

### 4.2 Public/auth-side

| Méthode | Route | Auth | Description |
|---|---|---|---|
| `GET` | `/api/invitations/{token}` | non | Lookup par token plaintext. Renvoie `{ companyName, ownerName, email, firstName, lastName, expiresAt }` ou 404/410. Throttle 60/min/IP. |
| `POST` | `/api/auth/register` | non | **Modifié.** Champ optionnel `invitation_token`. Si présent et valide : email forcé, `email_verified_at=now()`, auto-acceptation atomique. |
| `GET` | `/api/me/invitations` | sanctum | Liste les invitations `pending` matchant l'email du user authentifié. |
| `POST` | `/api/me/invitations/{id}/accept` | sanctum | Crée le pivot `company_user(is_active=true)`, marque `accepted`, notifie owner. Idempotent. |
| `POST` | `/api/me/invitations/{id}/refuse` | sanctum | Marque `refused`, notifie owner. |

### 4.3 Forme JSON

**Invitation côté owner** (`InvitationResource`) :
```json
{
  "id": 42,
  "kind": "invitation",
  "email": "alice@example.com",
  "firstName": "Alice",
  "lastName": "Martin",
  "specialties": ["coloriste"],
  "role": "employee",
  "status": "pending",
  "expiresAt": "2026-05-01T10:00:00Z",
  "createdAt": "2026-04-24T10:00:00Z",
  "hasAccount": false
}
```

**Member côté owner** (`EmployeeResource` actuel) — on ajoute `"kind": "member"`.

**Invitation côté invité** (`MyInvitationResource`) :
```json
{
  "id": 42,
  "company": {
    "id": 17,
    "name": "Salon X",
    "city": "Prishtinë",
    "logoUrl": "..."
  },
  "invitedBy": { "firstName": "Bob", "lastName": "Owner" },
  "role": "employee",
  "expiresAt": "2026-05-01T10:00:00Z"
}
```

## 5. Flux Flutter

### 5.1 Flow 1 — Owner crée un compte pour un employé sans compte

1. Owner ouvre dialog « Inviter un employé » sur `CompanyDashboardScreen`.
2. Toggle/segment `Avec lien d'inscription` activé.
3. Champs : email (req), prénom, nom, spécialités (optionnels).
4. Submit → `POST /my-company/employees/invite` avec `first_name + last_name`.
5. La carte « En attente » apparaît dans la liste avec « Lien envoyé · expire dans 7j 0h ».
6. Email reçu côté employé → CTA `Créer mon compte` → deep link `terminim://invite/{token}` (web fallback `https://terminim.com/invite/{token}` qui propose ouverture app/install).
7. App ouvre `SignupScreen` en mode invitation :
   - Email **désactivé**, pré-rempli depuis `GET /api/invitations/{token}`.
   - Prénom/nom **pré-remplis mais éditables**.
   - Pas de step OTP (email auto-vérifié).
8. Submit → `POST /api/auth/register` avec `invitation_token` → compte créé + login auto + redirigé vers home. Le pivot `company_user` est `confirmed`.

### 5.2 Flow 2 — Owner invite un email existant

1. Owner toggle `Sans lien d'inscription` (ou laisse les champs nom vides).
2. Submit → `POST /my-company/employees/invite` avec juste `email`.
3. Si l'email matche un user existant : push « X t'invite à rejoindre Y » + entrée dans la notif inbox. L'invitation est dans `/me/invitations`.
4. À la prochaine ouverture de l'app : bannière dorée non-dismissible en haut de `HomeScreen` → « Tu as été invité chez Y · Voir ».
5. Tap → modal avec : logo + nom du salon, owner, ville, message « Tu rejoindrais en tant qu'employé », boutons `Refuser` / `Accepter`.
6. Accept/refuse → POST → notif owner.

### 5.3 Flow 3 — User s'inscrit normalement avec un email qui a une invitation pending

1. Le signup classique réussit (pas de blocage : aucune ligne `users` n'a été créée par l'invitation).
2. Après le signup, `GET /me/invitations` est appelé → renvoie les pending matchant l'email.
3. Bannière + modal identiques au Flow 2.

### 5.4 Bannière

- Composant partagé `<PendingInvitationBanner />`.
- Visible **uniquement** sur `HomeScreen` (pas globalement).
- Re-poll au pull-to-refresh + au foreground resume.
- Affiche le 1er pending si plusieurs ; tap → modal qui les liste tous.

## 6. UI « Mon salon » — affichage

Sur `CompanyDashboardScreen` (mobile + desktop), section employés :

**Confirmés** (lus depuis `company_user` filtrés par `kind:'member'`) : carte employé classique (avatar, nom, rôle, spécialités), swipe pour edit/delete.

**Pending** (lus depuis `employee_invitations`) :
- Avatar placeholder (initiales prénom/nom ou enveloppe si pas de nom).
- Nom (ou email seul si pas de nom fourni).
- Badge `En attente` (couleur `or`).
- Sous-texte : **« Expire dans Xj Yh »** (countdown live recalculé à l'ouverture).
- Actions : `Renvoyer` (resend) | `Annuler` (revoke).

**Refusés / expirés / révoqués** : **non affichés** sur la liste principale. Un bouton « Voir l'historique » ouvre une feuille modale (lit `?include=history`) qui liste statut + horodatage.

## 7. Notifications

| Évènement | Email | Push + in-app inbox | Destinataire |
|---|---|---|---|
| Invitation envoyée — Flow 1 (no account) | ✅ obligatoire | — | invité (par email) |
| Invitation envoyée — Flow 2 (account existant) | ❌ | ✅ | invité (par user_id) |
| Acceptation | ❌ | ✅ | owner |
| Refus | ❌ | ✅ | owner |
| Expiration (job nightly) | ❌ | ✅ | owner |

**Templates email** : `EmployeeInvitationLinkMail` (FR/EN/SQ), CTA `Créer mon compte`, palette + signature de marque comme les autres mails Termini im.

**Évènements push** (utilise le système FCM existant) :
- `employee.invitation.received`
- `employee.invitation.accepted`
- `employee.invitation.refused`
- `employee.invitation.expired`

## 8. Job nightly d'expiration

Un command `php artisan invitations:expire` (planifié `daily()` dans `routes/console.php`) :
- Cherche les `pending WHERE expires_at < now()`.
- Passe à `expired`.
- Dispatch une notif owner par invitation.

## 9. Tests

### 9.1 Backend (Pest/PHPUnit)

- Owner peut inviter un email inconnu → invitation créée, mail dispatched.
- Owner peut inviter un email existant → invitation créée, push dispatched (mail NON dispatched).
- 2e invite sur un email pending régénère le token (l'ancien devient invalide).
- Lookup d'un token expiré → 410.
- `register` avec `invitation_token` valide → user créé, `email_verified_at != null`, pivot créé `is_active=true`, invitation `accepted`.
- `register` avec `invitation_token` valide mais email mismatch → 422.
- `register` avec `invitation_token` invalide/expiré → 410.
- `register` sans `invitation_token` sur un email avec pending → succès, invitation reste `pending`, accessible via `/me/invitations`.
- Refus puis nouvelle invite → nouvelle ligne (l'ancienne reste `refused`).
- Job nightly : pending dont `expires_at < now()` → `expired` + notif owner.
- Owner invite son propre email → 422.
- Owner invite un email déjà membre confirmé → 422.
- Accept idempotent (double-tap = pas de double pivot).
- Throttle resend 3/h respecté.
- Throttle lookup token 60/min/IP respecté.

### 9.2 Flutter (widget tests + intégration)

- `SignupScreen` en mode invitation : email désactivé, OTP step skipped.
- `<PendingInvitationBanner />` visible quand `/me/invitations` non vide, masqué sinon.
- Modal accept/refuse appelle les bons endpoints, ferme et rafraîchit la liste.
- `CompanyDashboardScreen` affiche les invitations pending avec countdown.
- Resend/revoke depuis la carte pending appelle les bons endpoints + rafraîchit.

## 10. Out of scope (à traiter séparément)

- Migration des employés actuellement créés sans password (data migration manuelle ou script ad-hoc).
- Liens d'invitation web standalone (la page web `/invite/{token}` est juste un splash qui pousse vers l'app/store).
- Multi-langue de l'email beyond FR/EN/SQ (déjà couvert par le système de locales existant).
- Paramètre `role=owner` réellement utilisé (cas hypothétique de transfert d'ownership — pas demandé).

## 11. Plan de release

1. Backend PR sur Lagedi : migration, modèle, endpoints, tests, mail template, job. Mergé en premier.
2. Mobile PR sur hairspot_mobile : refactor `CompanyDashboardScreen`, dialog d'invite revu, bannière, modal, signup mode invitation, deep link handler. Mergé après backend déployé en staging.
3. Suppression du flow legacy `/employees/create` côté mobile dans la même PR mobile.
4. Migration manuelle (script artisan one-shot) pour supprimer les comptes legacy sans password si besoin — décidé après revue par owner.
