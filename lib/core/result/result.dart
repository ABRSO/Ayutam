/// Shared result type for application/domain boundaries.
library;

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    Failure() => null,
  };

  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) {
    return switch (this) {
      Success(:final value) => success(value),
      Failure(:final error) => failure(error),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AppFailure error;
}

/// Typed application failure with a stable diagnostic code.
final class AppFailure {
  const AppFailure({required this.code, required this.message, this.cause});

  /// Stable code family, e.g. `DB-OPEN`, `VAL-NAME`.
  final String code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'AppFailure($code): $message';
}
