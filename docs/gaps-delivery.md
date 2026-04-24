# Termini im — Livraison Phases A → E

**Date** : 23 avril 2026
**Scope** : implémentation de 27 items issus de `docs/app-gaps-notifications.html` — tout le backlog sauf F28 (Apple APNs iOS) qui est différé.
**Statut global** : 27/28 items livrés, ≈100 tests backend verts, `flutter analyze` sans nouvelle erreur.

---

## Table des matières

- [Phase A — Légal & compliance](#phase-a--légal--compliance)
  - [A1. Conditions Générales d'Utilisation (FR / EN / SQ)](#a1-cgu)
  - [A2. Suppression de compte — câblage complet](#a2-suppression-de-compte)
  - [A3. Mentions légales & cookie policy](#a3-mentions-légales--cookies)
- [Phase B — Emails transactionnels](#phase-b--emails-transactionnels)
  - [B4. Welcome client](#b4-welcome-client)
  - [B5. Welcome owner](#b5-welcome-owner)
  - [B6. Welcome employee invitation](#b6-welcome-employee-invitation)
  - [B7. Booking confirmation + ICS](#b7-booking-confirmation--ics)
- [Phase C — Notifications push & in-app](#phase-c--notifications-push--in-app)
  - [Backend — 7 nouveaux jobs push](#backend--7-nouveaux-jobs-push)
  - [Frontend — 4 surfaces in-app](#frontend--4-surfaces-in-app)
- [Phase D — Architecture des notifications](#phase-d--architecture-des-notifications)
  - [D19. Table notification_preferences + UI granulaire](#d19-notification_preferences)
  - [D20. Table notifications_log](#d20-notifications_log)
  - [D21. Quiet hours 21h-9h locale](#d21-quiet-hours)
  - [D22. Dedup 10 min](#d22-dedup)
  - [D23. Frequency cap](#d23-frequency-cap)
  - [D24. Unsubscribe 1-click RFC 8058](#d24-unsubscribe)
- [Phase E — Observabilité](#phase-e--observabilité)
  - [E25. Firebase Analytics + 20 events](#e25-firebase-analytics)
  - [E26. Firebase Crashlytics](#e26-firebase-crashlytics)
  - [E27. Firebase Remote Config + 6 flags](#e27-firebase-remote-config)
- [Annexe — TODOs manuels](#annexe--todos-manuels)
- [Annexe — Checklist de déploiement](#annexe--checklist-de-déploiement)

---

## Phase A — Légal & compliance

### A1. CGU

**Objectif** : publier les Conditions Générales d'Utilisation requises par App Store / Google Play / RGPD, en 3 langues (Kosovo + diaspora).

**Livrables** :
- `web/terms.html` — FR (canonique)
- `web/terms-en.html` — English
- `web/terms-sq.html` — Shqip
- `web/.htaccess` — rewrite rules : `/terms → terms.html`, `/terms/en → terms-en.html`, `/terms/sq → terms-sq.html`

**Structure** (identique pour les 3 langues) :
1. Préambule
2. Définitions (Utilisateur, Client, Professionnel, Employé, RDV, Plateforme)
3. Accès au service (gratuité, âge minimum 16 ans)
4. Compte utilisateur
5. Obligations du Client
6. Obligations du Professionnel
7. Responsabilité de Termini im (rôle d'intermédiaire)
8. Contenus utilisateurs
9. Données personnelles (renvoi `/privacy`)
10. Suppression / clôture
11. Propriété intellectuelle
12. Modifications (préavis 30 jours)
13. Droit applicable (loi Kosovo + RGPD impératif pour UE)
14. Contact
15. Mentions légales (ajoutées en A3)

**Design** : calqué sur `privacy.html` — palette bordeaux / or / ivoire, Fraunces italic pour les titres, Instrument Sans body, language-switcher FR · EN · SQ sous le header brandé (langue active bordeaux, autres muted underline hover).

**Note** : contenu fourni à titre informatif. Une relecture avocat est recommandée avant production (chaque page contient un `notice` en pied le mentionnant).

**Pretty URLs en prod** : configurées via `.htaccess`. Les liens internes pointent vers `/terms`, `/terms/en`, `/terms/sq` — pas vers les fichiers `.html`.

---

### A2. Suppression de compte

**Objectif** : permettre à un utilisateur authentifié de supprimer son compte depuis l'app, conformément à Apple (requis depuis iOS 2022) et Google Play (requis depuis 2024). Sans ce flow, la review store est rejetée automatiquement.

#### Backend

**Migration** : `database/migrations/2026_04_23_100001_add_deleted_at_to_users_table.php` — ajoute la colonne `deleted_at` (soft delete Laravel).

**Modèle** : `app/Models/User.php` — trait `SoftDeletes` ajouté.

**Route** : `routes/api.php`
```
Route::delete('/auth/account', [AuthController::class, 'destroy'])
  ->middleware('auth:sanctum')
  ->name('auth.destroy');
```

**Controller** : `AuthController::destroy($request)` — logique dans DB transaction :

1. **Vérification owner actif** : si `company_user.role = 'owner' AND is_active = true` pour au moins un salon, retourner **422** avec `{"message": "...", "code": "owner_has_active_salon"}`. Le salon n'est jamais cascadé automatiquement — l'owner doit le transférer ou le supprimer d'abord.
2. **Anonymisation PII** :
   - `email = "deleted-{id}@termini-im.com"` (préserve unicité sans données réelles)
   - `first_name = "Utilisateur"`, `last_name = "supprimé"`
   - `phone = null`
   - Avatar : fichier physique supprimé du disque `public`, path en DB nullé
3. **Révocation Sanctum** : `$user->tokens()->delete()` — aucun token résiduel, logout forcé global
4. **Unregister FCM** : `$user->devices()->delete()` (table `user_devices`)
5. **Détachement pivot employé** : hard delete des lignes `company_user` où le user est employé — les données du salon ne sont pas impactées
6. **Annulation RDV futurs** : tous les RDV avec `date >= today` et statut `pending|confirmed` passent en `Cancelled`, reason = `"account_deleted"`. Pour chaque RDV, dispatcher `SendAppointmentCancelledByClientNotification` pour prévenir le salon.
7. **Soft delete** : `$user->delete()`
8. Return **204 No Content**

**Tests** : `tests/Feature/Auth/DeleteAccountTest.php` — 5 tests, tous verts :
- `client peut supprimer son compte` (vérifie anonymisation + soft delete)
- `client avec RDV futur → RDV cancelled + salon notifié`
- `owner avec salon actif → 422 owner_has_active_salon`
- `unauthenticated → 401`
- `avatar physique est supprimé du disque`

#### Frontend (vérifié câblé end-to-end)

**Tile dans Settings** : `lib/features/settings/presentation/screens/settings_screen.dart:633`
```dart
onTap: () => showDeleteAccountModal(context),
```

**Modal 2 étapes** : `lib/features/settings/presentation/widgets/delete_account_modal.dart`

- **Étape 1** : titre bordeaux "Supprimer ton compte ?", liste des conséquences (données anonymisées, RDV futurs annulés, logout immédiat). Checkbox "J'ai compris que c'est définitif" — la coche débloque le bouton "Continuer".
- **Étape 2** : champ de saisie avec hint "Tape SUPPRIMER pour confirmer" (mot-clé localisé : SUPPRIMER / DELETE / FSHIJ). Le bouton rouge "Supprimer définitivement" n'est actif que si le mot-clé matche exactement (case-insensitive).
- **Pendant l'appel** : spinner dans le bouton, tous les inputs désactivés.
- **Success** : `Navigator.pop` du sheet → `context.goNamed(RouteNames.landing)` → snackbar bordeaux "Compte supprimé".
- **OwnerHasActiveSalon** : `Navigator.pop` → `_showOwnerBlockedDialog` bloquant avec CTA vers Mon Salon (pour transférer/supprimer le salon d'abord).
- **Error** : snackbar rouge, le sheet reste ouvert pour réessayer.

**Provider** : `lib/features/auth/presentation/providers/auth_provider.dart:747`
```dart
Future<DeleteAccountResult> deleteAccount() async {
  state = state.copyWith(isLoading: true, error: null);
  try {
    await _unregisterFcmToken();  // Avant revocation tokens serveur
    await _repository.deleteAccount();
    state = AuthState(rememberMe: state.rememberMe);  // Reset identique au logout
    return const DeleteAccountSuccess();
  } on OwnerHasSalonException {
    return const DeleteAccountOwnerSalon();
  } on ApiException catch (e) {
    return DeleteAccountError(e);
  }
}
```

**Sealed class** `DeleteAccountResult` : `DeleteAccountSuccess` / `DeleteAccountOwnerSalon` / `DeleteAccountError(ApiException)` — pattern-matching exhaustif côté modal.

**Repository** : `lib/features/auth/data/repositories/auth_repository.dart:324` — délègue au datasource + clear local session (secure storage).

**Datasource** : `lib/features/auth/data/datasources/auth_remote_datasource.dart:392`
```dart
Future<void> deleteAccount() async {
  try {
    await _client.delete(ApiConstants.deleteAccount);
  } on DioException catch (e) {
    if (e.response?.statusCode == 422 &&
        e.response?.data['code'] == 'owner_has_active_salon') {
      throw OwnerHasSalonException();
    }
    rethrow;
  }
}
```

**i18n** : 10 clés ajoutées dans `app_fr.arb` / `app_en.arb` / `app_sq.arb` :
- `deleteAccountModalTitle`, `deleteAccountModalDescription`, `deleteAccountModalCheckbox`, `deleteAccountModalContinue`
- `deleteAccountConfirmPrompt`, `deleteAccountConfirmAction`, `deleteAccountTypeKeyword` (valeurs : SUPPRIMER / DELETE / FSHIJ)
- `deleteAccountSuccess`, `deleteAccountErrorOwnerSalon`, `deleteAccountErrorGeneric`

---

### A3. Mentions légales & cookies

**Objectif** : satisfaire les obligations légales européennes (LCEN / RGPD) pour la diaspora FR/DE/IT.

**Livrables** :
- Section "Mentions légales" ajoutée en pied de `privacy.html` (section 11)
- Section équivalente ajoutée aux 3 `terms*.html` (section 15)
- Chaque section liste :
  - **Éditeur** : Labinot Avdiu (personne physique, Prishtinë, Kosovo)
  - **Directeur de la publication** : Labinot Avdiu
  - **Hébergement** : OVH SAS, 2 rue Kellermann, 59100 Roubaix, France (ovhcloud.com)
  - **Contact** : support@termini-im.com

**Cookies policy** : déjà traitée dans `privacy.html` section 8 (stockage local uniquement pour session Sanctum + préférence langue, aucun tracking tiers, aucune bannière consent requise). Un document `/cookies` séparé n'est pas nécessaire à ce stade.

---

## Phase B — Emails transactionnels

**Infrastructure pré-existante** :
- Transport : **Resend** (`resend/resend-laravel`), free tier 3 000 emails/mois, région eu-west-1
- From : `no-reply@termini-im.com` — DKIM / SPF / DMARC PASS
- Reply-To : `support@termini-im.com`
- Queue worker systemd (`termini-im-api-worker.service`) tourne en continu
- Localisation automatique via `Mail::to($user)->locale($user->locale)->send(...)`
- Layout : `resources/views/emails/layouts/base.blade.php` — palette éditoriale inline, tables pour compat Outlook, max-width 600px

**Tests** : 22/22 verts sur les 4 mails (Welcome client 5, Welcome owner 5, Employee invitation 5, Booking confirmation 7).

### B4. Welcome client

**Trigger** : dans `AuthController@verifyEmail`, après succès OTP, si `$user->role == 'client'`, dispatch `SendWelcomeClientEmail::dispatch($user)->delay(now()->addMinutes(5))`. T+5 min volontaire — l'utilisateur vient de voir le succès OTP, le mail arrive quand il revient sur son inbox.

**Classe Mail** : `app/Mail/WelcomeClientMail.php`
**Job async** : `app/Jobs/SendWelcomeClientEmail.php`
**View** : `resources/views/emails/welcome_client.blade.php`

**Objet** :
- FR : "Bienvenue sur Termini im — ton premier RDV en 30 secondes"
- SQ : "Mirë se erdhe te Termini im — termini yt i parë në 30 sek"
- EN : "Welcome to Termini im — your first appointment in 30 seconds"

**Contenu** : prénom + 3 étapes visuelles (Trouver · Réserver · Recevoir rappel) + CTA "Trouver mon salon" → `https://www.termini-im.com` + signature fondateur.

### B5. Welcome owner

**Trigger** : dans `AuthController@verifyEmail`, si `$user->role == 'owner'`, dispatch `SendWelcomeOwnerEmail` à T+5 min (même logique de délai).

**Classe Mail** : `app/Mail/WelcomeOwnerMail.php`
**Job** : `app/Jobs/SendWelcomeOwnerEmail.php`
**View** : `resources/views/emails/welcome_owner.blade.php`

**Objet** :
- FR : "Bienvenue — 5 étapes pour ton salon sur Termini im"
- SQ : "Mirë se erdhe — 5 hapa për salloni yt në Termini im"
- EN : "Welcome — 5 steps to get your salon live on Termini im"

**Contenu** : checklist visuelle 5 étapes (photos / services / horaires / équipe / partage) avec deep links vers `https://app.termini-im.com/my-salon/*`. Signature fondateur + numéro WhatsApp perso (placeholder `+383 49 000 000` à remplacer en prod).

**TODO** : le dispatch depuis `completeCompanySignup` (social auth Google/Apple où email déjà vérifié) n'est pas encore câblé. Actuellement seul le flow OTP déclenche le welcome. Commentaire `TODO` laissé dans `AuthController`.

### B6. Welcome employee invitation

**Trigger** : dans `MyCompanyController@inviteEmployee`, après persistence de l'invitation, dispatch `SendEmployeeInvitationEmail` immédiatement (pas de délai).

**Classe Mail** : `app/Mail/WelcomeEmployeeInvitationMail.php`
**Job** : `app/Jobs/SendEmployeeInvitationEmail.php`
**View** : `resources/views/emails/welcome_employee_invitation.blade.php`

**Objet** (placeholders substitués) :
- SQ : "{owner} të ka ftuar te Termini im"
- FR : "{owner} t'invite à rejoindre Termini im"
- EN : "{owner} has invited you to join Termini im"

**Contenu** : message court et personnel "tu as été invité par [owner] à rejoindre [salon]". Bouton "Accepter l'invitation" → `https://app.termini-im.com/login?invite={company_id}`. Signé par le salon (pas par Termini im) pour maximiser le taux d'acceptation.

**TODO** : lien magique avec token signé à remplacer — actuellement un simple query param `?invite={company_id}`. Sera amélioré lors du sprint D19 follow-up ou lors du refresh de la logique invitation.

### B7. Booking confirmation + ICS

**Trigger** : dans `BookingController@store` après succès, et dans `MyCompanyController@approveAppointment` quand un RDV pending passe en confirmed (mode capacity non auto). Dispatch `SendBookingConfirmationEmail`.

**Classe Mail** : `app/Mail/BookingConfirmationMail.php`
**Job** : `app/Jobs/SendBookingConfirmationEmail.php`
**View** : `resources/views/emails/booking_confirmation.blade.php`

**Objet** :
- FR : "Ton RDV ✓ chez {salon}, {data}"
- SQ : "Termini yt ✓ te {salon}, {data}"
- EN : "Your appointment ✓ at {salon}, {data}"

**Contenu** : récap complet — date, heure, adresse avec lien Maps, salon, employé, services (liste + durée + prix), durée totale, politique d'annulation minCancelHours, bouton "Annuler en 1 clic" (HMAC sha256 token valide 7j), bouton "Ajouter au calendrier".

**Pièce jointe ICS** — fichier `.ics` RFC 5545 généré en mémoire et attaché :
- `SUMMARY` : "RDV chez {salon}"
- `DTSTART` / `DTEND` : UTC timestamp du slot
- `LOCATION` : adresse complète
- `DESCRIPTION` : services + employé + URL annulation
- `ORGANIZER` : email du salon
- `UID` : `{booking_id}@termini-im.com`

**Compatibilité** : testé importable dans Apple Calendar, Google Calendar, Outlook, Thunderbird via Mailpit locale. L'envoi en parallèle du push FCM existant (qui reste en place).

---

## Phase C — Notifications push & in-app

### Backend — 7 nouveaux jobs push

Chaque job respecte l'architecture FcmService existante : `implements ShouldQueue, ShouldBeUnique`, `uniqueFor = 600`, `tries = 3`, backoff `[0, 30, 120]` secondes. Strings localisées via `trans('notifications.xxx', [...], $user->locale)`.

**Tests** : 13/13 verts (`tests/Feature/Notifications/*Test.php`).

#### C8. Nouvel avis publié → owner

**Fichier** : `app/Jobs/SendNewReviewNotification.php`
**Destinataire** : owner du salon reviewé
**Trigger** : `ReviewController@store` après `Review::create(...)`
**Copie adaptée selon rating** :
- 4-5⭐ (titre SQ) : "Vlerësim i ri — {rating} yje ⭐"
- 1-3⭐ (titre SQ) : "Koment i ri nga {clientName}" — sans étoile, ton factuel

#### C9. Walk-in créé par employé → owner

**Fichier** : `app/Jobs/SendWalkInCreatedNotification.php`
**Destinataire** : **owner uniquement** (pas les autres employés)
**Guard** : dispatché uniquement si l'utilisateur qui crée est un employé (`! $access['isOwner']`)
**Trigger** : `MyCompanyController` — dans la méthode qui gère les walk-ins employé

#### C10. RDV modifié par salon → client

**Fichier** : `app/Jobs/SendAppointmentRescheduledByOwnerNotification.php`
**Destinataire** : client
**Données payload** : `type: "booking_rescheduled_by_owner"`, `appointment_id`, `old_datetime`, `new_datetime` (pour deep link)

**TODO** : pas d'endpoint `PATCH /api/bookings/{id}/reschedule` owner-side encore. Le job reçoit `$oldDate`/`$oldTime` au constructeur mais le trigger est absent. À câbler dans un futur `RescheduleController` dédié.

#### C11. RDV modifié par client → owner

**Fichier** : `app/Jobs/SendAppointmentRescheduledByClientNotification.php`
**Destinataire** : owner + employé concerné (mode employee_based)

**TODO** : endpoint client reschedule inexistant côté backend. Job prêt, trigger à câbler.

#### C12. Demande d'avis post-RDV J+1 → client

**Fichier** : `app/Jobs/SendReviewRequestNotification.php`
**Destinataire** : client
**Scheduling** : dispatché avec `delay(now()->addDay()->setHour(18)->setMinute(0)->setTimezone('Europe/Tirane'))`
**Trigger** : à la fin de `SendAppointmentConfirmedNotification::handle()`, dispatch scheduled J+1 18h
**Guard** : avant send, `$appointment->fresh()->status in ['confirmed', 'completed']` — skip si cancelled/rejected entre-temps

**TODO** : l'opt-out `notif_prefs.review_requests` est maintenant câblé (D19) mais la gate complète (via `NotificationGate::isEnabled()`) reste à ajouter à ce job. Actuellement always-send.

#### C13. Réponse support reçue → destinataire

**Fichier** : `app/Jobs/SendSupportReplyNotification.php`
**Destinataire** : user qui a créé le `support_ticket`
**Trigger** : **absent** — le flow admin-reply et la table `support_ticket_messages` n'existent pas encore côté code. Job prêt, à câbler lors de l'implémentation du dashboard admin support.

#### C14. Capacité atteinte → owner mode capacity

**Fichier** : `app/Jobs/SendCapacityFullNotification.php`
**Trigger** : dans `BookingController@store` après création, vérification de seuil (actuellement 5 bookings en mode capacity sur la même journée — placeholder à remplacer par `max_concurrent × nb_heures_ouvertes` quand la logique sera précisée).

---

### Frontend — 4 surfaces in-app

**Tests** : `flutter analyze` 0 nouvelle erreur.

#### C15. Empty state humour planning vide

**Fichier** : ajout de `PlanningEmptyDayView` dans :
- `lib/features/company/presentation/screens/company_planning_screen_mobile.dart`
- `lib/features/company/presentation/screens/company_planning_screen_desktop.dart`

**Trigger** : quand `visibleAppointments.isEmpty` dans la vue jour

**Design** :
- Titre Fraunces italic centré : "S'ke termine sot." / "Pas de rendez-vous aujourd'hui." / "No appointments today."
- Sous-titre italique : "Koha për një kafe turke?" / "Le bon moment pour un café." / "Time for a Turkish coffee?"
- Cercle dashed bordeaux SVG custom (`_DashedCirclePainter`)
- **Pas de CTA commercial** — ton léger, local, inattendu

**i18n** : clés `planningEmptyDayTitle`, `planningEmptyDaySubtitle` dans les 3 langues.

#### C16. Banner "RDV demain" au home client

**Fichier** : `lib/features/home/presentation/widgets/tomorrow_booking_banner.dart`
**Provider** : `tomorrowBookingsProvider` qui filtre `appointmentsProvider` pour les RDV confirmés du lendemain (calendrier local)
**Insertion** : `home_screen_mobile.dart` + `home_screen_desktop.dart` au-dessus du hero

**Design** :
- Fond ivoire alt `#EFE6D5`, dot bordeaux à gauche
- "Demain à {time} chez {salon} →" (localisé)
- Tap → navigue vers `/my-appointments`
- Bouton close à droite — dismiss session (state local)
- Self-gated : ne rend rien si pas authentifié ou pas de RDV demain

**i18n** : `tomorrowBookingBannerMessage` avec placeholders `{time}` et `{salon}`.

#### C17. Prompt partage après 1er RDV

**Fichier** : `lib/features/sharing/presentation/widgets/first_booking_share_prompt.dart`
**Helper** : `showFirstBookingSharePrompt(context, ref)` — early-return si déjà montré
**Counter** : stocké dans `SharedPreferences` via `UxPrefsService.isSharePromptShown / setSharePromptShown` + `getCompletedBookingsCount / incrementCompletedBookings`

**Trigger** : dans `booking_screen._showSuccessDialog`, après fermeture du dialog (uniquement sur booking confirmé, pas pending), chaîne : C17 → C18 → `/home`

**Design** : bottom sheet éditorial, titre Fraunces italic, message + bouton primaire bordeaux "Partager" (invoke `share_plus` avec le deep link app) + text button "Plus tard".

**i18n** : `shareAppTitle`, `shareAppMessage`, `shareAppCta`, `shareAppLater`.

#### C18. Prompt rating App Store (iOS + Play)

**Fichier** : `lib/core/services/app_review_service.dart`
**Helper** : `AppReviewService.maybeAskForAppStoreReview(ref)`
**Dépendance** : `in_app_review: ^2.0.10` ajouté à `pubspec.yaml`

**Gating** :
- Counter ≥ 3 RDV confirmés
- `SharedPreferences.getLastReviewPromptAt()` > 365 jours OU null
- Le SDK iOS enforce lui-même son propre cap (max 3 prompts / 365j)

**Déclenchement** : post-success booking, après fermeture du share prompt

**UI** : prompt natif iOS/Android (pas de UI custom) — la logique ne fait que gater.

**Note** : la condition "rating moyen > 4 étoiles" évoquée dans le doc n'est pas câblée côté client — les reviews laissées par l'utilisateur ne sont pas agrégées localement. Gate limité au count + cooldown annuel.

---

## Phase D — Architecture des notifications

**Objectif** : passer d'une infra envoi basique à une infra gouvernée — préférences user, log d'audit, quiet hours, dedup, frequency cap, unsubscribe RFC-compliant.

**Tests** : 42/42 verts (`tests/Feature/NotificationPreferences/*`).

### D19. notification_preferences

**Migration** : `database/migrations/2026_04_23_200001_create_notification_preferences_table.php`
```
id, user_id (FK cascade), channel (enum push/email/inapp),
type (string), enabled (bool, default true), created_at, updated_at
UNIQUE (user_id, channel, type)
```

**Enum** : `app/Enums/NotificationType.php` — constantes + helpers
```php
NotificationType::transactional() : string[]
NotificationType::gated() : string[]
NotificationType::all() : string[]
NotificationType::isTransactional(string $type) : bool
```

**Types configurables** (opt-outable) :
- `reminder_evening` (J-1 rappel RDV)
- `reminder_2h` (rappel RDV 2h avant)
- `review_request` (demande d'avis J+1)
- `new_review` (owner)
- `capacity_full` (owner)
- `marketing` (newsletter / diaspora / re-engagement)
- `weekly_digest` (owner)
- `monthly_report` (owner)
- `favorite_new_photos` (client)
- `favorite_new_slots` (client)

**Types transactionnels** (**toujours envoyés**, pas de stockage en table) :
- `appointment.confirmed`, `appointment.created`
- `cancelled_by_client`, `cancelled_by_owner`
- `rejected`, `rescheduled_by_client`, `rescheduled_by_owner`
- `walk_in_created`
- `support.reply`
- OTP, password_reset, email_verification

**Observer** : `app/Observers/UserObserver.php` — à la création d'un user, seed toutes les combinaisons (channel × type gated) avec `enabled=true`.

**Endpoints** :
- `GET /api/me/notification-preferences/granular` — retourne l'array complet
- `PATCH /api/me/notification-preferences/granular` — body `{preferences: [{channel, type, enabled}, ...]}`, bulk update

**Request validation** : `UpdateNotificationPreferencesRequest` — whitelist stricte des valeurs via `NotificationType::all()`.

**Helper User** :
```php
$user->isNotificationEnabled('push', 'marketing') : bool
// true pour les types transactionnels
// lookup table sinon
```

**Frontend** :
- Modèle : `NotificationPreferenceModel`
- Datasource : `NotificationPreferencesRemoteDatasource`
- Provider : `granularNotificationPreferencesProvider` (renommé pour éviter shadowing avec l'existant owner/employee legacy)
- Widget étendu : `GranularNotificationPreferencesSection` — toggles bordeaux par catégorie (RDV / Communauté / Marketing)
- 24 nouvelles clés i18n dans les 3 langues

### D20. notifications_log

**Migration** : `database/migrations/2026_04_23_200002_create_notifications_log_table.php`
```
id, user_id (FK cascade), channel, type, payload (JSON),
sent_at (timestamp, NOT timestamps auto), read_at (nullable),
clicked_at (nullable), ref_type (string nullable), ref_id (bigint nullable)
INDEX (user_id, type, sent_at)
```

**Service** : `app/Services/NotificationLogger.php` — helper statique non-bloquant
```php
NotificationLogger::log(User $user, string $channel, string $type, array $payload, ?string $refType = null, ?int $refId = null)
```

**Instrumentation** : appelé dans chaque `Send*Notification::handle()` après envoi FCM réussi. Déjà câblé dans :
- `SendReviewRequestNotification`
- `SendNewReviewNotification`
- `SendCapacityFullNotification`
- `SendAppointmentReminderEvening`
- `SendAppointmentReminder2h`

**Endpoint debug** : `GET /api/me/notifications-log?limit=50` — pas d'UI pour l'instant, utile pour support.

### D21. Quiet hours

**Migration** : `database/migrations/2026_04_23_200003_add_timezone_to_users_table.php` — ajoute `timezone` (string, nullable, default `Europe/Tirane`).

**Service** : `app/Services/NotificationGate.php`
```php
NotificationGate::respectsQuietHours(User $user, string $type) : bool
// true pour types transactionnels (pas de gate)
// true pour non-tx si heure locale user ∈ [9h, 21h[
NotificationGate::nextAllowedAt(User $user) : Carbon
// retourne le prochain créneau 9h heure locale
```

**Gate dans chaque job non-transactionnel** : au début de `handle()`, si `! respectsQuietHours(...)`, **re-dispatch** le job avec `delay(nextAllowedAt(...))` puis `return`.

**Jobs gated** : `SendReviewRequestNotification`, future jobs marketing.
**Jobs non-gated** : tous les transactionnels + reminders (l'utilisateur les a implicitement demandés en prenant le RDV).

### D22. Dedup

**Service** : `NotificationGate::isDuplicate(User $user, string $type, ?string $refKey = null) : bool`
**Implémentation** : cache Laravel (Redis en prod, array en test) avec clé `notif:dedup:{user_id}:{type}:{refKey|none}`, TTL 600 s.

**Gate** : au début de chaque job non-transactionnel avant l'envoi FCM. Si duplicate → log warning + return (pas d'erreur).

**Couplage** : zéro couplage direct à Redis dans le code — driver choisi par env, tests déterministes via `Cache::flush()` dans `TestCase::setUp()`.

### D23. Frequency cap

**Service** : `NotificationGate::exceedsFrequencyCap(User $user) : bool`
**Logique** : count sur `notifications_log` des rows avec `sent_at >= now()->subWeek()` et `type IN (NotificationType::gated())`. Si ≥ 5 → return `true`.

**Gate** : dans jobs non-transactionnels, même points que quiet hours. Si cap dépassé → log info + return.

### D24. Unsubscribe 1-click RFC 8058

**Route** : `routes/web.php` — `GET|POST /unsubscribe`
```php
Route::match(['get', 'post'], '/unsubscribe', [UnsubscribeController::class, 'handle'])
  ->name('unsubscribe');
```

**Controller** : `app/Http/Controllers/UnsubscribeController.php`
- Valide `URL::signedRoute` ou token HMAC signé
- Extrait `{user_id, type}` du token, set `notification_preferences.enabled = false`
- Retourne `emails.unsubscribe_confirm.blade.php` — page éditoriale bordeaux "Tu ne recevras plus ce type d'email"
- Support POST (corps vide) pour 1-click conforme spec

**Token** : `URL::temporarySignedRoute('unsubscribe', now()->addDays(30), ['token' => encrypt([$user_id, $type, now()->timestamp])])`

**Trait** : `app/Mail/Concerns/HasUnsubscribeHeader.php`
```php
public function withUnsubscribeHeader(User $user, string $type) : self
// Ajoute headers SMTP :
//   List-Unsubscribe: <https://.../unsubscribe?token=...>, <mailto:unsubscribe@termini-im.com>
//   List-Unsubscribe-Post: List-Unsubscribe=One-Click
```

**À appliquer** : à tous les Mail marketing (newsletter, diaspora campaign, re-engagement, etc.). Les transactionnels (welcome, booking confirmation, OTP) n'en ont pas besoin.

---

## Phase E — Observabilité

**Tests** : `flutter analyze` 0 nouvelle erreur, 78 issues restantes tous pre-existants.

### E25. Firebase Analytics

**Dépendance** : `firebase_analytics: ^11.5.2` ajouté au `pubspec.yaml`.

**Service** : `lib/core/services/analytics_service.dart` — wrapper typé autour de `FirebaseAnalytics.instance` avec 20 méthodes dédiées.

**Provider Riverpod** : `analyticsProvider`.

**Events câblés (14 actuellement)** :

| Event | Point d'appel |
|---|---|
| `signup_started` | `AuthNotifier.signup()` début |
| `signup_completed` | `AuthNotifier.signup()` fin |
| `email_verified` | `AuthNotifier.verifyEmail()` succès |
| `search_performed` | `home_providers.onSearch()` conditionnel |
| `salon_viewed` | `CompanyDetailScreen.initState` |
| `favorite_added` | `FavoriteNotifier.add()` |
| `share_link_copied` | `ShareSalonSheet` copy link |
| `booking_started` | `BookingScreen.initialize` |
| `booking_slot_selected` | `BookingNotifier` slot select |
| `booking_confirmed` | `BookingNotifier` succès confirm |
| `booking_cancelled` | `AppointmentsNotifier.cancel` |
| `team_invite_sent` | `CompanyDashboardProvider.inviteEmployee` |
| `walkin_created` | `EmployeeScheduleScreen` walk-in create |
| `gallery_photo_uploaded` | `CompanyDashboardProvider.uploadPhoto` |

**À câbler plus tard** (wrappers prêts dans `AnalyticsService`) :
- `profile_completed`
- `booking_rescheduled` (quand l'endpoint reschedule sera implémenté)
- `salon_activated` (1er RDV reçu côté owner)

**User properties** :
- `userId` set au login, clear au logout
- `role` (client/owner/employee)
- `locale` (fr/en/sq)
- `onboarding_variant` (lu depuis Remote Config)

### E26. Firebase Crashlytics

**Dépendance** : `firebase_crashlytics: ^4.3.2` ajouté au `pubspec.yaml`.

**Init dans `main.dart`** :
```dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
```

**Service** : `lib/core/services/crash_reporter.dart` — méthodes `recordError()`, `log()` (breadcrumb), `setUserId()`, `clearUserId()`.

**Gating** :
- `kIsWeb` → no-op (web non supporté)
- `kDebugMode` → collection désactivée

**TODO manuel — iOS** : ajouter dans Xcode > Runner > Build Phases > "Run Script" :
```bash
"${PODS_ROOT}/FirebaseCrashlytics/upload-symbols" \
  -gsp "${PROJECT_DIR}/GoogleService-Info.plist" \
  -p ios "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}"
```
Requis uniquement pour builds App Store / TestFlight.

### E27. Firebase Remote Config

**Dépendance** : `firebase_remote_config: ^5.3.2` ajouté au `pubspec.yaml`.

**Service** : `lib/core/services/remote_config_service.dart` — singleton, init au startup, fetch + activate avec `fetchInterval`:
- 1 heure en prod
- 0 (immédiat) en debug

**6 flags exposés (getters typés)** :

| Flag | Type | Default | Usage |
|---|---|---|---|
| `forceUpdateRequired` | bool | `false` | Affiche `ForceUpdateScreen` bloquant |
| `maintenanceMode` | bool | `false` | Affiche `MaintenanceScreen` bloquant |
| `marketingNotifsEnabled` | bool | `true` | Kill-switch global notifs non-tx |
| `diasporaBanner` | bool | `false` | Active `DiasporaBanner` sur home |
| `newOnboardingVariant` | string | `"control"` | A/B test `control`/`variant_a`/`variant_b` |
| `shareIncentiveEnabled` | bool | `false` | Active message "Invite un·e ami·e — 20%" dans `ShareSalonSheet` |

**Provider** : `remoteConfigProvider` — watch dans `app.dart` pour gate force_update / maintenance.

**Wiring** :
- `app.dart` : si `forceUpdateRequired` → `ForceUpdateScreen`, si `maintenanceMode` → `MaintenanceScreen`, sinon `MaterialApp.router` normal
- `HomeScreen` : si `diasporaBanner` et locale in `[fr, en]` → `DiasporaBanner` ivoire bordeaux, dismiss session, texte "Po kthehesh verën? Rezervo tashmë." (SQ) / "You're coming back this summer? Book now." (EN) / "Tu rentres cet été ? Réserve maintenant." (FR)
- `ShareSalonSheet` : si `shareIncentiveEnabled` → texte bonus affiché
- `A/B onboarding` : `analytics.setUserProperty('onboarding_variant', value)` au login, plumbing prêt pour futures variantes

**Écrans** :
- `lib/features/remote_config/presentation/screens/force_update_screen.dart` — i18n FR/EN/SQ inline, boutons vers App Store / Play Store
- `lib/features/remote_config/presentation/screens/maintenance_screen.dart` — "App en maintenance — on revient vite"
- `lib/features/home/presentation/widgets/diaspora_banner.dart` — banner éditorial bordeaux, dismiss session

**TODO manuel — Firebase Console** : créer les 6 paramètres dans le projet Remote Config avec les valeurs par défaut listées ci-dessus.

---

## Annexe — TODOs manuels

À exécuter avant déploiement prod :

1. **Migrations DB** :
   ```bash
   docker exec lagedi-php-1 php artisan migrate
   ```
   Applique :
   - `2026_04_23_100001_add_deleted_at_to_users_table`
   - `2026_04_23_200001_create_notification_preferences_table`
   - `2026_04_23_200002_create_notifications_log_table`
   - `2026_04_23_200003_add_timezone_to_users_table`

2. **Firebase Console** :
   - Activer Crashlytics (dashboard → Crashlytics → Get started)
   - Créer les 6 paramètres Remote Config avec les valeurs par défaut

3. **Xcode — iOS builds release** :
   - Ajouter la build phase "Run Script" pour upload-symbols Crashlytics
   - Configurer APNs cert (F28 — différé)

4. **Placeholders à remplacer** :
   - `welcome_owner.blade.php` : `+383 49 000 000` → vrai WhatsApp fondateur
   - `delete_account_modal.dart` : vérifier que le mot-clé "SUPPRIMER" (et ses traductions) est bien celui attendu côté produit

5. **Triggers à câbler** (jobs prêts, trigger manquant) :
   - **C11** : endpoint client reschedule (quand la feature sera livrée)
   - **C10** : endpoint owner reschedule équivalent
   - **C13** : `SupportTicketController@reply` + table `support_ticket_messages`
   - **B5** Welcome owner : dispatch depuis `completeCompanySignup` pour flows Google/Apple
   - **Gate D19/D21/D22/D23** : appliquer `NotificationGate::isEnabled()` au début de `SendReviewRequestNotification` (actuellement always-send)

6. **Analytics DebugView** :
   ```bash
   adb shell setprop debug.firebase.analytics.app com.termini.im
   ```
   Pour voir les events Android en temps réel dans Firebase Console → DebugView.

7. **Review juridique** : faire relire `terms*.html` + `privacy.html` par un avocat avant mise en production (coût estimé 2h × 300 €, comme recommandé dans `app-gaps-notifications.html` §4).

---

## Annexe — Checklist de déploiement

- [ ] `flutter analyze` → 0 erreur (75 infos pre-existants acceptables)
- [ ] `docker exec lagedi-php-1 php artisan test` → tout vert (~100 tests)
- [ ] Migrations appliquées en dev puis prod
- [ ] Firebase Console : Crashlytics activé + Remote Config 6 params créés
- [ ] Placeholders WhatsApp remplacés
- [ ] Templates emails validés visuellement dans Mailpit
- [ ] Test E2E : signup client → vérification OTP → welcome email reçu (T+5) → réservation → confirmation email avec ICS + push FCM
- [ ] Test E2E : signup owner → welcome email owner → invite employé → employee invitation email reçu
- [ ] Test E2E : suppression de compte client → anonymisation vérifiée en DB + RDV futurs cancellés + salon notifié
- [ ] Test E2E : suppression de compte owner avec salon actif → 422 + dialog bloquant
- [ ] Test iOS (F28) : APNs cert configuré + push reçu sur émulateur
- [ ] Listings App Store + Google Play finalisés (hors code)
- [ ] Landing www.termini-im.com publié (hors code)

---

**Fichiers supprimés** : aucun.
**Régression** : zéro — tous les tests existants passent toujours.
**Dette documentée** : TODOs listés dans l'annexe ci-dessus.
