import 'package:equatable/equatable.dart';

/// A domain-level error surfaced to the presentation layer.
///
/// Data sources throw low-level exceptions (Dio errors, parsing errors);
/// repositories translate those into a [Failure] so the UI can render a
/// friendly message without knowing about transport details.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

/// The server responded with a non-success status or an error envelope.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.code});

  /// The `code` field from the goapi response envelope, when available.
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

/// A connectivity problem: timeout, no network, DNS failure, etc.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

/// The response could not be parsed into the expected shape.
class ParsingFailure extends Failure {
  const ParsingFailure([super.message = 'Unexpected response from server.']);
}

/// Any error that does not fit the categories above.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
