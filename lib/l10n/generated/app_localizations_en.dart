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
  String get continueWithApple => 'Continue with Apple';

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
  String get edit => 'Edit';

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
  String get notificationsSubtitle =>
      'Choose which notifications you want to receive';

  @override
  String get notifNewBookingLabel => 'New appointment';

  @override
  String get notifNewBookingDesc =>
      'Notify me each time a new appointment is booked';

  @override
  String get notifQuietDayLabel => '1h reminder (quiet days)';

  @override
  String get notifQuietDayDesc =>
      'Reminder 1h before when you have ≤ 2 appointments that day';

  @override
  String get notifPermissionBannerTitle => 'Notifications disabled';

  @override
  String get notifPermissionBannerBody =>
      'Enable them in your device settings to get reminders.';

  @override
  String get openSettings => 'Open settings';

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
  String get searchWhen => 'When';

  @override
  String get searchWho => 'For';

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
  String seeMorePastAppointments(int count) {
    return 'Show $count more';
  }

  @override
  String get appointmentConfirmed => 'Confirmed';

  @override
  String get appointmentPending => 'Pending';

  @override
  String get appointmentCompleted => 'Completed';

  @override
  String get appointmentCancelled => 'Cancelled';

  @override
  String get appointmentRejected => 'Rejected';

  @override
  String get appointmentNoShow => 'No-show';

  @override
  String get appointmentNoShowDetail =>
      'You didn\'t show up for this appointment.';

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
  String get createEmployee => 'Create';

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
  String get capacitySettings => 'My salon — Schedule';

  @override
  String get noBreaksYet => 'No break configured yet';

  @override
  String get noDaysOffYet => 'No upcoming closure';

  @override
  String get deleteBreakConfirm => 'Delete this break?';

  @override
  String get deleteDayOffConfirm => 'Delete this closure?';

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
  String get reason => 'Reason';

  @override
  String get dayOffReasonHint => 'E.g.: Annual leave';

  @override
  String get fromDate => 'From';

  @override
  String get untilDate => 'Until';

  @override
  String get addUntilDate => 'Extend over several days';

  @override
  String get closureKicker => 'Closure · My schedule';

  @override
  String get closureSubtitle => 'Pick the date or dates of the closure.';

  @override
  String get addDayOffPrefix => 'Add a';

  @override
  String get addDayOffAccent => 'day off';

  @override
  String get ofClosure => 'of closure';

  @override
  String get optional => 'Optional';

  @override
  String get confirmClosure => 'Confirm the closure';

  @override
  String dayOffRangePreview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String dayOffConflictTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appointments in conflict',
      one: '1 appointment in conflict',
    );
    return '$_temp0';
  }

  @override
  String get dayOffConflictHint =>
      'Cancel or refuse the appointments below before adding the closure.';

  @override
  String andNOthers(int count) {
    return '… and $count others';
  }

  @override
  String get breakConflictTitle => 'Appointments during the break';

  @override
  String get breakConflictHint => 'These appointments start during the break.';

  @override
  String breakConflictMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appointments start during this break.',
      one: '1 appointment starts during this break.',
    );
    return '$_temp0 Save the break anyway?';
  }

  @override
  String get breakConflictContinue => 'Save anyway';

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
  String get landingHeroSubtitle => 'Book your slot in seconds.';

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
      'A reminder will be sent 24h before your appointment.';

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
  String get previousWeek => 'Previous week';

  @override
  String get nextWeek => 'Next week';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

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
  String get pendingEmptyTitle => 'All caught up.';

  @override
  String get pendingEmptySubtitle => 'No pending requests at the moment.';

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
  String get actionFailed => 'Action failed. Try again.';

  @override
  String get viewDay => 'Day';

  @override
  String get viewWeek => 'Week';

  @override
  String get viewMonth => 'Month';

  @override
  String get errorNetwork =>
      'Unable to reach the server. Check your connection.';

  @override
  String get errorUnauthorized => 'Session expired. Please sign in again.';

  @override
  String get errorNotFound => 'Not found.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get homeBrandTagline => 'Beauty & Style';

  @override
  String get homeHeroOverline => 'Directory · Beauty & Style';

  @override
  String get homeHeroTitlePrefix => 'Kosovo\nhas ';

  @override
  String get homeHeroTitleItalic => 'style.';

  @override
  String get homeHeroSubtitle =>
      'A curated selection of salons across Kosovo.\nInstant booking, confirmation within minutes.';

  @override
  String get homeResultsOverline => 'Results';

  @override
  String get homeResultsOverlineSearch => 'Results';

  @override
  String get homeSortLabel => 'Sort: Rating · Distance';

  @override
  String get landingHeroLine1 => 'Salons of';

  @override
  String get landingHeroLine2 => 'Kosovo';

  @override
  String get capacityBasedHint1 =>
      'You define a capacity per service (e.g. 3 haircuts at the same time).';

  @override
  String get capacityBasedHint2 =>
      'Clients choose a time slot — no employee is visible.';

  @override
  String get capacityBasedHint3 =>
      'Perfect if you work alone or manage bookings yourself.';

  @override
  String get employeeBasedHint1 =>
      'Each employee has their own schedule and opening hours.';

  @override
  String get employeeBasedHint2 =>
      'Clients pick their stylist at booking (or \"No preference\").';

  @override
  String get employeeBasedHint3 =>
      'Each employee manages their own breaks and days off.';

  @override
  String get employeeBasedHint4 =>
      'Perfect for a salon with multiple independent stylists.';

  @override
  String get addressHintExample => 'Rruga Nënë Tereza 12, Prishtina';

  @override
  String get ok => 'OK';

  @override
  String get bookingDesktopChoose => 'Pick ';

  @override
  String get bookingDesktopChooseEm => 'your\ntime slot.';

  @override
  String get bookingDesktopConfirm => 'Confirm\n';

  @override
  String get bookingDesktopConfirmEm => 'your appointment.';

  @override
  String get saveSuccess => 'Changes saved';

  @override
  String get editCategoryTitle => 'Edit category';

  @override
  String get salonName => 'Salon name';

  @override
  String get editServiceTitle => 'Edit service';

  @override
  String get durationMinLabel => 'Duration (min)';

  @override
  String get priceEurLabel => 'Price (€)';

  @override
  String get maxCapacityLabel => 'Max capacity';

  @override
  String get createEmployeeTitle => 'Create employee';

  @override
  String get greetingHello => 'HELLO';

  @override
  String get dashboardKpiServices => 'SERVICES';

  @override
  String get dashboardKpiCategories => 'CATEGORIES';

  @override
  String get dashboardKpiTeam => 'TEAM';

  @override
  String get dashboardKpiMode => 'MODE';

  @override
  String get capacityMode => 'Capacity';

  @override
  String get editHoursTooltip => 'Edit hours';

  @override
  String get capacitySettingsDescription => 'Manage slots and maximum capacity';

  @override
  String get configureAction => 'Configure';

  @override
  String get walkInBadge => 'WALK-IN';

  @override
  String get callClient => 'Call client';

  @override
  String get authPromptTitle => 'Join Termini im';

  @override
  String get authPromptSubtitle => 'Sign in to book your favorite salons.';

  @override
  String get monthTotalOverline => 'Appointments this month';

  @override
  String get monthStatConfirmed => 'confirmed';

  @override
  String get monthStatPending => 'pending';

  @override
  String get monthStatRejected => 'rejected';

  @override
  String get monthStatCancelled => 'cancelled';

  @override
  String get monthStatNoShow => 'no-shows';

  @override
  String get appointmentSingular => 'appointment';

  @override
  String get appointmentPlural => 'appointments';

  @override
  String get emptyDayTitle => 'No appointments';

  @override
  String get emptyDaySubtitle => 'Nothing scheduled for this day.';

  @override
  String get clickToOpenDay => 'Click again to open the day.';

  @override
  String get tapAgain => 'Tap again';

  @override
  String get selectMonth => 'Choose a month';

  @override
  String get bookOverline => 'Book · in 30 s';

  @override
  String get bookSidebarTitle => 'Book your ';

  @override
  String get bookSidebarTitleEm => 'appointment.';

  @override
  String get bookSidebarHint => 'Pick a service to continue.';

  @override
  String get viewServices => 'View services';

  @override
  String get averageRating => 'Average rating';

  @override
  String get companyOverline => 'Barber · Men\'s cut';

  @override
  String get salonForMen => 'Salon for men';

  @override
  String get salonForWomen => 'Salon for women';

  @override
  String get salonClienteleLabel => 'Salon clientele';

  @override
  String get salonClienteleMen => 'Men';

  @override
  String get salonClienteleWomen => 'Women';

  @override
  String get salonClienteleBoth => 'Both';

  @override
  String get salonClienteleRequired => 'Pick the salon\'s clientele';

  @override
  String get completeYourProfileTitle => 'Complete your profile';

  @override
  String get completeProfileGenderPhone =>
      'Add your phone and gender for a better experience.';

  @override
  String get completeProfileGenderOnly =>
      'Add your gender to personalise filters.';

  @override
  String get completeProfilePhoneOnly =>
      'Add your phone number so we can confirm bookings.';

  @override
  String get useMyGpsLocation => 'Use my GPS location';

  @override
  String get gpsLocationCaptured => 'Location saved ✓';

  @override
  String get gpsHintNoAddressOnGoogle =>
      'Address not on Google? Use GPS to save the salon\'s exact location — the address you typed stays.';

  @override
  String get gpsErrorServiceDisabled =>
      'Turn on GPS on your device then try again.';

  @override
  String get gpsErrorPermissionDenied =>
      'Allow location access to save the coordinates.';

  @override
  String get gpsErrorPermissionDeniedForever =>
      'Open system settings and enable location for Termini im.';

  @override
  String get gpsErrorTimeout =>
      'Couldn\'t get your location. Step outside or try again.';

  @override
  String get gpsErrorUnknown => 'Something went wrong. Please try again.';

  @override
  String get salonGeocodingBannerTitle =>
      'Finish setting up your salon\'s location';

  @override
  String get salonGeocodingBannerBody =>
      'Your salon will appear in searches sooner with a Google address OR saved GPS coordinates.';

  @override
  String get salonGeocodingDialogTitle => 'Salon location';

  @override
  String get salonGeocodingDialogSubtitle =>
      'Pick an address from Google OR save the position via GPS.';

  @override
  String get salonGeocodingSaveCta => 'Save location';

  @override
  String get salonGeocodingSuccessToast => 'Location saved.';

  @override
  String get shareSalon => 'Share';

  @override
  String get shareSalonSheetTitle => 'Share this salon';

  @override
  String get shareSalonSheetSubtitle => 'Invite someone to book';

  @override
  String get shareViaWhatsApp => 'WhatsApp';

  @override
  String get shareViaWhatsAppCaption => 'Direct send · pre-filled message';

  @override
  String get shareMore => 'Share…';

  @override
  String get shareMoreCaption => 'System sheet · other apps';

  @override
  String get shareCopyLink => 'Copy link';

  @override
  String get shareLinkCopied => 'Link copied';

  @override
  String get shareIncludeMeAsPro => 'Recommend me';

  @override
  String get shareIncludeMeAsProHelp =>
      'The recipient will land on the booking with you already picked.';

  @override
  String get shareLinkPreviewLabel => 'Preview';

  @override
  String get tomorrowLabel => 'Tomorrow';

  @override
  String get noPhoneAvailable => 'No phone on file';

  @override
  String get sharedEmployeePrefix => 'Booking with';

  @override
  String get sharedEmployeeHint => 'Services filtered for this pro';

  @override
  String shareWhatsAppMessage(String salonName, String url) {
    return 'Hey! I recommend $salonName — book here: $url';
  }

  @override
  String get companySetupHeadline => 'Your salon details';

  @override
  String get companySetupSubtitle =>
      'A few more details to activate your owner dashboard.';

  @override
  String get companyModeHeadline => 'Booking mode';

  @override
  String get companyModeSubtitle => 'How clients book at your salon.';

  @override
  String companySetupStepIndicator(int current, int total) {
    return 'Step $current / $total';
  }

  @override
  String get companySetupNextButton => 'Next';

  @override
  String get companySetupSubmitButton => 'Confirm and create my salon';

  @override
  String get companySetupModeTitle => 'How does your salon work?';

  @override
  String get companySetupModeIndividualTitle => 'Individual mode';

  @override
  String get companySetupModeIndividualExample =>
      'E.g. Salon with 2 stylists, each with their own schedule';

  @override
  String get companySetupModeIndividualBullet1 =>
      'Each professional has their own schedule';

  @override
  String get companySetupModeIndividualBullet2 =>
      'Clients choose their preferred stylist';

  @override
  String get companySetupModeIndividualBullet3 =>
      'Invite your team at any time';

  @override
  String get companySetupModeIndividualBullet4 =>
      'Recommended for pros who manage their own revenue';

  @override
  String get companySetupModeCapacityTitle => 'Capacity mode';

  @override
  String get companySetupModeCapacityExample =>
      'E.g. Large salon with 5 parallel seats';

  @override
  String get companySetupModeCapacityBullet1 =>
      'Clients pick a slot, not a specific pro';

  @override
  String get companySetupModeCapacityBullet2 =>
      'The salon manages revenue collectively';

  @override
  String get companySetupModeCapacityBullet3 =>
      'Add as many stations as needed';

  @override
  String get companySetupModeCapacityBullet4 =>
      'Recommended for institutes with pooled revenue';

  @override
  String get companySetupModeBadgePopular => 'Popular';

  @override
  String get companySetupModeCaption =>
      'You can change this setting later from My Salon → Settings.';

  @override
  String get salonUnisex => 'Salon · Men & Women';

  @override
  String get servicesOffered => 'offered';

  @override
  String get approvalsTitle => 'APPROVALS';

  @override
  String get approvalsPendingSuffix => ' pending';

  @override
  String approvalsConfirmedToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count confirmed today',
      one: '$count confirmed today',
    );
    return '$_temp0';
  }

  @override
  String get allApprovedTitle => 'All caught up';

  @override
  String get allApprovedSubtitle => 'No appointments waiting for approval';

  @override
  String get clientFallback => 'Client';

  @override
  String get galleryEmpty => 'No photos yet. Add your first photo.';

  @override
  String get galleryAddPhoto => 'Add photo';

  @override
  String get galleryDelete => 'Delete photo';

  @override
  String get galleryDeleteConfirm => 'Delete this photo from your gallery?';

  @override
  String get galleryUploading => 'Uploading…';

  @override
  String get galleryUploadError => 'Upload failed. Please try again.';

  @override
  String get galleryReorderHint => 'Hold and drag to reorder';

  @override
  String get galleryOrderExplanation =>
      'The photo order matches how your salon appears on its public page.';

  @override
  String get salonCoverPhotoHint =>
      'The first photo of your gallery is shown on the search page.';

  @override
  String get favoriteAdded => 'Added to favorites';

  @override
  String get favoriteRemoved => 'Removed from favorites';

  @override
  String get removeFavoriteTitle => 'Remove from favorites?';

  @override
  String removeFavoriteConfirm(String name) {
    return '$name will no longer be highlighted.';
  }

  @override
  String get remove => 'Remove';

  @override
  String get favoriteBadgeTooltip => 'In your favorites';

  @override
  String get loginToFavorite => 'Log in to add to favorites';

  @override
  String photoCount(int count) {
    return '$count photos';
  }

  @override
  String get viewGallery => 'See gallery';

  @override
  String photoCountPlus(int count) {
    return '+ $count';
  }

  @override
  String galleryOf(String current, String total) {
    return '$current — $total';
  }

  @override
  String get close => 'Close';

  @override
  String get genderSelectorLabel => 'I am';

  @override
  String get genderSelectorHint =>
      'Used to pre-filter salons. You can change it anytime.';

  @override
  String get myProfile => 'My profile';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get removePhotoConfirm => 'Remove your profile photo?';

  @override
  String get avatarUploading => 'Uploading…';

  @override
  String get avatarUploadError => 'Photo upload failed.';

  @override
  String get cropPhotoTitle => 'Crop photo';

  @override
  String get experienceSection => 'Experience';

  @override
  String get hapticLabel => 'Haptic feedback';

  @override
  String get hapticDesc => 'Subtle taps when you interact';

  @override
  String get soundsLabel => 'Interface sounds';

  @override
  String get soundsDesc => 'Off by default';

  @override
  String get animationsLabel => 'Animations';

  @override
  String get animationsDesc => 'Transitions and visual effects';

  @override
  String get cancelAppointmentTitle => 'Cancel this appointment?';

  @override
  String cancelAppointmentBody(String salon, String date) {
    return '$salon · $date. This action cannot be undone.';
  }

  @override
  String get cancelAppointmentBodyOwner => 'This will free up the time slot.';

  @override
  String get cancelReasonLabel => 'Reason (optional)';

  @override
  String cancellableUntil(String date) {
    return 'Cancellable until $date';
  }

  @override
  String get cancellationTooLate => 'Too late to cancel this booking.';

  @override
  String get minCancelHoursLabel => 'Minimum cancellation window (hours)';

  @override
  String get minCancelHoursHint => '0 = no restriction';

  @override
  String get minCancelHoursNone => 'Cancellation with no restriction';

  @override
  String minCancelHoursValue(int hours) {
    return 'Cancellable up to ${hours}h before';
  }

  @override
  String get bookingCancelPolicyNone =>
      'You can cancel this appointment at any time.';

  @override
  String bookingCancelPolicyHours(int hours) {
    return 'Cancellable up to ${hours}h before the appointment.';
  }

  @override
  String get upcomingReminderTitle => 'Your appointment is coming up';

  @override
  String upcomingReminderBody(String salon, String duration) {
    return '$salon · in $duration';
  }

  @override
  String get upcomingReminderNow => 'now';

  @override
  String inXHoursYMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}min';
  }

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String get reviewSubmitTitle => 'Rate your visit';

  @override
  String get reviewRatingLabel => 'Your rating';

  @override
  String get reviewCommentLabel => 'Your review (optional)';

  @override
  String get reviewCommentHint => 'Share your experience…';

  @override
  String get reviewSubmit => 'Publish review';

  @override
  String get reviewSubmitted => 'Thanks! Your review is live.';

  @override
  String reviewsSeeAll(int count) {
    return 'See all reviews ($count)';
  }

  @override
  String get reviewsEmpty => 'No reviews yet';

  @override
  String get reviewsOnlyRatings =>
      'All reviews are ratings only, without any written comment.';

  @override
  String get cancellationReasonOwnerLabel => 'CANCELLATION REASON';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get reviewHideTitle => 'Hide this review?';

  @override
  String get reviewHideReason => 'Reason';

  @override
  String get reviewsReceived => 'Reviews received';

  @override
  String get reviewHidden => 'Review hidden';

  @override
  String reviewBadge(int rating) {
    return '★ $rating/5';
  }

  @override
  String get markNoShow => 'Mark no-show';

  @override
  String get noShowConfirmTitle => 'Mark as no-show?';

  @override
  String noShowConfirmBody(String client) {
    return '$client will be marked as absent. Visible on their profile.';
  }

  @override
  String noShowBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count no-shows',
      one: '1 no-show',
    );
    return '$_temp0';
  }

  @override
  String get noShowRegistered => 'No-show recorded';

  @override
  String noShowTooltip(int count) {
    return 'This client missed $count appointments.';
  }

  @override
  String get appointmentsDesktopTitle => 'Your visits';

  @override
  String get appointmentsDesktopOverline => 'MY APPOINTMENTS';

  @override
  String get reviewsReceivedCardTitle => 'Reviews received';

  @override
  String get averageRatingOutOf => 'out of 5';

  @override
  String get seeAllReviews => 'See all →';

  @override
  String get noReviewsYetOwner => 'No reviews yet.';

  @override
  String get rejectAppointmentTitle => 'Reject this booking?';

  @override
  String rejectAppointmentSubtitle(String client) {
    return '$client will be notified.';
  }

  @override
  String get rejectAppointmentWarning =>
      'The slot remains blocked after rejection. To free the slot and allow other clients to book, use the \"Free the slot\" button after rejecting.';

  @override
  String get rejectAppointmentReasonLabel => 'Reason for rejection (optional)';

  @override
  String get rejectAppointmentButton => 'Reject';

  @override
  String get freeSlotButton => 'Free the slot';

  @override
  String get freeSlotConfirmTitle => 'Free this slot?';

  @override
  String get freeSlotConfirmBody =>
      'The client will not receive another notification.';

  @override
  String get freeSlotDone => 'Slot freed';

  @override
  String get slotFreedBadge => 'Slot freed';

  @override
  String get rejectionReasonOwnerLabel => 'REJECTION REASON';

  @override
  String get rejectionReasonClientLabel => 'Salon\'s reason';

  @override
  String get cancelAppointmentOwnerTitle => 'Cancel this booking?';

  @override
  String cancelAppointmentOwnerSubtitle(String client) {
    return '$client will be notified and the slot will be freed.';
  }

  @override
  String cancelAppointmentOwnerSubtitleWalkIn(String client) {
    return '$client\'s slot will be freed.';
  }

  @override
  String get cancelAppointmentOwnerWarning =>
      'The slot will become available again and the client will be notified.';

  @override
  String get cancelAppointmentOwnerWarningWalkIn =>
      'The slot will become available again.';

  @override
  String get cancelAppointmentOwnerReasonLabel =>
      'Reason for cancellation (optional)';

  @override
  String get helpAndSupport => 'Help & support';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get needHelpFooter => 'Need help?';

  @override
  String get needHelpFooterLink => 'Contact support';

  @override
  String get problemWithSalon => 'Issue with this salon?';

  @override
  String get supportKicker => 'SUPPORT';

  @override
  String get supportTitle => 'Contact';

  @override
  String get supportTitleAccent => 'the team';

  @override
  String get supportSubtitle => 'We\'ll get back to you as soon as possible';

  @override
  String get supportFirstNameLabel => 'FIRST NAME';

  @override
  String get supportFirstNamePlaceholder => 'Your first name';

  @override
  String get supportPhoneLabel => 'PHONE';

  @override
  String get supportPhonePlaceholder => '+383 44 000 000';

  @override
  String get supportEmailLabel => 'EMAIL';

  @override
  String get supportEmailPlaceholder => 'your.email@example.com';

  @override
  String get supportMessageLabel => 'MESSAGE';

  @override
  String get supportMessagePlaceholder => 'Describe your issue or question…';

  @override
  String supportMessageCounter(int count, int max) {
    return '$count / $max';
  }

  @override
  String get supportAttachmentsLabel => 'ATTACHMENTS';

  @override
  String get supportAttachmentsHint =>
      '3 files max • JPG, PNG, PDF • 5 MB each';

  @override
  String get supportAddAttachment => 'Add a file';

  @override
  String get supportSubmit => 'SEND MESSAGE';

  @override
  String get supportSubmitting => 'SENDING…';

  @override
  String get supportSuccessTitle => 'Message';

  @override
  String get supportSuccessTitleAccent => 'sent';

  @override
  String get supportSuccessSubtitle =>
      'We\'ll get back to you as soon as possible.';

  @override
  String get supportSuccessClose => 'CLOSE';

  @override
  String get supportErrorTitle => 'Could not send';

  @override
  String get supportErrorSubtitle => 'Check your connection and try again.';

  @override
  String get supportErrorRetry => 'Retry';

  @override
  String get supportFileTooLarge => 'File too large • max 5 MB';

  @override
  String get supportFileUnsupported => 'Unsupported format';

  @override
  String get supportMaxThreeFiles => '3 files maximum';

  @override
  String get supportFieldRequired => 'Required field';

  @override
  String get supportMessageMinLength => 'Minimum 10 characters';

  @override
  String get supportPrefilledBadge => 'PREFILLED';

  @override
  String get fullName => 'Full name';

  @override
  String get gender => 'Gender';

  @override
  String get personalGenderMen => 'Male';

  @override
  String get personalGenderWomen => 'Female';

  @override
  String get myPagesSection => 'My pages';

  @override
  String get ownerSpaceSection => 'Pro space';

  @override
  String get myNotifications => 'My notifications';

  @override
  String get myNotificationsSubtitle => 'Rejections, reminders, reviews…';

  @override
  String get messages => 'Messages';

  @override
  String get messagesSubtitle => 'Conversations with salons';

  @override
  String get myScheduleEntry => 'My schedule';

  @override
  String get myScheduleEntrySubtitle => 'Working days';

  @override
  String get myBreaksEntry => 'My breaks';

  @override
  String get myBreaksEntrySubtitle => 'Recurring breaks and days off';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get comingSoonMessage => 'This feature is coming soon.';

  @override
  String get verifyEmailTitle => 'Confirm your email';

  @override
  String verifyEmailSubtitle(String email) {
    return 'A 6-character code was sent to $email';
  }

  @override
  String get verifyEmailOverline => 'VERIFICATION';

  @override
  String get verifyEmailConfirm => 'Confirm';

  @override
  String get verifyEmailResend => 'Resend code';

  @override
  String verifyEmailResendCooldown(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get verifyEmailSuccess => 'Email confirmed';

  @override
  String get verifyEmailSuccessTitle => 'Email confirmed';

  @override
  String get verifyEmailSuccessMessage =>
      'Your address is now verified. You can book with peace of mind.';

  @override
  String get verifyEmailSuccessCta => 'Back to home';

  @override
  String get verifyEmailCodeRequired => 'Code is required';

  @override
  String get verifyEmailCodeLength => 'Code must be 6 characters';

  @override
  String get verifyEmailErrorInvalid => 'Invalid or expired code';

  @override
  String get verifyEmailErrorNotFound => 'No account linked to this email';

  @override
  String get unverifiedBannerMessage =>
      'Confirm your email to secure your account';

  @override
  String get unverifiedBannerCta => 'Confirm';

  @override
  String get verifyEmailToBookTitle => 'Verify your email to book';

  @override
  String get verifyEmailToBookMessage =>
      'We can only confirm an appointment once your email is verified. It only takes 30 seconds.';

  @override
  String get verifyEmailToBookCta => 'Verify my email';

  @override
  String get verifyEmailToBookDismiss => 'Later';

  @override
  String get autoApprovalEnabled => 'Auto-approval enabled';

  @override
  String get autoApprovalEmptyMessage =>
      'All new appointments are confirmed directly. This list will stay empty while auto-approval is active.';

  @override
  String get autoApprovalEditCta => 'Change this setting';

  @override
  String get autoApprovalToggleLabel => 'Auto-approval';

  @override
  String get autoApprovalToggleHelper =>
      'New appointments will be confirmed directly, without any validation step on your end.';

  @override
  String get autoApprovalCapacityOnly => 'Capacity mode only';

  @override
  String get autoApprovalBadgeAuto => 'auto';

  @override
  String get autoApprovalBadgeManual => 'manual';

  @override
  String get autoApprovalBadgeTitle => 'Review';

  @override
  String get autoApprovalConfirmEnableTitle => 'Enable auto-approval?';

  @override
  String get autoApprovalConfirmEnableMessage =>
      'All new appointments will be confirmed directly, without any action from you.';

  @override
  String get autoApprovalConfirmDisableTitle => 'Disable auto-approval?';

  @override
  String get autoApprovalConfirmDisableMessage =>
      'New appointments will go back through the \"To confirm\" queue.';

  @override
  String get autoApprovalConfirmAction => 'Confirm';

  @override
  String get deleteAccountModalTitle => 'Delete your account?';

  @override
  String get deleteAccountModalDescription =>
      'This will permanently delete your account, your appointment history and your personal information. Your saved salons will be removed. This action cannot be undone.';

  @override
  String get deleteAccountModalCheckbox =>
      'I understand that deletion is permanent';

  @override
  String get deleteAccountModalContinue => 'Continue';

  @override
  String deleteAccountConfirmPrompt(String keyword) {
    return 'Type $keyword to confirm';
  }

  @override
  String get deleteAccountConfirmAction => 'Permanently delete my account';

  @override
  String get deleteAccountTypeKeyword => 'DELETE';

  @override
  String get deleteAccountSuccess => 'Your account has been deleted.';

  @override
  String get deleteAccountErrorOwnerSalon =>
      'You must transfer or delete your salon before you can delete your account.';

  @override
  String get deleteAccountErrorGeneric =>
      'Something went wrong. Please try again later.';

  @override
  String get planningEmptyDayTitle => 'No appointments today.';

  @override
  String get planningEmptyDaySubtitle => 'Time for a Turkish coffee?';

  @override
  String tomorrowBookingBannerMessage(String time, String salon) {
    return 'Tomorrow at $time at $salon →';
  }

  @override
  String get shareAppTitle => 'Share Termini im';

  @override
  String get shareAppMessage =>
      'Enjoying it? A friend who discovers it means one more salon in Kosovo.';

  @override
  String get shareAppCta => 'Share';

  @override
  String get shareAppLater => 'Later';

  @override
  String get notifCategoryAppointments => 'Appointments';

  @override
  String get notifCategoryCommunity => 'Community';

  @override
  String get notifCategoryMarketing => 'Marketing';

  @override
  String get notifTypeReminderEveningLabel => 'Evening reminder';

  @override
  String get notifTypeReminderEveningDesc =>
      'Get a reminder the evening before your appointment.';

  @override
  String get notifTypeReminder2hLabel => '2-hour reminder';

  @override
  String get notifTypeReminder2hDesc =>
      'A notification 2 hours before your appointment time.';

  @override
  String get notifTypeReviewRequestLabel => 'Review request';

  @override
  String get notifTypeReviewRequestDesc =>
      'The day after your visit, we ask for your feedback.';

  @override
  String get notifTypeNewReviewLabel => 'New review';

  @override
  String get notifTypeNewReviewDesc =>
      'Get notified when a client posts a review on your salon.';

  @override
  String get notifTypeCapacityFullLabel => 'Full capacity';

  @override
  String get notifTypeCapacityFullDesc =>
      'Notification when all slots for a day are taken.';

  @override
  String get notifTypeWeeklyDigestLabel => 'Weekly digest';

  @override
  String get notifTypeWeeklyDigestDesc =>
      'A summary of your activity each week.';

  @override
  String get notifTypeMonthlyReportLabel => 'Monthly report';

  @override
  String get notifTypeMonthlyReportDesc =>
      'Statistics and trends for the past month.';

  @override
  String get notifTypeFavoriteNewPhotosLabel => 'New photos (favourites)';

  @override
  String get notifTypeFavoriteNewPhotosDesc =>
      'When one of your favourite salons adds photos.';

  @override
  String get notifTypeFavoriteNewSlotsLabel => 'New slots (favourites)';

  @override
  String get notifTypeFavoriteNewSlotsDesc =>
      'When a favourite salon opens new booking slots.';

  @override
  String get notifTypeMarketingLabel => 'Offers & news';

  @override
  String get notifTypeMarketingDesc =>
      'Campaigns, promotions and Termini im updates.';

  @override
  String get notificationsInboxTitle => 'Inbox';

  @override
  String notificationsInboxUnreadCount(int count) {
    return '$count unread';
  }

  @override
  String get notificationsInboxMarkAllRead => 'Mark all as read';

  @override
  String get notificationsInboxEmptyTitle => 'Empty inbox';

  @override
  String get notificationsInboxEmptySubtitle =>
      'Your notifications will appear here as they arrive.';

  @override
  String get notificationsInboxToday => 'Today';

  @override
  String get notificationsInboxYesterday => 'Yesterday';

  @override
  String get notificationsChannelPush => 'PUSH';

  @override
  String get notificationsChannelEmail => 'EMAIL';

  @override
  String get notificationsChannelInApp => 'IN-APP';
}
