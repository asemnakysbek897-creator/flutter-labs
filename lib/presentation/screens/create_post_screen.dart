import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../state/create_post_cubit.dart';
import '../state/posts_bloc.dart';
import '../state/posts_event.dart';
import '../state/posts_state.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => CreatePostCubit(ctx.read<PostRepository>()),
      child: const _CreatePostView(),
    );
  }
}

class _CreatePostView extends StatefulWidget {
  const _CreatePostView();

  @override
  State<_CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<_CreatePostView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  int? _userId;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    // Сначала проверяем поля, и только потом отправляем запрос.
    if (!_formKey.currentState!.validate()) return;
    context.read<CreatePostCubit>().submit(
          title: _titleController.text,
          body: _bodyController.text,
          userId: _userId!,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreatePostCubit, CreatePostState>(
      // Реагируем только на момент успеха: добавляем пост в локальный список.
      listenWhen: (prev, curr) =>
          prev.status != curr.status && curr.status == CreatePostStatus.success,
      listener: (context, state) {
        context
            .read<PostsBloc>()
            .add(PostsLocalPostAdded(state.createdPost!));
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Новый пост')),
          body: state.status == CreatePostStatus.success
              ? _buildSuccess(state.createdPost!)
              : _buildForm(state),
        );
      },
    );
  }

  Widget _buildForm(CreatePostState state) {
    final submitting = state.isSubmitting;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _titleController,
            enabled: !submitting,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Заголовок',
              helperText: 'От 5 до 100 символов',
              border: OutlineInputBorder(),
            ),
            validator: PostValidator.title,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bodyController,
            enabled: !submitting,
            maxLength: 1000,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Текст поста',
              helperText: 'От 10 до 1000 символов',
              border: OutlineInputBorder(),
            ),
            validator: PostValidator.body,
          ),
          const SizedBox(height: 12),
          BlocBuilder<PostsBloc, PostsState>(
            buildWhen: (prev, curr) => prev.users != curr.users,
            builder: (context, postsState) {
              return DropdownButtonFormField<int>(
                initialValue: _userId,
                decoration: const InputDecoration(
                  labelText: 'Автор',
                  border: OutlineInputBorder(),
                ),
                items: postsState.users
                    .map(
                      (u) => DropdownMenuItem<int>(
                        value: u.id,
                        child: Text(u.name),
                      ),
                    )
                    .toList(),
                onChanged: submitting
                    ? null
                    : (value) => setState(() => _userId = value),
                validator: PostValidator.userId,
              );
            },
          ),
          const SizedBox(height: 16),
          if (state.status == CreatePostStatus.failure)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                state.errorMessage ?? 'Не удалось отправить пост.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          // Пока идёт запрос, кнопка отключена: повторно нажать нельзя.
          FilledButton(
            onPressed: submitting ? null : _submit,
            child: submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    state.status == CreatePostStatus.failure
                        ? 'Повторить отправку'
                        : 'Отправить',
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(Post created) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
        const SizedBox(height: 12),
        Text(
          'Сервер принял пост',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ответ сервера',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('id: ${created.id}'),
                Text('userId: ${created.userId}'),
                Text('title: ${created.title}'),
                Text('body: ${created.body}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Тестовый сервер не сохраняет посты. Поэтому пост добавлен '
          'только в локальный список с пометкой «создан локально».',
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('К списку постов'),
        ),
      ],
    );
  }
}