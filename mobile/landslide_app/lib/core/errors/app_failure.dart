/// Standard domain failure representation
class AppFailure {
  final String message;
  final int? code;
  final dynamic originalError;

  AppFailure({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => message;
}
