import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import 'posts_event.dart';
import 'posts_state.dart';
import 'posts_status.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  PostsBloc(this._repository) : super(const PostsState()) {
    on<PostsStarted>(_onStarted);
    on<PostsRefreshed>(_onRefreshed);
    on<PostsLoadMore>(_onLoadMore);
    on<PostsSearchChanged>(_onSearchChanged);
    on<PostsUserFilterChanged>(_onUserFilterChanged);
    on<PostsSortToggled>(_onSortToggled);
    on<PostsFiltersReset>(_onFiltersReset);
    on<PostsLocalPostAdded>(_onLocalPostAdded);
  }

  final PostRepository _repository;
  static const int pageSize = 10;

  // Номер «поколения» запросов. Когда меняется фильтр, номер растёт,
  // и ответы на старые запросы выбрасываются, а не смешиваются с новыми.
  int _requestId = 0;

  // ---------- Обработчики событий ----------

  Future<void> _onStarted(
    PostsStarted event,
    Emitter<PostsState> emit,
  ) async {
    await Future.wait([_loadInitial(emit), _loadUsers(emit)]);
  }

  Future<void> _onRefreshed(
    PostsRefreshed event,
    Emitter<PostsState> emit,
  ) {
    return _loadInitial(emit);
  }

  Future<void> _onLoadMore(
    PostsLoadMore event,
    Emitter<PostsState> emit,
  ) async {
    // Защита от повторной загрузки одной и той же страницы.
    if (state.isLoadingMore || !state.hasMore || state.isUpdating) return;
    if (state.status != PostsStatus.success) return;

    final requestId = _requestId;
    final nextPage = state.page + 1;
    emit(state.copyWith(isLoadingMore: true, clearLoadMoreError: true));

    try {
      final next = await _fetchPage(nextPage);
      if (requestId != _requestId) return;
      final knownIds = state.posts.map((p) => p.id).toSet();
      final fresh = next.where((p) => !knownIds.contains(p.id)).toList();
      emit(state.copyWith(
        posts: [...state.posts, ...fresh],
        page: nextPage,
        hasMore: next.length == pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      if (requestId != _requestId) return;
      emit(state.copyWith(
        loadMoreError: _messageOf(e),
        isLoadingMore: false,
      ));
    }
  }

  /// Поиск работает только по уже загруженным постам.
  void _onSearchChanged(
    PostsSearchChanged event,
    Emitter<PostsState> emit,
  ) {
    emit(state.copyWith(query: event.query));
  }

  Future<void> _onUserFilterChanged(
    PostsUserFilterChanged event,
    Emitter<PostsState> emit,
  ) async {
    if (state.userId == event.userId) return;
    // Старые результаты убираем сразу, чтобы они не смешивались с новыми.
    emit(state.copyWith(
      userId: event.userId,
      clearUserId: event.userId == null,
      posts: const <Post>[],
    ));
    await _loadInitial(emit);
  }

  void _onSortToggled(PostsSortToggled event, Emitter<PostsState> emit) {
    emit(state.copyWith(ascending: !state.ascending));
  }

  Future<void> _onFiltersReset(
    PostsFiltersReset event,
    Emitter<PostsState> emit,
  ) async {
    final hadUser = state.userId != null;
    emit(state.copyWith(
      query: '',
      ascending: true,
      clearUserId: true,
      posts: hadUser ? const <Post>[] : null,
    ));
    if (hadUser) await _loadInitial(emit);
  }

  /// Добавляет созданный пост в локальный список (сервер его не хранит).
  void _onLocalPostAdded(
    PostsLocalPostAdded event,
    Emitter<PostsState> emit,
  ) {
    emit(state.copyWith(localPosts: [event.post, ...state.localPosts]));
  }

  // ---------- Вспомогательные методы ----------

  /// Первая загрузка и обновление. Сначала показываем кэш, потом сервер.
  Future<void> _loadInitial(Emitter<PostsState> emit) async {
    final requestId = ++_requestId;
    emit(state.copyWith(
      page: 0,
      hasMore: true,
      isLoadingMore: false,
      clearLoadMoreError: true,
      clearErrorMessage: true,
      isUpdating: true,
    ));

    if (state.posts.isEmpty) {
      emit(state.copyWith(status: PostsStatus.loading));
      if (state.userId == null) {
        final cached = await _repository.getCachedPosts();
        if (requestId != _requestId) return;
        if (cached.isNotEmpty) {
          emit(state.copyWith(posts: cached, status: PostsStatus.cached));
        }
      }
    }

    try {
      final fresh = await _fetchPage(1);
      if (requestId != _requestId) return;
      emit(state.copyWith(
        posts: fresh,
        page: 1,
        hasMore: state.userId == null && fresh.length == pageSize,
        status: PostsStatus.success,
        isUpdating: false,
      ));
    } catch (e) {
      if (requestId != _requestId) return;
      // Старые данные не стираем: если они есть, это режим «кэш».
      emit(state.copyWith(
        errorMessage: _messageOf(e),
        status: state.posts.isNotEmpty ? PostsStatus.cached : PostsStatus.error,
        isUpdating: false,
      ));
    }
  }

  Future<void> _loadUsers(Emitter<PostsState> emit) async {
    try {
      final users = await _repository.getUsers();
      emit(state.copyWith(users: users));
    } catch (_) {
      // Список авторов не критичен: без него фильтр просто пустой.
    }
  }

  Future<List<Post>> _fetchPage(int page) {
    final userId = state.userId;
    if (userId != null) {
      return _repository.getPostsByUser(userId);
    }
    return _repository.getPosts(page: page, limit: pageSize);
  }

  String _messageOf(Object e) =>
      e is AppException ? e.message : 'Произошла непредвиденная ошибка.';
}