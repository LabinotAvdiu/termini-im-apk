# Termini im — 6 prompts hero Midjourney · v1

> Générés pour la phase 0 de lancement. Colle chaque prompt tel quel dans Midjourney.
> 4 variations × 6 prompts = 24 images brutes. Tu sélectionnes la meilleure de chaque série
> et tu la stockes à côté de ce fichier, nommée `hero-01.png` → `hero-06.png`.

## Palette de référence (pour rappel)

- Bordeaux `#7A2232`
- Or `#C89B47`
- Ivoire `#F7F2EA`
- Encre `#171311`
- Bone `#E8DCC8`

## Règles partagées des 6 prompts

- **Format feed IG** : `--ar 4:5`
- **Format story/reel** : remplace `--ar 4:5` par `--ar 9:16`
- **Format OG image / bannière** : remplace par `--ar 16:9`
- **Style parameter** : `--style raw` désature le « look IA » générique, `--s 250` garde la cohérence éditoriale sans sur-styliser
- **Jamais de visage net, jamais de texte, jamais de logo** — on ajoute ça en Canva ensuite
- **Équilibre 3F / 3M** : prompts #1, #3, #4 à dominance féminine/neutre ; #2, #5, #6 équilibrés ou masculins. L'ensemble signale visuellement que l'app couvre coiffure, barberie, esthétique, manucure, mariage — pour tous les genres.

---

## Prompt 1 — Mood opener · Prishtinë (neutre)

**Usage** : premier post éditorial, teaser J1 ou J16 (« Prishtinë, capitale du stil »)

```
editorial photography, soft morning light pouring through a tall casement window,
an old Prishtina café table in the foreground, a single cup of Turkish coffee
on a marble surface, folded linen napkin in muted burgundy, brass spoon catching
highlights, aged walls in warm ivory, 35mm film grain, Kinfolk magazine aesthetic,
minimal composition, no text no logo, no people --ar 4:5 --style raw --s 250
```

---

## Prompt 2 — Barberie · le segment hommes (masculin)

**Usage** : signale explicitement que l'app couvre les barberies. À poster dès la semaine 1 pour casser tout de suite l'impression « app pour femmes seulement ».

```
editorial photography, soft morning light in a Balkan barber shop,
close-up of a vintage barber chair in oxblood burgundy leather,
polished brass armrest details, a leather strop and an ivory-handled
straight razor resting on a marble counter, aged mirror in the background
with dim reflection, 35mm film grain, Kinfolk magazine aesthetic,
no text no logo, no faces visible --ar 4:5 --style raw --s 250
```

---

## Prompt 3 — Salon coiffure · mains au travail (féminin/neutre)

**Usage** : mouvement, précision du geste, tradition culturelle (tresse balkanique). Peut servir de hero pour la section « Pour toi » de la landing.

```
editorial photography, soft morning light, close-up over-the-shoulder
of a hairstylist's hands braiding long dark hair into a traditional
Balkan crown braid, warm skin tones, ivory linen robe, burgundy velvet
chair corner just visible, 35mm film grain, Kinfolk aesthetic,
no face visible, tranquil mood, no text no logo
--ar 4:5 --style raw --s 250
```

---

## Prompt 4 — Manucure · détail (féminin)

**Usage** : signale la manucure comme service couvert. Cadre intime, photo-quasi-documentaire.

```
editorial photography, soft natural light from the side,
overhead close-up of manicurist's hands and a client's hand
resting on an ivory linen surface, a small brass dish of muted
burgundy nail polish in the corner, cuticle tools aligned neatly,
dried roses in the blur background, 35mm film grain, Kinfolk aesthetic,
no faces visible, no text no logo --ar 4:5 --style raw --s 250
```

---

## Prompt 5 — Barber grooming · still life (masculin)

**Usage** : deuxième image barberie, plus abstraite — outils et matières, pour un carousel « ce que tu trouves sur Termini im ».

```
editorial photography, soft morning light, still life on an aged walnut
barber counter, a badger-hair shaving brush, a bar of sandalwood soap,
an ivory-handled straight razor catching a burgundy reflection,
a folded charcoal towel, worn brass scissors, 35mm film grain,
Kinfolk magazine aesthetic, no text no logo, no people
--ar 4:5 --style raw --s 250
```

---

## Prompt 6 — Préparation mariage · moment culturel (mixte)

**Usage** : pic saisonnier mariages mai-octobre. Peut servir tel quel pour le post éditorial J25 (« Bajram / mariage / rentrée »).

```
editorial photography, soft morning light in a traditional Kosovar home,
close-up of a bride's hand with intricate henna reaching toward a small
brass tray holding gold earrings and a folded ivory veil, burgundy velvet
curtain blurred behind, natural unstyled mood, 35mm film grain,
Kinfolk aesthetic, no face visible, dignified not exoticized,
no text no logo --ar 4:5 --style raw --s 250
```

---

## Workflow exécution (J-6, ~4h)

1. Ouvre Midjourney (Discord ou app web)
2. Colle les 6 prompts **un par un**. Chacun génère une grille de 4 variantes en ~60 sec
3. Pour chaque prompt, upscale la meilleure variante → `U1` / `U2` / `U3` / `U4`
4. Télécharge l'image upscale au format PNG
5. Renomme en `hero-01.png` → `hero-06.png` et mets-les dans ce dossier (`brand/v1/`)
6. Si une génération ne te convient pas, reroll avec `🔄` ou varie légèrement le wording (ex: remplace « burgundy » par « deep maroon », « Kinfolk » par « Cereal magazine »)

## Si Midjourney n'est pas disponible

Fallback avec les mêmes prompts (enlève juste les paramètres `--ar`, `--style`, `--s` et indique l'aspect ratio autrement) :

- **DALL-E 3 via ChatGPT** — génère en 1024×1024, crop ensuite en 4:5 via Canva. Résultat correct mais moins cinéma.
- **Ideogram 2.0** — très fort pour l'éditorial, permet `--ar 4:5` natif. Compte gratuit = 20 images/jour.
- **Leonardo.ai** — modèle « Flux » bon pour le mood photographique, 150 crédits/jour gratuits.

## Après génération — nommage et archivage

Structure cible du dossier :

```
brand/
└── v1/
    ├── hero-prompts.md         ← ce fichier
    ├── hero-01.png             ← mood Prishtinë
    ├── hero-02.png             ← barberie
    ├── hero-03.png             ← coiffure mains
    ├── hero-04.png             ← manucure
    ├── hero-05.png             ← barber grooming still life
    ├── hero-06.png             ← mariage
    └── _raw/                   ← les 4 variantes brutes de chaque, pour y revenir
        ├── hero-01-var-a.png
        ├── hero-01-var-b.png
        └── ...
```

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

---

## Extensions possibles (si tu veux + d'images)

Si tu veux monter à 12 au lieu de 6, duplique avec variations :
- **Jour** : `soft morning light` → `late afternoon golden light` (même scène, autre ambiance)
- **Saison** : `dried roses` → `pomegranate and dried rose hips` (variante automne/hiver)
- **Culture** : ajoute `filigran jewelry, traditional Kosovar xhubleta motif` pour variantes culturelles
