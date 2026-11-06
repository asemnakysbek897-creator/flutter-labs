import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/post.dart';
import '../state/posts_bloc.dart';
import '../state/posts_event.dart';
import '../state/posts_state.dart';
import '../state/posts_status.dart';
import 'create_post_screen.dart';
import 'post_details_screen.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final _scroll = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final nearBottom =
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 200;
    if (nearBottom) {
      context.read<PostsBloc>().add(const PostsLoadMore());
    }
  }

  /// Pull-to-refresh: отправляем событие и ждём, пока обновление закончится.
  Future<void> _refresh() async {
    final bloc = context.read<PostsBloc>();
    bloc.add(const PostsRefreshed());
    await bloc.stream.firstWhere((s) => !s.isUpdating);
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PostsBloc>();

    return BlocBuilder<PostsBloc, PostsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Post Explorer'),
            actions: [
              IconButton(
                tooltip: state.ascending
                    ? 'Сначала старые (по ID)'
                    : 'Сначала новые (по ID)',
                icon: Icon(
                  state.ascending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                onPressed: () => bloc.add(const PostsSortToggled()),
              ),
              IconButton(
                tooltip: 'Сбросить фильтры',
                icon: const Icon(Icons.filter_alt_off),
                onPressed: () {
                  _searchController.clear();
                  bloc.add(const PostsFiltersReset());
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreatePostScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Новый пост'),
          ),
          body: Column(
            children: [
              _buildFilters(state, bloc),
              if (state.displayStatus == PostsStatus.cached)
                _buildCachedBanner(state),
              Expanded(child: _buildBody(state, bloc)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters(PostsState state, PostsBloc bloc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => bloc.add(PostsSearchChanged(value)),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Поиск по заголовку',
              helperText: 'Поиск идёт только среди уже загруженных постов',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Автор: '),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<int?>(
                  isExpanded: true,
                  value: state.userId,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Все авторы'),
                    ),
                    ...state.users.map(
                      (u) => DropdownMenuItem<int?>(
                        value: u.id,
                        child: Text(u.name),
                      ),
                    ),
                  ],
                  onChanged: (id) => bloc.add(PostsUserFilterChanged(id)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCachedBanner(PostsState state) {
    final text = state.isUpdating
        ? 'Показаны сохранённые данные, идёт обновление…'
        : (state.errorMessage ?? 'Показаны сохранённые данные');
    return Container(
      width: double.infinity,
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildBody(PostsState state, PostsBloc bloc) {
    switch (state.displayStatus) {
      case PostsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case PostsStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  state.errorMessage ?? 'Не удалось загрузить посты.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => bloc.add(const PostsRefreshed()),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        );
      case PostsStatus.empty:
        return const Center(child: Text('Постов не найдено'));
      case PostsStatus.success:
      case PostsStatus.cached:
        return _buildList(state, bloc);
    }
  }

  Widget _buildList(PostsState state, PostsBloc bloc) {
    final posts = state.visiblePosts;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: posts.length + 1,
        itemBuilder: (context, index) {
          if (index == posts.length) return _buildFooter(state, bloc);
          final Post post = posts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(child: Text('${post.id ?? '–'}')),
              title: Text(
                post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                post.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PostDetailsScreen(
                    post: post,
                    isLocal: state.isLocal(post),
                  ),
                ),
              ),
              trailing: state.isLocal(post)
                  ? const Chip(label: Text('создан локально'))
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(PostsState state, PostsBloc bloc) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(state.loadMoreError!, textAlign: TextAlign.center),
            TextButton(
              onPressed: () => bloc.add(const PostsLoadMore()),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    return const SizedBox(height: 16);
  }
}