import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:proflower_lesson_2/data/models/post.dart';
import 'package:proflower_lesson_2/data/repositories/post_repository.dart';
import 'package:proflower_lesson_2/presentation/state/posts_bloc.dart';
import 'package:proflower_lesson_2/presentation/state/posts_event.dart';
import 'package:proflower_lesson_2/presentation/state/posts_status.dart';

class MockPostRepository extends Mock implements PostRepository {}

List<Post> _page(int from) => List.generate(
      10,
      (i) => Post(
        userId: 1,
        id: from + i,
        title: 'Пост ${from + i}',
        body: 'Текст поста ${from + i}',
      ),
    );

void main() {
  test('одна и та же страница не загружается дважды', () async {
    final repo = MockPostRepository();
    final secondPage = Completer<List<Post>>();

    when(() => repo.getCachedPosts()).thenAnswer((_) async => []);
    when(() => repo.getUsers()).thenAnswer((_) async => []);
    when(() => repo.getPosts(page: 1, limit: 10))
        .thenAnswer((_) async => _page(1));
    // Вторая страница «отвечает» только когда мы сами это разрешим.
    when(() => repo.getPosts(page: 2, limit: 10))
        .thenAnswer((_) => secondPage.future);

    final bloc = PostsBloc(repo)..add(const PostsStarted());
    await bloc.stream.firstWhere(
      (s) => s.status == PostsStatus.success && !s.isUpdating,
    );

    // Пользователь «дёргает» прокрутку три раза подряд.
    bloc
      ..add(const PostsLoadMore())
      ..add(const PostsLoadMore())
      ..add(const PostsLoadMore());
    await Future<void>.delayed(Duration.zero);

    secondPage.complete(_page(11));
    await bloc.stream.firstWhere((s) => !s.isLoadingMore);

    verify(() => repo.getPosts(page: 2, limit: 10)).called(1);
    expect(bloc.state.posts.length, 20);

    await bloc.close();
  });
}