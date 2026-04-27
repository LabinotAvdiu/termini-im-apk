import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/dio_provider.dart';
import '../models/admin_support_ticket_model.dart';

class AdminSupportTicketsDatasource {
  final DioClient _client;
  const AdminSupportTicketsDatasource({required DioClient client})
      : _client = client;

  Future<({List<AdminSupportTicket> tickets, bool hasMore})> listTickets({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _client.dio.get(
        ApiConstants.adminSupportTickets,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final body = response.data as Map<String, dynamic>;
      final items = (body['data'] as List<dynamic>)
          .map((e) => AdminSupportTicket.fromJson(e as Map<String, dynamic>))
          .toList();
      final meta = body['meta'] as Map<String, dynamic>?;
      final lastPage = (meta?['last_page'] as num?)?.toInt() ?? 1;
      return (tickets: items, hasMore: page < lastPage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> markResolved(int id) async {
    try {
      await _client.dio.patch(
        ApiConstants.adminSupportTicket(id.toString()),
        data: {'status': 'resolved'},
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

final adminSupportTicketsDatasourceProvider =
    Provider<AdminSupportTicketsDatasource>((ref) {
  return AdminSupportTicketsDatasource(client: ref.watch(dioClientProvider));
});
