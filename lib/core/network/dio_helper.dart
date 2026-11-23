import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/constants.dart';
import 'api_exception.dart';

export 'package:dio/dio.dart';

class DioHelper {
  Dio dio = Dio();
  CancelToken cancelToken = CancelToken();

  DioHelper() {
    _init();
  }

  void _init() {
    dio = Dio();
    dio.options.baseUrl = AppConstants.baseUrl;
    dio.options.followRedirects = true;
    dio.options.headers[HttpHeaders.acceptHeader] = 'application/json';
    dio.options.connectTimeout = const Duration(
      milliseconds: AppConstants.connectTimeoutMs,
    );
    dio.options.receiveTimeout = const Duration(
      milliseconds: AppConstants.receiveTimeoutMs,
    );

    _setupErrorInterceptor();
    _setupLogInterceptor();
  }

  void reInitializeCancelToken() => cancelToken = CancelToken();

  void _setupErrorInterceptor() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.cancelToken = cancelToken;
          handler.next(options);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) {
          if (error.type == DioExceptionType.badResponse) {
            final statusCode = error.response?.statusCode;
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: error.type,
                error: _handleStatusCode(statusCode),
              ),
            );
            return;
          }

          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                type: error.type,
                error: const ApiException(
                  'Connection timed out. Please try again.',
                ),
              ),
            );
            return;
          }

          if (error.type == DioExceptionType.cancel) {
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                type: error.type,
                error: const ApiException('Request was cancelled.'),
              ),
            );
            return;
          }

          if (error.type == DioExceptionType.connectionError ||
              error.error is SocketException) {
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                type: error.type,
                error: const ApiException(
                  'No internet connection. Please check your network.',
                ),
              ),
            );
            return;
          }

          // unknown errors
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              type: error.type,
              error: const ApiException(
                'Something went wrong. Please try again.',
              ),
            ),
          );
        },
      ),
    );
  }

  ApiException _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return const ApiException('Bad request.', statusCode: 400);
      case 403:
        return const ApiException('Access denied.', statusCode: 403);
      case 404:
        return const ApiException('Resource not found.', statusCode: 404);
      case 405:
        return const ApiException('Method not allowed.', statusCode: 405);
      case 429:
        return const ApiException(
          'Too many requests. Please wait a moment.',
          statusCode: 429,
        );
      case 500:
        return const ApiException(
          'Internal server error. Please try later.',
          statusCode: 500,
        );
      case 502:
        return const ApiException(
          'Bad gateway. Please try later.',
          statusCode: 502,
        );
      case 503:
        return const ApiException(
          'Service unavailable. Please try later.',
          statusCode: 503,
        );
      default:
        return ApiException(
          'Something went wrong. Please try again.',
          statusCode: statusCode,
        );
    }
  }

  void _setupLogInterceptor() {
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }
}

final DioHelper dioHelper = DioHelper();
final Dio dio = dioHelper.dio;
