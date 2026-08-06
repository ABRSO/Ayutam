/// Global tag with case-insensitive uniqueness (display casing preserved).
final class Tag {
  const Tag({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.sourceDeviceId,
  });

  final String id;
  final String name;
  final String normalizedName;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final String sourceDeviceId;

  static String normalize(String raw) => raw.trim().toLowerCase();
}
