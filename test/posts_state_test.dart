import 'package:flutter_test/flutter_test.dart';
import 'package:proflower_lesson_2/data/models/post.dart';
import 'package:proflower_lesson_2/presentation/state/posts_state.dart';
import 'package:proflower_lesson_2/presentation/state/posts_status.dart';

void main() {
  final posts = [
    Post(userId: 1, id: 1, title: 'Alpha one', body: 'Первый пост'),
    Post(userId: 2, id: 2, title: 'Beta two', body: 'Второй пост'),
    Post(userId: 1, id: 3, title: 'Gamma alpha', body: 'Третий пост'),
  ];

  List<int?> ids(PostsState state) =>
      state.visiblePosts.map((p) => p.id).toList();

  group('Фильтрация постов', () {
    test('фильтр по автору оставляет только его посты', () {
      final state = PostsState(
        status: PostsStatus.success,
        posts: posts,
        userId: 1,
      );

      expect(ids(state), [1, 3]);
    });

    test('поиск по заголовку не зависит от регистра', () {
      final state = PostsState(
        status: PostsStatus.success,
        posts: posts,
        query: 'ALPHA',
      );

      expect(ids(state), [1, 3]);
    });

    test('автор и поиск работают вместе', () {
      final state = PostsState(
        status: PostsStatus.success,
        posts: posts,
        userId: 2,
        query: 'beta',
      );

      expect(ids(state), [2]);
    });

    test('сортировка по ID в обратную сторону', () {
      final state = PostsState(
        status: PostsStatus.success,
        posts: posts,
        ascending: false,
      );

      expect(ids(state), [3, 2, 1]);
    });

    test('если ничего не нашлось, экран получает статус «пусто»', () {
      final state = PostsState(
        status: PostsStatus.success,
        posts: posts,
        query: 'такого заголовка нет',
      );

      expect(state.displayStatus, PostsStatus.empty);
    });
  });
}