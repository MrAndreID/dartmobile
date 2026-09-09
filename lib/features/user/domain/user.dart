import 'package:equatable/equatable.dart';

import 'user_email.dart';

/// A user as understood by the application.
///
/// Mirrors the goapi `User` resource but exposes only the fields the UI needs.
class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.emails,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final List<UserEmail> emails;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Convenience accessor for showing the addresses inline in a list.
  String get emailSummary =>
      emails.isEmpty ? 'No email' : emails.map((e) => e.email).join(', ');

  @override
  List<Object?> get props => [id, name, emails, createdAt, updatedAt];
}
