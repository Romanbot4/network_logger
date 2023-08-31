import 'exceptions.dart';

class UnauthorizeException with QuickFoodException {
  final String? message;

  const UnauthorizeException({
    this.message,
  });
}
