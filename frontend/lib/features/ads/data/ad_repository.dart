import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../auth/data/auth_repository.dart' show ApiException;
import 'ad_dtos.dart';

class AdRepository {
  final Dio _dio;
  AdRepository(this._dio);

  Future<AdPricingInfo> pricing() async {
    try {
      final res = await _dio.get('/api/ads/pricing');
      if (res.statusCode != 200) throw _toApiException(res);
      final pricing =
          (res.data as Map<String, dynamic>)['pricing'] as Map<String, dynamic>;
      return AdPricingInfo.fromJson(pricing);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<List<Advertisement>> listActive({
    AdPlacementType? placement,
    int limit = 5,
  }) async {
    try {
      final res = await _dio.get(
        '/api/ads/active',
        queryParameters: {
          'limit': limit.toString(),
          if (placement != null) 'placement': placement.toWire(),
        },
      );
      if (res.statusCode != 200) throw _toApiException(res);
      final data = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
      return data
          .cast<Map<String, dynamic>>()
          .map(Advertisement.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<AdRequestResult> submitRequest({
    required String companyName,
    required String contactEmail,
    required String contactPhone,
    required String title,
    String? description,
    required String targetUrl,
    required int durationDays,
    AdPlacementType placementType = AdPlacementType.banner,
    Uint8List? imageBytes,
    String? imageFilename,
  }) async {
    try {
      final form = FormData.fromMap({
        'companyName': companyName,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        'targetUrl': targetUrl,
        'durationDays': durationDays.toString(),
        'placementType': placementType.toWire(),
      });
      if (imageBytes != null && imageFilename != null) {
        form.files.add(
          MapEntry(
            'image',
            MultipartFile.fromBytes(imageBytes, filename: imageFilename),
          ),
        );
      }

      final res = await _dio.post(
        '/api/ads/request',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      if (res.statusCode != 201) throw _toApiException(res);
      final body = res.data as Map<String, dynamic>;
      final ad = Advertisement.fromJson(
        body['advertisement'] as Map<String, dynamic>,
      );
      final pricing = body['pricing'] as Map<String, dynamic>? ?? {};
      return AdRequestResult(
        advertisement: ad,
        amountEtb: (pricing['amountEtb'] as num?)?.toDouble() ?? 0,
        dailyRateEtb: (pricing['dailyRateEtb'] as num?)?.toDouble() ?? 0,
        durationDays: (pricing['durationDays'] as num?)?.toInt() ?? durationDays,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<({Advertisement advertisement, double amountEtb})> getForPayment(
      int id) async {
    try {
      final res = await _dio.get('/api/ads/pay/$id');
      if (res.statusCode != 200) throw _toApiException(res);
      final body = res.data as Map<String, dynamic>;
      final ad = Advertisement.fromJson(
        body['advertisement'] as Map<String, dynamic>,
      );
      final pricing = body['pricing'] as Map<String, dynamic>? ?? {};
      return (
        advertisement: ad,
        amountEtb: (pricing['amountEtb'] as num?)?.toDouble() ?? 0,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Advertisement> getRequestStatus(int id) async {
    try {
      final res = await _dio.get('/api/ads/request/$id');
      if (res.statusCode != 200) throw _toApiException(res);
      return Advertisement.fromJson(
        (res.data as Map<String, dynamic>)['advertisement']
            as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Advertisement> verifyPaymentStatus(int id) async {
    try {
      final res = await _dio.get('/api/ads/$id/verify-payment');
      if (res.statusCode != 200) throw _toApiException(res);
      return Advertisement.fromJson(
        (res.data as Map<String, dynamic>)['advertisement']
            as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<void> recordImpression(int adId) async {
    try {
      await _dio.post('/api/ads/$adId/impression');
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<void> recordClick(int adId) async {
    try {
      await _dio.post('/api/ads/$adId/click');
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<String> initializePayment(int id) async {
    try {
      final res = await _dio.get('/api/ads/$id/payment/initiate');
      if (res.statusCode != 200) throw _toApiException(res);
      return (res.data as Map<String, dynamic>)['paymentUrl'] as String;
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<({List<Advertisement> items, int total})> adminList({
    AdStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get(
        '/api/ads/admin/list',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (status != null) 'status': _statusWire(status),
        },
      );
      if (res.statusCode != 200) throw _toApiException(res);
      final body = res.data as Map<String, dynamic>;
      final items = (body['data'] as List)
          .cast<Map<String, dynamic>>()
          .map(Advertisement.fromJson)
          .toList();
      final meta = (body['meta'] as Map?)?.cast<String, dynamic>() ?? {};
      return (items: items, total: (meta['total'] as num?)?.toInt() ?? 0);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Advertisement> adminApprove(int id) async {
    try {
      final res = await _dio.post('/api/ads/admin/$id/approve');
      if (res.statusCode != 200) throw _toApiException(res);
      return Advertisement.fromJson(
        (res.data as Map<String, dynamic>)['advertisement']
            as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<Advertisement> adminReject(int id, {String? reason}) async {
    try {
      final res = await _dio.post(
        '/api/ads/admin/$id/reject',
        data: {if (reason != null) 'reason': reason},
      );
      if (res.statusCode != 200) throw _toApiException(res);
      return Advertisement.fromJson(
        (res.data as Map<String, dynamic>)['advertisement']
            as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  String _statusWire(AdStatus s) {
    switch (s) {
      case AdStatus.pendingReview:
        return 'PENDING_REVIEW';
      case AdStatus.awaitingPayment:
        return 'AWAITING_PAYMENT';
      case AdStatus.active:
        return 'ACTIVE';
      case AdStatus.rejected:
        return 'REJECTED';
      case AdStatus.expired:
        return 'EXPIRED';
    }
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

final adRepositoryProvider = Provider<AdRepository>((ref) {
  return AdRepository(ref.watch(apiClientProvider).dio);
});
