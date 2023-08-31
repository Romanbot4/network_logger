import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http_network_logger/http_network_logger.dart';
import 'package:secure_storage_service/secure_storage_service.dart';

import '../network_client.dart';
import 'token_entity.dart';

class NetworkClient {
  final NetworkClientConfig config;
  final QuickFoodErrorHandler errorHandler;

  const NetworkClient._internal({
    required this.config,
    this.errorHandler = const QuickFoodErrorHandler(),
  });

  static NetworkClient? _instance;
  static Future<NetworkClient> getInstance({
    required NetworkClientConfig config,
    QuickFoodErrorHandler errorHandler = const QuickFoodErrorHandler(),
    Future<void> Function()? onNetworkConnectionError,
  }) async {
    await _initialize();

    _instance ??= NetworkClient._internal(
      config: config,
      errorHandler: errorHandler,
    );

    return _instance!;
  }

  static const Duration timeOutDuration = Duration(seconds: 10);

  static late http.Client _client;
  static String? _token;
  static String? _refreshToken;
  static DateTime? _tokenExpireTimeStamp;

  String? get token => _token;

  static bool _initialized = false;
  static Future<void> _initialize() async {
    if (_initialized) return;
    _client = http.Client();

    _secureStorage = SecureStorageService();
    await _loadAuthKeys();

    _initialized = true;
  }

  static late SecureStorageService _secureStorage;

  static const _userTokenKey = "USER_TOKEN";
  static const _userRefreshTokenKey = "USER_REFRESH_TOKEN";
  static const _tokenExpireTimeStampKey = "TOKEN_EXP_TIMESTAMP";

  bool get isTokenAlive {
    final now = DateTime.now();
    return _tokenExpireTimeStamp?.isAfter(now) == true;
  }

  bool get shouldRefreshToken {
    final now = DateTime.now();
    return _tokenExpireTimeStamp
            ?.subtract(const Duration(days: 1))
            .isBefore(now) ==
        true;
  }

  static Future<void> _loadAuthKeys() async {
    _token = await _secureStorage.getString(_userTokenKey);
    _refreshToken = await _secureStorage.getString(_userRefreshTokenKey);

    final expTime = await _secureStorage.getString(_tokenExpireTimeStampKey);
    _tokenExpireTimeStamp = expTime == null ? null : DateTime.tryParse(expTime);
  }

  static Future<void> _saveAuthKeys() async {
    await _secureStorage.setString(_userTokenKey, _token);
    await _secureStorage.setString(_userRefreshTokenKey, _refreshToken);
    await _secureStorage.setString(
      _tokenExpireTimeStampKey,
      _tokenExpireTimeStamp?.toIso8601String(),
    );
  }

  Future<void> updateTokens(TokensEntity tokensEntity) async {
    return await _updateAuthKeys(
      accessToken: tokensEntity.accessToken,
      refreshToken: tokensEntity.refreshToken,
      expirationDays: tokensEntity.expirationDays,
    );
  }

  static Future<void> _updateAuthKeys({
    required String accessToken,
    required String refreshToken,
    required int expirationDays,
  }) async {
    _token = accessToken;
    _refreshToken = refreshToken;

    final now = DateTime.now();
    final age = Duration(days: expirationDays);
    _tokenExpireTimeStamp = now.add(age);

    await _saveAuthKeys();
  }

  Future<void> _refreshAuthorization() async {
    final tokensEntity = await config.onAccessRefreshRequired.call();
    if (tokensEntity != null) updateTokens(tokensEntity);
  }

  static final _logger = PrettyHttpLogger();
  Future<String> send(
    String? path, {
    String method = 'GET',
    String? bearer,
    Map<String, String>? queryParameters,
    Map<String, String>? optionalHeaders,
    Map<String, String>? body,
    String? jsonString,
    Future<http.MultipartRequest> Function(http.MultipartRequest)? transform,
    int apiVersion = 1,
    bool isUnAuthMethod = false,
  }) async {
    await _initialize();
    try {
      if (shouldRefreshToken && !isUnAuthMethod) await _refreshAuthorization();

      final apiPath = config.apiVersionRoutesMap[apiVersion]!;

      final uri = Uri(
        scheme: config.scheme,
        host: config.host,
        path: "$apiPath${path ?? ''}",
        queryParameters: queryParameters,
      );

      final headers = {
        ...config.getRequestDefaultHeaders,
        if (bearer != null) 'Authorization': 'Bearer $bearer',
        ...optionalHeaders ?? {},
      };

      late StreamedResponse res;

      if (body != null) {
        http.MultipartRequest request = http.MultipartRequest(method, uri);
        request.headers.addAll(headers);
        request.fields.addAll(body);

        request = await transform?.call(request) ?? request;

        if (config.isDebugMode) _logger.printRequest(request);
        res = await _client.send(request);
      } else {
        http.Request request = http.Request(method, uri);

        request.headers.addAll(headers);
        request.body = jsonString!;

        if (config.isDebugMode) _logger.printRequest(request);
        res = await _client.send(request);
      }

      if (config.isDebugMode) _logger.printResponse(res);
      return await res.stream.transform(utf8.decoder).join();
    } catch (err) {
      if (err is SocketException) config.onNetworkConnectionError?.call();
      rethrow;
    }
  }

  Future<String> get(
    String? path, {
    String? bearer,
    Map<String, String>? queryParameters,
    Map<String, String>? optionalHeaders,
    Map<String, dynamic>? data,
    Map<String, String>? body,
    String? jsonString,
    Future<http.MultipartRequest> Function(http.MultipartRequest)? transform,
    int apiVersion = 1,
    bool isUnAuthMethod = false,
  }) async {
    return await send(
      path,
      method: 'GET',
      bearer: bearer,
      queryParameters: queryParameters,
      optionalHeaders: optionalHeaders,
      body: body,
      jsonString: jsonString,
      transform: transform,
      apiVersion: apiVersion,
      isUnAuthMethod: isUnAuthMethod,
    );
  }

  Future<String> post(
    String? path, {
    String? bearer,
    Map<String, String>? queryParameters,
    Map<String, String>? optionalHeaders,
    Map<String, String>? body,
    String? jsonString,
    Future<http.MultipartRequest> Function(http.MultipartRequest)? transform,
    int apiVersion = 1,
    bool isUnAuthMethod = false,
  }) async {
    return await send(
      path,
      method: 'POST',
      bearer: bearer,
      queryParameters: queryParameters,
      optionalHeaders: optionalHeaders,
      body: body,
      jsonString: jsonString,
      transform: transform,
      apiVersion: apiVersion,
      isUnAuthMethod: isUnAuthMethod,
    );
  }

  Future<String> delete(
    String? path, {
    String? bearer,
    Map<String, String>? queryParameters,
    Map<String, String>? optionalHeaders,
    Map<String, String>? body,
    String? jsonString,
    Future<http.MultipartRequest> Function(http.MultipartRequest)? transform,
    int apiVersion = 1,
    bool isUnAuthMethod = false,
  }) async {
    return await send(
      path,
      method: 'DELETE',
      bearer: bearer,
      queryParameters: queryParameters,
      optionalHeaders: optionalHeaders,
      body: body,
      jsonString: jsonString,
      transform: transform,
      apiVersion: apiVersion,
      isUnAuthMethod: isUnAuthMethod,
    );
  }

  Future<String> put(
    String? path, {
    String? bearer,
    Map<String, String>? queryParameters,
    Map<String, String>? optionalHeaders,
    Map<String, String>? body,
    String? jsonString,
    Future<http.MultipartRequest> Function(http.MultipartRequest)? transform,
    int apiVersion = 1,
    bool isUnAuthMethod = false,
  }) async {
    return await send(
      path,
      method: 'PUT',
      bearer: bearer,
      queryParameters: queryParameters,
      optionalHeaders: optionalHeaders,
      body: body,
      jsonString: jsonString,
      transform: transform,
      apiVersion: apiVersion,
      isUnAuthMethod: isUnAuthMethod,
    );
  }
}
