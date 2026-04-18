import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/dio_provider.dart';

/// Calls the backend favorite endpoints.
///
/// Both endpoints are idempotent (POST and DELETE) — the server returns 204.
/// Errors bubble up as [DioException] wrapped by [ApiInterceptor] into
/// [ApiException]; callers are responsible for rollback.
class FavoriteRepository {
  final DioClient _client;

  const FavoriteRepository({required DioClient client}) : _client = client;

  /// Marks a company as favorite. Throws on network/API error.
  Future<void> add(String companyId) async {
    await _client.post(ApiConstants.companyFavorite(companyId));
  }

  /// Removes a company from favorites. Throws on network/API error.
  Future<void> remove(String companyId) async {
    await _client.delete(ApiConstants.companyFavorite(companyId));
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return FavoriteRepository(client: client);
});
