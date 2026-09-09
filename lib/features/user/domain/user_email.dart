import 'package:equatable/equatable.dart';

/// A single email address belonging to a [User].
///
/// This is a domain entity: it holds only what the app cares about and is free
/// of any serialization concerns (those live in the data layer DTOs).
class UserEmail extends Equatable {
  const UserEmail({
    required this.id,
    required this.email,
  });

  final String id;
  final String email;

  @override
  List<Object?> get props => [id, email];
}
