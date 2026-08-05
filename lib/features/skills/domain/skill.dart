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

  /// May exceed 1.0 when practice is past the target ([product-spec] Progress).
  double get progressFraction {
    if (targetSeconds <= 0) {
      return 0;
    }
    final fraction = completedActiveSeconds / targetSeconds;
    return fraction < 0 ? 0 : fraction;
  }

  /// Clamped 0..1 for [LinearProgressIndicator] (Material requires ≤ 1).
  double get progressBarValue {
    final fraction = progressFraction;
    if (fraction > 1) {
      return 1;
    }
    return fraction;
  }

  /// Rounded percent; may exceed 100 when past target.
  int get progressPercent => (progressFraction * 100).round();

  /// Remaining seconds to target, clamped ≥ 0 when past target.
  int get remainingSeconds {
    final remaining = targetSeconds - completedActiveSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  Skill copyWith({
    String? name,
    String? descriptionMarkdown,
    bool clearDescription = false,
    int? targetSeconds,
    String? createdLocalDate,
    int? accentArgb,
    SkillStatus? status,
    int? sortOrder,
    DateTime? updatedAtUtc,
    int? completedActiveSeconds,
  }) {
    return Skill(
      id: id,
      name: name ?? this.name,
      descriptionMarkdown: clearDescription
          ? null
          : (descriptionMarkdown ?? this.descriptionMarkdown),
      targetSeconds: targetSeconds ?? this.targetSeconds,
      createdLocalDate: createdLocalDate ?? this.createdLocalDate,
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
