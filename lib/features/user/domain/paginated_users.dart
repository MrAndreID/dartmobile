import 'package:equatable/equatable.dart';

import 'user.dart';

/// A page of users returned by the list endpoint.
///
/// Maps the goapi `{records, total, nextPage}` paginator response into a
/// domain-friendly shape.
class PaginatedUsers extends Equatable {
  const PaginatedUsers({
    required this.users,
    required this.total,
    required this.hasNextPage,
  });

  final List<User> users;
  final int total;
  final bool hasNextPage;

  @override
  List<Object?> get props => [users, total, hasNextPage];
}
