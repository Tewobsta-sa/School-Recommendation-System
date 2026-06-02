import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../auth/data/auth_repository.dart';
import 'review_dtos.dart';

class ReviewRepository {
  final Dio _dio;
  ReviewRepository(this._dio);

  Future<List<Review>> listForSchool(int schoolId, {int? offset, int? limit}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (offset != null) queryParams['offset'] = offset;
      if (limit != null) queryParams['limit'] = limit;
      
      final res = await _dio.get(
        '/api/reviews/school/$schoolId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (res.statusCode != 200) throw _toApiException(res);
      final body = res.data as Map<String, dynamic>;
      return (body['data'] as List)
          .cast<Map<String, dynamic>>()
          .map(Review.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Review> create(int schoolId, ReviewInput input) async {
    try {
      final res = await _dio.post(
        '/api/reviews/$schoolId',
        data: input.toJson(),
      );
      if (res.statusCode != 201 && res.statusCode != 200) {
        throw _toApiException(res);
      }
      final body = res.data as Map<String, dynamic>;
      return Review.fromJson(body['review'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Review> update(int reviewId, ReviewInput input) async {
    try {
      final res = await _dio.put(
        '/api/reviews/$reviewId',
        data: input.toJson(),
      );
      if (res.statusCode != 200) throw _toApiException(res);
      final body = res.data as Map<String, dynamic>;
      return Review.fromJson(body['review'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<void> delete(int reviewId) async {
    try {
      final res = await _dio.delete('/api/reviews/$reviewId');
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw _toApiException(res);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }
}

ApiException _toApiException(Response<dynamic> r) {
  final data = r.data;
  if (data is Map) {
    final msg =
        (data['error'] ?? data['message'])?.toString() ?? 'Request failed';
    final code = data['code']?.toString();
    return ApiException(msg, statusCode: r.statusCode, code: code);
  }
  return ApiException('Request failed (${r.statusCode})',
      statusCode: r.statusCode);
}

ApiException _handleDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return ApiException('Request timed out. Please check your connection and try again.');
    case DioExceptionType.connectionError:
      return ApiException('Please check your internet connection and try again.');
    case DioExceptionType.badResponse:
      if (e.response != null) {
        return _toApiException(e.response!);
      }
      return ApiException('Server error occurred. Please try again later.');
    case DioExceptionType.cancel:
      return ApiException('Request was cancelled.');
    case DioExceptionType.unknown:
      if (e.error != null && e.error.toString().contains('SocketException')) {
        return ApiException('Please check your internet connection and try again.');
      }
      return ApiException('An unexpected error occurred. Please try again.');
    default:
      return ApiException('An unexpected error occurred. Please try again.');
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(apiClientProvider).dio);
});
