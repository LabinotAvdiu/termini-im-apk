import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/company_remote_datasource.dart';
import '../../data/models/company_card_model.dart';
import '../../data/models/gender_filter.dart';

// ---------------------------------------------------------------------------
// Simple value providers
// ---------------------------------------------------------------------------

/// Current text entered in the home search bar.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Currently selected gender filter chip.
///
/// The filter auto-initialises from the authenticated user's `gender` (set at
/// signup) and rebuilds whenever the logged-in user changes. Within a single
/// session the user is free to change the filter via chips — manual changes
/// stick because the provider only re-runs `build()` on `user.id` transitions,
/// not on every unrelated auth-state update (we `select` the id explicitly).
class GenderFilterNotifier extends Notifier<GenderFilter> {
  @override
  GenderFilter build() {
    // Re-initialise when the logged-in user changes (different id ⇒ fresh session).
    ref.watch(authStateProvider.select((s) => s.user?.id));
    final gender = ref.read(authStateProvider).user?.gender;
    return switch (gender) {
      'men'   => GenderFilter.men,
      'women' => GenderFilter.women,
      _       => GenderFilter.both,
    };
  }
}

final genderFilterProvider =
    NotifierProvider<GenderFilterNotifier, GenderFilter>(
  GenderFilterNotifier.new,
);

/// City filter.
final cityFilterProvider = StateProvider<String>((ref) => '');

/// Date filter.
final dateFilterProvider = StateProvider<DateTime?>((ref) => null);

// ---------------------------------------------------------------------------
// Datasource provider
// ---------------------------------------------------------------------------

final companyDatasourceProvider = Provider<CompanyRemoteDatasource>((ref) {
  final client = ref.watch(dioClientProvider);
  return CompanyRemoteDatasource(client: client);
});

// ---------------------------------------------------------------------------
// Company list state
// ---------------------------------------------------------------------------

class CompanyListState {
  final List<CompanyCardModel> companies;
  final bool isLoading;
  final String? error;

  const CompanyListState({
    this.companies = const [],
    this.isLoading = false,
    this.error,
  });

  CompanyListState copyWith({
    List<CompanyCardModel>? companies,
    bool? isLoading,
    String? error,
  }) {
    return CompanyListState(
      companies: companies ?? this.companies,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CompanyListNotifier extends StateNotifier<CompanyListState> {
  final CompanyRemoteDatasource _datasource;

  CompanyListNotifier({required CompanyRemoteDatasource datasource})
      : _datasource = datasource,
        super(const CompanyListState());

  Future<void> loadCompanies({
    String? search,
    String? city,
    String? gender,
    String? date,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _datasource.getCompanies(
        search: search,
        city: city,
        gender: gender,
        date: date,
      );
      state = state.copyWith(
        companies: response.companies,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh({
    String? search,
    String? city,
    String? gender,
    String? date,
  }) async {
    await loadCompanies(
      search: search,
      city: city,
      gender: gender,
      date: date,
    );
  }

  /// Patches the [isFavorite] flag on a single card without a network call.
  /// Used by [FavoriteNotifier] for optimistic UI updates and rollbacks.
  /// No-op when [companyId] is not in the current list.
  void patchFavorite({required String companyId, required bool isFavorite}) {
    final updated = state.companies.map((c) {
      return c.id == companyId ? c.copyWith(isFavorite: isFavorite) : c;
    }).toList();
    state = state.copyWith(companies: updated);
  }
}

final companyListProvider =
    StateNotifierProvider<CompanyListNotifier, CompanyListState>((ref) {
  final datasource = ref.watch(companyDatasourceProvider);
  final notifier = CompanyListNotifier(datasource: datasource);

  // Auto-load on creation
  final search = ref.watch(searchQueryProvider);
  final city = ref.watch(cityFilterProvider);
  final gender = ref.watch(genderFilterProvider);
  final date = ref.watch(dateFilterProvider);

  final genderStr = switch (gender) {
    GenderFilter.men => 'men',
    GenderFilter.women => 'women',
    GenderFilter.both => 'both',
  };

  notifier.loadCompanies(
    search: search.isNotEmpty ? search : null,
    city: city.isNotEmpty ? city : null,
    gender: genderStr,
    date: date?.toIso8601String().split('T').first,
  );

  // E25 — search_performed (uniquement si l'utilisateur a saisi une query ou filtré)
  if (search.isNotEmpty || city.isNotEmpty || date != null) {
    ref.read(analyticsProvider).logSearchPerformed(
          city: city.isNotEmpty ? city : null,
          gender: genderStr != 'both' ? genderStr : null,
          date: date,
        );
  }

  return notifier;
});

/// Convenience provider for the company list only.
final filteredCompanyListProvider = Provider<List<CompanyCardModel>>((ref) {
  return ref.watch(companyListProvider).companies;
});
