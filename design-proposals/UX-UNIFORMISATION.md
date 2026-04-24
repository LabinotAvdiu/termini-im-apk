# Termini im — Document d'uniformisation UX/Design

> Version : 2026-04-23 | Branche : `feat/owner-employee-ui` | Statut : référence normative

---

## §1 Principes directeurs

### 1.1 Palette — valeurs normatives

| Token | Couleur | Hex | Usage principal |
|---|---|---|---|
| `AppColors.primary` | Bourgogne | `#7A2232` | CTA primaire, icônes actives, bordure focus, slot sélectionné |
| `AppColors.primaryLight` | Bourgogne clair | `#9E3D4F` | Gradient hero (arrêt final) |
| `AppColors.primaryDark` | Bourgogne profond | `#511522` | Gradient hero (arrêt initial), sidebar desktop |
| `AppColors.secondary` | Or | `#C89B47` | Étoiles, accents texte, hover/actif secondaire |
| `AppColors.background` | Sable | `#F7F2EA` | Fond Scaffold, fond bouton primaire inversé |
| `AppColors.surface` | Ivoire | `#FCF7EE` | Fond carte, fond champ de saisie |
| `AppColors.ivoryAlt` | Ivoire alt | `#EFE6D5` | Slot disponible, badge non sélectionné |
| `AppColors.textPrimary` | Encre | `#171311` | Titres, bouton filled (fond) |
| `AppColors.textSecondary` | Encre secondaire | `#332C29` | Corps, labels de champ |
| `AppColors.textHint` | Encre atténuée | `#716059` | Placeholders, légendes, icônes inactives |
| `AppColors.divider` | Diviseur | `#E8DCC8` | Séparateurs horizontaux |
| `AppColors.border` | Bordure | `#D9CAB3` | Bordures de carte, champ, chip |
| `AppColors.error` | Erreur | `#B83D3D` | Messages d'erreur, bordure erreur |
| `AppColors.success` | Sage | `#6F7E55` | Confirmations, badges "confirmé" |
| `AppColors.cardShadow` | Ombre carte | `#14171311` (8 %) | Ombre douce des cartes |

**Règle** : ne jamais introduire de couleur hors de ce référentiel. Si une nuance manque, dériver avec `.withValues(alpha: x)` depuis un token existant.

### 1.2 Typographie

| Style | Fonte | Taille | Graisse | Usage |
|---|---|---|---|---|
| `h1` | Fraunces | 34 | 400 | Titre hero (LandingScreen) |
| `h2` | Fraunces | 26 | 400 | Titres de section, titres d'écran principaux |
| `h3` | Fraunces | 19 | 500 | Titres de cartes, sections de formulaire |
| `subtitle` | Instrument Sans | 15 | 400 | Sous-titres immédiats |
| `body` | Instrument Sans | 14 | 400 | Contenu courant |
| `bodySmall` | Instrument Sans | 12 | 400 | Descriptions secondaires |
| `caption` | Instrument Sans | 11 | 400 | Légendes, métadonnées (letterSpacing 0.88) |
| `overline` | Instrument Sans | 10 | 500 | Labels catégorie UPPERCASED (letterSpacing 1.4) |
| `button` | Instrument Sans | 13 | 600 | Libellés de bouton (letterSpacing 1.04) |
| `buttonSmall` | Instrument Sans | 12 | 600 | Boutons compacts, chips |
| `emphasis` | Instrument Serif | 14 | 400 | Texte italique expressif, lien "s'inscrire", mention "im" |

**Règle** : les titres d'écran principaux utilisent `h2` (Fraunces). Les overlines catégorie s'écrivent en UPPERCASE via `.toUpperCase()` + `AppTextStyles.overline`. Le mot "im" dans la marque et les liens expressifs utilisent `emphasis` (Instrument Serif italic).

### 1.3 Rythme vertical — espacements

| Token | dp | Équivalent sémantique |
|---|---|---|
| `AppSpacing.xs` | 4 | Espace mini (ex. entre label et valeur) |
| `AppSpacing.sm` | 8 | Espace intra-groupe |
| `AppSpacing.md` | 16 | Padding standard, espace inter-champ |
| `AppSpacing.lg` | 24 | Espace inter-section dans un écran |
| `AppSpacing.xl` | 32 | Espace entre blocs majeurs |
| `AppSpacing.xxl` | 48 | Padding bottom (safe area, zone de respiration) |

**Règle** : la colonne d'un écran scrollable se termine par `SizedBox(height: AppSpacing.xxl)` pour éviter que le contenu passe derrière la nav bar.

### 1.4 Rayons et elevation

| Token | dp | Usage |
|---|---|---|
| `AppSpacing.radiusSm` | 8 | Chips, badges, petits conteneurs |
| `AppSpacing.radiusMd` | 12 | Boutons (valeur normative), cartes compactes |
| `AppSpacing.radiusLg` | 16 | Cartes standard, bottom sheets |
| `AppSpacing.radiusXl` | 24 | Cartes larges (ex. form card login) |

**Elevation** : `0` sur toutes les cartes et app bars (`elevation: 0`, `scrolledUnderElevation: 0`). L'ombre est simulée par une `BoxDecoration` avec `BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0,4))`. Ne pas utiliser `elevation > 0` sur Material 3.

### 1.5 Responsive — breakpoints

Le projet utilise `ResponsiveLayout` (classe existante dans `lib/core/utils/responsive.dart`).

| Régime | Breakpoint | Layout type |
|---|---|---|
| Mobile | `< 1100 px` | Colonne unique, bottom nav bar |
| Desktop | `>= 1100 px` | Deux colonnes (sidebar + contenu) ou split-screen |

**Largeur max du contenu central desktop** : `1360 px` (aligned avec `termini-editorial.html`). Sur mobile, padding horizontal `AppSpacing.md` (16 dp) de chaque côté. Les formulaires et cartes se contraignent à `maxWidth: 440–560` en mobile via `ConstrainedBox`.

---

## §2 Composants communs à standardiser

### 2.1 App Bar — pattern normé

**Mobile** :
```
AppBar(
  backgroundColor: AppColors.background,
  foregroundColor: AppColors.textPrimary,
  elevation: 0,
  scrolledUnderElevation: 0,
  centerTitle: true,
  title: Text(titre, style: AppTextStyles.h3),
)
```

**Écarts observés** :
- `MyCompanyReviewsScreen` : titre avec `.copyWith(color: AppColors.textPrimary)` superflu — `h3` l'a déjà. Retirer le `copyWith`.
- `MaintenanceScreen` / `ForceUpdateScreen` : pas d'AppBar — correct (écrans bloquants).
- `AppointmentsScreenMobile` : pas d'AppBar, le titre `h2` est rendu dans le body (scrollable). Acceptable mais incohérent avec `MyCompanyReviewsScreen`. Choisir un pattern et l'appliquer partout : soit AppBar avec `h3` + body sans titre, soit pas d'AppBar + titre `h2` en haut du body.

**Recommandation** : adopter le pattern "titre dans le body" pour les écrans fullscreen scrollables (Appointments, Reviews, Settings) et AppBar classique pour les sous-écrans en navigation push (CompanyReviews, ForgotPassword, VerifyEmail).

### 2.2 Section Header — pattern normé

Utilisé partout dans les écrans scrollables pour introduire un groupe de contenu.

```dart
// Pattern recommandé (actuellement inconsistant)
Row(
  children: [
    Icon(icon, size: 16, color: color),
    SizedBox(width: AppSpacing.sm),
    Text(label.toUpperCase(), style: AppTextStyles.overline.copyWith(color: color)),
  ],
)
```

**Variante éditoriale** (utilisée dans `settings-redesign.html`) : numéro de section en Fraunces + titre display. Réserver aux pages de contenu éditorial (Settings desktop). Pour les listes opérationnelles (Appointments, PendingApprovals), utiliser le pattern compact ci-dessus.

### 2.3 Carte standard

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),  // 16
    border: Border.all(color: AppColors.border, width: 1),
    boxShadow: [
      BoxShadow(
        color: AppColors.cardShadow,
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  ),
  padding: EdgeInsets.all(AppSpacing.md),  // ou lg selon le contenu
  child: ...,
)
```

**Écarts observés** :
- `login_screen.dart:389` : radius `radiusXl` (24) pour la form card — acceptable pour les formulaires immersifs, mais à unifier avec `company_setup_screen.dart` qui utilise un padding plat sans `Container` wrappé.
- `AppTheme.cardTheme` définit `radiusMd` (12) et `margin: horizontal 16, vertical 8`. Mais la plupart des écrans recréent leurs propres `Container` au lieu d'utiliser `Card`. Le `cardTheme` est sous-exploité.

**Recommandation** : créer un `AppCard` widget partagé qui encapsule la `BoxDecoration` normée. Les écrans arrêtent de répéter la même déco à la main.

### 2.4 Bouton primaire — CTA principal

```dart
SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    onPressed: onPressed,
    // style depuis AppTheme : fond textPrimary (#171311), texte background (#F7F2EA)
    child: Text(label.toUpperCase(), style: AppTextStyles.button.copyWith(color: AppColors.background)),
  ),
)
```

**Écarts observés** :
- `AppButton` (filled) utilise `ElevatedButton` du thème — cohérent.
- `ForceUpdateScreen:89` utilise `FilledButton` avec `backgroundColor: AppColors.primary` — divergence. Le bouton CTA bloquant devrait utiliser `primary` (bourgogne) comme couleur principale, pas `textPrimary` (encre). C'est intentionnellement différent ici, mais non documenté. Clarifier : les CTA sur fond sable utilisent encre (`textPrimary`), les CTA sur fond bourgogne/coloré utilisent ivoire.
- `landing_screen.dart:555` : bouton Login avec fond `textPrimary` — correct. Bouton Signup avec `OutlinedButton` + bordure `AppColors.border` — correct (secondaire).

**Hiérarchie boutons à formaliser** :
1. **Primaire** : `ElevatedButton`, fond `#171311`, texte `#F7F2EA`, h=50, radius 12
2. **Secondaire** : `OutlinedButton`, bordure `#D9CAB3`, texte `#171311`, h=50, radius 12
3. **Accent** : `ElevatedButton`, fond `#7A2232`, texte `#F7F2EA` — uniquement pour écrans bloquants (ForceUpdate) ou CTAs bourgogne explicitement voulus
4. **Ghost** : `TextButton`, texte `#7A2232` — liens inline
5. **Social** : `AppSocialButton` — bordure `#D9CAB3`, fond transparent

### 2.5 Champ de formulaire — `AppTextField`

Le widget existe et est bien utilisé. Points à uniformiser :

- Le `label` above-the-field est en `bodySmall` (12px, `textSecondary`, w500) — correct.
- La hauteur effective d'un champ (padding vertical 14px × 2 + font 14px) ≈ 48px — respecte le minimum touch target de 48dp.
- Radius = 10px (aligné avec `AppTheme.inputDecorationTheme`) — légèrement inférieur à `radiusMd` (12). Unifier à `radiusMd` ou documenter l'exception.
- Le `prefixIcon` a `size: 18, color: textHint`. Certains écrans custom ont `size: 15` ou `size: 20`. Uniformiser à **18**.

### 2.6 État vide (Empty State)

Pattern actuel : inconsistant. `AppointmentsScreenMobile` utilise un `_EmptyCard` avec icône + texte centré. `MyCompanyReviewsScreen` utilise un simple `Center(child: Text(...))` sans icône, sans CTA.

**Pattern normé à adopter** :
```
Colonne centrée verticalement :
  Icône Material (48×48, couleur textHint ou couleur thématique avec opacity 0.4)
  SizedBox(height: md)
  Texte h3 (Fraunces, centré) — titre de l'état vide
  SizedBox(height: xs)
  Texte bodySmall (centré, textHint) — description courte
  [Optionnel] SizedBox(height: lg) + AppButton — CTA contextuel
```

### 2.7 État de chargement (Loading State)

**Skeleton loaders** : utilisés dans `HomeScreenMobile`, `CompanyDashboardScreenMobile`, `PendingApprovalsScreen`. La classe `SkeletonDashboard` existe dans `lib/core/widgets/skeletons/skeleton_widgets.dart`.

**Écarts** :
- `MyCompanyReviewsScreen` utilise `CircularProgressIndicator` plein écran au lieu d'un skeleton — visuellement moins élaboré et crée un flash de layout.
- `EmployeeScheduleScreen` et `ScheduleSettingsScreen` : état de chargement non audité visuellement mais probablement `CircularProgressIndicator`.

**Recommandation** : remplacer tous les `CircularProgressIndicator` plein écran par des skeletons contextuels, ou au minimum par un `SkeletonList` générique (rectangles aux bonnes dimensions).

### 2.8 Bannière d'erreur (Error State)

**Login screen** (`login_screen.dart:486`) : bannière inline avec `error.withValues(alpha:0.08)` fond + bordure `error.withValues(alpha:0.30)` + icône `error_outline_rounded` + texte 12px. C'est le pattern le plus complet — adopter comme norme.

**Écarts** :
- `AppointmentsScreenMobile` : `_ErrorState` avec icône + texte + bouton retry — bon.
- `MyCompanyReviewsScreen` : pas d'état d'erreur — lacune.
- `ScheduleSettingsScreen` : à vérifier.

**Pattern normé** :
```
Container(
  padding: EdgeInsets.all(AppSpacing.sm + 2),  // 10
  decoration: BoxDecoration(
    color: AppColors.error.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
    border: Border.all(color: AppColors.error.withValues(alpha: 0.30)),
  ),
  child: Row(icône 16px + texte bodySmall + [bouton retry]),
)
```

### 2.9 Toast / Snackbar

Défini dans `AppTheme.snackBarTheme` : fond `textPrimary`, texte `background`, radius 10, floating. Utilisé via `context.showErrorSnackBar(error)`. Cohérent. Ne pas introduire d'autres mécanismes de notification inline (ex. dialog pour des erreurs simples).

### 2.10 Bottom Sheet / Modal

**Pattern actuel** : `showModalBottomSheet` utilisé pour `LanguageSheet`, `AuthRequiredModal`. Radius top : `radiusXl` (24) — cohérent avec les maquettes HTML.

**Recommandation** : uniformiser le drag handle : une barre de 32×4 px, `AppColors.border`, radius 2, centrée en haut de la sheet avec padding top 12px.

---

## §3 Patterns de layout

### 3.1 Mobile — structure d'un écran standard

```
Scaffold(
  backgroundColor: AppColors.background,
  appBar: AppBar(...),     // si navigation push
  body: RefreshIndicator(  // si liste rechargeable
    child: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: Column(banners...)),
        SliverList(...)    // liste principale
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    ),
  ),
  bottomNavigationBar: ...,  // géré par MainShell
)
```

**Padding horizontal uniforme** : `EdgeInsets.symmetric(horizontal: AppSpacing.md)` (16dp) pour toutes les listes. Les cartes ont leur propre padding interne.

### 3.2 Desktop — structure d'un écran avec sidebar

```
Scaffold(
  body: Row(
    children: [
      _Sidebar(width: 240),    // fond textPrimary (#171311)
      Expanded(
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1360),
              child: ...,
            ),
          ),
        ),
      ),
    ],
  ),
)
```

**Écart** : le dashboard desktop (`company_dashboard_screen_desktop.dart`) et le planning desktop (`company_planning_screen_desktop.dart`) utilisent tous deux cette structure, mais la largeur de la sidebar et ses items divergent légèrement. Unifier via un widget `AppSidebar` partagé.

### 3.3 Split-screen éditorial (desktop uniquement)

Utilisé par `RoleSelectionScreenDesktop` : 40 % gauche (bourgogne), 60 % droite (ivoire). Pattern réservé aux écrans de marque (onboarding, landing éventuel sur web). Ne pas utiliser pour les écrans opérationnels.

### 3.4 Formulaires multi-étapes

`SignupScreen` utilise un stepper à 4 étapes avec `_currentStep`. `ForgotPasswordScreen` utilise une bascule booléenne `_emailSent`. `BookingScreen` utilise un `PageController`.

**Recommandation** : unifier avec un `StepIndicator` widget (déjà existant dans `lib/features/booking/presentation/widgets/step_indicator.dart`) appliqué à tous les formulaires multi-étapes.

---

## §4 Audit écran par écran

### 4.1 Auth & Onboarding

#### LandingScreen (`lib/features/home/presentation/screens/landing_screen.dart`)

**But** : point d'entrée public. Recherche de salon en mode invité, accès auth.

**Fonctionnalités présentes** :
- Hero bourgogne avec dégradé 3 arrêts, blob or radial, headline Fraunces 38px
- Floating search card (ville, date, clientèle) avec `Transform.translate(offset: Offset(0,-22))`
- Filtre genre (hommes/femmes/tous) via chips animées
- Bouton "RECHERCHER" → mode invité + home
- Section auth : divider "OU" + Login + Signup

**Points positifs** : hero très fidèle à `termini-editorial.html`, animations `FadeTransition` + `SlideTransition` bien dosées, blob or en coin cohérent.

**Écarts et problèmes** :
- Pas de variante desktop — l'écran unique s'affiche sur toutes les tailles. Sur un écran 1440px, la search card `maxWidth: 560` est très étroite et le hero remplit toute la largeur, ce qui crée un déséquilibre visuel important.
- La date est formatée manuellement `'${d.day}/${d.month}/${d.year}'` sans zéro padded (`1/1/2026` au lieu de `01/01/2026`). Incohérent avec la cible DD/MM.
- `_SearchRow` : label fixe `SizedBox(width: 46)` — peut tronquer les traductions longues (albanais).
- Le bouton Signup affiche une `RichText` Instrument Serif italic inline dans un `OutlinedButton` — techniquement correct mais visuellement fragile sur de petits appareils.
- Pas d'état de loading/erreur sur la recherche — si l'API échoue, l'utilisateur ne voit rien.

**Recommandations** :
- Créer `landing_screen_desktop.dart` avec layout split : hero full-height gauche (bourgogne) + search card centrée droite (ivoire). Référence : `termini-editorial.html` sections hero + brandbar.
- Corriger le format date : `DateFormat('dd/MM/yyyy', locale)` via `intl`.
- Remplacer `SizedBox(width: 46)` par `Flexible` dans `_SearchRow`.

---

#### LoginScreen (`lib/features/auth/presentation/screens/login_screen.dart`)

**But** : authentification email/password + social.

**Fonctionnalités** : champ email/password, remember me, forgot password, Google/Facebook/Apple, lien signup, contact support, langue.

**Points positifs** : pattern form card très propre, gestion fine du loading par provider social, blob gradient décoratif cohérent.

**Écarts** :
- `login_screen.dart:31` : `TextEditingController(text: 'donjeta@termini.im')` — valeur de test non retirée (TODO commenté mais toujours là). À supprimer avant release.
- L'overline `'TERMINI IM'` avec `letterSpacing: 2.4` (`login_screen.dart:315`) viole la règle du CLAUDE.md ("Never use 'TERMINI IM' in all-caps spaced characters"). Remplacer par le `BrandLogo` seul ou par `'Termini im'` en Fraunces.
- Le blob gradient (`_TopGradientDecoration`) utilise `Positioned` dans un `Stack` sans `Positioned.fill` pour le contenu principal — ce qui force l'utilisation de `SafeArea` dans le Stack. Acceptable mais fragile sur notch.
- Pas de variante desktop — sur grand écran le formulaire centré à `maxWidth: 440` flotte dans un grand vide sableux.

**Recommandations** :
- Supprimer la valeur de test email.
- Remplacer `'TERMINI IM'` par `BrandLogo(variant: BrandLogoVariant.burgundy, size: 32)` + texte Fraunces `'Bienvenue.'`.
- Créer `login_screen_desktop.dart` : split-screen 40/60 (bourgogne branding / ivoire form), calqué sur `RoleSelectionScreenDesktop`.

---

#### SignupScreen (`lib/features/auth/presentation/screens/signup_screen.dart`)

**But** : inscription en 4 étapes (client ou propriétaire).

**Fonctionnalités** : informations personnelles, infos salon (owner), mode booking, sécurité, social OAuth.

**Écarts** :
- `_currentStep` atteint 4 étapes pour les propriétaires mais l'indicateur de step n'est pas visible visuellement — `StepIndicator` n'est pas utilisé ici. Incohérent avec `BookingScreen` qui l'utilise.
- Pas de variante desktop — la colonne d'input s'étire sur toute la largeur sur grand écran.
- Le `step2` (infos salon) duplique exactement la logique de `CompanySetupScreen` (infos salon pour social login). Refactoriser en widget partagé.
- Sélecteur de clientèle (`CompanyClienteleSelector`) : widget non audité ici mais critère de validation externe non intégré au formulaire Form — erreur non captée par le formKey si l'utilisateur oublie de sélectionner.

**Recommandations** :
- Ajouter `StepIndicator` en haut du formulaire (steps 1–4).
- Créer `signup_screen_desktop.dart` split-screen.
- Extraire le bloc infos salon en `_SalonInfoStep` partagé entre `SignupScreen` et `CompanySetupScreen`.

---

#### ForgotPasswordScreen (`lib/features/auth/presentation/screens/forgot_password_screen.dart`)

**But** : récupération de mot de passe en 2 étapes (email puis OTP + nouveau mdp).

**Fonctionnalités** : champ email, puis champ token 6-car + nouveau password + confirmation.

**Écarts** :
- Pas d'indicateur de progression entre step 1 et step 2 — la transition est une simple bascule `_emailSent`. L'utilisateur ne sait pas combien d'étapes restent.
- Le champ token est un `AppTextField` standard — moins intuitif que les 6 cellules OTP de `EmailVerificationScreen`. Incohérence dans le pattern OTP.
- Pas de variante desktop.

**Recommandations** :
- Utiliser le même widget OTP à 6 cellules que `EmailVerificationScreen`.
- Ajouter un indicateur binaire (étape 1/2) via un `StepIndicator(totalSteps: 2)`.

---

#### EmailVerificationScreen (`lib/features/auth/presentation/screens/verify_email_screen.dart`)

**But** : vérification du code OTP reçu par email après inscription.

**Fonctionnalités** : 6 cellules OTP individuelles, resend avec cooldown 60s, état succès.

**Points positifs** : pattern OTP à cellules bien conçu, feedback haptique, cooldown visuel.

**Écarts** :
- Pas de variante desktop.
- État succès (`_verified`) affiche un card — non audité visuellement pour sa conformité avec les tokens.

---

#### RoleSelectionScreen (`lib/features/auth/presentation/screens/role_selection_screen.dart`)

**But** : choix du rôle (client / propriétaire) avant inscription.

**Variantes** : mobile (fond bourgogne fullscreen, cartes blanches) + desktop (split 40/60).

**Points positifs** : seul écran auth avec split-screen desktop. L'arc SVG or séparateur est une touche éditoriale distinctive.

**Écarts** :
- Mobile : fond bourgogne fullscreen — cohérent avec la landing. Mais les cartes rôle ont un fond blanc (`Colors.white`) hard-coded au lieu de `AppColors.surface`. Remplacer.
- Desktop (`role_selection_screen_desktop.dart:80`) : `Colors.white.withValues(alpha: 0.15)` pour le container logo — correct (sur fond bourgogne). Mais le panneau droit ivoire utilise `GoogleFonts.fraunces` appelé directement au lieu de `AppTextStyles.h2`. Harmoniser.

---

#### CompanySetupScreen (`lib/features/auth/presentation/screens/company_setup_screen.dart`)

**But** : configuration salon post-OAuth (social login → rôle company sans salon existant).

**Fonctionnalités** : nom salon, adresse, clientèle, mode booking.

**Écarts** :
- Pas de variante desktop.
- Logique dupliquée avec `SignupScreen` étape 2 (voir ci-dessus).
- Le Scaffold n'a pas de `backgroundColor: AppColors.background` explicite — hérite du thème, mais mieux vaut l'expliciter pour la cohérence de lecture du code.

---

### 4.2 Shell & Navigation

#### MainShell (`lib/features/shell/presentation/screens/main_shell.dart`)

**But** : shell principal post-auth, gère bottom nav (mobile) + sidebar (desktop).

**Fonctionnalités** : dispatch conditionnel des tabs selon rôle (client / owner / employee / capacity owner / individual employee), badge "À confirmer" sur l'onglet approbations.

**Points positifs** : logique de rôle bien encapsulée, `_LazyPage` pour différer le chargement, `ShellNavRequest` pour la communication inter-tabs.

**Écarts** :
- La bottom nav mobile utilise `BottomNavigationBar` du thème (`AppColors.primary` actif, `AppColors.textHint` inactif). Mais le label des onglets n'utilise pas `AppTextStyles.buttonSmall` — il utilise le style par défaut de `BottomNavigationBar`. Appliquer `selectedLabelStyle` et `unselectedLabelStyle` explicitement.
- Desktop : la sidebar est définie dans `company_dashboard_screen_desktop.dart` ET dans `company_planning_screen_desktop.dart` — deux implémentations séparées de la même sidebar. Toute modification doit être dupliquée. Extraire en `AppSidebar` widget partagé.
- Le `_selectedIndex` est un state local dans `MainShell` — si le shell est rebuild par un `ref.watch` (ex. `authStateProvider`), l'index peut se reset. Déplacer dans `shellNavProvider` pour la persistance.

---

### 4.3 Home (côté client)

#### HomeScreen — Mobile (`lib/features/home/presentation/screens/home_screen_mobile.dart`)

**But** : liste des salons avec filtres, bandeau d'accueil.

**Fonctionnalités** : banners (profil incomplet, geocoding, tomorrow reminder, diaspora, upcoming appointment), search filter bar, liste de salons avec skeleton loader, empty state.

**Écarts** :
- `_MobileAppBar` : non audité en détail mais utilise probablement `AppBar` du thème — à vérifier que `centerTitle: true` et pas de `title` (la home n'a pas de titre de page, juste le logo + filtres).
- Les banners sont empilés verticalement sans séparateur ni espacement normé — risque de collision visuelle si plusieurs banners sont visibles simultanément.
- L'empty state (zéro résultats) : non audité mais probablement un `Text` centré sans pattern normé.

**Recommandations** :
- Ajouter `SizedBox(height: AppSpacing.xs)` entre chaque banner.
- Auditer et aligner l'empty state sur le pattern §2.6.

---

#### HomeScreen — Desktop (`lib/features/home/presentation/screens/home_screen_desktop.dart`)

**But** : même contenu mais layout éditorial 3 colonnes.

**Structure** : brandbar, hero editorial gauche + image droite, search bar horizontale, grille 3 colonnes.

**Points positifs** : grille 3 colonnes avec `crossAxisSpacing: AppSpacing.lg`, max-width 1360, pattern très proche de `termini-editorial.html`.

**Écarts** :
- Le hero desktop importe `GoogleFonts.fraunces` directement pour la taille clamp — acceptable mais préférable d'ajouter un `h1Large` au `AppTextStyles` pour les usages `clamp(38px, 4vw, 56px)`.
- Le shimmer / skeleton de la grille desktop utilise `shimmer` package — cohérent avec mobile.
- Les cartes salon desktop (`company_card.dart`) : non lues en détail — vérifier que la hauteur d'image et les tokens sont cohérents avec la version mobile.

---

### 4.4 Company Detail (fiche salon côté client)

#### CompanyDetailScreen — Mobile (`lib/features/company_detail/presentation/screens/company_detail_screen_mobile.dart`)

**But** : fiche complète du salon — photos, info, services, employés, avis, CTA booking.

**Fonctionnalités** : `SliverAppBar` hero 280dp avec `PhotoGallery`, gradient de lisibilité, back button, share, favoris, infos salon, services par catégorie, CTA "PRENDRE RDV".

**Points positifs** : `SliverAppBar` épinglée correctement, PhotoGallery avec PageView horizontal.

**Écarts** :
- `SliverAppBar` : `pinned: true, expandedHeight: 280`. La back button est un widget custom `_BackButton` — non audité mais probablement cohérent avec le pattern login (container 40×40, radiusMd, border).
- Le gradient sur la photo (`Colors.black.withValues(alpha: 0.10)`) est très léger — l'icône share et le coeur peuvent être illisibles sur des photos claires. Passer à `0.20–0.30` en haut.
- CTA "PRENDRE RDV" : non audité en détail mais doit utiliser le pattern bouton primaire h=50, width=double.infinity.
- Employés : sélecteur d'employé non audité visuellement.

---

#### CompanyDetailScreen — Desktop (`lib/features/company_detail/presentation/screens/company_detail_screen_desktop.dart`)

Non lu en détail. D'après la structure du projet : probablement un layout deux colonnes (photos gauche, infos droite) ou similaire à `termini-editorial.html` section salon.

**Point à vérifier** : max-width conteneur, sidebar ou non, CTA sticky latéral.

---

### 4.5 Booking (prise de RDV client)

#### BookingScreen — Mobile (`lib/features/booking/presentation/screens/booking_screen_mobile.dart`)

**But** : tunnel de réservation en 2 étapes (sélection employé + créneau → confirmation).

**Fonctionnalités** : `StepIndicator` (2 étapes), `PageView` non scrollable manuellement, bottom nav bar avec boutons Précédent/Suivant/Confirmer.

**Points positifs** : utilisation de `StepIndicator`, `NeverScrollableScrollPhysics`, bottom bar bien gérée.

**Écarts** :
- `_MobileAppBar` affiche le `serviceName` dans le titre — si le service est long, il risque d'être tronqué. Ajouter `overflow: TextOverflow.ellipsis`.
- La bottom bar (`_MobileBottomNavBar`) contient les boutons navigation — non audité pour les heights (doivent être ≥ 48dp).
- Pas de skeleton pour l'étape de chargement employees — `_LoadingView` montre un `CircularProgressIndicator`. Remplacer par skeleton.

---

#### BookingScreen — Desktop (`lib/features/booking/presentation/screens/booking_screen_desktop.dart`)

Non lu en détail. À vérifier : layout deux-colonnes (sélection gauche / résumé droite), max-width.

---

### 4.6 Appointments (rendez-vous client)

#### AppointmentsScreen — Mobile (`lib/features/appointments/presentation/screens/appointments_screen_mobile.dart`)

**But** : liste des RDV du client (à venir + passés).

**Fonctionnalités** : deux sections (upcoming/past), `_EmptyCard` par section, `RefreshIndicator`, skeleton loader, `UpcomingAppointmentBanner`, `_AppointmentCard` avec annulation.

**Points positifs** : skeleton loading, empty state par section, séparation sections claire.

**Écarts** :
- Titre `h2` dans le body (pas d'AppBar) — incohérent avec `MyCompanyReviewsScreen` qui a une AppBar. Choisir un pattern (voir §2.1).
- `_SectionHeader` utilise une `Row(icon + Text)` — pattern ad hoc, à aligner sur le composant §2.2.
- `_EmptyCard` : container avec icône + texte — bon pattern, mais le radius et les couleurs ne sont pas audités. Vérifier l'alignement avec §2.6.
- Pas d'état d'erreur sur la section "past" séparément — si l'API échoue pour la liste past, toute la vue affiche l'erreur.

---

#### AppointmentsScreen — Desktop (`lib/features/appointments/presentation/screens/appointments_screen_desktop.dart`)

Non lu en détail. À vérifier : colonnes (upcoming gauche / past droite) ou liste unique centrée avec max-width.

---

### 4.7 Reviews

#### SubmitReviewScreen — Mobile (`lib/features/reviews/presentation/screens/submit_review_screen_mobile.dart`)

**But** : formulaire d'avis post-RDV (étoiles + commentaire).

**Fonctionnalités** : 5 étoiles tapables avec animation scale, textarea commentaire, submit.

**Points positifs** : feedback haptique, animation scale des étoiles, état `_submitted` avec card de confirmation.

**Écarts** :
- Les étoiles utilisent `AppColors.starRating` (`#C89B47` = secondary) — correct.
- L'état de succès : non audité pour la conformité token.
- Pas de variante desktop — `submit_review_screen_desktop.dart` existe mais non lu. À vérifier la cohérence.

---

#### MyCompanyReviewsScreen (`lib/features/company/presentation/screens/my_company_reviews_screen.dart`)

**But** : liste des avis reçus par le salon (côté owner).

**Fonctionnalités** : liste paginée, `_OwnerReviewCard`, load-more automatique.

**Écarts importants** :
- `my_company_reviews_screen.dart:36` : état de chargement = `CircularProgressIndicator` centré. Aucun skeleton.
- `my_company_reviews_screen.dart:37` : état vide = `Center(child: Text(...))` sans icône, sans structure — viole le pattern §2.6.
- Pas d'état d'erreur défini — si l'API échoue, rien n'est affiché.
- Le "load more" automatique via `WidgetsBinding.instance.addPostFrameCallback` est fragile (boucle infinie potentielle si `hasMore` reste true). Préférer un `ScrollController` avec threshold.
- Pas de variante desktop — écran uniquement mobile. Pour un dashboard owner desktop, cet écran devrait être intégré dans le panneau de contenu de la sidebar desktop ou avoir une variante dédiée.
- AppBar avec `iconTheme: IconThemeData(color: AppColors.textPrimary)` — superflu car déjà dans le thème.

**Recommandations** :
- Ajouter skeleton loader.
- Ajouter état vide conforme §2.6 (icône star_outline + texte).
- Ajouter état d'erreur conforme §2.8.
- Remplacer le load-more automatique par `ScrollController`.
- Planifier une variante desktop ou intégration dans le dashboard.

---

### 4.8 Company Dashboard (côté owner)

#### CompanyDashboardScreen — Mobile (`lib/features/company/presentation/screens/company_dashboard_screen_mobile.dart`)

**But** : dashboard de gestion du salon (infos, catégories, services, équipe, horaires, photos).

**Fonctionnalités** : skeleton dashboard, error view, liste de sections scrollable avec cartes, actions CRUD via callbacks.

**Points positifs** : `SkeletonDashboard` utilisé, callbacks bien typés, séparation logique/UI propre.

**Écarts** :
- Le body n'est pas audité ligne à ligne mais la structure est conforme.
- L'`AutoApproveCard` et `SalonGeocodingBanner` : widgets non audités visuellement.
- Pas d'AppBar sur cette version — le "retour" n'est pas applicable (c'est un tab shell). Correct.

---

#### CompanyDashboardScreen — Desktop (`lib/features/company/presentation/screens/company_dashboard_screen_desktop.dart`)

**But** : même contenu, layout deux colonnes (sidebar ~240px + contenu).

**Structure** : sidebar encre `textPrimary`, contenu scrollable ivoire.

**Écarts** :
- La sidebar est dupliquée avec `CompanyPlanningScreenDesktop` (voir §3.2 recommandation `AppSidebar`).
- Les typedefs callbacks sont également dupliqués (redéfinis en `_OnEditCompany` etc. préfixés `_` alors qu'ils sont identiques à ceux du fichier mobile). Externaliser dans un fichier partagé.

---

#### CompanyPlanningScreen — Mobile (`lib/features/company/presentation/screens/company_planning_screen_mobile.dart`)

**But** : vue planning des RDV par jour/semaine (grille timeline).

**Fonctionnalités** : grille timeline 15min-slots, navigation date, walk-in dialog, `NextAppointmentBanner`, annulation, rejet.

**Points positifs** : `kPlanningRowHeight`, `kPlanningTimeColumnWidth` comme constantes partagées, helpers `planningTimeToMinutes` etc. exportés.

**Écarts** :
- La grille utilise des couleurs custom inline (non vérifiable sans lecture complète). À vérifier l'usage de `AppColors` vs hardcoded.
- Navigation date : non audité pour le style du sélecteur de date (utilise-t-il le `DatePicker` thème ou un custom?).

---

#### CompanyPlanningScreen — Desktop (`lib/features/company/presentation/screens/company_planning_screen_desktop.dart`)

**Structure** : trois zones — sidebar, grille centrale, panneau droit approbations.

**Écart** : sidebar dupliquée (même problème que le dashboard desktop).

---

#### PendingApprovalsScreen (`lib/features/company/presentation/screens/pending_approvals_screen.dart`)

**But** : liste des RDV en attente d'approbation (mode capacity).

**Fonctionnalités** : skeleton, liste, approve/reject avec dialog, `RejectAppointmentDialog`.

**Écarts** :
- État vide : non audité — probablement manquant ou non conforme §2.6.
- `pending_approvals_screen.dart:80` : optimistic update puis fetch pour confirmation — bon pattern.
- Pas de variante desktop explicite — cet écran est probablement intégré dans le panneau droit du planning desktop. À confirmer.

**Signalement** : `PendingApprovalsScreen` n'a PAS de variante desktop/mobile explicite (pas de `_desktop`/`_mobile` files). Hors shell, il s'affiche tel quel sur toutes les tailles. À créer une variante desktop ou confirmer qu'il n'est utilisé qu'en panel.

---

#### CapacitySettingsScreen (`lib/features/company/presentation/screens/capacity_settings_screen.dart`)

**But** : configuration des pauses et jours off en mode capacity.

**Fonctionnalités** : liste breaks, liste jours off, ajout/suppression, dialog `AddDayOffDialog`.

**Écarts** :
- Pas de variante desktop.
- L'état de chargement et les états vides ne sont pas audités en détail.
- La logique d'état est locale (StateNotifier privé) — cohérent pour un écran de config isolé.

---

### 4.9 Employee Schedule

#### EmployeeScheduleScreen (`lib/features/employee_schedule/presentation/screens/employee_schedule_screen.dart`)

**But** : vue planning individuelle de l'employé (grille timeline identique au planning owner).

**Fonctionnalités** : grille 15min-slots, walk-in, annulation, même helpers que `CompanyPlanningScreen`.

**Signalement** : cet écran n'a PAS de variante desktop/mobile. Or il est affiché dans le shell qui a un contexte desktop — il devrait avoir une variante desktop ou au minimum être contraint à `maxWidth` sur grand écran.

---

#### ScheduleSettingsScreen (`lib/features/employee_schedule/presentation/screens/schedule_settings_screen.dart`)

**But** : configuration des horaires de travail, pauses et jours off de l'employé.

**Fonctionnalités** : 3 vues (`ScheduleView.all`, `hoursOnly`, `breaksAndDaysOff`), tableau des 7 jours, time pickers, `AddDayOffDialog`.

**Points positifs** : enum `ScheduleView` pour la flexibilité, initialisation defensive des 7 jours.

**Écarts** :
- Pas de variante desktop.
- L'état de chargement : non audité — probablement `CircularProgressIndicator`.
- Les time pickers : `showTimePicker` standard Material — cohérent mais non customisé pour le thème. Le dialog `TimePicker` utilisera `AppColors.primary` pour la sélection (via le `colorScheme`) — à vérifier.

---

### 4.10 Settings

#### SettingsScreen (`lib/features/settings/presentation/screens/settings_screen.dart`)

**But** : paramètres utilisateur (profil, pages, espace proprio, expérience, notifications, support, danger zone).

**Fonctionnalités** : édition profil avec avatar, sélecteur genre, changement MDP, notifications, langue, dark mode (UXPrefs), support, suppression compte.

**Points positifs** : anchor keys pour scroll-to-section (desktop sidebar), `startInProfileEdit` pour l'entrée depuis le banner.

**Écarts** :
- Pas de variante desktop explicite `settings_screen_desktop.dart`. La sidebar de settings (anchor scroll) est implémentée dans le même fichier. C'est fonctionnel mais la séparation mobile/desktop n'est pas appliquée ici contrairement aux autres écrans.
- L'avatar `AvatarEditor` est un widget partagé — à vérifier la conformité tokens.
- Les sections utilisent un pattern "header + contenu" ad hoc — non unifié avec §2.2.
- `GoogleFonts.fraunces` peut être appelé directement dans les section headers — à remplacer par `AppTextStyles.h3`.

---

### 4.11 Maintenance & Force Update

#### MaintenanceScreen (`lib/features/remote_config/presentation/screens/maintenance_screen.dart`)

**But** : écran bloquant en mode maintenance.

**Fonctionnalités** : icône + titre + corps. Pas de CTA.

**Écarts** :
- Icône `Icons.construction_rounded` size 72, `color: AppColors.primary` — correct.
- Texte localisé via `switch(locale)` hardcodé — ne bénéficie pas du système ARB. Acceptable pour un écran bloquant (pas de Scaffold avec localisation si l'app est en cours de démarrage).
- Pas de variante desktop — acceptable, cet écran est identique partout.
- Pas de logo de marque visible. Ajouter `BrandLogo` au-dessus de l'icône pour la cohérence de marque même en mode bloquant.

---

#### ForceUpdateScreen (`lib/features/remote_config/presentation/screens/force_update_screen.dart`)

**But** : écran bloquant de mise à jour forcée.

**Fonctionnalités** : icône + titre + corps + bouton store.

**Écarts** :
- `force_update_screen.dart:89` : `FilledButton` avec `backgroundColor: AppColors.primary`. C'est le seul endroit dans l'app où un `FilledButton` avec bourgogne est utilisé. Tous les autres CTA principaux utilisent `ElevatedButton` avec fond encre. Décision à documenter explicitement ou harmoniser.
- Même remarque que `MaintenanceScreen` : ajouter `BrandLogo`.
- `const url = String.fromEnvironment('FLUTTER_PLATFORM') == 'ios'` — cette détection ne fonctionne pas à runtime, seulement via `dart-define`. Remplacer par `Platform.isIOS` ou `defaultTargetPlatform == TargetPlatform.iOS`.

---

## §5 Plan d'action priorisé

### Quick wins (1–2h chacun)

| # | Action | Écran(s) | Impact |
|---|---|---|---|
| Q1 | Supprimer les valeurs de test email hardcodées | `login_screen.dart:31` | Release critique |
| Q2 | Remplacer `'TERMINI IM'` all-caps par `BrandLogo` | `login_screen.dart:315` | Conformité marque |
| Q3 | Corriger la détection de plateforme iOS dans `ForceUpdateScreen` | `force_update_screen.dart` | Bug silencieux |
| Q4 | Appliquer le pattern état vide normé à `MyCompanyReviewsScreen` | `my_company_reviews_screen.dart` | Cohérence UX |
| Q5 | Ajouter l'état d'erreur à `MyCompanyReviewsScreen` | `my_company_reviews_screen.dart` | Robustesse |
| Q6 | Corriger le format date DD/MM avec zéro padded dans `LandingScreen` | `landing_screen.dart` | Polish |
| Q7 | Retirer les `copyWith(color: ...)` superflus sur les styles qui ont déjà la bonne couleur | Plusieurs écrans | Lisibilité code |
| Q8 | Ajouter `BrandLogo` aux écrans `MaintenanceScreen` et `ForceUpdateScreen` | 2 fichiers | Cohérence marque |
| Q9 | Remplacer le `CircularProgressIndicator` plein écran par skeleton dans `MyCompanyReviewsScreen` | `my_company_reviews_screen.dart` | Cohérence loading |
| Q10 | Unifier `selectedLabelStyle`/`unselectedLabelStyle` sur la bottom nav dans `MainShell` | `main_shell.dart` | Cohérence typo |

### Refactors moyens (demi-journée chacun)

| # | Action | Écran(s) | Impact |
|---|---|---|---|
| M1 | Extraire `AppCard` widget partagé (Container + BoxDecoration normée) | Tous les écrans | Dette technique |
| M2 | Extraire `AppSidebar` widget partagé depuis dashboard + planning desktop | 2 fichiers desktop | Maintenabilité |
| M3 | Externaliser les typedefs callbacks dashboard en fichier partagé | `company_dashboard_screen_*.dart` | Maintenabilité |
| M4 | Ajouter `StepIndicator` à `SignupScreen` | `signup_screen.dart` | Cohérence UX |
| M5 | Unifier le pattern OTP : `ForgotPasswordScreen` → 6 cellules comme `EmailVerificationScreen` | `forgot_password_screen.dart` | Cohérence UX |
| M6 | Remplacer le load-more `PostFrameCallback` par `ScrollController` dans `MyCompanyReviewsScreen` | `my_company_reviews_screen.dart` | Robustesse |
| M7 | Extraire `_SalonInfoStep` partagé entre `SignupScreen` et `CompanySetupScreen` | 2 fichiers | Dette technique |
| M8 | Ajouter skeleton loader à `ScheduleSettingsScreen` et `EmployeeScheduleScreen` | 2 fichiers | Cohérence loading |

### Refactors lourds (1–2 jours chacun)

| # | Action | Écran(s) | Impact |
|---|---|---|---|
| L1 | Créer `landing_screen_desktop.dart` (split-screen hero + search card) | `landing_screen.dart` | Expérience web majeure |
| L2 | Créer `login_screen_desktop.dart` (split-screen branding + form) | `login_screen.dart` | Expérience web |
| L3 | Créer `signup_screen_desktop.dart` (split-screen) | `signup_screen.dart` | Expérience web |
| L4 | Créer variante desktop pour `EmployeeScheduleScreen` | `employee_schedule_screen.dart` | Responsive |
| L5 | Créer variante desktop pour `CapacitySettingsScreen` | `capacity_settings_screen.dart` | Responsive |
| L6 | Déplacer `_selectedIndex` de `MainShell` vers `shellNavProvider` | `main_shell.dart` | Robustesse état |
| L7 | Évaluer si `SettingsScreen` nécessite une vraie variante desktop (fichier dédié) ou si le layout courant suffit | `settings_screen.dart` | Architecture |

---

## §6 Checklist de conformité pour tout nouvel écran

À vérifier avant de merger un nouvel écran ou une modification majeure :

### Tokens et styles

- [ ] `scaffoldBackgroundColor: AppColors.background` explicite sur le `Scaffold`
- [ ] Aucune couleur hex hardcodée hors de `AppColors` (exception tolérée : dégradés bourgogne documentés en comment)
- [ ] Titres d'écran en `AppTextStyles.h2` ou `h3` — jamais `GoogleFonts.fraunces(...)` appelé directement
- [ ] Labels de section en `AppTextStyles.overline` + `.toUpperCase()`
- [ ] Espacement inter-champs = `AppSpacing.md` (16), inter-sections = `AppSpacing.lg` (24)
- [ ] Fin de liste scrollable : `SizedBox(height: AppSpacing.xxl)` pour safe area
- [ ] Bouton primaire : `ElevatedButton` h=50, fond `textPrimary`, texte `button.toUpperCase()`
- [ ] Bouton secondaire : `OutlinedButton` h=50, bordure `AppColors.border`
- [ ] Radius de champ : 10px (conforme `AppTheme.inputDecorationTheme`)

### États

- [ ] État de chargement : skeleton (préféré) ou `CircularProgressIndicator` localisé (pas plein écran)
- [ ] État vide : icône + titre `h3` + description `bodySmall` + CTA optionnel (pattern §2.6)
- [ ] État d'erreur : bannière inline conformément §2.8
- [ ] État succès : feedback visible (snackbar ou card conforme)

### Accessibilité

- [ ] Toutes les icônes sans texte ont un `tooltip` ou `Semantics(label: ...)`
- [ ] Touch targets ≥ 48dp (vérifier les `GestureDetector` custom avec `HitTestBehavior.opaque` ou padding suffisant)
- [ ] Contraste texte sur fond : `textPrimary` (#171311) sur `background` (#F7F2EA) → 13.4:1 — conforme AAA
- [ ] Contraste `textHint` (#716059) sur `surface` (#FCF7EE) → ~4.6:1 — limite AA, ne pas aller en dessous

### Responsive

- [ ] L'écran a une variante desktop si du contenu est dense ou si le layout mobile s'étire sur grand écran sans `maxWidth`
- [ ] Les formulaires utilisent `ConstrainedBox(constraints: BoxConstraints(maxWidth: 440–560))`
- [ ] Le contenu desktop utilise `ConstrainedBox(constraints: BoxConstraints(maxWidth: 1360))`
- [ ] La séparation mobile/desktop est faite via `ResponsiveLayout` (pas de `MediaQuery.of(context).size.width` inline)

### Navigation

- [ ] Le bouton retour (push screens) est un container 40×40, radius `radiusMd`, bordure `AppColors.border`, icône `Icons.arrow_back_rounded` size 20
- [ ] Les écrans shell (tabs) n'ont pas de back button
- [ ] Les modales/sheets ont le drag handle normé (§2.10)

### Marque

- [ ] Pas de `'TERMINI IM'` en all-caps avec espacement large
- [ ] Le logo utilise `BrandLogo` widget avec la bonne variante (`ivory` sur fond bourgogne, `burgundy` sur fond clair)
- [ ] Le wordmark textuel utilise le pattern Instrument Sans "Termini " + Instrument Serif italic or "im"

---

## Annexe — Écrans sans variante desktop identifiés

Les écrans suivants n'ont PAS de variante desktop et devraient en avoir (selon la densité de contenu et l'audience) :

| Écran | Priorité | Raison |
|---|---|---|
| `LandingScreen` | Haute | Page d'accueil publique web — expérience dégradée |
| `LoginScreen` | Haute | Auth sur web fréquente pour les owners |
| `SignupScreen` | Haute | Inscription owners souvent sur desktop |
| `ForgotPasswordScreen` | Moyenne | Flow court, maxWidth suffit peut-être |
| `EmployeeScheduleScreen` | Haute | Interface métier vue en permanence |
| `ScheduleSettingsScreen` | Moyenne | Interface de config |
| `CapacitySettingsScreen` | Moyenne | Interface de config |
| `MyCompanyReviewsScreen` | Basse | Secondaire, peu fréquenté |
| `CompanySetupScreen` | Basse | Flow ponctuel |

Les écrans suivants n'ont PAS de variante desktop et c'est **acceptable** :

| Écran | Raison |
|---|---|
| `MaintenanceScreen` | Écran bloquant identique partout |
| `ForceUpdateScreen` | Écran bloquant identique partout |
| `EmailVerificationScreen` | Flow ponctuel, court |
| `PendingApprovalsScreen` | Intégré en panel dans le desktop planning |
