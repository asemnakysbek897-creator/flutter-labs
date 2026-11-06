import 'package:equatable/equatable.dart';

import '../../data/models/post.dart';
import '../../data/models/user.dart';
import 'posts_status.dart';

class PostsState extends Equatable {
  const PostsState({
    this.status = PostsStatus.loading,
    this.posts = const [],
    this.localPosts = const [],
    this.users = const [],
    this.page = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isUpdating = false,
    this.errorMessage,
    this.loadMoreError,
    this.userId,
    this.query = '',
    this.ascending = true,
  });

  final PostsStatus status;
  final List<Post> posts;
  final List<Post> localPosts;
  final List<User> users;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isUpdating;
  final String? errorMessage;
  final String? loadMoreError;
  final int? userId;
  final String query;
  final bool ascending;

  /// Статус для экрана: если данные есть, но после фильтров ничего
  /// не осталось, показываем «Пусто».
  PostsStatus get displayStatus {
    final hasData =
        status == PostsStatus.success || status == PostsStatus.cached;
    if (hasData && visiblePosts.isEmpty) return PostsStatus.empty;
    return status;
  }

  bool isLocal(Post post) => localPosts.contains(post);

  /// Посты с учётом поиска, фильтра по автору и сортировки по ID.
  List<Post> get visiblePosts {
    Iterable<Post> list = [...localPosts, ...posts];
    if (userId != null) {
      list = list.where((p) => p.userId == userId);
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) => p.title.toLowerCase().contains(q));
    }
    final result = list.toList()
      ..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    return ascending ? result : result.reversed.toList();
  }

  /// Создаёт копию состояния с изменёнными полями.
  /// Флаги clear... нужны, чтобы можно было сбросить поле в null.
  PostsState copyWith({
    PostsStatus? status,
    List<Post>? posts,
    List<Post>? localPosts,
    List<User>? users,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isUpdating,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    int? userId,
    bool clearUserId = false,
    String? query,
    bool? ascending,
  }) {
    return PostsState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      localPosts: localPosts ?? this.localPosts,
      users: users ?? this.users,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
      userId: clearUserId ? null : (userId ?? this.userId),
      query: query ?? this.query,
      ascending: ascending ?? this.ascending,
    );
  }

  @override
  List<Object?> get props => [
        status,
        posts,
        localPosts,
        users,
        page,
        hasMore,
        isLoadingMore,
        isUpdating,
        errorMessage,
        loadMoreError,
        userId,
        query,
        ascending,
      ];
}