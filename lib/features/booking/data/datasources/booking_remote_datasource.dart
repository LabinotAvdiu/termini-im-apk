import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/available_slot_model.dart';
import '../models/booking_model.dart';
import '../models/day_availability_model.dart';

class BookingRemoteDatasource {
  final DioClient _client;

  const BookingRemoteDatasource({required DioClient client}) : _client = client;

  /// Fetch 14-day availability for a company.
  Future<List<DayAvailability>> getAvailability({
    required String companyId,
    String? employeeId,
    String? serviceId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (employeeId != null) 'employee_id': employeeId,
        if (serviceId != null) 'service_id': serviceId,
      };

      final response = await _client.get(
        ApiConstants.companyAvailability(companyId),
        queryParameters: queryParams,
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];

      return data
          .map((e) => DayAvailability.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Fetch available time slots for a company on a specific date.
  Future<List<AvailableSlotModel>> getSlots({
    required String companyId,
    required String date,
    String? employeeId,
    String? serviceId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'date': date,
        if (employeeId != null) 'employee_id': employeeId,
        if (serviceId != null) 'service_id': serviceId,
      };

      final response = await _client.get(
        ApiConstants.companySlots(companyId),
        queryParameters: queryParams,
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];

      return data
          .map((e) => AvailableSlotModel.fromJson(e as Map<String, dynamic>))
          .where((slot) => slot.available)
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Create a booking.
  Future<BookingModel> createBooking({
    required String companyId,
    required String serviceId,
    String? employeeId,
    required String dateTime,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.bookings,
        data: {
          'company_id': companyId,
          'service_id': serviceId,
          'employee_id': employeeId,
          'date_time': dateTime,
        },
      );

      return BookingModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  ApiException _mapDioException(DioException e) {
    final wrapped = e.error;
    if (wrapped is ApiException) return wrapped;
    final statusCode = e.response?.statusCode;
    String? msg;
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      msg = data['message'] as String?;
    }
    if (statusCode != null && statusCode >= 500) {
      return ServerException(message: msg ?? 'Erreur serveur');
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkException();
    }
    return ApiException(
      message: msg ?? e.message ?? 'Erreur inconnue',
      statusCode: statusCode,
    );
  }
}
