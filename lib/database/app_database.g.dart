// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SkillsTable extends Skills with TableInfo<$SkillsTable, Skill> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SkillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMarkdownMeta =
      const VerificationMeta('descriptionMarkdown');
  @override
  late final GeneratedColumn<String> descriptionMarkdown =
      GeneratedColumn<String>(
        'description_markdown',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _targetSecondsMeta = const VerificationMeta(
    'targetSeconds',
  );
  @override
  late final GeneratedColumn<int> targetSeconds = GeneratedColumn<int>(
    'target_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(36000000),
  );
  static const VerificationMeta _createdLocalDateMeta = const VerificationMeta(
    'createdLocalDate',
  );
  @override
  late final GeneratedColumn<String> createdLocalDate = GeneratedColumn<String>(
    'created_local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accentArgbMeta = const VerificationMeta(
    'accentArgb',
  );
  @override
  late final GeneratedColumn<int> accentArgb = GeneratedColumn<int>(
    'accent_argb',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<int> createdAtUtc = GeneratedColumn<int>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtc = GeneratedColumn<int>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceDeviceIdMeta = const VerificationMeta(
    'sourceDeviceId',
  );
  @override
  late final GeneratedColumn<String> sourceDeviceId = GeneratedColumn<String>(
    'source_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtUtcMeta = const VerificationMeta(
    'deletedAtUtc',
  );
  @override
  late final GeneratedColumn<int> deletedAtUtc = GeneratedColumn<int>(
    'deleted_at_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    descriptionMarkdown,
    targetSeconds,
    createdLocalDate,
    accentArgb,
    status,
    sortOrder,
    createdAtUtc,
    updatedAtUtc,
    sourceDeviceId,
    deletedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'skills';
  @override
  VerificationContext validateIntegrity(
    Insertable<Skill> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description_markdown')) {
      context.handle(
        _descriptionMarkdownMeta,
        descriptionMarkdown.isAcceptableOrUnknown(
          data['description_markdown']!,
          _descriptionMarkdownMeta,
        ),
      );
    }
    if (data.containsKey('target_seconds')) {
      context.handle(
        _targetSecondsMeta,
        targetSeconds.isAcceptableOrUnknown(
          data['target_seconds']!,
          _targetSecondsMeta,
        ),
      );
    }
    if (data.containsKey('created_local_date')) {
      context.handle(
        _createdLocalDateMeta,
        createdLocalDate.isAcceptableOrUnknown(
          data['created_local_date']!,
          _createdLocalDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdLocalDateMeta);
    }
    if (data.containsKey('accent_argb')) {
      context.handle(
        _accentArgbMeta,
        accentArgb.isAcceptableOrUnknown(data['accent_argb']!, _accentArgbMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    if (data.containsKey('source_device_id')) {
      context.handle(
        _sourceDeviceIdMeta,
        sourceDeviceId.isAcceptableOrUnknown(
          data['source_device_id']!,
          _sourceDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceDeviceIdMeta);
    }
    if (data.containsKey('deleted_at_utc')) {
      context.handle(
        _deletedAtUtcMeta,
        deletedAtUtc.isAcceptableOrUnknown(
          data['deleted_at_utc']!,
          _deletedAtUtcMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Skill map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Skill(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      descriptionMarkdown: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description_markdown'],
      ),
      targetSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_seconds'],
      )!,
      createdLocalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_local_date'],
      )!,
      accentArgb: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}accent_argb'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc'],
      )!,
      sourceDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_device_id'],
      )!,
      deletedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_utc'],
      ),
    );
  }

  @override
  $SkillsTable createAlias(String alias) {
    return $SkillsTable(attachedDatabase, alias);
  }
}

class Skill extends DataClass implements Insertable<Skill> {
  final String id;
  final String name;
  final String? descriptionMarkdown;
  final int targetSeconds;
  final String createdLocalDate;
  final int? accentArgb;
  final String status;
  final int sortOrder;
  final int createdAtUtc;
  final int updatedAtUtc;
  final String sourceDeviceId;
  final int? deletedAtUtc;
  const Skill({
    required this.id,
    required this.name,
    this.descriptionMarkdown,
    required this.targetSeconds,
    required this.createdLocalDate,
    this.accentArgb,
    required this.status,
    required this.sortOrder,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.sourceDeviceId,
    this.deletedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || descriptionMarkdown != null) {
      map['description_markdown'] = Variable<String>(descriptionMarkdown);
    }
    map['target_seconds'] = Variable<int>(targetSeconds);
    map['created_local_date'] = Variable<String>(createdLocalDate);
    if (!nullToAbsent || accentArgb != null) {
      map['accent_argb'] = Variable<int>(accentArgb);
    }
    map['status'] = Variable<String>(status);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at_utc'] = Variable<int>(createdAtUtc);
    map['updated_at_utc'] = Variable<int>(updatedAtUtc);
    map['source_device_id'] = Variable<String>(sourceDeviceId);
    if (!nullToAbsent || deletedAtUtc != null) {
      map['deleted_at_utc'] = Variable<int>(deletedAtUtc);
    }
    return map;
  }

  SkillsCompanion toCompanion(bool nullToAbsent) {
    return SkillsCompanion(
      id: Value(id),
      name: Value(name),
      descriptionMarkdown: descriptionMarkdown == null && nullToAbsent
          ? const Value.absent()
          : Value(descriptionMarkdown),
      targetSeconds: Value(targetSeconds),
      createdLocalDate: Value(createdLocalDate),
      accentArgb: accentArgb == null && nullToAbsent
          ? const Value.absent()
          : Value(accentArgb),
      status: Value(status),
      sortOrder: Value(sortOrder),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
      sourceDeviceId: Value(sourceDeviceId),
      deletedAtUtc: deletedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtUtc),
    );
  }

  factory Skill.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Skill(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      descriptionMarkdown: serializer.fromJson<String?>(
        json['descriptionMarkdown'],
      ),
      targetSeconds: serializer.fromJson<int>(json['targetSeconds']),
      createdLocalDate: serializer.fromJson<String>(json['createdLocalDate']),
      accentArgb: serializer.fromJson<int?>(json['accentArgb']),
      status: serializer.fromJson<String>(json['status']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAtUtc: serializer.fromJson<int>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<int>(json['updatedAtUtc']),
      sourceDeviceId: serializer.fromJson<String>(json['sourceDeviceId']),
      deletedAtUtc: serializer.fromJson<int?>(json['deletedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'descriptionMarkdown': serializer.toJson<String?>(descriptionMarkdown),
      'targetSeconds': serializer.toJson<int>(targetSeconds),
      'createdLocalDate': serializer.toJson<String>(createdLocalDate),
      'accentArgb': serializer.toJson<int?>(accentArgb),
      'status': serializer.toJson<String>(status),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAtUtc': serializer.toJson<int>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<int>(updatedAtUtc),
      'sourceDeviceId': serializer.toJson<String>(sourceDeviceId),
      'deletedAtUtc': serializer.toJson<int?>(deletedAtUtc),
    };
  }

  Skill copyWith({
    String? id,
    String? name,
    Value<String?> descriptionMarkdown = const Value.absent(),
    int? targetSeconds,
    String? createdLocalDate,
    Value<int?> accentArgb = const Value.absent(),
    String? status,
    int? sortOrder,
    int? createdAtUtc,
    int? updatedAtUtc,
    String? sourceDeviceId,
    Value<int?> deletedAtUtc = const Value.absent(),
  }) => Skill(
    id: id ?? this.id,
    name: name ?? this.name,
    descriptionMarkdown: descriptionMarkdown.present
        ? descriptionMarkdown.value
        : this.descriptionMarkdown,
    targetSeconds: targetSeconds ?? this.targetSeconds,
    createdLocalDate: createdLocalDate ?? this.createdLocalDate,
    accentArgb: accentArgb.present ? accentArgb.value : this.accentArgb,
    status: status ?? this.status,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
    deletedAtUtc: deletedAtUtc.present ? deletedAtUtc.value : this.deletedAtUtc,
  );
  Skill copyWithCompanion(SkillsCompanion data) {
    return Skill(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      descriptionMarkdown: data.descriptionMarkdown.present
          ? data.descriptionMarkdown.value
          : this.descriptionMarkdown,
      targetSeconds: data.targetSeconds.present
          ? data.targetSeconds.value
          : this.targetSeconds,
      createdLocalDate: data.createdLocalDate.present
          ? data.createdLocalDate.value
          : this.createdLocalDate,
      accentArgb: data.accentArgb.present
          ? data.accentArgb.value
          : this.accentArgb,
      status: data.status.present ? data.status.value : this.status,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
      sourceDeviceId: data.sourceDeviceId.present
          ? data.sourceDeviceId.value
          : this.sourceDeviceId,
      deletedAtUtc: data.deletedAtUtc.present
          ? data.deletedAtUtc.value
          : this.deletedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Skill(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('descriptionMarkdown: $descriptionMarkdown, ')
          ..write('targetSeconds: $targetSeconds, ')
          ..write('createdLocalDate: $createdLocalDate, ')
          ..write('accentArgb: $accentArgb, ')
          ..write('status: $status, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('sourceDeviceId: $sourceDeviceId, ')
          ..write('deletedAtUtc: $deletedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    descriptionMarkdown,
    targetSeconds,
    createdLocalDate,
    accentArgb,
    status,
    sortOrder,
    createdAtUtc,
    updatedAtUtc,
    sourceDeviceId,
    deletedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Skill &&
          other.id == this.id &&
          other.name == this.name &&
          other.descriptionMarkdown == this.descriptionMarkdown &&
          other.targetSeconds == this.targetSeconds &&
          other.createdLocalDate == this.createdLocalDate &&
          other.accentArgb == this.accentArgb &&
          other.status == this.status &&
          other.sortOrder == this.sortOrder &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc &&
          other.sourceDeviceId == this.sourceDeviceId &&
          other.deletedAtUtc == this.deletedAtUtc);
}

class SkillsCompanion extends UpdateCompanion<Skill> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> descriptionMarkdown;
  final Value<int> targetSeconds;
  final Value<String> createdLocalDate;
  final Value<int?> accentArgb;
  final Value<String> status;
  final Value<int> sortOrder;
  final Value<int> createdAtUtc;
  final Value<int> updatedAtUtc;
  final Value<String> sourceDeviceId;
  final Value<int?> deletedAtUtc;
  final Value<int> rowid;
  const SkillsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.descriptionMarkdown = const Value.absent(),
    this.targetSeconds = const Value.absent(),
    this.createdLocalDate = const Value.absent(),
    this.accentArgb = const Value.absent(),
    this.status = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.sourceDeviceId = const Value.absent(),
    this.deletedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SkillsCompanion.insert({
    required String id,
    required String name,
    this.descriptionMarkdown = const Value.absent(),
    this.targetSeconds = const Value.absent(),
    required String createdLocalDate,
    this.accentArgb = const Value.absent(),
    this.status = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAtUtc,
    required int updatedAtUtc,
    required String sourceDeviceId,
    this.deletedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdLocalDate = Value(createdLocalDate),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc),
       sourceDeviceId = Value(sourceDeviceId);
  static Insertable<Skill> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? descriptionMarkdown,
    Expression<int>? targetSeconds,
    Expression<String>? createdLocalDate,
    Expression<int>? accentArgb,
    Expression<String>? status,
    Expression<int>? sortOrder,
    Expression<int>? createdAtUtc,
    Expression<int>? updatedAtUtc,
    Expression<String>? sourceDeviceId,
    Expression<int>? deletedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (descriptionMarkdown != null)
        'description_markdown': descriptionMarkdown,
      if (targetSeconds != null) 'target_seconds': targetSeconds,
      if (createdLocalDate != null) 'created_local_date': createdLocalDate,
      if (accentArgb != null) 'accent_argb': accentArgb,
      if (status != null) 'status': status,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (sourceDeviceId != null) 'source_device_id': sourceDeviceId,
      if (deletedAtUtc != null) 'deleted_at_utc': deletedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SkillsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? descriptionMarkdown,
    Value<int>? targetSeconds,
    Value<String>? createdLocalDate,
    Value<int?>? accentArgb,
    Value<String>? status,
    Value<int>? sortOrder,
    Value<int>? createdAtUtc,
    Value<int>? updatedAtUtc,
    Value<String>? sourceDeviceId,
    Value<int?>? deletedAtUtc,
    Value<int>? rowid,
  }) {
    return SkillsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      descriptionMarkdown: descriptionMarkdown ?? this.descriptionMarkdown,
      targetSeconds: targetSeconds ?? this.targetSeconds,
      createdLocalDate: createdLocalDate ?? this.createdLocalDate,
      accentArgb: accentArgb ?? this.accentArgb,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      deletedAtUtc: deletedAtUtc ?? this.deletedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (descriptionMarkdown.present) {
      map['description_markdown'] = Variable<String>(descriptionMarkdown.value);
    }
    if (targetSeconds.present) {
      map['target_seconds'] = Variable<int>(targetSeconds.value);
    }
    if (createdLocalDate.present) {
      map['created_local_date'] = Variable<String>(createdLocalDate.value);
    }
    if (accentArgb.present) {
      map['accent_argb'] = Variable<int>(accentArgb.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<int>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<int>(updatedAtUtc.value);
    }
    if (sourceDeviceId.present) {
      map['source_device_id'] = Variable<String>(sourceDeviceId.value);
    }
    if (deletedAtUtc.present) {
      map['deleted_at_utc'] = Variable<int>(deletedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SkillsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('descriptionMarkdown: $descriptionMarkdown, ')
          ..write('targetSeconds: $targetSeconds, ')
          ..write('createdLocalDate: $createdLocalDate, ')
          ..write('accentArgb: $accentArgb, ')
          ..write('status: $status, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('sourceDeviceId: $sourceDeviceId, ')
          ..write('deletedAtUtc: $deletedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skillIdMeta = const VerificationMeta(
    'skillId',
  );
  @override
  late final GeneratedColumn<String> skillId = GeneratedColumn<String>(
    'skill_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES skills (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMarkdownMeta = const VerificationMeta(
    'noteMarkdown',
  );
  @override
  late final GeneratedColumn<String> noteMarkdown = GeneratedColumn<String>(
    'note_markdown',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('stopwatch'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('timer'),
  );
  static const VerificationMeta _startAtUtcMeta = const VerificationMeta(
    'startAtUtc',
  );
  @override
  late final GeneratedColumn<int> startAtUtc = GeneratedColumn<int>(
    'start_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtUtcMeta = const VerificationMeta(
    'endAtUtc',
  );
  @override
  late final GeneratedColumn<int> endAtUtc = GeneratedColumn<int>(
    'end_at_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeSecondsMeta = const VerificationMeta(
    'activeSeconds',
  );
  @override
  late final GeneratedColumn<int> activeSeconds = GeneratedColumn<int>(
    'active_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pausedSecondsMeta = const VerificationMeta(
    'pausedSeconds',
  );
  @override
  late final GeneratedColumn<int> pausedSeconds = GeneratedColumn<int>(
    'paused_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _timezoneIdAtCreationMeta =
      const VerificationMeta('timezoneIdAtCreation');
  @override
  late final GeneratedColumn<String> timezoneIdAtCreation =
      GeneratedColumn<String>(
        'timezone_id_at_creation',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _offsetMinutesAtStartMeta =
      const VerificationMeta('offsetMinutesAtStart');
  @override
  late final GeneratedColumn<int> offsetMinutesAtStart = GeneratedColumn<int>(
    'offset_minutes_at_start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<int> createdAtUtc = GeneratedColumn<int>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtc = GeneratedColumn<int>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceDeviceIdMeta = const VerificationMeta(
    'sourceDeviceId',
  );
  @override
  late final GeneratedColumn<String> sourceDeviceId = GeneratedColumn<String>(
    'source_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtUtcMeta = const VerificationMeta(
    'deletedAtUtc',
  );
  @override
  late final GeneratedColumn<int> deletedAtUtc = GeneratedColumn<int>(
    'deleted_at_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    skillId,
    title,
    noteMarkdown,
    mode,
    status,
    source,
    startAtUtc,
    endAtUtc,
    activeSeconds,
    pausedSeconds,
    timezoneIdAtCreation,
    offsetMinutesAtStart,
    createdAtUtc,
    updatedAtUtc,
    sourceDeviceId,
    deletedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('skill_id')) {
      context.handle(
        _skillIdMeta,
        skillId.isAcceptableOrUnknown(data['skill_id']!, _skillIdMeta),
      );
    } else if (isInserting) {
      context.missing(_skillIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('note_markdown')) {
      context.handle(
        _noteMarkdownMeta,
        noteMarkdown.isAcceptableOrUnknown(
          data['note_markdown']!,
          _noteMarkdownMeta,
        ),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('start_at_utc')) {
      context.handle(
        _startAtUtcMeta,
        startAtUtc.isAcceptableOrUnknown(
          data['start_at_utc']!,
          _startAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startAtUtcMeta);
    }
    if (data.containsKey('end_at_utc')) {
      context.handle(
        _endAtUtcMeta,
        endAtUtc.isAcceptableOrUnknown(data['end_at_utc']!, _endAtUtcMeta),
      );
    }
    if (data.containsKey('active_seconds')) {
      context.handle(
        _activeSecondsMeta,
        activeSeconds.isAcceptableOrUnknown(
          data['active_seconds']!,
          _activeSecondsMeta,
        ),
      );
    }
    if (data.containsKey('paused_seconds')) {
      context.handle(
        _pausedSecondsMeta,
        pausedSeconds.isAcceptableOrUnknown(
          data['paused_seconds']!,
          _pausedSecondsMeta,
        ),
      );
    }
    if (data.containsKey('timezone_id_at_creation')) {
      context.handle(
        _timezoneIdAtCreationMeta,
        timezoneIdAtCreation.isAcceptableOrUnknown(
          data['timezone_id_at_creation']!,
          _timezoneIdAtCreationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timezoneIdAtCreationMeta);
    }
    if (data.containsKey('offset_minutes_at_start')) {
      context.handle(
        _offsetMinutesAtStartMeta,
        offsetMinutesAtStart.isAcceptableOrUnknown(
          data['offset_minutes_at_start']!,
          _offsetMinutesAtStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_offsetMinutesAtStartMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    if (data.containsKey('source_device_id')) {
      context.handle(
        _sourceDeviceIdMeta,
        sourceDeviceId.isAcceptableOrUnknown(
          data['source_device_id']!,
          _sourceDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceDeviceIdMeta);
    }
    if (data.containsKey('deleted_at_utc')) {
      context.handle(
        _deletedAtUtcMeta,
        deletedAtUtc.isAcceptableOrUnknown(
          data['deleted_at_utc']!,
          _deletedAtUtcMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      skillId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skill_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      noteMarkdown: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_markdown'],
      ),
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      startAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_at_utc'],
      )!,
      endAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_at_utc'],
      ),
      activeSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_seconds'],
      )!,
      pausedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paused_seconds'],
      )!,
      timezoneIdAtCreation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone_id_at_creation'],
      )!,
      offsetMinutesAtStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_minutes_at_start'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc'],
      )!,
      sourceDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_device_id'],
      )!,
      deletedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_utc'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final String skillId;
  final String? title;
  final String? noteMarkdown;
  final String mode;
  final String status;
  final String source;
  final int startAtUtc;
  final int? endAtUtc;
  final int activeSeconds;
  final int pausedSeconds;
  final String timezoneIdAtCreation;
  final int offsetMinutesAtStart;
  final int createdAtUtc;
  final int updatedAtUtc;
  final String sourceDeviceId;
  final int? deletedAtUtc;
  const Session({
    required this.id,
    required this.skillId,
    this.title,
    this.noteMarkdown,
    required this.mode,
    required this.status,
    required this.source,
    required this.startAtUtc,
    this.endAtUtc,
    required this.activeSeconds,
    required this.pausedSeconds,
    required this.timezoneIdAtCreation,
    required this.offsetMinutesAtStart,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.sourceDeviceId,
    this.deletedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['skill_id'] = Variable<String>(skillId);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || noteMarkdown != null) {
      map['note_markdown'] = Variable<String>(noteMarkdown);
    }
    map['mode'] = Variable<String>(mode);
    map['status'] = Variable<String>(status);
    map['source'] = Variable<String>(source);
    map['start_at_utc'] = Variable<int>(startAtUtc);
    if (!nullToAbsent || endAtUtc != null) {
      map['end_at_utc'] = Variable<int>(endAtUtc);
    }
    map['active_seconds'] = Variable<int>(activeSeconds);
    map['paused_seconds'] = Variable<int>(pausedSeconds);
    map['timezone_id_at_creation'] = Variable<String>(timezoneIdAtCreation);
    map['offset_minutes_at_start'] = Variable<int>(offsetMinutesAtStart);
    map['created_at_utc'] = Variable<int>(createdAtUtc);
    map['updated_at_utc'] = Variable<int>(updatedAtUtc);
    map['source_device_id'] = Variable<String>(sourceDeviceId);
    if (!nullToAbsent || deletedAtUtc != null) {
      map['deleted_at_utc'] = Variable<int>(deletedAtUtc);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      skillId: Value(skillId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      noteMarkdown: noteMarkdown == null && nullToAbsent
          ? const Value.absent()
          : Value(noteMarkdown),
      mode: Value(mode),
      status: Value(status),
      source: Value(source),
      startAtUtc: Value(startAtUtc),
      endAtUtc: endAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(endAtUtc),
      activeSeconds: Value(activeSeconds),
      pausedSeconds: Value(pausedSeconds),
      timezoneIdAtCreation: Value(timezoneIdAtCreation),
      offsetMinutesAtStart: Value(offsetMinutesAtStart),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
      sourceDeviceId: Value(sourceDeviceId),
      deletedAtUtc: deletedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtUtc),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      skillId: serializer.fromJson<String>(json['skillId']),
      title: serializer.fromJson<String?>(json['title']),
      noteMarkdown: serializer.fromJson<String?>(json['noteMarkdown']),
      mode: serializer.fromJson<String>(json['mode']),
      status: serializer.fromJson<String>(json['status']),
      source: serializer.fromJson<String>(json['source']),
      startAtUtc: serializer.fromJson<int>(json['startAtUtc']),
      endAtUtc: serializer.fromJson<int?>(json['endAtUtc']),
      activeSeconds: serializer.fromJson<int>(json['activeSeconds']),
      pausedSeconds: serializer.fromJson<int>(json['pausedSeconds']),
      timezoneIdAtCreation: serializer.fromJson<String>(
        json['timezoneIdAtCreation'],
      ),
      offsetMinutesAtStart: serializer.fromJson<int>(
        json['offsetMinutesAtStart'],
      ),
      createdAtUtc: serializer.fromJson<int>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<int>(json['updatedAtUtc']),
      sourceDeviceId: serializer.fromJson<String>(json['sourceDeviceId']),
      deletedAtUtc: serializer.fromJson<int?>(json['deletedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'skillId': serializer.toJson<String>(skillId),
      'title': serializer.toJson<String?>(title),
      'noteMarkdown': serializer.toJson<String?>(noteMarkdown),
      'mode': serializer.toJson<String>(mode),
      'status': serializer.toJson<String>(status),
      'source': serializer.toJson<String>(source),
      'startAtUtc': serializer.toJson<int>(startAtUtc),
      'endAtUtc': serializer.toJson<int?>(endAtUtc),
      'activeSeconds': serializer.toJson<int>(activeSeconds),
      'pausedSeconds': serializer.toJson<int>(pausedSeconds),
      'timezoneIdAtCreation': serializer.toJson<String>(timezoneIdAtCreation),
      'offsetMinutesAtStart': serializer.toJson<int>(offsetMinutesAtStart),
      'createdAtUtc': serializer.toJson<int>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<int>(updatedAtUtc),
      'sourceDeviceId': serializer.toJson<String>(sourceDeviceId),
      'deletedAtUtc': serializer.toJson<int?>(deletedAtUtc),
    };
  }

  Session copyWith({
    String? id,
    String? skillId,
    Value<String?> title = const Value.absent(),
    Value<String?> noteMarkdown = const Value.absent(),
    String? mode,
    String? status,
    String? source,
    int? startAtUtc,
    Value<int?> endAtUtc = const Value.absent(),
    int? activeSeconds,
    int? pausedSeconds,
    String? timezoneIdAtCreation,
    int? offsetMinutesAtStart,
    int? createdAtUtc,
    int? updatedAtUtc,
    String? sourceDeviceId,
    Value<int?> deletedAtUtc = const Value.absent(),
  }) => Session(
    id: id ?? this.id,
    skillId: skillId ?? this.skillId,
    title: title.present ? title.value : this.title,
    noteMarkdown: noteMarkdown.present ? noteMarkdown.value : this.noteMarkdown,
    mode: mode ?? this.mode,
    status: status ?? this.status,
    source: source ?? this.source,
    startAtUtc: startAtUtc ?? this.startAtUtc,
    endAtUtc: endAtUtc.present ? endAtUtc.value : this.endAtUtc,
    activeSeconds: activeSeconds ?? this.activeSeconds,
    pausedSeconds: pausedSeconds ?? this.pausedSeconds,
    timezoneIdAtCreation: timezoneIdAtCreation ?? this.timezoneIdAtCreation,
    offsetMinutesAtStart: offsetMinutesAtStart ?? this.offsetMinutesAtStart,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
    deletedAtUtc: deletedAtUtc.present ? deletedAtUtc.value : this.deletedAtUtc,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      skillId: data.skillId.present ? data.skillId.value : this.skillId,
      title: data.title.present ? data.title.value : this.title,
      noteMarkdown: data.noteMarkdown.present
          ? data.noteMarkdown.value
          : this.noteMarkdown,
      mode: data.mode.present ? data.mode.value : this.mode,
      status: data.status.present ? data.status.value : this.status,
      source: data.source.present ? data.source.value : this.source,
      startAtUtc: data.startAtUtc.present
          ? data.startAtUtc.value
          : this.startAtUtc,
      endAtUtc: data.endAtUtc.present ? data.endAtUtc.value : this.endAtUtc,
      activeSeconds: data.activeSeconds.present
          ? data.activeSeconds.value
          : this.activeSeconds,
      pausedSeconds: data.pausedSeconds.present
          ? data.pausedSeconds.value
          : this.pausedSeconds,
      timezoneIdAtCreation: data.timezoneIdAtCreation.present
          ? data.timezoneIdAtCreation.value
          : this.timezoneIdAtCreation,
      offsetMinutesAtStart: data.offsetMinutesAtStart.present
          ? data.offsetMinutesAtStart.value
          : this.offsetMinutesAtStart,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
      sourceDeviceId: data.sourceDeviceId.present
          ? data.sourceDeviceId.value
          : this.sourceDeviceId,
      deletedAtUtc: data.deletedAtUtc.present
          ? data.deletedAtUtc.value
          : this.deletedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('skillId: $skillId, ')
          ..write('title: $title, ')
          ..write('noteMarkdown: $noteMarkdown, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('endAtUtc: $endAtUtc, ')
          ..write('activeSeconds: $activeSeconds, ')
          ..write('pausedSeconds: $pausedSeconds, ')
          ..write('timezoneIdAtCreation: $timezoneIdAtCreation, ')
          ..write('offsetMinutesAtStart: $offsetMinutesAtStart, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('sourceDeviceId: $sourceDeviceId, ')
          ..write('deletedAtUtc: $deletedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    skillId,
    title,
    noteMarkdown,
    mode,
    status,
    source,
    startAtUtc,
    endAtUtc,
    activeSeconds,
    pausedSeconds,
    timezoneIdAtCreation,
    offsetMinutesAtStart,
    createdAtUtc,
    updatedAtUtc,
    sourceDeviceId,
    deletedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.skillId == this.skillId &&
          other.title == this.title &&
          other.noteMarkdown == this.noteMarkdown &&
          other.mode == this.mode &&
          other.status == this.status &&
          other.source == this.source &&
          other.startAtUtc == this.startAtUtc &&
          other.endAtUtc == this.endAtUtc &&
          other.activeSeconds == this.activeSeconds &&
          other.pausedSeconds == this.pausedSeconds &&
          other.timezoneIdAtCreation == this.timezoneIdAtCreation &&
          other.offsetMinutesAtStart == this.offsetMinutesAtStart &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc &&
          other.sourceDeviceId == this.sourceDeviceId &&
          other.deletedAtUtc == this.deletedAtUtc);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<String> skillId;
  final Value<String?> title;
  final Value<String?> noteMarkdown;
  final Value<String> mode;
  final Value<String> status;
  final Value<String> source;
  final Value<int> startAtUtc;
  final Value<int?> endAtUtc;
  final Value<int> activeSeconds;
  final Value<int> pausedSeconds;
  final Value<String> timezoneIdAtCreation;
  final Value<int> offsetMinutesAtStart;
  final Value<int> createdAtUtc;
  final Value<int> updatedAtUtc;
  final Value<String> sourceDeviceId;
  final Value<int?> deletedAtUtc;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.skillId = const Value.absent(),
    this.title = const Value.absent(),
    this.noteMarkdown = const Value.absent(),
    this.mode = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    this.startAtUtc = const Value.absent(),
    this.endAtUtc = const Value.absent(),
    this.activeSeconds = const Value.absent(),
    this.pausedSeconds = const Value.absent(),
    this.timezoneIdAtCreation = const Value.absent(),
    this.offsetMinutesAtStart = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.sourceDeviceId = const Value.absent(),
    this.deletedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required String skillId,
    this.title = const Value.absent(),
    this.noteMarkdown = const Value.absent(),
    this.mode = const Value.absent(),
    required String status,
    this.source = const Value.absent(),
    required int startAtUtc,
    this.endAtUtc = const Value.absent(),
    this.activeSeconds = const Value.absent(),
    this.pausedSeconds = const Value.absent(),
    required String timezoneIdAtCreation,
    required int offsetMinutesAtStart,
    required int createdAtUtc,
    required int updatedAtUtc,
    required String sourceDeviceId,
    this.deletedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       skillId = Value(skillId),
       status = Value(status),
       startAtUtc = Value(startAtUtc),
       timezoneIdAtCreation = Value(timezoneIdAtCreation),
       offsetMinutesAtStart = Value(offsetMinutesAtStart),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc),
       sourceDeviceId = Value(sourceDeviceId);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<String>? skillId,
    Expression<String>? title,
    Expression<String>? noteMarkdown,
    Expression<String>? mode,
    Expression<String>? status,
    Expression<String>? source,
    Expression<int>? startAtUtc,
    Expression<int>? endAtUtc,
    Expression<int>? activeSeconds,
    Expression<int>? pausedSeconds,
    Expression<String>? timezoneIdAtCreation,
    Expression<int>? offsetMinutesAtStart,
    Expression<int>? createdAtUtc,
    Expression<int>? updatedAtUtc,
    Expression<String>? sourceDeviceId,
    Expression<int>? deletedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (skillId != null) 'skill_id': skillId,
      if (title != null) 'title': title,
      if (noteMarkdown != null) 'note_markdown': noteMarkdown,
      if (mode != null) 'mode': mode,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (startAtUtc != null) 'start_at_utc': startAtUtc,
      if (endAtUtc != null) 'end_at_utc': endAtUtc,
      if (activeSeconds != null) 'active_seconds': activeSeconds,
      if (pausedSeconds != null) 'paused_seconds': pausedSeconds,
      if (timezoneIdAtCreation != null)
        'timezone_id_at_creation': timezoneIdAtCreation,
      if (offsetMinutesAtStart != null)
        'offset_minutes_at_start': offsetMinutesAtStart,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (sourceDeviceId != null) 'source_device_id': sourceDeviceId,
      if (deletedAtUtc != null) 'deleted_at_utc': deletedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? skillId,
    Value<String?>? title,
    Value<String?>? noteMarkdown,
    Value<String>? mode,
    Value<String>? status,
    Value<String>? source,
    Value<int>? startAtUtc,
    Value<int?>? endAtUtc,
    Value<int>? activeSeconds,
    Value<int>? pausedSeconds,
    Value<String>? timezoneIdAtCreation,
    Value<int>? offsetMinutesAtStart,
    Value<int>? createdAtUtc,
    Value<int>? updatedAtUtc,
    Value<String>? sourceDeviceId,
    Value<int?>? deletedAtUtc,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      skillId: skillId ?? this.skillId,
      title: title ?? this.title,
      noteMarkdown: noteMarkdown ?? this.noteMarkdown,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      source: source ?? this.source,
      startAtUtc: startAtUtc ?? this.startAtUtc,
      endAtUtc: endAtUtc ?? this.endAtUtc,
      activeSeconds: activeSeconds ?? this.activeSeconds,
      pausedSeconds: pausedSeconds ?? this.pausedSeconds,
      timezoneIdAtCreation: timezoneIdAtCreation ?? this.timezoneIdAtCreation,
      offsetMinutesAtStart: offsetMinutesAtStart ?? this.offsetMinutesAtStart,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      deletedAtUtc: deletedAtUtc ?? this.deletedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (skillId.present) {
      map['skill_id'] = Variable<String>(skillId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (noteMarkdown.present) {
      map['note_markdown'] = Variable<String>(noteMarkdown.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (startAtUtc.present) {
      map['start_at_utc'] = Variable<int>(startAtUtc.value);
    }
    if (endAtUtc.present) {
      map['end_at_utc'] = Variable<int>(endAtUtc.value);
    }
    if (activeSeconds.present) {
      map['active_seconds'] = Variable<int>(activeSeconds.value);
    }
    if (pausedSeconds.present) {
      map['paused_seconds'] = Variable<int>(pausedSeconds.value);
    }
    if (timezoneIdAtCreation.present) {
      map['timezone_id_at_creation'] = Variable<String>(
        timezoneIdAtCreation.value,
      );
    }
    if (offsetMinutesAtStart.present) {
      map['offset_minutes_at_start'] = Variable<int>(
        offsetMinutesAtStart.value,
      );
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<int>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<int>(updatedAtUtc.value);
    }
    if (sourceDeviceId.present) {
      map['source_device_id'] = Variable<String>(sourceDeviceId.value);
    }
    if (deletedAtUtc.present) {
      map['deleted_at_utc'] = Variable<int>(deletedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('skillId: $skillId, ')
          ..write('title: $title, ')
          ..write('noteMarkdown: $noteMarkdown, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('endAtUtc: $endAtUtc, ')
          ..write('activeSeconds: $activeSeconds, ')
          ..write('pausedSeconds: $pausedSeconds, ')
          ..write('timezoneIdAtCreation: $timezoneIdAtCreation, ')
          ..write('offsetMinutesAtStart: $offsetMinutesAtStart, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('sourceDeviceId: $sourceDeviceId, ')
          ..write('deletedAtUtc: $deletedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionSegmentsTable extends SessionSegments
    with TableInfo<$SessionSegmentsTable, SessionSegment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionSegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _segmentTypeMeta = const VerificationMeta(
    'segmentType',
  );
  @override
  late final GeneratedColumn<String> segmentType = GeneratedColumn<String>(
    'segment_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pomodoroPhaseMeta = const VerificationMeta(
    'pomodoroPhase',
  );
  @override
  late final GeneratedColumn<String> pomodoroPhase = GeneratedColumn<String>(
    'pomodoro_phase',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cycleNumberMeta = const VerificationMeta(
    'cycleNumber',
  );
  @override
  late final GeneratedColumn<int> cycleNumber = GeneratedColumn<int>(
    'cycle_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startAtUtcMeta = const VerificationMeta(
    'startAtUtc',
  );
  @override
  late final GeneratedColumn<int> startAtUtc = GeneratedColumn<int>(
    'start_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtUtcMeta = const VerificationMeta(
    'endAtUtc',
  );
  @override
  late final GeneratedColumn<int> endAtUtc = GeneratedColumn<int>(
    'end_at_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<int> createdAtUtc = GeneratedColumn<int>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtc = GeneratedColumn<int>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    segmentType,
    pomodoroPhase,
    cycleNumber,
    startAtUtc,
    endAtUtc,
    durationSeconds,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_segments';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionSegment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('segment_type')) {
      context.handle(
        _segmentTypeMeta,
        segmentType.isAcceptableOrUnknown(
          data['segment_type']!,
          _segmentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_segmentTypeMeta);
    }
    if (data.containsKey('pomodoro_phase')) {
      context.handle(
        _pomodoroPhaseMeta,
        pomodoroPhase.isAcceptableOrUnknown(
          data['pomodoro_phase']!,
          _pomodoroPhaseMeta,
        ),
      );
    }
    if (data.containsKey('cycle_number')) {
      context.handle(
        _cycleNumberMeta,
        cycleNumber.isAcceptableOrUnknown(
          data['cycle_number']!,
          _cycleNumberMeta,
        ),
      );
    }
    if (data.containsKey('start_at_utc')) {
      context.handle(
        _startAtUtcMeta,
        startAtUtc.isAcceptableOrUnknown(
          data['start_at_utc']!,
          _startAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startAtUtcMeta);
    }
    if (data.containsKey('end_at_utc')) {
      context.handle(
        _endAtUtcMeta,
        endAtUtc.isAcceptableOrUnknown(data['end_at_utc']!, _endAtUtcMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionSegment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionSegment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      segmentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segment_type'],
      )!,
      pomodoroPhase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pomodoro_phase'],
      ),
      cycleNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cycle_number'],
      ),
      startAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_at_utc'],
      )!,
      endAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_at_utc'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $SessionSegmentsTable createAlias(String alias) {
    return $SessionSegmentsTable(attachedDatabase, alias);
  }
}

class SessionSegment extends DataClass implements Insertable<SessionSegment> {
  final String id;
  final String sessionId;
  final String segmentType;
  final String? pomodoroPhase;
  final int? cycleNumber;
  final int startAtUtc;
  final int? endAtUtc;
  final int durationSeconds;
  final int createdAtUtc;
  final int updatedAtUtc;
  const SessionSegment({
    required this.id,
    required this.sessionId,
    required this.segmentType,
    this.pomodoroPhase,
    this.cycleNumber,
    required this.startAtUtc,
    this.endAtUtc,
    required this.durationSeconds,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['segment_type'] = Variable<String>(segmentType);
    if (!nullToAbsent || pomodoroPhase != null) {
      map['pomodoro_phase'] = Variable<String>(pomodoroPhase);
    }
    if (!nullToAbsent || cycleNumber != null) {
      map['cycle_number'] = Variable<int>(cycleNumber);
    }
    map['start_at_utc'] = Variable<int>(startAtUtc);
    if (!nullToAbsent || endAtUtc != null) {
      map['end_at_utc'] = Variable<int>(endAtUtc);
    }
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['created_at_utc'] = Variable<int>(createdAtUtc);
    map['updated_at_utc'] = Variable<int>(updatedAtUtc);
    return map;
  }

  SessionSegmentsCompanion toCompanion(bool nullToAbsent) {
    return SessionSegmentsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      segmentType: Value(segmentType),
      pomodoroPhase: pomodoroPhase == null && nullToAbsent
          ? const Value.absent()
          : Value(pomodoroPhase),
      cycleNumber: cycleNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(cycleNumber),
      startAtUtc: Value(startAtUtc),
      endAtUtc: endAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(endAtUtc),
      durationSeconds: Value(durationSeconds),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory SessionSegment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionSegment(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      segmentType: serializer.fromJson<String>(json['segmentType']),
      pomodoroPhase: serializer.fromJson<String?>(json['pomodoroPhase']),
      cycleNumber: serializer.fromJson<int?>(json['cycleNumber']),
      startAtUtc: serializer.fromJson<int>(json['startAtUtc']),
      endAtUtc: serializer.fromJson<int?>(json['endAtUtc']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      createdAtUtc: serializer.fromJson<int>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<int>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'segmentType': serializer.toJson<String>(segmentType),
      'pomodoroPhase': serializer.toJson<String?>(pomodoroPhase),
      'cycleNumber': serializer.toJson<int?>(cycleNumber),
      'startAtUtc': serializer.toJson<int>(startAtUtc),
      'endAtUtc': serializer.toJson<int?>(endAtUtc),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'createdAtUtc': serializer.toJson<int>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<int>(updatedAtUtc),
    };
  }

  SessionSegment copyWith({
    String? id,
    String? sessionId,
    String? segmentType,
    Value<String?> pomodoroPhase = const Value.absent(),
    Value<int?> cycleNumber = const Value.absent(),
    int? startAtUtc,
    Value<int?> endAtUtc = const Value.absent(),
    int? durationSeconds,
    int? createdAtUtc,
    int? updatedAtUtc,
  }) => SessionSegment(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    segmentType: segmentType ?? this.segmentType,
    pomodoroPhase: pomodoroPhase.present
        ? pomodoroPhase.value
        : this.pomodoroPhase,
    cycleNumber: cycleNumber.present ? cycleNumber.value : this.cycleNumber,
    startAtUtc: startAtUtc ?? this.startAtUtc,
    endAtUtc: endAtUtc.present ? endAtUtc.value : this.endAtUtc,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  SessionSegment copyWithCompanion(SessionSegmentsCompanion data) {
    return SessionSegment(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      segmentType: data.segmentType.present
          ? data.segmentType.value
          : this.segmentType,
      pomodoroPhase: data.pomodoroPhase.present
          ? data.pomodoroPhase.value
          : this.pomodoroPhase,
      cycleNumber: data.cycleNumber.present
          ? data.cycleNumber.value
          : this.cycleNumber,
      startAtUtc: data.startAtUtc.present
          ? data.startAtUtc.value
          : this.startAtUtc,
      endAtUtc: data.endAtUtc.present ? data.endAtUtc.value : this.endAtUtc,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionSegment(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('segmentType: $segmentType, ')
          ..write('pomodoroPhase: $pomodoroPhase, ')
          ..write('cycleNumber: $cycleNumber, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('endAtUtc: $endAtUtc, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    segmentType,
    pomodoroPhase,
    cycleNumber,
    startAtUtc,
    endAtUtc,
    durationSeconds,
    createdAtUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionSegment &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.segmentType == this.segmentType &&
          other.pomodoroPhase == this.pomodoroPhase &&
          other.cycleNumber == this.cycleNumber &&
          other.startAtUtc == this.startAtUtc &&
          other.endAtUtc == this.endAtUtc &&
          other.durationSeconds == this.durationSeconds &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class SessionSegmentsCompanion extends UpdateCompanion<SessionSegment> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> segmentType;
  final Value<String?> pomodoroPhase;
  final Value<int?> cycleNumber;
  final Value<int> startAtUtc;
  final Value<int?> endAtUtc;
  final Value<int> durationSeconds;
  final Value<int> createdAtUtc;
  final Value<int> updatedAtUtc;
  final Value<int> rowid;
  const SessionSegmentsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.segmentType = const Value.absent(),
    this.pomodoroPhase = const Value.absent(),
    this.cycleNumber = const Value.absent(),
    this.startAtUtc = const Value.absent(),
    this.endAtUtc = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionSegmentsCompanion.insert({
    required String id,
    required String sessionId,
    required String segmentType,
    this.pomodoroPhase = const Value.absent(),
    this.cycleNumber = const Value.absent(),
    required int startAtUtc,
    this.endAtUtc = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    required int createdAtUtc,
    required int updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       segmentType = Value(segmentType),
       startAtUtc = Value(startAtUtc),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<SessionSegment> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? segmentType,
    Expression<String>? pomodoroPhase,
    Expression<int>? cycleNumber,
    Expression<int>? startAtUtc,
    Expression<int>? endAtUtc,
    Expression<int>? durationSeconds,
    Expression<int>? createdAtUtc,
    Expression<int>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (segmentType != null) 'segment_type': segmentType,
      if (pomodoroPhase != null) 'pomodoro_phase': pomodoroPhase,
      if (cycleNumber != null) 'cycle_number': cycleNumber,
      if (startAtUtc != null) 'start_at_utc': startAtUtc,
      if (endAtUtc != null) 'end_at_utc': endAtUtc,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionSegmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? segmentType,
    Value<String?>? pomodoroPhase,
    Value<int?>? cycleNumber,
    Value<int>? startAtUtc,
    Value<int?>? endAtUtc,
    Value<int>? durationSeconds,
    Value<int>? createdAtUtc,
    Value<int>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return SessionSegmentsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      segmentType: segmentType ?? this.segmentType,
      pomodoroPhase: pomodoroPhase ?? this.pomodoroPhase,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      startAtUtc: startAtUtc ?? this.startAtUtc,
      endAtUtc: endAtUtc ?? this.endAtUtc,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (segmentType.present) {
      map['segment_type'] = Variable<String>(segmentType.value);
    }
    if (pomodoroPhase.present) {
      map['pomodoro_phase'] = Variable<String>(pomodoroPhase.value);
    }
    if (cycleNumber.present) {
      map['cycle_number'] = Variable<int>(cycleNumber.value);
    }
    if (startAtUtc.present) {
      map['start_at_utc'] = Variable<int>(startAtUtc.value);
    }
    if (endAtUtc.present) {
      map['end_at_utc'] = Variable<int>(endAtUtc.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<int>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<int>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionSegmentsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('segmentType: $segmentType, ')
          ..write('pomodoroPhase: $pomodoroPhase, ')
          ..write('cycleNumber: $cycleNumber, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('endAtUtc: $endAtUtc, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimerRuntimeTable extends TimerRuntime
    with TableInfo<$TimerRuntimeTable, TimerRuntimeData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimerRuntimeTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _singletonIdMeta = const VerificationMeta(
    'singletonId',
  );
  @override
  late final GeneratedColumn<int> singletonId = GeneratedColumn<int>(
    'singleton_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
    ),
  );
  static const VerificationMeta _machineStateMeta = const VerificationMeta(
    'machineState',
  );
  @override
  late final GeneratedColumn<String> machineState = GeneratedColumn<String>(
    'machine_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('idle'),
  );
  static const VerificationMeta _currentSegmentIdMeta = const VerificationMeta(
    'currentSegmentId',
  );
  @override
  late final GeneratedColumn<String> currentSegmentId = GeneratedColumn<String>(
    'current_segment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phasePlannedSecondsMeta =
      const VerificationMeta('phasePlannedSeconds');
  @override
  late final GeneratedColumn<int> phasePlannedSeconds = GeneratedColumn<int>(
    'phase_planned_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phaseStartedAtUtcMeta = const VerificationMeta(
    'phaseStartedAtUtc',
  );
  @override
  late final GeneratedColumn<int> phaseStartedAtUtc = GeneratedColumn<int>(
    'phase_started_at_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phaseAccumulatedSecondsMeta =
      const VerificationMeta('phaseAccumulatedSeconds');
  @override
  late final GeneratedColumn<int> phaseAccumulatedSeconds =
      GeneratedColumn<int>(
        'phase_accumulated_seconds',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _currentCycleMeta = const VerificationMeta(
    'currentCycle',
  );
  @override
  late final GeneratedColumn<int> currentCycle = GeneratedColumn<int>(
    'current_cycle',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _monotonicAnchorMicrosMeta =
      const VerificationMeta('monotonicAnchorMicros');
  @override
  late final GeneratedColumn<int> monotonicAnchorMicros = GeneratedColumn<int>(
    'monotonic_anchor_micros',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wallClockAnchorUtcMeta =
      const VerificationMeta('wallClockAnchorUtc');
  @override
  late final GeneratedColumn<int> wallClockAnchorUtc = GeneratedColumn<int>(
    'wall_clock_anchor_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastHeartbeatUtcMeta = const VerificationMeta(
    'lastHeartbeatUtc',
  );
  @override
  late final GeneratedColumn<int> lastHeartbeatUtc = GeneratedColumn<int>(
    'last_heartbeat_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastCheckpointAtUtcMeta =
      const VerificationMeta('lastCheckpointAtUtc');
  @override
  late final GeneratedColumn<int> lastCheckpointAtUtc = GeneratedColumn<int>(
    'last_checkpoint_at_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recoveryReasonMeta = const VerificationMeta(
    'recoveryReason',
  );
  @override
  late final GeneratedColumn<String> recoveryReason = GeneratedColumn<String>(
    'recovery_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtc = GeneratedColumn<int>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    singletonId,
    sessionId,
    machineState,
    currentSegmentId,
    phasePlannedSeconds,
    phaseStartedAtUtc,
    phaseAccumulatedSeconds,
    currentCycle,
    monotonicAnchorMicros,
    wallClockAnchorUtc,
    lastHeartbeatUtc,
    lastCheckpointAtUtc,
    recoveryReason,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timer_runtime';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimerRuntimeData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('singleton_id')) {
      context.handle(
        _singletonIdMeta,
        singletonId.isAcceptableOrUnknown(
          data['singleton_id']!,
          _singletonIdMeta,
        ),
      );
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    if (data.containsKey('machine_state')) {
      context.handle(
        _machineStateMeta,
        machineState.isAcceptableOrUnknown(
          data['machine_state']!,
          _machineStateMeta,
        ),
      );
    }
    if (data.containsKey('current_segment_id')) {
      context.handle(
        _currentSegmentIdMeta,
        currentSegmentId.isAcceptableOrUnknown(
          data['current_segment_id']!,
          _currentSegmentIdMeta,
        ),
      );
    }
    if (data.containsKey('phase_planned_seconds')) {
      context.handle(
        _phasePlannedSecondsMeta,
        phasePlannedSeconds.isAcceptableOrUnknown(
          data['phase_planned_seconds']!,
          _phasePlannedSecondsMeta,
        ),
      );
    }
    if (data.containsKey('phase_started_at_utc')) {
      context.handle(
        _phaseStartedAtUtcMeta,
        phaseStartedAtUtc.isAcceptableOrUnknown(
          data['phase_started_at_utc']!,
          _phaseStartedAtUtcMeta,
        ),
      );
    }
    if (data.containsKey('phase_accumulated_seconds')) {
      context.handle(
        _phaseAccumulatedSecondsMeta,
        phaseAccumulatedSeconds.isAcceptableOrUnknown(
          data['phase_accumulated_seconds']!,
          _phaseAccumulatedSecondsMeta,
        ),
      );
    }
    if (data.containsKey('current_cycle')) {
      context.handle(
        _currentCycleMeta,
        currentCycle.isAcceptableOrUnknown(
          data['current_cycle']!,
          _currentCycleMeta,
        ),
      );
    }
    if (data.containsKey('monotonic_anchor_micros')) {
      context.handle(
        _monotonicAnchorMicrosMeta,
        monotonicAnchorMicros.isAcceptableOrUnknown(
          data['monotonic_anchor_micros']!,
          _monotonicAnchorMicrosMeta,
        ),
      );
    }
    if (data.containsKey('wall_clock_anchor_utc')) {
      context.handle(
        _wallClockAnchorUtcMeta,
        wallClockAnchorUtc.isAcceptableOrUnknown(
          data['wall_clock_anchor_utc']!,
          _wallClockAnchorUtcMeta,
        ),
      );
    }
    if (data.containsKey('last_heartbeat_utc')) {
      context.handle(
        _lastHeartbeatUtcMeta,
        lastHeartbeatUtc.isAcceptableOrUnknown(
          data['last_heartbeat_utc']!,
          _lastHeartbeatUtcMeta,
        ),
      );
    }
    if (data.containsKey('last_checkpoint_at_utc')) {
      context.handle(
        _lastCheckpointAtUtcMeta,
        lastCheckpointAtUtc.isAcceptableOrUnknown(
          data['last_checkpoint_at_utc']!,
          _lastCheckpointAtUtcMeta,
        ),
      );
    }
    if (data.containsKey('recovery_reason')) {
      context.handle(
        _recoveryReasonMeta,
        recoveryReason.isAcceptableOrUnknown(
          data['recovery_reason']!,
          _recoveryReasonMeta,
        ),
      );
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singletonId};
  @override
  TimerRuntimeData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimerRuntimeData(
      singletonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      ),
      machineState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}machine_state'],
      )!,
      currentSegmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_segment_id'],
      ),
      phasePlannedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}phase_planned_seconds'],
      ),
      phaseStartedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}phase_started_at_utc'],
      ),
      phaseAccumulatedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}phase_accumulated_seconds'],
      )!,
      currentCycle: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_cycle'],
      )!,
      monotonicAnchorMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monotonic_anchor_micros'],
      ),
      wallClockAnchorUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wall_clock_anchor_utc'],
      ),
      lastHeartbeatUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_heartbeat_utc'],
      ),
      lastCheckpointAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_checkpoint_at_utc'],
      ),
      recoveryReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recovery_reason'],
      ),
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $TimerRuntimeTable createAlias(String alias) {
    return $TimerRuntimeTable(attachedDatabase, alias);
  }
}

class TimerRuntimeData extends DataClass
    implements Insertable<TimerRuntimeData> {
  final int singletonId;
  final String? sessionId;
  final String machineState;
  final String? currentSegmentId;
  final int? phasePlannedSeconds;
  final int? phaseStartedAtUtc;
  final int phaseAccumulatedSeconds;
  final int currentCycle;
  final int? monotonicAnchorMicros;
  final int? wallClockAnchorUtc;
  final int? lastHeartbeatUtc;
  final int? lastCheckpointAtUtc;
  final String? recoveryReason;
  final int updatedAtUtc;
  const TimerRuntimeData({
    required this.singletonId,
    this.sessionId,
    required this.machineState,
    this.currentSegmentId,
    this.phasePlannedSeconds,
    this.phaseStartedAtUtc,
    required this.phaseAccumulatedSeconds,
    required this.currentCycle,
    this.monotonicAnchorMicros,
    this.wallClockAnchorUtc,
    this.lastHeartbeatUtc,
    this.lastCheckpointAtUtc,
    this.recoveryReason,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton_id'] = Variable<int>(singletonId);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<String>(sessionId);
    }
    map['machine_state'] = Variable<String>(machineState);
    if (!nullToAbsent || currentSegmentId != null) {
      map['current_segment_id'] = Variable<String>(currentSegmentId);
    }
    if (!nullToAbsent || phasePlannedSeconds != null) {
      map['phase_planned_seconds'] = Variable<int>(phasePlannedSeconds);
    }
    if (!nullToAbsent || phaseStartedAtUtc != null) {
      map['phase_started_at_utc'] = Variable<int>(phaseStartedAtUtc);
    }
    map['phase_accumulated_seconds'] = Variable<int>(phaseAccumulatedSeconds);
    map['current_cycle'] = Variable<int>(currentCycle);
    if (!nullToAbsent || monotonicAnchorMicros != null) {
      map['monotonic_anchor_micros'] = Variable<int>(monotonicAnchorMicros);
    }
    if (!nullToAbsent || wallClockAnchorUtc != null) {
      map['wall_clock_anchor_utc'] = Variable<int>(wallClockAnchorUtc);
    }
    if (!nullToAbsent || lastHeartbeatUtc != null) {
      map['last_heartbeat_utc'] = Variable<int>(lastHeartbeatUtc);
    }
    if (!nullToAbsent || lastCheckpointAtUtc != null) {
      map['last_checkpoint_at_utc'] = Variable<int>(lastCheckpointAtUtc);
    }
    if (!nullToAbsent || recoveryReason != null) {
      map['recovery_reason'] = Variable<String>(recoveryReason);
    }
    map['updated_at_utc'] = Variable<int>(updatedAtUtc);
    return map;
  }

  TimerRuntimeCompanion toCompanion(bool nullToAbsent) {
    return TimerRuntimeCompanion(
      singletonId: Value(singletonId),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
      machineState: Value(machineState),
      currentSegmentId: currentSegmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentSegmentId),
      phasePlannedSeconds: phasePlannedSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(phasePlannedSeconds),
      phaseStartedAtUtc: phaseStartedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(phaseStartedAtUtc),
      phaseAccumulatedSeconds: Value(phaseAccumulatedSeconds),
      currentCycle: Value(currentCycle),
      monotonicAnchorMicros: monotonicAnchorMicros == null && nullToAbsent
          ? const Value.absent()
          : Value(monotonicAnchorMicros),
      wallClockAnchorUtc: wallClockAnchorUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(wallClockAnchorUtc),
      lastHeartbeatUtc: lastHeartbeatUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(lastHeartbeatUtc),
      lastCheckpointAtUtc: lastCheckpointAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCheckpointAtUtc),
      recoveryReason: recoveryReason == null && nullToAbsent
          ? const Value.absent()
          : Value(recoveryReason),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory TimerRuntimeData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimerRuntimeData(
      singletonId: serializer.fromJson<int>(json['singletonId']),
      sessionId: serializer.fromJson<String?>(json['sessionId']),
      machineState: serializer.fromJson<String>(json['machineState']),
      currentSegmentId: serializer.fromJson<String?>(json['currentSegmentId']),
      phasePlannedSeconds: serializer.fromJson<int?>(
        json['phasePlannedSeconds'],
      ),
      phaseStartedAtUtc: serializer.fromJson<int?>(json['phaseStartedAtUtc']),
      phaseAccumulatedSeconds: serializer.fromJson<int>(
        json['phaseAccumulatedSeconds'],
      ),
      currentCycle: serializer.fromJson<int>(json['currentCycle']),
      monotonicAnchorMicros: serializer.fromJson<int?>(
        json['monotonicAnchorMicros'],
      ),
      wallClockAnchorUtc: serializer.fromJson<int?>(json['wallClockAnchorUtc']),
      lastHeartbeatUtc: serializer.fromJson<int?>(json['lastHeartbeatUtc']),
      lastCheckpointAtUtc: serializer.fromJson<int?>(
        json['lastCheckpointAtUtc'],
      ),
      recoveryReason: serializer.fromJson<String?>(json['recoveryReason']),
      updatedAtUtc: serializer.fromJson<int>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singletonId': serializer.toJson<int>(singletonId),
      'sessionId': serializer.toJson<String?>(sessionId),
      'machineState': serializer.toJson<String>(machineState),
      'currentSegmentId': serializer.toJson<String?>(currentSegmentId),
      'phasePlannedSeconds': serializer.toJson<int?>(phasePlannedSeconds),
      'phaseStartedAtUtc': serializer.toJson<int?>(phaseStartedAtUtc),
      'phaseAccumulatedSeconds': serializer.toJson<int>(
        phaseAccumulatedSeconds,
      ),
      'currentCycle': serializer.toJson<int>(currentCycle),
      'monotonicAnchorMicros': serializer.toJson<int?>(monotonicAnchorMicros),
      'wallClockAnchorUtc': serializer.toJson<int?>(wallClockAnchorUtc),
      'lastHeartbeatUtc': serializer.toJson<int?>(lastHeartbeatUtc),
      'lastCheckpointAtUtc': serializer.toJson<int?>(lastCheckpointAtUtc),
      'recoveryReason': serializer.toJson<String?>(recoveryReason),
      'updatedAtUtc': serializer.toJson<int>(updatedAtUtc),
    };
  }

  TimerRuntimeData copyWith({
    int? singletonId,
    Value<String?> sessionId = const Value.absent(),
    String? machineState,
    Value<String?> currentSegmentId = const Value.absent(),
    Value<int?> phasePlannedSeconds = const Value.absent(),
    Value<int?> phaseStartedAtUtc = const Value.absent(),
    int? phaseAccumulatedSeconds,
    int? currentCycle,
    Value<int?> monotonicAnchorMicros = const Value.absent(),
    Value<int?> wallClockAnchorUtc = const Value.absent(),
    Value<int?> lastHeartbeatUtc = const Value.absent(),
    Value<int?> lastCheckpointAtUtc = const Value.absent(),
    Value<String?> recoveryReason = const Value.absent(),
    int? updatedAtUtc,
  }) => TimerRuntimeData(
    singletonId: singletonId ?? this.singletonId,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
    machineState: machineState ?? this.machineState,
    currentSegmentId: currentSegmentId.present
        ? currentSegmentId.value
        : this.currentSegmentId,
    phasePlannedSeconds: phasePlannedSeconds.present
        ? phasePlannedSeconds.value
        : this.phasePlannedSeconds,
    phaseStartedAtUtc: phaseStartedAtUtc.present
        ? phaseStartedAtUtc.value
        : this.phaseStartedAtUtc,
    phaseAccumulatedSeconds:
        phaseAccumulatedSeconds ?? this.phaseAccumulatedSeconds,
    currentCycle: currentCycle ?? this.currentCycle,
    monotonicAnchorMicros: monotonicAnchorMicros.present
        ? monotonicAnchorMicros.value
        : this.monotonicAnchorMicros,
    wallClockAnchorUtc: wallClockAnchorUtc.present
        ? wallClockAnchorUtc.value
        : this.wallClockAnchorUtc,
    lastHeartbeatUtc: lastHeartbeatUtc.present
        ? lastHeartbeatUtc.value
        : this.lastHeartbeatUtc,
    lastCheckpointAtUtc: lastCheckpointAtUtc.present
        ? lastCheckpointAtUtc.value
        : this.lastCheckpointAtUtc,
    recoveryReason: recoveryReason.present
        ? recoveryReason.value
        : this.recoveryReason,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  TimerRuntimeData copyWithCompanion(TimerRuntimeCompanion data) {
    return TimerRuntimeData(
      singletonId: data.singletonId.present
          ? data.singletonId.value
          : this.singletonId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      machineState: data.machineState.present
          ? data.machineState.value
          : this.machineState,
      currentSegmentId: data.currentSegmentId.present
          ? data.currentSegmentId.value
          : this.currentSegmentId,
      phasePlannedSeconds: data.phasePlannedSeconds.present
          ? data.phasePlannedSeconds.value
          : this.phasePlannedSeconds,
      phaseStartedAtUtc: data.phaseStartedAtUtc.present
          ? data.phaseStartedAtUtc.value
          : this.phaseStartedAtUtc,
      phaseAccumulatedSeconds: data.phaseAccumulatedSeconds.present
          ? data.phaseAccumulatedSeconds.value
          : this.phaseAccumulatedSeconds,
      currentCycle: data.currentCycle.present
          ? data.currentCycle.value
          : this.currentCycle,
      monotonicAnchorMicros: data.monotonicAnchorMicros.present
          ? data.monotonicAnchorMicros.value
          : this.monotonicAnchorMicros,
      wallClockAnchorUtc: data.wallClockAnchorUtc.present
          ? data.wallClockAnchorUtc.value
          : this.wallClockAnchorUtc,
      lastHeartbeatUtc: data.lastHeartbeatUtc.present
          ? data.lastHeartbeatUtc.value
          : this.lastHeartbeatUtc,
      lastCheckpointAtUtc: data.lastCheckpointAtUtc.present
          ? data.lastCheckpointAtUtc.value
          : this.lastCheckpointAtUtc,
      recoveryReason: data.recoveryReason.present
          ? data.recoveryReason.value
          : this.recoveryReason,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimerRuntimeData(')
          ..write('singletonId: $singletonId, ')
          ..write('sessionId: $sessionId, ')
          ..write('machineState: $machineState, ')
          ..write('currentSegmentId: $currentSegmentId, ')
          ..write('phasePlannedSeconds: $phasePlannedSeconds, ')
          ..write('phaseStartedAtUtc: $phaseStartedAtUtc, ')
          ..write('phaseAccumulatedSeconds: $phaseAccumulatedSeconds, ')
          ..write('currentCycle: $currentCycle, ')
          ..write('monotonicAnchorMicros: $monotonicAnchorMicros, ')
          ..write('wallClockAnchorUtc: $wallClockAnchorUtc, ')
          ..write('lastHeartbeatUtc: $lastHeartbeatUtc, ')
          ..write('lastCheckpointAtUtc: $lastCheckpointAtUtc, ')
          ..write('recoveryReason: $recoveryReason, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    singletonId,
    sessionId,
    machineState,
    currentSegmentId,
    phasePlannedSeconds,
    phaseStartedAtUtc,
    phaseAccumulatedSeconds,
    currentCycle,
    monotonicAnchorMicros,
    wallClockAnchorUtc,
    lastHeartbeatUtc,
    lastCheckpointAtUtc,
    recoveryReason,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimerRuntimeData &&
          other.singletonId == this.singletonId &&
          other.sessionId == this.sessionId &&
          other.machineState == this.machineState &&
          other.currentSegmentId == this.currentSegmentId &&
          other.phasePlannedSeconds == this.phasePlannedSeconds &&
          other.phaseStartedAtUtc == this.phaseStartedAtUtc &&
          other.phaseAccumulatedSeconds == this.phaseAccumulatedSeconds &&
          other.currentCycle == this.currentCycle &&
          other.monotonicAnchorMicros == this.monotonicAnchorMicros &&
          other.wallClockAnchorUtc == this.wallClockAnchorUtc &&
          other.lastHeartbeatUtc == this.lastHeartbeatUtc &&
          other.lastCheckpointAtUtc == this.lastCheckpointAtUtc &&
          other.recoveryReason == this.recoveryReason &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class TimerRuntimeCompanion extends UpdateCompanion<TimerRuntimeData> {
  final Value<int> singletonId;
  final Value<String?> sessionId;
  final Value<String> machineState;
  final Value<String?> currentSegmentId;
  final Value<int?> phasePlannedSeconds;
  final Value<int?> phaseStartedAtUtc;
  final Value<int> phaseAccumulatedSeconds;
  final Value<int> currentCycle;
  final Value<int?> monotonicAnchorMicros;
  final Value<int?> wallClockAnchorUtc;
  final Value<int?> lastHeartbeatUtc;
  final Value<int?> lastCheckpointAtUtc;
  final Value<String?> recoveryReason;
  final Value<int> updatedAtUtc;
  const TimerRuntimeCompanion({
    this.singletonId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.machineState = const Value.absent(),
    this.currentSegmentId = const Value.absent(),
    this.phasePlannedSeconds = const Value.absent(),
    this.phaseStartedAtUtc = const Value.absent(),
    this.phaseAccumulatedSeconds = const Value.absent(),
    this.currentCycle = const Value.absent(),
    this.monotonicAnchorMicros = const Value.absent(),
    this.wallClockAnchorUtc = const Value.absent(),
    this.lastHeartbeatUtc = const Value.absent(),
    this.lastCheckpointAtUtc = const Value.absent(),
    this.recoveryReason = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
  });
  TimerRuntimeCompanion.insert({
    this.singletonId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.machineState = const Value.absent(),
    this.currentSegmentId = const Value.absent(),
    this.phasePlannedSeconds = const Value.absent(),
    this.phaseStartedAtUtc = const Value.absent(),
    this.phaseAccumulatedSeconds = const Value.absent(),
    this.currentCycle = const Value.absent(),
    this.monotonicAnchorMicros = const Value.absent(),
    this.wallClockAnchorUtc = const Value.absent(),
    this.lastHeartbeatUtc = const Value.absent(),
    this.lastCheckpointAtUtc = const Value.absent(),
    this.recoveryReason = const Value.absent(),
    required int updatedAtUtc,
  }) : updatedAtUtc = Value(updatedAtUtc);
  static Insertable<TimerRuntimeData> custom({
    Expression<int>? singletonId,
    Expression<String>? sessionId,
    Expression<String>? machineState,
    Expression<String>? currentSegmentId,
    Expression<int>? phasePlannedSeconds,
    Expression<int>? phaseStartedAtUtc,
    Expression<int>? phaseAccumulatedSeconds,
    Expression<int>? currentCycle,
    Expression<int>? monotonicAnchorMicros,
    Expression<int>? wallClockAnchorUtc,
    Expression<int>? lastHeartbeatUtc,
    Expression<int>? lastCheckpointAtUtc,
    Expression<String>? recoveryReason,
    Expression<int>? updatedAtUtc,
  }) {
    return RawValuesInsertable({
      if (singletonId != null) 'singleton_id': singletonId,
      if (sessionId != null) 'session_id': sessionId,
      if (machineState != null) 'machine_state': machineState,
      if (currentSegmentId != null) 'current_segment_id': currentSegmentId,
      if (phasePlannedSeconds != null)
        'phase_planned_seconds': phasePlannedSeconds,
      if (phaseStartedAtUtc != null) 'phase_started_at_utc': phaseStartedAtUtc,
      if (phaseAccumulatedSeconds != null)
        'phase_accumulated_seconds': phaseAccumulatedSeconds,
      if (currentCycle != null) 'current_cycle': currentCycle,
      if (monotonicAnchorMicros != null)
        'monotonic_anchor_micros': monotonicAnchorMicros,
      if (wallClockAnchorUtc != null)
        'wall_clock_anchor_utc': wallClockAnchorUtc,
      if (lastHeartbeatUtc != null) 'last_heartbeat_utc': lastHeartbeatUtc,
      if (lastCheckpointAtUtc != null)
        'last_checkpoint_at_utc': lastCheckpointAtUtc,
      if (recoveryReason != null) 'recovery_reason': recoveryReason,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
    });
  }

  TimerRuntimeCompanion copyWith({
    Value<int>? singletonId,
    Value<String?>? sessionId,
    Value<String>? machineState,
    Value<String?>? currentSegmentId,
    Value<int?>? phasePlannedSeconds,
    Value<int?>? phaseStartedAtUtc,
    Value<int>? phaseAccumulatedSeconds,
    Value<int>? currentCycle,
    Value<int?>? monotonicAnchorMicros,
    Value<int?>? wallClockAnchorUtc,
    Value<int?>? lastHeartbeatUtc,
    Value<int?>? lastCheckpointAtUtc,
    Value<String?>? recoveryReason,
    Value<int>? updatedAtUtc,
  }) {
    return TimerRuntimeCompanion(
      singletonId: singletonId ?? this.singletonId,
      sessionId: sessionId ?? this.sessionId,
      machineState: machineState ?? this.machineState,
      currentSegmentId: currentSegmentId ?? this.currentSegmentId,
      phasePlannedSeconds: phasePlannedSeconds ?? this.phasePlannedSeconds,
      phaseStartedAtUtc: phaseStartedAtUtc ?? this.phaseStartedAtUtc,
      phaseAccumulatedSeconds:
          phaseAccumulatedSeconds ?? this.phaseAccumulatedSeconds,
      currentCycle: currentCycle ?? this.currentCycle,
      monotonicAnchorMicros:
          monotonicAnchorMicros ?? this.monotonicAnchorMicros,
      wallClockAnchorUtc: wallClockAnchorUtc ?? this.wallClockAnchorUtc,
      lastHeartbeatUtc: lastHeartbeatUtc ?? this.lastHeartbeatUtc,
      lastCheckpointAtUtc: lastCheckpointAtUtc ?? this.lastCheckpointAtUtc,
      recoveryReason: recoveryReason ?? this.recoveryReason,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singletonId.present) {
      map['singleton_id'] = Variable<int>(singletonId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (machineState.present) {
      map['machine_state'] = Variable<String>(machineState.value);
    }
    if (currentSegmentId.present) {
      map['current_segment_id'] = Variable<String>(currentSegmentId.value);
    }
    if (phasePlannedSeconds.present) {
      map['phase_planned_seconds'] = Variable<int>(phasePlannedSeconds.value);
    }
    if (phaseStartedAtUtc.present) {
      map['phase_started_at_utc'] = Variable<int>(phaseStartedAtUtc.value);
    }
    if (phaseAccumulatedSeconds.present) {
      map['phase_accumulated_seconds'] = Variable<int>(
        phaseAccumulatedSeconds.value,
      );
    }
    if (currentCycle.present) {
      map['current_cycle'] = Variable<int>(currentCycle.value);
    }
    if (monotonicAnchorMicros.present) {
      map['monotonic_anchor_micros'] = Variable<int>(
        monotonicAnchorMicros.value,
      );
    }
    if (wallClockAnchorUtc.present) {
      map['wall_clock_anchor_utc'] = Variable<int>(wallClockAnchorUtc.value);
    }
    if (lastHeartbeatUtc.present) {
      map['last_heartbeat_utc'] = Variable<int>(lastHeartbeatUtc.value);
    }
    if (lastCheckpointAtUtc.present) {
      map['last_checkpoint_at_utc'] = Variable<int>(lastCheckpointAtUtc.value);
    }
    if (recoveryReason.present) {
      map['recovery_reason'] = Variable<String>(recoveryReason.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<int>(updatedAtUtc.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimerRuntimeCompanion(')
          ..write('singletonId: $singletonId, ')
          ..write('sessionId: $sessionId, ')
          ..write('machineState: $machineState, ')
          ..write('currentSegmentId: $currentSegmentId, ')
          ..write('phasePlannedSeconds: $phasePlannedSeconds, ')
          ..write('phaseStartedAtUtc: $phaseStartedAtUtc, ')
          ..write('phaseAccumulatedSeconds: $phaseAccumulatedSeconds, ')
          ..write('currentCycle: $currentCycle, ')
          ..write('monotonicAnchorMicros: $monotonicAnchorMicros, ')
          ..write('wallClockAnchorUtc: $wallClockAnchorUtc, ')
          ..write('lastHeartbeatUtc: $lastHeartbeatUtc, ')
          ..write('lastCheckpointAtUtc: $lastCheckpointAtUtc, ')
          ..write('recoveryReason: $recoveryReason, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<int> createdAtUtc = GeneratedColumn<int>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtc = GeneratedColumn<int>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceDeviceIdMeta = const VerificationMeta(
    'sourceDeviceId',
  );
  @override
  late final GeneratedColumn<String> sourceDeviceId = GeneratedColumn<String>(
    'source_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    normalizedName,
    createdAtUtc,
    updatedAtUtc,
    sourceDeviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    if (data.containsKey('source_device_id')) {
      context.handle(
        _sourceDeviceIdMeta,
        sourceDeviceId.isAcceptableOrUnknown(
          data['source_device_id']!,
          _sourceDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceDeviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc'],
      )!,
      sourceDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_device_id'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final String id;
  final String name;
  final String normalizedName;
  final int createdAtUtc;
  final int updatedAtUtc;
  final String sourceDeviceId;
  const Tag({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.sourceDeviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    map['created_at_utc'] = Variable<int>(createdAtUtc);
    map['updated_at_utc'] = Variable<int>(updatedAtUtc);
    map['source_device_id'] = Variable<String>(sourceDeviceId);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      normalizedName: Value(normalizedName),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
      sourceDeviceId: Value(sourceDeviceId),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      createdAtUtc: serializer.fromJson<int>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<int>(json['updatedAtUtc']),
      sourceDeviceId: serializer.fromJson<String>(json['sourceDeviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'createdAtUtc': serializer.toJson<int>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<int>(updatedAtUtc),
      'sourceDeviceId': serializer.toJson<String>(sourceDeviceId),
    };
  }

  Tag copyWith({
    String? id,
    String? name,
    String? normalizedName,
    int? createdAtUtc,
    int? updatedAtUtc,
    String? sourceDeviceId,
  }) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    normalizedName: normalizedName ?? this.normalizedName,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
      sourceDeviceId: data.sourceDeviceId.present
          ? data.sourceDeviceId.value
          : this.sourceDeviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('sourceDeviceId: $sourceDeviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    normalizedName,
    createdAtUtc,
    updatedAtUtc,
    sourceDeviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc &&
          other.sourceDeviceId == this.sourceDeviceId);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<int> createdAtUtc;
  final Value<int> updatedAtUtc;
  final Value<String> sourceDeviceId;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.sourceDeviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    required String normalizedName,
    required int createdAtUtc,
    required int updatedAtUtc,
    required String sourceDeviceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       normalizedName = Value(normalizedName),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc),
       sourceDeviceId = Value(sourceDeviceId);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<int>? createdAtUtc,
    Expression<int>? updatedAtUtc,
    Expression<String>? sourceDeviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (sourceDeviceId != null) 'source_device_id': sourceDeviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? normalizedName,
    Value<int>? createdAtUtc,
    Value<int>? updatedAtUtc,
    Value<String>? sourceDeviceId,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<int>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<int>(updatedAtUtc.value);
    }
    if (sourceDeviceId.present) {
      map['source_device_id'] = Variable<String>(sourceDeviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('sourceDeviceId: $sourceDeviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionTagsTable extends SessionTags
    with TableInfo<$SessionTagsTable, SessionTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [sessionId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, tagId};
  @override
  SessionTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionTag(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $SessionTagsTable createAlias(String alias) {
    return $SessionTagsTable(attachedDatabase, alias);
  }
}

class SessionTag extends DataClass implements Insertable<SessionTag> {
  final String sessionId;
  final String tagId;
  const SessionTag({required this.sessionId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  SessionTagsCompanion toCompanion(bool nullToAbsent) {
    return SessionTagsCompanion(
      sessionId: Value(sessionId),
      tagId: Value(tagId),
    );
  }

  factory SessionTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionTag(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  SessionTag copyWith({String? sessionId, String? tagId}) => SessionTag(
    sessionId: sessionId ?? this.sessionId,
    tagId: tagId ?? this.tagId,
  );
  SessionTag copyWithCompanion(SessionTagsCompanion data) {
    return SessionTag(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionTag(')
          ..write('sessionId: $sessionId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionTag &&
          other.sessionId == this.sessionId &&
          other.tagId == this.tagId);
}

class SessionTagsCompanion extends UpdateCompanion<SessionTag> {
  final Value<String> sessionId;
  final Value<String> tagId;
  final Value<int> rowid;
  const SessionTagsCompanion({
    this.sessionId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionTagsCompanion.insert({
    required String sessionId,
    required String tagId,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       tagId = Value(tagId);
  static Insertable<SessionTag> custom({
    Expression<String>? sessionId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionTagsCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? tagId,
    Value<int>? rowid,
  }) {
    return SessionTagsCompanion(
      sessionId: sessionId ?? this.sessionId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionTagsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtc = GeneratedColumn<int>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceDeviceIdMeta = const VerificationMeta(
    'sourceDeviceId',
  );
  @override
  late final GeneratedColumn<String> sourceDeviceId = GeneratedColumn<String>(
    'source_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    valueJson,
    updatedAtUtc,
    sourceDeviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    if (data.containsKey('source_device_id')) {
      context.handle(
        _sourceDeviceIdMeta,
        sourceDeviceId.isAcceptableOrUnknown(
          data['source_device_id']!,
          _sourceDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceDeviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc'],
      )!,
      sourceDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_device_id'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String valueJson;
  final int updatedAtUtc;
  final String sourceDeviceId;
  const AppSetting({
    required this.key,
    required this.valueJson,
    required this.updatedAtUtc,
    required this.sourceDeviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value_json'] = Variable<String>(valueJson);
    map['updated_at_utc'] = Variable<int>(updatedAtUtc);
    map['source_device_id'] = Variable<String>(sourceDeviceId);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      valueJson: Value(valueJson),
      updatedAtUtc: Value(updatedAtUtc),
      sourceDeviceId: Value(sourceDeviceId),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
      updatedAtUtc: serializer.fromJson<int>(json['updatedAtUtc']),
      sourceDeviceId: serializer.fromJson<String>(json['sourceDeviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'valueJson': serializer.toJson<String>(valueJson),
      'updatedAtUtc': serializer.toJson<int>(updatedAtUtc),
      'sourceDeviceId': serializer.toJson<String>(sourceDeviceId),
    };
  }

  AppSetting copyWith({
    String? key,
    String? valueJson,
    int? updatedAtUtc,
    String? sourceDeviceId,
  }) => AppSetting(
    key: key ?? this.key,
    valueJson: valueJson ?? this.valueJson,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
      sourceDeviceId: data.sourceDeviceId.present
          ? data.sourceDeviceId.value
          : this.sourceDeviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('sourceDeviceId: $sourceDeviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, valueJson, updatedAtUtc, sourceDeviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.valueJson == this.valueJson &&
          other.updatedAtUtc == this.updatedAtUtc &&
          other.sourceDeviceId == this.sourceDeviceId);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> valueJson;
  final Value<int> updatedAtUtc;
  final Value<String> sourceDeviceId;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.sourceDeviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String valueJson,
    required int updatedAtUtc,
    required String sourceDeviceId,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       valueJson = Value(valueJson),
       updatedAtUtc = Value(updatedAtUtc),
       sourceDeviceId = Value(sourceDeviceId);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? valueJson,
    Expression<int>? updatedAtUtc,
    Expression<String>? sourceDeviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (valueJson != null) 'value_json': valueJson,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (sourceDeviceId != null) 'source_device_id': sourceDeviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? valueJson,
    Value<int>? updatedAtUtc,
    Value<String>? sourceDeviceId,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      valueJson: valueJson ?? this.valueJson,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<int>(updatedAtUtc.value);
    }
    if (sourceDeviceId.present) {
      map['source_device_id'] = Variable<String>(sourceDeviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('sourceDeviceId: $sourceDeviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BackupHistoryTable extends BackupHistory
    with TableInfo<$BackupHistoryTable, BackupHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BackupHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backupTypeMeta = const VerificationMeta(
    'backupType',
  );
  @override
  late final GeneratedColumn<String> backupType = GeneratedColumn<String>(
    'backup_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationDisplayMeta =
      const VerificationMeta('destinationDisplay');
  @override
  late final GeneratedColumn<String> destinationDisplay =
      GeneratedColumn<String>(
        'destination_display',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<int> createdAtUtc = GeneratedColumn<int>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verifiedAtUtcMeta = const VerificationMeta(
    'verifiedAtUtc',
  );
  @override
  late final GeneratedColumn<int> verifiedAtUtc = GeneratedColumn<int>(
    'verified_at_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionHighWatermarkUtcMeta =
      const VerificationMeta('sessionHighWatermarkUtc');
  @override
  late final GeneratedColumn<int> sessionHighWatermarkUtc =
      GeneratedColumn<int>(
        'session_high_watermark_utc',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _skillsCountMeta = const VerificationMeta(
    'skillsCount',
  );
  @override
  late final GeneratedColumn<int> skillsCount = GeneratedColumn<int>(
    'skills_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sessionsCountMeta = const VerificationMeta(
    'sessionsCount',
  );
  @override
  late final GeneratedColumn<int> sessionsCount = GeneratedColumn<int>(
    'sessions_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalActiveSecondsMeta =
      const VerificationMeta('totalActiveSeconds');
  @override
  late final GeneratedColumn<int> totalActiveSeconds = GeneratedColumn<int>(
    'total_active_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fileSha256Meta = const VerificationMeta(
    'fileSha256',
  );
  @override
  late final GeneratedColumn<String> fileSha256 = GeneratedColumn<String>(
    'file_sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    backupType,
    destinationDisplay,
    createdAtUtc,
    verifiedAtUtc,
    sessionHighWatermarkUtc,
    skillsCount,
    sessionsCount,
    totalActiveSeconds,
    fileSha256,
    status,
    errorCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'backup_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<BackupHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('backup_type')) {
      context.handle(
        _backupTypeMeta,
        backupType.isAcceptableOrUnknown(data['backup_type']!, _backupTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_backupTypeMeta);
    }
    if (data.containsKey('destination_display')) {
      context.handle(
        _destinationDisplayMeta,
        destinationDisplay.isAcceptableOrUnknown(
          data['destination_display']!,
          _destinationDisplayMeta,
        ),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('verified_at_utc')) {
      context.handle(
        _verifiedAtUtcMeta,
        verifiedAtUtc.isAcceptableOrUnknown(
          data['verified_at_utc']!,
          _verifiedAtUtcMeta,
        ),
      );
    }
    if (data.containsKey('session_high_watermark_utc')) {
      context.handle(
        _sessionHighWatermarkUtcMeta,
        sessionHighWatermarkUtc.isAcceptableOrUnknown(
          data['session_high_watermark_utc']!,
          _sessionHighWatermarkUtcMeta,
        ),
      );
    }
    if (data.containsKey('skills_count')) {
      context.handle(
        _skillsCountMeta,
        skillsCount.isAcceptableOrUnknown(
          data['skills_count']!,
          _skillsCountMeta,
        ),
      );
    }
    if (data.containsKey('sessions_count')) {
      context.handle(
        _sessionsCountMeta,
        sessionsCount.isAcceptableOrUnknown(
          data['sessions_count']!,
          _sessionsCountMeta,
        ),
      );
    }
    if (data.containsKey('total_active_seconds')) {
      context.handle(
        _totalActiveSecondsMeta,
        totalActiveSeconds.isAcceptableOrUnknown(
          data['total_active_seconds']!,
          _totalActiveSecondsMeta,
        ),
      );
    }
    if (data.containsKey('file_sha256')) {
      context.handle(
        _fileSha256Meta,
        fileSha256.isAcceptableOrUnknown(data['file_sha256']!, _fileSha256Meta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BackupHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BackupHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      backupType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backup_type'],
      )!,
      destinationDisplay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_display'],
      ),
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc'],
      )!,
      verifiedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verified_at_utc'],
      ),
      sessionHighWatermarkUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_high_watermark_utc'],
      ),
      skillsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skills_count'],
      )!,
      sessionsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sessions_count'],
      )!,
      totalActiveSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_active_seconds'],
      )!,
      fileSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_sha256'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
    );
  }

  @override
  $BackupHistoryTable createAlias(String alias) {
    return $BackupHistoryTable(attachedDatabase, alias);
  }
}

class BackupHistoryData extends DataClass
    implements Insertable<BackupHistoryData> {
  final String id;
  final String backupType;
  final String? destinationDisplay;
  final int createdAtUtc;
  final int? verifiedAtUtc;
  final int? sessionHighWatermarkUtc;
  final int skillsCount;
  final int sessionsCount;
  final int totalActiveSeconds;
  final String? fileSha256;
  final String status;
  final String? errorCode;
  const BackupHistoryData({
    required this.id,
    required this.backupType,
    this.destinationDisplay,
    required this.createdAtUtc,
    this.verifiedAtUtc,
    this.sessionHighWatermarkUtc,
    required this.skillsCount,
    required this.sessionsCount,
    required this.totalActiveSeconds,
    this.fileSha256,
    required this.status,
    this.errorCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['backup_type'] = Variable<String>(backupType);
    if (!nullToAbsent || destinationDisplay != null) {
      map['destination_display'] = Variable<String>(destinationDisplay);
    }
    map['created_at_utc'] = Variable<int>(createdAtUtc);
    if (!nullToAbsent || verifiedAtUtc != null) {
      map['verified_at_utc'] = Variable<int>(verifiedAtUtc);
    }
    if (!nullToAbsent || sessionHighWatermarkUtc != null) {
      map['session_high_watermark_utc'] = Variable<int>(
        sessionHighWatermarkUtc,
      );
    }
    map['skills_count'] = Variable<int>(skillsCount);
    map['sessions_count'] = Variable<int>(sessionsCount);
    map['total_active_seconds'] = Variable<int>(totalActiveSeconds);
    if (!nullToAbsent || fileSha256 != null) {
      map['file_sha256'] = Variable<String>(fileSha256);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    return map;
  }

  BackupHistoryCompanion toCompanion(bool nullToAbsent) {
    return BackupHistoryCompanion(
      id: Value(id),
      backupType: Value(backupType),
      destinationDisplay: destinationDisplay == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationDisplay),
      createdAtUtc: Value(createdAtUtc),
      verifiedAtUtc: verifiedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAtUtc),
      sessionHighWatermarkUtc: sessionHighWatermarkUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionHighWatermarkUtc),
      skillsCount: Value(skillsCount),
      sessionsCount: Value(sessionsCount),
      totalActiveSeconds: Value(totalActiveSeconds),
      fileSha256: fileSha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSha256),
      status: Value(status),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
    );
  }

  factory BackupHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BackupHistoryData(
      id: serializer.fromJson<String>(json['id']),
      backupType: serializer.fromJson<String>(json['backupType']),
      destinationDisplay: serializer.fromJson<String?>(
        json['destinationDisplay'],
      ),
      createdAtUtc: serializer.fromJson<int>(json['createdAtUtc']),
      verifiedAtUtc: serializer.fromJson<int?>(json['verifiedAtUtc']),
      sessionHighWatermarkUtc: serializer.fromJson<int?>(
        json['sessionHighWatermarkUtc'],
      ),
      skillsCount: serializer.fromJson<int>(json['skillsCount']),
      sessionsCount: serializer.fromJson<int>(json['sessionsCount']),
      totalActiveSeconds: serializer.fromJson<int>(json['totalActiveSeconds']),
      fileSha256: serializer.fromJson<String?>(json['fileSha256']),
      status: serializer.fromJson<String>(json['status']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'backupType': serializer.toJson<String>(backupType),
      'destinationDisplay': serializer.toJson<String?>(destinationDisplay),
      'createdAtUtc': serializer.toJson<int>(createdAtUtc),
      'verifiedAtUtc': serializer.toJson<int?>(verifiedAtUtc),
      'sessionHighWatermarkUtc': serializer.toJson<int?>(
        sessionHighWatermarkUtc,
      ),
      'skillsCount': serializer.toJson<int>(skillsCount),
      'sessionsCount': serializer.toJson<int>(sessionsCount),
      'totalActiveSeconds': serializer.toJson<int>(totalActiveSeconds),
      'fileSha256': serializer.toJson<String?>(fileSha256),
      'status': serializer.toJson<String>(status),
      'errorCode': serializer.toJson<String?>(errorCode),
    };
  }

  BackupHistoryData copyWith({
    String? id,
    String? backupType,
    Value<String?> destinationDisplay = const Value.absent(),
    int? createdAtUtc,
    Value<int?> verifiedAtUtc = const Value.absent(),
    Value<int?> sessionHighWatermarkUtc = const Value.absent(),
    int? skillsCount,
    int? sessionsCount,
    int? totalActiveSeconds,
    Value<String?> fileSha256 = const Value.absent(),
    String? status,
    Value<String?> errorCode = const Value.absent(),
  }) => BackupHistoryData(
    id: id ?? this.id,
    backupType: backupType ?? this.backupType,
    destinationDisplay: destinationDisplay.present
        ? destinationDisplay.value
        : this.destinationDisplay,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    verifiedAtUtc: verifiedAtUtc.present
        ? verifiedAtUtc.value
        : this.verifiedAtUtc,
    sessionHighWatermarkUtc: sessionHighWatermarkUtc.present
        ? sessionHighWatermarkUtc.value
        : this.sessionHighWatermarkUtc,
    skillsCount: skillsCount ?? this.skillsCount,
    sessionsCount: sessionsCount ?? this.sessionsCount,
    totalActiveSeconds: totalActiveSeconds ?? this.totalActiveSeconds,
    fileSha256: fileSha256.present ? fileSha256.value : this.fileSha256,
    status: status ?? this.status,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
  );
  BackupHistoryData copyWithCompanion(BackupHistoryCompanion data) {
    return BackupHistoryData(
      id: data.id.present ? data.id.value : this.id,
      backupType: data.backupType.present
          ? data.backupType.value
          : this.backupType,
      destinationDisplay: data.destinationDisplay.present
          ? data.destinationDisplay.value
          : this.destinationDisplay,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      verifiedAtUtc: data.verifiedAtUtc.present
          ? data.verifiedAtUtc.value
          : this.verifiedAtUtc,
      sessionHighWatermarkUtc: data.sessionHighWatermarkUtc.present
          ? data.sessionHighWatermarkUtc.value
          : this.sessionHighWatermarkUtc,
      skillsCount: data.skillsCount.present
          ? data.skillsCount.value
          : this.skillsCount,
      sessionsCount: data.sessionsCount.present
          ? data.sessionsCount.value
          : this.sessionsCount,
      totalActiveSeconds: data.totalActiveSeconds.present
          ? data.totalActiveSeconds.value
          : this.totalActiveSeconds,
      fileSha256: data.fileSha256.present
          ? data.fileSha256.value
          : this.fileSha256,
      status: data.status.present ? data.status.value : this.status,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BackupHistoryData(')
          ..write('id: $id, ')
          ..write('backupType: $backupType, ')
          ..write('destinationDisplay: $destinationDisplay, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('verifiedAtUtc: $verifiedAtUtc, ')
          ..write('sessionHighWatermarkUtc: $sessionHighWatermarkUtc, ')
          ..write('skillsCount: $skillsCount, ')
          ..write('sessionsCount: $sessionsCount, ')
          ..write('totalActiveSeconds: $totalActiveSeconds, ')
          ..write('fileSha256: $fileSha256, ')
          ..write('status: $status, ')
          ..write('errorCode: $errorCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    backupType,
    destinationDisplay,
    createdAtUtc,
    verifiedAtUtc,
    sessionHighWatermarkUtc,
    skillsCount,
    sessionsCount,
    totalActiveSeconds,
    fileSha256,
    status,
    errorCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BackupHistoryData &&
          other.id == this.id &&
          other.backupType == this.backupType &&
          other.destinationDisplay == this.destinationDisplay &&
          other.createdAtUtc == this.createdAtUtc &&
          other.verifiedAtUtc == this.verifiedAtUtc &&
          other.sessionHighWatermarkUtc == this.sessionHighWatermarkUtc &&
          other.skillsCount == this.skillsCount &&
          other.sessionsCount == this.sessionsCount &&
          other.totalActiveSeconds == this.totalActiveSeconds &&
          other.fileSha256 == this.fileSha256 &&
          other.status == this.status &&
          other.errorCode == this.errorCode);
}

class BackupHistoryCompanion extends UpdateCompanion<BackupHistoryData> {
  final Value<String> id;
  final Value<String> backupType;
  final Value<String?> destinationDisplay;
  final Value<int> createdAtUtc;
  final Value<int?> verifiedAtUtc;
  final Value<int?> sessionHighWatermarkUtc;
  final Value<int> skillsCount;
  final Value<int> sessionsCount;
  final Value<int> totalActiveSeconds;
  final Value<String?> fileSha256;
  final Value<String> status;
  final Value<String?> errorCode;
  final Value<int> rowid;
  const BackupHistoryCompanion({
    this.id = const Value.absent(),
    this.backupType = const Value.absent(),
    this.destinationDisplay = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.verifiedAtUtc = const Value.absent(),
    this.sessionHighWatermarkUtc = const Value.absent(),
    this.skillsCount = const Value.absent(),
    this.sessionsCount = const Value.absent(),
    this.totalActiveSeconds = const Value.absent(),
    this.fileSha256 = const Value.absent(),
    this.status = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BackupHistoryCompanion.insert({
    required String id,
    required String backupType,
    this.destinationDisplay = const Value.absent(),
    required int createdAtUtc,
    this.verifiedAtUtc = const Value.absent(),
    this.sessionHighWatermarkUtc = const Value.absent(),
    this.skillsCount = const Value.absent(),
    this.sessionsCount = const Value.absent(),
    this.totalActiveSeconds = const Value.absent(),
    this.fileSha256 = const Value.absent(),
    required String status,
    this.errorCode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       backupType = Value(backupType),
       createdAtUtc = Value(createdAtUtc),
       status = Value(status);
  static Insertable<BackupHistoryData> custom({
    Expression<String>? id,
    Expression<String>? backupType,
    Expression<String>? destinationDisplay,
    Expression<int>? createdAtUtc,
    Expression<int>? verifiedAtUtc,
    Expression<int>? sessionHighWatermarkUtc,
    Expression<int>? skillsCount,
    Expression<int>? sessionsCount,
    Expression<int>? totalActiveSeconds,
    Expression<String>? fileSha256,
    Expression<String>? status,
    Expression<String>? errorCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (backupType != null) 'backup_type': backupType,
      if (destinationDisplay != null) 'destination_display': destinationDisplay,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (verifiedAtUtc != null) 'verified_at_utc': verifiedAtUtc,
      if (sessionHighWatermarkUtc != null)
        'session_high_watermark_utc': sessionHighWatermarkUtc,
      if (skillsCount != null) 'skills_count': skillsCount,
      if (sessionsCount != null) 'sessions_count': sessionsCount,
      if (totalActiveSeconds != null)
        'total_active_seconds': totalActiveSeconds,
      if (fileSha256 != null) 'file_sha256': fileSha256,
      if (status != null) 'status': status,
      if (errorCode != null) 'error_code': errorCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BackupHistoryCompanion copyWith({
    Value<String>? id,
    Value<String>? backupType,
    Value<String?>? destinationDisplay,
    Value<int>? createdAtUtc,
    Value<int?>? verifiedAtUtc,
    Value<int?>? sessionHighWatermarkUtc,
    Value<int>? skillsCount,
    Value<int>? sessionsCount,
    Value<int>? totalActiveSeconds,
    Value<String?>? fileSha256,
    Value<String>? status,
    Value<String?>? errorCode,
    Value<int>? rowid,
  }) {
    return BackupHistoryCompanion(
      id: id ?? this.id,
      backupType: backupType ?? this.backupType,
      destinationDisplay: destinationDisplay ?? this.destinationDisplay,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      verifiedAtUtc: verifiedAtUtc ?? this.verifiedAtUtc,
      sessionHighWatermarkUtc:
          sessionHighWatermarkUtc ?? this.sessionHighWatermarkUtc,
      skillsCount: skillsCount ?? this.skillsCount,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      totalActiveSeconds: totalActiveSeconds ?? this.totalActiveSeconds,
      fileSha256: fileSha256 ?? this.fileSha256,
      status: status ?? this.status,
      errorCode: errorCode ?? this.errorCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (backupType.present) {
      map['backup_type'] = Variable<String>(backupType.value);
    }
    if (destinationDisplay.present) {
      map['destination_display'] = Variable<String>(destinationDisplay.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<int>(createdAtUtc.value);
    }
    if (verifiedAtUtc.present) {
      map['verified_at_utc'] = Variable<int>(verifiedAtUtc.value);
    }
    if (sessionHighWatermarkUtc.present) {
      map['session_high_watermark_utc'] = Variable<int>(
        sessionHighWatermarkUtc.value,
      );
    }
    if (skillsCount.present) {
      map['skills_count'] = Variable<int>(skillsCount.value);
    }
    if (sessionsCount.present) {
      map['sessions_count'] = Variable<int>(sessionsCount.value);
    }
    if (totalActiveSeconds.present) {
      map['total_active_seconds'] = Variable<int>(totalActiveSeconds.value);
    }
    if (fileSha256.present) {
      map['file_sha256'] = Variable<String>(fileSha256.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BackupHistoryCompanion(')
          ..write('id: $id, ')
          ..write('backupType: $backupType, ')
          ..write('destinationDisplay: $destinationDisplay, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('verifiedAtUtc: $verifiedAtUtc, ')
          ..write('sessionHighWatermarkUtc: $sessionHighWatermarkUtc, ')
          ..write('skillsCount: $skillsCount, ')
          ..write('sessionsCount: $sessionsCount, ')
          ..write('totalActiveSeconds: $totalActiveSeconds, ')
          ..write('fileSha256: $fileSha256, ')
          ..write('status: $status, ')
          ..write('errorCode: $errorCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSnapshotsTable extends LocalSnapshots
    with TableInfo<$LocalSnapshotsTable, LocalSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<int> createdAtUtc = GeneratedColumn<int>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSha256Meta = const VerificationMeta(
    'fileSha256',
  );
  @override
  late final GeneratedColumn<String> fileSha256 = GeneratedColumn<String>(
    'file_sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isValidMeta = const VerificationMeta(
    'isValid',
  );
  @override
  late final GeneratedColumn<int> isValid = GeneratedColumn<int>(
    'is_valid',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    filePath,
    reason,
    createdAtUtc,
    schemaVersion,
    fileSha256,
    sizeBytes,
    isValid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_schemaVersionMeta);
    }
    if (data.containsKey('file_sha256')) {
      context.handle(
        _fileSha256Meta,
        fileSha256.isAcceptableOrUnknown(data['file_sha256']!, _fileSha256Meta),
      );
    } else if (isInserting) {
      context.missing(_fileSha256Meta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('is_valid')) {
      context.handle(
        _isValidMeta,
        isValid.isAcceptableOrUnknown(data['is_valid']!, _isValidMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      fileSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_sha256'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      isValid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_valid'],
      )!,
    );
  }

  @override
  $LocalSnapshotsTable createAlias(String alias) {
    return $LocalSnapshotsTable(attachedDatabase, alias);
  }
}

class LocalSnapshot extends DataClass implements Insertable<LocalSnapshot> {
  final String id;
  final String filePath;
  final String reason;
  final int createdAtUtc;
  final int schemaVersion;
  final String fileSha256;
  final int sizeBytes;
  final int isValid;
  const LocalSnapshot({
    required this.id,
    required this.filePath,
    required this.reason,
    required this.createdAtUtc,
    required this.schemaVersion,
    required this.fileSha256,
    required this.sizeBytes,
    required this.isValid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['file_path'] = Variable<String>(filePath);
    map['reason'] = Variable<String>(reason);
    map['created_at_utc'] = Variable<int>(createdAtUtc);
    map['schema_version'] = Variable<int>(schemaVersion);
    map['file_sha256'] = Variable<String>(fileSha256);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['is_valid'] = Variable<int>(isValid);
    return map;
  }

  LocalSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return LocalSnapshotsCompanion(
      id: Value(id),
      filePath: Value(filePath),
      reason: Value(reason),
      createdAtUtc: Value(createdAtUtc),
      schemaVersion: Value(schemaVersion),
      fileSha256: Value(fileSha256),
      sizeBytes: Value(sizeBytes),
      isValid: Value(isValid),
    );
  }

  factory LocalSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSnapshot(
      id: serializer.fromJson<String>(json['id']),
      filePath: serializer.fromJson<String>(json['filePath']),
      reason: serializer.fromJson<String>(json['reason']),
      createdAtUtc: serializer.fromJson<int>(json['createdAtUtc']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      fileSha256: serializer.fromJson<String>(json['fileSha256']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      isValid: serializer.fromJson<int>(json['isValid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'filePath': serializer.toJson<String>(filePath),
      'reason': serializer.toJson<String>(reason),
      'createdAtUtc': serializer.toJson<int>(createdAtUtc),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'fileSha256': serializer.toJson<String>(fileSha256),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'isValid': serializer.toJson<int>(isValid),
    };
  }

  LocalSnapshot copyWith({
    String? id,
    String? filePath,
    String? reason,
    int? createdAtUtc,
    int? schemaVersion,
    String? fileSha256,
    int? sizeBytes,
    int? isValid,
  }) => LocalSnapshot(
    id: id ?? this.id,
    filePath: filePath ?? this.filePath,
    reason: reason ?? this.reason,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    fileSha256: fileSha256 ?? this.fileSha256,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    isValid: isValid ?? this.isValid,
  );
  LocalSnapshot copyWithCompanion(LocalSnapshotsCompanion data) {
    return LocalSnapshot(
      id: data.id.present ? data.id.value : this.id,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      reason: data.reason.present ? data.reason.value : this.reason,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      fileSha256: data.fileSha256.present
          ? data.fileSha256.value
          : this.fileSha256,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      isValid: data.isValid.present ? data.isValid.value : this.isValid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSnapshot(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('reason: $reason, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('fileSha256: $fileSha256, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('isValid: $isValid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    filePath,
    reason,
    createdAtUtc,
    schemaVersion,
    fileSha256,
    sizeBytes,
    isValid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSnapshot &&
          other.id == this.id &&
          other.filePath == this.filePath &&
          other.reason == this.reason &&
          other.createdAtUtc == this.createdAtUtc &&
          other.schemaVersion == this.schemaVersion &&
          other.fileSha256 == this.fileSha256 &&
          other.sizeBytes == this.sizeBytes &&
          other.isValid == this.isValid);
}

class LocalSnapshotsCompanion extends UpdateCompanion<LocalSnapshot> {
  final Value<String> id;
  final Value<String> filePath;
  final Value<String> reason;
  final Value<int> createdAtUtc;
  final Value<int> schemaVersion;
  final Value<String> fileSha256;
  final Value<int> sizeBytes;
  final Value<int> isValid;
  final Value<int> rowid;
  const LocalSnapshotsCompanion({
    this.id = const Value.absent(),
    this.filePath = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.fileSha256 = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.isValid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSnapshotsCompanion.insert({
    required String id,
    required String filePath,
    required String reason,
    required int createdAtUtc,
    required int schemaVersion,
    required String fileSha256,
    required int sizeBytes,
    this.isValid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       filePath = Value(filePath),
       reason = Value(reason),
       createdAtUtc = Value(createdAtUtc),
       schemaVersion = Value(schemaVersion),
       fileSha256 = Value(fileSha256),
       sizeBytes = Value(sizeBytes);
  static Insertable<LocalSnapshot> custom({
    Expression<String>? id,
    Expression<String>? filePath,
    Expression<String>? reason,
    Expression<int>? createdAtUtc,
    Expression<int>? schemaVersion,
    Expression<String>? fileSha256,
    Expression<int>? sizeBytes,
    Expression<int>? isValid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filePath != null) 'file_path': filePath,
      if (reason != null) 'reason': reason,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (fileSha256 != null) 'file_sha256': fileSha256,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (isValid != null) 'is_valid': isValid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSnapshotsCompanion copyWith({
    Value<String>? id,
    Value<String>? filePath,
    Value<String>? reason,
    Value<int>? createdAtUtc,
    Value<int>? schemaVersion,
    Value<String>? fileSha256,
    Value<int>? sizeBytes,
    Value<int>? isValid,
    Value<int>? rowid,
  }) {
    return LocalSnapshotsCompanion(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      reason: reason ?? this.reason,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      fileSha256: fileSha256 ?? this.fileSha256,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      isValid: isValid ?? this.isValid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<int>(createdAtUtc.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (fileSha256.present) {
      map['file_sha256'] = Variable<String>(fileSha256.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (isValid.present) {
      map['is_valid'] = Variable<int>(isValid.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('reason: $reason, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('fileSha256: $fileSha256, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('isValid: $isValid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeviceIdentityTable extends DeviceIdentity
    with TableInfo<$DeviceIdentityTable, DeviceIdentityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceIdentityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<int> createdAtUtc = GeneratedColumn<int>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [deviceId, createdAtUtc, displayName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_identity';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceIdentityData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  DeviceIdentityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceIdentityData(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
    );
  }

  @override
  $DeviceIdentityTable createAlias(String alias) {
    return $DeviceIdentityTable(attachedDatabase, alias);
  }
}

class DeviceIdentityData extends DataClass
    implements Insertable<DeviceIdentityData> {
  final String deviceId;
  final int createdAtUtc;
  final String? displayName;
  const DeviceIdentityData({
    required this.deviceId,
    required this.createdAtUtc,
    this.displayName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['created_at_utc'] = Variable<int>(createdAtUtc);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    return map;
  }

  DeviceIdentityCompanion toCompanion(bool nullToAbsent) {
    return DeviceIdentityCompanion(
      deviceId: Value(deviceId),
      createdAtUtc: Value(createdAtUtc),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
    );
  }

  factory DeviceIdentityData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceIdentityData(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      createdAtUtc: serializer.fromJson<int>(json['createdAtUtc']),
      displayName: serializer.fromJson<String?>(json['displayName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'createdAtUtc': serializer.toJson<int>(createdAtUtc),
      'displayName': serializer.toJson<String?>(displayName),
    };
  }

  DeviceIdentityData copyWith({
    String? deviceId,
    int? createdAtUtc,
    Value<String?> displayName = const Value.absent(),
  }) => DeviceIdentityData(
    deviceId: deviceId ?? this.deviceId,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    displayName: displayName.present ? displayName.value : this.displayName,
  );
  DeviceIdentityData copyWithCompanion(DeviceIdentityCompanion data) {
    return DeviceIdentityData(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceIdentityData(')
          ..write('deviceId: $deviceId, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('displayName: $displayName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, createdAtUtc, displayName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceIdentityData &&
          other.deviceId == this.deviceId &&
          other.createdAtUtc == this.createdAtUtc &&
          other.displayName == this.displayName);
}

class DeviceIdentityCompanion extends UpdateCompanion<DeviceIdentityData> {
  final Value<String> deviceId;
  final Value<int> createdAtUtc;
  final Value<String?> displayName;
  final Value<int> rowid;
  const DeviceIdentityCompanion({
    this.deviceId = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.displayName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeviceIdentityCompanion.insert({
    required String deviceId,
    required int createdAtUtc,
    this.displayName = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       createdAtUtc = Value(createdAtUtc);
  static Insertable<DeviceIdentityData> custom({
    Expression<String>? deviceId,
    Expression<int>? createdAtUtc,
    Expression<String>? displayName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (displayName != null) 'display_name': displayName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeviceIdentityCompanion copyWith({
    Value<String>? deviceId,
    Value<int>? createdAtUtc,
    Value<String?>? displayName,
    Value<int>? rowid,
  }) {
    return DeviceIdentityCompanion(
      deviceId: deviceId ?? this.deviceId,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      displayName: displayName ?? this.displayName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<int>(createdAtUtc.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceIdentityCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('displayName: $displayName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SchemaMetadataTable extends SchemaMetadata
    with TableInfo<$SchemaMetadataTable, SchemaMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchemaMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schema_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<SchemaMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SchemaMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchemaMetadataData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SchemaMetadataTable createAlias(String alias) {
    return $SchemaMetadataTable(attachedDatabase, alias);
  }
}

class SchemaMetadataData extends DataClass
    implements Insertable<SchemaMetadataData> {
  final String key;
  final String value;
  const SchemaMetadataData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SchemaMetadataCompanion toCompanion(bool nullToAbsent) {
    return SchemaMetadataCompanion(key: Value(key), value: Value(value));
  }

  factory SchemaMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchemaMetadataData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SchemaMetadataData copyWith({String? key, String? value}) =>
      SchemaMetadataData(key: key ?? this.key, value: value ?? this.value);
  SchemaMetadataData copyWithCompanion(SchemaMetadataCompanion data) {
    return SchemaMetadataData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SchemaMetadataData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchemaMetadataData &&
          other.key == this.key &&
          other.value == this.value);
}

class SchemaMetadataCompanion extends UpdateCompanion<SchemaMetadataData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SchemaMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchemaMetadataCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SchemaMetadataData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SchemaMetadataCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SchemaMetadataCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchemaMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SkillsTable skills = $SkillsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SessionSegmentsTable sessionSegments = $SessionSegmentsTable(
    this,
  );
  late final $TimerRuntimeTable timerRuntime = $TimerRuntimeTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $SessionTagsTable sessionTags = $SessionTagsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $BackupHistoryTable backupHistory = $BackupHistoryTable(this);
  late final $LocalSnapshotsTable localSnapshots = $LocalSnapshotsTable(this);
  late final $DeviceIdentityTable deviceIdentity = $DeviceIdentityTable(this);
  late final $SchemaMetadataTable schemaMetadata = $SchemaMetadataTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    skills,
    sessions,
    sessionSegments,
    timerRuntime,
    tags,
    sessionTags,
    appSettings,
    backupHistory,
    localSnapshots,
    deviceIdentity,
    schemaMetadata,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('session_segments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('session_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('session_tags', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SkillsTableCreateCompanionBuilder =
    SkillsCompanion Function({
      required String id,
      required String name,
      Value<String?> descriptionMarkdown,
      Value<int> targetSeconds,
      required String createdLocalDate,
      Value<int?> accentArgb,
      Value<String> status,
      Value<int> sortOrder,
      required int createdAtUtc,
      required int updatedAtUtc,
      required String sourceDeviceId,
      Value<int?> deletedAtUtc,
      Value<int> rowid,
    });
typedef $$SkillsTableUpdateCompanionBuilder =
    SkillsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> descriptionMarkdown,
      Value<int> targetSeconds,
      Value<String> createdLocalDate,
      Value<int?> accentArgb,
      Value<String> status,
      Value<int> sortOrder,
      Value<int> createdAtUtc,
      Value<int> updatedAtUtc,
      Value<String> sourceDeviceId,
      Value<int?> deletedAtUtc,
      Value<int> rowid,
    });

final class $$SkillsTableReferences
    extends BaseReferences<_$AppDatabase, $SkillsTable, Skill> {
  $$SkillsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionsTable, List<Session>> _sessionsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.sessions,
    aliasName: 'skills__id__sessions__skill_id',
  );

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.skillId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SkillsTableFilterComposer
    extends Composer<_$AppDatabase, $SkillsTable> {
  $$SkillsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descriptionMarkdown => $composableBuilder(
    column: $table.descriptionMarkdown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetSeconds => $composableBuilder(
    column: $table.targetSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdLocalDate => $composableBuilder(
    column: $table.createdLocalDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accentArgb => $composableBuilder(
    column: $table.accentArgb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceDeviceId => $composableBuilder(
    column: $table.sourceDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtUtc => $composableBuilder(
    column: $table.deletedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionsRefs(
    Expression<bool> Function($$SessionsTableFilterComposer f) f,
  ) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.skillId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SkillsTableOrderingComposer
    extends Composer<_$AppDatabase, $SkillsTable> {
  $$SkillsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descriptionMarkdown => $composableBuilder(
    column: $table.descriptionMarkdown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetSeconds => $composableBuilder(
    column: $table.targetSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdLocalDate => $composableBuilder(
    column: $table.createdLocalDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accentArgb => $composableBuilder(
    column: $table.accentArgb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceDeviceId => $composableBuilder(
    column: $table.sourceDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtUtc => $composableBuilder(
    column: $table.deletedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SkillsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SkillsTable> {
  $$SkillsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get descriptionMarkdown => $composableBuilder(
    column: $table.descriptionMarkdown,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetSeconds => $composableBuilder(
    column: $table.targetSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdLocalDate => $composableBuilder(
    column: $table.createdLocalDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get accentArgb => $composableBuilder(
    column: $table.accentArgb,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceDeviceId => $composableBuilder(
    column: $table.sourceDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAtUtc => $composableBuilder(
    column: $table.deletedAtUtc,
    builder: (column) => column,
  );

  Expression<T> sessionsRefs<T extends Object>(
    Expression<T> Function($$SessionsTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.skillId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SkillsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SkillsTable,
          Skill,
          $$SkillsTableFilterComposer,
          $$SkillsTableOrderingComposer,
          $$SkillsTableAnnotationComposer,
          $$SkillsTableCreateCompanionBuilder,
          $$SkillsTableUpdateCompanionBuilder,
          (Skill, $$SkillsTableReferences),
          Skill,
          PrefetchHooks Function({bool sessionsRefs})
        > {
  $$SkillsTableTableManager(_$AppDatabase db, $SkillsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SkillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SkillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SkillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> descriptionMarkdown = const Value.absent(),
                Value<int> targetSeconds = const Value.absent(),
                Value<String> createdLocalDate = const Value.absent(),
                Value<int?> accentArgb = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAtUtc = const Value.absent(),
                Value<int> updatedAtUtc = const Value.absent(),
                Value<String> sourceDeviceId = const Value.absent(),
                Value<int?> deletedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SkillsCompanion(
                id: id,
                name: name,
                descriptionMarkdown: descriptionMarkdown,
                targetSeconds: targetSeconds,
                createdLocalDate: createdLocalDate,
                accentArgb: accentArgb,
                status: status,
                sortOrder: sortOrder,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                sourceDeviceId: sourceDeviceId,
                deletedAtUtc: deletedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> descriptionMarkdown = const Value.absent(),
                Value<int> targetSeconds = const Value.absent(),
                required String createdLocalDate,
                Value<int?> accentArgb = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAtUtc,
                required int updatedAtUtc,
                required String sourceDeviceId,
                Value<int?> deletedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SkillsCompanion.insert(
                id: id,
                name: name,
                descriptionMarkdown: descriptionMarkdown,
                targetSeconds: targetSeconds,
                createdLocalDate: createdLocalDate,
                accentArgb: accentArgb,
                status: status,
                sortOrder: sortOrder,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                sourceDeviceId: sourceDeviceId,
                deletedAtUtc: deletedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SkillsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({sessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sessionsRefs) db.sessions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionsRefs)
                    await $_getPrefetchedData<Skill, $SkillsTable, Session>(
                      currentTable: table,
                      referencedTable: $$SkillsTableReferences
                          ._sessionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SkillsTableReferences(db, table, p0).sessionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.skillId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SkillsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SkillsTable,
      Skill,
      $$SkillsTableFilterComposer,
      $$SkillsTableOrderingComposer,
      $$SkillsTableAnnotationComposer,
      $$SkillsTableCreateCompanionBuilder,
      $$SkillsTableUpdateCompanionBuilder,
      (Skill, $$SkillsTableReferences),
      Skill,
      PrefetchHooks Function({bool sessionsRefs})
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String id,
      required String skillId,
      Value<String?> title,
      Value<String?> noteMarkdown,
      Value<String> mode,
      required String status,
      Value<String> source,
      required int startAtUtc,
      Value<int?> endAtUtc,
      Value<int> activeSeconds,
      Value<int> pausedSeconds,
      required String timezoneIdAtCreation,
      required int offsetMinutesAtStart,
      required int createdAtUtc,
      required int updatedAtUtc,
      required String sourceDeviceId,
      Value<int?> deletedAtUtc,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> id,
      Value<String> skillId,
      Value<String?> title,
      Value<String?> noteMarkdown,
      Value<String> mode,
      Value<String> status,
      Value<String> source,
      Value<int> startAtUtc,
      Value<int?> endAtUtc,
      Value<int> activeSeconds,
      Value<int> pausedSeconds,
      Value<String> timezoneIdAtCreation,
      Value<int> offsetMinutesAtStart,
      Value<int> createdAtUtc,
      Value<int> updatedAtUtc,
      Value<String> sourceDeviceId,
      Value<int?> deletedAtUtc,
      Value<int> rowid,
    });

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, Session> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SkillsTable _skillIdTable(_$AppDatabase db) =>
      db.skills.createAlias('sessions__skill_id__skills__id');

  $$SkillsTableProcessedTableManager get skillId {
    final $_column = $_itemColumn<String>('skill_id')!;

    final manager = $$SkillsTableTableManager(
      $_db,
      $_db.skills,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_skillIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SessionSegmentsTable, List<SessionSegment>>
  _sessionSegmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionSegments,
    aliasName: 'sessions__id__session_segments__session_id',
  );

  $$SessionSegmentsTableProcessedTableManager get sessionSegmentsRefs {
    final manager = $$SessionSegmentsTableTableManager(
      $_db,
      $_db.sessionSegments,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sessionSegmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TimerRuntimeTable, List<TimerRuntimeData>>
  _timerRuntimeRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.timerRuntime,
    aliasName: 'sessions__id__timer_runtime__session_id',
  );

  $$TimerRuntimeTableProcessedTableManager get timerRuntimeRefs {
    final manager = $$TimerRuntimeTableTableManager(
      $_db,
      $_db.timerRuntime,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_timerRuntimeRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SessionTagsTable, List<SessionTag>>
  _sessionTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionTags,
    aliasName: 'sessions__id__session_tags__session_id',
  );

  $$SessionTagsTableProcessedTableManager get sessionTagsRefs {
    final manager = $$SessionTagsTableTableManager(
      $_db,
      $_db.sessionTags,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get noteMarkdown => $composableBuilder(
    column: $table.noteMarkdown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endAtUtc => $composableBuilder(
    column: $table.endAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeSeconds => $composableBuilder(
    column: $table.activeSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pausedSeconds => $composableBuilder(
    column: $table.pausedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezoneIdAtCreation => $composableBuilder(
    column: $table.timezoneIdAtCreation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetMinutesAtStart => $composableBuilder(
    column: $table.offsetMinutesAtStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceDeviceId => $composableBuilder(
    column: $table.sourceDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtUtc => $composableBuilder(
    column: $table.deletedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$SkillsTableFilterComposer get skillId {
    final $$SkillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.skillId,
      referencedTable: $db.skills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillsTableFilterComposer(
            $db: $db,
            $table: $db.skills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> sessionSegmentsRefs(
    Expression<bool> Function($$SessionSegmentsTableFilterComposer f) f,
  ) {
    final $$SessionSegmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionSegments,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionSegmentsTableFilterComposer(
            $db: $db,
            $table: $db.sessionSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> timerRuntimeRefs(
    Expression<bool> Function($$TimerRuntimeTableFilterComposer f) f,
  ) {
    final $$TimerRuntimeTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timerRuntime,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimerRuntimeTableFilterComposer(
            $db: $db,
            $table: $db.timerRuntime,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sessionTagsRefs(
    Expression<bool> Function($$SessionTagsTableFilterComposer f) f,
  ) {
    final $$SessionTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionTags,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionTagsTableFilterComposer(
            $db: $db,
            $table: $db.sessionTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get noteMarkdown => $composableBuilder(
    column: $table.noteMarkdown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endAtUtc => $composableBuilder(
    column: $table.endAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeSeconds => $composableBuilder(
    column: $table.activeSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pausedSeconds => $composableBuilder(
    column: $table.pausedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezoneIdAtCreation => $composableBuilder(
    column: $table.timezoneIdAtCreation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetMinutesAtStart => $composableBuilder(
    column: $table.offsetMinutesAtStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceDeviceId => $composableBuilder(
    column: $table.sourceDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtUtc => $composableBuilder(
    column: $table.deletedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$SkillsTableOrderingComposer get skillId {
    final $$SkillsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.skillId,
      referencedTable: $db.skills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillsTableOrderingComposer(
            $db: $db,
            $table: $db.skills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get noteMarkdown => $composableBuilder(
    column: $table.noteMarkdown,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endAtUtc =>
      $composableBuilder(column: $table.endAtUtc, builder: (column) => column);

  GeneratedColumn<int> get activeSeconds => $composableBuilder(
    column: $table.activeSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pausedSeconds => $composableBuilder(
    column: $table.pausedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timezoneIdAtCreation => $composableBuilder(
    column: $table.timezoneIdAtCreation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offsetMinutesAtStart => $composableBuilder(
    column: $table.offsetMinutesAtStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceDeviceId => $composableBuilder(
    column: $table.sourceDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAtUtc => $composableBuilder(
    column: $table.deletedAtUtc,
    builder: (column) => column,
  );

  $$SkillsTableAnnotationComposer get skillId {
    final $$SkillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.skillId,
      referencedTable: $db.skills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SkillsTableAnnotationComposer(
            $db: $db,
            $table: $db.skills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> sessionSegmentsRefs<T extends Object>(
    Expression<T> Function($$SessionSegmentsTableAnnotationComposer a) f,
  ) {
    final $$SessionSegmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionSegments,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionSegmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> timerRuntimeRefs<T extends Object>(
    Expression<T> Function($$TimerRuntimeTableAnnotationComposer a) f,
  ) {
    final $$TimerRuntimeTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timerRuntime,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimerRuntimeTableAnnotationComposer(
            $db: $db,
            $table: $db.timerRuntime,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sessionTagsRefs<T extends Object>(
    Expression<T> Function($$SessionTagsTableAnnotationComposer a) f,
  ) {
    final $$SessionTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionTags,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, $$SessionsTableReferences),
          Session,
          PrefetchHooks Function({
            bool skillId,
            bool sessionSegmentsRefs,
            bool timerRuntimeRefs,
            bool sessionTagsRefs,
          })
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> skillId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> noteMarkdown = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> startAtUtc = const Value.absent(),
                Value<int?> endAtUtc = const Value.absent(),
                Value<int> activeSeconds = const Value.absent(),
                Value<int> pausedSeconds = const Value.absent(),
                Value<String> timezoneIdAtCreation = const Value.absent(),
                Value<int> offsetMinutesAtStart = const Value.absent(),
                Value<int> createdAtUtc = const Value.absent(),
                Value<int> updatedAtUtc = const Value.absent(),
                Value<String> sourceDeviceId = const Value.absent(),
                Value<int?> deletedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                skillId: skillId,
                title: title,
                noteMarkdown: noteMarkdown,
                mode: mode,
                status: status,
                source: source,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                activeSeconds: activeSeconds,
                pausedSeconds: pausedSeconds,
                timezoneIdAtCreation: timezoneIdAtCreation,
                offsetMinutesAtStart: offsetMinutesAtStart,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                sourceDeviceId: sourceDeviceId,
                deletedAtUtc: deletedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String skillId,
                Value<String?> title = const Value.absent(),
                Value<String?> noteMarkdown = const Value.absent(),
                Value<String> mode = const Value.absent(),
                required String status,
                Value<String> source = const Value.absent(),
                required int startAtUtc,
                Value<int?> endAtUtc = const Value.absent(),
                Value<int> activeSeconds = const Value.absent(),
                Value<int> pausedSeconds = const Value.absent(),
                required String timezoneIdAtCreation,
                required int offsetMinutesAtStart,
                required int createdAtUtc,
                required int updatedAtUtc,
                required String sourceDeviceId,
                Value<int?> deletedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                skillId: skillId,
                title: title,
                noteMarkdown: noteMarkdown,
                mode: mode,
                status: status,
                source: source,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                activeSeconds: activeSeconds,
                pausedSeconds: pausedSeconds,
                timezoneIdAtCreation: timezoneIdAtCreation,
                offsetMinutesAtStart: offsetMinutesAtStart,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                sourceDeviceId: sourceDeviceId,
                deletedAtUtc: deletedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                skillId = false,
                sessionSegmentsRefs = false,
                timerRuntimeRefs = false,
                sessionTagsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sessionSegmentsRefs) db.sessionSegments,
                    if (timerRuntimeRefs) db.timerRuntime,
                    if (sessionTagsRefs) db.sessionTags,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (skillId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.skillId,
                                    referencedTable: $$SessionsTableReferences
                                        ._skillIdTable(db),
                                    referencedColumn: $$SessionsTableReferences
                                        ._skillIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sessionSegmentsRefs)
                        await $_getPrefetchedData<
                          Session,
                          $SessionsTable,
                          SessionSegment
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._sessionSegmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionSegmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (timerRuntimeRefs)
                        await $_getPrefetchedData<
                          Session,
                          $SessionsTable,
                          TimerRuntimeData
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._timerRuntimeRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).timerRuntimeRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (sessionTagsRefs)
                        await $_getPrefetchedData<
                          Session,
                          $SessionsTable,
                          SessionTag
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._sessionTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, $$SessionsTableReferences),
      Session,
      PrefetchHooks Function({
        bool skillId,
        bool sessionSegmentsRefs,
        bool timerRuntimeRefs,
        bool sessionTagsRefs,
      })
    >;
typedef $$SessionSegmentsTableCreateCompanionBuilder =
    SessionSegmentsCompanion Function({
      required String id,
      required String sessionId,
      required String segmentType,
      Value<String?> pomodoroPhase,
      Value<int?> cycleNumber,
      required int startAtUtc,
      Value<int?> endAtUtc,
      Value<int> durationSeconds,
      required int createdAtUtc,
      required int updatedAtUtc,
      Value<int> rowid,
    });
typedef $$SessionSegmentsTableUpdateCompanionBuilder =
    SessionSegmentsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> segmentType,
      Value<String?> pomodoroPhase,
      Value<int?> cycleNumber,
      Value<int> startAtUtc,
      Value<int?> endAtUtc,
      Value<int> durationSeconds,
      Value<int> createdAtUtc,
      Value<int> updatedAtUtc,
      Value<int> rowid,
    });

final class $$SessionSegmentsTableReferences
    extends
        BaseReferences<_$AppDatabase, $SessionSegmentsTable, SessionSegment> {
  $$SessionSegmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('session_segments__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SessionSegmentsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionSegmentsTable> {
  $$SessionSegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get segmentType => $composableBuilder(
    column: $table.segmentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pomodoroPhase => $composableBuilder(
    column: $table.pomodoroPhase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cycleNumber => $composableBuilder(
    column: $table.cycleNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endAtUtc => $composableBuilder(
    column: $table.endAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionSegmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionSegmentsTable> {
  $$SessionSegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get segmentType => $composableBuilder(
    column: $table.segmentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pomodoroPhase => $composableBuilder(
    column: $table.pomodoroPhase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cycleNumber => $composableBuilder(
    column: $table.cycleNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endAtUtc => $composableBuilder(
    column: $table.endAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionSegmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionSegmentsTable> {
  $$SessionSegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get segmentType => $composableBuilder(
    column: $table.segmentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pomodoroPhase => $composableBuilder(
    column: $table.pomodoroPhase,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cycleNumber => $composableBuilder(
    column: $table.cycleNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endAtUtc =>
      $composableBuilder(column: $table.endAtUtc, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionSegmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionSegmentsTable,
          SessionSegment,
          $$SessionSegmentsTableFilterComposer,
          $$SessionSegmentsTableOrderingComposer,
          $$SessionSegmentsTableAnnotationComposer,
          $$SessionSegmentsTableCreateCompanionBuilder,
          $$SessionSegmentsTableUpdateCompanionBuilder,
          (SessionSegment, $$SessionSegmentsTableReferences),
          SessionSegment,
          PrefetchHooks Function({bool sessionId})
        > {
  $$SessionSegmentsTableTableManager(
    _$AppDatabase db,
    $SessionSegmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionSegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionSegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionSegmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> segmentType = const Value.absent(),
                Value<String?> pomodoroPhase = const Value.absent(),
                Value<int?> cycleNumber = const Value.absent(),
                Value<int> startAtUtc = const Value.absent(),
                Value<int?> endAtUtc = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<int> createdAtUtc = const Value.absent(),
                Value<int> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionSegmentsCompanion(
                id: id,
                sessionId: sessionId,
                segmentType: segmentType,
                pomodoroPhase: pomodoroPhase,
                cycleNumber: cycleNumber,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                durationSeconds: durationSeconds,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String segmentType,
                Value<String?> pomodoroPhase = const Value.absent(),
                Value<int?> cycleNumber = const Value.absent(),
                required int startAtUtc,
                Value<int?> endAtUtc = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                required int createdAtUtc,
                required int updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => SessionSegmentsCompanion.insert(
                id: id,
                sessionId: sessionId,
                segmentType: segmentType,
                pomodoroPhase: pomodoroPhase,
                cycleNumber: cycleNumber,
                startAtUtc: startAtUtc,
                endAtUtc: endAtUtc,
                durationSeconds: durationSeconds,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionSegmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable:
                                    $$SessionSegmentsTableReferences
                                        ._sessionIdTable(db),
                                referencedColumn:
                                    $$SessionSegmentsTableReferences
                                        ._sessionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SessionSegmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionSegmentsTable,
      SessionSegment,
      $$SessionSegmentsTableFilterComposer,
      $$SessionSegmentsTableOrderingComposer,
      $$SessionSegmentsTableAnnotationComposer,
      $$SessionSegmentsTableCreateCompanionBuilder,
      $$SessionSegmentsTableUpdateCompanionBuilder,
      (SessionSegment, $$SessionSegmentsTableReferences),
      SessionSegment,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$TimerRuntimeTableCreateCompanionBuilder =
    TimerRuntimeCompanion Function({
      Value<int> singletonId,
      Value<String?> sessionId,
      Value<String> machineState,
      Value<String?> currentSegmentId,
      Value<int?> phasePlannedSeconds,
      Value<int?> phaseStartedAtUtc,
      Value<int> phaseAccumulatedSeconds,
      Value<int> currentCycle,
      Value<int?> monotonicAnchorMicros,
      Value<int?> wallClockAnchorUtc,
      Value<int?> lastHeartbeatUtc,
      Value<int?> lastCheckpointAtUtc,
      Value<String?> recoveryReason,
      required int updatedAtUtc,
    });
typedef $$TimerRuntimeTableUpdateCompanionBuilder =
    TimerRuntimeCompanion Function({
      Value<int> singletonId,
      Value<String?> sessionId,
      Value<String> machineState,
      Value<String?> currentSegmentId,
      Value<int?> phasePlannedSeconds,
      Value<int?> phaseStartedAtUtc,
      Value<int> phaseAccumulatedSeconds,
      Value<int> currentCycle,
      Value<int?> monotonicAnchorMicros,
      Value<int?> wallClockAnchorUtc,
      Value<int?> lastHeartbeatUtc,
      Value<int?> lastCheckpointAtUtc,
      Value<String?> recoveryReason,
      Value<int> updatedAtUtc,
    });

final class $$TimerRuntimeTableReferences
    extends
        BaseReferences<_$AppDatabase, $TimerRuntimeTable, TimerRuntimeData> {
  $$TimerRuntimeTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('timer_runtime__session_id__sessions__id');

  $$SessionsTableProcessedTableManager? get sessionId {
    final $_column = $_itemColumn<String>('session_id');
    if ($_column == null) return null;
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TimerRuntimeTableFilterComposer
    extends Composer<_$AppDatabase, $TimerRuntimeTable> {
  $$TimerRuntimeTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get machineState => $composableBuilder(
    column: $table.machineState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentSegmentId => $composableBuilder(
    column: $table.currentSegmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get phasePlannedSeconds => $composableBuilder(
    column: $table.phasePlannedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get phaseStartedAtUtc => $composableBuilder(
    column: $table.phaseStartedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get phaseAccumulatedSeconds => $composableBuilder(
    column: $table.phaseAccumulatedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentCycle => $composableBuilder(
    column: $table.currentCycle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monotonicAnchorMicros => $composableBuilder(
    column: $table.monotonicAnchorMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wallClockAnchorUtc => $composableBuilder(
    column: $table.wallClockAnchorUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastHeartbeatUtc => $composableBuilder(
    column: $table.lastHeartbeatUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastCheckpointAtUtc => $composableBuilder(
    column: $table.lastCheckpointAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recoveryReason => $composableBuilder(
    column: $table.recoveryReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimerRuntimeTableOrderingComposer
    extends Composer<_$AppDatabase, $TimerRuntimeTable> {
  $$TimerRuntimeTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get machineState => $composableBuilder(
    column: $table.machineState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentSegmentId => $composableBuilder(
    column: $table.currentSegmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get phasePlannedSeconds => $composableBuilder(
    column: $table.phasePlannedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get phaseStartedAtUtc => $composableBuilder(
    column: $table.phaseStartedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get phaseAccumulatedSeconds => $composableBuilder(
    column: $table.phaseAccumulatedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentCycle => $composableBuilder(
    column: $table.currentCycle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monotonicAnchorMicros => $composableBuilder(
    column: $table.monotonicAnchorMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wallClockAnchorUtc => $composableBuilder(
    column: $table.wallClockAnchorUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastHeartbeatUtc => $composableBuilder(
    column: $table.lastHeartbeatUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastCheckpointAtUtc => $composableBuilder(
    column: $table.lastCheckpointAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recoveryReason => $composableBuilder(
    column: $table.recoveryReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimerRuntimeTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimerRuntimeTable> {
  $$TimerRuntimeTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get singletonId => $composableBuilder(
    column: $table.singletonId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get machineState => $composableBuilder(
    column: $table.machineState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currentSegmentId => $composableBuilder(
    column: $table.currentSegmentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get phasePlannedSeconds => $composableBuilder(
    column: $table.phasePlannedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get phaseStartedAtUtc => $composableBuilder(
    column: $table.phaseStartedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get phaseAccumulatedSeconds => $composableBuilder(
    column: $table.phaseAccumulatedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentCycle => $composableBuilder(
    column: $table.currentCycle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get monotonicAnchorMicros => $composableBuilder(
    column: $table.monotonicAnchorMicros,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wallClockAnchorUtc => $composableBuilder(
    column: $table.wallClockAnchorUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastHeartbeatUtc => $composableBuilder(
    column: $table.lastHeartbeatUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastCheckpointAtUtc => $composableBuilder(
    column: $table.lastCheckpointAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recoveryReason => $composableBuilder(
    column: $table.recoveryReason,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimerRuntimeTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimerRuntimeTable,
          TimerRuntimeData,
          $$TimerRuntimeTableFilterComposer,
          $$TimerRuntimeTableOrderingComposer,
          $$TimerRuntimeTableAnnotationComposer,
          $$TimerRuntimeTableCreateCompanionBuilder,
          $$TimerRuntimeTableUpdateCompanionBuilder,
          (TimerRuntimeData, $$TimerRuntimeTableReferences),
          TimerRuntimeData,
          PrefetchHooks Function({bool sessionId})
        > {
  $$TimerRuntimeTableTableManager(_$AppDatabase db, $TimerRuntimeTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimerRuntimeTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimerRuntimeTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimerRuntimeTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> singletonId = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String> machineState = const Value.absent(),
                Value<String?> currentSegmentId = const Value.absent(),
                Value<int?> phasePlannedSeconds = const Value.absent(),
                Value<int?> phaseStartedAtUtc = const Value.absent(),
                Value<int> phaseAccumulatedSeconds = const Value.absent(),
                Value<int> currentCycle = const Value.absent(),
                Value<int?> monotonicAnchorMicros = const Value.absent(),
                Value<int?> wallClockAnchorUtc = const Value.absent(),
                Value<int?> lastHeartbeatUtc = const Value.absent(),
                Value<int?> lastCheckpointAtUtc = const Value.absent(),
                Value<String?> recoveryReason = const Value.absent(),
                Value<int> updatedAtUtc = const Value.absent(),
              }) => TimerRuntimeCompanion(
                singletonId: singletonId,
                sessionId: sessionId,
                machineState: machineState,
                currentSegmentId: currentSegmentId,
                phasePlannedSeconds: phasePlannedSeconds,
                phaseStartedAtUtc: phaseStartedAtUtc,
                phaseAccumulatedSeconds: phaseAccumulatedSeconds,
                currentCycle: currentCycle,
                monotonicAnchorMicros: monotonicAnchorMicros,
                wallClockAnchorUtc: wallClockAnchorUtc,
                lastHeartbeatUtc: lastHeartbeatUtc,
                lastCheckpointAtUtc: lastCheckpointAtUtc,
                recoveryReason: recoveryReason,
                updatedAtUtc: updatedAtUtc,
              ),
          createCompanionCallback:
              ({
                Value<int> singletonId = const Value.absent(),
                Value<String?> sessionId = const Value.absent(),
                Value<String> machineState = const Value.absent(),
                Value<String?> currentSegmentId = const Value.absent(),
                Value<int?> phasePlannedSeconds = const Value.absent(),
                Value<int?> phaseStartedAtUtc = const Value.absent(),
                Value<int> phaseAccumulatedSeconds = const Value.absent(),
                Value<int> currentCycle = const Value.absent(),
                Value<int?> monotonicAnchorMicros = const Value.absent(),
                Value<int?> wallClockAnchorUtc = const Value.absent(),
                Value<int?> lastHeartbeatUtc = const Value.absent(),
                Value<int?> lastCheckpointAtUtc = const Value.absent(),
                Value<String?> recoveryReason = const Value.absent(),
                required int updatedAtUtc,
              }) => TimerRuntimeCompanion.insert(
                singletonId: singletonId,
                sessionId: sessionId,
                machineState: machineState,
                currentSegmentId: currentSegmentId,
                phasePlannedSeconds: phasePlannedSeconds,
                phaseStartedAtUtc: phaseStartedAtUtc,
                phaseAccumulatedSeconds: phaseAccumulatedSeconds,
                currentCycle: currentCycle,
                monotonicAnchorMicros: monotonicAnchorMicros,
                wallClockAnchorUtc: wallClockAnchorUtc,
                lastHeartbeatUtc: lastHeartbeatUtc,
                lastCheckpointAtUtc: lastCheckpointAtUtc,
                recoveryReason: recoveryReason,
                updatedAtUtc: updatedAtUtc,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TimerRuntimeTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$TimerRuntimeTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$TimerRuntimeTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TimerRuntimeTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimerRuntimeTable,
      TimerRuntimeData,
      $$TimerRuntimeTableFilterComposer,
      $$TimerRuntimeTableOrderingComposer,
      $$TimerRuntimeTableAnnotationComposer,
      $$TimerRuntimeTableCreateCompanionBuilder,
      $$TimerRuntimeTableUpdateCompanionBuilder,
      (TimerRuntimeData, $$TimerRuntimeTableReferences),
      TimerRuntimeData,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      required String id,
      required String name,
      required String normalizedName,
      required int createdAtUtc,
      required int updatedAtUtc,
      required String sourceDeviceId,
      Value<int> rowid,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> normalizedName,
      Value<int> createdAtUtc,
      Value<int> updatedAtUtc,
      Value<String> sourceDeviceId,
      Value<int> rowid,
    });

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionTagsTable, List<SessionTag>>
  _sessionTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionTags,
    aliasName: 'tags__id__session_tags__tag_id',
  );

  $$SessionTagsTableProcessedTableManager get sessionTagsRefs {
    final manager = $$SessionTagsTableTableManager(
      $_db,
      $_db.sessionTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceDeviceId => $composableBuilder(
    column: $table.sourceDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionTagsRefs(
    Expression<bool> Function($$SessionTagsTableFilterComposer f) f,
  ) {
    final $$SessionTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionTagsTableFilterComposer(
            $db: $db,
            $table: $db.sessionTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceDeviceId => $composableBuilder(
    column: $table.sourceDeviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceDeviceId => $composableBuilder(
    column: $table.sourceDeviceId,
    builder: (column) => column,
  );

  Expression<T> sessionTagsRefs<T extends Object>(
    Expression<T> Function($$SessionTagsTableAnnotationComposer a) f,
  ) {
    final $$SessionTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({bool sessionTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<int> createdAtUtc = const Value.absent(),
                Value<int> updatedAtUtc = const Value.absent(),
                Value<String> sourceDeviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                name: name,
                normalizedName: normalizedName,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                sourceDeviceId: sourceDeviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String normalizedName,
                required int createdAtUtc,
                required int updatedAtUtc,
                required String sourceDeviceId,
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                normalizedName: normalizedName,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                sourceDeviceId: sourceDeviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TagsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({sessionTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sessionTagsRefs) db.sessionTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, SessionTag>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences
                          ._sessionTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).sessionTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({bool sessionTagsRefs})
    >;
typedef $$SessionTagsTableCreateCompanionBuilder =
    SessionTagsCompanion Function({
      required String sessionId,
      required String tagId,
      Value<int> rowid,
    });
typedef $$SessionTagsTableUpdateCompanionBuilder =
    SessionTagsCompanion Function({
      Value<String> sessionId,
      Value<String> tagId,
      Value<int> rowid,
    });

final class $$SessionTagsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionTagsTable, SessionTag> {
  $$SessionTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('session_tags__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('session_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SessionTagsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionTagsTable> {
  $$SessionTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionTagsTable> {
  $$SessionTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionTagsTable> {
  $$SessionTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionTagsTable,
          SessionTag,
          $$SessionTagsTableFilterComposer,
          $$SessionTagsTableOrderingComposer,
          $$SessionTagsTableAnnotationComposer,
          $$SessionTagsTableCreateCompanionBuilder,
          $$SessionTagsTableUpdateCompanionBuilder,
          (SessionTag, $$SessionTagsTableReferences),
          SessionTag,
          PrefetchHooks Function({bool sessionId, bool tagId})
        > {
  $$SessionTagsTableTableManager(_$AppDatabase db, $SessionTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionTagsCompanion(
                sessionId: sessionId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String tagId,
                Value<int> rowid = const Value.absent(),
              }) => SessionTagsCompanion.insert(
                sessionId: sessionId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$SessionTagsTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$SessionTagsTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$SessionTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$SessionTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SessionTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionTagsTable,
      SessionTag,
      $$SessionTagsTableFilterComposer,
      $$SessionTagsTableOrderingComposer,
      $$SessionTagsTableAnnotationComposer,
      $$SessionTagsTableCreateCompanionBuilder,
      $$SessionTagsTableUpdateCompanionBuilder,
      (SessionTag, $$SessionTagsTableReferences),
      SessionTag,
      PrefetchHooks Function({bool sessionId, bool tagId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String valueJson,
      required int updatedAtUtc,
      required String sourceDeviceId,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> valueJson,
      Value<int> updatedAtUtc,
      Value<String> sourceDeviceId,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceDeviceId => $composableBuilder(
    column: $table.sourceDeviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceDeviceId => $composableBuilder(
    column: $table.sourceDeviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);

  GeneratedColumn<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceDeviceId => $composableBuilder(
    column: $table.sourceDeviceId,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<int> updatedAtUtc = const Value.absent(),
                Value<String> sourceDeviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                valueJson: valueJson,
                updatedAtUtc: updatedAtUtc,
                sourceDeviceId: sourceDeviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String valueJson,
                required int updatedAtUtc,
                required String sourceDeviceId,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                valueJson: valueJson,
                updatedAtUtc: updatedAtUtc,
                sourceDeviceId: sourceDeviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$BackupHistoryTableCreateCompanionBuilder =
    BackupHistoryCompanion Function({
      required String id,
      required String backupType,
      Value<String?> destinationDisplay,
      required int createdAtUtc,
      Value<int?> verifiedAtUtc,
      Value<int?> sessionHighWatermarkUtc,
      Value<int> skillsCount,
      Value<int> sessionsCount,
      Value<int> totalActiveSeconds,
      Value<String?> fileSha256,
      required String status,
      Value<String?> errorCode,
      Value<int> rowid,
    });
typedef $$BackupHistoryTableUpdateCompanionBuilder =
    BackupHistoryCompanion Function({
      Value<String> id,
      Value<String> backupType,
      Value<String?> destinationDisplay,
      Value<int> createdAtUtc,
      Value<int?> verifiedAtUtc,
      Value<int?> sessionHighWatermarkUtc,
      Value<int> skillsCount,
      Value<int> sessionsCount,
      Value<int> totalActiveSeconds,
      Value<String?> fileSha256,
      Value<String> status,
      Value<String?> errorCode,
      Value<int> rowid,
    });

class $$BackupHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $BackupHistoryTable> {
  $$BackupHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backupType => $composableBuilder(
    column: $table.backupType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationDisplay => $composableBuilder(
    column: $table.destinationDisplay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verifiedAtUtc => $composableBuilder(
    column: $table.verifiedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessionHighWatermarkUtc => $composableBuilder(
    column: $table.sessionHighWatermarkUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get skillsCount => $composableBuilder(
    column: $table.skillsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessionsCount => $composableBuilder(
    column: $table.sessionsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalActiveSeconds => $composableBuilder(
    column: $table.totalActiveSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileSha256 => $composableBuilder(
    column: $table.fileSha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BackupHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $BackupHistoryTable> {
  $$BackupHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backupType => $composableBuilder(
    column: $table.backupType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationDisplay => $composableBuilder(
    column: $table.destinationDisplay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verifiedAtUtc => $composableBuilder(
    column: $table.verifiedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessionHighWatermarkUtc => $composableBuilder(
    column: $table.sessionHighWatermarkUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get skillsCount => $composableBuilder(
    column: $table.skillsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessionsCount => $composableBuilder(
    column: $table.sessionsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalActiveSeconds => $composableBuilder(
    column: $table.totalActiveSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileSha256 => $composableBuilder(
    column: $table.fileSha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BackupHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $BackupHistoryTable> {
  $$BackupHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get backupType => $composableBuilder(
    column: $table.backupType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationDisplay => $composableBuilder(
    column: $table.destinationDisplay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get verifiedAtUtc => $composableBuilder(
    column: $table.verifiedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sessionHighWatermarkUtc => $composableBuilder(
    column: $table.sessionHighWatermarkUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get skillsCount => $composableBuilder(
    column: $table.skillsCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sessionsCount => $composableBuilder(
    column: $table.sessionsCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalActiveSeconds => $composableBuilder(
    column: $table.totalActiveSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileSha256 => $composableBuilder(
    column: $table.fileSha256,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);
}

class $$BackupHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BackupHistoryTable,
          BackupHistoryData,
          $$BackupHistoryTableFilterComposer,
          $$BackupHistoryTableOrderingComposer,
          $$BackupHistoryTableAnnotationComposer,
          $$BackupHistoryTableCreateCompanionBuilder,
          $$BackupHistoryTableUpdateCompanionBuilder,
          (
            BackupHistoryData,
            BaseReferences<
              _$AppDatabase,
              $BackupHistoryTable,
              BackupHistoryData
            >,
          ),
          BackupHistoryData,
          PrefetchHooks Function()
        > {
  $$BackupHistoryTableTableManager(_$AppDatabase db, $BackupHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BackupHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BackupHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BackupHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> backupType = const Value.absent(),
                Value<String?> destinationDisplay = const Value.absent(),
                Value<int> createdAtUtc = const Value.absent(),
                Value<int?> verifiedAtUtc = const Value.absent(),
                Value<int?> sessionHighWatermarkUtc = const Value.absent(),
                Value<int> skillsCount = const Value.absent(),
                Value<int> sessionsCount = const Value.absent(),
                Value<int> totalActiveSeconds = const Value.absent(),
                Value<String?> fileSha256 = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BackupHistoryCompanion(
                id: id,
                backupType: backupType,
                destinationDisplay: destinationDisplay,
                createdAtUtc: createdAtUtc,
                verifiedAtUtc: verifiedAtUtc,
                sessionHighWatermarkUtc: sessionHighWatermarkUtc,
                skillsCount: skillsCount,
                sessionsCount: sessionsCount,
                totalActiveSeconds: totalActiveSeconds,
                fileSha256: fileSha256,
                status: status,
                errorCode: errorCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String backupType,
                Value<String?> destinationDisplay = const Value.absent(),
                required int createdAtUtc,
                Value<int?> verifiedAtUtc = const Value.absent(),
                Value<int?> sessionHighWatermarkUtc = const Value.absent(),
                Value<int> skillsCount = const Value.absent(),
                Value<int> sessionsCount = const Value.absent(),
                Value<int> totalActiveSeconds = const Value.absent(),
                Value<String?> fileSha256 = const Value.absent(),
                required String status,
                Value<String?> errorCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BackupHistoryCompanion.insert(
                id: id,
                backupType: backupType,
                destinationDisplay: destinationDisplay,
                createdAtUtc: createdAtUtc,
                verifiedAtUtc: verifiedAtUtc,
                sessionHighWatermarkUtc: sessionHighWatermarkUtc,
                skillsCount: skillsCount,
                sessionsCount: sessionsCount,
                totalActiveSeconds: totalActiveSeconds,
                fileSha256: fileSha256,
                status: status,
                errorCode: errorCode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BackupHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BackupHistoryTable,
      BackupHistoryData,
      $$BackupHistoryTableFilterComposer,
      $$BackupHistoryTableOrderingComposer,
      $$BackupHistoryTableAnnotationComposer,
      $$BackupHistoryTableCreateCompanionBuilder,
      $$BackupHistoryTableUpdateCompanionBuilder,
      (
        BackupHistoryData,
        BaseReferences<_$AppDatabase, $BackupHistoryTable, BackupHistoryData>,
      ),
      BackupHistoryData,
      PrefetchHooks Function()
    >;
typedef $$LocalSnapshotsTableCreateCompanionBuilder =
    LocalSnapshotsCompanion Function({
      required String id,
      required String filePath,
      required String reason,
      required int createdAtUtc,
      required int schemaVersion,
      required String fileSha256,
      required int sizeBytes,
      Value<int> isValid,
      Value<int> rowid,
    });
typedef $$LocalSnapshotsTableUpdateCompanionBuilder =
    LocalSnapshotsCompanion Function({
      Value<String> id,
      Value<String> filePath,
      Value<String> reason,
      Value<int> createdAtUtc,
      Value<int> schemaVersion,
      Value<String> fileSha256,
      Value<int> sizeBytes,
      Value<int> isValid,
      Value<int> rowid,
    });

class $$LocalSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSnapshotsTable> {
  $$LocalSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileSha256 => $composableBuilder(
    column: $table.fileSha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isValid => $composableBuilder(
    column: $table.isValid,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSnapshotsTable> {
  $$LocalSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileSha256 => $composableBuilder(
    column: $table.fileSha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isValid => $composableBuilder(
    column: $table.isValid,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSnapshotsTable> {
  $$LocalSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileSha256 => $composableBuilder(
    column: $table.fileSha256,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get isValid =>
      $composableBuilder(column: $table.isValid, builder: (column) => column);
}

class $$LocalSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSnapshotsTable,
          LocalSnapshot,
          $$LocalSnapshotsTableFilterComposer,
          $$LocalSnapshotsTableOrderingComposer,
          $$LocalSnapshotsTableAnnotationComposer,
          $$LocalSnapshotsTableCreateCompanionBuilder,
          $$LocalSnapshotsTableUpdateCompanionBuilder,
          (
            LocalSnapshot,
            BaseReferences<_$AppDatabase, $LocalSnapshotsTable, LocalSnapshot>,
          ),
          LocalSnapshot,
          PrefetchHooks Function()
        > {
  $$LocalSnapshotsTableTableManager(
    _$AppDatabase db,
    $LocalSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<int> createdAtUtc = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<String> fileSha256 = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<int> isValid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSnapshotsCompanion(
                id: id,
                filePath: filePath,
                reason: reason,
                createdAtUtc: createdAtUtc,
                schemaVersion: schemaVersion,
                fileSha256: fileSha256,
                sizeBytes: sizeBytes,
                isValid: isValid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String filePath,
                required String reason,
                required int createdAtUtc,
                required int schemaVersion,
                required String fileSha256,
                required int sizeBytes,
                Value<int> isValid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSnapshotsCompanion.insert(
                id: id,
                filePath: filePath,
                reason: reason,
                createdAtUtc: createdAtUtc,
                schemaVersion: schemaVersion,
                fileSha256: fileSha256,
                sizeBytes: sizeBytes,
                isValid: isValid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSnapshotsTable,
      LocalSnapshot,
      $$LocalSnapshotsTableFilterComposer,
      $$LocalSnapshotsTableOrderingComposer,
      $$LocalSnapshotsTableAnnotationComposer,
      $$LocalSnapshotsTableCreateCompanionBuilder,
      $$LocalSnapshotsTableUpdateCompanionBuilder,
      (
        LocalSnapshot,
        BaseReferences<_$AppDatabase, $LocalSnapshotsTable, LocalSnapshot>,
      ),
      LocalSnapshot,
      PrefetchHooks Function()
    >;
typedef $$DeviceIdentityTableCreateCompanionBuilder =
    DeviceIdentityCompanion Function({
      required String deviceId,
      required int createdAtUtc,
      Value<String?> displayName,
      Value<int> rowid,
    });
typedef $$DeviceIdentityTableUpdateCompanionBuilder =
    DeviceIdentityCompanion Function({
      Value<String> deviceId,
      Value<int> createdAtUtc,
      Value<String?> displayName,
      Value<int> rowid,
    });

class $$DeviceIdentityTableFilterComposer
    extends Composer<_$AppDatabase, $DeviceIdentityTable> {
  $$DeviceIdentityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeviceIdentityTableOrderingComposer
    extends Composer<_$AppDatabase, $DeviceIdentityTable> {
  $$DeviceIdentityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeviceIdentityTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeviceIdentityTable> {
  $$DeviceIdentityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );
}

class $$DeviceIdentityTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeviceIdentityTable,
          DeviceIdentityData,
          $$DeviceIdentityTableFilterComposer,
          $$DeviceIdentityTableOrderingComposer,
          $$DeviceIdentityTableAnnotationComposer,
          $$DeviceIdentityTableCreateCompanionBuilder,
          $$DeviceIdentityTableUpdateCompanionBuilder,
          (
            DeviceIdentityData,
            BaseReferences<
              _$AppDatabase,
              $DeviceIdentityTable,
              DeviceIdentityData
            >,
          ),
          DeviceIdentityData,
          PrefetchHooks Function()
        > {
  $$DeviceIdentityTableTableManager(
    _$AppDatabase db,
    $DeviceIdentityTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceIdentityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceIdentityTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceIdentityTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<int> createdAtUtc = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeviceIdentityCompanion(
                deviceId: deviceId,
                createdAtUtc: createdAtUtc,
                displayName: displayName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required int createdAtUtc,
                Value<String?> displayName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeviceIdentityCompanion.insert(
                deviceId: deviceId,
                createdAtUtc: createdAtUtc,
                displayName: displayName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeviceIdentityTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeviceIdentityTable,
      DeviceIdentityData,
      $$DeviceIdentityTableFilterComposer,
      $$DeviceIdentityTableOrderingComposer,
      $$DeviceIdentityTableAnnotationComposer,
      $$DeviceIdentityTableCreateCompanionBuilder,
      $$DeviceIdentityTableUpdateCompanionBuilder,
      (
        DeviceIdentityData,
        BaseReferences<_$AppDatabase, $DeviceIdentityTable, DeviceIdentityData>,
      ),
      DeviceIdentityData,
      PrefetchHooks Function()
    >;
typedef $$SchemaMetadataTableCreateCompanionBuilder =
    SchemaMetadataCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SchemaMetadataTableUpdateCompanionBuilder =
    SchemaMetadataCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SchemaMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $SchemaMetadataTable> {
  $$SchemaMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SchemaMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $SchemaMetadataTable> {
  $$SchemaMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SchemaMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchemaMetadataTable> {
  $$SchemaMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SchemaMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchemaMetadataTable,
          SchemaMetadataData,
          $$SchemaMetadataTableFilterComposer,
          $$SchemaMetadataTableOrderingComposer,
          $$SchemaMetadataTableAnnotationComposer,
          $$SchemaMetadataTableCreateCompanionBuilder,
          $$SchemaMetadataTableUpdateCompanionBuilder,
          (
            SchemaMetadataData,
            BaseReferences<
              _$AppDatabase,
              $SchemaMetadataTable,
              SchemaMetadataData
            >,
          ),
          SchemaMetadataData,
          PrefetchHooks Function()
        > {
  $$SchemaMetadataTableTableManager(
    _$AppDatabase db,
    $SchemaMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchemaMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchemaMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchemaMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  SchemaMetadataCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SchemaMetadataCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SchemaMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchemaMetadataTable,
      SchemaMetadataData,
      $$SchemaMetadataTableFilterComposer,
      $$SchemaMetadataTableOrderingComposer,
      $$SchemaMetadataTableAnnotationComposer,
      $$SchemaMetadataTableCreateCompanionBuilder,
      $$SchemaMetadataTableUpdateCompanionBuilder,
      (
        SchemaMetadataData,
        BaseReferences<_$AppDatabase, $SchemaMetadataTable, SchemaMetadataData>,
      ),
      SchemaMetadataData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SkillsTableTableManager get skills =>
      $$SkillsTableTableManager(_db, _db.skills);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SessionSegmentsTableTableManager get sessionSegments =>
      $$SessionSegmentsTableTableManager(_db, _db.sessionSegments);
  $$TimerRuntimeTableTableManager get timerRuntime =>
      $$TimerRuntimeTableTableManager(_db, _db.timerRuntime);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$SessionTagsTableTableManager get sessionTags =>
      $$SessionTagsTableTableManager(_db, _db.sessionTags);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$BackupHistoryTableTableManager get backupHistory =>
      $$BackupHistoryTableTableManager(_db, _db.backupHistory);
  $$LocalSnapshotsTableTableManager get localSnapshots =>
      $$LocalSnapshotsTableTableManager(_db, _db.localSnapshots);
  $$DeviceIdentityTableTableManager get deviceIdentity =>
      $$DeviceIdentityTableTableManager(_db, _db.deviceIdentity);
  $$SchemaMetadataTableTableManager get schemaMetadata =>
      $$SchemaMetadataTableTableManager(_db, _db.schemaMetadata);
}
