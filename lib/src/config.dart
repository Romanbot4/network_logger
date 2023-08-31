import 'package:network_client/src/token_entity.dart';

import 'errors/exceptions/exceptions.dart';

class NetworkClientConfig {
  final String scheme;
  final String host;
  final Map<String, String> getRequestDefaultHeaders;
  final Map<String, String> postRequestDefaultHeaders;
  final Map<String, String> putRequestDefaultHeaders;
  final Future<void> Function()? onNetworkConnectionError;
  final Map<int, String> apiVersionRoutesMap;
  final Future<TokensEntity?> Function() onAccessRefreshRequired;
  final void Function(QuickFoodException)? onError;
  final bool isDebugMode;
  final Duration timeOutDuration;

  const NetworkClientConfig({
    this.scheme = "https",
    required this.host,
    required this.onAccessRefreshRequired,
    this.onNetworkConnectionError,
    this.isDebugMode = false,
    this.getRequestDefaultHeaders = const <String, String>{},
    this.postRequestDefaultHeaders = const <String, String>{},
    this.putRequestDefaultHeaders = const <String, String>{},
    this.apiVersionRoutesMap = const <int, String>{},
    this.onError,
    this.timeOutDuration = const Duration(seconds: 10),
  });
}
