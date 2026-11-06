import 'dart:convert';   // Импорт библиотеки для работы с кодированием и декодированием JSON

import 'package:shared_preferences/shared_preferences.dart';   // Импорт пакета для сохранения данных в локальное хранилище (ключ-значение)

import '../models/post.dart';   // Импорт модели данных Post (посты)

class PostCache {   // Класс для управления локальным кэшированием постов на устройстве
  static const _key = 'cached_posts';   // Ключ, под которым данные постов будут храниться в памяти

  /// Сохраняет список постов на устройстве.
  Future<void> savePosts(List<Post> posts) async {   // Асинхронный метод для сохранения списка постов
    final prefs = await SharedPreferences.getInstance();   // Получение экземпляра SharedPreferences
    final json = jsonEncode(posts.map((p) => p.toJson()).toList());   // Преобразование списка объектов Post в JSON-строку
    await prefs.setString(_key, json);   // Сохранение JSON-строки в локальное хранилище под ключом
  }

  /// Возвращает сохранённые посты или пустой список, если кэша нет.
  Future<List<Post>> loadPosts() async {   // Асинхронный метод для загрузки кэшированных постов
    final prefs = await SharedPreferences.getInstance();   // Получение экземпляра SharedPreferences
    final raw = prefs.getString(_key);   // Чтение сохраненной JSON-строки по ключу
    if (raw == null) return [];   // Если данных в кэше нет (null), возвращаем пустой список
    try {
      final list = jsonDecode(raw) as List<dynamic>;   // Декодирование JSON-строки обратно в динамический список
      return list
          .map((e) => Post.fromJson(e as Map<String, dynamic>))   // Преобразование каждого элемента в объект Post
          .toList();   // Возвращение готового списка объектов Post
    } catch (_) {
      // Если кэш повреждён, приложение не падает, а просто начинает с нуля.
      return [];   // В случае ошибки парсинга возвращаем пустой список, чтобы приложение не зависло
    } 
  }
}