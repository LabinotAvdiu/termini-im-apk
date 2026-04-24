import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/notification_preference_model.dart';

/// D19 — Datasource pour les préférences granulaires (channel × type).
class NotificationPreferencesRemoteDatasource {
  final DioClient _client;

  const NotificationPreferencesRemoteDatasource(this._client);

  /// GET /api/me/notification-preferences/granular
  Future<List<NotificationPreferenceModel>> getAll() async {
    try {
      final response = await _client.get(
        ApiConstants.myNotificationPreferencesGranular,
      );

      final raw = (response.data as Map<String, dynamic>)['data'] as List;
      return raw
          .map((e) => NotificationPreferenceModel.fromJson(
                e as Map<String, dynamic>,
              ))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// PATCH /api/me/notification-preferences/granular
  ///
  /// Envoie un tableau de mises à jour (channel, type, enabled).
  /// Utilise [DioClient.dio] directement car DioClient n'expose pas encore PATCH.
  Future<List<NotificationPreferenceModel>> updateAll(
    List<NotificationPreferenceModel> updates,
  ) async {
    try {
      final response = await _client.dio.patch(
        ApiConstants.myNotificationPreferencesGranular,
        data: updates.map((e) => e.toJson()).toList(),
      );

      final raw = (response.data as Map<String, dynamic>)['data'] as List;
      return raw
          .map((e) => NotificationPreferenceModel.fromJson(
                e as Map<String, dynamic>,
              ))
          .toList();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
