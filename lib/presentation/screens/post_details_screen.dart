import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../state/post_details_cubit.dart';
import '../state/posts_status.dart';

class PostDetailsScreen extends StatelessWidget {
  const PostDetailsScreen({
    super.key,
    required this.post,
    this.isLocal = false,
  });

  final Post post;
  final bool isLocal;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Cubit создаётся при открытии экрана и сразу загружает комментарии.
      create: (ctx) => PostDetailsCubit(
        ctx.read<PostRepository>(),
        post.id ?? 0,
      )..load(),
      child: Scaffold(
        appBar: AppBar(title: Text('Пост № ${post.id ?? '–'}')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isLocal)
              const Align(
                alignment: Alignment.centerLeft,
                child: Chip(label: Text('создан локально')),
              ),
            Text(
              post.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(post.body),
            const SizedBox(height: 8),
            Text(
              'Автор: пользователь № ${post.userId}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 32),
            Text(
              'Комментарии',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const _CommentsSection(),
          ],
        ),
      ),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostDetailsCubit, PostDetailsState>(
      builder: (context, state) {
        switch (state.status) {
          case PostsStatus.loading:
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          case PostsStatus.error:
            return Column(
              children: [
                Text(
                  state.errorMessage ?? 'Не удалось загрузить комментарии.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => context.read<PostDetailsCubit>().load(),
                  child: const Text('Повторить'),
                ),
              ],
            );
          case PostsStatus.empty:
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Комментариев пока нет'),
            );
          case PostsStatus.success:
          case PostsStatus.cached:
            return Column(
              children: [
                for (final comment in state.comments)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            comment.email,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Text(comment.body),
                        ],
                      ),
                    ),
                  ),
              ],
            );
        }
      },
    );
  }
}