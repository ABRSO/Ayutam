enum SkillStatus {
  active,
  archived;

  static SkillStatus parse(String value) => switch (value) {
    'archived' => SkillStatus.archived,
    _ => SkillStatus.active,
  };

  String get storageValue => name;
}

final class Skill {
  const Skill({
    required this.id,
    required this.name,
    required this.targetSeconds,
    required this.createdLocalDate,
    required this.status,
    required this.sortOrder,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.sourceDeviceId,
    this.descriptionMarkdown,
    this.accentArgb,
    this.deletedAtUtc,
    this.completedActiveSeconds = 0,
  });

  final String id;
  final String name;
  final String? descriptionMarkdown;
  final int targetSeconds;
  final String createdLocalDate;
  final int? accentArgb;
  final SkillStatus status;
  final int sortOrder;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final String sourceDeviceId;
  final DateTime? deletedAtUtc;

  /// Sum of completed sessions' active seconds (list UI helper).
  final int completedActiveSeconds;

  double get progressFraction {
    if (targetSeconds <= 0) {
      return 0;
    }
    final fraction = completedActiveSeconds / targetSeconds;
    if (fraction < 0) {
      return 0;
    }
    if (fraction > 1) {
      return 1;
    }
    return fraction;
  }

  Skill copyWith({
    String? name,
    String? descriptionMarkdown,
    int? targetSeconds,
    int? accentArgb,
    SkillStatus? status,
    int? sortOrder,
    DateTime? updatedAtUtc,
    int? completedActiveSeconds,
  }) {
    return Skill(
      id: id,
      name: name ?? this.name,
      descriptionMarkdown: descriptionMarkdown ?? this.descriptionMarkdown,
      targetSeconds: targetSeconds ?? this.targetSeconds,
      createdLocalDate: createdLocalDate,
      accentArgb: accentArgb ?? this.accentArgb,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAtUtc: createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      sourceDeviceId: sourceDeviceId,
      deletedAtUtc: deletedAtUtc,
      completedActiveSeconds:
          completedActiveSeconds ?? this.completedActiveSeconds,
    );
  }
}
