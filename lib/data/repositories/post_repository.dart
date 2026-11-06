import 'package:dio/dio.dart';   // Импорт сетевой библиотеки Dio для обработки сетевых ошибок

import '../../core/error/app_exception.dart';   // Импорт кастомных исключений приложения
import '../local/post_cache.dart';   // Импорт сервиса локального кэширования постов
import '../models/comment.dart';   // Импорт модели данных комментариев
import '../models/post.dart';   // Импорт модели данных постов
import '../models/user.dart';   // Импорт модели данных пользователей
import '../remote/post_api.dart';   // Импорт Retrofit API клиента для сетевых запросов

class PostRepository {   // Класс-репозиторий для управления источниками данных (сеть + кэш)
  final PostApi _api;   // Ссылка на удаленный API клиент
  final PostCache _cache;   // Ссылка на локальный кэш

  PostRepository(this._api, this._cache);   // Конструктор для внедрения зависимостей API и кэша

  /// Сохранённые ранее посты (для показа, пока идёт запрос).
  Future<List<Post>> getCachedPosts() => _cache.loadPosts();   // Метод загрузки постов из локального кэша

  /// Загружает страницу постов. Первую страницу сохраняет в кэш.
  Future<List<Post>> getPosts({required int page, int limit = 10}) async {   // Метод получения списка постов с пагинацией
    final posts = await _guard(() => _api.getPosts(page: page, limit: limit));   // Запрос к серверу через защитный метод _guard
    if (page == 1) {   // Если это первая страница постов
      await _cache.savePosts(posts);   // Сохраняем её в локальный кэш
    }
    return posts;   // Возвращаем полученный список постов
  }

  Future<List<Post>> getPostsByUser(int userId) {   // Метод получения постов конкретного пользователя
    return _guard(() => _api.getPostsByUser(userId));   // Выполнение запроса через _guard
  }

  Future<List<Comment>> getPostComments(int postId) {   // Метод получения комментариев к посту
    return _guard(() => _api.getPostComments(postId));   // Выполнение запроса через _guard
  }

  Future<List<User>> getUsers() {   // Метод получения списка пользователей
    return _guard(() => _api.getUsers());   // Выполнение запроса через _guard
  }

  Future<Post> createPost(Post post) {   // Метод создания нового поста
    return _guard(() => _api.createPost(post));   // Выполнение запроса через _guard
  }

  /// Выполняет запрос и превращает любые сбои в AppException.
  Future<T> _guard<T>(Future<T> Function() request) async {   // Вспомогательный метод для централизованной обработки ошибок
    try {
      return await request();   // Попытка выполнить переданный сетевой запрос
    } on DioException catch (e) {   // Перехват сетевых ошибок Dio
      final error = e.error;   // Получение внутренней ошибки
      if (error is AppException) throw error;   // Если это кастомное исключение приложения — пробрасываем его дальше
      throw AppException('Произошла непредвиденная ошибка.');   // Иначе генерируем общую ошибку приложения
    } on AppException {
      rethrow;   // Повторный проброс уже известных AppException
    } catch (_) {
      throw ParsingException('Сервер прислал данные в неожиданном формате.');   // Обработка ошибок парсинга или других непредвиденных сбоев
    }
  }
}