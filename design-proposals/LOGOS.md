# Termini im — Kit logo

Système d'identité dans la direction **Prishtina Editorial**.

## Fichiers

| Fichier | Usage |
|---|---|
| `logo-primary.svg` | Wordmark horizontal · signature principale, site, emails, factures |
| `logo-primary-dark.svg` | Version sombre · footers, overlays, modes dark |
| `logo-stacked.svg` | Version empilée · cartes sociales carrées, print, about |
| `logo-monogram-ivory.svg` | App icon clair · avatar utilisateur |
| `logo-monogram-ink.svg` | App icon sombre · dock macOS, iOS dark |
| `logo-monogram-burgundy.svg` | Variante premium · espace pro, owner tier |
| `favicon.svg` | Favicon navigateur (32×32 optimisé) |

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
