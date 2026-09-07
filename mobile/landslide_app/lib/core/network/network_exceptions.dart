/// Network Exception classes for clean error handling
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  NetworkException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => message;
}

class UnauthorizedException extends NetworkException {
  UnauthorizedException({String message = 'Unauthorized access. Please login again.'})
      : super(message: message, statusCode: 401);
}

class NoInternetException extends NetworkException {
  NoInternetException({String message = 'No internet connection detected. Working in offline mode.'})
      : super(message: message, statusCode: 0);
}

class ServerException extends NetworkException {
  ServerException({String message = 'Server encountered an error. Please try again later.', int? statusCode})
      : super(message: message, statusCode: statusCode ?? 500);
}

class TimeoutException extends NetworkException {
  TimeoutException({String message = 'Connection timed out. Please check your network.'})
      : super(message: message, statusCode: 408);
}
