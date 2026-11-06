import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/dio_client.dart';
import 'data/local/post_cache.dart';
import 'data/remote/post_api.dart';
import 'data/repositories/post_repository.dart';
import 'presentation/screens/posts_screen.dart';
import 'presentation/state/posts_bloc.dart';
import 'presentation/state/posts_event.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Один DioClient на всё приложение, новый для каждого запроса не создаём.
  final dioClient = DioClient();
  final repository = PostRepository(PostApi(dioClient.dio), PostCache());

  runApp(
    // Репозиторий доступен всему приложению.
    RepositoryProvider<PostRepository>.value(
      value: repository,
      child: BlocProvider(
        // Создаём Bloc и сразу отправляем событие «экран открылся».
        create: (_) => PostsBloc(repository)..add(const PostsStarted()),
        child: const PostExplorerApp(),
      ),
    ),
  );
}

class PostExplorerApp extends StatelessWidget {
  const PostExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const PostsScreen(),
    );
  }
}