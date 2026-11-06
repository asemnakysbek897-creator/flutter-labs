import 'package:dio/dio.dart';   // Импорт сетевой библиотеки Dio для выполнения HTTP-запросов
import 'package:retrofit/retrofit.dart';   // Импорт генератора Retrofit для декларативного описания API
import '../models/post.dart';   // Импорт модели данных Post (посты)
import '../models/comment.dart';   // Импорт модели данных Comment (комментарии)
import '../models/user.dart';   // Импорт модели данных User (пользователи)

part 'post_api.g.dart';   // Подключение сгенерированного файла реализации Retrofit (через build_runner)

@RestApi(baseUrl: 'https://jsonplaceholder.typicode.com')   // Аннотация с базовой ссылкой (URL) для всех API-запросов
abstract class PostApi {   // Абстрактный класс, описывающий эндпоинты сервера
  factory PostApi(Dio dio, {String baseUrl}) = _PostApi;   // Фабричный конструктор для инициализации сгенерированного класса

  @GET('/posts')   // GET-запрос для получения списка всех постов
  Future<List<Post>> getPosts({
    @Query('_page') required int page,   // Параметр запроса для пагинации (номер страницы)
    @Query('_limit') required int limit,   // Параметр запроса для ограничения количества элементов на странице
  });

  @GET('/posts/{id}')   // GET-запрос для получения конкретного поста по его ID
  Future<Post> getPostById(@Path('id') int id);   // Передача ID в путь URL

  @GET('/posts')   // GET-запрос для получения постов конкретного пользователя
  Future<List<Post>> getPostsByUser(@Query('userId') int userId);   // Фильтрация по Query-параметру userId

  @GET('/posts/{id}/comments')   // GET-запрос для получения комментариев к определенному посту
  Future<List<Comment>> getPostComments(@Path('id') int id);   // Передача ID поста в путь URL

  @POST('/posts')   // POST-запрос для создания нового поста
  Future<Post> createPost(@Body() Post post);   // Передача объекта поста в теле запроса (Body)

  @GET('/users')   // GET-запрос для получения списка всех пользователей
  Future<List<User>> getUsers();

  @GET('/users/{id}')   // GET-запрос для получения данных конкретного пользователя по ID
  Future<User> getUserById(@Path('id') int id);   // Передача ID пользователя в путь URL
}