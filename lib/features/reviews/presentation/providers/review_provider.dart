import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/review_remote_datasource.dart';
import '../../data/models/review_model.dart';

// ---------------------------------------------------------------------------
// Datasource provider
// ---------------------------------------------------------------------------

final reviewDatasourceProvider = Provider<ReviewRemoteDatasource>((ref) {
  final client = ref.watch(dioClientProvider);
  return ReviewRemoteDatasource(client: client);
});

// ---------------------------------------------------------------------------
// State — company reviews (paginated, for public company page)
// ---------------------------------------------------------------------------

class CompanyReviewsState {
  final List<ReviewModel> reviews;
  final bool isLoading;
  final bool isLoadingMore;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? error;

  const CompanyReviewsState({
    this.reviews = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.currentPage = 0,
    this.lastPage = 1,
    this.total = 0,
    this.error,
  });

  bool get hasMore => currentPage < lastPage;

  CompanyReviewsState copyWith({
    List<ReviewModel>? reviews,
    bool? isLoading,
    bool? isLoadingMore,
    int? currentPage,
    int? lastPage,
    int? total,
    String? error,
  }) {
    return CompanyReviewsState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier — company reviews (public)
// ---------------------------------------------------------------------------

class CompanyReviewsNotifier
    extends StateNotifier<CompanyReviewsState> {
  final ReviewRemoteDatasource _datasource;
  final String _companyId;

  CompanyReviewsNotifier({
    required ReviewRemoteDatasource datasource,
    required String companyId,
  })  : _datasource = datasource,
        _companyId = companyId,
        super(const CompanyReviewsState()) {
    load();
  }

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _datasource.getCompanyReviews(_companyId, page: 1);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        reviews: result.reviews,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
        error: null,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!mounted || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _datasource.getCompanyReviews(
        _companyId,
        page: state.currentPage + 1,
      );
      if (!mounted) return;
      state = state.copyWith(
        isLoadingMore: false,
        reviews: [...state.reviews, ...result.reviews],
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        total: result.total,
        error: null,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

// Provider family — keyed by companyId
final companyReviewsProvider = StateNotifierProvider.family<
    CompanyReviewsNotifier, CompanyReviewsState, String>((ref, companyId) {
  final datasource = ref.watch(reviewDatasourceProvider);
  return CompanyReviewsNotifier(
    datasource: datasource,
    companyId: companyId,
  );
});

// ---------------------------------------------------------------------------
// State — owner reviews (for moderation screen)
// ---------------------------------------------------------------------------

class MyCompanyReviewsState {
  final List<ReviewModel> reviews;
  final bool isLoading;
  final bool isLoadingMore;
  final int currentPage;
  final int lastPage;
  final String? error;

  const MyCompanyReviewsState({
    this.reviews = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.currentPage = 0,
    this.lastPage = 1,
    this.error,
  });

  bool get hasMore => currentPage < lastPage;

  MyCompanyReviewsState copyWith({
    List<ReviewModel>? reviews,
    bool? isLoading,
    bool? isLoadingMore,
    int? currentPage,
    int? lastPage,
    String? error,
  }) {
    return MyCompanyReviewsState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      error: error,
    );
  }
}

class MyCompanyReviewsNotifier
    extends StateNotifier<MyCompanyReviewsState> {
  final ReviewRemoteDatasource _datasource;

  MyCompanyReviewsNotifier({required ReviewRemoteDatasource datasource})
      : _datasource = datasource,
        super(const MyCompanyReviewsState()) {
    load();
  }

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _datasource.getMyCompanyReviews(page: 1);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        reviews: result.reviews,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        error: null,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!mounted || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result =
          await _datasource.getMyCompanyReviews(page: state.currentPage + 1);
      if (!mounted) return;
      state = state.copyWith(
        isLoadingMore: false,
        reviews: [...state.reviews, ...result.reviews],
        currentPage: result.currentPage,
        lastPage: result.lastPage,
        error: null,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<bool> hideReview(String reviewId, {String? reason}) async {
    if (!mounted) return false;
    try {
      final updated =
          await _datasource.hideReview(reviewId, reason: reason);
      _replaceReview(updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unhideReview(String reviewId) async {
    if (!mounted) return false;
    try {
      final updated = await _datasource.unhideReview(reviewId);
      _replaceReview(updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _replaceReview(ReviewModel updated) {
    if (!mounted) return;
    final newList = state.reviews
        .map((r) => r.id == updated.id ? updated : r)
        .toList();
    state = state.copyWith(reviews: newList);
  }
}

final myCompanyReviewsProvider = StateNotifierProvider<
    MyCompanyReviewsNotifier, MyCompanyReviewsState>((ref) {
  final datasource = ref.watch(reviewDatasourceProvider);
  return MyCompanyReviewsNotifier(datasource: datasource);
});
