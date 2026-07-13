// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueTypeMeta =
      const VerificationMeta('valueType');
  @override
  late final GeneratedColumn<String> valueType = GeneratedColumn<String>(
      'value_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [category, key, value, valueType, updatedAt];
  @override
  String get aliasedName => _alias ?? 'settings';
  @override
  String get actualTableName => 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('value_type')) {
      context.handle(_valueTypeMeta,
          valueType.isAcceptableOrUnknown(data['value_type']!, _valueTypeMeta));
    } else if (isInserting) {
      context.missing(_valueTypeMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {category, key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      valueType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value_type'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String category;
  final String key;
  final String value;
  final String valueType;
  final int updatedAt;
  const Setting(
      {required this.category,
      required this.key,
      required this.value,
      required this.valueType,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['category'] = Variable<String>(category);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['value_type'] = Variable<String>(valueType);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      category: Value(category),
      key: Value(key),
      value: Value(value),
      valueType: Value(valueType),
      updatedAt: Value(updatedAt),
    );
  }

  factory Setting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      category: serializer.fromJson<String>(json['category']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      valueType: serializer.fromJson<String>(json['valueType']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'category': serializer.toJson<String>(category),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'valueType': serializer.toJson<String>(valueType),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Setting copyWith(
          {String? category,
          String? key,
          String? value,
          String? valueType,
          int? updatedAt}) =>
      Setting(
        category: category ?? this.category,
        key: key ?? this.key,
        value: value ?? this.value,
        valueType: valueType ?? this.valueType,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('category: $category, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('valueType: $valueType, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(category, key, value, valueType, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.category == this.category &&
          other.key == this.key &&
          other.value == this.value &&
          other.valueType == this.valueType &&
          other.updatedAt == this.updatedAt);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> category;
  final Value<String> key;
  final Value<String> value;
  final Value<String> valueType;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const SettingsCompanion({
    this.category = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.valueType = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String category,
    required String key,
    required String value,
    required String valueType,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : category = Value(category),
        key = Value(key),
        value = Value(value),
        valueType = Value(valueType),
        updatedAt = Value(updatedAt);
  static Insertable<Setting> custom({
    Expression<String>? category,
    Expression<String>? key,
    Expression<String>? value,
    Expression<String>? valueType,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (category != null) 'category': category,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (valueType != null) 'value_type': valueType,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith(
      {Value<String>? category,
      Value<String>? key,
      Value<String>? value,
      Value<String>? valueType,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return SettingsCompanion(
      category: category ?? this.category,
      key: key ?? this.key,
      value: value ?? this.value,
      valueType: valueType ?? this.valueType,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (valueType.present) {
      map['value_type'] = Variable<String>(valueType.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('category: $category, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('valueType: $valueType, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isSystemMeta =
      const VerificationMeta('isSystem');
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
      'is_system', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_system" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _configJsonMeta =
      const VerificationMeta('configJson');
  @override
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
      'config_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, type, isSystem, isActive, configJson, createdAt];
  @override
  String get aliasedName => _alias ?? 'profiles';
  @override
  String get actualTableName => 'profiles';
  @override
  VerificationContext validateIntegrity(Insertable<Profile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('is_system')) {
      context.handle(_isSystemMeta,
          isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('config_json')) {
      context.handle(
          _configJsonMeta,
          configJson.isAcceptableOrUnknown(
              data['config_json']!, _configJsonMeta));
    } else if (isInserting) {
      context.missing(_configJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      isSystem: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_system'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      configJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}config_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final String id;
  final String name;
  final String type;
  final bool isSystem;
  final bool isActive;
  final String configJson;
  final int createdAt;
  const Profile(
      {required this.id,
      required this.name,
      required this.type,
      required this.isSystem,
      required this.isActive,
      required this.configJson,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['is_system'] = Variable<bool>(isSystem);
    map['is_active'] = Variable<bool>(isActive);
    map['config_json'] = Variable<String>(configJson);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      isSystem: Value(isSystem),
      isActive: Value(isActive),
      configJson: Value(configJson),
      createdAt: Value(createdAt),
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      configJson: serializer.fromJson<String>(json['configJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'isSystem': serializer.toJson<bool>(isSystem),
      'isActive': serializer.toJson<bool>(isActive),
      'configJson': serializer.toJson<String>(configJson),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Profile copyWith(
          {String? id,
          String? name,
          String? type,
          bool? isSystem,
          bool? isActive,
          String? configJson,
          int? createdAt}) =>
      Profile(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        isSystem: isSystem ?? this.isSystem,
        isActive: isActive ?? this.isActive,
        configJson: configJson ?? this.configJson,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('isSystem: $isSystem, ')
          ..write('isActive: $isActive, ')
          ..write('configJson: $configJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, type, isSystem, isActive, configJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.isSystem == this.isSystem &&
          other.isActive == this.isActive &&
          other.configJson == this.configJson &&
          other.createdAt == this.createdAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<bool> isSystem;
  final Value<bool> isActive;
  final Value<String> configJson;
  final Value<int> createdAt;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.isActive = const Value.absent(),
    this.configJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required String name,
    required String type,
    this.isSystem = const Value.absent(),
    this.isActive = const Value.absent(),
    required String configJson,
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        type = Value(type),
        configJson = Value(configJson),
        createdAt = Value(createdAt);
  static Insertable<Profile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<bool>? isSystem,
    Expression<bool>? isActive,
    Expression<String>? configJson,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (isSystem != null) 'is_system': isSystem,
      if (isActive != null) 'is_active': isActive,
      if (configJson != null) 'config_json': configJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? type,
      Value<bool>? isSystem,
      Value<bool>? isActive,
      Value<String>? configJson,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isSystem: isSystem ?? this.isSystem,
      isActive: isActive ?? this.isActive,
      configJson: configJson ?? this.configJson,
      createdAt: createdAt ?? this.createdAt,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('isSystem: $isSystem, ')
          ..write('isActive: $isActive, ')
          ..write('configJson: $configJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FirewallRulesTable extends FirewallRules
    with TableInfo<$FirewallRulesTable, FirewallRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FirewallRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _appIdMeta = const VerificationMeta('appId');
  @override
  late final GeneratedColumn<String> appId = GeneratedColumn<String>(
      'app_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _conditionsJsonMeta =
      const VerificationMeta('conditionsJson');
  @override
  late final GeneratedColumn<String> conditionsJson = GeneratedColumn<String>(
      'conditions_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profile_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isGlobalMeta =
      const VerificationMeta('isGlobal');
  @override
  late final GeneratedColumn<bool> isGlobal = GeneratedColumn<bool>(
      'is_global', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_global" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        appId,
        action,
        priority,
        conditionsJson,
        profileId,
        isGlobal,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? 'firewall_rules';
  @override
  String get actualTableName => 'firewall_rules';
  @override
  VerificationContext validateIntegrity(Insertable<FirewallRule> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('app_id')) {
      context.handle(
          _appIdMeta, appId.isAcceptableOrUnknown(data['app_id']!, _appIdMeta));
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('conditions_json')) {
      context.handle(
          _conditionsJsonMeta,
          conditionsJson.isAcceptableOrUnknown(
              data['conditions_json']!, _conditionsJsonMeta));
    } else if (isInserting) {
      context.missing(_conditionsJsonMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    }
    if (data.containsKey('is_global')) {
      context.handle(_isGlobalMeta,
          isGlobal.isAcceptableOrUnknown(data['is_global']!, _isGlobalMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FirewallRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FirewallRule(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      appId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_id']),
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      conditionsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}conditions_json'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_id']),
      isGlobal: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_global'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $FirewallRulesTable createAlias(String alias) {
    return $FirewallRulesTable(attachedDatabase, alias);
  }
}

class FirewallRule extends DataClass implements Insertable<FirewallRule> {
  final String id;
  final String? appId;
  final String action;
  final int priority;
  final String conditionsJson;
  final String? profileId;
  final bool isGlobal;
  final int createdAt;
  final int updatedAt;
  const FirewallRule(
      {required this.id,
      this.appId,
      required this.action,
      required this.priority,
      required this.conditionsJson,
      this.profileId,
      required this.isGlobal,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || appId != null) {
      map['app_id'] = Variable<String>(appId);
    }
    map['action'] = Variable<String>(action);
    map['priority'] = Variable<int>(priority);
    map['conditions_json'] = Variable<String>(conditionsJson);
    if (!nullToAbsent || profileId != null) {
      map['profile_id'] = Variable<String>(profileId);
    }
    map['is_global'] = Variable<bool>(isGlobal);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  FirewallRulesCompanion toCompanion(bool nullToAbsent) {
    return FirewallRulesCompanion(
      id: Value(id),
      appId:
          appId == null && nullToAbsent ? const Value.absent() : Value(appId),
      action: Value(action),
      priority: Value(priority),
      conditionsJson: Value(conditionsJson),
      profileId: profileId == null && nullToAbsent
          ? const Value.absent()
          : Value(profileId),
      isGlobal: Value(isGlobal),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FirewallRule.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FirewallRule(
      id: serializer.fromJson<String>(json['id']),
      appId: serializer.fromJson<String?>(json['appId']),
      action: serializer.fromJson<String>(json['action']),
      priority: serializer.fromJson<int>(json['priority']),
      conditionsJson: serializer.fromJson<String>(json['conditionsJson']),
      profileId: serializer.fromJson<String?>(json['profileId']),
      isGlobal: serializer.fromJson<bool>(json['isGlobal']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'appId': serializer.toJson<String?>(appId),
      'action': serializer.toJson<String>(action),
      'priority': serializer.toJson<int>(priority),
      'conditionsJson': serializer.toJson<String>(conditionsJson),
      'profileId': serializer.toJson<String?>(profileId),
      'isGlobal': serializer.toJson<bool>(isGlobal),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  FirewallRule copyWith(
          {String? id,
          Value<String?> appId = const Value.absent(),
          String? action,
          int? priority,
          String? conditionsJson,
          Value<String?> profileId = const Value.absent(),
          bool? isGlobal,
          int? createdAt,
          int? updatedAt}) =>
      FirewallRule(
        id: id ?? this.id,
        appId: appId.present ? appId.value : this.appId,
        action: action ?? this.action,
        priority: priority ?? this.priority,
        conditionsJson: conditionsJson ?? this.conditionsJson,
        profileId: profileId.present ? profileId.value : this.profileId,
        isGlobal: isGlobal ?? this.isGlobal,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  @override
  String toString() {
    return (StringBuffer('FirewallRule(')
          ..write('id: $id, ')
          ..write('appId: $appId, ')
          ..write('action: $action, ')
          ..write('priority: $priority, ')
          ..write('conditionsJson: $conditionsJson, ')
          ..write('profileId: $profileId, ')
          ..write('isGlobal: $isGlobal, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, appId, action, priority, conditionsJson,
      profileId, isGlobal, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FirewallRule &&
          other.id == this.id &&
          other.appId == this.appId &&
          other.action == this.action &&
          other.priority == this.priority &&
          other.conditionsJson == this.conditionsJson &&
          other.profileId == this.profileId &&
          other.isGlobal == this.isGlobal &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FirewallRulesCompanion extends UpdateCompanion<FirewallRule> {
  final Value<String> id;
  final Value<String?> appId;
  final Value<String> action;
  final Value<int> priority;
  final Value<String> conditionsJson;
  final Value<String?> profileId;
  final Value<bool> isGlobal;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const FirewallRulesCompanion({
    this.id = const Value.absent(),
    this.appId = const Value.absent(),
    this.action = const Value.absent(),
    this.priority = const Value.absent(),
    this.conditionsJson = const Value.absent(),
    this.profileId = const Value.absent(),
    this.isGlobal = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FirewallRulesCompanion.insert({
    required String id,
    this.appId = const Value.absent(),
    required String action,
    required int priority,
    required String conditionsJson,
    this.profileId = const Value.absent(),
    this.isGlobal = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        action = Value(action),
        priority = Value(priority),
        conditionsJson = Value(conditionsJson),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<FirewallRule> custom({
    Expression<String>? id,
    Expression<String>? appId,
    Expression<String>? action,
    Expression<int>? priority,
    Expression<String>? conditionsJson,
    Expression<String>? profileId,
    Expression<bool>? isGlobal,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (appId != null) 'app_id': appId,
      if (action != null) 'action': action,
      if (priority != null) 'priority': priority,
      if (conditionsJson != null) 'conditions_json': conditionsJson,
      if (profileId != null) 'profile_id': profileId,
      if (isGlobal != null) 'is_global': isGlobal,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FirewallRulesCompanion copyWith(
      {Value<String>? id,
      Value<String?>? appId,
      Value<String>? action,
      Value<int>? priority,
      Value<String>? conditionsJson,
      Value<String?>? profileId,
      Value<bool>? isGlobal,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return FirewallRulesCompanion(
      id: id ?? this.id,
      appId: appId ?? this.appId,
      action: action ?? this.action,
      priority: priority ?? this.priority,
      conditionsJson: conditionsJson ?? this.conditionsJson,
      profileId: profileId ?? this.profileId,
      isGlobal: isGlobal ?? this.isGlobal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (appId.present) {
      map['app_id'] = Variable<String>(appId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (conditionsJson.present) {
      map['conditions_json'] = Variable<String>(conditionsJson.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (isGlobal.present) {
      map['is_global'] = Variable<bool>(isGlobal.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FirewallRulesCompanion(')
          ..write('id: $id, ')
          ..write('appId: $appId, ')
          ..write('action: $action, ')
          ..write('priority: $priority, ')
          ..write('conditionsJson: $conditionsJson, ')
          ..write('profileId: $profileId, ')
          ..write('isGlobal: $isGlobal, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemporaryRulesTable extends TemporaryRules
    with TableInfo<$TemporaryRulesTable, TemporaryRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemporaryRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _appIdMeta = const VerificationMeta('appId');
  @override
  late final GeneratedColumn<String> appId = GeneratedColumn<String>(
      'app_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startAtMeta =
      const VerificationMeta('startAt');
  @override
  late final GeneratedColumn<int> startAt = GeneratedColumn<int>(
      'start_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<int> endAt = GeneratedColumn<int>(
      'end_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _previousRuleIdMeta =
      const VerificationMeta('previousRuleId');
  @override
  late final GeneratedColumn<String> previousRuleId = GeneratedColumn<String>(
      'previous_rule_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _conditionsJsonMeta =
      const VerificationMeta('conditionsJson');
  @override
  late final GeneratedColumn<String> conditionsJson = GeneratedColumn<String>(
      'conditions_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, appId, action, startAt, endAt, previousRuleId, conditionsJson];
  @override
  String get aliasedName => _alias ?? 'temporary_rules';
  @override
  String get actualTableName => 'temporary_rules';
  @override
  VerificationContext validateIntegrity(Insertable<TemporaryRule> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('app_id')) {
      context.handle(
          _appIdMeta, appId.isAcceptableOrUnknown(data['app_id']!, _appIdMeta));
    } else if (isInserting) {
      context.missing(_appIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('start_at')) {
      context.handle(_startAtMeta,
          startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta));
    } else if (isInserting) {
      context.missing(_startAtMeta);
    }
    if (data.containsKey('end_at')) {
      context.handle(
          _endAtMeta, endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta));
    } else if (isInserting) {
      context.missing(_endAtMeta);
    }
    if (data.containsKey('previous_rule_id')) {
      context.handle(
          _previousRuleIdMeta,
          previousRuleId.isAcceptableOrUnknown(
              data['previous_rule_id']!, _previousRuleIdMeta));
    }
    if (data.containsKey('conditions_json')) {
      context.handle(
          _conditionsJsonMeta,
          conditionsJson.isAcceptableOrUnknown(
              data['conditions_json']!, _conditionsJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemporaryRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemporaryRule(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      appId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      startAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_at'])!,
      endAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_at'])!,
      previousRuleId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}previous_rule_id']),
      conditionsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}conditions_json']),
    );
  }

  @override
  $TemporaryRulesTable createAlias(String alias) {
    return $TemporaryRulesTable(attachedDatabase, alias);
  }
}

class TemporaryRule extends DataClass implements Insertable<TemporaryRule> {
  final String id;
  final String appId;
  final String action;
  final int startAt;
  final int endAt;
  final String? previousRuleId;
  final String? conditionsJson;
  const TemporaryRule(
      {required this.id,
      required this.appId,
      required this.action,
      required this.startAt,
      required this.endAt,
      this.previousRuleId,
      this.conditionsJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['app_id'] = Variable<String>(appId);
    map['action'] = Variable<String>(action);
    map['start_at'] = Variable<int>(startAt);
    map['end_at'] = Variable<int>(endAt);
    if (!nullToAbsent || previousRuleId != null) {
      map['previous_rule_id'] = Variable<String>(previousRuleId);
    }
    if (!nullToAbsent || conditionsJson != null) {
      map['conditions_json'] = Variable<String>(conditionsJson);
    }
    return map;
  }

  TemporaryRulesCompanion toCompanion(bool nullToAbsent) {
    return TemporaryRulesCompanion(
      id: Value(id),
      appId: Value(appId),
      action: Value(action),
      startAt: Value(startAt),
      endAt: Value(endAt),
      previousRuleId: previousRuleId == null && nullToAbsent
          ? const Value.absent()
          : Value(previousRuleId),
      conditionsJson: conditionsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(conditionsJson),
    );
  }

  factory TemporaryRule.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemporaryRule(
      id: serializer.fromJson<String>(json['id']),
      appId: serializer.fromJson<String>(json['appId']),
      action: serializer.fromJson<String>(json['action']),
      startAt: serializer.fromJson<int>(json['startAt']),
      endAt: serializer.fromJson<int>(json['endAt']),
      previousRuleId: serializer.fromJson<String?>(json['previousRuleId']),
      conditionsJson: serializer.fromJson<String?>(json['conditionsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'appId': serializer.toJson<String>(appId),
      'action': serializer.toJson<String>(action),
      'startAt': serializer.toJson<int>(startAt),
      'endAt': serializer.toJson<int>(endAt),
      'previousRuleId': serializer.toJson<String?>(previousRuleId),
      'conditionsJson': serializer.toJson<String?>(conditionsJson),
    };
  }

  TemporaryRule copyWith(
          {String? id,
          String? appId,
          String? action,
          int? startAt,
          int? endAt,
          Value<String?> previousRuleId = const Value.absent(),
          Value<String?> conditionsJson = const Value.absent()}) =>
      TemporaryRule(
        id: id ?? this.id,
        appId: appId ?? this.appId,
        action: action ?? this.action,
        startAt: startAt ?? this.startAt,
        endAt: endAt ?? this.endAt,
        previousRuleId:
            previousRuleId.present ? previousRuleId.value : this.previousRuleId,
        conditionsJson:
            conditionsJson.present ? conditionsJson.value : this.conditionsJson,
      );
  @override
  String toString() {
    return (StringBuffer('TemporaryRule(')
          ..write('id: $id, ')
          ..write('appId: $appId, ')
          ..write('action: $action, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('previousRuleId: $previousRuleId, ')
          ..write('conditionsJson: $conditionsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, appId, action, startAt, endAt, previousRuleId, conditionsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemporaryRule &&
          other.id == this.id &&
          other.appId == this.appId &&
          other.action == this.action &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.previousRuleId == this.previousRuleId &&
          other.conditionsJson == this.conditionsJson);
}

class TemporaryRulesCompanion extends UpdateCompanion<TemporaryRule> {
  final Value<String> id;
  final Value<String> appId;
  final Value<String> action;
  final Value<int> startAt;
  final Value<int> endAt;
  final Value<String?> previousRuleId;
  final Value<String?> conditionsJson;
  final Value<int> rowid;
  const TemporaryRulesCompanion({
    this.id = const Value.absent(),
    this.appId = const Value.absent(),
    this.action = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.previousRuleId = const Value.absent(),
    this.conditionsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemporaryRulesCompanion.insert({
    required String id,
    required String appId,
    required String action,
    required int startAt,
    required int endAt,
    this.previousRuleId = const Value.absent(),
    this.conditionsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        appId = Value(appId),
        action = Value(action),
        startAt = Value(startAt),
        endAt = Value(endAt);
  static Insertable<TemporaryRule> custom({
    Expression<String>? id,
    Expression<String>? appId,
    Expression<String>? action,
    Expression<int>? startAt,
    Expression<int>? endAt,
    Expression<String>? previousRuleId,
    Expression<String>? conditionsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (appId != null) 'app_id': appId,
      if (action != null) 'action': action,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (previousRuleId != null) 'previous_rule_id': previousRuleId,
      if (conditionsJson != null) 'conditions_json': conditionsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemporaryRulesCompanion copyWith(
      {Value<String>? id,
      Value<String>? appId,
      Value<String>? action,
      Value<int>? startAt,
      Value<int>? endAt,
      Value<String?>? previousRuleId,
      Value<String?>? conditionsJson,
      Value<int>? rowid}) {
    return TemporaryRulesCompanion(
      id: id ?? this.id,
      appId: appId ?? this.appId,
      action: action ?? this.action,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      previousRuleId: previousRuleId ?? this.previousRuleId,
      conditionsJson: conditionsJson ?? this.conditionsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (appId.present) {
      map['app_id'] = Variable<String>(appId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<int>(startAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<int>(endAt.value);
    }
    if (previousRuleId.present) {
      map['previous_rule_id'] = Variable<String>(previousRuleId.value);
    }
    if (conditionsJson.present) {
      map['conditions_json'] = Variable<String>(conditionsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemporaryRulesCompanion(')
          ..write('id: $id, ')
          ..write('appId: $appId, ')
          ..write('action: $action, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('previousRuleId: $previousRuleId, ')
          ..write('conditionsJson: $conditionsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionRulesTable extends SessionRules
    with TableInfo<$SessionRulesTable, SessionRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _appIdMeta = const VerificationMeta('appId');
  @override
  late final GeneratedColumn<String> appId = GeneratedColumn<String>(
      'app_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, appId, action, sessionId];
  @override
  String get aliasedName => _alias ?? 'session_rules';
  @override
  String get actualTableName => 'session_rules';
  @override
  VerificationContext validateIntegrity(Insertable<SessionRule> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('app_id')) {
      context.handle(
          _appIdMeta, appId.isAcceptableOrUnknown(data['app_id']!, _appIdMeta));
    } else if (isInserting) {
      context.missing(_appIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRule(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      appId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
    );
  }

  @override
  $SessionRulesTable createAlias(String alias) {
    return $SessionRulesTable(attachedDatabase, alias);
  }
}

class SessionRule extends DataClass implements Insertable<SessionRule> {
  final String id;
  final String appId;
  final String action;
  final String sessionId;
  const SessionRule(
      {required this.id,
      required this.appId,
      required this.action,
      required this.sessionId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['app_id'] = Variable<String>(appId);
    map['action'] = Variable<String>(action);
    map['session_id'] = Variable<String>(sessionId);
    return map;
  }

  SessionRulesCompanion toCompanion(bool nullToAbsent) {
    return SessionRulesCompanion(
      id: Value(id),
      appId: Value(appId),
      action: Value(action),
      sessionId: Value(sessionId),
    );
  }

  factory SessionRule.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRule(
      id: serializer.fromJson<String>(json['id']),
      appId: serializer.fromJson<String>(json['appId']),
      action: serializer.fromJson<String>(json['action']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'appId': serializer.toJson<String>(appId),
      'action': serializer.toJson<String>(action),
      'sessionId': serializer.toJson<String>(sessionId),
    };
  }

  SessionRule copyWith(
          {String? id, String? appId, String? action, String? sessionId}) =>
      SessionRule(
        id: id ?? this.id,
        appId: appId ?? this.appId,
        action: action ?? this.action,
        sessionId: sessionId ?? this.sessionId,
      );
  @override
  String toString() {
    return (StringBuffer('SessionRule(')
          ..write('id: $id, ')
          ..write('appId: $appId, ')
          ..write('action: $action, ')
          ..write('sessionId: $sessionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, appId, action, sessionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRule &&
          other.id == this.id &&
          other.appId == this.appId &&
          other.action == this.action &&
          other.sessionId == this.sessionId);
}

class SessionRulesCompanion extends UpdateCompanion<SessionRule> {
  final Value<String> id;
  final Value<String> appId;
  final Value<String> action;
  final Value<String> sessionId;
  final Value<int> rowid;
  const SessionRulesCompanion({
    this.id = const Value.absent(),
    this.appId = const Value.absent(),
    this.action = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionRulesCompanion.insert({
    required String id,
    required String appId,
    required String action,
    required String sessionId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        appId = Value(appId),
        action = Value(action),
        sessionId = Value(sessionId);
  static Insertable<SessionRule> custom({
    Expression<String>? id,
    Expression<String>? appId,
    Expression<String>? action,
    Expression<String>? sessionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (appId != null) 'app_id': appId,
      if (action != null) 'action': action,
      if (sessionId != null) 'session_id': sessionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionRulesCompanion copyWith(
      {Value<String>? id,
      Value<String>? appId,
      Value<String>? action,
      Value<String>? sessionId,
      Value<int>? rowid}) {
    return SessionRulesCompanion(
      id: id ?? this.id,
      appId: appId ?? this.appId,
      action: action ?? this.action,
      sessionId: sessionId ?? this.sessionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (appId.present) {
      map['app_id'] = Variable<String>(appId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionRulesCompanion(')
          ..write('id: $id, ')
          ..write('appId: $appId, ')
          ..write('action: $action, ')
          ..write('sessionId: $sessionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrustedNetworksTable extends TrustedNetworks
    with TableInfo<$TrustedNetworksTable, TrustedNetwork> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrustedNetworksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ssidMeta = const VerificationMeta('ssid');
  @override
  late final GeneratedColumn<String> ssid = GeneratedColumn<String>(
      'ssid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bssidMeta = const VerificationMeta('bssid');
  @override
  late final GeneratedColumn<String> bssid = GeneratedColumn<String>(
      'bssid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _trustLevelMeta =
      const VerificationMeta('trustLevel');
  @override
  late final GeneratedColumn<String> trustLevel = GeneratedColumn<String>(
      'trust_level', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profile_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, ssid, bssid, trustLevel, profileId];
  @override
  String get aliasedName => _alias ?? 'trusted_networks';
  @override
  String get actualTableName => 'trusted_networks';
  @override
  VerificationContext validateIntegrity(Insertable<TrustedNetwork> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ssid')) {
      context.handle(
          _ssidMeta, ssid.isAcceptableOrUnknown(data['ssid']!, _ssidMeta));
    } else if (isInserting) {
      context.missing(_ssidMeta);
    }
    if (data.containsKey('bssid')) {
      context.handle(
          _bssidMeta, bssid.isAcceptableOrUnknown(data['bssid']!, _bssidMeta));
    } else if (isInserting) {
      context.missing(_bssidMeta);
    }
    if (data.containsKey('trust_level')) {
      context.handle(
          _trustLevelMeta,
          trustLevel.isAcceptableOrUnknown(
              data['trust_level']!, _trustLevelMeta));
    } else if (isInserting) {
      context.missing(_trustLevelMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrustedNetwork map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrustedNetwork(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      ssid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ssid'])!,
      bssid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bssid'])!,
      trustLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trust_level'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_id'])!,
    );
  }

  @override
  $TrustedNetworksTable createAlias(String alias) {
    return $TrustedNetworksTable(attachedDatabase, alias);
  }
}

class TrustedNetwork extends DataClass implements Insertable<TrustedNetwork> {
  final String id;
  final String ssid;
  final String bssid;
  final String trustLevel;
  final String profileId;
  const TrustedNetwork(
      {required this.id,
      required this.ssid,
      required this.bssid,
      required this.trustLevel,
      required this.profileId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['ssid'] = Variable<String>(ssid);
    map['bssid'] = Variable<String>(bssid);
    map['trust_level'] = Variable<String>(trustLevel);
    map['profile_id'] = Variable<String>(profileId);
    return map;
  }

  TrustedNetworksCompanion toCompanion(bool nullToAbsent) {
    return TrustedNetworksCompanion(
      id: Value(id),
      ssid: Value(ssid),
      bssid: Value(bssid),
      trustLevel: Value(trustLevel),
      profileId: Value(profileId),
    );
  }

  factory TrustedNetwork.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrustedNetwork(
      id: serializer.fromJson<String>(json['id']),
      ssid: serializer.fromJson<String>(json['ssid']),
      bssid: serializer.fromJson<String>(json['bssid']),
      trustLevel: serializer.fromJson<String>(json['trustLevel']),
      profileId: serializer.fromJson<String>(json['profileId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ssid': serializer.toJson<String>(ssid),
      'bssid': serializer.toJson<String>(bssid),
      'trustLevel': serializer.toJson<String>(trustLevel),
      'profileId': serializer.toJson<String>(profileId),
    };
  }

  TrustedNetwork copyWith(
          {String? id,
          String? ssid,
          String? bssid,
          String? trustLevel,
          String? profileId}) =>
      TrustedNetwork(
        id: id ?? this.id,
        ssid: ssid ?? this.ssid,
        bssid: bssid ?? this.bssid,
        trustLevel: trustLevel ?? this.trustLevel,
        profileId: profileId ?? this.profileId,
      );
  @override
  String toString() {
    return (StringBuffer('TrustedNetwork(')
          ..write('id: $id, ')
          ..write('ssid: $ssid, ')
          ..write('bssid: $bssid, ')
          ..write('trustLevel: $trustLevel, ')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ssid, bssid, trustLevel, profileId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrustedNetwork &&
          other.id == this.id &&
          other.ssid == this.ssid &&
          other.bssid == this.bssid &&
          other.trustLevel == this.trustLevel &&
          other.profileId == this.profileId);
}

class TrustedNetworksCompanion extends UpdateCompanion<TrustedNetwork> {
  final Value<String> id;
  final Value<String> ssid;
  final Value<String> bssid;
  final Value<String> trustLevel;
  final Value<String> profileId;
  final Value<int> rowid;
  const TrustedNetworksCompanion({
    this.id = const Value.absent(),
    this.ssid = const Value.absent(),
    this.bssid = const Value.absent(),
    this.trustLevel = const Value.absent(),
    this.profileId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrustedNetworksCompanion.insert({
    required String id,
    required String ssid,
    required String bssid,
    required String trustLevel,
    required String profileId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        ssid = Value(ssid),
        bssid = Value(bssid),
        trustLevel = Value(trustLevel),
        profileId = Value(profileId);
  static Insertable<TrustedNetwork> custom({
    Expression<String>? id,
    Expression<String>? ssid,
    Expression<String>? bssid,
    Expression<String>? trustLevel,
    Expression<String>? profileId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ssid != null) 'ssid': ssid,
      if (bssid != null) 'bssid': bssid,
      if (trustLevel != null) 'trust_level': trustLevel,
      if (profileId != null) 'profile_id': profileId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrustedNetworksCompanion copyWith(
      {Value<String>? id,
      Value<String>? ssid,
      Value<String>? bssid,
      Value<String>? trustLevel,
      Value<String>? profileId,
      Value<int>? rowid}) {
    return TrustedNetworksCompanion(
      id: id ?? this.id,
      ssid: ssid ?? this.ssid,
      bssid: bssid ?? this.bssid,
      trustLevel: trustLevel ?? this.trustLevel,
      profileId: profileId ?? this.profileId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ssid.present) {
      map['ssid'] = Variable<String>(ssid.value);
    }
    if (bssid.present) {
      map['bssid'] = Variable<String>(bssid.value);
    }
    if (trustLevel.present) {
      map['trust_level'] = Variable<String>(trustLevel.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrustedNetworksCompanion(')
          ..write('id: $id, ')
          ..write('ssid: $ssid, ')
          ..write('bssid: $bssid, ')
          ..write('trustLevel: $trustLevel, ')
          ..write('profileId: $profileId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DnsProfilesTable extends DnsProfiles
    with TableInfo<$DnsProfilesTable, DnsProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DnsProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerMeta =
      const VerificationMeta('provider');
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
      'provider', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _protocolMeta =
      const VerificationMeta('protocol');
  @override
  late final GeneratedColumn<String> protocol = GeneratedColumn<String>(
      'protocol', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _endpointMeta =
      const VerificationMeta('endpoint');
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
      'endpoint', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _blocklistsMeta =
      const VerificationMeta('blocklists');
  @override
  late final GeneratedColumn<String> blocklists = GeneratedColumn<String>(
      'blocklists', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, provider, protocol, endpoint, blocklists];
  @override
  String get aliasedName => _alias ?? 'dns_profiles';
  @override
  String get actualTableName => 'dns_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<DnsProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(_providerMeta,
          provider.isAcceptableOrUnknown(data['provider']!, _providerMeta));
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('protocol')) {
      context.handle(_protocolMeta,
          protocol.isAcceptableOrUnknown(data['protocol']!, _protocolMeta));
    } else if (isInserting) {
      context.missing(_protocolMeta);
    }
    if (data.containsKey('endpoint')) {
      context.handle(_endpointMeta,
          endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta));
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('blocklists')) {
      context.handle(
          _blocklistsMeta,
          blocklists.isAcceptableOrUnknown(
              data['blocklists']!, _blocklistsMeta));
    } else if (isInserting) {
      context.missing(_blocklistsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DnsProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DnsProfile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      provider: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider'])!,
      protocol: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}protocol'])!,
      endpoint: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}endpoint'])!,
      blocklists: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}blocklists'])!,
    );
  }

  @override
  $DnsProfilesTable createAlias(String alias) {
    return $DnsProfilesTable(attachedDatabase, alias);
  }
}

class DnsProfile extends DataClass implements Insertable<DnsProfile> {
  final String id;
  final String name;
  final String provider;
  final String protocol;
  final String endpoint;
  final String blocklists;
  const DnsProfile(
      {required this.id,
      required this.name,
      required this.provider,
      required this.protocol,
      required this.endpoint,
      required this.blocklists});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['provider'] = Variable<String>(provider);
    map['protocol'] = Variable<String>(protocol);
    map['endpoint'] = Variable<String>(endpoint);
    map['blocklists'] = Variable<String>(blocklists);
    return map;
  }

  DnsProfilesCompanion toCompanion(bool nullToAbsent) {
    return DnsProfilesCompanion(
      id: Value(id),
      name: Value(name),
      provider: Value(provider),
      protocol: Value(protocol),
      endpoint: Value(endpoint),
      blocklists: Value(blocklists),
    );
  }

  factory DnsProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DnsProfile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      provider: serializer.fromJson<String>(json['provider']),
      protocol: serializer.fromJson<String>(json['protocol']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      blocklists: serializer.fromJson<String>(json['blocklists']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'provider': serializer.toJson<String>(provider),
      'protocol': serializer.toJson<String>(protocol),
      'endpoint': serializer.toJson<String>(endpoint),
      'blocklists': serializer.toJson<String>(blocklists),
    };
  }

  DnsProfile copyWith(
          {String? id,
          String? name,
          String? provider,
          String? protocol,
          String? endpoint,
          String? blocklists}) =>
      DnsProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        provider: provider ?? this.provider,
        protocol: protocol ?? this.protocol,
        endpoint: endpoint ?? this.endpoint,
        blocklists: blocklists ?? this.blocklists,
      );
  @override
  String toString() {
    return (StringBuffer('DnsProfile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('provider: $provider, ')
          ..write('protocol: $protocol, ')
          ..write('endpoint: $endpoint, ')
          ..write('blocklists: $blocklists')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, provider, protocol, endpoint, blocklists);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DnsProfile &&
          other.id == this.id &&
          other.name == this.name &&
          other.provider == this.provider &&
          other.protocol == this.protocol &&
          other.endpoint == this.endpoint &&
          other.blocklists == this.blocklists);
}

class DnsProfilesCompanion extends UpdateCompanion<DnsProfile> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> provider;
  final Value<String> protocol;
  final Value<String> endpoint;
  final Value<String> blocklists;
  final Value<int> rowid;
  const DnsProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.provider = const Value.absent(),
    this.protocol = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.blocklists = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DnsProfilesCompanion.insert({
    required String id,
    required String name,
    required String provider,
    required String protocol,
    required String endpoint,
    required String blocklists,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        provider = Value(provider),
        protocol = Value(protocol),
        endpoint = Value(endpoint),
        blocklists = Value(blocklists);
  static Insertable<DnsProfile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? provider,
    Expression<String>? protocol,
    Expression<String>? endpoint,
    Expression<String>? blocklists,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (provider != null) 'provider': provider,
      if (protocol != null) 'protocol': protocol,
      if (endpoint != null) 'endpoint': endpoint,
      if (blocklists != null) 'blocklists': blocklists,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DnsProfilesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? provider,
      Value<String>? protocol,
      Value<String>? endpoint,
      Value<String>? blocklists,
      Value<int>? rowid}) {
    return DnsProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      protocol: protocol ?? this.protocol,
      endpoint: endpoint ?? this.endpoint,
      blocklists: blocklists ?? this.blocklists,
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
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (protocol.present) {
      map['protocol'] = Variable<String>(protocol.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (blocklists.present) {
      map['blocklists'] = Variable<String>(blocklists.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DnsProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('provider: $provider, ')
          ..write('protocol: $protocol, ')
          ..write('endpoint: $endpoint, ')
          ..write('blocklists: $blocklists, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DnsBlocklistsTable extends DnsBlocklists
    with TableInfo<$DnsBlocklistsTable, DnsBlocklist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DnsBlocklistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _enabledMeta =
      const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
      'enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _checksumMeta =
      const VerificationMeta('checksum');
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
      'checksum', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _domainCountMeta =
      const VerificationMeta('domainCount');
  @override
  late final GeneratedColumn<int> domainCount = GeneratedColumn<int>(
      'domain_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, category, enabled, url, checksum, updatedAt, domainCount];
  @override
  String get aliasedName => _alias ?? 'dns_blocklists';
  @override
  String get actualTableName => 'dns_blocklists';
  @override
  VerificationContext validateIntegrity(Insertable<DnsBlocklist> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(_checksumMeta,
          checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('domain_count')) {
      context.handle(
          _domainCountMeta,
          domainCount.isAcceptableOrUnknown(
              data['domain_count']!, _domainCountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DnsBlocklist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DnsBlocklist(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url'])!,
      checksum: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}checksum']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      domainCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}domain_count']),
    );
  }

  @override
  $DnsBlocklistsTable createAlias(String alias) {
    return $DnsBlocklistsTable(attachedDatabase, alias);
  }
}

class DnsBlocklist extends DataClass implements Insertable<DnsBlocklist> {
  final String id;
  final String name;
  final String category;
  final bool enabled;
  final String url;
  final String? checksum;
  final int updatedAt;
  final int? domainCount;
  const DnsBlocklist(
      {required this.id,
      required this.name,
      required this.category,
      required this.enabled,
      required this.url,
      this.checksum,
      required this.updatedAt,
      this.domainCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['enabled'] = Variable<bool>(enabled);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || checksum != null) {
      map['checksum'] = Variable<String>(checksum);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || domainCount != null) {
      map['domain_count'] = Variable<int>(domainCount);
    }
    return map;
  }

  DnsBlocklistsCompanion toCompanion(bool nullToAbsent) {
    return DnsBlocklistsCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      enabled: Value(enabled),
      url: Value(url),
      checksum: checksum == null && nullToAbsent
          ? const Value.absent()
          : Value(checksum),
      updatedAt: Value(updatedAt),
      domainCount: domainCount == null && nullToAbsent
          ? const Value.absent()
          : Value(domainCount),
    );
  }

  factory DnsBlocklist.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DnsBlocklist(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      url: serializer.fromJson<String>(json['url']),
      checksum: serializer.fromJson<String?>(json['checksum']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      domainCount: serializer.fromJson<int?>(json['domainCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'enabled': serializer.toJson<bool>(enabled),
      'url': serializer.toJson<String>(url),
      'checksum': serializer.toJson<String?>(checksum),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'domainCount': serializer.toJson<int?>(domainCount),
    };
  }

  DnsBlocklist copyWith(
          {String? id,
          String? name,
          String? category,
          bool? enabled,
          String? url,
          Value<String?> checksum = const Value.absent(),
          int? updatedAt,
          Value<int?> domainCount = const Value.absent()}) =>
      DnsBlocklist(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        enabled: enabled ?? this.enabled,
        url: url ?? this.url,
        checksum: checksum.present ? checksum.value : this.checksum,
        updatedAt: updatedAt ?? this.updatedAt,
        domainCount: domainCount.present ? domainCount.value : this.domainCount,
      );
  @override
  String toString() {
    return (StringBuffer('DnsBlocklist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('enabled: $enabled, ')
          ..write('url: $url, ')
          ..write('checksum: $checksum, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('domainCount: $domainCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, category, enabled, url, checksum, updatedAt, domainCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DnsBlocklist &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.enabled == this.enabled &&
          other.url == this.url &&
          other.checksum == this.checksum &&
          other.updatedAt == this.updatedAt &&
          other.domainCount == this.domainCount);
}

class DnsBlocklistsCompanion extends UpdateCompanion<DnsBlocklist> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> category;
  final Value<bool> enabled;
  final Value<String> url;
  final Value<String?> checksum;
  final Value<int> updatedAt;
  final Value<int?> domainCount;
  final Value<int> rowid;
  const DnsBlocklistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.enabled = const Value.absent(),
    this.url = const Value.absent(),
    this.checksum = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.domainCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DnsBlocklistsCompanion.insert({
    required String id,
    required String name,
    required String category,
    this.enabled = const Value.absent(),
    required String url,
    this.checksum = const Value.absent(),
    required int updatedAt,
    this.domainCount = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        category = Value(category),
        url = Value(url),
        updatedAt = Value(updatedAt);
  static Insertable<DnsBlocklist> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<bool>? enabled,
    Expression<String>? url,
    Expression<String>? checksum,
    Expression<int>? updatedAt,
    Expression<int>? domainCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (enabled != null) 'enabled': enabled,
      if (url != null) 'url': url,
      if (checksum != null) 'checksum': checksum,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (domainCount != null) 'domain_count': domainCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DnsBlocklistsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? category,
      Value<bool>? enabled,
      Value<String>? url,
      Value<String?>? checksum,
      Value<int>? updatedAt,
      Value<int?>? domainCount,
      Value<int>? rowid}) {
    return DnsBlocklistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      enabled: enabled ?? this.enabled,
      url: url ?? this.url,
      checksum: checksum ?? this.checksum,
      updatedAt: updatedAt ?? this.updatedAt,
      domainCount: domainCount ?? this.domainCount,
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
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (domainCount.present) {
      map['domain_count'] = Variable<int>(domainCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DnsBlocklistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('enabled: $enabled, ')
          ..write('url: $url, ')
          ..write('checksum: $checksum, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('domainCount: $domainCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DnsLogsTable extends DnsLogs with TableInfo<$DnsLogsTable, DnsLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DnsLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
      'domain', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _latencyMsMeta =
      const VerificationMeta('latencyMs');
  @override
  late final GeneratedColumn<int> latencyMs = GeneratedColumn<int>(
      'latency_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _appIdMeta = const VerificationMeta('appId');
  @override
  late final GeneratedColumn<String> appId = GeneratedColumn<String>(
      'app_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _countryCodeMeta =
      const VerificationMeta('countryCode');
  @override
  late final GeneratedColumn<String> countryCode = GeneratedColumn<String>(
      'country_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, domain, action, category, latencyMs, appId, countryCode, timestamp];
  @override
  String get aliasedName => _alias ?? 'dns_logs';
  @override
  String get actualTableName => 'dns_logs';
  @override
  VerificationContext validateIntegrity(Insertable<DnsLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('domain')) {
      context.handle(_domainMeta,
          domain.isAcceptableOrUnknown(data['domain']!, _domainMeta));
    } else if (isInserting) {
      context.missing(_domainMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('latency_ms')) {
      context.handle(_latencyMsMeta,
          latencyMs.isAcceptableOrUnknown(data['latency_ms']!, _latencyMsMeta));
    }
    if (data.containsKey('app_id')) {
      context.handle(
          _appIdMeta, appId.isAcceptableOrUnknown(data['app_id']!, _appIdMeta));
    }
    if (data.containsKey('country_code')) {
      context.handle(
          _countryCodeMeta,
          countryCode.isAcceptableOrUnknown(
              data['country_code']!, _countryCodeMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DnsLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DnsLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      domain: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}domain'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      latencyMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}latency_ms']),
      appId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_id']),
      countryCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}country_code']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $DnsLogsTable createAlias(String alias) {
    return $DnsLogsTable(attachedDatabase, alias);
  }
}

class DnsLog extends DataClass implements Insertable<DnsLog> {
  final int id;
  final String domain;
  final String action;
  final String? category;
  final int? latencyMs;
  final String? appId;
  final String? countryCode;
  final int timestamp;
  const DnsLog(
      {required this.id,
      required this.domain,
      required this.action,
      this.category,
      this.latencyMs,
      this.appId,
      this.countryCode,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['domain'] = Variable<String>(domain);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || latencyMs != null) {
      map['latency_ms'] = Variable<int>(latencyMs);
    }
    if (!nullToAbsent || appId != null) {
      map['app_id'] = Variable<String>(appId);
    }
    if (!nullToAbsent || countryCode != null) {
      map['country_code'] = Variable<String>(countryCode);
    }
    map['timestamp'] = Variable<int>(timestamp);
    return map;
  }

  DnsLogsCompanion toCompanion(bool nullToAbsent) {
    return DnsLogsCompanion(
      id: Value(id),
      domain: Value(domain),
      action: Value(action),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      latencyMs: latencyMs == null && nullToAbsent
          ? const Value.absent()
          : Value(latencyMs),
      appId:
          appId == null && nullToAbsent ? const Value.absent() : Value(appId),
      countryCode: countryCode == null && nullToAbsent
          ? const Value.absent()
          : Value(countryCode),
      timestamp: Value(timestamp),
    );
  }

  factory DnsLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DnsLog(
      id: serializer.fromJson<int>(json['id']),
      domain: serializer.fromJson<String>(json['domain']),
      action: serializer.fromJson<String>(json['action']),
      category: serializer.fromJson<String?>(json['category']),
      latencyMs: serializer.fromJson<int?>(json['latencyMs']),
      appId: serializer.fromJson<String?>(json['appId']),
      countryCode: serializer.fromJson<String?>(json['countryCode']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'domain': serializer.toJson<String>(domain),
      'action': serializer.toJson<String>(action),
      'category': serializer.toJson<String?>(category),
      'latencyMs': serializer.toJson<int?>(latencyMs),
      'appId': serializer.toJson<String?>(appId),
      'countryCode': serializer.toJson<String?>(countryCode),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  DnsLog copyWith(
          {int? id,
          String? domain,
          String? action,
          Value<String?> category = const Value.absent(),
          Value<int?> latencyMs = const Value.absent(),
          Value<String?> appId = const Value.absent(),
          Value<String?> countryCode = const Value.absent(),
          int? timestamp}) =>
      DnsLog(
        id: id ?? this.id,
        domain: domain ?? this.domain,
        action: action ?? this.action,
        category: category.present ? category.value : this.category,
        latencyMs: latencyMs.present ? latencyMs.value : this.latencyMs,
        appId: appId.present ? appId.value : this.appId,
        countryCode: countryCode.present ? countryCode.value : this.countryCode,
        timestamp: timestamp ?? this.timestamp,
      );
  @override
  String toString() {
    return (StringBuffer('DnsLog(')
          ..write('id: $id, ')
          ..write('domain: $domain, ')
          ..write('action: $action, ')
          ..write('category: $category, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('appId: $appId, ')
          ..write('countryCode: $countryCode, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, domain, action, category, latencyMs, appId, countryCode, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DnsLog &&
          other.id == this.id &&
          other.domain == this.domain &&
          other.action == this.action &&
          other.category == this.category &&
          other.latencyMs == this.latencyMs &&
          other.appId == this.appId &&
          other.countryCode == this.countryCode &&
          other.timestamp == this.timestamp);
}

class DnsLogsCompanion extends UpdateCompanion<DnsLog> {
  final Value<int> id;
  final Value<String> domain;
  final Value<String> action;
  final Value<String?> category;
  final Value<int?> latencyMs;
  final Value<String?> appId;
  final Value<String?> countryCode;
  final Value<int> timestamp;
  const DnsLogsCompanion({
    this.id = const Value.absent(),
    this.domain = const Value.absent(),
    this.action = const Value.absent(),
    this.category = const Value.absent(),
    this.latencyMs = const Value.absent(),
    this.appId = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  DnsLogsCompanion.insert({
    this.id = const Value.absent(),
    required String domain,
    required String action,
    this.category = const Value.absent(),
    this.latencyMs = const Value.absent(),
    this.appId = const Value.absent(),
    this.countryCode = const Value.absent(),
    required int timestamp,
  })  : domain = Value(domain),
        action = Value(action),
        timestamp = Value(timestamp);
  static Insertable<DnsLog> custom({
    Expression<int>? id,
    Expression<String>? domain,
    Expression<String>? action,
    Expression<String>? category,
    Expression<int>? latencyMs,
    Expression<String>? appId,
    Expression<String>? countryCode,
    Expression<int>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (domain != null) 'domain': domain,
      if (action != null) 'action': action,
      if (category != null) 'category': category,
      if (latencyMs != null) 'latency_ms': latencyMs,
      if (appId != null) 'app_id': appId,
      if (countryCode != null) 'country_code': countryCode,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  DnsLogsCompanion copyWith(
      {Value<int>? id,
      Value<String>? domain,
      Value<String>? action,
      Value<String?>? category,
      Value<int?>? latencyMs,
      Value<String?>? appId,
      Value<String?>? countryCode,
      Value<int>? timestamp}) {
    return DnsLogsCompanion(
      id: id ?? this.id,
      domain: domain ?? this.domain,
      action: action ?? this.action,
      category: category ?? this.category,
      latencyMs: latencyMs ?? this.latencyMs,
      appId: appId ?? this.appId,
      countryCode: countryCode ?? this.countryCode,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (latencyMs.present) {
      map['latency_ms'] = Variable<int>(latencyMs.value);
    }
    if (appId.present) {
      map['app_id'] = Variable<String>(appId.value);
    }
    if (countryCode.present) {
      map['country_code'] = Variable<String>(countryCode.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DnsLogsCompanion(')
          ..write('id: $id, ')
          ..write('domain: $domain, ')
          ..write('action: $action, ')
          ..write('category: $category, ')
          ..write('latencyMs: $latencyMs, ')
          ..write('appId: $appId, ')
          ..write('countryCode: $countryCode, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $ApplicationsTable extends Applications
    with TableInfo<$ApplicationsTable, Application> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApplicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _packageNameMeta =
      const VerificationMeta('packageName');
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
      'package_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
      'version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _firstSeenMeta =
      const VerificationMeta('firstSeen');
  @override
  late final GeneratedColumn<int> firstSeen = GeneratedColumn<int>(
      'first_seen', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _iconBytesMeta =
      const VerificationMeta('iconBytes');
  @override
  late final GeneratedColumn<Uint8List> iconBytes = GeneratedColumn<Uint8List>(
      'icon_bytes', aliasedName, true,
      type: DriftSqlType.blob, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, packageName, displayName, version, firstSeen, iconBytes];
  @override
  String get aliasedName => _alias ?? 'applications';
  @override
  String get actualTableName => 'applications';
  @override
  VerificationContext validateIntegrity(Insertable<Application> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
          _packageNameMeta,
          packageName.isAcceptableOrUnknown(
              data['package_name']!, _packageNameMeta));
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('first_seen')) {
      context.handle(_firstSeenMeta,
          firstSeen.isAcceptableOrUnknown(data['first_seen']!, _firstSeenMeta));
    } else if (isInserting) {
      context.missing(_firstSeenMeta);
    }
    if (data.containsKey('icon_bytes')) {
      context.handle(_iconBytesMeta,
          iconBytes.isAcceptableOrUnknown(data['icon_bytes']!, _iconBytesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Application map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Application(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      packageName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}package_name'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}version']),
      firstSeen: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}first_seen'])!,
      iconBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}icon_bytes']),
    );
  }

  @override
  $ApplicationsTable createAlias(String alias) {
    return $ApplicationsTable(attachedDatabase, alias);
  }
}

class Application extends DataClass implements Insertable<Application> {
  final String id;
  final String packageName;
  final String displayName;
  final String? version;
  final int firstSeen;
  final Uint8List? iconBytes;
  const Application(
      {required this.id,
      required this.packageName,
      required this.displayName,
      this.version,
      required this.firstSeen,
      this.iconBytes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['package_name'] = Variable<String>(packageName);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<String>(version);
    }
    map['first_seen'] = Variable<int>(firstSeen);
    if (!nullToAbsent || iconBytes != null) {
      map['icon_bytes'] = Variable<Uint8List>(iconBytes);
    }
    return map;
  }

  ApplicationsCompanion toCompanion(bool nullToAbsent) {
    return ApplicationsCompanion(
      id: Value(id),
      packageName: Value(packageName),
      displayName: Value(displayName),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      firstSeen: Value(firstSeen),
      iconBytes: iconBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(iconBytes),
    );
  }

  factory Application.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Application(
      id: serializer.fromJson<String>(json['id']),
      packageName: serializer.fromJson<String>(json['packageName']),
      displayName: serializer.fromJson<String>(json['displayName']),
      version: serializer.fromJson<String?>(json['version']),
      firstSeen: serializer.fromJson<int>(json['firstSeen']),
      iconBytes: serializer.fromJson<Uint8List?>(json['iconBytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'packageName': serializer.toJson<String>(packageName),
      'displayName': serializer.toJson<String>(displayName),
      'version': serializer.toJson<String?>(version),
      'firstSeen': serializer.toJson<int>(firstSeen),
      'iconBytes': serializer.toJson<Uint8List?>(iconBytes),
    };
  }

  Application copyWith(
          {String? id,
          String? packageName,
          String? displayName,
          Value<String?> version = const Value.absent(),
          int? firstSeen,
          Value<Uint8List?> iconBytes = const Value.absent()}) =>
      Application(
        id: id ?? this.id,
        packageName: packageName ?? this.packageName,
        displayName: displayName ?? this.displayName,
        version: version.present ? version.value : this.version,
        firstSeen: firstSeen ?? this.firstSeen,
        iconBytes: iconBytes.present ? iconBytes.value : this.iconBytes,
      );
  @override
  String toString() {
    return (StringBuffer('Application(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('displayName: $displayName, ')
          ..write('version: $version, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('iconBytes: $iconBytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, packageName, displayName, version,
      firstSeen, $driftBlobEquality.hash(iconBytes));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Application &&
          other.id == this.id &&
          other.packageName == this.packageName &&
          other.displayName == this.displayName &&
          other.version == this.version &&
          other.firstSeen == this.firstSeen &&
          $driftBlobEquality.equals(other.iconBytes, this.iconBytes));
}

class ApplicationsCompanion extends UpdateCompanion<Application> {
  final Value<String> id;
  final Value<String> packageName;
  final Value<String> displayName;
  final Value<String?> version;
  final Value<int> firstSeen;
  final Value<Uint8List?> iconBytes;
  final Value<int> rowid;
  const ApplicationsCompanion({
    this.id = const Value.absent(),
    this.packageName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.version = const Value.absent(),
    this.firstSeen = const Value.absent(),
    this.iconBytes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApplicationsCompanion.insert({
    required String id,
    required String packageName,
    required String displayName,
    this.version = const Value.absent(),
    required int firstSeen,
    this.iconBytes = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        packageName = Value(packageName),
        displayName = Value(displayName),
        firstSeen = Value(firstSeen);
  static Insertable<Application> custom({
    Expression<String>? id,
    Expression<String>? packageName,
    Expression<String>? displayName,
    Expression<String>? version,
    Expression<int>? firstSeen,
    Expression<Uint8List>? iconBytes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packageName != null) 'package_name': packageName,
      if (displayName != null) 'display_name': displayName,
      if (version != null) 'version': version,
      if (firstSeen != null) 'first_seen': firstSeen,
      if (iconBytes != null) 'icon_bytes': iconBytes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApplicationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? packageName,
      Value<String>? displayName,
      Value<String?>? version,
      Value<int>? firstSeen,
      Value<Uint8List?>? iconBytes,
      Value<int>? rowid}) {
    return ApplicationsCompanion(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      displayName: displayName ?? this.displayName,
      version: version ?? this.version,
      firstSeen: firstSeen ?? this.firstSeen,
      iconBytes: iconBytes ?? this.iconBytes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (firstSeen.present) {
      map['first_seen'] = Variable<int>(firstSeen.value);
    }
    if (iconBytes.present) {
      map['icon_bytes'] = Variable<Uint8List>(iconBytes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApplicationsCompanion(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('displayName: $displayName, ')
          ..write('version: $version, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('iconBytes: $iconBytes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ApplicationStatsTable extends ApplicationStats
    with TableInfo<$ApplicationStatsTable, ApplicationStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApplicationStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _appIdMeta = const VerificationMeta('appId');
  @override
  late final GeneratedColumn<String> appId = GeneratedColumn<String>(
      'app_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _connectionsMeta =
      const VerificationMeta('connections');
  @override
  late final GeneratedColumn<int> connections = GeneratedColumn<int>(
      'connections', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _blockedMeta =
      const VerificationMeta('blocked');
  @override
  late final GeneratedColumn<int> blocked = GeneratedColumn<int>(
      'blocked', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _bytesSentMeta =
      const VerificationMeta('bytesSent');
  @override
  late final GeneratedColumn<int> bytesSent = GeneratedColumn<int>(
      'bytes_sent', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _bytesRecvMeta =
      const VerificationMeta('bytesRecv');
  @override
  late final GeneratedColumn<int> bytesRecv = GeneratedColumn<int>(
      'bytes_recv', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _statDateMeta =
      const VerificationMeta('statDate');
  @override
  late final GeneratedColumn<String> statDate = GeneratedColumn<String>(
      'stat_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, appId, connections, blocked, bytesSent, bytesRecv, statDate];
  @override
  String get aliasedName => _alias ?? 'application_stats';
  @override
  String get actualTableName => 'application_stats';
  @override
  VerificationContext validateIntegrity(Insertable<ApplicationStat> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('app_id')) {
      context.handle(
          _appIdMeta, appId.isAcceptableOrUnknown(data['app_id']!, _appIdMeta));
    } else if (isInserting) {
      context.missing(_appIdMeta);
    }
    if (data.containsKey('connections')) {
      context.handle(
          _connectionsMeta,
          connections.isAcceptableOrUnknown(
              data['connections']!, _connectionsMeta));
    }
    if (data.containsKey('blocked')) {
      context.handle(_blockedMeta,
          blocked.isAcceptableOrUnknown(data['blocked']!, _blockedMeta));
    }
    if (data.containsKey('bytes_sent')) {
      context.handle(_bytesSentMeta,
          bytesSent.isAcceptableOrUnknown(data['bytes_sent']!, _bytesSentMeta));
    }
    if (data.containsKey('bytes_recv')) {
      context.handle(_bytesRecvMeta,
          bytesRecv.isAcceptableOrUnknown(data['bytes_recv']!, _bytesRecvMeta));
    }
    if (data.containsKey('stat_date')) {
      context.handle(_statDateMeta,
          statDate.isAcceptableOrUnknown(data['stat_date']!, _statDateMeta));
    } else if (isInserting) {
      context.missing(_statDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ApplicationStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApplicationStat(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      appId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_id'])!,
      connections: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}connections'])!,
      blocked: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}blocked'])!,
      bytesSent: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bytes_sent'])!,
      bytesRecv: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bytes_recv'])!,
      statDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stat_date'])!,
    );
  }

  @override
  $ApplicationStatsTable createAlias(String alias) {
    return $ApplicationStatsTable(attachedDatabase, alias);
  }
}

class ApplicationStat extends DataClass implements Insertable<ApplicationStat> {
  final String id;
  final String appId;
  final int connections;
  final int blocked;
  final int bytesSent;
  final int bytesRecv;
  final String statDate;
  const ApplicationStat(
      {required this.id,
      required this.appId,
      required this.connections,
      required this.blocked,
      required this.bytesSent,
      required this.bytesRecv,
      required this.statDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['app_id'] = Variable<String>(appId);
    map['connections'] = Variable<int>(connections);
    map['blocked'] = Variable<int>(blocked);
    map['bytes_sent'] = Variable<int>(bytesSent);
    map['bytes_recv'] = Variable<int>(bytesRecv);
    map['stat_date'] = Variable<String>(statDate);
    return map;
  }

  ApplicationStatsCompanion toCompanion(bool nullToAbsent) {
    return ApplicationStatsCompanion(
      id: Value(id),
      appId: Value(appId),
      connections: Value(connections),
      blocked: Value(blocked),
      bytesSent: Value(bytesSent),
      bytesRecv: Value(bytesRecv),
      statDate: Value(statDate),
    );
  }

  factory ApplicationStat.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApplicationStat(
      id: serializer.fromJson<String>(json['id']),
      appId: serializer.fromJson<String>(json['appId']),
      connections: serializer.fromJson<int>(json['connections']),
      blocked: serializer.fromJson<int>(json['blocked']),
      bytesSent: serializer.fromJson<int>(json['bytesSent']),
      bytesRecv: serializer.fromJson<int>(json['bytesRecv']),
      statDate: serializer.fromJson<String>(json['statDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'appId': serializer.toJson<String>(appId),
      'connections': serializer.toJson<int>(connections),
      'blocked': serializer.toJson<int>(blocked),
      'bytesSent': serializer.toJson<int>(bytesSent),
      'bytesRecv': serializer.toJson<int>(bytesRecv),
      'statDate': serializer.toJson<String>(statDate),
    };
  }

  ApplicationStat copyWith(
          {String? id,
          String? appId,
          int? connections,
          int? blocked,
          int? bytesSent,
          int? bytesRecv,
          String? statDate}) =>
      ApplicationStat(
        id: id ?? this.id,
        appId: appId ?? this.appId,
        connections: connections ?? this.connections,
        blocked: blocked ?? this.blocked,
        bytesSent: bytesSent ?? this.bytesSent,
        bytesRecv: bytesRecv ?? this.bytesRecv,
        statDate: statDate ?? this.statDate,
      );
  @override
  String toString() {
    return (StringBuffer('ApplicationStat(')
          ..write('id: $id, ')
          ..write('appId: $appId, ')
          ..write('connections: $connections, ')
          ..write('blocked: $blocked, ')
          ..write('bytesSent: $bytesSent, ')
          ..write('bytesRecv: $bytesRecv, ')
          ..write('statDate: $statDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, appId, connections, blocked, bytesSent, bytesRecv, statDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApplicationStat &&
          other.id == this.id &&
          other.appId == this.appId &&
          other.connections == this.connections &&
          other.blocked == this.blocked &&
          other.bytesSent == this.bytesSent &&
          other.bytesRecv == this.bytesRecv &&
          other.statDate == this.statDate);
}

class ApplicationStatsCompanion extends UpdateCompanion<ApplicationStat> {
  final Value<String> id;
  final Value<String> appId;
  final Value<int> connections;
  final Value<int> blocked;
  final Value<int> bytesSent;
  final Value<int> bytesRecv;
  final Value<String> statDate;
  final Value<int> rowid;
  const ApplicationStatsCompanion({
    this.id = const Value.absent(),
    this.appId = const Value.absent(),
    this.connections = const Value.absent(),
    this.blocked = const Value.absent(),
    this.bytesSent = const Value.absent(),
    this.bytesRecv = const Value.absent(),
    this.statDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApplicationStatsCompanion.insert({
    required String id,
    required String appId,
    this.connections = const Value.absent(),
    this.blocked = const Value.absent(),
    this.bytesSent = const Value.absent(),
    this.bytesRecv = const Value.absent(),
    required String statDate,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        appId = Value(appId),
        statDate = Value(statDate);
  static Insertable<ApplicationStat> custom({
    Expression<String>? id,
    Expression<String>? appId,
    Expression<int>? connections,
    Expression<int>? blocked,
    Expression<int>? bytesSent,
    Expression<int>? bytesRecv,
    Expression<String>? statDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (appId != null) 'app_id': appId,
      if (connections != null) 'connections': connections,
      if (blocked != null) 'blocked': blocked,
      if (bytesSent != null) 'bytes_sent': bytesSent,
      if (bytesRecv != null) 'bytes_recv': bytesRecv,
      if (statDate != null) 'stat_date': statDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApplicationStatsCompanion copyWith(
      {Value<String>? id,
      Value<String>? appId,
      Value<int>? connections,
      Value<int>? blocked,
      Value<int>? bytesSent,
      Value<int>? bytesRecv,
      Value<String>? statDate,
      Value<int>? rowid}) {
    return ApplicationStatsCompanion(
      id: id ?? this.id,
      appId: appId ?? this.appId,
      connections: connections ?? this.connections,
      blocked: blocked ?? this.blocked,
      bytesSent: bytesSent ?? this.bytesSent,
      bytesRecv: bytesRecv ?? this.bytesRecv,
      statDate: statDate ?? this.statDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (appId.present) {
      map['app_id'] = Variable<String>(appId.value);
    }
    if (connections.present) {
      map['connections'] = Variable<int>(connections.value);
    }
    if (blocked.present) {
      map['blocked'] = Variable<int>(blocked.value);
    }
    if (bytesSent.present) {
      map['bytes_sent'] = Variable<int>(bytesSent.value);
    }
    if (bytesRecv.present) {
      map['bytes_recv'] = Variable<int>(bytesRecv.value);
    }
    if (statDate.present) {
      map['stat_date'] = Variable<String>(statDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApplicationStatsCompanion(')
          ..write('id: $id, ')
          ..write('appId: $appId, ')
          ..write('connections: $connections, ')
          ..write('blocked: $blocked, ')
          ..write('bytesSent: $bytesSent, ')
          ..write('bytesRecv: $bytesRecv, ')
          ..write('statDate: $statDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConnectionHistoryTable extends ConnectionHistory
    with TableInfo<$ConnectionHistoryTable, ConnectionHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConnectionHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _appIdMeta = const VerificationMeta('appId');
  @override
  late final GeneratedColumn<String> appId = GeneratedColumn<String>(
      'app_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _destHostMeta =
      const VerificationMeta('destHost');
  @override
  late final GeneratedColumn<String> destHost = GeneratedColumn<String>(
      'dest_host', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _destIpMeta = const VerificationMeta('destIp');
  @override
  late final GeneratedColumn<String> destIp = GeneratedColumn<String>(
      'dest_ip', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
      'port', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _protocolMeta =
      const VerificationMeta('protocol');
  @override
  late final GeneratedColumn<String> protocol = GeneratedColumn<String>(
      'protocol', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ruleIdMeta = const VerificationMeta('ruleId');
  @override
  late final GeneratedColumn<String> ruleId = GeneratedColumn<String>(
      'rule_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
      'bytes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _countryCodeMeta =
      const VerificationMeta('countryCode');
  @override
  late final GeneratedColumn<String> countryCode = GeneratedColumn<String>(
      'country_code', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        appId,
        destHost,
        destIp,
        port,
        protocol,
        ruleId,
        action,
        bytes,
        countryCode,
        timestamp
      ];
  @override
  String get aliasedName => _alias ?? 'connection_history';
  @override
  String get actualTableName => 'connection_history';
  @override
  VerificationContext validateIntegrity(
      Insertable<ConnectionHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('app_id')) {
      context.handle(
          _appIdMeta, appId.isAcceptableOrUnknown(data['app_id']!, _appIdMeta));
    } else if (isInserting) {
      context.missing(_appIdMeta);
    }
    if (data.containsKey('dest_host')) {
      context.handle(_destHostMeta,
          destHost.isAcceptableOrUnknown(data['dest_host']!, _destHostMeta));
    } else if (isInserting) {
      context.missing(_destHostMeta);
    }
    if (data.containsKey('dest_ip')) {
      context.handle(_destIpMeta,
          destIp.isAcceptableOrUnknown(data['dest_ip']!, _destIpMeta));
    }
    if (data.containsKey('port')) {
      context.handle(
          _portMeta, port.isAcceptableOrUnknown(data['port']!, _portMeta));
    }
    if (data.containsKey('protocol')) {
      context.handle(_protocolMeta,
          protocol.isAcceptableOrUnknown(data['protocol']!, _protocolMeta));
    }
    if (data.containsKey('rule_id')) {
      context.handle(_ruleIdMeta,
          ruleId.isAcceptableOrUnknown(data['rule_id']!, _ruleIdMeta));
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
          _bytesMeta, bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta));
    }
    if (data.containsKey('country_code')) {
      context.handle(
          _countryCodeMeta,
          countryCode.isAcceptableOrUnknown(
              data['country_code']!, _countryCodeMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConnectionHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConnectionHistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      appId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_id'])!,
      destHost: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dest_host'])!,
      destIp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dest_ip']),
      port: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}port']),
      protocol: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}protocol']),
      ruleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rule_id']),
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      bytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bytes']),
      countryCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}country_code']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $ConnectionHistoryTable createAlias(String alias) {
    return $ConnectionHistoryTable(attachedDatabase, alias);
  }
}

class ConnectionHistoryData extends DataClass
    implements Insertable<ConnectionHistoryData> {
  final int id;
  final String appId;
  final String destHost;
  final String? destIp;
  final int? port;
  final String? protocol;
  final String? ruleId;
  final String action;
  final int? bytes;
  final String? countryCode;
  final int timestamp;
  const ConnectionHistoryData(
      {required this.id,
      required this.appId,
      required this.destHost,
      this.destIp,
      this.port,
      this.protocol,
      this.ruleId,
      required this.action,
      this.bytes,
      this.countryCode,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['app_id'] = Variable<String>(appId);
    map['dest_host'] = Variable<String>(destHost);
    if (!nullToAbsent || destIp != null) {
      map['dest_ip'] = Variable<String>(destIp);
    }
    if (!nullToAbsent || port != null) {
      map['port'] = Variable<int>(port);
    }
    if (!nullToAbsent || protocol != null) {
      map['protocol'] = Variable<String>(protocol);
    }
    if (!nullToAbsent || ruleId != null) {
      map['rule_id'] = Variable<String>(ruleId);
    }
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || bytes != null) {
      map['bytes'] = Variable<int>(bytes);
    }
    if (!nullToAbsent || countryCode != null) {
      map['country_code'] = Variable<String>(countryCode);
    }
    map['timestamp'] = Variable<int>(timestamp);
    return map;
  }

  ConnectionHistoryCompanion toCompanion(bool nullToAbsent) {
    return ConnectionHistoryCompanion(
      id: Value(id),
      appId: Value(appId),
      destHost: Value(destHost),
      destIp:
          destIp == null && nullToAbsent ? const Value.absent() : Value(destIp),
      port: port == null && nullToAbsent ? const Value.absent() : Value(port),
      protocol: protocol == null && nullToAbsent
          ? const Value.absent()
          : Value(protocol),
      ruleId:
          ruleId == null && nullToAbsent ? const Value.absent() : Value(ruleId),
      action: Value(action),
      bytes:
          bytes == null && nullToAbsent ? const Value.absent() : Value(bytes),
      countryCode: countryCode == null && nullToAbsent
          ? const Value.absent()
          : Value(countryCode),
      timestamp: Value(timestamp),
    );
  }

  factory ConnectionHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConnectionHistoryData(
      id: serializer.fromJson<int>(json['id']),
      appId: serializer.fromJson<String>(json['appId']),
      destHost: serializer.fromJson<String>(json['destHost']),
      destIp: serializer.fromJson<String?>(json['destIp']),
      port: serializer.fromJson<int?>(json['port']),
      protocol: serializer.fromJson<String?>(json['protocol']),
      ruleId: serializer.fromJson<String?>(json['ruleId']),
      action: serializer.fromJson<String>(json['action']),
      bytes: serializer.fromJson<int?>(json['bytes']),
      countryCode: serializer.fromJson<String?>(json['countryCode']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'appId': serializer.toJson<String>(appId),
      'destHost': serializer.toJson<String>(destHost),
      'destIp': serializer.toJson<String?>(destIp),
      'port': serializer.toJson<int?>(port),
      'protocol': serializer.toJson<String?>(protocol),
      'ruleId': serializer.toJson<String?>(ruleId),
      'action': serializer.toJson<String>(action),
      'bytes': serializer.toJson<int?>(bytes),
      'countryCode': serializer.toJson<String?>(countryCode),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  ConnectionHistoryData copyWith(
          {int? id,
          String? appId,
          String? destHost,
          Value<String?> destIp = const Value.absent(),
          Value<int?> port = const Value.absent(),
          Value<String?> protocol = const Value.absent(),
          Value<String?> ruleId = const Value.absent(),
          String? action,
          Value<int?> bytes = const Value.absent(),
          Value<String?> countryCode = const Value.absent(),
          int? timestamp}) =>
      ConnectionHistoryData(
        id: id ?? this.id,
        appId: appId ?? this.appId,
        destHost: destHost ?? this.destHost,
        destIp: destIp.present ? destIp.value : this.destIp,
        port: port.present ? port.value : this.port,
        protocol: protocol.present ? protocol.value : this.protocol,
        ruleId: ruleId.present ? ruleId.value : this.ruleId,
        action: action ?? this.action,
        bytes: bytes.present ? bytes.value : this.bytes,
        countryCode: countryCode.present ? countryCode.value : this.countryCode,
        timestamp: timestamp ?? this.timestamp,
      );
  @override
  String toString() {
    return (StringBuffer('ConnectionHistoryData(')
          ..write('id: $id, ')
          ..write('appId: $appId, ')
          ..write('destHost: $destHost, ')
          ..write('destIp: $destIp, ')
          ..write('port: $port, ')
          ..write('protocol: $protocol, ')
          ..write('ruleId: $ruleId, ')
          ..write('action: $action, ')
          ..write('bytes: $bytes, ')
          ..write('countryCode: $countryCode, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, appId, destHost, destIp, port, protocol,
      ruleId, action, bytes, countryCode, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConnectionHistoryData &&
          other.id == this.id &&
          other.appId == this.appId &&
          other.destHost == this.destHost &&
          other.destIp == this.destIp &&
          other.port == this.port &&
          other.protocol == this.protocol &&
          other.ruleId == this.ruleId &&
          other.action == this.action &&
          other.bytes == this.bytes &&
          other.countryCode == this.countryCode &&
          other.timestamp == this.timestamp);
}

class ConnectionHistoryCompanion
    extends UpdateCompanion<ConnectionHistoryData> {
  final Value<int> id;
  final Value<String> appId;
  final Value<String> destHost;
  final Value<String?> destIp;
  final Value<int?> port;
  final Value<String?> protocol;
  final Value<String?> ruleId;
  final Value<String> action;
  final Value<int?> bytes;
  final Value<String?> countryCode;
  final Value<int> timestamp;
  const ConnectionHistoryCompanion({
    this.id = const Value.absent(),
    this.appId = const Value.absent(),
    this.destHost = const Value.absent(),
    this.destIp = const Value.absent(),
    this.port = const Value.absent(),
    this.protocol = const Value.absent(),
    this.ruleId = const Value.absent(),
    this.action = const Value.absent(),
    this.bytes = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  ConnectionHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String appId,
    required String destHost,
    this.destIp = const Value.absent(),
    this.port = const Value.absent(),
    this.protocol = const Value.absent(),
    this.ruleId = const Value.absent(),
    required String action,
    this.bytes = const Value.absent(),
    this.countryCode = const Value.absent(),
    required int timestamp,
  })  : appId = Value(appId),
        destHost = Value(destHost),
        action = Value(action),
        timestamp = Value(timestamp);
  static Insertable<ConnectionHistoryData> custom({
    Expression<int>? id,
    Expression<String>? appId,
    Expression<String>? destHost,
    Expression<String>? destIp,
    Expression<int>? port,
    Expression<String>? protocol,
    Expression<String>? ruleId,
    Expression<String>? action,
    Expression<int>? bytes,
    Expression<String>? countryCode,
    Expression<int>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (appId != null) 'app_id': appId,
      if (destHost != null) 'dest_host': destHost,
      if (destIp != null) 'dest_ip': destIp,
      if (port != null) 'port': port,
      if (protocol != null) 'protocol': protocol,
      if (ruleId != null) 'rule_id': ruleId,
      if (action != null) 'action': action,
      if (bytes != null) 'bytes': bytes,
      if (countryCode != null) 'country_code': countryCode,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  ConnectionHistoryCompanion copyWith(
      {Value<int>? id,
      Value<String>? appId,
      Value<String>? destHost,
      Value<String?>? destIp,
      Value<int?>? port,
      Value<String?>? protocol,
      Value<String?>? ruleId,
      Value<String>? action,
      Value<int?>? bytes,
      Value<String?>? countryCode,
      Value<int>? timestamp}) {
    return ConnectionHistoryCompanion(
      id: id ?? this.id,
      appId: appId ?? this.appId,
      destHost: destHost ?? this.destHost,
      destIp: destIp ?? this.destIp,
      port: port ?? this.port,
      protocol: protocol ?? this.protocol,
      ruleId: ruleId ?? this.ruleId,
      action: action ?? this.action,
      bytes: bytes ?? this.bytes,
      countryCode: countryCode ?? this.countryCode,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (appId.present) {
      map['app_id'] = Variable<String>(appId.value);
    }
    if (destHost.present) {
      map['dest_host'] = Variable<String>(destHost.value);
    }
    if (destIp.present) {
      map['dest_ip'] = Variable<String>(destIp.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (protocol.present) {
      map['protocol'] = Variable<String>(protocol.value);
    }
    if (ruleId.present) {
      map['rule_id'] = Variable<String>(ruleId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (countryCode.present) {
      map['country_code'] = Variable<String>(countryCode.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionHistoryCompanion(')
          ..write('id: $id, ')
          ..write('appId: $appId, ')
          ..write('destHost: $destHost, ')
          ..write('destIp: $destIp, ')
          ..write('port: $port, ')
          ..write('protocol: $protocol, ')
          ..write('ruleId: $ruleId, ')
          ..write('action: $action, ')
          ..write('bytes: $bytes, ')
          ..write('countryCode: $countryCode, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $AlertsTable extends Alerts with TableInfo<$AlertsTable, Alert> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _severityMeta =
      const VerificationMeta('severity');
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
      'severity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _appIdMeta = const VerificationMeta('appId');
  @override
  late final GeneratedColumn<String> appId = GeneratedColumn<String>(
      'app_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('unread'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, type, severity, title, body, appId, status, createdAt];
  @override
  String get aliasedName => _alias ?? 'alerts';
  @override
  String get actualTableName => 'alerts';
  @override
  VerificationContext validateIntegrity(Insertable<Alert> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(_severityMeta,
          severity.isAcceptableOrUnknown(data['severity']!, _severityMeta));
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('app_id')) {
      context.handle(
          _appIdMeta, appId.isAcceptableOrUnknown(data['app_id']!, _appIdMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Alert map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Alert(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      severity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}severity'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      appId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_id']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AlertsTable createAlias(String alias) {
    return $AlertsTable(attachedDatabase, alias);
  }
}

class Alert extends DataClass implements Insertable<Alert> {
  final String id;
  final String type;
  final String severity;
  final String title;
  final String body;
  final String? appId;
  final String status;
  final int createdAt;
  const Alert(
      {required this.id,
      required this.type,
      required this.severity,
      required this.title,
      required this.body,
      this.appId,
      required this.status,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['severity'] = Variable<String>(severity);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || appId != null) {
      map['app_id'] = Variable<String>(appId);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  AlertsCompanion toCompanion(bool nullToAbsent) {
    return AlertsCompanion(
      id: Value(id),
      type: Value(type),
      severity: Value(severity),
      title: Value(title),
      body: Value(body),
      appId:
          appId == null && nullToAbsent ? const Value.absent() : Value(appId),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory Alert.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Alert(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      severity: serializer.fromJson<String>(json['severity']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      appId: serializer.fromJson<String?>(json['appId']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'severity': serializer.toJson<String>(severity),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'appId': serializer.toJson<String?>(appId),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Alert copyWith(
          {String? id,
          String? type,
          String? severity,
          String? title,
          String? body,
          Value<String?> appId = const Value.absent(),
          String? status,
          int? createdAt}) =>
      Alert(
        id: id ?? this.id,
        type: type ?? this.type,
        severity: severity ?? this.severity,
        title: title ?? this.title,
        body: body ?? this.body,
        appId: appId.present ? appId.value : this.appId,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('Alert(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('severity: $severity, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('appId: $appId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, severity, title, body, appId, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Alert &&
          other.id == this.id &&
          other.type == this.type &&
          other.severity == this.severity &&
          other.title == this.title &&
          other.body == this.body &&
          other.appId == this.appId &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class AlertsCompanion extends UpdateCompanion<Alert> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> severity;
  final Value<String> title;
  final Value<String> body;
  final Value<String?> appId;
  final Value<String> status;
  final Value<int> createdAt;
  final Value<int> rowid;
  const AlertsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.severity = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.appId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlertsCompanion.insert({
    required String id,
    required String type,
    required String severity,
    required String title,
    required String body,
    this.appId = const Value.absent(),
    this.status = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        type = Value(type),
        severity = Value(severity),
        title = Value(title),
        body = Value(body),
        createdAt = Value(createdAt);
  static Insertable<Alert> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? severity,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? appId,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (severity != null) 'severity': severity,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (appId != null) 'app_id': appId,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlertsCompanion copyWith(
      {Value<String>? id,
      Value<String>? type,
      Value<String>? severity,
      Value<String>? title,
      Value<String>? body,
      Value<String?>? appId,
      Value<String>? status,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return AlertsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      body: body ?? this.body,
      appId: appId ?? this.appId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (appId.present) {
      map['app_id'] = Variable<String>(appId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('severity: $severity, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('appId: $appId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LiveConnectionsTable extends LiveConnections
    with TableInfo<$LiveConnectionsTable, LiveConnection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LiveConnectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _appIdMeta = const VerificationMeta('appId');
  @override
  late final GeneratedColumn<String> appId = GeneratedColumn<String>(
      'app_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _destMeta = const VerificationMeta('dest');
  @override
  late final GeneratedColumn<String> dest = GeneratedColumn<String>(
      'dest', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _protocolMeta =
      const VerificationMeta('protocol');
  @override
  late final GeneratedColumn<String> protocol = GeneratedColumn<String>(
      'protocol', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
      'started_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
      'bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, appId, dest, protocol, startedAt, bytes];
  @override
  String get aliasedName => _alias ?? 'live_connections';
  @override
  String get actualTableName => 'live_connections';
  @override
  VerificationContext validateIntegrity(Insertable<LiveConnection> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('app_id')) {
      context.handle(
          _appIdMeta, appId.isAcceptableOrUnknown(data['app_id']!, _appIdMeta));
    } else if (isInserting) {
      context.missing(_appIdMeta);
    }
    if (data.containsKey('dest')) {
      context.handle(
          _destMeta, dest.isAcceptableOrUnknown(data['dest']!, _destMeta));
    } else if (isInserting) {
      context.missing(_destMeta);
    }
    if (data.containsKey('protocol')) {
      context.handle(_protocolMeta,
          protocol.isAcceptableOrUnknown(data['protocol']!, _protocolMeta));
    } else if (isInserting) {
      context.missing(_protocolMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
          _bytesMeta, bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LiveConnection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LiveConnection(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      appId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}app_id'])!,
      dest: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dest'])!,
      protocol: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}protocol'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}started_at'])!,
      bytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bytes'])!,
    );
  }

  @override
  $LiveConnectionsTable createAlias(String alias) {
    return $LiveConnectionsTable(attachedDatabase, alias);
  }
}

class LiveConnection extends DataClass implements Insertable<LiveConnection> {
  final String id;
  final String appId;
  final String dest;
  final String protocol;
  final int startedAt;
  final int bytes;
  const LiveConnection(
      {required this.id,
      required this.appId,
      required this.dest,
      required this.protocol,
      required this.startedAt,
      required this.bytes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['app_id'] = Variable<String>(appId);
    map['dest'] = Variable<String>(dest);
    map['protocol'] = Variable<String>(protocol);
    map['started_at'] = Variable<int>(startedAt);
    map['bytes'] = Variable<int>(bytes);
    return map;
  }

  LiveConnectionsCompanion toCompanion(bool nullToAbsent) {
    return LiveConnectionsCompanion(
      id: Value(id),
      appId: Value(appId),
      dest: Value(dest),
      protocol: Value(protocol),
      startedAt: Value(startedAt),
      bytes: Value(bytes),
    );
  }

  factory LiveConnection.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LiveConnection(
      id: serializer.fromJson<String>(json['id']),
      appId: serializer.fromJson<String>(json['appId']),
      dest: serializer.fromJson<String>(json['dest']),
      protocol: serializer.fromJson<String>(json['protocol']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      bytes: serializer.fromJson<int>(json['bytes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'appId': serializer.toJson<String>(appId),
      'dest': serializer.toJson<String>(dest),
      'protocol': serializer.toJson<String>(protocol),
      'startedAt': serializer.toJson<int>(startedAt),
      'bytes': serializer.toJson<int>(bytes),
    };
  }

  LiveConnection copyWith(
          {String? id,
          String? appId,
          String? dest,
          String? protocol,
          int? startedAt,
          int? bytes}) =>
      LiveConnection(
        id: id ?? this.id,
        appId: appId ?? this.appId,
        dest: dest ?? this.dest,
        protocol: protocol ?? this.protocol,
        startedAt: startedAt ?? this.startedAt,
        bytes: bytes ?? this.bytes,
      );
  @override
  String toString() {
    return (StringBuffer('LiveConnection(')
          ..write('id: $id, ')
          ..write('appId: $appId, ')
          ..write('dest: $dest, ')
          ..write('protocol: $protocol, ')
          ..write('startedAt: $startedAt, ')
          ..write('bytes: $bytes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, appId, dest, protocol, startedAt, bytes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LiveConnection &&
          other.id == this.id &&
          other.appId == this.appId &&
          other.dest == this.dest &&
          other.protocol == this.protocol &&
          other.startedAt == this.startedAt &&
          other.bytes == this.bytes);
}

class LiveConnectionsCompanion extends UpdateCompanion<LiveConnection> {
  final Value<String> id;
  final Value<String> appId;
  final Value<String> dest;
  final Value<String> protocol;
  final Value<int> startedAt;
  final Value<int> bytes;
  final Value<int> rowid;
  const LiveConnectionsCompanion({
    this.id = const Value.absent(),
    this.appId = const Value.absent(),
    this.dest = const Value.absent(),
    this.protocol = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.bytes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LiveConnectionsCompanion.insert({
    required String id,
    required String appId,
    required String dest,
    required String protocol,
    required int startedAt,
    this.bytes = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        appId = Value(appId),
        dest = Value(dest),
        protocol = Value(protocol),
        startedAt = Value(startedAt);
  static Insertable<LiveConnection> custom({
    Expression<String>? id,
    Expression<String>? appId,
    Expression<String>? dest,
    Expression<String>? protocol,
    Expression<int>? startedAt,
    Expression<int>? bytes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (appId != null) 'app_id': appId,
      if (dest != null) 'dest': dest,
      if (protocol != null) 'protocol': protocol,
      if (startedAt != null) 'started_at': startedAt,
      if (bytes != null) 'bytes': bytes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LiveConnectionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? appId,
      Value<String>? dest,
      Value<String>? protocol,
      Value<int>? startedAt,
      Value<int>? bytes,
      Value<int>? rowid}) {
    return LiveConnectionsCompanion(
      id: id ?? this.id,
      appId: appId ?? this.appId,
      dest: dest ?? this.dest,
      protocol: protocol ?? this.protocol,
      startedAt: startedAt ?? this.startedAt,
      bytes: bytes ?? this.bytes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (appId.present) {
      map['app_id'] = Variable<String>(appId.value);
    }
    if (dest.present) {
      map['dest'] = Variable<String>(dest.value);
    }
    if (protocol.present) {
      map['protocol'] = Variable<String>(protocol.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LiveConnectionsCompanion(')
          ..write('id: $id, ')
          ..write('appId: $appId, ')
          ..write('dest: $dest, ')
          ..write('protocol: $protocol, ')
          ..write('startedAt: $startedAt, ')
          ..write('bytes: $bytes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SchemaVersionsTable extends SchemaVersions
    with TableInfo<$SchemaVersionsTable, SchemaVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchemaVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _appliedAtMeta =
      const VerificationMeta('appliedAt');
  @override
  late final GeneratedColumn<int> appliedAt = GeneratedColumn<int>(
      'applied_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [version, appliedAt, description];
  @override
  String get aliasedName => _alias ?? 'schema_versions';
  @override
  String get actualTableName => 'schema_versions';
  @override
  VerificationContext validateIntegrity(Insertable<SchemaVersion> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('applied_at')) {
      context.handle(_appliedAtMeta,
          appliedAt.isAcceptableOrUnknown(data['applied_at']!, _appliedAtMeta));
    } else if (isInserting) {
      context.missing(_appliedAtMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {version};
  @override
  SchemaVersion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchemaVersion(
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      appliedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}applied_at'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
    );
  }

  @override
  $SchemaVersionsTable createAlias(String alias) {
    return $SchemaVersionsTable(attachedDatabase, alias);
  }
}

class SchemaVersion extends DataClass implements Insertable<SchemaVersion> {
  final int version;
  final int appliedAt;
  final String? description;
  const SchemaVersion(
      {required this.version, required this.appliedAt, this.description});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['version'] = Variable<int>(version);
    map['applied_at'] = Variable<int>(appliedAt);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  SchemaVersionsCompanion toCompanion(bool nullToAbsent) {
    return SchemaVersionsCompanion(
      version: Value(version),
      appliedAt: Value(appliedAt),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory SchemaVersion.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchemaVersion(
      version: serializer.fromJson<int>(json['version']),
      appliedAt: serializer.fromJson<int>(json['appliedAt']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'version': serializer.toJson<int>(version),
      'appliedAt': serializer.toJson<int>(appliedAt),
      'description': serializer.toJson<String?>(description),
    };
  }

  SchemaVersion copyWith(
          {int? version,
          int? appliedAt,
          Value<String?> description = const Value.absent()}) =>
      SchemaVersion(
        version: version ?? this.version,
        appliedAt: appliedAt ?? this.appliedAt,
        description: description.present ? description.value : this.description,
      );
  @override
  String toString() {
    return (StringBuffer('SchemaVersion(')
          ..write('version: $version, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(version, appliedAt, description);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchemaVersion &&
          other.version == this.version &&
          other.appliedAt == this.appliedAt &&
          other.description == this.description);
}

class SchemaVersionsCompanion extends UpdateCompanion<SchemaVersion> {
  final Value<int> version;
  final Value<int> appliedAt;
  final Value<String?> description;
  const SchemaVersionsCompanion({
    this.version = const Value.absent(),
    this.appliedAt = const Value.absent(),
    this.description = const Value.absent(),
  });
  SchemaVersionsCompanion.insert({
    this.version = const Value.absent(),
    required int appliedAt,
    this.description = const Value.absent(),
  }) : appliedAt = Value(appliedAt);
  static Insertable<SchemaVersion> custom({
    Expression<int>? version,
    Expression<int>? appliedAt,
    Expression<String>? description,
  }) {
    return RawValuesInsertable({
      if (version != null) 'version': version,
      if (appliedAt != null) 'applied_at': appliedAt,
      if (description != null) 'description': description,
    });
  }

  SchemaVersionsCompanion copyWith(
      {Value<int>? version,
      Value<int>? appliedAt,
      Value<String?>? description}) {
    return SchemaVersionsCompanion(
      version: version ?? this.version,
      appliedAt: appliedAt ?? this.appliedAt,
      description: description ?? this.description,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (appliedAt.present) {
      map['applied_at'] = Variable<int>(appliedAt.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchemaVersionsCompanion(')
          ..write('version: $version, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $FirewallRulesTable firewallRules = $FirewallRulesTable(this);
  late final $TemporaryRulesTable temporaryRules = $TemporaryRulesTable(this);
  late final $SessionRulesTable sessionRules = $SessionRulesTable(this);
  late final $TrustedNetworksTable trustedNetworks =
      $TrustedNetworksTable(this);
  late final $DnsProfilesTable dnsProfiles = $DnsProfilesTable(this);
  late final $DnsBlocklistsTable dnsBlocklists = $DnsBlocklistsTable(this);
  late final $DnsLogsTable dnsLogs = $DnsLogsTable(this);
  late final $ApplicationsTable applications = $ApplicationsTable(this);
  late final $ApplicationStatsTable applicationStats =
      $ApplicationStatsTable(this);
  late final $ConnectionHistoryTable connectionHistory =
      $ConnectionHistoryTable(this);
  late final $AlertsTable alerts = $AlertsTable(this);
  late final $LiveConnectionsTable liveConnections =
      $LiveConnectionsTable(this);
  late final $SchemaVersionsTable schemaVersions = $SchemaVersionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        settings,
        profiles,
        firewallRules,
        temporaryRules,
        sessionRules,
        trustedNetworks,
        dnsProfiles,
        dnsBlocklists,
        dnsLogs,
        applications,
        applicationStats,
        connectionHistory,
        alerts,
        liveConnections,
        schemaVersions
      ];
}
