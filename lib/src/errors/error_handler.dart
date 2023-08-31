import 'package:colorize/colorize.dart';

import 'exceptions/exceptions.dart';

class QuickFoodErrorHandler {
  final void Function(Object?)? onErrorCallback;

  final bool isDebugMode;

  const QuickFoodErrorHandler({
    this.onErrorCallback,
    this.isDebugMode = false,
  });

  void onError(Object error, {String? source}) {
    String message = "QuickFood Client Error - ${source ?? ''}";

    switch (error.runtimeType) {
      case UnauthorizeException:
        error as UnauthorizeException;
        message = '$message Unauthorize Error | ${error.message}';
        break;
      case StatusException:
        error as StatusException;
        message =
            '$message Response Status Error | ${error.status} | ${error.mesasge}';
        break;
      default:
        message = 'Type Error ! $error';
        break;
    }

    // ignore: avoid_print
    if (isDebugMode) print(Colorize(message).bgRed().yellow());
    onErrorCallback?.call(error);
  }
}
