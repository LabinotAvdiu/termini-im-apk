import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Takimi IM'**
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

  /// No description provided for @iAmUser.
  ///
  /// In fr, this message translates to:
  /// **'Je suis un client'**
  String get iAmUser;

  /// No description provided for @iAmCompany.
  ///
  /// In fr, this message translates to:
  /// **'Je suis un professionnel'**
  String get iAmCompany;

  /// No description provided for @chooseRole.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre profil'**
  String get chooseRole;

  /// No description provided for @chooseRoleSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Comment souhaitez-vous utiliser Takimi IM ?'**
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
  /// **'Ex: Paris, Salon Élégance...'**
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
  /// **'Recevoir des rappels de rendez-vous'**
  String get notificationsSubtitle;

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

  /// No description provided for @cityHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Paris, Lyon...'**
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
      <String>['en', 'fr'].contains(locale.languageCode);

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
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
