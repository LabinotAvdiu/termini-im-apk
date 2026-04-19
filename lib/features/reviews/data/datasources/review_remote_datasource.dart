import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/review_model.dart';

class ReviewRemoteDatasource {
  final DioClient _client;

  const ReviewRemoteDatasource({required DioClient client}) : _client = client;

  // ── Client ────────────────────────────────────────────────────────────────

  Future<ReviewModel> submitReview(
    String appointmentId, {
    required int rating,
    String? comment,
  }) async {
    try {
      final data = <String, dynamic>{'rating': rating};
      if (comment != null && comment.trim().isNotEmpty) {
        data['comment'] = comment.trim();
      }
      final response = await _client.post(
        ApiConstants.appointmentReview(appointmentId),
        data: data,
      );
      final body = response.data as Map<String, dynamic>;
      final reviewData =
          body['data'] as Map<String, dynamic>? ?? body;
      return ReviewModel.fromJson(reviewData);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<ReviewModel?> getReviewForAppointment(String appointmentId) async {
    try {
      final response = await _client.get(
        ApiConstants.appointmentReview(appointmentId),
      );
      final body = response.data as Map<String, dynamic>;
      final reviewData =
          body['data'] as Map<String, dynamic>? ?? body;
      return ReviewModel.fromJson(reviewData);
    } on DioException catch (e) {
      final ex = mapDioException(e);
      if (ex.kind == ApiErrorKind.notFound) return null;
      throw ex;
    }
  }

  Future<PaginatedReviews> getCompanyReviews(
    String companyId, {
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await _client.get(
        '${ApiConstants.companyReviews(companyId)}?page=$page&per_page=$perPage',
      );
      return PaginatedReviews.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  // ── Owner ─────────────────────────────────────────────────────────────────

  Future<PaginatedReviews> getMyCompanyReviews({int page = 1}) async {
    try {
      final response = await _client.get(
        '${ApiConstants.myCompanyReviews}?page=$page&per_page=20',
      );
      return PaginatedReviews.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<ReviewModel> hideReview(String reviewId, {String? reason}) async {
    try {
      final data = <String, dynamic>{};
      if (reason != null && reason.trim().isNotEmpty) {
        data['reason'] = reason.trim();
      }
      final response = await _client.put(
        ApiConstants.myCompanyReviewHide(reviewId),
        data: data,
      );
      final body = response.data as Map<String, dynamic>;
      return ReviewModel.fromJson(body['data'] as Map<String, dynamic>? ?? body);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<ReviewModel> unhideReview(String reviewId) async {
    try {
      final response = await _client.put(
        ApiConstants.myCompanyReviewUnhide(reviewId),
        data: <String, dynamic>{},
      );
      final body = response.data as Map<String, dynamic>;
      return ReviewModel.fromJson(body['data'] as Map<String, dynamic>? ?? body);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
