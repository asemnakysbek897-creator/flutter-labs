import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/comment.dart';
import '../../data/repositories/post_repository.dart';
import 'posts_status.dart';

class PostDetailsState extends Equatable {
  const PostDetailsState({
    this.status = PostsStatus.loading,
    this.comments = const [],
    this.errorMessage,
  });

  final PostsStatus status;
  final List<Comment> comments;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, comments, errorMessage];
}

class PostDetailsCubit extends Cubit<PostDetailsState> {
  PostDetailsCubit(this._repository, this._postId)
      : super(const PostDetailsState());

  final PostRepository _repository;
  final int _postId;

  /// Загружает комментарии к посту. Вызывается и по кнопке «Повторить».
  Future<void> load() async {
    emit(const PostDetailsState());
    try {
      final comments = await _repository.getPostComments(_postId);
      if (isClosed) return; // пользователь уже ушёл с экрана
      emit(PostDetailsState(
        status: comments.isEmpty ? PostsStatus.empty : PostsStatus.success,
        comments: comments,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(PostDetailsState(
        status: PostsStatus.error,
        errorMessage:
            e is AppException ? e.message : 'Произошла непредвиденная ошибка.',
      ));
    }
  }
}