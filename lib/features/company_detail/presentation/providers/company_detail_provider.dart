import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/company_detail_remote_datasource.dart';
import '../../data/models/company_detail_model.dart';

// ---------------------------------------------------------------------------
// Datasource provider
// ---------------------------------------------------------------------------

final companyDetailDatasourceProvider =
    Provider<CompanyDetailRemoteDatasource>((ref) {
  final client = ref.watch(dioClientProvider);
  return CompanyDetailRemoteDatasource(client: client);
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class CompanyDetailState {
  final CompanyDetailModel? company;
  final bool isLoading;
  final String? error;

  const CompanyDetailState({
    this.company,
    this.isLoading = false,
    this.error,
  });

  CompanyDetailState copyWith({
    CompanyDetailModel? company,
    bool? isLoading,
    String? error,
  }) {
    return CompanyDetailState(
      company: company ?? this.company,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class CompanyDetailNotifier extends StateNotifier<CompanyDetailState> {
  final CompanyDetailRemoteDatasource _datasource;

  CompanyDetailNotifier({required CompanyDetailRemoteDatasource datasource})
      : _datasource = datasource,
        super(const CompanyDetailState());

  Future<void> loadCompany(String companyId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final company = await _datasource.getCompanyDetail(companyId);
      state = state.copyWith(company: company, isLoading: false);
    } catch (e, stack) {
      // ignore: avoid_print
      print('CompanyDetail error: $e\n$stack');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Patches the favorite flag on the loaded company without a network call.
  /// Used by [FavoriteNotifier] for optimistic UI updates and rollback.
  /// No-op when [companyId] doesn't match the currently loaded company.
  void setFavoriteIfLoaded({
    required String companyId,
    required bool isFavorite,
  }) {
    final company = state.company;
    if (company == null || company.id != companyId) return;
    state = state.copyWith(
      company: company.copyWith(isFavorite: isFavorite),
    );
  }

  ServiceModel? findService(String serviceId) {
    if (state.company == null) return null;
    for (final cat in state.company!.categories) {
      for (final svc in cat.services) {
        if (svc.id == serviceId) return svc;
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final companyDetailProvider =
    StateNotifierProvider.autoDispose<CompanyDetailNotifier, CompanyDetailState>(
  (ref) {
    final datasource = ref.watch(companyDetailDatasourceProvider);
    return CompanyDetailNotifier(datasource: datasource);
  },
);
