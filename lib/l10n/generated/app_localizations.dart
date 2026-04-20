import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_sq.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('sq'),
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Termini im'**
  String get appName;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get signup;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// No description provided for @firstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get lastName;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// No description provided for @companyName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'entreprise'**
  String get companyName;

  /// No description provided for @address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get address;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas de compte ?'**
  String get noAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get alreadyHaveAccount;

  /// No description provided for @signupNow.
  ///
  /// In fr, this message translates to:
  /// **'Inscrivez-vous'**
  String get signupNow;

  /// No description provided for @loginNow.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous'**
  String get loginNow;

  /// No description provided for @orContinueWith.
  ///
  /// In fr, this message translates to:
  /// **'Ou continuer avec'**
  String get orContinueWith;

  /// No description provided for @continueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithFacebook.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Facebook'**
  String get continueWithFacebook;

  /// No description provided for @continueWithApple.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Apple'**
  String get continueWithApple;

  /// No description provided for @iAmUser.
  ///
  /// In fr, this message translates to:
  /// **'Je suis un client'**
  String get iAmUser;

  /// No description provided for @iAmUserSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Trouvez et réservez vos rendez-vous beauté'**
  String get iAmUserSubtitle;

  /// No description provided for @iAmCompany.
  ///
  /// In fr, this message translates to:
  /// **'Je suis un professionnel'**
  String get iAmCompany;

  /// No description provided for @iAmCompanySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Gérez votre salon et vos réservations'**
  String get iAmCompanySubtitle;

  /// No description provided for @chooseRole.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre profil'**
  String get chooseRole;

  /// No description provided for @chooseRoleSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment souhaitez-vous utiliser Termini im ?'**
  String get chooseRoleSubtitle;

  /// No description provided for @searchPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un salon...'**
  String get searchPlaceholder;

  /// No description provided for @filterMen.
  ///
  /// In fr, this message translates to:
  /// **'Homme'**
  String get filterMen;

  /// No description provided for @filterWomen.
  ///
  /// In fr, this message translates to:
  /// **'Femme'**
  String get filterWomen;

  /// No description provided for @filterBoth.
  ///
  /// In fr, this message translates to:
  /// **'Les deux'**
  String get filterBoth;

  /// No description provided for @morning.
  ///
  /// In fr, this message translates to:
  /// **'MATIN'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In fr, this message translates to:
  /// **'APRÈS-MIDI'**
  String get afternoon;

  /// No description provided for @bookAppointment.
  ///
  /// In fr, this message translates to:
  /// **'Prendre RDV'**
  String get bookAppointment;

  /// No description provided for @moreInfo.
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'informations'**
  String get moreInfo;

  /// No description provided for @reviews.
  ///
  /// In fr, this message translates to:
  /// **'{count} avis'**
  String reviews(int count);

  /// No description provided for @gallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get gallery;

  /// No description provided for @categories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categories;

  /// No description provided for @services.
  ///
  /// In fr, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @choose.
  ///
  /// In fr, this message translates to:
  /// **'Choisir'**
  String get choose;

  /// No description provided for @price.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get price;

  /// No description provided for @duration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get duration;

  /// No description provided for @minutes.
  ///
  /// In fr, this message translates to:
  /// **'{count} min'**
  String minutes(int count);

  /// No description provided for @step1Title.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un employé'**
  String get step1Title;

  /// No description provided for @step2Title.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un créneau'**
  String get step2Title;

  /// No description provided for @step3Title.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation'**
  String get step3Title;

  /// No description provided for @noPreference.
  ///
  /// In fr, this message translates to:
  /// **'Sans préférence'**
  String get noPreference;

  /// No description provided for @selectDate.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une heure'**
  String get selectTime;

  /// No description provided for @confirmBooking.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la réservation'**
  String get confirmBooking;

  /// No description provided for @bookingConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Réservation confirmée !'**
  String get bookingConfirmed;

  /// No description provided for @bookingConfirmedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre rendez-vous a été réservé avec succès.'**
  String get bookingConfirmedMessage;

  /// No description provided for @backToHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backToHome;

  /// No description provided for @employee.
  ///
  /// In fr, this message translates to:
  /// **'Employé'**
  String get employee;

  /// No description provided for @dateAndTime.
  ///
  /// In fr, this message translates to:
  /// **'Date et heure'**
  String get dateAndTime;

  /// No description provided for @service.
  ///
  /// In fr, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @summary.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif'**
  String get summary;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get previous;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @noResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get noResults;

  /// No description provided for @noResultsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun salon trouvé pour votre recherche.'**
  String get noResultsMessage;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @albanian.
  ///
  /// In fr, this message translates to:
  /// **'Shqip'**
  String get albanian;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @emailRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'email est requis'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get emailInvalid;

  /// No description provided for @emailAlreadyUsed.
  ///
  /// In fr, this message translates to:
  /// **'Cet email est déjà utilisé'**
  String get emailAlreadyUsed;

  /// No description provided for @passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est requis'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 8 caractères'**
  String get passwordTooShort;

  /// No description provided for @passwordNeedsUpper.
  ///
  /// In fr, this message translates to:
  /// **'Doit contenir au moins une majuscule'**
  String get passwordNeedsUpper;

  /// No description provided for @passwordNeedsLower.
  ///
  /// In fr, this message translates to:
  /// **'Doit contenir au moins une minuscule'**
  String get passwordNeedsLower;

  /// No description provided for @passwordNeedsNumber.
  ///
  /// In fr, this message translates to:
  /// **'Doit contenir au moins un chiffre'**
  String get passwordNeedsNumber;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordsDoNotMatch;

  /// No description provided for @firstNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le prénom est requis'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est requis'**
  String get lastNameRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le téléphone est requis'**
  String get phoneRequired;

  /// No description provided for @filterGenderLabel.
  ///
  /// In fr, this message translates to:
  /// **'Genre'**
  String get filterGenderLabel;

  /// No description provided for @filterCityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ville / Salon'**
  String get filterCityLabel;

  /// No description provided for @filterCityHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Prishtina, Salon Elegance...'**
  String get filterCityHint;

  /// No description provided for @filterCitySalonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Ville ou nom du salon'**
  String get filterCitySalonLabel;

  /// No description provided for @filterDateLabel.
  ///
  /// In fr, this message translates to:
  /// **'À tout moment'**
  String get filterDateLabel;

  /// No description provided for @filterDateWhen.
  ///
  /// In fr, this message translates to:
  /// **'Quand ?'**
  String get filterDateWhen;

  /// No description provided for @filterClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get filterClear;

  /// No description provided for @filterSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get filterSearch;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @editProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get editProfile;

  /// No description provided for @personalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get personalInfo;

  /// No description provided for @saveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get saveChanges;

  /// No description provided for @changesSaved.
  ///
  /// In fr, this message translates to:
  /// **'Modifications enregistrées'**
  String get changesSaved;

  /// No description provided for @changePassword.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le nouveau mot de passe'**
  String get confirmNewPassword;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez les notifications que vous souhaitez recevoir'**
  String get notificationsSubtitle;

  /// No description provided for @notifNewBookingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau rendez-vous'**
  String get notifNewBookingLabel;

  /// No description provided for @notifNewBookingDesc.
  ///
  /// In fr, this message translates to:
  /// **'Notification à chaque nouvelle réservation'**
  String get notifNewBookingDesc;

  /// No description provided for @notifQuietDayLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rappel 1h avant (jours calmes)'**
  String get notifQuietDayLabel;

  /// No description provided for @notifQuietDayDesc.
  ///
  /// In fr, this message translates to:
  /// **'Rappel envoyé 1h avant le RDV si ≤ 2 RDV ce jour-là'**
  String get notifQuietDayDesc;

  /// No description provided for @notifPermissionBannerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications désactivées'**
  String get notifPermissionBannerTitle;

  /// No description provided for @notifPermissionBannerBody.
  ///
  /// In fr, this message translates to:
  /// **'Activez-les dans les réglages de votre appareil pour recevoir les rappels.'**
  String get notifPermissionBannerBody;

  /// No description provided for @openSettings.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les réglages'**
  String get openSettings;

  /// No description provided for @deleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get deleteAccount;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible'**
  String get deleteAccountWarning;

  /// No description provided for @logoutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir vous déconnecter ?'**
  String get logoutConfirm;

  /// No description provided for @rememberMe.
  ///
  /// In fr, this message translates to:
  /// **'Se souvenir de moi'**
  String get rememberMe;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre email pour recevoir un lien de réinitialisation'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get sendResetLink;

  /// No description provided for @resetEmailSent.
  ///
  /// In fr, this message translates to:
  /// **'Un email de réinitialisation a été envoyé'**
  String get resetEmailSent;

  /// No description provided for @resetToken.
  ///
  /// In fr, this message translates to:
  /// **'Code de réinitialisation'**
  String get resetToken;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié avec succès'**
  String get resetPasswordSuccess;

  /// No description provided for @resetPassword.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get resetPassword;

  /// No description provided for @emailNotVerifiedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Email non vérifié'**
  String get emailNotVerifiedTitle;

  /// No description provided for @emailNotVerifiedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez vérifier votre email pour pouvoir prendre rendez-vous.'**
  String get emailNotVerifiedMessage;

  /// No description provided for @security.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get security;

  /// No description provided for @yourInfo.
  ///
  /// In fr, this message translates to:
  /// **'Vos informations'**
  String get yourInfo;

  /// No description provided for @yourCompany.
  ///
  /// In fr, this message translates to:
  /// **'Votre entreprise'**
  String get yourCompany;

  /// No description provided for @stepOf.
  ///
  /// In fr, this message translates to:
  /// **'Étape {current}/{total}'**
  String stepOf(int current, int total);

  /// No description provided for @signupSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre compte en quelques secondes'**
  String get signupSubtitle;

  /// No description provided for @companyNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Mon Salon'**
  String get companyNameHint;

  /// No description provided for @companyNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom de l\'entreprise est requis'**
  String get companyNameRequired;

  /// No description provided for @addressRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'adresse est requise'**
  String get addressRequired;

  /// No description provided for @city.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get city;

  /// No description provided for @searchWhen.
  ///
  /// In fr, this message translates to:
  /// **'Quand'**
  String get searchWhen;

  /// No description provided for @searchWho.
  ///
  /// In fr, this message translates to:
  /// **'Qui'**
  String get searchWho;

  /// No description provided for @cityHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Prishtinë, Prizren...'**
  String get cityHint;

  /// No description provided for @cityDescription.
  ///
  /// In fr, this message translates to:
  /// **'Nous utiliserons votre ville pour vous recommander les salons les plus proches de chez vous.'**
  String get cityDescription;

  /// No description provided for @cityCompany.
  ///
  /// In fr, this message translates to:
  /// **'Ville de l\'entreprise'**
  String get cityCompany;

  /// No description provided for @cityCompanyDescription.
  ///
  /// In fr, this message translates to:
  /// **'La ville où se situe votre salon. Elle sera aussi utilisée pour votre profil.'**
  String get cityCompanyDescription;

  /// No description provided for @cityRequired.
  ///
  /// In fr, this message translates to:
  /// **'La ville est requise'**
  String get cityRequired;

  /// No description provided for @findYourSalon.
  ///
  /// In fr, this message translates to:
  /// **'Trouvez votre salon idéal'**
  String get findYourSalon;

  /// No description provided for @loginToBook.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour réserver'**
  String get loginToBook;

  /// No description provided for @loginToBookMessage.
  ///
  /// In fr, this message translates to:
  /// **'Pour prendre rendez-vous, vous devez avoir un compte.'**
  String get loginToBookMessage;

  /// No description provided for @continueWithoutAccount.
  ///
  /// In fr, this message translates to:
  /// **'Continuer sans compte'**
  String get continueWithoutAccount;

  /// No description provided for @welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue'**
  String get welcome;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @myAppointments.
  ///
  /// In fr, this message translates to:
  /// **'Mes RDV'**
  String get myAppointments;

  /// No description provided for @upcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get upcoming;

  /// No description provided for @past.
  ///
  /// In fr, this message translates to:
  /// **'Passés'**
  String get past;

  /// No description provided for @noUpcomingAppointments.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rendez-vous à venir'**
  String get noUpcomingAppointments;

  /// No description provided for @noPastAppointments.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rendez-vous passé'**
  String get noPastAppointments;

  /// No description provided for @seeMorePastAppointments.
  ///
  /// In fr, this message translates to:
  /// **'Voir {count} de plus'**
  String seeMorePastAppointments(int count);

  /// No description provided for @appointmentConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmé'**
  String get appointmentConfirmed;

  /// No description provided for @appointmentPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get appointmentPending;

  /// No description provided for @appointmentCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get appointmentCompleted;

  /// No description provided for @appointmentCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get appointmentCancelled;

  /// No description provided for @appointmentRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusé'**
  String get appointmentRejected;

  /// No description provided for @appointmentNoShow.
  ///
  /// In fr, this message translates to:
  /// **'Absent'**
  String get appointmentNoShow;

  /// No description provided for @appointmentNoShowDetail.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne vous êtes pas présenté à ce rendez-vous.'**
  String get appointmentNoShowDetail;

  /// No description provided for @mySalon.
  ///
  /// In fr, this message translates to:
  /// **'Mon Salon'**
  String get mySalon;

  /// No description provided for @companyInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations du salon'**
  String get companyInfo;

  /// No description provided for @servicesAndCategories.
  ///
  /// In fr, this message translates to:
  /// **'Services & Catégories'**
  String get servicesAndCategories;

  /// No description provided for @team.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get team;

  /// No description provided for @openingHours.
  ///
  /// In fr, this message translates to:
  /// **'Horaires d\'ouverture'**
  String get openingHours;

  /// No description provided for @addCategory.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une catégorie'**
  String get addCategory;

  /// No description provided for @addService.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un service'**
  String get addService;

  /// No description provided for @inviteEmployee.
  ///
  /// In fr, this message translates to:
  /// **'Inviter un employé'**
  String get inviteEmployee;

  /// No description provided for @createEmployee.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get createEmployee;

  /// No description provided for @closed.
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get closed;

  /// No description provided for @categoryName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la catégorie'**
  String get categoryName;

  /// No description provided for @serviceDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée (minutes)'**
  String get serviceDuration;

  /// No description provided for @servicePrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix (€)'**
  String get servicePrice;

  /// No description provided for @employeeEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email de l\'employé'**
  String get employeeEmail;

  /// No description provided for @specialties.
  ///
  /// In fr, this message translates to:
  /// **'Spécialités'**
  String get specialties;

  /// No description provided for @active.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get inactive;

  /// No description provided for @assignedServices.
  ///
  /// In fr, this message translates to:
  /// **'Services assignés'**
  String get assignedServices;

  /// No description provided for @noServicesAssigned.
  ///
  /// In fr, this message translates to:
  /// **'Aucun service assigné'**
  String get noServicesAssigned;

  /// No description provided for @myPlanning.
  ///
  /// In fr, this message translates to:
  /// **'Mon Planning'**
  String get myPlanning;

  /// No description provided for @available.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get available;

  /// No description provided for @walkIn.
  ///
  /// In fr, this message translates to:
  /// **'Sans RDV'**
  String get walkIn;

  /// No description provided for @addWalkIn.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un client'**
  String get addWalkIn;

  /// No description provided for @nextAppointment.
  ///
  /// In fr, this message translates to:
  /// **'Prochain rendez-vous'**
  String get nextAppointment;

  /// No description provided for @noAppointmentsToday.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rendez-vous aujourd\'hui'**
  String get noAppointmentsToday;

  /// No description provided for @clientFirstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom du client'**
  String get clientFirstName;

  /// No description provided for @clientLastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du client (optionnel)'**
  String get clientLastName;

  /// No description provided for @clientPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (optionnel)'**
  String get clientPhone;

  /// No description provided for @scheduleSettings.
  ///
  /// In fr, this message translates to:
  /// **'Horaires'**
  String get scheduleSettings;

  /// No description provided for @myWorkHours.
  ///
  /// In fr, this message translates to:
  /// **'Mes horaires de travail'**
  String get myWorkHours;

  /// No description provided for @companyHoursHint.
  ///
  /// In fr, this message translates to:
  /// **'Salon : {hours}'**
  String companyHoursHint(String hours);

  /// No description provided for @breaks.
  ///
  /// In fr, this message translates to:
  /// **'Pauses'**
  String get breaks;

  /// No description provided for @addBreak.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une pause'**
  String get addBreak;

  /// No description provided for @breakLabel.
  ///
  /// In fr, this message translates to:
  /// **'Libellé (optionnel)'**
  String get breakLabel;

  /// No description provided for @daysOff.
  ///
  /// In fr, this message translates to:
  /// **'Jours de congé'**
  String get daysOff;

  /// No description provided for @addDayOff.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un jour de congé'**
  String get addDayOff;

  /// No description provided for @reason.
  ///
  /// In fr, this message translates to:
  /// **'Motif (optionnel)'**
  String get reason;

  /// No description provided for @dayOffReasonHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Congé annuel'**
  String get dayOffReasonHint;

  /// No description provided for @everyDay.
  ///
  /// In fr, this message translates to:
  /// **'Tous les jours'**
  String get everyDay;

  /// No description provided for @breakSlot.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get breakSlot;

  /// No description provided for @working.
  ///
  /// In fr, this message translates to:
  /// **'Travaille'**
  String get working;

  /// No description provided for @notWorking.
  ///
  /// In fr, this message translates to:
  /// **'Ne travaille pas'**
  String get notWorking;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @dayOff.
  ///
  /// In fr, this message translates to:
  /// **'Jour de congé'**
  String get dayOff;

  /// No description provided for @youDontWorkToday.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne travaillez pas ce jour'**
  String get youDontWorkToday;

  /// No description provided for @landingHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Réservez votre créneau en quelques secondes.'**
  String get landingHeroSubtitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous à votre compte'**
  String get loginSubtitle;

  /// No description provided for @bookingAppBarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prendre RDV'**
  String get bookingAppBarTitle;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @continueLabel.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueLabel;

  /// No description provided for @bookingSuccessMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre rendez-vous a été pris avec succès. Vous recevrez une confirmation par notification.'**
  String get bookingSuccessMessage;

  /// No description provided for @bookingConfirmationSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez les détails avant de confirmer.'**
  String get bookingConfirmationSubtitle;

  /// No description provided for @yourAppointment.
  ///
  /// In fr, this message translates to:
  /// **'Votre rendez-vous'**
  String get yourAppointment;

  /// No description provided for @reminderNote.
  ///
  /// In fr, this message translates to:
  /// **'Un rappel vous sera envoyé 24h avant votre rendez-vous.'**
  String get reminderNote;

  /// No description provided for @hairdresser.
  ///
  /// In fr, this message translates to:
  /// **'Coiffeur(se)'**
  String get hairdresser;

  /// No description provided for @noPreferenceShort.
  ///
  /// In fr, this message translates to:
  /// **'Sans préf.'**
  String get noPreferenceShort;

  /// No description provided for @dateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @timeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get timeLabel;

  /// No description provided for @selectDateHint.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez une date ci-dessus.'**
  String get selectDateHint;

  /// No description provided for @noSlotsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun créneau disponible\npour cette date.'**
  String get noSlotsAvailable;

  /// No description provided for @slotStatusDayOff.
  ///
  /// In fr, this message translates to:
  /// **'Congé'**
  String get slotStatusDayOff;

  /// No description provided for @slotStatusNotWorking.
  ///
  /// In fr, this message translates to:
  /// **'Absent'**
  String get slotStatusNotWorking;

  /// No description provided for @slotStatusFull.
  ///
  /// In fr, this message translates to:
  /// **'Complet'**
  String get slotStatusFull;

  /// No description provided for @ourServices.
  ///
  /// In fr, this message translates to:
  /// **'Nos services'**
  String get ourServices;

  /// No description provided for @orDivider.
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get orDivider;

  /// No description provided for @resultsFound.
  ///
  /// In fr, this message translates to:
  /// **'{count} résultat{plural} trouvé{plural}'**
  String resultsFound(int count, String plural);

  /// No description provided for @salonsNearby.
  ///
  /// In fr, this message translates to:
  /// **'{count} salon{plural} près de vous'**
  String salonsNearby(int count, String plural);

  /// No description provided for @phoneCopied.
  ///
  /// In fr, this message translates to:
  /// **'Numéro copié : {phone}'**
  String phoneCopied(String phone);

  /// No description provided for @selectServiceRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un service'**
  String get selectServiceRequired;

  /// No description provided for @walkInSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Client ajouté avec succès'**
  String get walkInSuccess;

  /// No description provided for @walkInError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'ajout'**
  String get walkInError;

  /// No description provided for @todayLabel.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get todayLabel;

  /// No description provided for @previousDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour précédent'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour suivant'**
  String get nextDay;

  /// No description provided for @previousWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine précédente'**
  String get previousWeek;

  /// No description provided for @nextWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine suivante'**
  String get nextWeek;

  /// No description provided for @previousMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois précédent'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois suivant'**
  String get nextMonth;

  /// No description provided for @noBreaksConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Aucune pause configurée'**
  String get noBreaksConfigured;

  /// No description provided for @noLeavePlanned.
  ///
  /// In fr, this message translates to:
  /// **'Aucun congé planifié'**
  String get noLeavePlanned;

  /// No description provided for @noServicesConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Aucun service configuré'**
  String get noServicesConfigured;

  /// No description provided for @dayOfWeekLabel.
  ///
  /// In fr, this message translates to:
  /// **'Jour de la semaine'**
  String get dayOfWeekLabel;

  /// No description provided for @startTimeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get startTimeLabel;

  /// No description provided for @endTimeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get endTimeLabel;

  /// No description provided for @employeeScheduleHint.
  ///
  /// In fr, this message translates to:
  /// **'Horaires : {hours}'**
  String employeeScheduleHint(String hours);

  /// No description provided for @phoneSecondary.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone secondaire'**
  String get phoneSecondary;

  /// No description provided for @descriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @monday.
  ///
  /// In fr, this message translates to:
  /// **'Lundi'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In fr, this message translates to:
  /// **'Mardi'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In fr, this message translates to:
  /// **'Mercredi'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In fr, this message translates to:
  /// **'Jeudi'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In fr, this message translates to:
  /// **'Vendredi'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In fr, this message translates to:
  /// **'Samedi'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In fr, this message translates to:
  /// **'Dimanche'**
  String get sunday;

  /// No description provided for @monthJan.
  ///
  /// In fr, this message translates to:
  /// **'janvier'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In fr, this message translates to:
  /// **'février'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In fr, this message translates to:
  /// **'mars'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In fr, this message translates to:
  /// **'avril'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In fr, this message translates to:
  /// **'mai'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In fr, this message translates to:
  /// **'juin'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In fr, this message translates to:
  /// **'juillet'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In fr, this message translates to:
  /// **'août'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In fr, this message translates to:
  /// **'septembre'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In fr, this message translates to:
  /// **'octobre'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In fr, this message translates to:
  /// **'novembre'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In fr, this message translates to:
  /// **'décembre'**
  String get monthDec;

  /// No description provided for @monthShortJan.
  ///
  /// In fr, this message translates to:
  /// **'Jan'**
  String get monthShortJan;

  /// No description provided for @monthShortFeb.
  ///
  /// In fr, this message translates to:
  /// **'Fév'**
  String get monthShortFeb;

  /// No description provided for @monthShortMar.
  ///
  /// In fr, this message translates to:
  /// **'Mar'**
  String get monthShortMar;

  /// No description provided for @monthShortApr.
  ///
  /// In fr, this message translates to:
  /// **'Avr'**
  String get monthShortApr;

  /// No description provided for @monthShortMay.
  ///
  /// In fr, this message translates to:
  /// **'Mai'**
  String get monthShortMay;

  /// No description provided for @monthShortJun.
  ///
  /// In fr, this message translates to:
  /// **'Juin'**
  String get monthShortJun;

  /// No description provided for @monthShortJul.
  ///
  /// In fr, this message translates to:
  /// **'Juil'**
  String get monthShortJul;

  /// No description provided for @monthShortAug.
  ///
  /// In fr, this message translates to:
  /// **'Août'**
  String get monthShortAug;

  /// No description provided for @monthShortSep.
  ///
  /// In fr, this message translates to:
  /// **'Sep'**
  String get monthShortSep;

  /// No description provided for @monthShortOct.
  ///
  /// In fr, this message translates to:
  /// **'Oct'**
  String get monthShortOct;

  /// No description provided for @monthShortNov.
  ///
  /// In fr, this message translates to:
  /// **'Nov'**
  String get monthShortNov;

  /// No description provided for @monthShortDec.
  ///
  /// In fr, this message translates to:
  /// **'Déc'**
  String get monthShortDec;

  /// No description provided for @dayShortMon.
  ///
  /// In fr, this message translates to:
  /// **'lun.'**
  String get dayShortMon;

  /// No description provided for @dayShortTue.
  ///
  /// In fr, this message translates to:
  /// **'mar.'**
  String get dayShortTue;

  /// No description provided for @dayShortWed.
  ///
  /// In fr, this message translates to:
  /// **'mer.'**
  String get dayShortWed;

  /// No description provided for @dayShortThu.
  ///
  /// In fr, this message translates to:
  /// **'jeu.'**
  String get dayShortThu;

  /// No description provided for @dayShortFri.
  ///
  /// In fr, this message translates to:
  /// **'ven.'**
  String get dayShortFri;

  /// No description provided for @dayShortSat.
  ///
  /// In fr, this message translates to:
  /// **'sam.'**
  String get dayShortSat;

  /// No description provided for @dayShortSun.
  ///
  /// In fr, this message translates to:
  /// **'dim.'**
  String get dayShortSun;

  /// No description provided for @bookingModeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mode de réservation'**
  String get bookingModeTitle;

  /// No description provided for @bookingModeCapacityBasedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Un seul accueil'**
  String get bookingModeCapacityBasedTitle;

  /// No description provided for @bookingModeCapacityBasedShort.
  ///
  /// In fr, this message translates to:
  /// **'Idéal si vous gérez seul tous les RDV'**
  String get bookingModeCapacityBasedShort;

  /// No description provided for @bookingModeCapacityBasedDescription.
  ///
  /// In fr, this message translates to:
  /// **'Vous gérez tous les rendez-vous. Définissez une capacité par service (ex: 3 coupes simultanées). Les clients voient uniquement des créneaux.'**
  String get bookingModeCapacityBasedDescription;

  /// No description provided for @bookingModeEmployeeBasedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Chacun gère ses RDV'**
  String get bookingModeEmployeeBasedTitle;

  /// No description provided for @bookingModeEmployeeBasedShort.
  ///
  /// In fr, this message translates to:
  /// **'Chaque employé a son propre planning'**
  String get bookingModeEmployeeBasedShort;

  /// No description provided for @bookingModeEmployeeBasedDescription.
  ///
  /// In fr, this message translates to:
  /// **'Chaque employé a son propre planning. Les clients choisissent leur coiffeur au moment de la réservation.'**
  String get bookingModeEmployeeBasedDescription;

  /// No description provided for @settingsEditableLater.
  ///
  /// In fr, this message translates to:
  /// **'Tous ces paramètres peuvent être modifiés plus tard.'**
  String get settingsEditableLater;

  /// No description provided for @maxConcurrent.
  ///
  /// In fr, this message translates to:
  /// **'Rendez-vous simultanés max'**
  String get maxConcurrent;

  /// No description provided for @capacitySettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Capacité & pauses'**
  String get capacitySettingsTitle;

  /// No description provided for @reducedCapacityDays.
  ///
  /// In fr, this message translates to:
  /// **'Jours à capacité réduite'**
  String get reducedCapacityDays;

  /// No description provided for @spotsRemaining.
  ///
  /// In fr, this message translates to:
  /// **'{count,plural,=1{1 place} other{{count} places}}'**
  String spotsRemaining(num count);

  /// No description provided for @pendingEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tout est à jour.'**
  String get pendingEmptyTitle;

  /// No description provided for @pendingEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande en attente pour le moment.'**
  String get pendingEmptySubtitle;

  /// No description provided for @pendingApprovals.
  ///
  /// In fr, this message translates to:
  /// **'Demandes en attente'**
  String get pendingApprovals;

  /// No description provided for @pendingApprovalsShort.
  ///
  /// In fr, this message translates to:
  /// **'Demandes'**
  String get pendingApprovalsShort;

  /// No description provided for @approve.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get reject;

  /// No description provided for @bookingPendingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée'**
  String get bookingPendingTitle;

  /// No description provided for @bookingPendingMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande a été envoyée. Le salon va confirmer ou refuser dans les meilleurs délais.'**
  String get bookingPendingMessage;

  /// No description provided for @changeBookingModeWarning.
  ///
  /// In fr, this message translates to:
  /// **'Basculer vers {mode}. Les rendez-vous déjà réservés seront conservés. Continuer ?'**
  String changeBookingModeWarning(String mode);

  /// No description provided for @confirmAppointment.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirmAppointment;

  /// No description provided for @rejectAppointment.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get rejectAppointment;

  /// No description provided for @cancelAppointment.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le rendez-vous'**
  String get cancelAppointment;

  /// No description provided for @confirmRejectTitle.
  ///
  /// In fr, this message translates to:
  /// **'Refuser ce rendez-vous ?'**
  String get confirmRejectTitle;

  /// No description provided for @confirmCancelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ce rendez-vous ?'**
  String get confirmCancelTitle;

  /// No description provided for @actionFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'action. Réessayez.'**
  String get actionFailed;

  /// No description provided for @viewDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour'**
  String get viewDay;

  /// No description provided for @viewWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine'**
  String get viewWeek;

  /// No description provided for @viewMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get viewMonth;

  /// No description provided for @errorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de joindre le serveur. Vérifiez votre connexion.'**
  String get errorNetwork;

  /// No description provided for @errorUnauthorized.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée. Reconnectez-vous.'**
  String get errorUnauthorized;

  /// No description provided for @errorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Élément introuvable.'**
  String get errorNotFound;

  /// No description provided for @errorServer.
  ///
  /// In fr, this message translates to:
  /// **'Erreur serveur. Réessayez plus tard.'**
  String get errorServer;

  /// No description provided for @errorUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez.'**
  String get errorUnknown;

  /// No description provided for @homeBrandTagline.
  ///
  /// In fr, this message translates to:
  /// **'Salons & Barbiers · Prishtina'**
  String get homeBrandTagline;

  /// No description provided for @homeHeroOverline.
  ///
  /// In fr, this message translates to:
  /// **'Annuaire · Salons & Barbiers'**
  String get homeHeroOverline;

  /// No description provided for @homeHeroTitlePrefix.
  ///
  /// In fr, this message translates to:
  /// **'Prishtina\nse '**
  String get homeHeroTitlePrefix;

  /// No description provided for @homeHeroTitleItalic.
  ///
  /// In fr, this message translates to:
  /// **'coiffe.'**
  String get homeHeroTitleItalic;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Une sélection curatée de salons à travers le Kosovo.\nRéservation instantanée, confirmation sous 2 minutes.'**
  String get homeHeroSubtitle;

  /// No description provided for @homeResultsOverline.
  ///
  /// In fr, this message translates to:
  /// **'Résultats · Prishtinë'**
  String get homeResultsOverline;

  /// No description provided for @homeResultsOverlineSearch.
  ///
  /// In fr, this message translates to:
  /// **'Résultats · Recherche'**
  String get homeResultsOverlineSearch;

  /// No description provided for @homeSortLabel.
  ///
  /// In fr, this message translates to:
  /// **'Tri : Note · Distance'**
  String get homeSortLabel;

  /// No description provided for @landingHeroLine1.
  ///
  /// In fr, this message translates to:
  /// **'Salons du'**
  String get landingHeroLine1;

  /// No description provided for @landingHeroLine2.
  ///
  /// In fr, this message translates to:
  /// **'Kosovo'**
  String get landingHeroLine2;

  /// No description provided for @capacityBasedHint1.
  ///
  /// In fr, this message translates to:
  /// **'Vous définissez une capacité par service (ex : 3 coupes en même temps).'**
  String get capacityBasedHint1;

  /// No description provided for @capacityBasedHint2.
  ///
  /// In fr, this message translates to:
  /// **'Les clients choisissent un créneau — pas d\'employé visible.'**
  String get capacityBasedHint2;

  /// No description provided for @capacityBasedHint3.
  ///
  /// In fr, this message translates to:
  /// **'Idéal si vous êtes seul ou si vous gérez la répartition des RDV vous-même.'**
  String get capacityBasedHint3;

  /// No description provided for @employeeBasedHint1.
  ///
  /// In fr, this message translates to:
  /// **'Chaque employé a son propre planning et ses horaires.'**
  String get employeeBasedHint1;

  /// No description provided for @employeeBasedHint2.
  ///
  /// In fr, this message translates to:
  /// **'Les clients choisissent leur coiffeur au moment du RDV (ou « Sans préférence »).'**
  String get employeeBasedHint2;

  /// No description provided for @employeeBasedHint3.
  ///
  /// In fr, this message translates to:
  /// **'Chaque employé gère ses pauses et jours de congé.'**
  String get employeeBasedHint3;

  /// No description provided for @employeeBasedHint4.
  ///
  /// In fr, this message translates to:
  /// **'Idéal pour un salon avec plusieurs coiffeurs indépendants.'**
  String get employeeBasedHint4;

  /// No description provided for @addressHintExample.
  ///
  /// In fr, this message translates to:
  /// **'Rruga Nënë Tereza 12, Prishtinë'**
  String get addressHintExample;

  /// No description provided for @ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @bookingDesktopChoose.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez '**
  String get bookingDesktopChoose;

  /// No description provided for @bookingDesktopChooseEm.
  ///
  /// In fr, this message translates to:
  /// **'votre\ncréneau.'**
  String get bookingDesktopChooseEm;

  /// No description provided for @bookingDesktopConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez\n'**
  String get bookingDesktopConfirm;

  /// No description provided for @bookingDesktopConfirmEm.
  ///
  /// In fr, this message translates to:
  /// **'votre rendez-vous.'**
  String get bookingDesktopConfirmEm;

  /// No description provided for @saveSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Modifications enregistrées'**
  String get saveSuccess;

  /// No description provided for @editCategoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la catégorie'**
  String get editCategoryTitle;

  /// No description provided for @salonName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du salon'**
  String get salonName;

  /// No description provided for @editServiceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le service'**
  String get editServiceTitle;

  /// No description provided for @durationMinLabel.
  ///
  /// In fr, this message translates to:
  /// **'Durée (min)'**
  String get durationMinLabel;

  /// No description provided for @priceEurLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prix (€)'**
  String get priceEurLabel;

  /// No description provided for @maxCapacityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Capacité max'**
  String get maxCapacityLabel;

  /// No description provided for @createEmployeeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un employé'**
  String get createEmployeeTitle;

  /// No description provided for @greetingHello.
  ///
  /// In fr, this message translates to:
  /// **'BONJOUR'**
  String get greetingHello;

  /// No description provided for @dashboardKpiServices.
  ///
  /// In fr, this message translates to:
  /// **'SERVICES'**
  String get dashboardKpiServices;

  /// No description provided for @dashboardKpiCategories.
  ///
  /// In fr, this message translates to:
  /// **'CATÉGORIES'**
  String get dashboardKpiCategories;

  /// No description provided for @dashboardKpiTeam.
  ///
  /// In fr, this message translates to:
  /// **'ÉQUIPE'**
  String get dashboardKpiTeam;

  /// No description provided for @dashboardKpiMode.
  ///
  /// In fr, this message translates to:
  /// **'MODE'**
  String get dashboardKpiMode;

  /// No description provided for @capacityMode.
  ///
  /// In fr, this message translates to:
  /// **'Capacité'**
  String get capacityMode;

  /// No description provided for @editHoursTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les horaires'**
  String get editHoursTooltip;

  /// No description provided for @capacitySettingsDescription.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les créneaux et la capacité maximale'**
  String get capacitySettingsDescription;

  /// No description provided for @configureAction.
  ///
  /// In fr, this message translates to:
  /// **'Configurer'**
  String get configureAction;

  /// No description provided for @walkInBadge.
  ///
  /// In fr, this message translates to:
  /// **'SANS RDV'**
  String get walkInBadge;

  /// No description provided for @callClient.
  ///
  /// In fr, this message translates to:
  /// **'Appeler le client'**
  String get callClient;

  /// No description provided for @authPromptTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez Termini im'**
  String get authPromptTitle;

  /// No description provided for @authPromptSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour réserver vos salons préférés.'**
  String get authPromptSubtitle;

  /// No description provided for @monthTotalOverline.
  ///
  /// In fr, this message translates to:
  /// **'Rendez-vous ce mois'**
  String get monthTotalOverline;

  /// No description provided for @monthStatConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'confirmés'**
  String get monthStatConfirmed;

  /// No description provided for @monthStatPending.
  ///
  /// In fr, this message translates to:
  /// **'en attente'**
  String get monthStatPending;

  /// No description provided for @monthStatRejected.
  ///
  /// In fr, this message translates to:
  /// **'refusés'**
  String get monthStatRejected;

  /// No description provided for @monthStatCancelled.
  ///
  /// In fr, this message translates to:
  /// **'annulés'**
  String get monthStatCancelled;

  /// No description provided for @monthStatNoShow.
  ///
  /// In fr, this message translates to:
  /// **'absents'**
  String get monthStatNoShow;

  /// No description provided for @appointmentSingular.
  ///
  /// In fr, this message translates to:
  /// **'rendez-vous'**
  String get appointmentSingular;

  /// No description provided for @appointmentPlural.
  ///
  /// In fr, this message translates to:
  /// **'rendez-vous'**
  String get appointmentPlural;

  /// No description provided for @emptyDayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rendez-vous'**
  String get emptyDayTitle;

  /// No description provided for @emptyDaySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rien de prévu pour cette journée.'**
  String get emptyDaySubtitle;

  /// No description provided for @clickToOpenDay.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez à nouveau pour ouvrir la journée.'**
  String get clickToOpenDay;

  /// No description provided for @tapAgain.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez à nouveau'**
  String get tapAgain;

  /// No description provided for @selectMonth.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un mois'**
  String get selectMonth;

  /// No description provided for @bookOverline.
  ///
  /// In fr, this message translates to:
  /// **'Réservation · en 30 s'**
  String get bookOverline;

  /// No description provided for @bookSidebarTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prenez '**
  String get bookSidebarTitle;

  /// No description provided for @bookSidebarTitleEm.
  ///
  /// In fr, this message translates to:
  /// **'rendez-vous.'**
  String get bookSidebarTitleEm;

  /// No description provided for @bookSidebarHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un service pour continuer.'**
  String get bookSidebarHint;

  /// No description provided for @viewServices.
  ///
  /// In fr, this message translates to:
  /// **'Voir les services'**
  String get viewServices;

  /// No description provided for @averageRating.
  ///
  /// In fr, this message translates to:
  /// **'Note moyenne'**
  String get averageRating;

  /// No description provided for @companyOverline.
  ///
  /// In fr, this message translates to:
  /// **'Barber · Coupe homme'**
  String get companyOverline;

  /// No description provided for @salonForMen.
  ///
  /// In fr, this message translates to:
  /// **'Salon pour hommes'**
  String get salonForMen;

  /// No description provided for @salonForWomen.
  ///
  /// In fr, this message translates to:
  /// **'Salon pour femmes'**
  String get salonForWomen;

  /// No description provided for @salonClienteleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Clientèle du salon'**
  String get salonClienteleLabel;

  /// No description provided for @salonClienteleMen.
  ///
  /// In fr, this message translates to:
  /// **'Hommes'**
  String get salonClienteleMen;

  /// No description provided for @salonClienteleWomen.
  ///
  /// In fr, this message translates to:
  /// **'Femmes'**
  String get salonClienteleWomen;

  /// No description provided for @salonClienteleBoth.
  ///
  /// In fr, this message translates to:
  /// **'Les deux'**
  String get salonClienteleBoth;

  /// No description provided for @salonClienteleRequired.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne la clientèle du salon'**
  String get salonClienteleRequired;

  /// No description provided for @completeYourProfileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Complète ton profil'**
  String get completeYourProfileTitle;

  /// No description provided for @completeProfileGenderPhone.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute ton numéro et ton genre pour un meilleur service.'**
  String get completeProfileGenderPhone;

  /// No description provided for @completeProfileGenderOnly.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute ton genre pour personnaliser les filtres.'**
  String get completeProfileGenderOnly;

  /// No description provided for @completeProfilePhoneOnly.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute ton numéro pour recevoir les confirmations de rendez-vous.'**
  String get completeProfilePhoneOnly;

  /// No description provided for @useMyGpsLocation.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser ma position GPS'**
  String get useMyGpsLocation;

  /// No description provided for @gpsLocationCaptured.
  ///
  /// In fr, this message translates to:
  /// **'Position enregistrée ✓'**
  String get gpsLocationCaptured;

  /// No description provided for @gpsHintNoAddressOnGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Adresse introuvable sur Google ? Utilise ton GPS pour enregistrer la position exacte du salon — l\'adresse reste telle que tu l\'as écrite.'**
  String get gpsHintNoAddressOnGoogle;

  /// No description provided for @gpsErrorServiceDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Active le GPS sur ton appareil puis réessaie.'**
  String get gpsErrorServiceDisabled;

  /// No description provided for @gpsErrorPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Autorise l\'accès à la position pour enregistrer les coordonnées.'**
  String get gpsErrorPermissionDenied;

  /// No description provided for @gpsErrorPermissionDeniedForever.
  ///
  /// In fr, this message translates to:
  /// **'Ouvre les paramètres système et autorise la localisation pour Termini im.'**
  String get gpsErrorPermissionDeniedForever;

  /// No description provided for @gpsErrorTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'obtenir la position. Va dehors ou réessaie.'**
  String get gpsErrorTimeout;

  /// No description provided for @gpsErrorUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessaie.'**
  String get gpsErrorUnknown;

  /// No description provided for @salonGeocodingBannerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Finalise la localisation du salon'**
  String get salonGeocodingBannerTitle;

  /// No description provided for @salonGeocodingBannerBody.
  ///
  /// In fr, this message translates to:
  /// **'Ton salon apparaîtra plus rapidement dans les recherches avec une adresse Google OU des coordonnées GPS enregistrées.'**
  String get salonGeocodingBannerBody;

  /// No description provided for @salonGeocodingDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Localisation du salon'**
  String get salonGeocodingDialogTitle;

  /// No description provided for @salonGeocodingDialogSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une adresse depuis Google OU enregistre la position via GPS.'**
  String get salonGeocodingDialogSubtitle;

  /// No description provided for @salonGeocodingSaveCta.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la localisation'**
  String get salonGeocodingSaveCta;

  /// No description provided for @salonGeocodingSuccessToast.
  ///
  /// In fr, this message translates to:
  /// **'Localisation enregistrée.'**
  String get salonGeocodingSuccessToast;

  /// No description provided for @shareSalon.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get shareSalon;

  /// No description provided for @shareSalonSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partager ce salon'**
  String get shareSalonSheetTitle;

  /// No description provided for @shareSalonSheetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Invite un proche à réserver'**
  String get shareSalonSheetSubtitle;

  /// No description provided for @shareViaWhatsApp.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp'**
  String get shareViaWhatsApp;

  /// No description provided for @shareViaWhatsAppCaption.
  ///
  /// In fr, this message translates to:
  /// **'Envoi direct · message pré-rempli'**
  String get shareViaWhatsAppCaption;

  /// No description provided for @shareMore.
  ///
  /// In fr, this message translates to:
  /// **'Partager…'**
  String get shareMore;

  /// No description provided for @shareMoreCaption.
  ///
  /// In fr, this message translates to:
  /// **'Feuille système · autres apps'**
  String get shareMoreCaption;

  /// No description provided for @shareCopyLink.
  ///
  /// In fr, this message translates to:
  /// **'Copier le lien'**
  String get shareCopyLink;

  /// No description provided for @shareLinkCopied.
  ///
  /// In fr, this message translates to:
  /// **'Lien copié'**
  String get shareLinkCopied;

  /// No description provided for @shareIncludeMeAsPro.
  ///
  /// In fr, this message translates to:
  /// **'Me recommander'**
  String get shareIncludeMeAsPro;

  /// No description provided for @shareIncludeMeAsProHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le destinataire arrivera sur la réservation avec toi déjà choisi.'**
  String get shareIncludeMeAsProHelp;

  /// No description provided for @shareLinkPreviewLabel.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get shareLinkPreviewLabel;

  /// No description provided for @sharedEmployeePrefix.
  ///
  /// In fr, this message translates to:
  /// **'Rendez-vous avec'**
  String get sharedEmployeePrefix;

  /// No description provided for @sharedEmployeeHint.
  ///
  /// In fr, this message translates to:
  /// **'Services filtrés pour ce pro'**
  String get sharedEmployeeHint;

  /// No description provided for @shareWhatsAppMessage.
  ///
  /// In fr, this message translates to:
  /// **'Salut ! Je te recommande {salonName} — prends ton rendez-vous ici : {url}'**
  String shareWhatsAppMessage(String salonName, String url);

  /// No description provided for @companySetupHeadline.
  ///
  /// In fr, this message translates to:
  /// **'Termine la configuration de ton salon'**
  String get companySetupHeadline;

  /// No description provided for @companySetupSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Encore quelques infos pour activer ton espace propriétaire.'**
  String get companySetupSubtitle;

  /// No description provided for @salonUnisex.
  ///
  /// In fr, this message translates to:
  /// **'Salon · Hommes & Femmes'**
  String get salonUnisex;

  /// No description provided for @servicesOffered.
  ///
  /// In fr, this message translates to:
  /// **'proposés'**
  String get servicesOffered;

  /// No description provided for @approvalsTitle.
  ///
  /// In fr, this message translates to:
  /// **'APPROBATIONS'**
  String get approvalsTitle;

  /// No description provided for @approvalsPendingSuffix.
  ///
  /// In fr, this message translates to:
  /// **' en attente'**
  String get approvalsPendingSuffix;

  /// No description provided for @approvalsConfirmedToday.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{{count} confirmé aujourd\'hui} other{{count} confirmés aujourd\'hui}}'**
  String approvalsConfirmedToday(int count);

  /// No description provided for @allApprovedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tout est approuvé'**
  String get allApprovedTitle;

  /// No description provided for @allApprovedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rendez-vous en attente d\'approbation'**
  String get allApprovedSubtitle;

  /// No description provided for @clientFallback.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get clientFallback;

  /// No description provided for @galleryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune photo. Ajoutez votre première photo.'**
  String get galleryEmpty;

  /// No description provided for @galleryAddPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get galleryAddPhoto;

  /// No description provided for @galleryDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la photo'**
  String get galleryDelete;

  /// No description provided for @galleryDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette photo de votre galerie ?'**
  String get galleryDeleteConfirm;

  /// No description provided for @galleryUploading.
  ///
  /// In fr, this message translates to:
  /// **'Envoi en cours…'**
  String get galleryUploading;

  /// No description provided for @galleryUploadError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'envoi. Veuillez réessayer.'**
  String get galleryUploadError;

  /// No description provided for @galleryReorderHint.
  ///
  /// In fr, this message translates to:
  /// **'Maintenez et glissez pour réorganiser'**
  String get galleryReorderHint;

  /// No description provided for @galleryOrderExplanation.
  ///
  /// In fr, this message translates to:
  /// **'L\'ordre des photos correspond à celui affiché sur la fiche publique de votre salon.'**
  String get galleryOrderExplanation;

  /// No description provided for @salonCoverPhotoHint.
  ///
  /// In fr, this message translates to:
  /// **'La première photo de votre galerie est affichée sur la page de recherche.'**
  String get salonCoverPhotoHint;

  /// No description provided for @favoriteAdded.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté aux favoris'**
  String get favoriteAdded;

  /// No description provided for @favoriteRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Retiré des favoris'**
  String get favoriteRemoved;

  /// No description provided for @removeFavoriteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des favoris ?'**
  String get removeFavoriteTitle;

  /// No description provided for @removeFavoriteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'{name} ne sera plus mis en avant.'**
  String removeFavoriteConfirm(String name);

  /// No description provided for @remove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get remove;

  /// No description provided for @favoriteBadgeTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Dans vos favoris'**
  String get favoriteBadgeTooltip;

  /// No description provided for @loginToFavorite.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour ajouter aux favoris'**
  String get loginToFavorite;

  /// No description provided for @photoCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} photos'**
  String photoCount(int count);

  /// No description provided for @viewGallery.
  ///
  /// In fr, this message translates to:
  /// **'Voir la galerie'**
  String get viewGallery;

  /// No description provided for @photoCountPlus.
  ///
  /// In fr, this message translates to:
  /// **'+ {count}'**
  String photoCountPlus(int count);

  /// No description provided for @galleryOf.
  ///
  /// In fr, this message translates to:
  /// **'{current} — {total}'**
  String galleryOf(String current, String total);

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @genderSelectorLabel.
  ///
  /// In fr, this message translates to:
  /// **'Je suis'**
  String get genderSelectorLabel;

  /// No description provided for @genderSelectorHint.
  ///
  /// In fr, this message translates to:
  /// **'Sert à pré-filtrer les salons. Vous pourrez changer à tout moment.'**
  String get genderSelectorHint;

  /// No description provided for @myProfile.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get myProfile;

  /// No description provided for @changePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get changePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get chooseFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la photo'**
  String get removePhoto;

  /// No description provided for @removePhotoConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment supprimer votre photo de profil ?'**
  String get removePhotoConfirm;

  /// No description provided for @avatarUploading.
  ///
  /// In fr, this message translates to:
  /// **'Envoi en cours…'**
  String get avatarUploading;

  /// No description provided for @avatarUploadError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'envoi de la photo.'**
  String get avatarUploadError;

  /// No description provided for @cropPhotoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recadrer la photo'**
  String get cropPhotoTitle;

  /// No description provided for @experienceSection.
  ///
  /// In fr, this message translates to:
  /// **'Expérience'**
  String get experienceSection;

  /// No description provided for @hapticLabel.
  ///
  /// In fr, this message translates to:
  /// **'Vibrations'**
  String get hapticLabel;

  /// No description provided for @hapticDesc.
  ///
  /// In fr, this message translates to:
  /// **'Petits retours tactiles sur les interactions'**
  String get hapticDesc;

  /// No description provided for @soundsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sons de l\'interface'**
  String get soundsLabel;

  /// No description provided for @soundsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Désactivés par défaut'**
  String get soundsDesc;

  /// No description provided for @animationsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Animations'**
  String get animationsLabel;

  /// No description provided for @animationsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Transitions et effets visuels'**
  String get animationsDesc;

  /// No description provided for @cancelAppointmentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ce rendez-vous ?'**
  String get cancelAppointmentTitle;

  /// No description provided for @cancelAppointmentBody.
  ///
  /// In fr, this message translates to:
  /// **'{salon} · {date}. Cette action est irréversible.'**
  String cancelAppointmentBody(String salon, String date);

  /// No description provided for @cancelAppointmentBodyOwner.
  ///
  /// In fr, this message translates to:
  /// **'Cette action libérera le créneau.'**
  String get cancelAppointmentBodyOwner;

  /// No description provided for @cancelReasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Motif (facultatif)'**
  String get cancelReasonLabel;

  /// No description provided for @cancellableUntil.
  ///
  /// In fr, this message translates to:
  /// **'Annulable jusqu\'à {date}'**
  String cancellableUntil(String date);

  /// No description provided for @cancellationTooLate.
  ///
  /// In fr, this message translates to:
  /// **'Il est trop tard pour annuler ce rendez-vous.'**
  String get cancellationTooLate;

  /// No description provided for @minCancelHoursLabel.
  ///
  /// In fr, this message translates to:
  /// **'Délai minimum d\'annulation (heures)'**
  String get minCancelHoursLabel;

  /// No description provided for @minCancelHoursHint.
  ///
  /// In fr, this message translates to:
  /// **'0 = pas de contrainte'**
  String get minCancelHoursHint;

  /// No description provided for @minCancelHoursNone.
  ///
  /// In fr, this message translates to:
  /// **'Annulation sans contrainte'**
  String get minCancelHoursNone;

  /// No description provided for @minCancelHoursValue.
  ///
  /// In fr, this message translates to:
  /// **'Annulation jusqu\'à {hours}h avant'**
  String minCancelHoursValue(int hours);

  /// No description provided for @bookingCancelPolicyNone.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez annuler ce rendez-vous à tout moment.'**
  String get bookingCancelPolicyNone;

  /// No description provided for @bookingCancelPolicyHours.
  ///
  /// In fr, this message translates to:
  /// **'Annulable jusqu\'à {hours} h avant le RDV.'**
  String bookingCancelPolicyHours(int hours);

  /// No description provided for @upcomingReminderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre RDV approche'**
  String get upcomingReminderTitle;

  /// No description provided for @upcomingReminderBody.
  ///
  /// In fr, this message translates to:
  /// **'{salon} · dans {duration}'**
  String upcomingReminderBody(String salon, String duration);

  /// No description provided for @upcomingReminderNow.
  ///
  /// In fr, this message translates to:
  /// **'maintenant'**
  String get upcomingReminderNow;

  /// No description provided for @inXHoursYMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{hours}h {minutes}min'**
  String inXHoursYMinutes(int hours, int minutes);

  /// No description provided for @reviewsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avis'**
  String get reviewsTitle;

  /// No description provided for @reviewSubmitTitle.
  ///
  /// In fr, this message translates to:
  /// **'Noter votre visite'**
  String get reviewSubmitTitle;

  /// No description provided for @reviewRatingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Votre note'**
  String get reviewRatingLabel;

  /// No description provided for @reviewCommentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Votre avis (facultatif)'**
  String get reviewCommentLabel;

  /// No description provided for @reviewCommentHint.
  ///
  /// In fr, this message translates to:
  /// **'Partagez votre expérience…'**
  String get reviewCommentHint;

  /// No description provided for @reviewSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer mon avis'**
  String get reviewSubmit;

  /// No description provided for @reviewSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Merci ! Votre avis a été publié.'**
  String get reviewSubmitted;

  /// No description provided for @reviewsSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous les avis ({count})'**
  String reviewsSeeAll(int count);

  /// No description provided for @reviewsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun avis pour l\'instant'**
  String get reviewsEmpty;

  /// No description provided for @reviewsOnlyRatings.
  ///
  /// In fr, this message translates to:
  /// **'Tous les avis ont été laissés sous forme de note uniquement, sans commentaire.'**
  String get reviewsOnlyRatings;

  /// No description provided for @cancellationReasonOwnerLabel.
  ///
  /// In fr, this message translates to:
  /// **'MOTIF DE L\'ANNULATION'**
  String get cancellationReasonOwnerLabel;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get tomorrow;

  /// No description provided for @reviewHideTitle.
  ///
  /// In fr, this message translates to:
  /// **'Masquer cet avis ?'**
  String get reviewHideTitle;

  /// No description provided for @reviewHideReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get reviewHideReason;

  /// No description provided for @reviewsReceived.
  ///
  /// In fr, this message translates to:
  /// **'Avis reçus'**
  String get reviewsReceived;

  /// No description provided for @reviewHidden.
  ///
  /// In fr, this message translates to:
  /// **'Avis masqué'**
  String get reviewHidden;

  /// No description provided for @reviewBadge.
  ///
  /// In fr, this message translates to:
  /// **'★ {rating}/5'**
  String reviewBadge(int rating);

  /// No description provided for @markNoShow.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme absent'**
  String get markNoShow;

  /// No description provided for @noShowConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme absent ?'**
  String get noShowConfirmTitle;

  /// No description provided for @noShowConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'{client} sera marqué comme absent. Visible sur sa fiche.'**
  String noShowConfirmBody(String client);

  /// No description provided for @noShowBadge.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 absence} other{{count} absences}}'**
  String noShowBadge(int count);

  /// No description provided for @noShowRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Absence enregistrée'**
  String get noShowRegistered;

  /// No description provided for @noShowTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Ce client a manqué {count} rendez-vous.'**
  String noShowTooltip(int count);

  /// No description provided for @appointmentsDesktopTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos visites'**
  String get appointmentsDesktopTitle;

  /// No description provided for @appointmentsDesktopOverline.
  ///
  /// In fr, this message translates to:
  /// **'MES RENDEZ-VOUS'**
  String get appointmentsDesktopOverline;

  /// No description provided for @reviewsReceivedCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avis reçus'**
  String get reviewsReceivedCardTitle;

  /// No description provided for @averageRatingOutOf.
  ///
  /// In fr, this message translates to:
  /// **'sur 5'**
  String get averageRatingOutOf;

  /// No description provided for @seeAllReviews.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout →'**
  String get seeAllReviews;

  /// No description provided for @noReviewsYetOwner.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas encore d\'avis.'**
  String get noReviewsYetOwner;

  /// No description provided for @rejectAppointmentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Refuser ce rendez-vous ?'**
  String get rejectAppointmentTitle;

  /// No description provided for @rejectAppointmentSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'{client} sera prévenu(e).'**
  String rejectAppointmentSubtitle(String client);

  /// No description provided for @rejectAppointmentWarning.
  ///
  /// In fr, this message translates to:
  /// **'Le créneau reste bloqué après le refus. Pour libérer le créneau et permettre à d\'autres clients de réserver, utilisez le bouton « Libérer le créneau » après avoir refusé.'**
  String get rejectAppointmentWarning;

  /// No description provided for @rejectAppointmentReasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Motif du refus (facultatif)'**
  String get rejectAppointmentReasonLabel;

  /// No description provided for @rejectAppointmentButton.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get rejectAppointmentButton;

  /// No description provided for @freeSlotButton.
  ///
  /// In fr, this message translates to:
  /// **'Libérer le créneau'**
  String get freeSlotButton;

  /// No description provided for @freeSlotConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Libérer ce créneau ?'**
  String get freeSlotConfirmTitle;

  /// No description provided for @freeSlotConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Le client ne recevra pas de nouvelle notification.'**
  String get freeSlotConfirmBody;

  /// No description provided for @freeSlotDone.
  ///
  /// In fr, this message translates to:
  /// **'Créneau libéré'**
  String get freeSlotDone;

  /// No description provided for @slotFreedBadge.
  ///
  /// In fr, this message translates to:
  /// **'Créneau libéré'**
  String get slotFreedBadge;

  /// No description provided for @rejectionReasonOwnerLabel.
  ///
  /// In fr, this message translates to:
  /// **'MOTIF DU REFUS'**
  String get rejectionReasonOwnerLabel;

  /// No description provided for @rejectionReasonClientLabel.
  ///
  /// In fr, this message translates to:
  /// **'Motif du salon'**
  String get rejectionReasonClientLabel;

  /// No description provided for @cancelAppointmentOwnerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ce rendez-vous ?'**
  String get cancelAppointmentOwnerTitle;

  /// No description provided for @cancelAppointmentOwnerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'{client} sera prévenu(e) et le créneau sera libéré.'**
  String cancelAppointmentOwnerSubtitle(String client);

  /// No description provided for @cancelAppointmentOwnerWarning.
  ///
  /// In fr, this message translates to:
  /// **'Le créneau redeviendra disponible à la réservation et le client sera notifié.'**
  String get cancelAppointmentOwnerWarning;

  /// No description provided for @cancelAppointmentOwnerReasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Motif de l\'annulation (facultatif)'**
  String get cancelAppointmentOwnerReasonLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'sq'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'sq':
      return AppLocalizationsSq();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
