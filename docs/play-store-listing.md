# Google Play Store — Listing prêt à copier-coller

**Bundle ID** : `com.terminiim.app`
**Catégorie principale** : Lifestyle
**Catégorie secondaire** : Beauty (non dispo Play Store, laisse Lifestyle seul)
**Content rating** : Everyone / Tout public
**Langue par défaut** : Albanais (sq-AL)

---

## 1. Titre court (30 car max par langue)

- **SQ** : `Termini im`
- **FR** : `Termini im`
- **EN** : `Termini im`

## 2. Description courte (80 car max)

- **SQ** (78 car) : `Rezervo terminin tënd në 30 sekonda. Sallonet e Kosovës, në xhep.`
- **FR** (76 car) : `Réserve ton RDV en 30 secondes. Les salons du Kosovo, dans ta poche.`
- **EN** (75 car) : `Book your appointment in 30 seconds. Kosovo's salons in your pocket.`

## 3. Description complète (4 000 car max)

### Albanais (par défaut — ce que la diaspora + local verra)

```
Termini im — aplikacioni shqip për rezervim termine te sallonet e Kosovës.

Falas për klientët. Falas për sallonet. Pa komision, pa abonim, kurrë.

PËR KLIENTËT

Gjej sallonin më të afërt, filtro sipas qytetit, datës dhe gjinisë.
Rezervo në 30 sekonda. Merr kujtesë automatike një ditë më parë dhe një orë para.
Shto në të preferuarat. Shiko historikun. Ndaj me shoqet një sallon ose një frizer të veçantë.

PËR SALLONET

Prano rezervime 24/7 pa u ngacmuar nga telefoni gjatë prerjes.
Menagjo ekipin, oraret, ditët off, pauzat.
Shiko planin e ditës në një shikim.
Mode individual (një frizer — një orar) ose mode kapaciteti (sallon i plotë — X vende paralelisht).
Njoftime push të menjëhershme për çdo rezervim, anulim dhe vlerësim.

KARAKTERISTIKAT KRYESORE

• Rezervim online 24/7 në 30 sekonda
• Kujtesë automatike — një ditë dhe një orë para
• Ndarje me lidhje direkte për frizeren tënde
• Walk-in në 3 prekje për sallonet
• Galeria e sallonit me foto profesionale
• Komente dhe vlerësime të modereshme
• Njoftime push të menjëhershme
• Shqip · Français · English

Bërë në Prishtinë. Për Prishtinën — dhe gjithë Kosovën.
```

### Français (pour la diaspora FR/BE/CH/LUX)

```
Termini im — l'app qui transforme la prise de rendez-vous beauté en 30 secondes.

Gratuit pour les clients. Gratuit pour les salons. Sans commission, sans abonnement, jamais.

POUR LES CLIENTS

Trouve le salon le plus proche, filtre par ville, date et genre.
Réserve en 30 secondes. Reçois des rappels automatiques — la veille et une heure avant.
Ajoute tes salons préférés en favoris. Consulte ton historique. Partage avec une amie un salon ou un·e pro en particulier.

POUR LES SALONS

Accepte des réservations 24/7 sans être dérangé·e par le téléphone pendant une coupe.
Gère ton équipe, les horaires, les jours off, les pauses.
Vois le planning du jour en un coup d'œil.
Mode individuel (un·e pro — un planning) ou mode capacité (salon entier — X places en parallèle).
Notifications push instantanées pour chaque nouvelle réservation, annulation et avis.

FONCTIONNALITÉS CLÉS

• Réservation en ligne 24/7 en 30 secondes
• Rappels automatiques — veille et 1 heure avant
• Partage avec lien direct vers ton ou ta pro préféré·e
• Walk-in en 3 taps pour les salons
• Galerie photo professionnelle par salon
• Avis et notes modérés
• Notifications push instantanées
• Albanais · Français · English

Fabriqué à Prishtinë. Pour Prishtinë — et tout le Kosovo.
```

### English

```
Termini im — the app that turns beauty appointment booking into a 30-second task.

Free for clients. Free for salons. No commission, no subscription, ever.

FOR CLIENTS

Find the closest salon, filter by city, date and gender.
Book in 30 seconds. Get automatic reminders — the evening before and one hour before.
Save favourites. Browse your history. Share a specific salon or pro with a friend.

FOR SALONS

Accept bookings 24/7 without being disturbed by the phone during a cut.
Manage your team, schedules, days off, breaks.
See the day's planning at a glance.
Individual mode (one pro — one schedule) or capacity mode (full salon — X slots in parallel).
Instant push notifications for every new booking, cancellation and review.

KEY FEATURES

• Online booking 24/7 in 30 seconds
• Automatic reminders — the day before and one hour before
• Share with a direct link to your favourite pro
• Walk-in in 3 taps for salons
• Professional photo gallery per salon
• Moderated reviews and ratings
• Instant push notifications
• Albanian · French · English

Built in Prishtinë. For Prishtinë — and all of Kosovo.
```

---

## 4. Screenshots — scénario à shooter (minimum 2, recommandé 5-8)

Par langue (tu feras un seul set SQ pour démarrer, FR/EN peuvent attendre) :

| # | Écran | Overlay texte |
|---|---|---|
| 1 | **Hero home** — liste de salons avec la tagline | "Kosova ka shumë stil." |
| 2 | **Fiche salon** — galerie + services | "Shiko, zgjidh, rezervo." |
| 3 | **Flow booking** — sélection créneau | "30 sekonda. Gati." |
| 4 | **Confirmation** — "Termini yt është konfirmuar" | "Kujtesa vijnë vetë." |
| 5 | **Owner dashboard** — planning du jour | "Për sallonet — falas gjithmonë." |

Outil recommandé : **Previewed** (previewed.app — gratuit jusqu'à 5 screenshots) ou Figma. Format Play Store : 1080×1920 portrait PNG, pas de Status Bar ni Navigation Bar système (éviter les 44px top/bottom des screenshots Android bruts).

---

## 5. Data Safety — déclaration obligatoire

→ Play Console → Data safety. Coche ces sections :

### Data collected

| Data type | Purpose | Optional | Shared with third parties |
|---|---|---|---|
| Name | Account management, App functionality | No | No |
| Email address | Account management, App functionality | No | No |
| Phone number | Account management, App functionality | Yes (at signup optional) | No |
| User ID | Account management, Analytics | No | No |
| Photos | App functionality (salon gallery) | Yes | No |
| Precise location | Nearby salon search | Yes | No |
| App activity / App interactions | Analytics (Firebase Analytics) | No | Google Firebase |
| Crash logs | App functionality (Firebase Crashlytics) | No | Google Firebase |
| Diagnostics | App functionality (performance) | No | Google Firebase |

### Data security practices

- **Encrypted in transit** : Yes (HTTPS, TLS 1.2+)
- **Data can be deleted** : Yes (Settings → Supprimer mon compte)
- **Follows Google Play Families Policy** : Not applicable (pas d'app enfants)
- **Independent security review** : Not at launch — ajouter plus tard si pentest fait

---

## 6. Content rating questionnaire

→ Play Console → Content rating → Launch questionnaire.

- Catégorie : Utility, Productivity, Communications or Other
- Violence : None
- Sexual content : None
- Drugs / alcohol / tobacco : None
- Crude humor : None
- Gambling : None
- Personally identifiable info : Yes (name, email, phone) — explique que c'est pour le compte et les réservations
- User-generated content : Yes (avis utilisateurs) — modérés par le salon
- Miscellaneous : App a un système de messagerie ? Non (pour l'instant).

Résultat attendu : **Everyone** / **Tout public** / **PEGI 3**.

---

## 7. Store listing — infos techniques

| Champ | Valeur |
|---|---|
| **Contact email** | support@termini-im.com |
| **Website** | https://www.termini-im.com |
| **Privacy Policy** | https://www.termini-im.com/privacy |
| **Category** | Lifestyle |
| **Tags** | Beauty, Bookings, Appointments, Salon, Barber |

---

## 8. Release track — workflow recommandé

### Phase 1 — Internal testing (immédiat, sans review Play Store)

- Release → **Internal testing** → Upload AAB
- Liste les 3-5 emails de testeurs pilotes (owners + toi-même)
- Link d'opt-in → partage via WhatsApp aux salons pilotes
- Propagation < 1h, pas de review Google
- Idéal pour phase 0 du playbook (sem 1-2)

### Phase 2 — Closed beta (sem 3-4)

- Release → **Closed testing** → crée une liste de testeurs (ou Google Group)
- Premier vrai review Google (~3-7 jours première fois)
- 20-50 testeurs max recommandé

### Phase 3 — Production (J30, lancement public)

- Release → **Production** → push même AAB ou nouveau
- Review Google 1-3 jours
- App visible dans le store mondial (ou géo-restreint Kosovo + diaspora)
- **Phased rollout recommandé** : commencer à 10% → 50% → 100% sur 1 semaine pour détecter les crashes avant qu'ils touchent tout le monde

---

## 9. Commandes utiles

```bash
# Build AAB release
flutter build appbundle --release

# Taille du bundle
ls -lh build/app/outputs/bundle/release/app-release.aab

# Vérifier le signing
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab

# Décoder l'AAB (debug)
bundletool build-apks --bundle=app-release.aab --output=app.apks
```

---

## 10. Checklist avant upload

- [ ] AAB buildé avec la bonne `version: 1.0.0+1` (pubspec.yaml)
- [ ] Signé avec `termini-im-release.jks` (vérifier via jarsigner)
- [ ] Icône 512×512 prête
- [ ] Feature graphic 1024×500 prête
- [ ] Minimum 2 screenshots portrait
- [ ] Privacy policy accessible à https://www.termini-im.com/privacy
- [ ] Terms accessible à https://www.termini-im.com/terms
- [ ] Descriptions SQ/FR/EN prêtes (copiées depuis ce doc)
- [ ] Data Safety rempli
- [ ] Content rating questionnaire complété
- [ ] Contact email `support@termini-im.com` redirige bien

Une fois tout coché → Release → Internal testing → Upload AAB → Review → Publish.
