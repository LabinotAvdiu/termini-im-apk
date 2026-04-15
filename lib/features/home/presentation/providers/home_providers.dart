import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/company_remote_datasource.dart';
import '../../data/models/company_card_model.dart';
import '../../data/models/gender_filter.dart';

// ---------------------------------------------------------------------------
// Simple value providers
// ---------------------------------------------------------------------------

/// Current text entered in the home search bar.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Currently selected gender filter chip.
final genderFilterProvider =
    StateProvider<GenderFilter>((ref) => GenderFilter.both);

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

  return notifier;
});

/// Convenience provider for the company list only.
final filteredCompanyListProvider = Provider<List<CompanyCardModel>>((ref) {
  return ref.watch(companyListProvider).companies;
});
