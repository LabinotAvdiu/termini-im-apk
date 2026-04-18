import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/company_card_model.dart';

class CompanyListResponse {
  final List<CompanyCardModel> companies;
  final int currentPage;
  final int lastPage;
  final int total;

  const CompanyListResponse({
    required this.companies,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}

class CompanyRemoteDatasource {
  final DioClient _client;

  const CompanyRemoteDatasource({required DioClient client}) : _client = client;

  Future<CompanyListResponse> getCompanies({
    String? search,
    String? city,
    String? gender,
    String? date,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (city != null && city.isNotEmpty) 'city': city,
        if (gender != null && gender != 'both') 'gender': gender,
        if (date != null) 'date': date,
      };

      final response = await _client.get(
        ApiConstants.companies,
        queryParameters: queryParams,
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];
      final meta = body['meta'] as Map<String, dynamic>? ?? {};

      return CompanyListResponse(
        companies: data
            .map((e) => CompanyCardModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentPage: meta['current_page'] as int? ?? 1,
        lastPage: meta['last_page'] as int? ?? 1,
        total: meta['total'] as int? ?? 0,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  ApiException _mapDioException(DioException e) => mapDioException(e);
}
