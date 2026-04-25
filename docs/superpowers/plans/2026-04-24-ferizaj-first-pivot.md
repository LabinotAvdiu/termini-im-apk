# Ferizaj-First Pivot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Appliquer à tous les livrables marketing et au produit le pivot stratégique Ferizaj-first validé dans `docs/superpowers/specs/2026-04-24-ferizaj-first-pivot-design.md` : ville pilote = Ferizaj (15-20 salons), Prishtinë devient l'expansion phase M3-M4, protocole pilote fondateur activé dès aujourd'hui.

**Architecture :** Mise à jour séquentielle des documents in-repo (markdown + HTML éditoriaux), régénération des PDFs via Edge headless, persistance de la décision en mémoire projet, documentation des actions externes (Typeform, TestFlight, backend email). Aucun code applicatif modifié — travail 100 % documentation & configuration.

**Tech Stack :** HTML/CSS éditorial (stylesheet `docs/_shared/termini-editorial.css`), Markdown, Edge headless pour PDF, mémoire Claude dans `~/.claude/projects/C--Users-avdiu-Projetcs-hairspot-mobile/memory/`.

---

## File Structure

| Fichier | Responsabilité | Action |
|---|---|---|
| `.agents/product-marketing-context.md` | Contexte marketing produit, source pour tous les skills | Modifier (personas Ferizaj, target audience, use cases) |
| `docs/marketing-brief.md` | Brief source interne | Modifier (§3 marchés cibles, §9 personas) |
| `docs/marketing-strategy-kosovo.html` | Stratégie GTM 6 mois (éditoriale) | Modifier (phases 1 et 3, KPIs, Meta Ads geo, checklist) |
| `docs/playbook-30-jours-kosovo.html` | Playbook 30 jours paste-ready | Modifier (landing waitlist bloc pilotes, captions J4/J9/J16/J23/J27) |
| `docs/app-gaps-notifications.html` | Gaps produit + système notifications | Inspecter (pas de changement attendu) |
| `brand/v1/hero-prompts.md` | Prompts Midjourney hero | Modifier (ajout 2 prompts Ferizaj) |
| `docs/marketing-strategy-kosovo.pdf` / `playbook-30-jours-kosovo.pdf` | PDFs éditoriaux finaux | Regénérer depuis HTML |
| `~/.claude/projects/.../memory/project_termini_im_gtm.md` | Mémoire projet — décision stratégique persistante | Créer |
| `~/.claude/projects/.../memory/MEMORY.md` | Index mémoire | Modifier (nouvelle ligne) |
| `docs/superpowers/plans/2026-04-24-typeform-testflight-email.md` | Specs des actions externes que l'utilisateur doit exécuter dans les consoles SaaS | Créer |

---

## Task 1 : Updater les personas dans product-marketing-context.md

**Files:**
- Modify: `.agents/product-marketing-context.md` (table Personas lignes 52-57, section Target Audience ligne 22 environ, section Use cases lignes 33-43)

- [ ] **Step 1 : Relocaliser Drita à Ferizaj**

```
old_string: | **Drita, 28, consultante marketing, Prishtinë** (cliente locale coiffure/beauté) | Trouver sa coiffeuse de confiance, ne pas devoir rappeler 3 fois | Donjeta ne répond pas toujours sur WhatsApp, elle finit par aller ailleurs faute de confirmation | Voir les créneaux dispos en temps réel, réserver en 20 secondes, recevoir un rappel |

new_string: | **Drita, 28, consultante marketing, Ferizaj** (cliente locale coiffure/beauté) | Trouver sa coiffeuse de confiance, ne pas devoir rappeler 3 fois | Son salon habituel ne répond pas toujours sur WhatsApp, elle finit par aller ailleurs faute de confirmation | Voir les créneaux dispos en temps réel, réserver en 20 secondes, recevoir un rappel |
```

- [ ] **Step 2 : Relocaliser Egzon à Ferizaj**

```
old_string: | **Egzon, 26, ingénieur software, Prishtinë** (client local barberie)

new_string: | **Egzon, 26, ingénieur software, Ferizaj** (client local barberie)
```

- [ ] **Step 3 : Préciser Karim à Ferizaj (au lieu d'ambigu)**

```
old_string: | **Karim, 45, owner barberie** (owner individuel, segment hommes)

new_string: | **Karim, 45, owner barberie, Ferizaj** (owner individuel, segment hommes, pilote fondateur)
```

- [ ] **Step 4 : Ajouter note Ferizaj-first dans Target Audience**

Après la ligne qui commence par `**Target companies:**` dans la section Target Audience, ajouter cette note en paragraphe distinct :

```markdown
**Ville pilote initiale (mai 2026) :** Ferizaj. Prishtinë et autres villes du Kosovo entrent en phase d'expansion à partir de juillet 2026. Les salons hors Ferizaj peuvent s'inscrire sur la waitlist dès maintenant — ils sont activés par vagues par ville.
```

- [ ] **Step 5 : Vérifier que Fjolla mentionne retour au Kosovo incluant Ferizaj**

```
old_string: | **Fjolla, 32, diaspora Lyon** (cliente diaspora) | Se faire coiffer dès le lendemain de son arrivée au pays | Elle ne connaît plus personnellement les salons, ne veut pas chercher un numéro +383 | Découvrir et réserver depuis Lyon, 2 semaines avant, en albanais ou français |

new_string: | **Fjolla, 32, diaspora Lyon** (cliente diaspora) | Se faire coiffer dès le lendemain de son arrivée chez sa famille à Ferizaj | Elle ne connaît plus personnellement les salons, ne veut pas chercher un numéro +383 | Découvrir et réserver depuis Lyon 2 semaines avant le retour, en albanais ou français |
```

- [ ] **Step 6 : Vérifier qu'aucune autre mention Prishtinë ne reste problématique**

Run: rechercher `grep -n "Prishtinë" .agents/product-marketing-context.md` — Donjeta reste Prishtinë (persona forward-looking phase M3-M4), c'est attendu. Les autres occurrences (taglines, noms de villes dans le design system) sont OK.

- [ ] **Step 7 : Commit** (ne pas exécuter sans feu vert explicite — voir Task 15)

---

## Task 2 : Updater marketing-brief.md

**Files:**
- Modify: `docs/marketing-brief.md` (§3 Marchés cibles, §9 Personas)

- [ ] **Step 1 : Lire le fichier actuel pour repérer la section §3**

Run: `grep -n "## 3\. Marchés cibles" docs/marketing-brief.md`

- [ ] **Step 2 : Remplacer le bloc §3 Marché primaire**

```
old_string:
### Marché primaire
- **Kosovo** — 1.8M habitants, dont ~250k à Prishtina. Sous-équipé en outils digitaux de réservation. La grande majorité des salons prennent encore RDV par téléphone ou Instagram.
- **Langues** : Albanais (SQ) par défaut, Français (FR) pour la diaspora Kosovo en France / Belgique / Suisse, Anglais (EN) pour l'international

new_string:
### Marché primaire — Ferizaj (lancement mai 2026)
- **Ferizaj** — ~42k habitants ville, ~109k métropole. 4ᵉ ville du Kosovo, corridor industriel Prishtinë-Skopje, diaspora Suisse/Allemagne forte. ~80 à 140 salons estimés sur la ville. Pilote lancement choisi pour densité réseau personnel du fondateur (~10-25 intros chaudes).
- **Liquidité cible** : 15-20 salons actifs (≥ 15 % du marché local) avant ouverture Prishtinë.
- **Langues** : Albanais (SQ) par défaut, Français (FR) pour la diaspora Kosovo en France / Belgique / Suisse, Anglais (EN) pour l'international

### Marché d'expansion — Prishtinë (juillet 2026)
- **Prishtinë** — 1.8M habitants Kosovo total, ~250k Prishtinë. Sous-équipé en outils digitaux. Ouverture en phase M3-M4 avec la preuve sociale de Ferizaj (« 20 salons à Ferizaj, maintenant on ouvre ici »).
```

- [ ] **Step 3 : Mettre à jour §9 Owner individual (Karim explicitement Ferizaj)**

```
old_string: ### Owner individual : **Karim, 45 ans, barberie Paris**
new_string: ### Owner individual : **Karim, 45 ans, barberie Ferizaj** (pilote fondateur)
```

- [ ] **Step 4 : Ajouter sous §9 un sous-bloc Egzon**

Après le bloc Karim, ajouter :

```markdown
### Client local homme : **Egzon, 26 ans, ingénieur software Ferizaj**
- Barbe et dégradé toutes les 2-3 semaines
- Travaille en télétravail, son barbier prend les RDV par téléphone entre 11h et 14h uniquement — or Egzon est souvent en meeting
- Finit par passer sans RDV et attendre 30-40 min
- → Termini im : réserve en 30 sec depuis son bureau, rappel avant de quitter l'appart, zéro appel téléphonique
```

- [ ] **Step 5 : Commit** (ne pas exécuter sans feu vert — Task 15)

---

## Task 3 : Réécrire Phase 1 dans la stratégie (marketing-strategy-kosovo.html)

**Files:**
- Modify: `docs/marketing-strategy-kosovo.html` (lignes 737-774, bloc `.phase` « Phase 1 — Salon-first »)

- [ ] **Step 1 : Remplacer le bloc Phase 1 complet**

```
old_string:
  <div class="phase">
    <div class="phase-head">
      <h3 class="phase-name">Phase 1 — Salon-first (concierge)</h3>
      <div class="phase-meta">J0 → J90 · Terrain</div>
    </div>
    <p class="phase-goal">30 salons actifs à Prishtinë centre, ≥ 3 RDV / semaine chacun.</p>

    <h4>Le geste central : la vente de terrain par le fondateur</h4>
    <p>Pas de téléprospection, pas de forms, pas d'emails froids. Le fondateur — ou 1-2
    personnes de confiance — <strong>visite en personne 100 salons</strong> à Prishtinë
    centre sur 12 semaines. Environ 8 à 10 visites par jour utile. C'est inconfortable,
    c'est long, c'est ce qui fait la différence.</p>

new_string:
  <div class="phase">
    <div class="phase-head">
      <h3 class="phase-name">Phase 1 — Salon-first Ferizaj (concierge)</h3>
      <div class="phase-meta">J0 → J60 · Terrain</div>
    </div>
    <p class="phase-goal">15-20 salons actifs à Ferizaj, ≥ 3 RDV / semaine chacun. Dont 5-8 pilotes fondateurs déjà actifs avant le launch public.</p>

    <h4>Pourquoi Ferizaj et pas Prishtinë</h4>
    <p>Avantage déloyal du fondateur : <strong>10 à 25 intros warm à Ferizaj</strong> (ville natale) contre 1 seule à Prishtinë. Playbook marketplace classique — on démarre où on a le réseau, pas où on voudrait être. Taille marché Ferizaj ~80-140 salons : viser 15-20 pilotes = 15-20 % de saturation locale, on devient le standard de facto vite. Prishtinë ouvre en phase M3-M4 avec la preuve sociale de Ferizaj.</p>

    <h4>Le geste central : la vente de terrain par le fondateur</h4>
    <p>Pas de téléprospection, pas de forms, pas d'emails froids. Le fondateur — ou 1-2
    personnes de confiance — <strong>visite en personne 40 à 60 salons</strong> à Ferizaj
    sur 8 semaines, priorité aux intros warm via réseau familial. 6 à 8 visites par jour utile.</p>

    <h4>Protocole pilote fondateur (pré-launch)</h4>
    <p>Un salon warm qui veut signer <em>avant</em> mai n'est jamais éconduit. On l'onboarde dans un track privé, cap à 5-8 pilotes fondateurs. Ils ont accès à une bêta TestFlight/Internal Testing, ligne directe fondateur 6 mois, badge « Pilot Themelues » à vie dans la galerie permanente de l'app. Pas de communication publique avant le 15 avril. Voir le spec §« Protocole pilote fondateur » pour le détail.</p>
```

- [ ] **Step 2 : Remplacer le bloc KPIs de sortie phase 1**

```
old_string:
    <h4>KPIs de sortie de phase</h4>
    <ul class="tight">
      <li>30 salons actifs (critère strict : ≥ 3 RDV/semaine confirmés via l'app)</li>
      <li>Photographie propre livrée pour chaque salon</li>
      <li>100 % des salons pilotes ont partagé leur lien avec leur base WhatsApp</li>
      <li>500+ RDV cumulés confirmés via l'app</li>
    </ul>
  </div>

  <div class="phase">
    <div class="phase-head">
      <h3 class="phase-name">Phase 2 — Activation clientèle via les salons</h3>

new_string:
    <h4>KPIs de sortie de phase (J60)</h4>
    <ul class="tight">
      <li><strong>15-20 salons actifs à Ferizaj</strong> (critère strict : ≥ 3 RDV/semaine confirmés via l'app)</li>
      <li>Saturation marché local ≥ 15 % des salons de Ferizaj</li>
      <li>Photographie propre livrée pour chaque salon</li>
      <li>100 % des salons pilotes ont partagé leur lien avec leur base WhatsApp</li>
      <li>500+ RDV cumulés confirmés via l'app</li>
      <li>≥ 3 pilotes fondateurs encore actifs (signaux de succès pour le narratif « Ne filluam me ta »)</li>
    </ul>
  </div>

  <div class="phase">
    <div class="phase-head">
      <h3 class="phase-name">Phase 2 — Activation clientèle via les salons</h3>
```

---

## Task 4 : Réécrire Phase 3 de la stratégie (ajout Prishtinë activation)

**Files:**
- Modify: `docs/marketing-strategy-kosovo.html` (lignes ~807-831, bloc « Phase 3 — Lancement public »)

- [ ] **Step 1 : Remplacer le bloc Phase 3**

```
old_string:
      <h3 class="phase-name">Phase 3 — Lancement public</h3>
      <div class="phase-meta">J90 → J180 · Scale</div>
    </div>
    <p class="phase-goal">100 salons actifs. Présence à Prizren et Pejë.</p>

    <h4>Actions</h4>
    <ul>
      <li><strong>Campagne de lancement PR locale</strong> : Telegrafi, Koha, Kosovarja, Kosovo 2.0. Angle : « Une app kosovare pour remplacer le téléphone ».</li>
      <li>Premier partenariat <strong>macro-influenceur</strong> (Adelina Tahiri, Era Istrefi ou équivalent) — 1 à 2 posts sponsorisés, ~1 500 € à 2 500 €.</li>
      <li>Budget <strong>Meta Ads : 2 000 €/mois</strong>, <strong>TikTok Ads : 300 €/mois</strong>, <strong>Google Search : 200 €/mois</strong>.</li>
      <li>Réplication du playbook Phase 1 à <strong>Prizren</strong> (3 semaines concierge, 15 salons pilotes).</li>
      <li>Puis à <strong>Pejë</strong> (3 semaines, 10 salons).</li>
      <li>Premier <strong>événement physique « Termini Night »</strong> : un bar de Prishtinë, 30 salons pilotes + 5 influenceurs + presse. Shooting live, story coverage massive.</li>
    </ul>

new_string:
      <h3 class="phase-name">Phase 3 — Activation Prishtinë + expansion</h3>
      <div class="phase-meta">J60 → J150 · Scale</div>
    </div>
    <p class="phase-goal">30 salons actifs à Prishtinë + 20 actifs Ferizaj. Présence à Prizren et Pejë amorcée.</p>

    <h4>Actions</h4>
    <ul>
      <li><strong>Ouverture concierge Prishtinë</strong> — réplication du playbook Phase 1, mais cette fois avec la preuve sociale de Ferizaj (« 20 salons nous font confiance à Ferizaj, vous êtes les prochains »). 8 semaines, objectif 30 salons actifs.</li>
      <li><strong>Campagne de lancement PR locale</strong> : Telegrafi, Koha, Kosovarja, Kosovo 2.0. Angle éditorial : « Nga Ferizaj, për tërë Kosovën — une app kosovare pour remplacer le téléphone ».</li>
      <li>Premier partenariat <strong>macro-influenceur</strong> (Adelina Tahiri, Era Istrefi ou équivalent) — 1 à 2 posts sponsorisés, ~1 500 € à 2 500 €.</li>
      <li>Budget <strong>Meta Ads : 2 000 €/mois</strong> (60 % Prishtinë acquisition, 40 % Ferizaj rétention), <strong>TikTok Ads : 300 €/mois</strong>, <strong>Google Search : 200 €/mois</strong>.</li>
      <li>Préparation <strong>Prizren + Pejë</strong> (concierge mi-phase, à finaliser en phase 4).</li>
      <li>Premier <strong>événement physique « Termini Night »</strong> : un bar de Prishtinë, pilotes Ferizaj + premiers pilotes Prishtinë + influenceurs + presse. Narratif « on est venus de Ferizaj vous trouver ».</li>
    </ul>
```

- [ ] **Step 2 : Mettre à jour le bloc KPIs Phase 3**

```
old_string:
      <li>100 salons actifs (Prishtinë + Prizren + Pejë)</li>
      <li>15 000 clients actifs mensuels (tous genres)</li>
      <li>30 000 RDV / mois</li>
      <li>NPS salon ≥ 45, NPS client ≥ 60</li>

new_string:
      <li>50 salons actifs (Ferizaj consolidé + Prishtinë lancé)</li>
      <li>8 000 clients actifs mensuels (tous genres)</li>
      <li>10 000 RDV / mois cumulés</li>
      <li>NPS salon ≥ 45, NPS client ≥ 60</li>
      <li>Prizren + Pejë : au moins 5 pilotes signés chacun, ouverture officielle dans phase 4</li>
```

---

## Task 5 : Updater les mentions « Prishtinë centre » dans intro et règle d'or

**Files:**
- Modify: `docs/marketing-strategy-kosovo.html` (plusieurs mentions « Prishtinë centre » et « 30 salons » dans sections intro, chicken-and-egg, règle d'or)

- [ ] **Step 1 : Updater l'intro (callout doré)**

```
old_string:
      Gagner le Kosovo ne se fait pas en une campagne nationale. Ça se fait <strong>quartier par
      quartier, salon par salon</strong>. La bonne séquence : concentrer toute l'énergie sur
      <strong>Prishtinë centre</strong>, atteindre la liquidité locale (30 salons actifs, 3 RDV
      par semaine chacun), <em>puis</em> seulement ouvrir les vannes publicitaires.

new_string:
      Gagner le Kosovo ne se fait pas en une campagne nationale. Ça se fait <strong>ville par
      ville, salon par salon</strong>. La bonne séquence : concentrer toute l'énergie sur
      <strong>Ferizaj</strong> (ville natale du fondateur, 10-25 intros warm), atteindre la liquidité locale
      (15-20 salons actifs, 3 RDV par semaine chacun), <em>puis</em> basculer sur Prishtinë avec la
      preuve sociale de Ferizaj en main.
```

- [ ] **Step 2 : Updater les 4 règles marketplace**

```
old_string:
    <li><strong>Restreindre la géographie à l'absurde.</strong> Pas « Kosovo », pas même
    « Prishtinë », mais <em>Prishtinë centre</em> — 2 km² autour du boulevard Nënë Tereza.</li>
    <li><strong>Viser la liquidité locale avant tout.</strong> 30 salons actifs, chacun
    recevant ≥ 3 RDV par semaine via l'app. C'est notre seuil <em>go / no-go</em> avant
    le lancement public.</li>

new_string:
    <li><strong>Restreindre la géographie à l'absurde.</strong> Pas « Kosovo », pas « toutes les grandes villes », mais
    <em>Ferizaj d'abord</em> — ville de ~42k où le fondateur a son réseau warm.</li>
    <li><strong>Viser la liquidité locale avant tout.</strong> 15-20 salons actifs à Ferizaj, chacun
    recevant ≥ 3 RDV par semaine via l'app. C'est notre seuil <em>go / no-go</em> avant
    d'ouvrir Prishtinë et les autres villes.</li>
```

- [ ] **Step 3 : Updater la règle d'or (callout sombre)**

```
old_string:
      <strong>Aucune dépense publicitaire avant d'avoir 30 salons actifs.</strong>
      Attirer des clients sur une app semi-vide est le moyen le plus rapide de
      cramer sa marque. On paye pour du trafic <em>uniquement</em> quand chaque
      cliente qui arrive trouve au moins 5 salons pertinents à côté de chez elle.

new_string:
      <strong>Aucune dépense publicitaire avant d'avoir 15 salons actifs à Ferizaj.</strong>
      Attirer des clients sur une app semi-vide est le moyen le plus rapide de
      cramer sa marque. On paye pour du trafic <em>uniquement</em> quand chaque
      client·e qui arrive à Ferizaj trouve au moins 5 salons pertinents à côté de chez iel.
```

- [ ] **Step 4 : Updater la mention « phase 1 (30 salons) » en §6 Ads**

```
old_string: phase 1 (30 salons actifs) n'est pas bouclée. Ensuite on monte progressivement

new_string: phase 1 (15-20 salons actifs à Ferizaj) n'est pas bouclée. Ensuite on monte progressivement
```

---

## Task 6 : Updater géo-ciblage Meta Ads (section 6)

**Files:**
- Modify: `docs/marketing-strategy-kosovo.html` (section 6 Meta Ads — principe ciblage)

- [ ] **Step 1 : Ajouter un bloc note « géo-ciblage phasé » juste après le callout « Principe de ciblage : par service, pas par genre »**

Trouver dans le HTML le bloc `.callout` qui contient « Principe de ciblage : par service, pas par genre » et insérer *juste après* sa fermeture `</div>` :

```html
  <div class="callout gold">
    <h4>Géo-ciblage phasé par ville</h4>
    <p style="margin:0;">
      <strong>Phase 2 (M1-M2)</strong> : Meta Ads géo-ciblés sur <strong>Ferizaj uniquement</strong>, radius 15-20 km autour du centre-ville. Budget 600 €/mois.
      <strong>Phase 3 (M3-M4)</strong> : ouverture Prishtinë, budget réparti 60 % Prishtinë acquisition / 40 % Ferizaj rétention.
      <strong>Phase 4 (M5-M6)</strong> : Prizren + Pejë + diaspora Europe.
    </p>
  </div>
```

---

## Task 7 : Updater checklist lancement dans stratégie

**Files:**
- Modify: `docs/marketing-strategy-kosovo.html` (checklist finale)

- [ ] **Step 1 : Updater liste de salons cibles**

```
old_string: <li>Liste de 100 salons cibles à Prishtinë centre (feuille Airtable)</li>
new_string: <li>Liste de 60 salons cibles à Ferizaj (feuille Airtable, priorité : intros warm du fondateur)</li>
```

- [ ] **Step 2 : Updater seuil go/no-go fin de phase 1**

```
old_string: <li>Go / no-go de fin de phase 1 formellement écrit — seuil : 30 salons actifs</li>
new_string: <li>Go / no-go de fin de phase 1 formellement écrit — seuil : 15-20 salons actifs à Ferizaj + ≥ 3 pilotes fondateurs actifs</li>
```

---

## Task 8 : Updater bloc pilotes et FAQ dans le playbook (landing waitlist)

**Files:**
- Modify: `docs/playbook-30-jours-kosovo.html` (section 4 « Landing page Coming soon » — bloc pilotes, FAQ, puces structure)

- [ ] **Step 1 : Updater la puce « Pilotes wanted » dans la structure de page**

```
old_string: <li><strong>Pilotes wanted</strong> — « Kërkojmë 30 sallone pilot në Prishtinë. Je je sallon? Regjistrohu — fotot janë falas. » + CTA Typeform</li>

new_string: <li><strong>Pilotes wanted</strong> — « Kërkojmë 15 sallone pilot në Ferizaj — maji 2026. Qytete tjera: regjistrohu, vjen radha juaj. » + CTA Typeform avec champ ville obligatoire</li>
```

- [ ] **Step 2 : Remplacer le bloc pilotes complet**

```
old_string:
  <h4>Bloc pilotes</h4>
  <div class="callout gold">
    <p style="font-family:'Fraunces',serif; font-size: 13pt; margin: 0 0 3mm;">
      Kërkojmë <strong>30 sallone pilot</strong> në Prishtinë.
    </p>
    <p style="margin: 0 0 3mm;">
      Sesioni fotografik profesional — falas. Konfigurimi i sallonit — bëjmë ne. Badge « Pilot Termini im » — në vitrinën tënde dhe në bio Instagram. Komision — kurrë.
    </p>
    <p class="note" style="margin:0;">FR · Nous cherchons 30 salons pilotes à Prishtinë. Shooting photo pro — gratuit. Configuration du salon — on la fait pour toi. Badge « Pilote Termini im » — sur ta vitrine et dans ta bio Instagram. Commission — jamais.</p>
  </div>

new_string:
  <h4>Bloc pilotes</h4>
  <div class="callout gold">
    <p style="font-family:'Fraunces',serif; font-size: 13pt; margin: 0 0 3mm;">
      Kërkojmë <strong>15 sallone pilot në Ferizaj</strong> — maji 2026.
    </p>
    <p style="margin: 0 0 3mm;">
      Sesioni fotografik profesional — falas. Konfigurimi i sallonit — bëjmë ne. Badge « Pilot Termini im » — në vitrinën tënde dhe në bio Instagram. Komision — kurrë.
    </p>
    <p style="margin: 0 0 3mm;">
      <strong>Je nga qytet tjetër?</strong> Regjistrohu. Prishtinën e hapim në korrik. Prizren, Pejë — pas.
    </p>
    <p class="note" style="margin:0;">FR · Nous cherchons 15 salons pilotes à Ferizaj — mai 2026. Shooting photo pro — gratuit. Configuration du salon — on la fait pour toi. Badge « Pilote Termini im » — sur ta vitrine et dans ta bio Instagram. Commission — jamais. Tu es d'une autre ville ? Inscris-toi. On ouvre Prishtinë en juillet, puis Prizren et Pejë.</p>
  </div>
```

- [ ] **Step 3 : Updater la FAQ (question « Kur lansohet »)**

```
old_string:
        <td><strong>Kur lansohet?</strong></td>
        <td>Maji 2026. Regjistrohu për të qenë i pari/e para.</td>

new_string:
        <td><strong>Kur lansohet?</strong></td>
        <td>Ferizaj — maji 2026. Prishtinë — korriku 2026. Qytete tjera pas. Regjistrohu për të qenë i pari/e para në qytetin tënd.</td>
```

- [ ] **Step 4 : Ajouter dans section 4 checklist technique une ligne sur le champ ville Typeform**

Dans la sous-section « Checklist technique » de la landing page, ajouter à la liste `<ul class="check">` :

```html
    <li>Formulaire Typeform salon contient un champ obligatoire <code>qyteti</code> (Ferizaj / Prishtinë / Prizren / Pejë / Gjakovë / Mitrovicë / Gjilan / Tjetër) et un champ « Tu veux commencer quand ? » (Tash / Te lansimi)</li>
```

---

## Task 9 : Updater les captions du calendrier 30 jours dans le playbook

**Files:**
- Modify: `docs/playbook-30-jours-kosovo.html` (day cards J4, J9, J16, J23, J27)

- [ ] **Step 1 : Updater le post J4 (ajout slide Ferizaj)**

Trouver le day card `<div class="day-num">J4</div>` et updater le day-val « Format » :

```
old_string: <div class="day-val">Carrousel 5 slides éditoriales (4:5). Slide 1 : « Diçka po vjen. » (Quelque chose arrive). Slides 2-4 : images teaser beauté Prishtinë. Slide 5 : « Nga maji. <em>Termini im.</em> »</div>

new_string: <div class="day-val">Carrousel 5 slides éditoriales (4:5). Slide 1 : « Diçka po vjen. » (Quelque chose arrive). Slides 2-3 : images teaser beauté (mix Ferizaj + mood Kosovo). Slide 4 : « Fillojmë nga <em>Ferizaj.</em> » (On commence par Ferizaj). Slide 5 : « Nga maji. <em>Termini im.</em> »</div>
```

- [ ] **Step 2 : Updater le script FR de l'interview fondateur J9**

```
old_string:
    <div class="day-row"><div class="day-label">Script FR</div><div class="day-val copy">« Je m'appelle Labinot. Je construis Termini im parce que ma mère et ma sœur prennent encore RDV chez le coiffeur par WhatsApp, et que la moitié du temps le salon ne répond pas. Ça n'a aucun sens en 2026. Termini im sera gratuit — pour toujours. Et on démarre à Prishtinë. »</div></div>

new_string:
    <div class="day-row"><div class="day-label">Script FR</div><div class="day-val copy">« Je m'appelle Labinot. Je construis Termini im parce que ma mère et ma sœur prennent encore RDV chez le coiffeur par WhatsApp, et que la moitié du temps le salon ne répond pas. Ça n'a aucun sens en 2026. Termini im sera gratuit — pour toujours. Et on démarre à <strong>Ferizaj</strong>, ma ville natale, avec les salons qui m'ont vu grandir. Prishtinë ensuite, puis tout le Kosovo. »</div></div>
```

- [ ] **Step 3 : Updater le post éditorial J16 « Prishtinë, capitale du stil »**

Trouver le day card J16. Updater titre et caption :

```
old_string:
      <div class="day-title">Éditorial — « Prishtinë, capitale du stil »</div>

new_string:
      <div class="day-title">Éditorial — « Kosova ka shumë stil, fillojmë nga Ferizaj »</div>
```

Et la caption FR du même jour :

```
old_string: <div class="day-val caption-fr">Il suffit de regarder — Prishtinë a toujours été une capitale du <em>stil.</em> On la sert simplement mieux.</div>

new_string: <div class="day-val caption-fr">Il suffit de regarder — le Kosovo a toujours eu du <em>stil.</em> On commence à Ferizaj, ma ville. Prishtinë en juillet. Tout le Kosovo ensuite.</div>
```

Et le prompt IA :

```
old_string: <div class="day-val prompt">[base prompt §6] + "street photography of young Kosovar fashion, Mother Teresa boulevard, cappuccino on marble table, warm late afternoon, --ar 4:5"</div>

new_string: <div class="day-val prompt">[base prompt §6] + "street photography in Ferizaj town center, young Kosovar fashion, cappuccino on marble table, traditional Ottoman architecture blurred in background, warm late afternoon light, --ar 4:5"</div>
```

- [ ] **Step 4 : Updater l'exemple de caption J23 (portrait owner pilote)**

```
old_string: <div class="day-val copy">« Arbnora, 12 ans de métier à Dragodan. Elle est le 3ᵉ salon pilote de <em>Termini im.</em> Tu veux être le 4ᵉ ? Lien en bio. »</div>

new_string: <div class="day-val copy">« [Nom owner], [N] ans de métier à Ferizaj. Iel est le 3ᵉ pilote fondateur de <em>Termini im.</em> Tu veux être le 4ᵉ ? Lien en bio. » <em>[Remplacer [Nom owner] et [N] par le pilote fondateur réel une fois signé.]</em></div>
```

- [ ] **Step 5 : Updater J24 et J27 (révélation 5 salons — Ferizaj)**

```
old_string: <div class="day-val">3 stories : (1) « 5 sallone, të gjitha në Prishtinë, të gjitha <em>pilot.</em> » (2) 5 logos fondus + noms (si autorisés). (3) Sticker « Dua të provoj » → lien waitlist.</div>

new_string: <div class="day-val">3 stories : (1) « 5 sallone, të gjitha në Ferizaj, të gjitha <em>pilot themelues.</em> » (2) 5 logos fondus + noms (si autorisés). (3) Sticker « Dua të provoj » → lien waitlist.</div>
```

Et J27 :

```
old_string: <div class="day-val">Post carrousel 6 slides. Slide 1 : « <em>I paraqesim 5 e parët.</em> » (On te présente les 5 premiers.) Slides 2-6 : un salon par slide avec photo pro, nom, quartier, spécialité. Story identique.</div>

new_string: <div class="day-val">Post carrousel 6 slides. Slide 1 : « <em>I paraqesim 5 e parët te Ferizaj.</em> » (On te présente les 5 premiers de Ferizaj.) Slides 2-6 : un salon par slide avec photo pro, nom, quartier de Ferizaj, spécialité. Story identique.</div>
```

Et la caption FR de J27 :

```
old_string: <div class="day-val copy">Cinq salons. Cinq univers. Cinq confiances qu'on n'oubliera pas d'avoir gagnées en premier. À Prishtinë. <em>Termini im</em> — dans 3 jours.</div>

new_string: <div class="day-val copy">Cinq salons. Cinq univers. Cinq confiances qu'on n'oubliera pas d'avoir gagnées en premier. À Ferizaj — ma ville. <em>Termini im</em> — dans 3 jours.</div>
```

- [ ] **Step 6 : Updater J30 caption finale**

```
old_string: <div class="day-val copy">On y est. 5 salons à Prishtinë. Une app qui marche sur iOS, Android et web. Zéro commission, gratuite pour toujours, en albanais en premier.<br /><br />Télécharge. Réserve. Dis-nous ce qu'il faut améliorer.<br /><br /><em>Termini im. Prishtinë. 2026.</em></div>

new_string: <div class="day-val copy">On y est. 5 salons à Ferizaj. Une app qui marche sur iOS, Android et web. Zéro commission, gratuite pour toujours, en albanais en premier.<br /><br />Télécharge. Réserve. Dis-nous ce qu'il faut améliorer.<br /><br /><em>Nga Ferizaj, për tërë Kosovën. Termini im. 2026.</em></div>
```

---

## Task 10 : Ajouter 2 prompts Ferizaj dans brand/v1/hero-prompts.md

**Files:**
- Modify: `brand/v1/hero-prompts.md` (ajout section « Prompts bonus · Ferizaj »)

- [ ] **Step 1 : Ajouter 2 nouveaux prompts à la fin du fichier avant la section « Extensions possibles »**

Trouver le titre `## Extensions possibles (si tu veux + d'images)` et insérer *avant* :

```markdown
---

## Prompts bonus · Ferizaj (ville pilote)

Deux prompts supplémentaires pour signaler visuellement que le lancement démarre à Ferizaj. À utiliser dans les posts J4 (carousel « Quelque chose arrive »), J16 (éditorial « Kosova ka shumë stil, fillojmë nga Ferizaj »), et J24-J27 (révélation salons pilotes).

### Prompt 7 — Mood opener · Ferizaj

**Usage** : post J4 slide « Fillojmë nga Ferizaj », ou éditorial J16.

```
editorial photography, soft late afternoon light in Ferizaj town center,
Balkan Ottoman-era architecture in the background (clock tower silhouette),
a narrow cobblestone lane with a vintage barber pole in foreground,
warm terracotta walls, muted burgundy awning, brass café chair detail,
35mm film grain, Kinfolk magazine aesthetic, minimal composition,
no text no logo, no people clearly visible --ar 4:5 --style raw --s 250
```

### Prompt 8 — Le commerce local Ferizaj

**Usage** : portrait d'une rue marchande, à associer à un propos genre « Tes voisins vont ici. Toi aussi. »

```
editorial photography, soft morning light on a Ferizaj commercial street,
a row of small shopfronts with aged metal rolling shutters half-open,
a hand-painted salon sign in subtle burgundy, brass door handle catching light,
linen curtain behind the glass, slow life mood, 35mm film grain,
Kinfolk aesthetic, no text on the sign visible clearly, no people faces,
--ar 4:5 --style raw --s 250
```
```

---

## Task 11 : Vérifier app-gaps-notifications.html

**Files:**
- Inspect: `docs/app-gaps-notifications.html` (recherche d'implications Prishtinë-only)

- [ ] **Step 1 : Grep pour détecter mentions Prishtinë spécifiques**

Run: `grep -n "Prishtinë" docs/app-gaps-notifications.html`
Expected: les mentions Prishtinë doivent être uniquement dans les descriptions génériques ou neutres (palette, éditorial, descriptions stores). Aucune référence à « Prishtinë uniquement » ou « lancement Prishtinë ».

- [ ] **Step 2 : Si des mentions problématiques existent, les consigner pour revue**

Si le grep révèle des mentions du genre « ville pilote : Prishtinë » ou « lancement à Prishtinë » dans ce doc, les mettre en commentaire ici dans le plan et demander revue utilisateur. Sinon, aucune action.

---

## Task 12 : Régénérer les PDFs

**Files:**
- Overwrite: `docs/marketing-strategy-kosovo.pdf`
- Overwrite: `docs/playbook-30-jours-kosovo.pdf`
- Overwrite: `docs/app-gaps-notifications.pdf` (si modifié en Task 11)

- [ ] **Step 1 : Regénérer la stratégie**

```bash
"/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" --headless --disable-gpu --no-pdf-header-footer --virtual-time-budget=20000 --print-to-pdf="C:/Users/avdiu/Projetcs/hairspot_mobile/docs/marketing-strategy-kosovo.pdf" "file:///C:/Users/avdiu/Projetcs/hairspot_mobile/docs/marketing-strategy-kosovo.html"
```
Expected : « N bytes written to file … marketing-strategy-kosovo.pdf »

- [ ] **Step 2 : Regénérer le playbook**

```bash
"/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" --headless --disable-gpu --no-pdf-header-footer --virtual-time-budget=20000 --print-to-pdf="C:/Users/avdiu/Projetcs/hairspot_mobile/docs/playbook-30-jours-kosovo.pdf" "file:///C:/Users/avdiu/Projetcs/hairspot_mobile/docs/playbook-30-jours-kosovo.html"
```
Expected : « N bytes written to file … playbook-30-jours-kosovo.pdf »

- [ ] **Step 3 : Regénérer app-gaps (seulement si modifié)**

```bash
"/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" --headless --disable-gpu --no-pdf-header-footer --virtual-time-budget=20000 --print-to-pdf="C:/Users/avdiu/Projetcs/hairspot_mobile/docs/app-gaps-notifications.pdf" "file:///C:/Users/avdiu/Projetcs/hairspot_mobile/docs/app-gaps-notifications.html"
```

- [ ] **Step 4 : Vérifier les tailles des fichiers PDFs**

Run: `ls -la docs/*.pdf`
Expected : 3 fichiers PDF avec tailles similaires aux précédentes (~1-2 Mo chacun).

---

## Task 13 : Créer la mémoire projet GTM

**Files:**
- Create: `C:/Users/avdiu/.claude/projects/C--Users-avdiu-Projetcs-hairspot-mobile/memory/project_termini_im_gtm.md`
- Modify: `C:/Users/avdiu/.claude/projects/C--Users-avdiu-Projetcs-hairspot-mobile/memory/MEMORY.md` (ajout ligne index)

- [ ] **Step 1 : Créer le fichier mémoire**

Contenu complet du fichier :

```markdown
---
name: Termini im — stratégie GTM Ferizaj-first
description: Pivot décidé le 2026-04-24 — lancement Ferizaj (ville natale du fondateur) avant Prishtinë, liquidité 15-20 salons puis expansion
type: project
---

Stratégie Go-To-Market Termini im décidée le 2026-04-24 (voir spec `docs/superpowers/specs/2026-04-24-ferizaj-first-pivot-design.md`).

**Décision :** lancement à Ferizaj (ville natale du fondateur), pas Prishtinë. Pas de lancement parallèle.

**Pourquoi :** le fondateur a 10-25 intros chaudes à Ferizaj contre 1 seule à Prishtinë. En vente concierge solo, le ratio warm/cold change tout. Ferizaj ~80-140 salons estimés → viser 15-20 pilotes = 15-20 % saturation locale. Prishtinë arrive en phase M3-M4 avec la preuve sociale de Ferizaj en main.

**Séquencement :**
- M0 (J-30 → J0) : pré-launch nationale + focus Ferizaj
- M1-M2 (J0 → J60) : concierge Ferizaj, objectif 15-20 salons actifs
- M3-M4 (J60 → J120) : ouverture Prishtinë avec preuve Ferizaj
- M5-M6 (J120 → J180) : Prizren, Pejë, diaspora

**Protocole pilote fondateur :** un salon warm qui veut signer avant mai n'est jamais éconduit. Track privé, cap à 5-8 salons, badge « Pilot Themelues » à vie, ligne directe fondateur 6 mois. TestFlight + Internal Testing bêta privée avant le launch public J30.

**État DB au moment du pivot :** vide de users réels (seulement des données de test créées par le fondateur). Purge clean prévue avant launch.

**How to apply :** toute communication publique, landing page, copy waitlist, captions social, ads doivent refléter Ferizaj-first. Les salons hors Ferizaj s'inscrivent sur waitlist multi-vagues (Ferizaj = wave 1, Prishtinë = wave 2, etc.). Personas Drita et Egzon sont à Ferizaj. Karim (barberie) est un pilote fondateur Ferizaj. Donjeta reste Prishtinë comme persona forward-looking phase M3-M4. Direction artistique « Prishtina Editorial » inchangée (c'est le nom d'un style, pas d'un lieu d'opération).
```

- [ ] **Step 2 : Ajouter une ligne dans MEMORY.md**

```
old_string: - [Inclusivity genre (Termini im)](feedback_inclusivity_gender.md) — Marketing comm must cover men AND women explicitly; never position as women-only

new_string: - [Inclusivity genre (Termini im)](feedback_inclusivity_gender.md) — Marketing comm must cover men AND women explicitly; never position as women-only
- [Termini im GTM](project_termini_im_gtm.md) — Ferizaj-first launch (not Prishtinë); 15-20 pilot salons in Ferizaj, Prishtinë in M3-M4 with Ferizaj proof
```

---

## Task 14 : Documenter les actions externes (Typeform / TestFlight / Email)

**Files:**
- Create: `docs/superpowers/plans/2026-04-24-external-actions.md`

- [ ] **Step 1 : Créer le doc avec specs exécutables pour les 3 actions hors-repo**

Contenu complet :

````markdown
# Actions externes — Ferizaj pivot (2026-04-24)

Ce document liste les actions que l'utilisateur doit exécuter manuellement dans des consoles SaaS ou des repos tiers.

## 1. Typeform / Tally — salon candidature

**Objectif :** que le formulaire salon capture la ville et la fenêtre d'activation souhaitée.

**Champs à ajouter / modifier :**

| Champ | Type | Obligatoire | Options |
|---|---|---|---|
| `qyteti` | Dropdown | Oui | Ferizaj, Prishtinë, Prizren, Pejë, Gjakovë, Mitrovicë, Gjilan, Tjetër (préciser) |
| `kur_dëshiron_të_fillosh` | Radio | Oui | « Tash — sa më shpejt » (maintenant, flag pilote fondateur) / « Te lansimi i majit » (au launch public) |
| `si_dëgjove_për_ne` | Text court | Non | Optional, pour tracking organic/referral |

**Logic côté Airtable / Google Sheets :**
- Si `qyteti = Ferizaj` ET `kur = Tash` → tag « PILOTE_FONDATEUR_CANDIDATE », alerter fondateur par email immédiat
- Si `qyteti = Ferizaj` ET `kur = Mai` → tag « WAVE_1 »
- Si `qyteti != Ferizaj` → tag `WAVE_<Prishtinë|Prizren|...>` + email auto de wave 2+

**Email auto à envoyer si ville != Ferizaj** (via Zapier ou natif Typeform) :

```
Sujet : Faleminderit — të shohim në wave 2

Salloni yt është regjistruar. Ne lansojmë me 15 sallone
pilot në Ferizaj në maj. Prishtinën e hapim në korrik.

Do të të shkruajmë drejtpërdrejt kur të vijë radha e qytetit tënd.

— Labinot, Termini im
```

## 2. TestFlight + Google Play Internal Testing

**Objectif :** avoir une track bêta privée disponible pour les pilotes fondateurs avant le launch public J30.

**iOS (TestFlight) :**
1. Build iOS de test prêt (avec Apple Sign-In déjà câblé — cf. Task 2 du doc app-gaps-notifications)
2. Dans App Store Connect → TestFlight → créer un groupe **« Pilot Themelues »**
3. Ajouter les emails des pilotes fondateurs à ce groupe (manuellement au fil des signatures)
4. Envoyer l'invitation TestFlight ; chaque pilote installe via le lien TestFlight

**Android (Internal Testing) :**
1. Dans Google Play Console → Release → Testing → Internal testing → créer une track
2. Uploader le même AAB que la prod future
3. Ajouter une liste de testeurs (email Gmail obligatoire pour Play Store)
4. Partager le lien d'opt-in : `https://play.google.com/apps/internaltest/…`

**Communication à l'owner signant :**

> « Tu vas recevoir un email TestFlight dans 10 min (ou un lien Google Play si tu es sur Android). Tu installes, tu te connectes avec ton email, tu reçois un code de vérification par email, et tu es dans. Si quelque chose cloche, tu m'écris direct sur WhatsApp. »

## 3. Email template pilote fondateur (backend Laravel)

**Localisation :** repo `C:\Users\avdiu\Projetcs\Lagedi\backend`

**Fichier à créer :** `resources/views/emails/salon/pilot-themelues-welcome.blade.php`

**Différences avec le template welcome owner standard :**
- Ton plus personnel (« Hey, c'est Labi »)
- Mention explicite du statut « Pilot Themelues » et de ses privilèges à vie
- Numéro WhatsApp fondateur visible, avec CTA « WhatsApp-më direkt »
- Pas de "Contact support team" générique
- Checklist 5 étapes avec un timing serré (« dans les 48h »)

**Structure suggérée (SQ, à traduire aussi FR/EN via `Mail::to()->locale()->send()`) :**

```
Sujet : Mirë se erdhe te pilotët themelues — Termini im

Hej [name],

Jam Labi. Po të shkruaj personalisht sepse je ndër 5-8 sallonet e parë
që besojnë te ne para të tjerëve. Kjo nuk harrohet — kështu që ja
çka kam për ty :

1. Badge « Pilot Themelues » — për gjithë jetën në galerinë kryesore
2. Linjë direkte me mua në WhatsApp: +383 XX XXX XXX — për 6 muajt e parë
3. Përparësi në features të reja — para se ti vijnë publikut
4. Vendi i parë në kërkime Ferizaj për 3 muajt e parë pas lansimit

Tani : hap aplikacionin, shto shërbimet, shto 3 fotografi.
Bëje në 48 orë — unë të ndihmoj nëse ngecesh.

— Labi
```

**Trigger côté Laravel :** quand un salon est marqué `is_pilot_themelues = true` dans la DB, envoyer ce template au lieu du welcome owner standard. Flag à ajouter au model `Salon` (migration simple).

**Déclenchement :** le fondateur flag manuellement `is_pilot_themelues = true` dans Nova/Telescope/admin custom après la signature terrain — ce n'est pas un opt-in utilisateur.
````

- [ ] **Step 2 : Vérifier que le fichier est créé**

Run: `ls -la docs/superpowers/plans/2026-04-24-external-actions.md`

---

## Task 15 : Revue finale + commit optionnel

**Files:**
- Read: tous les fichiers modifiés pour revue finale

- [ ] **Step 1 : Grep de vérification globale — plus de « 30 salons » orphelin**

Run: `grep -n "30 salons" docs/*.html docs/*.md .agents/*.md`
Expected : aucune mention ne doit parler de « 30 salons à Prishtinë » en tant que phase 1. Les mentions qui restent (ex: cap diaspora, anecdotes) doivent être contextuellement justifiées.

- [ ] **Step 2 : Grep Prishtinë orphelin**

Run: `grep -n "Prishtinë centre" docs/*.html`
Expected : 0 résultat.

- [ ] **Step 3 : Demander confirmation utilisateur avant git commit**

Présenter un résumé des fichiers modifiés et demander :

> « Tous les docs sont à jour, PDFs regénérés, mémoire projet ajoutée. Je commit maintenant ou tu veux d'abord relire ? »

Attendre la réponse utilisateur.

- [ ] **Step 4 : Si utilisateur valide, commit**

```bash
git add \
  .agents/product-marketing-context.md \
  docs/marketing-brief.md \
  docs/marketing-strategy-kosovo.html \
  docs/marketing-strategy-kosovo.pdf \
  docs/playbook-30-jours-kosovo.html \
  docs/playbook-30-jours-kosovo.pdf \
  docs/app-gaps-notifications.html \
  docs/app-gaps-notifications.pdf \
  brand/v1/hero-prompts.md \
  docs/superpowers/specs/2026-04-24-ferizaj-first-pivot-design.md \
  docs/superpowers/plans/2026-04-24-ferizaj-first-pivot.md \
  docs/superpowers/plans/2026-04-24-external-actions.md

git commit -m "$(cat <<'EOF'
docs(gtm): pivot Ferizaj-first — ville pilote, protocole pilote fondateur, waitlist multi-villes

Décision stratégique prise le 2026-04-24. Lancement passe de Prishtinë-first (30 pilotes)
à Ferizaj-first (15-20 pilotes) pour exploiter le réseau warm du fondateur dans sa ville
natale. Prishtinë devient expansion M3-M4 avec la preuve sociale de Ferizaj.

- Stratégie GTM : phases 1 et 3 réécrites, KPIs ajustés, géo-ciblage ads révisé
- Playbook 30 jours : landing waitlist Ferizaj + multi-villes, captions J4/J9/J16/J23/J27
- Personas : Drita, Egzon, Karim relocalisés à Ferizaj ; Donjeta reste forward-looking Prishtinë
- Protocole pilote fondateur : cap 5-8 salons pré-launch avec statut lifetime
- Hero prompts : ajout 2 variantes Ferizaj dans brand/v1/
- Spec + plan + external actions documentés dans docs/superpowers/

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 5 : Le commit du fichier mémoire** (hors repo projet, vit dans `~/.claude/...`) n'a pas de git associé — juste la persistance sur disque.

---

## Checklist finale de complétude

Avant de clôturer, vérifier :

- [ ] Les 3 PDFs sont à jour (tailles raisonnables, pas de broken rendering)
- [ ] La mémoire projet `project_termini_im_gtm.md` existe et apparaît dans MEMORY.md index
- [ ] Le fichier external-actions.md est créé et actionnable
- [ ] Aucune mention « 30 salons à Prishtinë » ne traîne dans les docs comme phase 1
- [ ] `.agents/product-marketing-context.md` est cohérent (Ferizaj personas + note ville pilote)
- [ ] Le spec est toujours au chemin attendu et cohérent avec le plan

---

## Self-Review (exécuté au moment de l'écriture de ce plan)

**Spec coverage :** les 10 fichiers listés dans la section « Liste exécutable des fichiers à mettre à jour » du spec sont tous couverts par une task de ce plan. ✓

**Placeholder scan :** un seul placeholder acceptable (« [Nom owner], [N] ans de métier à Ferizaj » dans J23) qui est un champ à remplir au moment où un pilote fondateur signe — c'est volontaire et marqué comme tel. ✓

**Type consistency :** les statuts, clés et chaînes utilisées à travers les tasks sont cohérents (« Pilot Themelues » partout, jamais « Pilot Fondateur » en SQ ; « pilote fondateur » en FR ; `qyteti` comme nom du champ Typeform partout). ✓

**Scope check :** plan unique, ~15 tasks séquencées, ~2-4 h de travail total pour une exécution disciplinée. Aucune décomposition supplémentaire nécessaire. ✓
