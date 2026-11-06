import 'package:flutter_test/flutter_test.dart';
import 'package:proflower_lesson_2/data/models/post.dart';

void main() {
  group('Post JSON', () {
    test('JSON с сервера превращается в Post', () {
      final json = {
        'userId': 1,
        'id': 7,
        'title': 'Заголовок',
        'body': 'Текст поста',
      };

      final post = Post.fromJson(json);

      expect(post.userId, 1);
      expect(post.id, 7);
      expect(post.title, 'Заголовок');
      expect(post.body, 'Текст поста');
    });

    test('Post превращается обратно в JSON', () {
      final post = Post(
        userId: 2,
        id: 5,
        title: 'Заголовок',
        body: 'Текст поста',
      );

      expect(post.toJson(), {
        'userId': 2,
        'id': 5,
        'title': 'Заголовок',
        'body': 'Текст поста',
      });
    });

    test('у нового поста без id поле id не уходит на сервер', () {
      final post = Post(userId: 1, title: 'Новый', body: 'Текст нового поста');

      expect(post.toJson().containsKey('id'), isFalse);
    });

    test('в ответе нет обязательного поля: ошибка, а не молчаливый сбой', () {
      final broken = {'userId': 1, 'id': 1};

      expect(() => Post.fromJson(broken), throwsA(isA<TypeError>()));
    });
  });
}