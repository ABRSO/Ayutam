import 'package:uuid/uuid.dart';

/// Generates UUID v4 strings for entity and device IDs.
abstract class IdGenerator {
  String v4();
}

final class UuidIdGenerator implements IdGenerator {
  const UuidIdGenerator([this._uuid = const Uuid()]);

  final Uuid _uuid;

  @override
  String v4() => _uuid.v4();
}
