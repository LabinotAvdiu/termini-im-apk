import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/dio_provider.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class NotificationPreferences {
  final bool notifyNewBooking;
  final bool notifyQuietDayReminder;

  const NotificationPreferences({
    required this.notifyNewBooking,
    required this.notifyQuietDayReminder,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      notifyNewBooking: (json['notifyNewBooking'] as bool?) ?? true,
      notifyQuietDayReminder: (json['notifyQuietDayReminder'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'notifyNewBooking': notifyNewBooking,
        'notifyQuietDayReminder': notifyQuietDayReminder,
      };

  NotificationPreferences copyWith({
    bool? notifyNewBooking,
    bool? notifyQuietDayReminder,
  }) {
    return NotificationPreferences(
      notifyNewBooking: notifyNewBooking ?? this.notifyNewBooking,
      notifyQuietDayReminder:
          notifyQuietDayReminder ?? this.notifyQuietDayReminder,
    );
  }
}

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class NotificationRepository {
  final DioClient _client;

  const NotificationRepository(this._client);

  // ---- Préférences (owner / employee uniquement) --------------------------

  Future<NotificationPreferences> getPreferences() async {
    try {
      final response =
          await _client.get(ApiConstants.myNotificationPreferences);
      return NotificationPreferences.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> updatePreferences(NotificationPreferences prefs) async {
    try {
      await _client.put(
        ApiConstants.myNotificationPreferences,
        data: prefs.toJson(),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ---- Device token (tous les rôles) --------------------------------------

  /// Enregistre un device token FCM côté backend (idempotent).
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {
    try {
      await _client.post(
        ApiConstants.myDevices,
        data: {'token': token, 'platform': platform},
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Supprime un device token FCM côté backend (idempotent).
  Future<void> unregisterDevice({required String token}) async {
    try {
      await _client.delete(
        ApiConstants.myDevices,
        data: {'token': token},
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return NotificationRepository(client);
});
