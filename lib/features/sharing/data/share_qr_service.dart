import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/dio_provider.dart';

/// Sends the salon QR PNG by email to the authenticated user.
///
/// The PNG is generated client-side via `qr_flutter` + `RepaintBoundary` on
/// the Partage QR screen, then base64-encoded and posted here. The backend
/// validates the magic bytes and queues a Mailable with the PNG attached.
class ShareQrService {
  final DioClient _client;

  const ShareQrService({required DioClient client}) : _client = client;

  Future<void> emailQr({
    required String companyId,
    required Uint8List pngBytes,
    String? caption,
    String? employeeId,
  }) async {
    final body = <String, dynamic>{
      'company_id': int.tryParse(companyId) ?? companyId,
      'qr_png_base64': base64Encode(pngBytes),
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      if (employeeId != null && employeeId.isNotEmpty)
        'employee_id': int.tryParse(employeeId) ?? employeeId,
    };
    await _client.post(ApiConstants.shareQrEmail, data: body);
  }
}

final shareQrServiceProvider = Provider<ShareQrService>((ref) {
  return ShareQrService(client: ref.watch(dioClientProvider));
});
