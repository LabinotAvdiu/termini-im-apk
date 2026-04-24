import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/analytics_service.dart';
import '../../data/repositories/favorite_repository.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../company_detail/presentation/providers/company_detail_provider.dart';

// ---------------------------------------------------------------------------
// FavoriteNotifier
// ---------------------------------------------------------------------------
//
// Responsibilities:
//  1. Call the backend (add / remove).
//  2. Optimistically patch the home list and the detail provider so UI reacts
//     immediately — no full refetch needed.
//  3. On error: rollback both providers + expose the error for SnackBar.
//
// The notifier itself holds no persistent state — the source of truth lives in
// [CompanyListNotifier] and [CompanyDetailNotifier].
// ---------------------------------------------------------------------------

class FavoriteNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  FavoriteRepository get _repo => ref.read(favoriteRepositoryProvider);

  /// Adds [companyId] to favorites with optimistic UI update.
  /// Returns `true` on success, `false` on failure (already rolled back).
  Future<bool> add(String companyId) async {
    // Optimistic update — patch home list
    ref
        .read(companyListProvider.notifier)
        .patchFavorite(companyId: companyId, isFavorite: true);

    // Optimistic update — patch detail if loaded
    ref
        .read(companyDetailProvider.notifier)
        .setFavoriteIfLoaded(companyId: companyId, isFavorite: true);

    state = const AsyncLoading();
    try {
      await _repo.add(companyId);
      state = const AsyncData(null);
      // E25 — favorite_added
      ref.read(analyticsProvider).logFavoriteAdded(salonId: companyId);
      return true;
    } catch (e, st) {
      // Rollback
      ref
          .read(companyListProvider.notifier)
          .patchFavorite(companyId: companyId, isFavorite: false);
      ref
          .read(companyDetailProvider.notifier)
          .setFavoriteIfLoaded(companyId: companyId, isFavorite: false);
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Removes [companyId] from favorites with optimistic UI update.
  /// Returns `true` on success, `false` on failure (already rolled back).
  Future<bool> remove(String companyId) async {
    // Optimistic update
    ref
        .read(companyListProvider.notifier)
        .patchFavorite(companyId: companyId, isFavorite: false);
    ref
        .read(companyDetailProvider.notifier)
        .setFavoriteIfLoaded(companyId: companyId, isFavorite: false);

    state = const AsyncLoading();
    try {
      await _repo.remove(companyId);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      // Rollback
      ref
          .read(companyListProvider.notifier)
          .patchFavorite(companyId: companyId, isFavorite: true);
      ref
          .read(companyDetailProvider.notifier)
          .setFavoriteIfLoaded(companyId: companyId, isFavorite: true);
      state = AsyncError(e, st);
      return false;
    }
  }
}

final favoriteProvider =
    NotifierProvider<FavoriteNotifier, AsyncValue<void>>(
  FavoriteNotifier.new,
);
