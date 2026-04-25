# Product Marketing Context

*Last updated: 2026-04-22*
*Source: `docs/marketing-brief.md`, `lib/core/theme/`, `design-proposals/LOGOS.md`*

## Product Overview
**One-liner:** Termini im — « mon rendez-vous » en albanais. Application web + mobile de réservation pour salons de coiffure, barberies, manucure et esthétique, pensée d'abord pour le Kosovo et la diaspora albanophone.

**What it does:** Les clients trouvent un salon proche (par ville, date, genre, spécialité), réservent un créneau en moins de 30 secondes, et reçoivent des rappels automatiques. Les salons récupèrent des RDV 24h/24 sans décrocher, gèrent leur équipe, leurs horaires et leurs walk-ins depuis une seule app. Deux modes de planning au choix — **individuel** (par employé) ou **capacité** (par salon) — pour couvrir aussi bien la barberie single-chair que l'institut de beauté multi-postes.

**Product category:** Logiciel de prise de rendez-vous pour professionnels de la beauté (salon booking software). Les clients nous cherchent sur des termes comme « app rendez-vous coiffeur », « aplikacion për termine », « online booking salon ».

**Product type:** SaaS multi-faces (marketplace two-sided : clients ↔ salons), disponible Flutter iOS / Android / Web.

**Business model:** Gratuit côté client ET côté salon, sans commission ni abonnement. Monétisation future envisagée via features premium (statistiques avancées, multi-site, marketing automation) ou lead-gen, jamais via commission sur RDV.

---

## Target Audience
**Target companies:** Salons indépendants 1–10 postes au Kosovo (≈ 1.8M habitants, ~250k à Prishtina) et dans la diaspora albanophone (France, Belgique, Suisse, Allemagne, Macédoine du Nord, Albanie). Cible secondaire : instituts d'esthétique, barberies urbaines, studios manucure. Aujourd'hui la plupart prennent encore RDV par téléphone ou DM Instagram.

**Ville pilote initiale (mai 2026) :** Ferizaj (~42k habitants, ville natale du fondateur, ~10-25 intros warm). Prishtinë et autres villes du Kosovo entrent en phase d'expansion à partir de juillet 2026. Les salons hors Ferizaj peuvent s'inscrire sur la waitlist dès maintenant — ils sont activés par vagues par ville.

**Decision-makers:**
- **Owner / propriétaire** (solo ou multi-employés) — choisit l'outil, porte la décision
- **Employé / coiffeur·se** — utilise l'app au quotidien, influence par le confort d'usage
- Pas de procurement formel, pas d'IT — décision rapide, émotionnelle, driven par la confiance et le bouche-à-oreille

**Primary use case:** Arrêter de gérer ses RDV au téléphone / papier / WhatsApp, et laisser les clients réserver seuls, de jour comme de nuit.

**Jobs to be done:**
- *Client* : trouver un salon de confiance proche et réserver sans avoir à appeler
- *Client diaspora* : préparer son look avant un retour au pays, depuis l'étranger
- *Owner individuel* : ne plus rater d'appels pendant une coupe, réduire les no-shows grâce aux rappels
- *Owner capacité* : exposer en temps réel les créneaux dispo sans attribuer un·e pro par cliente
- *Employé* : avoir son propre planning, ses pauses, ses jours off, sans dépendre d'un carnet partagé

**Use cases:**
- RDV récurrent toutes les 4–8 semaines chez le/la même coiffeur·se (femmes) ou 2-3 semaines chez le barbier (hommes)
- Préparation mariage traditionnel kosovar (mère + mariée + témoins + invité·es)
- Préparation Eid / rentrée scolaire — pics saisonniers, tous genres
- Walk-in : le/la client·e passe, l'owner crée un booking en 3 taps
- Partage d'un salon / d'un·e pro via WhatsApp avec pré-sélection employé (`?employee=ID`)
- Découverte par la diaspora avant un retour estival au pays (hommes et femmes)

**Important — équilibre femmes / hommes:** le marché beauté au Kosovo se répartit approximativement en 60 % coiffure/esthétique femmes et 40 % barberie/coiffure hommes. Le produit et le positionnement couvrent explicitement les deux. Ne jamais communiquer comme si c'était une app « femmes seulement ».

---

## Personas

| Persona | Cares about | Challenge | Value we promise |
|---------|-------------|-----------|------------------|
| **Drita, 28, consultante marketing, Ferizaj** (cliente locale coiffure/beauté) | Trouver sa coiffeuse de confiance, ne pas devoir rappeler 3 fois | Son salon habituel ne répond pas toujours sur WhatsApp, elle finit par aller ailleurs faute de confirmation | Voir les créneaux dispos en temps réel, réserver en 20 secondes, recevoir un rappel |
| **Egzon, 26, ingénieur software, Ferizaj** (client local barberie) | Un rasoir propre et un dégradé toutes les 2-3 semaines, sans friction | Son barbier ne prend que par téléphone entre 11h et 14h — or Egzon est en meeting ; arrive souvent sans RDV et attend 40 min | Réservation en 30 sec depuis le bureau, rappel avant de quitter l'appart, zéro appel téléphonique |
| **Fjolla, 32, diaspora Lyon** (cliente diaspora) | Se faire coiffer dès le lendemain de son arrivée chez sa famille à Ferizaj | Elle ne connaît plus personnellement les salons, ne veut pas chercher un numéro +383 | Découvrir et réserver depuis Lyon 2 semaines avant le retour, en albanais ou français |
| **Karim, 45, owner barberie, Ferizaj** (owner individuel, segment hommes, pilote fondateur) | Garder ses mains libres pendant une coupe, réduire les no-shows | Il manque 30 % de ses appels, son carnet papier est illisible, 10–15 % de no-shows | Planning digital par employé, rappels auto veille + 1h avant, notifs push à chaque nouveau RDV |
| **Donjeta, 34, salon esthétique Prishtinë** (owner capacité, segment femmes) | Exposer la capacité du salon sans attribuer de pro | Ses 4 employées travaillent en parallèle, les clientes prennent « la première dispo » | Mode capacité : le salon affiche « X créneaux restants », pas de casse-tête d'attribution |
| **Employé·e** (user secondaire, tous genres) | Avoir SON planning, ses pauses, ses off | Dans les outils SaaS classiques, tout est centralisé côté owner, l'employé n'a rien | Compte employé dédié, gestion perso des horaires et jours off, avec check de conflits |

---

## Problems & Pain Points
**Core problem:** Au Kosovo et dans la diaspora, la prise de RDV beauté reste majoritairement analogique — téléphone, SMS, DM Instagram. Côté salon, ça veut dire répondre pendant les coupes, louper des appels, tenir un carnet papier illisible, essuyer des no-shows. Côté client, ça veut dire rappeler 3 fois, attendre une confirmation qui ne vient pas, finir par essayer ailleurs.

**Why alternatives fall short:**
- **Fresha / Booksy / Treatwell / Planity** sont en anglais ou français, freemium orienté enterprise, pas d'albanais, pas de contexte local (villes, téléphones +383, cas d'usage)
- **WhatsApp / Instagram DM** : pas de planning synchronisé, pas de rappels, pas de confirmation fiable
- **Carnet papier** : illisible, perdable, pas de rappel client, pas de stats
- **Appel téléphonique** : coupe le travail en cours, loupé si le pro est sur un client, pas d'historique

**What it costs them:**
- *Salons* : 10–15 % de no-shows, RDV perdus faute de décrocher, temps passé à écrire/appeler pour confirmer
- *Clients* : 2–3 tentatives pour réserver, frustration, basculement vers un concurrent non choisi
- *Diaspora* : RDV raté au retour au pays, perte d'un moment clé (mariage, Eid, retrouvailles)

**Emotional tension:** Pour le/la pro, l'impression d'être coincé·e entre le client en fauteuil et le téléphone qui sonne. Pour le/la client·e, le doute silencieux quand le message WhatsApp n'est pas lu depuis 6h — « est-ce qu'iel m'a oublié·e ? ». Pour la diaspora, l'angoisse de rentrer au pays sans savoir si son/sa pro sera dispo.

---

## Competitive Landscape
**Direct:**
- **Fresha (UK)** — énorme, international, freemium, très orienté enterprise. Pas d'albanais, UX générique SaaS, pousse vers le paiement en ligne (encore culturellement marginal au Kosovo).
- **Booksy (US / PL)** — similaire, forte traction USA + Pologne. Pas de présence réelle au Kosovo, pas de langue locale par défaut.
- **Planity, Treatwell, SalonIQ (FR/UK)** — européens, orientés France/UK, aucun ancrage albanophone.

**Secondary:**
- **Instagram DM / WhatsApp Business** — « pas besoin d'une app, je gère par DM » — mais pas de planning, pas de rappels, pas de no-show prevention.
- **Google Forms / Google Calendar** — bricolage maison, aucun UX pour la cliente.

**Indirect:**
- **Le carnet papier et le téléphone** — habitude culturelle ancrée, « ça marche comme ça depuis toujours »
- **Le bouche-à-oreille + visite en boutique** — walk-in pur, sans réservation

**How they fall short for us:** Aucun concurrent ne fait sérieusement de l'albanais-first, aucun ne comprend les cas d'usage locaux (mariages, Eid, téléphones +383, noms de villes en SQ). Les gros SaaS facturent ou prennent commission — incompatible avec un marché où les marges sont tendues. Et surtout : leurs UI ressemblent à des outils d'entreprise, là où Termini im ressemble à un magazine.

---

## Differentiation
**Key differentiators:**
- **Albanais par défaut** (FR et EN également) — aucun concurrent sérieux ne fait ça
- **Gratuité totale, des deux côtés** — pas de commission, pas d'abonnement
- **Design éditorial « Prishtina Editorial »** — l'app ressemble à un magazine de mode, pas à un SaaS
- **Deux modes de planning natifs** (individuel vs capacité) — couvre barberie ET institut sans compromis
- **Local knowledge** : villes en albanais (Prishtinë, Prizren, Pejë), téléphones +383, mariages traditionnels, Eid, diaspora
- **Partage pré-sélectionné** : lien `?employee=ID` → le/la client·e arrive directement sur le/la pro recommandé·e

**How we do it differently:** On ne part pas d'un template SaaS américain qu'on traduit. On part du contexte culturel kosovar et de sa diaspora, et on conçoit autour. La tagline elle-même — « Kosova ka shumë *stil* » — serait impossible à copier pour un concurrent qui n'a pas ce terrain.

**Why that's better:**
- Adoption plus rapide (pas de frottement linguistique)
- Confiance immédiate (le produit « parle comme nous »)
- Marges préservées (gratuit = pas d'arbitrage économique pour le salon)
- Branding mémorable (éditorial vs. générique)

**Why customers choose us:** Parce qu'on est le seul produit qui leur ressemble. Les salons kosovars téléchargent une app qui affiche « Prishtinë » et non « Pristina », qui dit « termin » et non « appointment », qui ne leur demande pas de payer 49 €/mois pour un outil qu'ils ne maîtrisent pas.

---

## Objections

| Objection | Response |
|-----------|----------|
| « Mes client·es préfèrent m'appeler, ils/elles sont fidèles » | C'est vrai pour les fidèles. Mais les nouveaux clients, eux, abandonnent si tu ne réponds pas en 2h. Termini im capte ces 30–40 % que tu perds aujourd'hui sans t'en rendre compte. |
| « C'est trop technique pour moi / mon équipe » | L'app est conçue pour se prendre en main en 10 minutes. On invite les employés par SMS, et le walk-in se fait en 3 taps. Si tu sais utiliser Instagram, tu sais utiliser Termini im. |
| « Si c'est gratuit, c'est qu'il y a un piège / vous allez me spammer de pubs » | Non. Pas de pub tierce, jamais. La monétisation future se fera via features premium optionnelles, jamais en imposant une commission ni en vendant tes données. |
| « J'ai essayé Fresha / Booksy, c'était compliqué » | Termini im n'a pas les 200 features d'un outil enterprise. On fait 5 choses très bien : planning, réservation, rappels, walk-in, partage. C'est ça qu'un salon indépendant utilise vraiment. |
| « Pas sûr·e que mes client·es s'en servent » | Le partage WhatsApp est intégré. Tu envoies ton lien perso à ta base, ils/elles réservent depuis WhatsApp sans rien installer (web). Après 1 essai, ~80 % réservent la fois suivante via l'app. |

**Anti-persona:**
- Chaînes de salons enterprise (>10 points de vente) — Fresha / Treatwell sont mieux positionnés
- Spas haut de gamme avec paiement en ligne comme critère bloquant — pas encore notre focus
- Professionnels non-albanophones hors diaspora — ce n'est pas notre marché primaire

---

## Switching Dynamics
**Push (ce qui les éloigne du système actuel):** Téléphone qui sonne en pleine coupe. Client·es qui ne confirment pas leur RDV WhatsApp. 10–15 % de no-shows sans rappel auto. Carnet papier illisible. DM Instagram qui s'entassent.

**Pull (ce qui les attire vers Termini im):** L'app « parle albanais », elle est belle (ressent comme un magazine), elle est gratuite, et le voisin du salon d'à côté l'utilise déjà. Les rappels auto + walk-in + planning multi-employés répondent au vrai problème sans sur-ingénierie.

**Habit (ce qui les garde dans leur approche actuelle):** « Ça marche comme ça depuis toujours ». Relation personnelle avec les client·es fidèles. Peur de casser un workflow qui, même imparfait, fonctionne. Le téléphone a l'avantage de la familiarité.

**Anxiety (ce qui les inquiète à l'idée de switcher):** « Et si mes client·es ne comprennent pas ? ». « Et si je perds des RDV pendant la transition ? ». « Et si l'app plante au moment d'un mariage ? ». « Est-ce qu'on va me facturer plus tard, une fois que je suis dedans ? ».

---

## Customer Language
**How they describe the problem (verbatim, à valider lors des interviews):**
- « Nuk kam kohë me i përgjigj telefonit kur jam duke punu » *(Je n'ai pas le temps de répondre au téléphone quand je travaille)*
- « Më ka harru » *(Elle m'a oubliée)* — la cliente quand le DM reste sans réponse
- « Telefoni s'pushon me ra » *(Le téléphone arrête pas de sonner)*
- « Pse s'kanë një aplikacion si normal ? » *(Pourquoi ils ont pas une app normale ?)*

**How they describe us (à capturer après 10 salons signés) :**
- « Tash po e rezervoj vet, s'kam nevojë me thirr » *(Maintenant je réserve seule, pas besoin d'appeler)*
- « Dashtë me pa kur ka vend te Donjeta ? — hape Termini » *(Tu veux voir quand Donjeta est dispo ? — ouvre Termini)*
- À compléter au fil des témoignages réels

**Words to use:**
- *SQ* : termini im, rezervo, stil, bukuri, sallon
- *FR* : réserver, créneau, rendez-vous, stil/style, éditorial, beauté
- *EN* : book, appointment, salon, style, beauty
- Toujours **Termini im** (minuscule « im ») — jamais « TERMINI IM » en capitales espacées
- Toujours **Kosova** / **Kosovo** / **Prishtinë** (en SQ) ou **Prishtina** (en FR/EN)

**Words to avoid:**
- « Takimi » (RDV pro/business) — on parle de *termin*, RDV beauté, pas de réunion
- « Enterprise », « platform », « SaaS » côté UI client
- « Sign up now 🔥 », « game-changer », « disruptor », « seamless », « cutting-edge »
- Emoji spam (✨🔥💯) — jamais
- « Cher·e utilisateur·rice » — on tutoie en FR
- « Confirmation en X minutes » / toute promesse de SLA qu'on ne tient pas
- « Pristina » (forme serbe) — toujours « Prishtinë » en SQ, « Prishtina » en FR/EN

**Glossary:**
| Term | Meaning |
|------|---------|
| Termini im | « Mon rendez-vous » en albanais — nom de l'app |
| Termin | Rendez-vous (SQ) |
| Mode individuel | Planning par employé, chacun avec ses horaires, pauses, jours off |
| Mode capacité | Planning par salon, X créneaux simultanés, pas d'attribution individuelle |
| Walk-in | Client qui passe sans RDV, l'owner crée un booking en 3 taps |
| Owner | Propriétaire du salon (rôle app) |
| Prishtina Editorial | Nom de la direction artistique (palette bordeaux/or + Fraunces) |

---

## Brand Voice
**Tone:** Éditorial, calme, raffiné. Termini im parle comme un magazine de mode kosovar, pas comme un outil B2B américain. Posé, confiant, sans surenchère.

**Style:** Direct, tutoiement en FR (« tu », jamais « vous »). Phrases courtes, rythmées. Italiques Instrument Serif pour les accents culturels (*stil*, *style*). Références locales assumées — Prishtina, mariage, Eid — mais sans folklore caricatural.

**Personality (3–5 adjectifs):** Éditoriale, locale, confiante, chaleureuse, soignée.

**Anti-patterns (rappel):** Pas de gradients violets, pas de glassmorphism, pas d'emoji spam, pas d'exclamations à la chaîne, pas de gamification (badges/streaks/niveaux), pas de dark patterns (opt-in pré-coché, re-confirmation insistante).

### Design tokens (source : `lib/core/theme/app_colors.dart`)

| Rôle | Hex | Nom |
|------|-----|-----|
| Primary / bourgogne | `#7A2232` | Bordeaux |
| Primary light | `#9E3D4F` | |
| Primary dark | `#511522` | |
| Secondary / or | `#C89B47` | Or |
| Background | `#F7F2EA` | Sable / Ivoire |
| Surface | `#FCF7EE` | Ivoire pur |
| Ink (texte) | `#171311` | Encre |
| Ink secondaire | `#332C29` | |
| Hint | `#716059` | Muted |
| Divider | `#E8DCC8` | Os |
| Border | `#D9CAB3` | |
| Ivory alt | `#EFE6D5` | |

### Typographie
- **Fraunces** (variable serif, Google Fonts) — titres h1/h2/h3
- **Instrument Sans** — corps, UI, boutons, captions
- **Instrument Serif Italic** — wordmark « im », emphases éditoriales

### Logo & wordmark
« Termini » en Fraunces encre + « im » en Instrument Serif italique bordeaux, point bordeaux décoratif au-dessus. Kit complet dans `assets/branding/` (primary, dark, stacked, monogram ivory/ink/burgundy, favicon). Tagline toujours en Instrument Sans, letter-spacing `0.28em` pour le format « PRISHTINË · 2026 ».

---

## Proof Points
**Metrics (état actuel — à actualiser régulièrement):**
- 5 salons démo seedés (Karim, Donjeta, Sophie, Marie, Thomas) — à remplacer dès les premiers salons réels signés
- Temps moyen de réservation : < 30 secondes
- Notifications push livrées sous 2 secondes après le trigger
- 3 langues (SQ / FR / EN), 2 modes de planning
- Auth : Google + Facebook en prod, Apple prévu iOS
- Push FCM : Android en prod, iOS et Web en attente

**Customers:** Aucun témoignage public encore. **À produire en priorité** : 3–5 salons pilotes à Prishtina (mélange barberie / coiffure / esthétique) avec shooting photo + quote. Voir `docs/marketing-brief.md` §14 — priorité 🔴.

**Testimonials:**
> À collecter auprès des salons pilotes dès qu'on atteint 10 salons actifs (§14 du marketing-brief).

**Value themes:**

| Theme | Proof |
|-------|-------|
| « Gratuit, pour toujours, sans condition » | Aucune commission, aucun abonnement. Monétisation future = features premium optionnelles, jamais coupure. |
| « Pensé pour le Kosovo » | Albanais par défaut, villes en SQ, téléphones +383, cas d'usage locaux (mariage, Eid) |
| « Moins de 30 secondes pour réserver » | Flow 3 étapes : choix employé → créneau → confirmation |
| « Deux modes, un seul produit » | Mode individuel (barberie) + mode capacité (institut) nativement |
| « Rappels auto = moins de no-shows » | Rappel veille au soir + rappel 1h avant, opt-out côté cliente |
| « Design éditorial, pas SaaS » | Fraunces + Instrument Serif, palette bordeaux/or/ivoire, kit logo complet |

---

## Goals
**Business goal:** Devenir le standard de facto de la prise de RDV beauté au Kosovo d'ici fin 2027, puis étendre à la diaspora (FR, CH, BE, DE) et aux pays voisins albanophones (Macédoine du Nord, Albanie).

**Conversion action:**
- *Client (B2C):* Réserver son premier RDV → l'activation clé est le 2ᵉ RDV (preuve de rétention)
- *Salon (B2B):* Signer le salon (inscription owner + création du premier employé + premier RDV reçu)

**Current metrics (à instrumenter):**
- Salons actifs (≥ 1 RDV / semaine)
- RDV confirmés par mois
- Taux de rétention cliente à J+30 (≥ 2ᵉ RDV)
- Taux de no-show avec / sans rappel (preuve de la valeur des rappels auto)
- NPS salon, NPS client

**Prioritaires marketing (réf. `docs/marketing-brief.md` §14):**
- 🔴 Comptes réseaux sociaux (Instagram @termini.im en premier)
- 🔴 Shooting 3–5 salons pilotes pour contenu visuel authentique
- 🔴 Landing page publique `www.termini-im.com`
- 🟠 Vidéo onboarding pro 90 secondes
- 🟠 Press kit (palette, logo, tagline, screenshots)
- 🟠 Case studies après 10 salons signés
- 🟡 Blog SEO (« Comment prendre RDV chez un coiffeur à Prishtina », « Tendances coiffure Kosovo 2026 »)
- 🟡 Partenariats influenceurs mode/beauté/lifestyle Kosovo

---

## Channels & URLs
- **App web:** https://www.termini-im.com
- **API:** https://api.termini-im.com
- **Privacy:** https://www.termini-im.com/privacy
- **Support email (humain, Reply-To):** support@termini-im.com
- **Transactionnel (From système):** no-reply@termini-im.com (via Resend, DKIM/SPF/DMARC PASS)
- **Réseaux sociaux (à créer):** Instagram `@termini.im`, Facebook `@terminiim`, TikTok `@termini.im`
- **Screenshots clés:** `flutter_01.png` → `flutter_07.png` à la racine
- **Mockups design:** `design-proposals/*.html`
- **Kit logo:** `assets/branding/*.svg` + `design-proposals/LOGOS.md`
