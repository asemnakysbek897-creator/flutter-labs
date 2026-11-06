import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:proflower_lesson_2/core/error/app_exception.dart';
import 'package:proflower_lesson_2/core/network/dio_client.dart';
import 'package:proflower_lesson_2/data/local/post_cache.dart';
import 'package:proflower_lesson_2/data/models/post.dart';
import 'package:proflower_lesson_2/data/remote/post_api.dart';
import 'package:proflower_lesson_2/data/repositories/post_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioAdapter adapter;
  late PostCache cache;
  late PostRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Настоящий DioClient со своими interceptor'ами, но без сети.
    final client = DioClient();
    adapter = DioAdapter(dio: client.dio);
    cache = PostCache();
    repository = PostRepository(PostApi(client.dio), cache);
  });

  const query = {'_page': 1, '_limit': 10};

  test('успешная загрузка постов через репозиторий', () async {
    adapter.onGet(
      '/posts',
      (server) => server.reply(200, [
        {'userId': 1, 'id': 1, 'title': 'Первый', 'body': 'Текст первого'},
        {'userId': 2, 'id': 2, 'title': 'Второй', 'body': 'Текст второго'},
      ]),
      queryParameters: query,
    );

    final posts = await repository.getPosts(page: 1);

    expect(posts.length, 2);
    expect(posts.first.title, 'Первый');
    // Первая страница после успеха сохраняется в кэш.
    final cached = await repository.getCachedPosts();
    expect(cached.length, 2);
  });

  test('ошибка сервера 500 превращается в ServerException', () async {
    adapter.onGet(
      '/posts',
      (server) => server.reply(500, {'message': 'Internal Server Error'}),
      queryParameters: query,
    );

    await expectLater(
      repository.getPosts(page: 1),
      throwsA(
        isA<ServerException>().having((e) => e.statusCode, 'statusCode', 500),
      ),
    );
  });

  test('при ошибке сети последний успешный кэш не удаляется', () async {
    await cache.savePosts([
      Post(userId: 1, id: 1, title: 'Старый пост', body: 'Сохранён раньше'),
    ]);
    adapter.onGet(
      '/posts',
      (server) => server.reply(500, {'message': 'Internal Server Error'}),
      queryParameters: query,
    );

    await expectLater(
      repository.getPosts(page: 1),
      throwsA(isA<ServerException>()),
    );

    final cached = await repository.getCachedPosts();
    expect(cached.length, 1);
    expect(cached.first.title, 'Старый пост');
  });

  test('отправка POST через mock-адаптер возвращает созданный пост', () async {
    adapter.onPost(
      '/posts',
      (server) => server.reply(201, {
        'userId': 1,
        'title': 'Заголовок поста',
        'body': 'Текст нового поста',
        'id': 101,
      }),
      data: Matchers.any,
    );

    final created = await repository.createPost(
      Post(userId: 1, title: 'Заголовок поста', body: 'Текст нового поста'),
    );

    expect(created.id, 101);
    expect(created.title, 'Заголовок поста');
  });
}