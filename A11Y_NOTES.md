# A11Y Notes — Problèmes détectés (non corrigés)

Ces problèmes ont été identifiés lors de la session UX polish du 2026-04-18.
Ils ne sont PAS corrigés ici — ils sont réservés pour la session a11y dédiée.

---

## Touch targets

- `_SlotChip` dans `company_card.dart` : les chips de créneaux (matin/après-midi)
  ont un padding `vertical: 3` → hauteur estimée ~22dp. Sous les 48dp recommandés.
  Correction : `vertical: 12` pour atteindre ~32dp + zone tapable élargie via `MaterialTapTargetSize`.

- `_DesktopSlotChip` dans `home_screen_desktop.dart` : idem, padding `vertical: 4`.

- Favoris badge (`FavoriteBadge`) : 28×28dp. Sous les 44dp.
  Correction : utiliser `GestureDetector` avec `behavior: HitTestBehavior.opaque`
  et un padding étendu autour du container 28×28.

- Boutons de step booking mobile (`_MobileBottomNavBar`) : `tapTargetSize: shrinkWrap`.
  Vérifier que la zone cliquable réelle est ≥ 44dp de hauteur.

---

## Contrastes

- `AppColors.textHint` (`#716059`) sur `AppColors.background` (`#F7F2EA`) :
  ratio calculé ~3.8:1. En dessous du seuil WCAG AA pour le texte normal (4.5:1).
  Utilisé dans les adresses, sous-titres, labels de slots.
  Correction : assombrir à ~`#5C4D44` pour atteindre 4.5:1.

- `AppColors.secondary` / `AppColors.secondaryDark` (`#A07A2C`) sur `#F7F2EA` :
  ratio ~3.4:1. Utilisé dans les badges "pending".
  Correction : utiliser `#8A6420` pour le texte (ratio ~4.6:1).

---

## Semantics manquants

- `PhotoGallery` : le `PageView` n'a pas de `Semantics` sur chaque image.
  Les lecteurs d'écran ne savent pas que c'est "Photo 1 sur 3" etc.
  Correction : `Semantics(label: 'Photo ${index+1} sur ${total}', child: ...)`.

- Les `SkeletonBox` ne sont pas marqués avec `ExcludeSemantics` — ils seront
  lus par les lecteurs d'écran comme des éléments vides.
  Correction : `ExcludeSemantics(child: SkeletonBox(...))` dans tous les skeletons.

- `StepIndicator` dans booking : les étapes n'ont pas de `Semantics`
  annonçant "Étape 1 sur 2" aux lecteurs d'écran.

---

## Focus / navigation clavier

- La lightbox galerie (`GalleryLightbox`) n'a pas de gestion du focus :
  impossible de la fermer avec Échap au clavier.
  Correction : `Focus(autofocus: true, onKeyEvent: ...)` ou `CallbackShortcuts`.

---

## Réduction de mouvement

- `AnimatedContainer` hover dans `_DesktopSalonCardState` n'est pas conditionné
  par `MediaQuery.disableAnimations`. À conditionner lors de la session a11y.
