import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory draft shared between the two company-setup steps.
///
/// Step 1 writes all fields except [bookingMode]; Step 2 reads the draft,
/// adds [bookingMode], and submits. The draft is intentionally NOT persisted
/// to SharedPreferences — the flow is meant to be completed in one session.
/// If the user kills the app mid-flow, they re-enter Step 1 with a clean
/// draft, which matches the previous single-screen behaviour.
class CompanySetupDraft {
  final String name;
  final String address;
  final String city;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final String companyGender; // 'men' | 'women' | 'both'
  final String? description;

  const CompanySetupDraft({
    required this.name,
    required this.address,
    required this.city,
    this.phone,
    this.latitude,
    this.longitude,
    required this.companyGender,
    this.description,
  });

  bool get isEmpty => name.isEmpty;
}

class _CompanySetupDraftNotifier extends StateNotifier<CompanySetupDraft?> {
  _CompanySetupDraftNotifier() : super(null);

  void save(CompanySetupDraft draft) => state = draft;

  void clear() => state = null;
}

final companySetupDraftProvider =
    StateNotifierProvider<_CompanySetupDraftNotifier, CompanySetupDraft?>(
  (ref) => _CompanySetupDraftNotifier(),
);
