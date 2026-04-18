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
