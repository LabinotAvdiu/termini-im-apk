// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Takimi IM';

  @override
  String get login => 'Login';

  @override
  String get signup => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get phone => 'Phone';

  @override
  String get companyName => 'Company Name';

  @override
  String get address => 'Address';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get signupNow => 'Sign up';

  @override
  String get loginNow => 'Log in';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithFacebook => 'Continue with Facebook';

  @override
  String get iAmUser => 'I\'m a client';

  @override
  String get iAmCompany => 'I\'m a professional';

  @override
  String get chooseRole => 'Choose your profile';

  @override
  String get chooseRoleSubtitle => 'How would you like to use Takimi IM?';

  @override
  String get searchPlaceholder => 'Search for a salon...';

  @override
  String get filterMen => 'Men';

  @override
  String get filterWomen => 'Women';

  @override
  String get filterBoth => 'Both';

  @override
  String get morning => 'MORNING';

  @override
  String get afternoon => 'AFTERNOON';

  @override
  String get bookAppointment => 'Book Now';

  @override
  String get moreInfo => 'More information';

  @override
  String reviews(int count) {
    return '$count reviews';
  }

  @override
  String get gallery => 'Gallery';

  @override
  String get categories => 'Categories';

  @override
  String get services => 'Services';

  @override
  String get choose => 'Choose';

  @override
  String get price => 'Price';

  @override
  String get duration => 'Duration';

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get step1Title => 'Choose an employee';

  @override
  String get step2Title => 'Choose a time slot';

  @override
  String get step3Title => 'Confirmation';

  @override
  String get noPreference => 'No preference';

  @override
  String get selectDate => 'Select a date';

  @override
  String get selectTime => 'Select a time';

  @override
  String get confirmBooking => 'Confirm booking';

  @override
  String get bookingConfirmed => 'Booking confirmed!';

  @override
  String get bookingConfirmedMessage =>
      'Your appointment has been booked successfully.';

  @override
  String get backToHome => 'Back to home';

  @override
  String get employee => 'Employee';

  @override
  String get dateAndTime => 'Date & Time';

  @override
  String get service => 'Service';

  @override
  String get summary => 'Summary';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'An error occurred';

  @override
  String get retry => 'Retry';

  @override
  String get noResults => 'No results';

  @override
  String get noResultsMessage => 'No salons found for your search.';

  @override
  String get language => 'Language';

  @override
  String get french => 'Français';

  @override
  String get english => 'English';

  @override
  String get logout => 'Logout';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Invalid email';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get passwordNeedsUpper => 'Must contain at least one uppercase letter';

  @override
  String get passwordNeedsLower => 'Must contain at least one lowercase letter';

  @override
  String get passwordNeedsNumber => 'Must contain at least one number';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get firstNameRequired => 'First name is required';

  @override
  String get lastNameRequired => 'Last name is required';

  @override
  String get phoneRequired => 'Phone is required';

  @override
  String get filterGenderLabel => 'Gender';

  @override
  String get filterCityLabel => 'City / Salon';

  @override
  String get filterCityHint => 'E.g.: Paris, Salon Élégance...';

  @override
  String get filterCitySalonLabel => 'City or salon name';

  @override
  String get filterDateLabel => 'Any time';

  @override
  String get filterDateWhen => 'When?';

  @override
  String get filterClear => 'Clear';

  @override
  String get filterSearch => 'Search';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get personalInfo => 'Personal information';

  @override
  String get saveChanges => 'Save';

  @override
  String get changesSaved => 'Changes saved';

  @override
  String get changePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle => 'Receive appointment reminders';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountWarning => 'This action is irreversible';

  @override
  String get logoutConfirm => 'Are you sure you want to log out?';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email to receive a reset link';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get resetEmailSent => 'A reset email has been sent';

  @override
  String get resetToken => 'Reset code';

  @override
  String get resetPasswordTitle => 'New password';

  @override
  String get resetPasswordSuccess => 'Password changed successfully';

  @override
  String get resetPassword => 'Reset';

  @override
  String get emailNotVerifiedTitle => 'Email not verified';

  @override
  String get emailNotVerifiedMessage =>
      'Please verify your email to be able to book appointments.';

  @override
  String get yourInfo => 'Your information';

  @override
  String get yourCompany => 'Your company';

  @override
  String stepOf(int current, int total) {
    return 'Step $current/$total';
  }

  @override
  String get companyNameRequired => 'Company name is required';

  @override
  String get addressRequired => 'Address is required';

  @override
  String get city => 'City';

  @override
  String get cityHint => 'E.g.: Paris, Lyon...';

  @override
  String get cityDescription =>
      'We\'ll use your city to recommend the nearest salons to you.';

  @override
  String get cityCompany => 'Company city';

  @override
  String get cityCompanyDescription =>
      'The city where your salon is located. It will also be used for your profile.';

  @override
  String get cityRequired => 'City is required';
}
