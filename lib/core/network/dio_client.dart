import 'package:dio/dio.dart';
import '../error/app_exception.dart';

class DioClient {
late final Dio dio;

DioClient() {
dio = Dio(
BaseOptions(
baseUrl: 'https://jsonplaceholder.typicode.com',
connectTimeout: const Duration(seconds: 5),
receiveTimeout: const Duration(seconds: 5),
headers: {
'Content-Type': 'application/json; charset=UTF-8',
'X-Client-Type': 'Flutter-Web',
        },
      ),
    );

dio.interceptors.add(LogInterceptor(
request: true,
requestBody: true,
responseBody: true,
error: true,
    ));

dio.interceptors.add(InterceptorsWrapper(
onError: (DioException err, ErrorInterceptorHandler handler) {
AppException appException;
switch (err.type) {
case DioExceptionType.connectionTimeout:
case DioExceptionType.sendTimeout:
case DioExceptionType.receiveTimeout:
appException = TimeoutException('Превышено время ожидания соединения.');
break;
case DioExceptionType.connectionError:
appException = NetworkException('Отсутствует подключение к интернету.');
break;
case DioExceptionType.badResponse:
final code = err.response?.statusCode;
appException = ServerException(
'Ошибка сервера: ${err.response?.statusMessage ?? 'Неизвестно'}',
statusCode: code,
            );
break;
default:
appException = AppException('Произошла непредвиденная ошибка: ${err.message}');
        }
return handler.next(DioException(
requestOptions: err.requestOptions,
error: appException,
type: err.type,
response: err.response,
        ));
      },
    ));
  }
}