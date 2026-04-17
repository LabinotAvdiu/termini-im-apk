// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Termini im';

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
  String get iAmUserSubtitle => 'Find and book your beauty appointments';

  @override
  String get iAmCompany => 'I\'m a professional';

  @override
  String get iAmCompanySubtitle => 'Manage your salon and your bookings';

  @override
  String get chooseRole => 'Choose your profile';

  @override
  String get chooseRoleSubtitle => 'How would you like to use Termini im?';

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
  String get albanian => 'Shqip';

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
  String get emailAlreadyUsed => 'This email is already in use';

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
  String get filterCityHint => 'E.g.: Prishtina, Salon Elegance...';

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
  String get security => 'Security';

  @override
  String get yourInfo => 'Your information';

  @override
  String get yourCompany => 'Your company';

  @override
  String stepOf(int current, int total) {
    return 'Step $current/$total';
  }

  @override
  String get signupSubtitle => 'Create your account in a few seconds';

  @override
  String get companyNameHint => 'My Salon';

  @override
  String get companyNameRequired => 'Company name is required';

  @override
  String get addressRequired => 'Address is required';

  @override
  String get city => 'City';

  @override
  String get cityHint => 'E.g.: Prishtina, Prizren...';

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

  @override
  String get findYourSalon => 'Find your perfect salon';

  @override
  String get loginToBook => 'Log in to book';

  @override
  String get loginToBookMessage =>
      'To book an appointment, you need an account.';

  @override
  String get continueWithoutAccount => 'Continue without account';

  @override
  String get welcome => 'Welcome';

  @override
  String get search => 'Search';

  @override
  String get myAppointments => 'My Appointments';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get past => 'Past';

  @override
  String get noUpcomingAppointments => 'No upcoming appointments';

  @override
  String get noPastAppointments => 'No past appointments';

  @override
  String get appointmentConfirmed => 'Confirmed';

  @override
  String get appointmentPending => 'Pending';

  @override
  String get appointmentCompleted => 'Completed';

  @override
  String get appointmentCancelled => 'Cancelled';

  @override
  String get mySalon => 'My Salon';

  @override
  String get companyInfo => 'Salon information';

  @override
  String get servicesAndCategories => 'Services & Categories';

  @override
  String get team => 'Team';

  @override
  String get openingHours => 'Opening Hours';

  @override
  String get addCategory => 'Add category';

  @override
  String get addService => 'Add service';

  @override
  String get inviteEmployee => 'Invite employee';

  @override
  String get createEmployee => 'Create employee account';

  @override
  String get closed => 'Closed';

  @override
  String get categoryName => 'Category name';

  @override
  String get serviceDuration => 'Duration (minutes)';

  @override
  String get servicePrice => 'Price (€)';

  @override
  String get employeeEmail => 'Employee email';

  @override
  String get specialties => 'Specialties';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get assignedServices => 'Assigned services';

  @override
  String get noServicesAssigned => 'No services assigned';

  @override
  String get myPlanning => 'My Schedule';

  @override
  String get available => 'Available';

  @override
  String get walkIn => 'Walk-in';

  @override
  String get addWalkIn => 'Add client';

  @override
  String get nextAppointment => 'Next appointment';

  @override
  String get noAppointmentsToday => 'No appointments today';

  @override
  String get clientFirstName => 'Client first name';

  @override
  String get clientLastName => 'Client last name (optional)';

  @override
  String get clientPhone => 'Phone (optional)';

  @override
  String get scheduleSettings => 'Schedule';

  @override
  String get myWorkHours => 'My work hours';

  @override
  String companyHoursHint(String hours) {
    return 'Salon: $hours';
  }

  @override
  String get breaks => 'Breaks';

  @override
  String get addBreak => 'Add break';

  @override
  String get breakLabel => 'Label (optional)';

  @override
  String get daysOff => 'Days off';

  @override
  String get addDayOff => 'Add day off';

  @override
  String get reason => 'Reason (optional)';

  @override
  String get dayOffReasonHint => 'E.g.: Annual leave';

  @override
  String get everyDay => 'Every day';

  @override
  String get breakSlot => 'Break';

  @override
  String get working => 'Working';

  @override
  String get notWorking => 'Not working';

  @override
  String get delete => 'Delete';

  @override
  String get dayOff => 'Day off';

  @override
  String get youDontWorkToday => 'You don\'t work this day';

  @override
  String get loginSubtitle => 'Sign in to your account';

  @override
  String get bookingAppBarTitle => 'Book Appointment';

  @override
  String get back => 'Back';

  @override
  String get continueLabel => 'Continue';

  @override
  String get bookingSuccessMessage =>
      'Your appointment has been booked successfully. You will receive a confirmation notification.';

  @override
  String get bookingConfirmationSubtitle =>
      'Review the details before confirming.';

  @override
  String get yourAppointment => 'Your appointment';

  @override
  String get reminderNote =>
      'A reminder will be sent 24h before your appointment. Cancellation is possible up to 2h before.';

  @override
  String get hairdresser => 'Stylist';

  @override
  String get noPreferenceShort => 'No pref.';

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Time';

  @override
  String get selectDateHint => 'Select a date above.';

  @override
  String get noSlotsAvailable => 'No available slots\nfor this date.';

  @override
  String get slotStatusDayOff => 'Day off';

  @override
  String get slotStatusNotWorking => 'Absent';

  @override
  String get slotStatusFull => 'Full';

  @override
  String get ourServices => 'Our services';

  @override
  String get orDivider => 'or';

  @override
  String resultsFound(int count, String plural) {
    return '$count result$plural found';
  }

  @override
  String salonsNearby(int count, String plural) {
    return '$count salon$plural near you';
  }

  @override
  String phoneCopied(String phone) {
    return 'Number copied: $phone';
  }

  @override
  String get selectServiceRequired => 'Please select a service';

  @override
  String get walkInSuccess => 'Client added successfully';

  @override
  String get walkInError => 'Error adding client';

  @override
  String get todayLabel => 'Today';

  @override
  String get previousDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get noBreaksConfigured => 'No breaks configured';

  @override
  String get noLeavePlanned => 'No leave planned';

  @override
  String get noServicesConfigured => 'No services configured';

  @override
  String get dayOfWeekLabel => 'Day of the week';

  @override
  String get startTimeLabel => 'Start';

  @override
  String get endTimeLabel => 'End';

  @override
  String employeeScheduleHint(String hours) {
    return 'Schedule: $hours';
  }

  @override
  String get phoneSecondary => 'Secondary phone';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get monthJan => 'January';

  @override
  String get monthFeb => 'February';

  @override
  String get monthMar => 'March';

  @override
  String get monthApr => 'April';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'June';

  @override
  String get monthJul => 'July';

  @override
  String get monthAug => 'August';

  @override
  String get monthSep => 'September';

  @override
  String get monthOct => 'October';

  @override
  String get monthNov => 'November';

  @override
  String get monthDec => 'December';

  @override
  String get monthShortJan => 'Jan';

  @override
  String get monthShortFeb => 'Feb';

  @override
  String get monthShortMar => 'Mar';

  @override
  String get monthShortApr => 'Apr';

  @override
  String get monthShortMay => 'May';

  @override
  String get monthShortJun => 'Jun';

  @override
  String get monthShortJul => 'Jul';

  @override
  String get monthShortAug => 'Aug';

  @override
  String get monthShortSep => 'Sep';

  @override
  String get monthShortOct => 'Oct';

  @override
  String get monthShortNov => 'Nov';

  @override
  String get monthShortDec => 'Dec';

  @override
  String get dayShortMon => 'Mon';

  @override
  String get dayShortTue => 'Tue';

  @override
  String get dayShortWed => 'Wed';

  @override
  String get dayShortThu => 'Thu';

  @override
  String get dayShortFri => 'Fri';

  @override
  String get dayShortSat => 'Sat';

  @override
  String get dayShortSun => 'Sun';

  @override
  String get bookingModeTitle => 'Booking mode';

  @override
  String get bookingModeCapacityBasedTitle => 'Single front desk';

  @override
  String get bookingModeCapacityBasedShort =>
      'Best if you handle all appointments alone';

  @override
  String get bookingModeCapacityBasedDescription =>
      'You handle all appointments. Set a capacity per service (e.g. 3 haircuts at once). Clients only see time slots.';

  @override
  String get bookingModeEmployeeBasedTitle => 'Each employee manages';

  @override
  String get bookingModeEmployeeBasedShort =>
      'Each employee keeps their own schedule';

  @override
  String get bookingModeEmployeeBasedDescription =>
      'Each employee has their own schedule. Clients pick their professional when booking.';

  @override
  String get settingsEditableLater =>
      'All these settings can be changed later.';

  @override
  String get maxConcurrent => 'Max concurrent appointments';

  @override
  String get capacitySettingsTitle => 'Capacity & breaks';

  @override
  String get reducedCapacityDays => 'Reduced-capacity days';

  @override
  String spotsRemaining(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString spots',
      one: '1 spot',
    );
    return '$_temp0';
  }

  @override
  String get pendingApprovals => 'Pending requests';

  @override
  String get pendingApprovalsShort => 'Requests';

  @override
  String get approve => 'Accept';

  @override
  String get reject => 'Refuse';

  @override
  String get bookingPendingTitle => 'Request sent';

  @override
  String get bookingPendingMessage =>
      'Your request has been sent. The salon will confirm or refuse shortly.';

  @override
  String changeBookingModeWarning(String mode) {
    return 'Switch to $mode. Existing appointments will be kept. Continue?';
  }

  @override
  String get confirmAppointment => 'Confirm';

  @override
  String get rejectAppointment => 'Refuse';

  @override
  String get cancelAppointment => 'Cancel appointment';

  @override
  String get confirmRejectTitle => 'Refuse this appointment?';

  @override
  String get confirmCancelTitle => 'Cancel this appointment?';

  @override
  String get cancelAppointmentBody => 'This will free the time slot.';

  @override
  String get actionFailed => 'Action failed. Try again.';
}
