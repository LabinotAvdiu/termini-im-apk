import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/notification_log_entry_model.dart';

/// D20-inbox — Datasource pour le journal de notifications.
///
/// Tous les appels requièrent un token Sanctum valide (fourni par [DioClient]).
class NotificationsLogRemoteDatasource {
  const NotificationsLogRemoteDatasource(this._client);

  final DioClient _client;

  /// GET /api/me/notifications-log?limit=[limit]
  Future<List<NotificationLogEntry>> fetchLog({int limit = 50}) async {
    try {
      final response = await _client.get(
        ApiConstants.myNotificationsLog,
        queryParameters: {'limit': limit},
      );

      final raw = (response.data as Map<String, dynamic>)['data'] as List;
      return raw
          .map((e) => NotificationLogEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// PATCH /api/me/notifications-log/{id}/read
  Future<void> markAsRead(int id) async {
    try {
      await _client.dio.patch(ApiConstants.myNotificationsLogMarkRead(id));
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// PATCH /api/me/notifications-log/read-all
  /// Retourne le nombre de lignes affectées.
  Future<int> markAllAsRead() async {
    try {
      final response = await _client.dio.patch(
        ApiConstants.myNotificationsLogReadAll,
      );
      return (response.data as Map<String, dynamic>)['affected'] as int? ?? 0;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
