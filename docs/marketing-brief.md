# Termini im — Brief marketing

> Document réutilisable comme contexte pour rédiger landing pages, posts réseaux sociaux, emails, ads, scripts vidéo, ou pour briefer une agence / un outil IA (skills `marketingskills`, ChatGPT, etc.).

Dernière mise à jour : 22 avril 2026.

---

## 1. Le produit en une phrase

**Termini im** est une application web + mobile de prise de rendez-vous pour salons de coiffure, barberies, manucure et esthétique, conçue spécifiquement pour le Kosovo et la diaspora albanophone.

Le nom vient de l'albanais : *termini im* = "mon rendez-vous".

---

## 2. Proposition de valeur

### Pour les **clients** (particuliers)
- **Trouver** un salon proche, adapté à leur genre (hommes / femmes / mixte), filtré par ville, date, spécialité
- **Réserver** un créneau en 30 secondes sans appeler, sans SMS, sans attente
- **Recevoir** rappels automatiques (la veille au soir + 1h avant)
- **Gérer** l'historique de ses RDV, noter les salons, les mettre en favoris
- **Partager** un salon ou un employé ("ma coiffeuse Donjeta") avec un lien direct qui pré-sélectionne la personne

### Pour les **salons** (propriétaires et employés)
- **Récupérer des RDV 24h/24** sans bloquer une personne au téléphone
- Deux modes au choix selon le type de salon :
  - **Mode individuel** (employé-based) — chaque pro a son propre planning, ses pauses, ses jours off. Parfait pour une barberie ou un salon à plusieurs coiffeurs
  - **Mode capacité** (capacity-based) — le salon définit combien de clients il peut prendre en même temps. Parfait pour un salon d'esthétique ou de manucure où plusieurs personnes travaillent en parallèle sans être "attitrées"
- **Notifications push** à chaque nouveau RDV reçu, confirmation ou annulation
- **Walk-in** intégré — un client qui passe en boutique sans RDV, l'owner crée un booking en 3 taps
- **Gestion de l'équipe** — inviter des employés, ajuster leurs services, leurs horaires
- **Galerie photo** du salon avec limite de poids + compression automatique
- **Avis clients** modérables (masquer un avis problématique)
- **Statistiques** légères (RDV du jour, taux de remplissage, avis récents)

---

## 3. Marchés cibles

### Marché primaire — Ferizaj (lancement mai 2026)
- **Ferizaj** — ~42k habitants ville, ~109k métropole. 4ᵉ ville du Kosovo, corridor industriel Prishtinë-Skopje, diaspora Suisse/Allemagne forte. ~80 à 140 salons estimés sur la ville. Pilote lancement choisi pour densité réseau personnel du fondateur (~10-25 intros chaudes).
- **Liquidité cible** : 15-20 salons actifs (≥ 15 % du marché local) avant ouverture Prishtinë.
- **Langues** : Albanais (SQ) par défaut, Français (FR) pour la diaspora Kosovo en France / Belgique / Suisse, Anglais (EN) pour l'international

### Marché d'expansion — Prishtinë (juillet 2026)
- **Prishtinë** — 1.8M habitants Kosovo total, ~250k Prishtinë. Sous-équipé en outils digitaux. Ouverture en phase M3-M4 avec la preuve sociale de Ferizaj (« 20 salons à Ferizaj, maintenant on ouvre ici »).

### Marché secondaire
- **Diaspora albanophone** — Albanais de France (~600k), Suisse, Belgique, Allemagne. Quand ils rentrent au pays l'été, ils prennent RDV via l'app
- **Macédoine du Nord, Albanie** — expansion possible une fois Kosovo stabilisé, même langue, même contexte culturel

### Pas encore ciblés
- Europe de l'Ouest (Fresha, Booksy dominent)
- Grand public non-albanophone

---

## 4. Positionnement & concurrence

### Concurrents directs
- **Fresha** (UK) — énorme, international, freemium, orienté enterprise
- **Booksy** (US) — similaire, forte présence USA + Pologne
- **SalonIQ**, **Treatwell**, **Planity** (FR) — européens

### Pourquoi Termini im gagne au Kosovo
1. **Interface en albanais** comme langue par défaut — aucun concurrent ne fait ça sérieusement
2. **Gratuité totale pour les salons** — pas de commission, pas d'abonnement. Monétisation future via features premium ou lead-gen
3. **Design éditorial** — l'app ne ressemble pas à un outil SaaS, elle ressemble à un magazine. Unique dans le secteur
4. **Local knowledge** — nom des villes en albanais (Prishtinë, Prizren, Pejë), téléphones au format +383, cas d'usage adaptés (mariages traditionnels, préparation Aïd, etc.)

### Pourquoi Termini im peut perdre
- Manque de notoriété (on démarre)
- Pas encore de preuve sociale (peu d'avis, peu de salons)
- Budget marketing limité vs Fresha qui peut payer Google Ads

---

## 5. Identité de marque — "Prishtina Editorial"

### Palette
- **Bordeaux** `#7a2232` — couleur primaire, accents, CTA
- **Or** `#c89b47` — accents secondaires, points décoratifs
- **Ivoire** `#f7f2ea` — fond principal, chaud et calme
- **Ink** `#171311` — typographie
- **Muted** `#716059` — secondaires, métadonnées
- **Bone** `#e8dcc8` — dividers, textures discrètes

### Typographie
- **Fraunces** (serif) — titres, moments éditoriaux. Variable font avec italique expressif
- **Instrument Sans** — corps, UI, boutons
- **Instrument Serif italique** — accents éditoriaux (ex: "Kosova ka shumë *stil*")

### Voix
- **Éditoriale, calme, raffinée** — l'app ressemble à un magazine de mode plutôt qu'à un SaaS
- **Personnelle** — tutoiement en FR (on dit "tu", pas "vous")
- **Ancrée localement** — références culturelles (Prishtina, mariage, Eid), sans stéréotypes
- **Minimaliste** — pas d'emoji spam, pas d'exclamations à la chaîne, pas de "SIGN UP NOW 🔥🔥🔥"

### Tagline principale
- **SQ** : "Kosova ka shumë *stil.*"
- **FR** : "Kosova a du *style.*" ou "Le Kosovo a du *style.*"
- **EN** : "Kosovo has *style.*"

### Sous-titre
- "Beauté & Style" / "Bukuri & Stil" / "Beauty & Style"

---

## 6. Features actuelles (en production)

### Utilisateurs
- Authentification email/password avec vérification par OTP 6 chiffres
- **Google login** ✅ actif en prod
- **Facebook login** ✅ actif en prod
- Apple login prévu (iOS)
- Profil modifiable (nom, téléphone, genre, langue)
- Page privacy policy éditoriale (www.termini-im.com/privacy)

### Recherche & réservation
- Liste des salons avec vignettes, rating, prochains créneaux
- Filtres : ville (search flou multi-mots), date, genre
- Fiche salon : galerie, horaires, équipe, services, avis, bouton "Partager"
- Prise de RDV en 3 étapes : choix employé → créneau → confirmation

### Côté pro
- Dashboard "Mon salon" (owner) / "Planning" (employé)
- Vue planning jour/semaine/mois avec chevauchements, pauses, jours off
- Walk-in en 3 taps
- Gestion équipe (inviter, créer un employé, assigner des services)
- Gestion horaires individuels + pauses récurrentes + jours off, avec check de conflits
- Gestion salon (infos, galerie, services, horaires)

### Notifications
- **Push FCM** fonctionnelles sur Android en prod (via Firebase)
- Notification owner : nouveau RDV, RDV annulé, walk-in
- Notification client : RDV confirmé, rappel veille, rappel 1h avant
- Préférences opt-in dans Settings
- iOS et Web en attente de configuration

### Partage
- Lien de partage d'un salon sur WhatsApp / SMS / natif
- Partage avec pré-sélection employé (`?employee=ID`)

### Contact / support
- Modal "Contacter le support" accessible depuis Settings, Mon salon, fiche salon, écrans auth, sidebar desktop
- Backend `POST /api/support-tickets` → table + email au support

---

## 7. Stack technique

- **Frontend** : Flutter (Android + iOS + Web)
- **Backend** : Laravel 11 sur Ubuntu VPS OVH (Roubaix, France)
- **DB** : MySQL
- **Auth** : Sanctum tokens + refresh, Google/Facebook OAuth
- **Push** : Firebase Cloud Messaging
- **Mail** : SMTP via Mailpit en dev, SMTP prod (à configurer)
- **Hébergement** : OVH VPS, domaines `www.termini-im.com` (app web) + `api.termini-im.com` (API)

---

## 8. Chiffres-clés

- **5 salons démo seedés** (Karim, Donjeta, Sophie, Marie, Thomas)
- **Gratuit** côté salon, côté client
- **Temps de réservation moyen** : < 30 secondes
- **3 langues** : SQ / FR / EN
- **2 modes de planning** (individuel, capacité)
- **Notifications push** : sous 2 secondes après le trigger

---

## 9. Personas

### Client : **Drita, 28 ans, Prishtina**
- Travaille en tant que consultante marketing
- Se coiffe toutes les 6 semaines chez Donjeta
- Use Instagram pour découvrir les salons, mais prend RDV par WhatsApp
- Frustration : Donjeta ne répond pas toujours, finit par aller ailleurs
- → Termini im : trouve Donjeta, voit les créneaux dispos, book en 20 sec

### Client diaspora : **Fjolla, 32 ans, Lyon**
- Rentre 2 semaines au Kosovo chaque été
- Veut se faire les cheveux dès le lendemain de l'arrivée
- Ne connaît pas personnellement les salons actuels
- → Termini im : book depuis Lyon 2 semaines avant

### Owner individual : **Karim, 45 ans, barberie Ferizaj** (pilote fondateur)
- 2 employés en plus de lui
- Gère les RDV par téléphone et calendrier papier
- Perte de temps + pas de rappels = 10-15% de no-shows
- → Termini im : plus d'appels à décrocher, rappels auto, historique client

### Client local homme : **Egzon, 26 ans, ingénieur software Ferizaj**
- Barbe et dégradé toutes les 2-3 semaines
- Travaille en télétravail, son barbier prend les RDV par téléphone entre 11h et 14h uniquement — or Egzon est souvent en meeting
- Finit par passer sans RDV et attendre 30-40 min
- → Termini im : réserve en 30 sec depuis son bureau, rappel avant de quitter l'appart, zéro appel téléphonique

### Owner capacité : **Donjeta, 34 ans, salon esthétique Prishtina**
- Salon de 4 employées, services en parallèle
- Pas d'attribution "ma cliente à moi" — les clientes prennent la première dispo
- → Termini im : mode capacité, clientes voient juste "combien de créneaux restants"

---

## 10. Messages marketing suggérés

### Hero (landing page)
- "Kosova ka shumë *stil.*"
- "Réservez votre prochain rendez-vous beauté en 30 secondes."
- CTA : "Trouver un salon"

### Pour les salons (acquisition B2B)
- "Votre téléphone sonne pendant une coupe. Plus maintenant."
- "Gratuit. Pour toujours. Sans condition."
- "Essayez pendant 14 jours — vous ne reviendrez pas au carnet papier."

### Push (notifs marketing, à utiliser avec modération)
- "Donjeta a 2 créneaux libres cet après-midi 🗓️"
- "Ton salon favori a ajouté des photos"

### Emails (onboarding)
- Sujet : "Bienvenue sur Termini im — ton premier RDV en 30 secondes"
- Ton : Tutoiement, éditorial, pas de trucs robotiques ("Dear user")

---

## 11. Non-objectifs / anti-patterns

- **Pas d'UI Silicon Valley** — pas de gradients violets, pas de neumorphism, pas de glassmorphism
- **Pas d'emojis partout** — un ou deux si justifiés, jamais de ✨🔥💯
- **Pas d'over-promising** — on ne dit pas "confirmation sous 2 minutes" (déjà retiré), on dit "dans les meilleurs délais"
- **Pas de dark patterns** — pas de toggle préselectionné pour opt-in marketing, pas de "sûr que tu veux vraiment te désabonner?" insistant
- **Pas de gamification forcée** — pas de badges, pas de niveaux, pas de streaks
- **Pas de publicité tierce** dans l'app

---

## 12. URLs & handles

- **App web** : https://www.termini-im.com
- **API** : https://api.termini-im.com
- **Privacy** : https://www.termini-im.com/privacy
- **Repo (interne)** : termini-im-apk (mobile), Lagedi (backend monorepo)
- **Support email (humain, Reply-To)** : support@termini-im.com
- **Transactionnel (From système)** : no-reply@termini-im.com (Resend, DKIM/SPF/DMARC PASS)
- **Réseaux sociaux** : à créer (Instagram @termini.im, Facebook @terminiim, TikTok @termini.im)

---

## 13. À fournir en complément

Quand tu utilises ce brief comme contexte dans un outil IA, joins aussi :

- Les screenshots clés (splash, home, fiche salon, booking, Mon salon) — dossier `flutter_*.png` à la racine
- Les mockups design (`design-proposals/*.html`)
- Les couleurs exactes (cf. section 5)
- Cette palette en format Figma / Adobe si le marketeer la demande

---

## 14. Todo marketing prioritaire

- [ ] 🔴 Créer les comptes réseaux sociaux (Instagram en premier, stories + reels)
- [ ] 🔴 Photographier 3-5 salons pilotes pour du contenu visuel authentique
- [ ] 🔴 Rédiger la landing page publique (actuellement juste l'app)
- [ ] 🟠 Onboarding pro : vidéo explicative 90 secondes
- [ ] 🟠 Press kit — palette, logo, tagline, screenshots
- [ ] 🟠 Case studies après 10 salons signés
- [ ] 🟡 Blog SEO : "Comment prendre RDV chez un coiffeur à Prishtina", "Tendances coiffure Kosovo 2026", etc.
- [ ] 🟡 Partnership influenceurs locaux (mode, beauté, lifestyle Kosovo)
