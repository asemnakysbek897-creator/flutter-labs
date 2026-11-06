import 'package:equatable/equatable.dart';

import '../../data/models/post.dart';

abstract class PostsEvent extends Equatable {
  const PostsEvent();

  @override
  List<Object?> get props => [];
}

/// Экран открылся: загрузить посты и список авторов.
class PostsStarted extends PostsEvent {
  const PostsStarted();
}

/// Pull-to-refresh или кнопка «Повторить» после ошибки.
class PostsRefreshed extends PostsEvent {
  const PostsRefreshed();
}

/// Прокрутили список до конца: подгрузить следующую страницу.
class PostsLoadMore extends PostsEvent {
  const PostsLoadMore();
}

/// Изменили текст в поиске.
class PostsSearchChanged extends PostsEvent {
  final String query;

  const PostsSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Выбрали автора (null означает «все авторы»).
class PostsUserFilterChanged extends PostsEvent {
  final int? userId;

  const PostsUserFilterChanged(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Нажали на сортировку по ID.
class PostsSortToggled extends PostsEvent {
  const PostsSortToggled();
}

/// Нажали «Сбросить фильтры».
class PostsFiltersReset extends PostsEvent {
  const PostsFiltersReset();
}

/// Создан новый пост: добавить его в локальный список.
class PostsLocalPostAdded extends PostsEvent {
  final Post post;

  const PostsLocalPostAdded(this.post);

  @override
  List<Object?> get props => [post];
}