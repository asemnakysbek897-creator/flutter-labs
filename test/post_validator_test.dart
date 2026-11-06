import 'package:flutter_test/flutter_test.dart';
import 'package:proflower_lesson_2/presentation/state/create_post_cubit.dart';

void main() {
  group('Проверка формы создания поста', () {
    test('заголовок: пустой, короткий, длинный и верный', () {
      expect(PostValidator.title(''), isNotNull);
      expect(PostValidator.title('abcd'), isNotNull);
      expect(PostValidator.title('a' * 101), isNotNull);
      expect(PostValidator.title('abcde'), isNull);
      expect(PostValidator.title('a' * 100), isNull);
    });

    test('текст: пустой, короткий, длинный и верный', () {
      expect(PostValidator.body(''), isNotNull);
      expect(PostValidator.body('a' * 9), isNotNull);
      expect(PostValidator.body('a' * 1001), isNotNull);
      expect(PostValidator.body('a' * 10), isNull);
      expect(PostValidator.body('a' * 1000), isNull);
    });

    test('автор обязателен', () {
      expect(PostValidator.userId(null), isNotNull);
      expect(PostValidator.userId(3), isNull);
    });
  });
}