import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/dio_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Result type for a successful avatar upload.
typedef AvatarUploadResult = ({String url, String? thumb});

/// Remote repository for /me/avatar operations.
class AvatarRepository {
  final DioClient _client;

  const AvatarRepository({required DioClient client}) : _client = client;

  /// Uploads [bytes] as multipart/form-data to POST /me/avatar.
  ///
  /// Uses [MultipartFile.fromBytes] so it works on Flutter Web too
  /// (dart:io [File] is not available in web builds).
  ///
  /// Returns the new [profileImageUrl] and optional [thumbnailUrl].
  Future<AvatarUploadResult> upload({
    required Uint8List bytes,
    required String filename,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _client.dio.post(
        '${_client.dio.options.baseUrl}${ApiConstants.meAvatar}',
        data: formData,
        onSendProgress: onSendProgress,
      );
      final body = response.data as Map<String, dynamic>;
      final url = body['profileImageUrl'] as String? ?? '';
      final thumb = body['thumbnailUrl'] as String?;
      return (url: url, thumb: thumb);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Deletes the current avatar via DELETE /me/avatar.
  Future<void> delete() async {
    try {
      await _client.delete(ApiConstants.meAvatar);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final avatarRepositoryProvider = Provider<AvatarRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return AvatarRepository(client: client);
});
