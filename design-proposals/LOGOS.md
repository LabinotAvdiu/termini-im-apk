# Termini im — Kit logo

Système d'identité dans la direction **Prishtina Editorial**.

## Règle pre-launch (jusqu'à juin 2026 minimum)

**Wordmark complet partout où c'est lisible.** La marque n'a pas encore la notoriété qui permet à un monogramme seul (« T » ou « im ») d'être reconnu. Un avatar IG avec juste « im » ne lit pas comme « Termini im » pour quelqu'un qui découvre la marque — il lit comme un artefact graphique aléatoire. Pre-launch, on ne prend pas ce risque.

- **Si tu doutes** : `logo-primary.svg` (clair) ou `logo-primary-dark.svg` (sombre)
- **Format carré** : `logo-stacked.svg` — wordmark + tagline `PRISHTINË · 2026`
- **Monogrammes** : seulement quand l'espace est < 48 px (favicon, app icon)
- **`logo-monogram-burgundy.svg` (le « im » italique sur bordeaux) est OFF-LIMITS** en pre-launch. Réservé pour un futur tier Pro/Owner premium (M+12 minimum).

## Fichiers

| Fichier | Usage |
|---|---|
| `logo-primary.svg` | **Workhorse pre-launch** · wordmark horizontal · landing, web app, emails, login mobile, signup, factures |
| `logo-primary-dark.svg` | Version sombre · footers dark, overlays, dark mode app, modals sombres |
| `logo-stacked.svg` | **Avatars sociaux 1080×1080** · IG / TikTok / FB · sticker vitrine salon · OG cards · splash mobile carré |
| `logo-monogram-ivory.svg` | « T » encre sur ivoire · usage de niche < 48 px (badges, tabbar active state) |
| `logo-monogram-ink.svg` | « T » ivoire sur encre + dot or · dock macOS, dark theme alternatif |
| `logo-monogram-burgundy.svg` | ⚠️ **RÉSERVÉ — ne pas utiliser en pre-launch.** « im » italique sur bordeaux. Variante prévue pour un futur tier Pro/Owner premium (espace owner, badge VIP). Jamais comme avatar général. |
| `favicon.svg` | Favicon navigateur 32×32 · « T » ivoire sur encre + dot bordeaux. Aligné avec `launcher-icon.png` et les PNG de prod (`web/favicon.png`, `docs/landing/favicon.png`). |
| `launcher-icon.png` / `launcher-icon-fg.png` | App icon iOS/Android · « T » ivoire sur encre + dot bordeaux. Géré par `flutter_launcher_icons` via `pubspec.yaml`. |

## Polices utilisées

- **Fraunces** (variable serif) — `Termini`, `T`
- **Instrument Serif Italic** — `im`
- **Instrument Sans** — labels secondaires

Les fichiers importent les polices depuis Google Fonts via `@import`. Ça fonctionne directement dans tous les contextes web modernes.

## Production : vectoriser le texte

Si tu veux des SVG 100 % portables (sans dépendance aux polices), passe les fichiers dans Figma ou Illustrator et vectorise :

**Figma** : sélectionne le texte → `Ctrl/Cmd + Shift + O` (Outline Stroke)  
**Illustrator** : sélectionne le texte → `Type > Create Outlines` (`Ctrl/Cmd + Shift + O`)

Ensuite `File > Export > SVG`. Les lettres deviennent des paths et le fichier n'a plus besoin des polices.

## Palette de référence

```
Ivoire       #F7F2EA
Os           #E8DCC8
Encre        #171311
Bordeaux     #7A2232
Or           #C89B47
```

## Zone de protection

Autour du wordmark, garde au minimum l'équivalent de la hauteur du point bordeaux (≈ 14 px à taille native). Ne jamais rogner ni recolorer "im" dans une autre teinte que bordeaux (clair) ou or (sombre).

## Compositions Flutter natives (in-app)

Pour les écrans Flutter à fort impact visuel (login, QR center, etc.), on **NE charge PAS le SVG** via `flutter_svg`. Raison : `logo-primary.svg` utilise `<style>` + `@import url(Google Fonts)` que `flutter_svg` ne sait pas parser, ce qui produit un fallback `Times New Roman`/`Georgia` peu fidèle à la marque ET un défaut de rendu où le `i` final de "Termini" semble se superposer au `i` de "im".

À la place, on compose le wordmark **natively avec `Text` + `Container`**, ce qui garantit :
- Les vraies polices Google déjà préchargées par l'app (Fraunces, Instrument Serif)
- Un positionnement pixel-précis des deux dots (• bordeaux à gauche, • ink à droite)
- Pas de fallback ambigu sur les plateformes web/Android/iOS

### Layout natif (référence)

`[• bordeaux] Termini [im italique bordeaux] [• ink]`

| Élément | Police | Taille au scale 1.0 |
|---|---|---|
| Dot bordeaux gauche | – | 5 px |
| `Termini` | Fraunces 400 | 18 px (letter-spacing -0.4) |
| `im` | Instrument Serif italic | 20 px |
| Dot ink droit | – | 3 px |
| Gaps | – | 6 / 3 / 4 px |

### Widgets concernés

| Widget | Fichier | Scale typique | Notes |
|---|---|---|---|
| `_LoginBrandWordmark` | `lib/features/auth/presentation/screens/login_screen.dart` | ~1.55 (font 28/30) | Header de login, sans fond — la page est déjà ivoire |
| `_QrCenterWordmark` | `lib/features/sharing/presentation/screens/share_qr_screen.dart` | 1.0 normal, jusqu'à ~2.36 en fullscreen | Centre du QR code, **avec** fond ivoire arrondi 8 px + ombre légère pour ressortir sur le QR noir/blanc |

### Quand utiliser quoi

- **Composition native** : tout écran Flutter où le wordmark est visible et "premium" (login, signup, splash, settings header, QR center, etc.)
- **`BrandLogo` (SVG)** : les contextes où la fidélité parfaite à la marque n'est pas critique et où on veut un seul source-of-truth (badges secondaires, footer "powered by", etc.)
- **`logo-primary.svg` direct** : web/HTML uniquement (landing, emails, OG cards) — là `@import` Google Fonts marche

### Si tu veux ajouter le wordmark sur un nouvel écran

Le plus simple : copie la classe `_QrCenterWordmark` (qui a déjà le paramètre `scale`) et adapte le `scale` à la taille voulue. Si plusieurs écrans en ont besoin, extraire en `BrandWordmark` partagé dans `lib/core/widgets/`.
