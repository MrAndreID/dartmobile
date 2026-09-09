import 'package:dart_mobile/features/user/data/models/user_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserDto.fromJson', () {
    test('parses a full record with nested emails', () {
      final dto = UserDto.fromJson({
        'id': 42,
        'name': 'Ada',
        'emails': [
          {'id': 1, 'email': 'ada@example.com'},
          {'id': 2, 'email': 'ada.work@example.com'},
        ],
        'createdAt': '2024-01-02T03:04:05Z',
      });

      final user = dto.toDomain();

      expect(user.id, '42');
      expect(user.name, 'Ada');
      expect(user.emails.map((e) => e.email), [
        'ada@example.com',
        'ada.work@example.com',
      ]);
      expect(user.createdAt, isNotNull);
    });

    test('tolerates missing/null fields', () {
      final dto = UserDto.fromJson({'id': null, 'name': null});
      final user = dto.toDomain();

      expect(user.id, '');
      expect(user.name, '');
      expect(user.emails, isEmpty);
      expect(user.createdAt, isNull);
      expect(user.emailSummary, 'No email');
    });
  });
}
