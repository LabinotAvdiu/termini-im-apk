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
  String get searchWho => 'Who';

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
  String get homeBrandTagline => 'Salons & Barbers · Prishtina';

  @override
  String get homeHeroOverline => 'Directory · Salons & Barbers';

  @override
  String get homeHeroTitlePrefix => 'Prishtina\nstyled ';

  @override
  String get homeHeroTitleItalic => 'just right.';

  @override
  String get homeHeroSubtitle =>
      'A curated selection of salons across Kosovo.\nInstant booking, confirmation in under 2 minutes.';

  @override
  String get homeResultsOverline => 'Results · Prishtina';

  @override
  String get homeResultsOverlineSearch => 'Results · Search';

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
}
