# Production TODO — Termini im

Liste des tâches à faire **avant la mise en production**. Les items sont groupés par feature, avec la priorité et le chemin exact du fichier à modifier.

> **Légende priorité**
> - 🔴 Bloquant pour la prod (la feature ne marche pas sans)
> - 🟠 Important (la feature marche mais dégradée / risque sécurité)
> - 🟡 Nice-to-have (durcissement, observabilité)

---

## 1. Firebase / Push notifications

### 🔴 Credentials Firebase — obligatoires pour que les notifications marchent

| Plateforme | Action | Fichier |
|---|---|---|
| Android | Remplacer le `google-services.json` placeholder par le vrai depuis [Firebase Console](https://console.firebase.google.com) | `android/app/google-services.json` |
| iOS | Remplacer `GoogleService-Info.plist` placeholder. **Puis** ouvrir Xcode → Runner → Build Phases → Copy Bundle Resources → ajouter le fichier | `ios/Runner/GoogleService-Info.plist` |
| Web | Remplacer les `PLACEHOLDER_API_KEY`, `PLACEHOLDER_APP_ID`, etc. par les vraies valeurs (Console Firebase → Paramètres du projet → Apps web → firebaseConfig) | `web/index.html` + `web/firebase-messaging-sw.js` |
| Web | Remplacer `PLACEHOLDER_VAPID_KEY` (Console Firebase → Cloud Messaging → Certificats push web) | `lib/core/notifications/notification_service.dart` |
| iOS | Activer APNs dans App Store Connect + importer le certificat APNs dans Firebase Console (Paramètres projet → Cloud Messaging → iOS) | Console Firebase + Apple Dev |

### 🔴 Backend FCM
- Renseigner `FIREBASE_CREDENTIALS` dans `.env` (chemin vers le JSON service account) dans `backend/.env`. Tant que c'est vide → mode **log-only** (les notifs ne partent pas, elles sont juste loggées).
- Vérifier : `docker exec lagedi-php-1 php artisan config:show firebase` renvoie bien le bon chemin.

### 🔴 Migrations backend notifications
```bash
docker exec lagedi-php-1 php artisan migrate
```
Crée `user_notification_preferences`, `user_devices`, `appointment_notifications_sent`.

### 🔴 Scheduler Laravel en prod
Crontab serveur :
```cron
* * * * * cd /var/www/html && php artisan schedule:run >> /dev/null 2>&1
```
Deux commandes planifiées tournent :
- `appointments:send-hour-reminders` → toutes les 10 min
- `appointments:send-evening-reminders` → tous les jours à 20:00

Vérifier : `docker exec lagedi-php-1 php artisan schedule:list`

### 🟠 Route Flutter `/appointments/:id`
Le tap sur notification navigue vers cette route. Confirmer qu'elle existe dans `lib/core/router/app_router.dart`. Sinon, l'ajouter avec un écran détail RDV.

---

## 2. Galerie — durcissement sécurité (audit linux-security-expert)

### 🟠 Limites PHP uploads alignées
Créer `docker/php/uploads-lagedi.ini` avec :
```ini
upload_max_filesize = 12M
post_max_size       = 15M
memory_limit        = 256M
max_file_uploads    = 1
```
Monter dans `docker-compose.yml` : `./docker/php/uploads-lagedi.ini:/usr/local/etc/php/conf.d/uploads.ini`.

### 🟠 Double validation MIME
Dans `MyCompanyGalleryController::store` — ajouter `mimes:jpeg,png,webp` + `mimetypes:image/jpeg,image/png,image/webp` dans `StoreGalleryPhotoRequest`, puis `finfo_file()` en plus de `$file->getMimeType()`.

### 🟠 Strip EXIF explicite
Dans la pipeline Intervention Image de `store()`, ajouter `$image->core()->native()->stripImage()` (ou équivalent GD) avant de sauver. Les EXIFs contiennent parfois GPS / coordonnées.

### 🟡 Quota + dédup
Table `company_gallery_stats` avec `used_bytes`, max 20 photos par salon, dédup via SHA-256 du fichier stocké en colonne `content_hash` (unique par company).

### 🟡 Cron cleanup orphelins
Commande `gallery:cleanup-orphans` qui supprime les fichiers `storage/app/public/gallery/*` sans ligne en DB. Scheduler hebdo.

### 🟡 Permissions filesystem
`chown -R www-data:www-data storage/app/public/gallery && chmod -R 2750 storage/app/public/gallery` + umask 027 sur le conteneur PHP.

### 🟡 Canal log dédié
Dans `config/logging.php` ajouter un canal `uploads` + logrotate configuré sur le VPS.

---

## 3. Auth / Sécurité générale

### 🟠 APP_URL en prod
`backend/.env` : `APP_URL=https://api.termini-im.example` (actuellement `http://localhost:8080` pour le dev). Les URLs Storage::url() dépendent de ça.

### 🟠 CORS restrictif
`docker/nginx/default.conf` — actuellement `Access-Control-Allow-Origin: *` sur `/storage/` (nécessaire pour dev CanvasKit). En prod, remplacer par l'origine exacte du site (`https://termini-im.example`).

### 🟠 Cookies Sanctum / SANCTUM_STATEFUL_DOMAINS
Configurer les domaines stateful dans `.env` prod pour éviter les CSRF failures côté web.

---

## 4. Base de données / Seeds

### 🔴 NE PAS lancer `db:seed` en prod
Les seeds créent des salons/users de démo (donjeta@termini.im / Password1 etc.). Pour initialiser la prod : uniquement `php artisan migrate`.

### 🟠 Indexes DB à vérifier
Sur grande volumétrie : `appointments(starts_at, status)`, `company_favorites(user_id, created_at)`, `appointment_notifications_sent(appointment_id, user_id, type)` — déjà en place via les migrations existantes, mais vérifier qu'ils n'ont pas été oubliés sur la DB prod (`SHOW INDEX FROM ...`).

---

## 5. Monitoring / Observabilité

### 🟡 Sentry (ou équivalent) côté Flutter + Laravel
- Flutter : `sentry_flutter`, capture les erreurs non-gérées + breadcrumbs auth
- Laravel : `sentry/sentry-laravel`, DSN dans `.env`

### 🟡 Health check endpoint
`GET /api/health` qui renvoie 200 + état DB + état cache. Utilisé par monitoring externe (UptimeRobot, Better Stack).

### 🟡 Log rotation serveur
Logrotate sur `storage/logs/laravel.log` — sinon le fichier explose.

---

## 6. Locale / i18n

### 🟡 Langue par défaut
Actuellement le splash web fallback sur `sq` (albanais). Confirmer que c'est bien le comportement voulu en prod (ça l'est pour Kosovo) — ou basculer sur détection IP.

---

## 7. Build / CI

### 🟠 Secrets en variables d'env (pas dans le repo)
- `google-services.json` iOS / Android → gérer via CI (GitHub Actions secret → écrit au build time)
- `GoogleService-Info.plist`
- Credentials Firebase backend (`firebase-adminsdk-*.json`)

### 🟡 Builds de release
- Android : `flutter build appbundle --release` avec keystore signé
- iOS : archive Xcode + profil de provisioning App Store
- Web : `flutter build web --release --web-renderer canvaskit`

---

## 8. Tests manuels notifications en prod 🔴

À faire **après** avoir configuré Firebase (creds Android/iOS/Web + `FIREBASE_CREDENTIALS` backend) et déployé.

Prérequis par test : comptes de prod avec rôles distincts (1 owner salon, 1 employee du même salon, 1 client), et navigateur/device avec permissions notifications accordées.

### Côté client (user)

- [ ] **RDV confirmé** : client prend un RDV, owner l'accepte → le client reçoit une push `Rendez-vous confirmé` sur son device. Tap sur la notif → ouvre la page détail RDV.
- [ ] **RDV refusé** : client prend un RDV, owner le refuse → le client reçoit `Rendez-vous refusé`.
- [ ] **Rappel 20h la veille** : client a un RDV demain, attendre 20:00 → push `Rappel : RDV demain à {heure} chez {salon}`. Tester aussi avec plusieurs RDV demain (un seul message par RDV).
- [ ] **Rappel 2h avant** : client a un RDV dans ~2h, attendre la fenêtre → push `Rappel : votre RDV commence dans 2h`.
- [ ] **Pas de double envoi** : vérifier qu'un même RDV ne déclenche **qu'une** push de chaque type même en relançant les crons (`appointment_notifications_sent` sert de garde).
- [ ] **Logout** : sur logout, `DELETE /api/me/devices` est appelé → plus aucune push n'arrive sur cet appareil.

### Côté owner / employee

- [ ] **Toggle visible** : l'écran Paramètres > Notifications affiche 2 switchs bordeaux. L'écran est **absent** pour un compte client.
- [ ] **Nouveau RDV (ON)** : toggle ON par défaut — client prend un RDV → owner + tous les employees du salon reçoivent `Nouveau rendez-vous`.
- [ ] **Nouveau RDV (OFF)** : owner coupe le switch → pas de push lors du prochain booking. Réactive → push reprend.
- [ ] **Rappel 1h jour calme (≤2 RDV)** : owner a 1 ou 2 RDV dans la journée → 1h avant chaque, push `Rappel : RDV dans 1h avec {client}`.
- [ ] **Pas de rappel 1h jour chargé (>2 RDV)** : owner a 3+ RDV → aucune push 1h avant (règle respectée).
- [ ] **Rappel 1h (OFF)** : toggle OFF → pas de push même avec ≤2 RDV.
- [ ] **Multi-employees** : si plusieurs employees dans le salon et RDV walk-in sans employé assigné → seul l'owner reçoit la push (ou tous, selon règle retenue — à documenter).

### Cross-plateforme

- [ ] **Chrome desktop** (Web) : service worker FCM enregistré, push reçue en foreground + en arrière-plan (onglet fermé).
- [ ] **Android** : push en foreground affiche le local notification custom (icône bordeaux, son). En background → push système native. Tap → ouvre l'app sur la bonne route.
- [ ] **iOS** : pareil que Android, + vérifier que l'APNs token est bien généré et enregistré.
- [ ] **Permission refusée** : refuse les notifs système → la bannière "Notifications désactivées" apparaît dans Paramètres avec bouton "Ouvrir les réglages" fonctionnel.
- [ ] **Changement de langue** : user en albanais reçoit la push en SQ ; FR en FR ; EN en EN (le backend lit `users.locale`).

### Observabilité

- [ ] Logs Laravel : vérifier que chaque envoi FCM apparaît (info level), sans erreur.
- [ ] Tokens expirés : simuler un uninstall → l'app renvoie un nouveau token au prochain login ; l'ancien token disparaît de `user_devices` (FcmService supprime sur `UNREGISTERED`).

---

## 9. UX — mutual-exclusion des actions concurrentes

Quand un call réseau tourne, les autres boutons qui pourraient lancer une action concurrente doivent être **désactivés** (pas juste montrer un spinner sur celui qu'on a cliqué). Règle générale : **un seul spinner à la fois**, les autres CTA passent en `onPressed: null` sans indicateur visuel, pour éviter :
- double-submit (tap Google pendant que le submit email tourne → 2 sessions créées / race conditions token)
- UX confuse où plusieurs boutons semblent "travailler" en même temps

### Pattern implémenté
- `lib/features/auth/presentation/screens/signup_screen.dart` + `login_screen.dart` — `String? _loadingSocial` track le bouton social tapé ; `submitLoading = isLoading && _loadingSocial == null` pour que le bouton submit principal ne tourne **pas** pendant un Google/Facebook/Apple. Chaque bouton social passe `onPressed: _loadingSocial != null || isLoading ? null : _...`.

### 🟠 À propager dans le reste de l'app ✅ (partiel)
Pattern : garde au niveau du **provider** (drop les requêtes entrantes quand une mutation de même id est déjà en vol), avec `Set<String>` ou `bool` exposé dans le state pour que l'UI désactive visuellement les CTAs concernés.

Implémenté :
- `booking_provider` : `_handleConfirm` / `_handleBack` / `_handlePrevious` bail out si `state.isLoading`
- `company_planning_provider` : `mutatingIds` + drop same-id dans `_updateStatus` ; `addWalkIn` drop si `isSubmittingWalkIn`
- `appointments_provider` (client) : `cancellingIds` + drop same-id dans `cancel()`
- `company_dashboard_provider` : `uploadPhoto` drop si `galleryUploading` ; `reorderGalleryPhotos` refuse si upload en vol

Les CTAs cross-card (accept salon A + reject salon B) restent permis volontairement — opérations indépendantes. Le risque concret (double-tap sur le même bouton) est couvert.

---

## 10. Sign in with Google — configuration requise

Les endpoints backend + le bouton Flutter sont déjà codés. Il reste la config côté plateforme + Google Cloud Console.

### 🔴 Google Cloud Console — créer 4 OAuth client IDs
[console.cloud.google.com](https://console.cloud.google.com) → APIs & Services → Credentials → **+ CREATE CREDENTIALS** → **OAuth client ID**. Même projet GCP que Firebase (ils partagent les credentials).

| Type | Usage | Config |
|---|---|---|
| Web application | Flutter Web + **validation backend `aud`** | Authorized JS origins : `http://localhost:8080` (dev), `https://app.termini-im.com` (prod) |
| Android (debug) | Tests locaux Android | Package `com.terminiim.app` + SHA-1 **debug keystore** |
| Android (release) | Build prod Android | Même package + SHA-1 **release / Play App Signing** |
| iOS | App iOS | Bundle ID iOS (voir `ios/Runner/Info.plist` → `CFBundleIdentifier`) |

### 🔴 Récupérer les SHA-1 Android
```bash
# Debug (local) — après avoir run l'app au moins une fois
cd android && ./gradlew signingReport
# Cherche la section "Variant: debug" → SHA1

# Release (prod)
# Option A — keystore local
keytool -list -v -keystore release.keystore -alias upload
# Option B — Play App Signing (recommandé)
# Play Console → ton app → Setup → App integrity → App signing key certificate → SHA-1
```

### 🔴 Remplacer les fichiers placeholder
| Fichier | Comment | Statut |
|---|---|---|
| `android/app/google-services.json` | Firebase Console → Paramètres projet → Apps Android → télécharger. **Regénérer après ajout des OAuth clients Android** dans GCP (les `oauth_client` n'apparaissent que si les SHA-1 sont enregistrés). | ✅ Fait (debug) |
| `ios/Runner/GoogleService-Info.plist` | Firebase Console → Apps iOS → télécharger | ⏳ TODO |
| `ios/Runner/Info.plist` | Ajouter un `CFBundleURLType` avec `CFBundleURLSchemes = [REVERSED_CLIENT_ID]` (valeur depuis `GoogleService-Info.plist`) | ⏳ TODO |
| `web/index.html` | Meta tag `google-signin-client_id` → **Web Client ID `759517993388-6hqo810qjnephb8v1rb6oupb6csi9er0`** | ✅ Fait |

### 🟠 Web — Authorized JS origins (à vérifier dans GCP)
[console.cloud.google.com](https://console.cloud.google.com) → APIs & Services → Credentials → OAuth 2.0 Client IDs → **Web client** (type 3) → Authorized JavaScript origins doit contenir :
- `http://localhost:PORT` — **récupère le port exact** que `flutter run -d chrome` ouvre (ex. `http://localhost:51234`). Astuce : fixer le port avec `flutter run -d chrome --web-port=8080` pour éviter le port random à chaque lancement.
- `https://app.termini-im.com` (prod, quand déployé)

Pas de redirect URI nécessaire pour le flow `google_sign_in` côté web (il utilise le Google One Tap JS SDK, pas un redirect OAuth).

### 🔴 Backend — env var anti-replay
Dans `backend/.env` :
```
GOOGLE_ALLOWED_CLIENT_IDS="WEB_CLIENT.apps.googleusercontent.com,ANDROID_CLIENT.apps.googleusercontent.com,IOS_CLIENT.apps.googleusercontent.com"
```
Sans cette variable → **le backend accepte n'importe quel id_token Google valide** (n'importe quelle app tierce pourrait se loguer). **Obligatoire en prod.**

### 🟠 Vérification rapide
```bash
# Backend : endpoint existe
docker exec lagedi-php-1 php artisan route:list | grep google
# → POST    api/auth/google  ....  AuthController@googleLogin

# Test manuel : tap "Continuer avec Google" sur /landing
# → popup natif Google s'ouvre → choix compte → retour sur /home authentifié
```

### Erreurs courantes
- **`DEVELOPER_ERROR` / code 10** (Android) : SHA-1 pas enregistré dans GCP **ou** `google-services.json` pas regénéré après avoir enregistré le SHA-1
- **`sign_in_failed`** (Android) : le package name dans `android/app/build.gradle.kts` (`applicationId`) diffère de celui enregistré dans GCP
- **`aud_mismatch` 401 du backend** : le client ID utilisé n'est pas dans `GOOGLE_ALLOWED_CLIENT_IDS`
- **Popup ne s'ouvre pas en Web** : la meta `google-signin-client_id` manque dans `web/index.html` **ou** le domaine actuel n'est pas dans les Authorized JS origins

---

## 11. Sign in with Apple — configuration requise

Les endpoints backend + le bouton Flutter sont déjà codés. Il reste la config côté plateforme.

### 🔴 Flutter — activer le plugin sur Windows
```powershell
start ms-settings:developers   # activer le Developer Mode
flutter pub get                 # installe sign_in_with_apple avec symlinks
```

### 🔴 Apple Developer Portal
1. **App ID** (Bundle ID iOS) : [developer.apple.com](https://developer.apple.com/account/resources/identifiers/list) → Identifiers → ton App ID → activer **Sign in with Apple** puis sauvegarder.
2. **Service ID** (seulement si tu veux Apple sur **Web / Android**) :
   - Créer un Service ID (ex : `com.termini.web`)
   - Activer "Sign in with Apple" + configurer `Return URLs` : `https://api.termini-im.com/auth/apple/callback`
   - Associer au Primary App ID
3. **Key** (pour que le backend puisse émettre le `client_secret` si flow web) : Keys → **+** → "Sign in with Apple" → télécharger le `.p8` et noter le `Key ID`.

### 🔴 iOS — capability Xcode
```
ios/Runner.xcworkspace → Runner target → Signing & Capabilities
  → + Capability → Sign in with Apple
```
Commit le fichier `Runner.entitlements` mis à jour.

### 🔴 Backend — env vars
Dans `backend/.env` :
```
APPLE_CLIENT_ID=com.termini.ios        # Bundle ID (iOS) OU Service ID (web)
```
Sans cette variable → la vérification de l'`aud` est **désactivée** (dev only).

### 🟠 Vérification rapide
```bash
# Backend : l'endpoint accepte les JWT Apple signés
docker exec lagedi-php-1 php artisan route:list | grep apple
# → POST    api/auth/apple  .... AuthController@appleLogin

# Flutter iOS : build + tap "Continuer avec Apple" dans /landing
# (ne marche pas sur Android/Web sans Service ID — voir point 2 ci-dessus)
```

### Notes
- Apple n'envoie **`first_name` + `last_name` qu'au PREMIER sign-in**. Le client forward les valeurs reçues ; le backend les persiste à la création du User. Les logins suivants résolvent le compte par email.
- "Hide my email" → Apple génère un email relais stable par app (`xyz@privaterelay.appleid.com`) : traité comme un email normal.
- Si aucun email n'est retourné (cas rare), fallback sur `<sub>@apple.invalid` pour garantir l'unicité.

---

## 12. Géolocalisation — configuration iOS ✅

Le package `geolocator` est intégré pour le fallback GPS du salon (signup + banner "Mon Salon"). Android et Web sont OK. Les 2 clés sont en place dans `ios/Runner/Info.plist` — `NSLocationWhenInUseUsageDescription` + `NSLocationAlwaysAndWhenInUseUsageDescription`.

---

## 13. Web — URL propres + fallback SPA

`main.dart` appelle `usePathUrlStrategy()` (Flutter Web) pour servir des URLs propres (`/company/5`) au lieu du hash routing par défaut (`/#/company/5`). Les liens partagés via `buildSalonShareUrl()` supposent les URLs propres.

**Côté serveur (nginx sur le VPS OVH)** — il faut que toutes les routes inconnues retombent sur `index.html` :

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

Sans ça, le navigateur qui ouvre directement `https://app.termini-im.com/company/5` reçoit un 404 nginx au lieu de l'app Flutter. Concerne **tous** les chemins de l'app (fiche salon, booking, settings, mes rdv, etc.).

### Vérification
```bash
# Après déploiement :
curl -I https://app.termini-im.com/company/5
# → doit retourner 200 + le HTML de l'app (pas un 404)
```

---

## 14. Facebook Login — configuration Web

Android fonctionne déjà (clé hash debug enregistrée + `email`/`public_profile` activés). Le web a besoin d'une config supplémentaire dans le portail Facebook.

### ✅ Flutter — init Web SDK
Déjà fait dans `lib/main.dart` (init conditionnel `if (kIsWeb) FacebookAuth.i.webAndDesktopInitialize(...)`). Aucune action.

### 🔴 Facebook Developer Portal — ajouter la plateforme Web
[developers.facebook.com/apps/1262066146100608](https://developers.facebook.com/apps/1262066146100608) → **Paramètres → Général → + Ajouter une plateforme → Site Web**.

| Champ | Valeur |
|---|---|
| URL du site | `http://localhost:8080/` (dev) · `https://app.termini-im.com/` (prod) |
| Domaines de l'app | `localhost` (dev) · `app.termini-im.com` (prod) |

Puis **Cas d'utilisation → Authentification et demande de données → Paramètres** :
| Option | Valeur |
|---|---|
| Connexion client OAuth | ✅ Activé |
| Connexion OAuth web | ✅ Activé |
| Forcer HTTPS sur les redirections OAuth web | ❌ Désactivé **en dev** (sinon localhost échoue) — ✅ Activé en prod |
| URI de redirection OAuth valides | `http://localhost:8080/` (dev) + prod |

### 🔴 Port Flutter Web — fixe pour que FB l'accepte
Facebook exige le domaine/port exact dans "Domaines de l'app". Lance toujours Chrome sur le même port :
```bash
flutter run -d chrome --web-port=8080
```

### 🟠 Vérification rapide
1. `flutter run -d chrome --web-port=8080`
2. `/landing` → clic **Continuer avec Facebook**
3. Popup FB s'ouvre → autoriser → retour sur `/home`

### Erreurs courantes
- **`URL bloquée`** : le port actuel (`localhost:XXXXX`) n'est pas dans l'URL du site / les domaines de l'app du portail Facebook
- **`App Not Active`** : l'app est en mode "Développement" → seuls les dev/testeurs peuvent se connecter (c'est normal avant la revue Meta)
- **Popup s'ouvre puis reste blanche** : le SDK JS Facebook a été bloqué (AdBlock ? extensions ?) ou `webAndDesktopInitialize` n'a pas été appelé avant `FacebookAuth.login()`

---

## Vérification rapide avant go-live

```bash
# Backend
docker exec lagedi-php-1 php artisan migrate --force
docker exec lagedi-php-1 php artisan config:cache
docker exec lagedi-php-1 php artisan route:cache
docker exec lagedi-php-1 php artisan schedule:list
docker exec lagedi-php-1 php artisan test

# Flutter (devrait passer sans warning)
cd C:/Users/avdiu/Projetcs/hairspot_mobile
flutter analyze
flutter test
```
