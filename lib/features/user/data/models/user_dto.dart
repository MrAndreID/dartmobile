import '../../domain/user.dart';
import '../../domain/user_email.dart';

/// Data Transfer Objects for the user feature.
///
/// DTOs own all JSON (de)serialization and know the exact shape returned by
/// goapi. They convert to/from the pure domain entities so serialization
/// details never leak into the rest of the app.

class UserEmailDto {
  const UserEmailDto({required this.id, required this.email});

  final String id;
  final String email;

  factory UserEmailDto.fromJson(Map<String, dynamic> json) {
    return UserEmailDto(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  UserEmail toDomain() => UserEmail(id: id, email: email);
}

class UserDto {
  const UserDto({
    required this.id,
    required this.name,
    required this.emails,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final List<UserEmailDto> emails;
  final String? createdAt;
  final String? updatedAt;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    final rawEmails = json['emails'];
    final emails = rawEmails is List
        ? rawEmails
            .whereType<Map<String, dynamic>>()
            .map(UserEmailDto.fromJson)
            .toList()
        : <UserEmailDto>[];

    return UserDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      emails: emails,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  User toDomain() {
    return User(
      id: id,
      name: name,
      emails: emails.map((e) => e.toDomain()).toList(),
      createdAt: DateTime.tryParse(createdAt ?? ''),
      updatedAt: DateTime.tryParse(updatedAt ?? ''),
    );
  }
}
