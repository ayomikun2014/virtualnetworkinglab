/// VirtuaNetLab Domain Failure Classes
///
/// Wraps raw Firebase, network, and validation exceptions into clean,
/// human-readable failure objects for the UI layer.
abstract class Failure implements Exception {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure: $message (code: $code)';
}

/// Authentication or Authorization Failure
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// Backend Database or Storage Server Failure
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Input Validation or Constraint Violation Failure
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Network Connectivity or Offline Failure
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}
