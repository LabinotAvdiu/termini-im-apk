# Contrat Planning — Backend → Frontend

> **Règle directrice** : le backend décide **quoi afficher** et **quelles actions sont permises**. Le frontend **affiche** et rien d'autre — pas de `if (bookingMode == '…')`, pas de `if (isOwner)`, pas de calcul `isPast`, pas de reconstruction de règles métier. Chaque resource porte des flags de capacité nommés clairement, et le front mappe 1:1 sur des boutons/sections.
>
> Si un nouveau comportement apparaît côté UI, la question à se poser est : **"est-ce que le backend peut m'envoyer ça comme flag ?"** → toujours oui, sauf rares exceptions purement cosmétiques.

---

## 1. Règles métier — ce que l'UI doit montrer

### Vue planning (jour / semaine / mois) — commun à TOUS les modes

Ces éléments sont présents quel que soit le mode de la société :

- **RDVs confirmés** (toujours affichés)
- **Ligne "now"** sur la vue jour quand la date courante est aujourd'hui
- **Pauses** : celles du salon (capacité) ET celles de l'utilisateur connecté (le pivot de la personne authentifiée, owner ou employé). Un owner qui est aussi un pro voit ses pauses perso. Rendues en bande beige `IgnorePointer` — **les rangées sous la pause restent tappables** : le pro a toujours le droit d'ajouter un walk-in d'urgence pendant une pause.
- **Jours fermés** : ceux du salon ET ceux de l'utilisateur connecté. Écrase la vue jour avec un écran dédié.
- **Bouton "No-show"** sur un RDV passé (≤ 24h) confirmé
- **Bouton "Annuler"** sur un RDV walk-in **ajouté manuellement** et **non encore passé**. Les RDV clients (non walk-in) n'exposent pas ce bouton — seul le client peut annuler son propre rendez-vous.

### Mode capacité (owner uniquement)

Superpose aux règles globales :

- **Tous les statuts de RDV** sont affichés (pending / confirmed / rejected / cancelled / no_show / completed)
- **Pas de bandeau "prochain RDV"** (plusieurs clients peuvent être en parallèle, notion de "prochain" vide de sens)
- **Boutons "+"** à côté d'un créneau déjà occupé pour ajouter un walk-in supplémentaire (multi-clients même horaire)
- **Boutons "Accepter" / "Refuser"** sur les RDV pending non passés

### Mode individuel (owner OU employé en employee_based)

Superpose aux règles globales :

- **Uniquement les RDVs confirmés** (les rejetés/annulés disparaissent du timeline)
- **Bandeau "prochain RDV"** visible en haut (avec téléphone / badge date si autre jour)

### Vue semaine — commun

Applique strictement les règles globales ci-dessus. Pas d'ajout mode-spécifique.

### Desktop uniquement — panneau "RDVs à confirmer" (mode capacité)

- Visible sur desktop, mode capacité, dans **toutes les vues** (jour / semaine / mois)
- **Vue jour** : affiche uniquement les RDVs à confirmer (pending)
- **Vue semaine / mois** : affiche **tous les RDVs** du jour sélectionné

---

## 2. Contrat backend — formes des resources

### 2.1 `GET /my-company/planning-settings` (nouveau, à créer)

Resource qui drive toutes les sections/sections cachées du planning. Le front ne calcule rien à partir de `bookingMode` — il lit ces flags.

```json
{
  "data": {
    "showPendingApprovalsPanel": true,
    "showNextAppointmentBanner": false,
    "showAllStatuses": true,
    "allowOverlappingWalkIns": true,
    "visibleStatuses": ["pending", "confirmed", "rejected", "cancelled", "no_show"]
  }
}
```

| Champ | Type | Rôle |
|---|---|---|
| `showPendingApprovalsPanel` | bool | Affiche le panneau desktop d'approbations (capacité uniquement) |
| `showNextAppointmentBanner` | bool | Affiche le bandeau "prochain RDV" en haut du planning |
| `showAllStatuses` | bool | `true` → affiche cancelled/rejected/no_show ; `false` → filtre les statuts non-actifs |
| `allowOverlappingWalkIns` | bool | Autorise les "+"  sur des créneaux occupés |
| `visibleStatuses` | `string[]` | Liste explicite des statuts à afficher (source de vérité pour les filtres UI) |

**Règle de calcul backend** :
- Owner + capacity → tous les flags `true` sauf `showNextAppointmentBanner`
- Owner + employee_based → `showNextAppointmentBanner: true`, reste `false`, `visibleStatuses = ['confirmed']`
- Employee → comme owner employee_based

### 2.2 `GET /my-company/planning-overlays?start=…&end=…` (existant)

Renvoie les pauses + jours off agrégés côté back. Le front n'a **pas à savoir** qui a créé la pause ni le rôle — il affiche la liste.

**Règles de collecte backend** :
- Pauses : toujours la liste du pivot de l'utilisateur authentifié (`employee_breaks` where `company_user_id = callerPivot`). Ça couvre aussi bien les employés que les owners qui servent aussi en tant que pro (cas employee_based). En mode **capacité** s'ajoutent les pauses company (`company_breaks`).
- Jours off : pivot de l'utilisateur (`employee_days_off`) + ceux de la société (`company_days_off`, applicables à tout le monde, ex : jour férié).

```json
{
  "data": {
    "breaks": [
      { "id": "1", "dayOfWeek": 1, "startTime": "12:00", "endTime": "13:00", "label": "Déjeuner" }
    ],
    "daysOff": [
      { "id": "5", "date": "2026-04-25", "reason": "Formation" }
    ]
  }
}
```

### 2.3 Enrichissement des `OwnerAppointmentResource`

Chaque RDV porte ses capacités. Le front rend les boutons ssi le flag est `true`.

```json
{
  "id": "42",
  "status": "confirmed",
  "startTime": "14:00",
  "endTime": "14:30",
  "clientName": "Jean Dupont",
  "isWalkIn": true,
  "isPast": false,

  "can": {
    "accept":   false,
    "reject":   false,
    "cancel":   true,
    "markNoShow": false,
    "freeSlot": false
  }
}
```

| Flag | Condition backend | Action frontend |
|---|---|---|
| `accept` | pending + non passé + owner + capacity_based | Bouton "Accepter" |
| `reject` | idem accept | Bouton "Refuser" |
| `cancel` | **walk-in uniquement** + non passé + confirmed/pending + rôle ≠ null | Bouton "Annuler" (les RDV clients ne sont annulables que par le client) |
| `markNoShow` | passé ≤ 24h + confirmed + rôle ≠ null | Bouton "Pas venu" |
| `freeSlot` | status = rejected + owner + capacity_based | Bouton "Libérer le créneau" |

**Règles métier encapsulées** (côté back, **pas** côté front) :
- `isPast` = `now > endDateTime` (ou `now > startDateTime` pour no-show)
- "non passé" = comparaison avec `now()` timezone du salon
- Un owner en mode employee_based voit les boutons d'approbation sur ses RDVs ? → backend décide via `can.accept/reject`
- Un employé ne peut pas approuver → backend renvoie `false`

**Le front teste UNIQUEMENT les flags**, jamais `if (appointment.status == 'pending' && !isPast && isOwner)`.

---

## 3. Comportement frontend — avant / après

### Avant (actuel, à refactorer)

```dart
// ❌ Logique métier dans l'UI
final isEmployeeBased = company.bookingMode != 'capacity_based';
final visibleAppointments = isEmployeeBased
    ? state.appointments.where((a) => a.status != 'cancelled' && a.status != 'rejected').toList()
    : state.appointments;

if (authState.isOwner && company.bookingMode == 'capacity_based') {
  showApprovalsPanel();
}

if (appointment.status == 'pending' &&
    !appointment.isPast &&
    authState.isOwner &&
    company.bookingMode == 'capacity_based') {
  renderAcceptButton();
}
```

### Après (cible)

```dart
// ✅ Le back a déjà décidé
final visibleAppointments = state.appointments
    .where((a) => settings.visibleStatuses.contains(a.status))
    .toList();

if (settings.showPendingApprovalsPanel) showApprovalsPanel();
if (settings.showNextAppointmentBanner) showNextRdvBanner();

if (appointment.can.accept) renderAcceptButton();
if (appointment.can.cancel) renderCancelButton();
if (appointment.can.markNoShow) renderNoShowButton();
```

Zéro `bookingMode`, zéro `isOwner`, zéro calcul de `isPast` dans le front.

---

## 4. Plan d'implémentation

1. **Backend**
   - Ajouter endpoint `GET /my-company/planning-settings` qui renvoie `PlanningSettingsResource`
   - Étoffer `OwnerAppointmentResource` avec la sous-structure `can` (calculée depuis le role + status + now)
   - Documenter les règles de calcul en un seul endroit (`PlanningAccessPolicy` ou service dédié)

2. **Frontend**
   - Nouveau modèle `PlanningSettingsModel` + fetch dans `companyPlanningProvider.load()`
   - Modèle `PlanningAppointmentCapabilitiesModel` attaché à `PlanningAppointmentModel`
   - Retirer toutes les conditions sur `bookingMode` / `authState.role` dans les écrans planning (mobile + desktop)
   - Remplacer par `settings.<flag>` ou `appointment.can.<action>`

3. **Tests**
   - Backend : tester la matrice role × mode × status pour chaque flag `can.*`
   - Frontend : retirer les tests qui reconstruisent la logique métier (source de vérité = backend)

---

## 5. Anti-patterns à bannir

- ❌ `if (company.bookingMode == 'capacity_based')` dans un widget
- ❌ `if (authState.isOwner)` dans un widget planning
- ❌ Calcul de `isPast` côté front (`DateTime.now().isAfter(...)`)
- ❌ Dérivation de `canAccept` depuis `status + role`
- ❌ Filtre de statuts hardcodé dans le client (`where((a) => a.status != 'cancelled')`)

Si une de ces choses est nécessaire, c'est que le backend manque un flag — **créer le flag, ne pas dupliquer la logique**.

---

## 6. Exception tolérée

Le purement cosmétique qui n'a pas de conséquence métier peut rester en front :
- Affichage conditionnel d'un skeleton pendant `isLoading`
- Responsive breakpoints (mobile vs desktop)
- Auto-scroll vers la ligne "now"
- Animations / haptic feedback

Tout le reste → backend.

---

## 7. Walk-in pendant une pause — override volontaire

Cas particulier : le pro peut **toujours** ajouter un walk-in pendant sa propre pause, quel que soit le mode de la société. Rationale : urgence / faveur client, c'est une décision humaine consciente, pas une lacune du logiciel.

Côté **frontend** :
- La bande grise de pause est rendue en `IgnorePointer`
- Les lignes sous la pause restent tappables (`coveredRows` n'inclut PAS les pauses)

Côté **backend** :
- `POST /my-company/walk-in` (`MyCompanyController::storeWalkIn`) **ne check pas** les pauses — crée directement le RDV walk-in
- `POST /api/booking` (`BookingController::storeBooking`) **check toujours** les pauses et refuse — les clients externes ne peuvent pas réserver pendant une pause (c'est tout l'intérêt d'une pause)
- `GET /companies/{id}/slots` exclut les créneaux qui overlap une pause — le client ne voit même pas la proposition

Le pare-feu est donc : les clients respectent les pauses (via l'endpoint public), le pro peut les outrepasser (via l'endpoint my-company).

### Scoping du walk-in par mode

| Mode | Rôle appelant | `company_user_id` du RDV créé |
|---|---|---|
| Capacity | owner | `null` (au niveau société, pas attribué à un pro) |
| Capacity | employé | `null` (idem) |
| Employee-based | employé | son pivot |
| Employee-based | **owner-pro** | **son pivot** (l'owner qui sert lui-même doit apparaître sur son planning perso) |

Ce dernier cas était un bug : `storeWalkIn` rejetait l'owner d'un salon employee_based en 403. Corrigé — on résout le pivot de l'owner via `CompanyUser::where('user_id', auth()->id())`.
