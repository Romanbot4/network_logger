import 'exceptions.dart';

class StatusException with QuickFoodException {
  final int status;
  final String? mesasge;

  const StatusException({
    required this.status,
    this.mesasge,
  });
}
