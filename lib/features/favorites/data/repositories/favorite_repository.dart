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

  /// Marks a company as favorite. When [employeeId] is provided, the backend
  /// records the preference so the favorites screen can show the dual-entry
  /// pattern (one card with the pro locked, one without). Throws on error.
  Future<void> add(String companyId, {String? employeeId}) async {
    await _client.post(
      ApiConstants.companyFavorite(companyId),
      data: employeeId == null
          ? null
          : {'employee_id': int.tryParse(employeeId) ?? employeeId},
    );
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
