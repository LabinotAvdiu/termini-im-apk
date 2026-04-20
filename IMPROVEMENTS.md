# Améliorations à faire — Termini im

Backlog des améliorations fonctionnelles / techniques. À compléter au fil de l'eau.

> **Note** : les blocages pour la mise en prod sont dans `PRODUCTION_TODO.md`.
> Ce fichier-ci est un backlog d'**évolutions produit**.

---

## 🔑 Authentification tierce

### Google Sign-In
- [ ] Créer un OAuth 2.0 Client ID dans Google Cloud Console (type **Android** + **iOS** + **Web**)
- [ ] Android : SHA-1 / SHA-256 du keystore de release dans la Console
- [ ] iOS : ajouter le `REVERSED_CLIENT_ID` dans `ios/Runner/Info.plist` → `CFBundleURLSchemes`
- [ ] Web : mettre le Client ID dans `web/index.html` (meta `google-signin-client_id`)
- [ ] Backend : endpoint `POST /api/auth/google` qui vérifie le `id_token` via la lib Google, crée / link l'user, renvoie un token Sanctum
- [ ] Flutter : utiliser le package `google_sign_in` déjà dans le pubspec, câbler `auth_repository.loginWithGoogle()` pour appeler l'endpoint
- [ ] Gérer le linking : si l'email Google existe déjà en local avec un mot de passe classique → proposer la fusion

### Facebook Login
- [ ] Créer une apclaup Facebook dans developers.facebook.com → activer Facebook Login + produits
- [ ] Android : `facebook_app_id` dans `strings.xml` + activity Facebook dans `AndroidManifest.xml`
- [ ] iOS : URL scheme `fb{APP_ID}` dans `Info.plist` + `FacebookAppID` / `FacebookClientToken` / `FacebookDisplayName`
- [ ] Backend : endpoint `POST /api/auth/facebook` qui vérifie le `access_token` via Graph API
- [ ] Flutter : utiliser `flutter_facebook_auth` déjà listé dans pubspec, câbler `auth_repository.loginWithFacebook()`
- [ ] Gérer le cas où Facebook ne renvoie pas l'email (user a refusé la permission email) — afficher un écran de complétion

### Sign in with Apple (obligatoire pour App Store si Google/Facebook sont proposés)
- [ ] Activer "Sign in with Apple" dans l'Apple Developer Portal pour l'App ID
- [ ] Ajouter la capability dans Xcode → Runner → Signing & Capabilities
- [ ] Android : fallback via OAuth web (Apple ne fournit pas de SDK Android natif, utiliser `sign_in_with_apple` avec `webAuthenticationOptions`)
- [ ] Backend : endpoint `POST /api/auth/apple` qui vérifie le JWT Apple (clé publique Apple + audience = bundle ID)
- [ ] Flutter : package `sign_in_with_apple`, câbler dans `auth_repository.loginWithApple()`
- [ ] Cas particulier : Apple ne renvoie le nom / email **qu'à la toute première authentification** → persister immédiatement

### Chantiers communs à ces 3 logins
- [ ] Écran d'accueil auth : boutons Google / Facebook / Apple avec icônes officielles, hiérarchie primaire (bordeaux), séparateur "ou" avant le login par email
- [ ] Gestion de l'erreur `email_already_exists_with_different_provider` (le user s'est inscrit via email en premier, puis essaie de login via Google avec le même mail)
- [ ] Table `user_oauth_identities` (user_id, provider, provider_user_id, created_at, unique sur (provider, provider_user_id))
- [ ] Si l'user est sur Web et utilise Google, redirect URL à configurer en prod
- [ ] Tests E2E manuels des 3 providers sur Android, iOS, Web

---

## 👤 Compte & Profil

- [ ] Upload de photo de profil (avatar user) — galerie + crop
- [ ] Suppression de compte RGPD-compliant (pas juste soft-delete : anonymisation des appointments + retrait des relations)
- [ ] Historique des connexions (IP, date, device) — visible dans Paramètres > Sécurité
- [ ] 2FA par email ou TOTP (au moins pour les owners)
- [ ] **Redirect post-login vers l'écran d'origine** — si l'user anonyme clique sur "Prendre RDV" ou "Favori" et se fait renvoyer sur `/login` ou `/signup`, après l'auth il doit atterrir **à la même étape** qu'il a laissée (ex : step 2 du booking d'un salon précis). Passer par un `redirectTo` en query param sur les routes auth, ou stocker la dernière intention dans un provider qui est consommé au retour de l'auth. Penser aussi au cas signup → onboarding complet → redirect.

---

## 📆 Réservation / Appointments

- [ ] Annulation client avec délai configurable par salon (ex. min 2h avant)
- [ ] Rappel "votre RDV approche" in-app (pas seulement push)
- [ ] Système d'avis / étoiles post-RDV (client note le salon, modération)
- [ ] Gestion des "no-show" côté owner : bouton sur la fiche RDV + impact sur la fiche client
- [ ] Frais de no-show configurable (carte bancaire en garantie — Stripe)
- [ ] Paiement en ligne à la réservation (Stripe Connect pour reverser au salon)
- [ ] Bookings récurrents (ex. coupe toutes les 4 semaines)

---

## 🏪 Owner / Salon

- [ ] Statistiques du salon : CA jour/semaine/mois, nb RDV, taux d'annulation (écran dédié)
- [ ] Export CSV / PDF des RDV passés
- [ ] Gestion multi-salon (un owner qui possède 2+ salons → switcher dans le shell)
- [ ] Messages directs client ↔ salon (chat simple, pas besoin de WebSocket au début, polling OK)
- [ ] Promotions / codes de réduction
- [ ] Abonnement client (carte de fidélité, ex. 10 coupes achetées = 1 offerte)

---

## 🌍 Recherche & Découverte

- [ ] Géolocalisation : "salons proches de moi" (trier par distance)
- [ ] Filtres avancés : prix max, ouvert maintenant, gender, services spécifiques
- [ ] Recherche full-text backend (Meilisearch ou Scout + Algolia)
- [ ] Page catégorie ("Tous les barbers de Prishtina") avec SEO côté web

---

## 🎨 UI / UX

- [ ] **Mode sombre** — preview validée dans `design-proposals/termini-dark-mode.html`.
  Palette proposée : BG `#0F0C0B`, surface `#1A1513`, surface+ `#231D1A`,
  burgundy clarifié `#B23A4C`, or `#E0B260`, texte `#F3ECE0`. 4ᵉ toggle dans
  Settings > Expérience pour l'override manuel. **Session dédiée après
  stabilisation des features.**
- [x] Animations de transition entre les screens (Hero + shared-element) — ✅ 2026-04-18
- [x] Skeleton loaders sur tous les écrans — ✅ 2026-04-18 (13 widgets, 15 écrans)
- [x] Micro-interactions : confettis sur RDV confirmé, vibrations haptic — ✅ 2026-04-18
      (sons : structure en place, off par défaut, TODO assets WAV)
- [ ] **Onboarding 3 écrans** au premier lancement. Flag `onboarding_done` via
  FlutterSecureStorage. Structure type :
    1. Promesse « Trouvez votre salon en quelques gestes »
    2. Différenciateur « Prenez RDV sans appeler »
    3. Réassurance « Pros vérifiés, avis honnêtes »
  Décisions à prendre : copy FR/EN/SQ, type d'illustration (photo/vectoriel/
  gradient), skip dès écran 1 ou après écran 2, CTA final (signup direct ou
  "explorer sans compte"). Reset depuis Settings en option.
- [ ] **Accessibilité** — audit livré dans `A11Y_NOTES.md` (non corrigé).
  5 axes à corriger : touch targets < 44dp (chips slots, favoris badge),
  contrastes `textHint` et `secondary` (sous AA 4.5:1), Semantics manquants
  (PhotoGallery, SkeletonBox, StepIndicator), focus clavier lightbox galerie,
  `MediaQuery.disableAnimations` sur hover desktop.

---

## 🔔 Notifications — évolutions

- [ ] Écran "centre de notifications" dans l'app (liste des notifs reçues, marker comme lu)
- [ ] Badge avec compteur sur l'icône de l'app (iOS/Android)
- [ ] Email fallback : si push non délivrée depuis > X heures, envoyer un email (queue delayed job)
- [ ] SMS (Twilio) pour les rappels 2h / RDV confirmé — option payante côté salon

---

## 💾 Backend / Infra

- [ ] **Fuseau horaire cohérent app/backend** 🔴 — actuellement `config/app.php`
  timezone = `UTC` et `appointments.date` / `start_time` stockés naïvement.
  Résultat : un RDV « 14:00 » en DB = 14:00 UTC = 16:00 à Prishtinë l'été.
  Les comparaisons côté serveur (`no-show`, `canCancel`, `minutesUntilStart`)
  considèrent le temps serveur UTC tandis que le Flutter affiche l'heure
  locale → décalage de 2h qui fait échouer « Cannot mark a future
  appointment as no-show » alors que l'owner voit le RDV passé.
  Fix propre :
    1. Définir `APP_TIMEZONE=Europe/Belgrade` (Kosovo) dans `.env` prod + CI
    2. OU : stocker tout en UTC et convertir à l'affichage Flutter via
       `intl` / `timezone` package avec la tz du company (colonne à ajouter)
    3. Backfill de la DB si besoin pour les RDV existants
- [ ] Migrer queue driver `sync` → `redis` en prod (pour les jobs notifs)
- [ ] Monitoring Laravel Horizon sur les queues
- [ ] Backup DB automatique (S3 ou Backblaze B2) quotidien + test de restore mensuel
- [ ] Rate limiting plus fin (per-endpoint, pas juste global)
- [ ] API Resource caching via `etag` + `Cache-Control`
- [ ] Migration Sanctum → Passport si besoin de refresh tokens long-lived ou authorization code flow
- [ ] OpenAPI / Swagger docs générées (scramble/l5-swagger)

---

## 🧪 Tests

- [ ] Coverage Laravel ≥ 70% (actuellement ~ sur les features critiques)
- [ ] Tests d'intégration Flutter (widget_test + golden tests pour les cartes home, booking)
- [ ] Tests E2E avec Patrol ou Maestro (login → booking → confirmation)
- [ ] CI GitHub Actions : lint + tests + build APK de preview sur chaque PR

---

## 🌐 i18n

- [ ] Ajouter le turc (`tr`) si cible élargie (beaucoup de turcs au Kosovo)
- [ ] Ajouter l'allemand (`de`) pour la diaspora kosovare en Europe
- [ ] Pluralisation proprement gérée (actuellement quelques fallback manuels)
- [ ] Formatage des prix selon la locale (€ / KZ si on ajoute le denar / EUR)
- [ ] Dates formatées locale-aware via `intl`

---

## 📱 Mobile spécifique

- [ ] Deep links : `terminiim://company/5`, `terminiim://appointment/22`
- [ ] Share sheet : partager un salon sur WhatsApp / Instagram
- [ ] Widget iOS / Android : "Prochain RDV"
- [ ] Apple Wallet / Google Wallet pass pour le RDV confirmé

---

## 🔐 Sécurité

- [ ] Audit complet des permissions (rôles) côté backend — chaque endpoint `my-company/*` vérifie bien le rôle owner ET que le company appartient à l'user
- [ ] Protection contre les enumeration attacks (login / password reset renvoient toujours le même message)
- [ ] CAPTCHA sur signup + forgot-password (hCaptcha ou Turnstile)
- [ ] Hardening galerie (voir `PRODUCTION_TODO.md` section 2)
- [ ] Scanner de dépendances : `composer audit`, `flutter pub outdated`, Dependabot

---

## 📊 Analytics

- [ ] Plausible (respect RGPD) ou Mixpanel pour l'usage funnel : landing → search → detail → booking → confirmation
- [ ] Events clés : booking_created, booking_confirmed, favorite_added, search_performed
- [ ] Dashboard interne pour l'équipe (nombre d'users actifs, taux de conversion)

---

## 🧹 Dette technique

- [ ] Générer les modèles en `freezed` (certains modèles sont encore écrits à la main)
- [ ] Centraliser les breakpoints responsive (actuellement dupliqués dans plusieurs fichiers)
- [ ] Supprimer les anciens fichiers `*_mobile.dart` / `*_desktop.dart` quand le wrapper n'est plus utilisé
- [ ] Revue de tous les `// TODO:` dispersés dans la codebase
- [ ] Supprimer les design-proposals HTML une fois le design figé
