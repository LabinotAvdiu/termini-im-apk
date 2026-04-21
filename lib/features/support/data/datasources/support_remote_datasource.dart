import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/dio_provider.dart';
import '../models/support_models.dart';

class SupportRemoteDataSource {
  final DioClient _client;
  const SupportRemoteDataSource({required DioClient client}) : _client = client;

  /// Submits a support ticket (multipart: fields + up to 3 files).
  /// Returns the server-side ticket id on 201.
  Future<int> submitTicket(SupportTicketRequest request) async {
    final fields = <String, dynamic>{
      'first_name': request.firstName,
      'phone': request.phone,
      'message': request.message,
      'source_page': request.sourcePage.wireValue,
    };
    if (request.email != null && request.email!.isNotEmpty) {
      fields['email'] = request.email;
    }
    final ctx = request.sourceContext;
    if (ctx != null) {
      ctx.forEach((k, v) {
        if (v != null) fields['source_context[$k]'] = v.toString();
      });
    }
    for (var i = 0; i < request.attachments.length; i++) {
      final a = request.attachments[i];
      fields['attachments[$i]'] = MultipartFile.fromBytes(
        a.bytes,
        filename: a.name,
      );
    }

    try {
      final response = await _client.dio.post(
        '${_client.dio.options.baseUrl}${ApiConstants.supportTickets}',
        data: FormData.fromMap(fields),
      );
      final body = response.data as Map<String, dynamic>;
      return (body['id'] as num).toInt();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

final supportRemoteDataSourceProvider = Provider<SupportRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return SupportRemoteDataSource(client: client);
});
