import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';

/// Состояния отправки формы. Они не зависят от состояний списка:
/// форма и список живут независимо друг от друга.
enum CreatePostStatus { idle, submitting, success, failure }

class CreatePostState extends Equatable {
  const CreatePostState({
    this.status = CreatePostStatus.idle,
    this.createdPost,
    this.errorMessage,
  });

  final CreatePostStatus status;
  final Post? createdPost;
  final String? errorMessage;

  bool get isSubmitting => status == CreatePostStatus.submitting;

  @override
  List<Object?> get props => [status, createdPost, errorMessage];
}

/// Проверка полей формы до отправки. Вынесена отдельно, чтобы её
/// можно было проверить тестом без запуска приложения.
class PostValidator {
  static String? title(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Введите заголовок';
    if (text.length < 5) return 'Заголовок: минимум 5 символов';
    if (text.length > 100) return 'Заголовок: максимум 100 символов';
    return null;
  }

  static String? body(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Введите текст поста';
    if (text.length < 10) return 'Текст: минимум 10 символов';
    if (text.length > 1000) return 'Текст: максимум 1000 символов';
    return null;
  }

  static String? userId(int? value) {
    if (value == null) return 'Выберите автора';
    return null;
  }
}

class CreatePostCubit extends Cubit<CreatePostState> {
  CreatePostCubit(this._repository) : super(const CreatePostState());

  final PostRepository _repository;

  /// Отправляет пост на сервер (POST через Retrofit).
  Future<void> submit({
    required String title,
    required String body,
    required int userId,
  }) async {
    // Защита от повторного нажатия, пока запрос ещё идёт.
    if (state.isSubmitting) return;

    emit(const CreatePostState(status: CreatePostStatus.submitting));
    try {
      final created = await _repository.createPost(
        Post(userId: userId, title: title.trim(), body: body.trim()),
      );
      if (isClosed) return;
      emit(CreatePostState(
        status: CreatePostStatus.success,
        createdPost: created,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(CreatePostState(
        status: CreatePostStatus.failure,
        errorMessage:
            e is AppException ? e.message : 'Произошла непредвиденная ошибка.',
      ));
    }
  }
}