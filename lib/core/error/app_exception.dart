class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => message;
}

class TimeoutException extends AppException {
  TimeoutException(super.message);
}

class NetworkException extends AppException {
  NetworkException(super.message);
}

class ServerException extends AppException {
  final int? statusCode;

  ServerException(super.message, {this.statusCode});
}

class ParsingException extends AppException {
  ParsingException(super.message);
}