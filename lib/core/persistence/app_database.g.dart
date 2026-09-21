// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PendingOperationsTable extends PendingOperations
    with TableInfo<$PendingOperationsTable, PendingOperationEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountKoboMeta = const VerificationMeta(
    'amountKobo',
  );
  @override
  late final GeneratedColumn<BigInt> amountKobo = GeneratedColumn<BigInt>(
    'amount_kobo',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
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
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<BigInt> lastAttemptAt = GeneratedColumn<BigInt>(
    'last_attempt_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorJsonMeta = const VerificationMeta(
    'lastErrorJson',
  );
  @override
  late final GeneratedColumn<String> lastErrorJson = GeneratedColumn<String>(
    'last_error_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteReferenceMeta = const VerificationMeta(
    'remoteReference',
  );
  @override
  late final GeneratedColumn<String> remoteReference = GeneratedColumn<String>(
    'remote_reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<BigInt> completedAt = GeneratedColumn<BigInt>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    idempotencyKey,
    operationType,
    payloadJson,
    amountKobo,
    status,
    attemptCount,
    createdAt,
    lastAttemptAt,
    lastErrorJson,
    remoteReference,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingOperationEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('amount_kobo')) {
      context.handle(
        _amountKoboMeta,
        amountKobo.isAcceptableOrUnknown(data['amount_kobo']!, _amountKoboMeta),
      );
    } else if (isInserting) {
      context.missing(_amountKoboMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error_json')) {
      context.handle(
        _lastErrorJsonMeta,
        lastErrorJson.isAcceptableOrUnknown(
          data['last_error_json']!,
          _lastErrorJsonMeta,
        ),
      );
    }
    if (data.containsKey('remote_reference')) {
      context.handle(
        _remoteReferenceMeta,
        remoteReference.isAcceptableOrUnknown(
          data['remote_reference']!,
          _remoteReferenceMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingOperationEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOperationEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      amountKobo: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}amount_kobo'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}last_attempt_at'],
      ),
      lastErrorJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_json'],
      ),
      remoteReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_reference'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $PendingOperationsTable createAlias(String alias) {
    return $PendingOperationsTable(attachedDatabase, alias);
  }
}

class PendingOperationEntry extends DataClass
    implements Insertable<PendingOperationEntry> {
  /// Unique local durable identifier (e.g. UUIDv4 string).
  final String id;

  /// Stable remote idempotency key reused across retries.
  final String idempotencyKey;

  /// Operation type discriminator: 'send' or 'contribution'.
  final String operationType;

  /// Complete JSON serialization of the user's intent payload.
  final String payloadJson;

  /// Monetary amount in integer kobo.
  final BigInt amountKobo;

  /// Current lifecycle state: 'pending', 'processing', 'completed', 'failed'.
  final String status;

  /// Number of sync attempts performed.
  final int attemptCount;

  /// Timestamp when the operation was originally queued (UTC epoch milliseconds).
  final BigInt createdAt;

  /// Timestamp of the most recent sync attempt (UTC epoch milliseconds), nullable.
  final BigInt? lastAttemptAt;

  /// Serialized [SyncError] JSON metadata, nullable.
  final String? lastErrorJson;

  /// Settlement reference returned by remote backend on completion, nullable.
  final String? remoteReference;

  /// Timestamp when the operation settled successfully (UTC epoch milliseconds), nullable.
  final BigInt? completedAt;
  const PendingOperationEntry({
    required this.id,
    required this.idempotencyKey,
    required this.operationType,
    required this.payloadJson,
    required this.amountKobo,
    required this.status,
    required this.attemptCount,
    required this.createdAt,
    this.lastAttemptAt,
    this.lastErrorJson,
    this.remoteReference,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['operation_type'] = Variable<String>(operationType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['amount_kobo'] = Variable<BigInt>(amountKobo);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    map['created_at'] = Variable<BigInt>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<BigInt>(lastAttemptAt);
    }
    if (!nullToAbsent || lastErrorJson != null) {
      map['last_error_json'] = Variable<String>(lastErrorJson);
    }
    if (!nullToAbsent || remoteReference != null) {
      map['remote_reference'] = Variable<String>(remoteReference);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<BigInt>(completedAt);
    }
    return map;
  }

  PendingOperationsCompanion toCompanion(bool nullToAbsent) {
    return PendingOperationsCompanion(
      id: Value(id),
      idempotencyKey: Value(idempotencyKey),
      operationType: Value(operationType),
      payloadJson: Value(payloadJson),
      amountKobo: Value(amountKobo),
      status: Value(status),
      attemptCount: Value(attemptCount),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      lastErrorJson: lastErrorJson == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorJson),
      remoteReference: remoteReference == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteReference),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory PendingOperationEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOperationEntry(
      id: serializer.fromJson<String>(json['id']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      operationType: serializer.fromJson<String>(json['operationType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      amountKobo: serializer.fromJson<BigInt>(json['amountKobo']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<BigInt?>(json['lastAttemptAt']),
      lastErrorJson: serializer.fromJson<String?>(json['lastErrorJson']),
      remoteReference: serializer.fromJson<String?>(json['remoteReference']),
      completedAt: serializer.fromJson<BigInt?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'operationType': serializer.toJson<String>(operationType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'amountKobo': serializer.toJson<BigInt>(amountKobo),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'lastAttemptAt': serializer.toJson<BigInt?>(lastAttemptAt),
      'lastErrorJson': serializer.toJson<String?>(lastErrorJson),
      'remoteReference': serializer.toJson<String?>(remoteReference),
      'completedAt': serializer.toJson<BigInt?>(completedAt),
    };
  }

  PendingOperationEntry copyWith({
    String? id,
    String? idempotencyKey,
    String? operationType,
    String? payloadJson,
    BigInt? amountKobo,
    String? status,
    int? attemptCount,
    BigInt? createdAt,
    Value<BigInt?> lastAttemptAt = const Value.absent(),
    Value<String?> lastErrorJson = const Value.absent(),
    Value<String?> remoteReference = const Value.absent(),
    Value<BigInt?> completedAt = const Value.absent(),
  }) => PendingOperationEntry(
    id: id ?? this.id,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    operationType: operationType ?? this.operationType,
    payloadJson: payloadJson ?? this.payloadJson,
    amountKobo: amountKobo ?? this.amountKobo,
    status: status ?? this.status,
    attemptCount: attemptCount ?? this.attemptCount,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    lastErrorJson: lastErrorJson.present
        ? lastErrorJson.value
        : this.lastErrorJson,
    remoteReference: remoteReference.present
        ? remoteReference.value
        : this.remoteReference,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  PendingOperationEntry copyWithCompanion(PendingOperationsCompanion data) {
    return PendingOperationEntry(
      id: data.id.present ? data.id.value : this.id,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      amountKobo: data.amountKobo.present
          ? data.amountKobo.value
          : this.amountKobo,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      lastErrorJson: data.lastErrorJson.present
          ? data.lastErrorJson.value
          : this.lastErrorJson,
      remoteReference: data.remoteReference.present
          ? data.remoteReference.value
          : this.remoteReference,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperationEntry(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('amountKobo: $amountKobo, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastErrorJson: $lastErrorJson, ')
          ..write('remoteReference: $remoteReference, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    idempotencyKey,
    operationType,
    payloadJson,
    amountKobo,
    status,
    attemptCount,
    createdAt,
    lastAttemptAt,
    lastErrorJson,
    remoteReference,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOperationEntry &&
          other.id == this.id &&
          other.idempotencyKey == this.idempotencyKey &&
          other.operationType == this.operationType &&
          other.payloadJson == this.payloadJson &&
          other.amountKobo == this.amountKobo &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.lastErrorJson == this.lastErrorJson &&
          other.remoteReference == this.remoteReference &&
          other.completedAt == this.completedAt);
}

class PendingOperationsCompanion
    extends UpdateCompanion<PendingOperationEntry> {
  final Value<String> id;
  final Value<String> idempotencyKey;
  final Value<String> operationType;
  final Value<String> payloadJson;
  final Value<BigInt> amountKobo;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<BigInt> createdAt;
  final Value<BigInt?> lastAttemptAt;
  final Value<String?> lastErrorJson;
  final Value<String?> remoteReference;
  final Value<BigInt?> completedAt;
  final Value<int> rowid;
  const PendingOperationsCompanion({
    this.id = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.operationType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.amountKobo = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastErrorJson = const Value.absent(),
    this.remoteReference = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingOperationsCompanion.insert({
    required String id,
    required String idempotencyKey,
    required String operationType,
    required String payloadJson,
    required BigInt amountKobo,
    required String status,
    this.attemptCount = const Value.absent(),
    required BigInt createdAt,
    this.lastAttemptAt = const Value.absent(),
    this.lastErrorJson = const Value.absent(),
    this.remoteReference = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       idempotencyKey = Value(idempotencyKey),
       operationType = Value(operationType),
       payloadJson = Value(payloadJson),
       amountKobo = Value(amountKobo),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<PendingOperationEntry> custom({
    Expression<String>? id,
    Expression<String>? idempotencyKey,
    Expression<String>? operationType,
    Expression<String>? payloadJson,
    Expression<BigInt>? amountKobo,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<BigInt>? createdAt,
    Expression<BigInt>? lastAttemptAt,
    Expression<String>? lastErrorJson,
    Expression<String>? remoteReference,
    Expression<BigInt>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (operationType != null) 'operation_type': operationType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (amountKobo != null) 'amount_kobo': amountKobo,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (lastErrorJson != null) 'last_error_json': lastErrorJson,
      if (remoteReference != null) 'remote_reference': remoteReference,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingOperationsCompanion copyWith({
    Value<String>? id,
    Value<String>? idempotencyKey,
    Value<String>? operationType,
    Value<String>? payloadJson,
    Value<BigInt>? amountKobo,
    Value<String>? status,
    Value<int>? attemptCount,
    Value<BigInt>? createdAt,
    Value<BigInt?>? lastAttemptAt,
    Value<String?>? lastErrorJson,
    Value<String?>? remoteReference,
    Value<BigInt?>? completedAt,
    Value<int>? rowid,
  }) {
    return PendingOperationsCompanion(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      operationType: operationType ?? this.operationType,
      payloadJson: payloadJson ?? this.payloadJson,
      amountKobo: amountKobo ?? this.amountKobo,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastErrorJson: lastErrorJson ?? this.lastErrorJson,
      remoteReference: remoteReference ?? this.remoteReference,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (amountKobo.present) {
      map['amount_kobo'] = Variable<BigInt>(amountKobo.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<BigInt>(lastAttemptAt.value);
    }
    if (lastErrorJson.present) {
      map['last_error_json'] = Variable<String>(lastErrorJson.value);
    }
    if (remoteReference.present) {
      map['remote_reference'] = Variable<String>(remoteReference.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<BigInt>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperationsCompanion(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('amountKobo: $amountKobo, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastErrorJson: $lastErrorJson, ')
          ..write('remoteReference: $remoteReference, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WalletCacheTable extends WalletCache
    with TableInfo<$WalletCacheTable, WalletCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalletCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _balanceKoboMeta = const VerificationMeta(
    'balanceKobo',
  );
  @override
  late final GeneratedColumn<BigInt> balanceKobo = GeneratedColumn<BigInt>(
    'balance_kobo',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUpdatedAtMeta = const VerificationMeta(
    'lastUpdatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> lastUpdatedAt = GeneratedColumn<BigInt>(
    'last_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, balanceKobo, lastUpdatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wallet_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<WalletCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('balance_kobo')) {
      context.handle(
        _balanceKoboMeta,
        balanceKobo.isAcceptableOrUnknown(
          data['balance_kobo']!,
          _balanceKoboMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_balanceKoboMeta);
    }
    if (data.containsKey('last_updated_at')) {
      context.handle(
        _lastUpdatedAtMeta,
        lastUpdatedAt.isAcceptableOrUnknown(
          data['last_updated_at']!,
          _lastUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WalletCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WalletCacheEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      balanceKobo: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}balance_kobo'],
      )!,
      lastUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}last_updated_at'],
      )!,
    );
  }

  @override
  $WalletCacheTable createAlias(String alias) {
    return $WalletCacheTable(attachedDatabase, alias);
  }
}

class WalletCacheEntry extends DataClass
    implements Insertable<WalletCacheEntry> {
  /// Singleton primary key (fixed ID = 1) ensuring exactly one active balance snapshot.
  final int id;

  /// Confirmed wallet balance in integer kobo.
  final BigInt balanceKobo;

  /// Timestamp when balance was last updated/refreshed (UTC epoch milliseconds).
  final BigInt lastUpdatedAt;
  const WalletCacheEntry({
    required this.id,
    required this.balanceKobo,
    required this.lastUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['balance_kobo'] = Variable<BigInt>(balanceKobo);
    map['last_updated_at'] = Variable<BigInt>(lastUpdatedAt);
    return map;
  }

  WalletCacheCompanion toCompanion(bool nullToAbsent) {
    return WalletCacheCompanion(
      id: Value(id),
      balanceKobo: Value(balanceKobo),
      lastUpdatedAt: Value(lastUpdatedAt),
    );
  }

  factory WalletCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WalletCacheEntry(
      id: serializer.fromJson<int>(json['id']),
      balanceKobo: serializer.fromJson<BigInt>(json['balanceKobo']),
      lastUpdatedAt: serializer.fromJson<BigInt>(json['lastUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'balanceKobo': serializer.toJson<BigInt>(balanceKobo),
      'lastUpdatedAt': serializer.toJson<BigInt>(lastUpdatedAt),
    };
  }

  WalletCacheEntry copyWith({
    int? id,
    BigInt? balanceKobo,
    BigInt? lastUpdatedAt,
  }) => WalletCacheEntry(
    id: id ?? this.id,
    balanceKobo: balanceKobo ?? this.balanceKobo,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
  );
  WalletCacheEntry copyWithCompanion(WalletCacheCompanion data) {
    return WalletCacheEntry(
      id: data.id.present ? data.id.value : this.id,
      balanceKobo: data.balanceKobo.present
          ? data.balanceKobo.value
          : this.balanceKobo,
      lastUpdatedAt: data.lastUpdatedAt.present
          ? data.lastUpdatedAt.value
          : this.lastUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WalletCacheEntry(')
          ..write('id: $id, ')
          ..write('balanceKobo: $balanceKobo, ')
          ..write('lastUpdatedAt: $lastUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, balanceKobo, lastUpdatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalletCacheEntry &&
          other.id == this.id &&
          other.balanceKobo == this.balanceKobo &&
          other.lastUpdatedAt == this.lastUpdatedAt);
}

class WalletCacheCompanion extends UpdateCompanion<WalletCacheEntry> {
  final Value<int> id;
  final Value<BigInt> balanceKobo;
  final Value<BigInt> lastUpdatedAt;
  const WalletCacheCompanion({
    this.id = const Value.absent(),
    this.balanceKobo = const Value.absent(),
    this.lastUpdatedAt = const Value.absent(),
  });
  WalletCacheCompanion.insert({
    this.id = const Value.absent(),
    required BigInt balanceKobo,
    required BigInt lastUpdatedAt,
  }) : balanceKobo = Value(balanceKobo),
       lastUpdatedAt = Value(lastUpdatedAt);
  static Insertable<WalletCacheEntry> custom({
    Expression<int>? id,
    Expression<BigInt>? balanceKobo,
    Expression<BigInt>? lastUpdatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (balanceKobo != null) 'balance_kobo': balanceKobo,
      if (lastUpdatedAt != null) 'last_updated_at': lastUpdatedAt,
    });
  }

  WalletCacheCompanion copyWith({
    Value<int>? id,
    Value<BigInt>? balanceKobo,
    Value<BigInt>? lastUpdatedAt,
  }) {
    return WalletCacheCompanion(
      id: id ?? this.id,
      balanceKobo: balanceKobo ?? this.balanceKobo,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (balanceKobo.present) {
      map['balance_kobo'] = Variable<BigInt>(balanceKobo.value);
    }
    if (lastUpdatedAt.present) {
      map['last_updated_at'] = Variable<BigInt>(lastUpdatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WalletCacheCompanion(')
          ..write('id: $id, ')
          ..write('balanceKobo: $balanceKobo, ')
          ..write('lastUpdatedAt: $lastUpdatedAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTableTable extends TransactionsTable
    with TableInfo<$TransactionsTableTable, TransactionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountKoboMeta = const VerificationMeta(
    'amountKobo',
  );
  @override
  late final GeneratedColumn<BigInt> amountKobo = GeneratedColumn<BigInt>(
    'amount_kobo',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _counterpartyMeta = const VerificationMeta(
    'counterparty',
  );
  @override
  late final GeneratedColumn<String> counterparty = GeneratedColumn<String>(
    'counterparty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('completed'),
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _narrationMeta = const VerificationMeta(
    'narration',
  );
  @override
  late final GeneratedColumn<String> narration = GeneratedColumn<String>(
    'narration',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionType,
    amountKobo,
    counterparty,
    createdAt,
    status,
    reference,
    narration,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('amount_kobo')) {
      context.handle(
        _amountKoboMeta,
        amountKobo.isAcceptableOrUnknown(data['amount_kobo']!, _amountKoboMeta),
      );
    } else if (isInserting) {
      context.missing(_amountKoboMeta);
    }
    if (data.containsKey('counterparty')) {
      context.handle(
        _counterpartyMeta,
        counterparty.isAcceptableOrUnknown(
          data['counterparty']!,
          _counterpartyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_counterpartyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    }
    if (data.containsKey('narration')) {
      context.handle(
        _narrationMeta,
        narration.isAcceptableOrUnknown(data['narration']!, _narrationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      )!,
      amountKobo: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}amount_kobo'],
      )!,
      counterparty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counterparty'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      ),
      narration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}narration'],
      ),
    );
  }

  @override
  $TransactionsTableTable createAlias(String alias) {
    return $TransactionsTableTable(attachedDatabase, alias);
  }
}

class TransactionEntry extends DataClass
    implements Insertable<TransactionEntry> {
  /// Unique transaction identifier.
  final String id;

  /// Transaction type: 'debit' or 'credit'.
  final String transactionType;

  /// Monetary amount in integer kobo.
  final BigInt amountKobo;

  /// Counterparty name or label (e.g. recipient name, sender name, goal name).
  final String counterparty;

  /// Transaction creation timestamp (UTC epoch milliseconds).
  final BigInt createdAt;

  /// Transaction status: 'completed', 'pending', 'failed'.
  final String status;

  /// Remote settlement reference, nullable.
  final String? reference;

  /// Optional narration / description.
  final String? narration;
  const TransactionEntry({
    required this.id,
    required this.transactionType,
    required this.amountKobo,
    required this.counterparty,
    required this.createdAt,
    required this.status,
    this.reference,
    this.narration,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_type'] = Variable<String>(transactionType);
    map['amount_kobo'] = Variable<BigInt>(amountKobo);
    map['counterparty'] = Variable<String>(counterparty);
    map['created_at'] = Variable<BigInt>(createdAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    if (!nullToAbsent || narration != null) {
      map['narration'] = Variable<String>(narration);
    }
    return map;
  }

  TransactionsTableCompanion toCompanion(bool nullToAbsent) {
    return TransactionsTableCompanion(
      id: Value(id),
      transactionType: Value(transactionType),
      amountKobo: Value(amountKobo),
      counterparty: Value(counterparty),
      createdAt: Value(createdAt),
      status: Value(status),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      narration: narration == null && nullToAbsent
          ? const Value.absent()
          : Value(narration),
    );
  }

  factory TransactionEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionEntry(
      id: serializer.fromJson<String>(json['id']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      amountKobo: serializer.fromJson<BigInt>(json['amountKobo']),
      counterparty: serializer.fromJson<String>(json['counterparty']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
      reference: serializer.fromJson<String?>(json['reference']),
      narration: serializer.fromJson<String?>(json['narration']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionType': serializer.toJson<String>(transactionType),
      'amountKobo': serializer.toJson<BigInt>(amountKobo),
      'counterparty': serializer.toJson<String>(counterparty),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'status': serializer.toJson<String>(status),
      'reference': serializer.toJson<String?>(reference),
      'narration': serializer.toJson<String?>(narration),
    };
  }

  TransactionEntry copyWith({
    String? id,
    String? transactionType,
    BigInt? amountKobo,
    String? counterparty,
    BigInt? createdAt,
    String? status,
    Value<String?> reference = const Value.absent(),
    Value<String?> narration = const Value.absent(),
  }) => TransactionEntry(
    id: id ?? this.id,
    transactionType: transactionType ?? this.transactionType,
    amountKobo: amountKobo ?? this.amountKobo,
    counterparty: counterparty ?? this.counterparty,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    reference: reference.present ? reference.value : this.reference,
    narration: narration.present ? narration.value : this.narration,
  );
  TransactionEntry copyWithCompanion(TransactionsTableCompanion data) {
    return TransactionEntry(
      id: data.id.present ? data.id.value : this.id,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      amountKobo: data.amountKobo.present
          ? data.amountKobo.value
          : this.amountKobo,
      counterparty: data.counterparty.present
          ? data.counterparty.value
          : this.counterparty,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      reference: data.reference.present ? data.reference.value : this.reference,
      narration: data.narration.present ? data.narration.value : this.narration,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionEntry(')
          ..write('id: $id, ')
          ..write('transactionType: $transactionType, ')
          ..write('amountKobo: $amountKobo, ')
          ..write('counterparty: $counterparty, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('reference: $reference, ')
          ..write('narration: $narration')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transactionType,
    amountKobo,
    counterparty,
    createdAt,
    status,
    reference,
    narration,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionEntry &&
          other.id == this.id &&
          other.transactionType == this.transactionType &&
          other.amountKobo == this.amountKobo &&
          other.counterparty == this.counterparty &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.reference == this.reference &&
          other.narration == this.narration);
}

class TransactionsTableCompanion extends UpdateCompanion<TransactionEntry> {
  final Value<String> id;
  final Value<String> transactionType;
  final Value<BigInt> amountKobo;
  final Value<String> counterparty;
  final Value<BigInt> createdAt;
  final Value<String> status;
  final Value<String?> reference;
  final Value<String?> narration;
  final Value<int> rowid;
  const TransactionsTableCompanion({
    this.id = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.amountKobo = const Value.absent(),
    this.counterparty = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.reference = const Value.absent(),
    this.narration = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsTableCompanion.insert({
    required String id,
    required String transactionType,
    required BigInt amountKobo,
    required String counterparty,
    required BigInt createdAt,
    this.status = const Value.absent(),
    this.reference = const Value.absent(),
    this.narration = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transactionType = Value(transactionType),
       amountKobo = Value(amountKobo),
       counterparty = Value(counterparty),
       createdAt = Value(createdAt);
  static Insertable<TransactionEntry> custom({
    Expression<String>? id,
    Expression<String>? transactionType,
    Expression<BigInt>? amountKobo,
    Expression<String>? counterparty,
    Expression<BigInt>? createdAt,
    Expression<String>? status,
    Expression<String>? reference,
    Expression<String>? narration,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionType != null) 'transaction_type': transactionType,
      if (amountKobo != null) 'amount_kobo': amountKobo,
      if (counterparty != null) 'counterparty': counterparty,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (reference != null) 'reference': reference,
      if (narration != null) 'narration': narration,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? transactionType,
    Value<BigInt>? amountKobo,
    Value<String>? counterparty,
    Value<BigInt>? createdAt,
    Value<String>? status,
    Value<String?>? reference,
    Value<String?>? narration,
    Value<int>? rowid,
  }) {
    return TransactionsTableCompanion(
      id: id ?? this.id,
      transactionType: transactionType ?? this.transactionType,
      amountKobo: amountKobo ?? this.amountKobo,
      counterparty: counterparty ?? this.counterparty,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      reference: reference ?? this.reference,
      narration: narration ?? this.narration,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (amountKobo.present) {
      map['amount_kobo'] = Variable<BigInt>(amountKobo.value);
    }
    if (counterparty.present) {
      map['counterparty'] = Variable<String>(counterparty.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (narration.present) {
      map['narration'] = Variable<String>(narration.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsTableCompanion(')
          ..write('id: $id, ')
          ..write('transactionType: $transactionType, ')
          ..write('amountKobo: $amountKobo, ')
          ..write('counterparty: $counterparty, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('reference: $reference, ')
          ..write('narration: $narration, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavingsGoalsTableTable extends SavingsGoalsTable
    with TableInfo<$SavingsGoalsTableTable, SavingsGoalEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsGoalsTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _targetAmountKoboMeta = const VerificationMeta(
    'targetAmountKobo',
  );
  @override
  late final GeneratedColumn<BigInt> targetAmountKobo = GeneratedColumn<BigInt>(
    'target_amount_kobo',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedAmountKoboMeta = const VerificationMeta(
    'savedAmountKobo',
  );
  @override
  late final GeneratedColumn<BigInt> savedAmountKobo = GeneratedColumn<BigInt>(
    'saved_amount_kobo',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<BigInt> targetDate = GeneratedColumn<BigInt>(
    'target_date',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    targetAmountKobo,
    savedAmountKobo,
    targetDate,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_goals_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavingsGoalEntry> instance, {
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
    if (data.containsKey('target_amount_kobo')) {
      context.handle(
        _targetAmountKoboMeta,
        targetAmountKobo.isAcceptableOrUnknown(
          data['target_amount_kobo']!,
          _targetAmountKoboMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetAmountKoboMeta);
    }
    if (data.containsKey('saved_amount_kobo')) {
      context.handle(
        _savedAmountKoboMeta,
        savedAmountKobo.isAcceptableOrUnknown(
          data['saved_amount_kobo']!,
          _savedAmountKoboMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_savedAmountKoboMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingsGoalEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsGoalEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      targetAmountKobo: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}target_amount_kobo'],
      )!,
      savedAmountKobo: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}saved_amount_kobo'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}target_date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SavingsGoalsTableTable createAlias(String alias) {
    return $SavingsGoalsTableTable(attachedDatabase, alias);
  }
}

class SavingsGoalEntry extends DataClass
    implements Insertable<SavingsGoalEntry> {
  /// Unique goal identifier.
  final String id;

  /// Goal display name.
  final String name;

  /// Target amount in integer kobo.
  final BigInt targetAmountKobo;

  /// Current saved amount in integer kobo.
  final BigInt savedAmountKobo;

  /// Target completion date (UTC epoch milliseconds).
  final BigInt targetDate;

  /// Timestamp when goal was created (UTC epoch milliseconds).
  final BigInt createdAt;
  const SavingsGoalEntry({
    required this.id,
    required this.name,
    required this.targetAmountKobo,
    required this.savedAmountKobo,
    required this.targetDate,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['target_amount_kobo'] = Variable<BigInt>(targetAmountKobo);
    map['saved_amount_kobo'] = Variable<BigInt>(savedAmountKobo);
    map['target_date'] = Variable<BigInt>(targetDate);
    map['created_at'] = Variable<BigInt>(createdAt);
    return map;
  }

  SavingsGoalsTableCompanion toCompanion(bool nullToAbsent) {
    return SavingsGoalsTableCompanion(
      id: Value(id),
      name: Value(name),
      targetAmountKobo: Value(targetAmountKobo),
      savedAmountKobo: Value(savedAmountKobo),
      targetDate: Value(targetDate),
      createdAt: Value(createdAt),
    );
  }

  factory SavingsGoalEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsGoalEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      targetAmountKobo: serializer.fromJson<BigInt>(json['targetAmountKobo']),
      savedAmountKobo: serializer.fromJson<BigInt>(json['savedAmountKobo']),
      targetDate: serializer.fromJson<BigInt>(json['targetDate']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'targetAmountKobo': serializer.toJson<BigInt>(targetAmountKobo),
      'savedAmountKobo': serializer.toJson<BigInt>(savedAmountKobo),
      'targetDate': serializer.toJson<BigInt>(targetDate),
      'createdAt': serializer.toJson<BigInt>(createdAt),
    };
  }

  SavingsGoalEntry copyWith({
    String? id,
    String? name,
    BigInt? targetAmountKobo,
    BigInt? savedAmountKobo,
    BigInt? targetDate,
    BigInt? createdAt,
  }) => SavingsGoalEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    targetAmountKobo: targetAmountKobo ?? this.targetAmountKobo,
    savedAmountKobo: savedAmountKobo ?? this.savedAmountKobo,
    targetDate: targetDate ?? this.targetDate,
    createdAt: createdAt ?? this.createdAt,
  );
  SavingsGoalEntry copyWithCompanion(SavingsGoalsTableCompanion data) {
    return SavingsGoalEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      targetAmountKobo: data.targetAmountKobo.present
          ? data.targetAmountKobo.value
          : this.targetAmountKobo,
      savedAmountKobo: data.savedAmountKobo.present
          ? data.savedAmountKobo.value
          : this.savedAmountKobo,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoalEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetAmountKobo: $targetAmountKobo, ')
          ..write('savedAmountKobo: $savedAmountKobo, ')
          ..write('targetDate: $targetDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    targetAmountKobo,
    savedAmountKobo,
    targetDate,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsGoalEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.targetAmountKobo == this.targetAmountKobo &&
          other.savedAmountKobo == this.savedAmountKobo &&
          other.targetDate == this.targetDate &&
          other.createdAt == this.createdAt);
}

class SavingsGoalsTableCompanion extends UpdateCompanion<SavingsGoalEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<BigInt> targetAmountKobo;
  final Value<BigInt> savedAmountKobo;
  final Value<BigInt> targetDate;
  final Value<BigInt> createdAt;
  final Value<int> rowid;
  const SavingsGoalsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.targetAmountKobo = const Value.absent(),
    this.savedAmountKobo = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavingsGoalsTableCompanion.insert({
    required String id,
    required String name,
    required BigInt targetAmountKobo,
    required BigInt savedAmountKobo,
    required BigInt targetDate,
    required BigInt createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       targetAmountKobo = Value(targetAmountKobo),
       savedAmountKobo = Value(savedAmountKobo),
       targetDate = Value(targetDate),
       createdAt = Value(createdAt);
  static Insertable<SavingsGoalEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<BigInt>? targetAmountKobo,
    Expression<BigInt>? savedAmountKobo,
    Expression<BigInt>? targetDate,
    Expression<BigInt>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (targetAmountKobo != null) 'target_amount_kobo': targetAmountKobo,
      if (savedAmountKobo != null) 'saved_amount_kobo': savedAmountKobo,
      if (targetDate != null) 'target_date': targetDate,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavingsGoalsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<BigInt>? targetAmountKobo,
    Value<BigInt>? savedAmountKobo,
    Value<BigInt>? targetDate,
    Value<BigInt>? createdAt,
    Value<int>? rowid,
  }) {
    return SavingsGoalsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmountKobo: targetAmountKobo ?? this.targetAmountKobo,
      savedAmountKobo: savedAmountKobo ?? this.savedAmountKobo,
      targetDate: targetDate ?? this.targetDate,
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
    if (targetAmountKobo.present) {
      map['target_amount_kobo'] = Variable<BigInt>(targetAmountKobo.value);
    }
    if (savedAmountKobo.present) {
      map['saved_amount_kobo'] = Variable<BigInt>(savedAmountKobo.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<BigInt>(targetDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoalsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetAmountKobo: $targetAmountKobo, ')
          ..write('savedAmountKobo: $savedAmountKobo, ')
          ..write('targetDate: $targetDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemoteIdempotencyTableTable extends RemoteIdempotencyTable
    with TableInfo<$RemoteIdempotencyTableTable, RemoteIdempotencyEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemoteIdempotencyTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteReferenceMeta = const VerificationMeta(
    'remoteReference',
  );
  @override
  late final GeneratedColumn<String> remoteReference = GeneratedColumn<String>(
    'remote_reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _debitAmountKoboMeta = const VerificationMeta(
    'debitAmountKobo',
  );
  @override
  late final GeneratedColumn<BigInt> debitAmountKobo = GeneratedColumn<BigInt>(
    'debit_amount_kobo',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settledAtMeta = const VerificationMeta(
    'settledAt',
  );
  @override
  late final GeneratedColumn<BigInt> settledAt = GeneratedColumn<BigInt>(
    'settled_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<BigInt> recordedAt = GeneratedColumn<BigInt>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    idempotencyKey,
    operationId,
    operationType,
    payloadJson,
    remoteReference,
    debitAmountKobo,
    settledAt,
    recordedAt,
    metadataJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_idempotency_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<RemoteIdempotencyEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('remote_reference')) {
      context.handle(
        _remoteReferenceMeta,
        remoteReference.isAcceptableOrUnknown(
          data['remote_reference']!,
          _remoteReferenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteReferenceMeta);
    }
    if (data.containsKey('debit_amount_kobo')) {
      context.handle(
        _debitAmountKoboMeta,
        debitAmountKobo.isAcceptableOrUnknown(
          data['debit_amount_kobo']!,
          _debitAmountKoboMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_debitAmountKoboMeta);
    }
    if (data.containsKey('settled_at')) {
      context.handle(
        _settledAtMeta,
        settledAt.isAcceptableOrUnknown(data['settled_at']!, _settledAtMeta),
      );
    } else if (isInserting) {
      context.missing(_settledAtMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {idempotencyKey};
  @override
  RemoteIdempotencyEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteIdempotencyEntry(
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      remoteReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_reference'],
      )!,
      debitAmountKobo: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}debit_amount_kobo'],
      )!,
      settledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}settled_at'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}recorded_at'],
      )!,
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      ),
    );
  }

  @override
  $RemoteIdempotencyTableTable createAlias(String alias) {
    return $RemoteIdempotencyTableTable(attachedDatabase, alias);
  }
}

class RemoteIdempotencyEntry extends DataClass
    implements Insertable<RemoteIdempotencyEntry> {
  /// Stable idempotency key (primary key).
  final String idempotencyKey;

  /// Logical operation ID.
  final String operationId;

  /// Operation type: 'send' or 'contribution'.
  final String operationType;

  /// Encoded JSON representation of the payload.
  final String payloadJson;

  /// The generated remote transaction reference.
  final String remoteReference;

  /// Monetary amount debited in integer kobo.
  final BigInt debitAmountKobo;

  /// Settlement timestamp (UTC epoch milliseconds).
  final BigInt settledAt;

  /// Record creation timestamp (UTC epoch milliseconds).
  final BigInt recordedAt;

  /// Optional metadata JSON.
  final String? metadataJson;
  const RemoteIdempotencyEntry({
    required this.idempotencyKey,
    required this.operationId,
    required this.operationType,
    required this.payloadJson,
    required this.remoteReference,
    required this.debitAmountKobo,
    required this.settledAt,
    required this.recordedAt,
    this.metadataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['operation_id'] = Variable<String>(operationId);
    map['operation_type'] = Variable<String>(operationType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['remote_reference'] = Variable<String>(remoteReference);
    map['debit_amount_kobo'] = Variable<BigInt>(debitAmountKobo);
    map['settled_at'] = Variable<BigInt>(settledAt);
    map['recorded_at'] = Variable<BigInt>(recordedAt);
    if (!nullToAbsent || metadataJson != null) {
      map['metadata_json'] = Variable<String>(metadataJson);
    }
    return map;
  }

  RemoteIdempotencyTableCompanion toCompanion(bool nullToAbsent) {
    return RemoteIdempotencyTableCompanion(
      idempotencyKey: Value(idempotencyKey),
      operationId: Value(operationId),
      operationType: Value(operationType),
      payloadJson: Value(payloadJson),
      remoteReference: Value(remoteReference),
      debitAmountKobo: Value(debitAmountKobo),
      settledAt: Value(settledAt),
      recordedAt: Value(recordedAt),
      metadataJson: metadataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataJson),
    );
  }

  factory RemoteIdempotencyEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemoteIdempotencyEntry(
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      operationId: serializer.fromJson<String>(json['operationId']),
      operationType: serializer.fromJson<String>(json['operationType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      remoteReference: serializer.fromJson<String>(json['remoteReference']),
      debitAmountKobo: serializer.fromJson<BigInt>(json['debitAmountKobo']),
      settledAt: serializer.fromJson<BigInt>(json['settledAt']),
      recordedAt: serializer.fromJson<BigInt>(json['recordedAt']),
      metadataJson: serializer.fromJson<String?>(json['metadataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'operationId': serializer.toJson<String>(operationId),
      'operationType': serializer.toJson<String>(operationType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'remoteReference': serializer.toJson<String>(remoteReference),
      'debitAmountKobo': serializer.toJson<BigInt>(debitAmountKobo),
      'settledAt': serializer.toJson<BigInt>(settledAt),
      'recordedAt': serializer.toJson<BigInt>(recordedAt),
      'metadataJson': serializer.toJson<String?>(metadataJson),
    };
  }

  RemoteIdempotencyEntry copyWith({
    String? idempotencyKey,
    String? operationId,
    String? operationType,
    String? payloadJson,
    String? remoteReference,
    BigInt? debitAmountKobo,
    BigInt? settledAt,
    BigInt? recordedAt,
    Value<String?> metadataJson = const Value.absent(),
  }) => RemoteIdempotencyEntry(
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    operationId: operationId ?? this.operationId,
    operationType: operationType ?? this.operationType,
    payloadJson: payloadJson ?? this.payloadJson,
    remoteReference: remoteReference ?? this.remoteReference,
    debitAmountKobo: debitAmountKobo ?? this.debitAmountKobo,
    settledAt: settledAt ?? this.settledAt,
    recordedAt: recordedAt ?? this.recordedAt,
    metadataJson: metadataJson.present ? metadataJson.value : this.metadataJson,
  );
  RemoteIdempotencyEntry copyWithCompanion(
    RemoteIdempotencyTableCompanion data,
  ) {
    return RemoteIdempotencyEntry(
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      remoteReference: data.remoteReference.present
          ? data.remoteReference.value
          : this.remoteReference,
      debitAmountKobo: data.debitAmountKobo.present
          ? data.debitAmountKobo.value
          : this.debitAmountKobo,
      settledAt: data.settledAt.present ? data.settledAt.value : this.settledAt,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemoteIdempotencyEntry(')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('operationId: $operationId, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('remoteReference: $remoteReference, ')
          ..write('debitAmountKobo: $debitAmountKobo, ')
          ..write('settledAt: $settledAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('metadataJson: $metadataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    idempotencyKey,
    operationId,
    operationType,
    payloadJson,
    remoteReference,
    debitAmountKobo,
    settledAt,
    recordedAt,
    metadataJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteIdempotencyEntry &&
          other.idempotencyKey == this.idempotencyKey &&
          other.operationId == this.operationId &&
          other.operationType == this.operationType &&
          other.payloadJson == this.payloadJson &&
          other.remoteReference == this.remoteReference &&
          other.debitAmountKobo == this.debitAmountKobo &&
          other.settledAt == this.settledAt &&
          other.recordedAt == this.recordedAt &&
          other.metadataJson == this.metadataJson);
}

class RemoteIdempotencyTableCompanion
    extends UpdateCompanion<RemoteIdempotencyEntry> {
  final Value<String> idempotencyKey;
  final Value<String> operationId;
  final Value<String> operationType;
  final Value<String> payloadJson;
  final Value<String> remoteReference;
  final Value<BigInt> debitAmountKobo;
  final Value<BigInt> settledAt;
  final Value<BigInt> recordedAt;
  final Value<String?> metadataJson;
  final Value<int> rowid;
  const RemoteIdempotencyTableCompanion({
    this.idempotencyKey = const Value.absent(),
    this.operationId = const Value.absent(),
    this.operationType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.remoteReference = const Value.absent(),
    this.debitAmountKobo = const Value.absent(),
    this.settledAt = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemoteIdempotencyTableCompanion.insert({
    required String idempotencyKey,
    required String operationId,
    required String operationType,
    required String payloadJson,
    required String remoteReference,
    required BigInt debitAmountKobo,
    required BigInt settledAt,
    required BigInt recordedAt,
    this.metadataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : idempotencyKey = Value(idempotencyKey),
       operationId = Value(operationId),
       operationType = Value(operationType),
       payloadJson = Value(payloadJson),
       remoteReference = Value(remoteReference),
       debitAmountKobo = Value(debitAmountKobo),
       settledAt = Value(settledAt),
       recordedAt = Value(recordedAt);
  static Insertable<RemoteIdempotencyEntry> custom({
    Expression<String>? idempotencyKey,
    Expression<String>? operationId,
    Expression<String>? operationType,
    Expression<String>? payloadJson,
    Expression<String>? remoteReference,
    Expression<BigInt>? debitAmountKobo,
    Expression<BigInt>? settledAt,
    Expression<BigInt>? recordedAt,
    Expression<String>? metadataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (operationId != null) 'operation_id': operationId,
      if (operationType != null) 'operation_type': operationType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (remoteReference != null) 'remote_reference': remoteReference,
      if (debitAmountKobo != null) 'debit_amount_kobo': debitAmountKobo,
      if (settledAt != null) 'settled_at': settledAt,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemoteIdempotencyTableCompanion copyWith({
    Value<String>? idempotencyKey,
    Value<String>? operationId,
    Value<String>? operationType,
    Value<String>? payloadJson,
    Value<String>? remoteReference,
    Value<BigInt>? debitAmountKobo,
    Value<BigInt>? settledAt,
    Value<BigInt>? recordedAt,
    Value<String?>? metadataJson,
    Value<int>? rowid,
  }) {
    return RemoteIdempotencyTableCompanion(
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      operationId: operationId ?? this.operationId,
      operationType: operationType ?? this.operationType,
      payloadJson: payloadJson ?? this.payloadJson,
      remoteReference: remoteReference ?? this.remoteReference,
      debitAmountKobo: debitAmountKobo ?? this.debitAmountKobo,
      settledAt: settledAt ?? this.settledAt,
      recordedAt: recordedAt ?? this.recordedAt,
      metadataJson: metadataJson ?? this.metadataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (remoteReference.present) {
      map['remote_reference'] = Variable<String>(remoteReference.value);
    }
    if (debitAmountKobo.present) {
      map['debit_amount_kobo'] = Variable<BigInt>(debitAmountKobo.value);
    }
    if (settledAt.present) {
      map['settled_at'] = Variable<BigInt>(settledAt.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<BigInt>(recordedAt.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemoteIdempotencyTableCompanion(')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('operationId: $operationId, ')
          ..write('operationType: $operationType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('remoteReference: $remoteReference, ')
          ..write('debitAmountKobo: $debitAmountKobo, ')
          ..write('settledAt: $settledAt, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemoteWalletStateTableTable extends RemoteWalletStateTable
    with TableInfo<$RemoteWalletStateTableTable, RemoteWalletStateEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemoteWalletStateTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _balanceKoboMeta = const VerificationMeta(
    'balanceKobo',
  );
  @override
  late final GeneratedColumn<BigInt> balanceKobo = GeneratedColumn<BigInt>(
    'balance_kobo',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUpdatedAtMeta = const VerificationMeta(
    'lastUpdatedAt',
  );
  @override
  late final GeneratedColumn<BigInt> lastUpdatedAt = GeneratedColumn<BigInt>(
    'last_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, balanceKobo, lastUpdatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_wallet_state_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<RemoteWalletStateEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('balance_kobo')) {
      context.handle(
        _balanceKoboMeta,
        balanceKobo.isAcceptableOrUnknown(
          data['balance_kobo']!,
          _balanceKoboMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_balanceKoboMeta);
    }
    if (data.containsKey('last_updated_at')) {
      context.handle(
        _lastUpdatedAtMeta,
        lastUpdatedAt.isAcceptableOrUnknown(
          data['last_updated_at']!,
          _lastUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RemoteWalletStateEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteWalletStateEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      balanceKobo: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}balance_kobo'],
      )!,
      lastUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}last_updated_at'],
      )!,
    );
  }

  @override
  $RemoteWalletStateTableTable createAlias(String alias) {
    return $RemoteWalletStateTableTable(attachedDatabase, alias);
  }
}

class RemoteWalletStateEntry extends DataClass
    implements Insertable<RemoteWalletStateEntry> {
  /// Singleton primary key (fixed ID = 1).
  final int id;

  /// Remote wallet balance in integer kobo.
  final BigInt balanceKobo;

  /// Timestamp when remote balance was last updated (UTC epoch milliseconds).
  final BigInt lastUpdatedAt;
  const RemoteWalletStateEntry({
    required this.id,
    required this.balanceKobo,
    required this.lastUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['balance_kobo'] = Variable<BigInt>(balanceKobo);
    map['last_updated_at'] = Variable<BigInt>(lastUpdatedAt);
    return map;
  }

  RemoteWalletStateTableCompanion toCompanion(bool nullToAbsent) {
    return RemoteWalletStateTableCompanion(
      id: Value(id),
      balanceKobo: Value(balanceKobo),
      lastUpdatedAt: Value(lastUpdatedAt),
    );
  }

  factory RemoteWalletStateEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemoteWalletStateEntry(
      id: serializer.fromJson<int>(json['id']),
      balanceKobo: serializer.fromJson<BigInt>(json['balanceKobo']),
      lastUpdatedAt: serializer.fromJson<BigInt>(json['lastUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'balanceKobo': serializer.toJson<BigInt>(balanceKobo),
      'lastUpdatedAt': serializer.toJson<BigInt>(lastUpdatedAt),
    };
  }

  RemoteWalletStateEntry copyWith({
    int? id,
    BigInt? balanceKobo,
    BigInt? lastUpdatedAt,
  }) => RemoteWalletStateEntry(
    id: id ?? this.id,
    balanceKobo: balanceKobo ?? this.balanceKobo,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
  );
  RemoteWalletStateEntry copyWithCompanion(
    RemoteWalletStateTableCompanion data,
  ) {
    return RemoteWalletStateEntry(
      id: data.id.present ? data.id.value : this.id,
      balanceKobo: data.balanceKobo.present
          ? data.balanceKobo.value
          : this.balanceKobo,
      lastUpdatedAt: data.lastUpdatedAt.present
          ? data.lastUpdatedAt.value
          : this.lastUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemoteWalletStateEntry(')
          ..write('id: $id, ')
          ..write('balanceKobo: $balanceKobo, ')
          ..write('lastUpdatedAt: $lastUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, balanceKobo, lastUpdatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteWalletStateEntry &&
          other.id == this.id &&
          other.balanceKobo == this.balanceKobo &&
          other.lastUpdatedAt == this.lastUpdatedAt);
}

class RemoteWalletStateTableCompanion
    extends UpdateCompanion<RemoteWalletStateEntry> {
  final Value<int> id;
  final Value<BigInt> balanceKobo;
  final Value<BigInt> lastUpdatedAt;
  const RemoteWalletStateTableCompanion({
    this.id = const Value.absent(),
    this.balanceKobo = const Value.absent(),
    this.lastUpdatedAt = const Value.absent(),
  });
  RemoteWalletStateTableCompanion.insert({
    this.id = const Value.absent(),
    required BigInt balanceKobo,
    required BigInt lastUpdatedAt,
  }) : balanceKobo = Value(balanceKobo),
       lastUpdatedAt = Value(lastUpdatedAt);
  static Insertable<RemoteWalletStateEntry> custom({
    Expression<int>? id,
    Expression<BigInt>? balanceKobo,
    Expression<BigInt>? lastUpdatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (balanceKobo != null) 'balance_kobo': balanceKobo,
      if (lastUpdatedAt != null) 'last_updated_at': lastUpdatedAt,
    });
  }

  RemoteWalletStateTableCompanion copyWith({
    Value<int>? id,
    Value<BigInt>? balanceKobo,
    Value<BigInt>? lastUpdatedAt,
  }) {
    return RemoteWalletStateTableCompanion(
      id: id ?? this.id,
      balanceKobo: balanceKobo ?? this.balanceKobo,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (balanceKobo.present) {
      map['balance_kobo'] = Variable<BigInt>(balanceKobo.value);
    }
    if (lastUpdatedAt.present) {
      map['last_updated_at'] = Variable<BigInt>(lastUpdatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemoteWalletStateTableCompanion(')
          ..write('id: $id, ')
          ..write('balanceKobo: $balanceKobo, ')
          ..write('lastUpdatedAt: $lastUpdatedAt')
          ..write(')'))
        .toString();
  }
}

class $RemoteTransactionsTableTable extends RemoteTransactionsTable
    with TableInfo<$RemoteTransactionsTableTable, RemoteTransactionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemoteTransactionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountKoboMeta = const VerificationMeta(
    'amountKobo',
  );
  @override
  late final GeneratedColumn<BigInt> amountKobo = GeneratedColumn<BigInt>(
    'amount_kobo',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _counterpartyMeta = const VerificationMeta(
    'counterparty',
  );
  @override
  late final GeneratedColumn<String> counterparty = GeneratedColumn<String>(
    'counterparty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<BigInt> createdAt = GeneratedColumn<BigInt>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('completed'),
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _narrationMeta = const VerificationMeta(
    'narration',
  );
  @override
  late final GeneratedColumn<String> narration = GeneratedColumn<String>(
    'narration',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionType,
    amountKobo,
    counterparty,
    createdAt,
    status,
    reference,
    narration,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'remote_transactions_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<RemoteTransactionEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('amount_kobo')) {
      context.handle(
        _amountKoboMeta,
        amountKobo.isAcceptableOrUnknown(data['amount_kobo']!, _amountKoboMeta),
      );
    } else if (isInserting) {
      context.missing(_amountKoboMeta);
    }
    if (data.containsKey('counterparty')) {
      context.handle(
        _counterpartyMeta,
        counterparty.isAcceptableOrUnknown(
          data['counterparty']!,
          _counterpartyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_counterpartyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    }
    if (data.containsKey('narration')) {
      context.handle(
        _narrationMeta,
        narration.isAcceptableOrUnknown(data['narration']!, _narrationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RemoteTransactionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RemoteTransactionEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      )!,
      amountKobo: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}amount_kobo'],
      )!,
      counterparty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counterparty'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      ),
      narration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}narration'],
      ),
    );
  }

  @override
  $RemoteTransactionsTableTable createAlias(String alias) {
    return $RemoteTransactionsTableTable(attachedDatabase, alias);
  }
}

class RemoteTransactionEntry extends DataClass
    implements Insertable<RemoteTransactionEntry> {
  /// Transaction ID / reference.
  final String id;

  /// Transaction type: 'debit' or 'credit'.
  final String transactionType;

  /// Monetary amount in integer kobo.
  final BigInt amountKobo;

  /// Counterparty name or label.
  final String counterparty;

  /// Transaction timestamp (UTC epoch milliseconds).
  final BigInt createdAt;

  /// Transaction status ('completed', etc.).
  final String status;

  /// Remote settlement reference.
  final String? reference;

  /// Optional narration.
  final String? narration;
  const RemoteTransactionEntry({
    required this.id,
    required this.transactionType,
    required this.amountKobo,
    required this.counterparty,
    required this.createdAt,
    required this.status,
    this.reference,
    this.narration,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_type'] = Variable<String>(transactionType);
    map['amount_kobo'] = Variable<BigInt>(amountKobo);
    map['counterparty'] = Variable<String>(counterparty);
    map['created_at'] = Variable<BigInt>(createdAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    if (!nullToAbsent || narration != null) {
      map['narration'] = Variable<String>(narration);
    }
    return map;
  }

  RemoteTransactionsTableCompanion toCompanion(bool nullToAbsent) {
    return RemoteTransactionsTableCompanion(
      id: Value(id),
      transactionType: Value(transactionType),
      amountKobo: Value(amountKobo),
      counterparty: Value(counterparty),
      createdAt: Value(createdAt),
      status: Value(status),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      narration: narration == null && nullToAbsent
          ? const Value.absent()
          : Value(narration),
    );
  }

  factory RemoteTransactionEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RemoteTransactionEntry(
      id: serializer.fromJson<String>(json['id']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      amountKobo: serializer.fromJson<BigInt>(json['amountKobo']),
      counterparty: serializer.fromJson<String>(json['counterparty']),
      createdAt: serializer.fromJson<BigInt>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
      reference: serializer.fromJson<String?>(json['reference']),
      narration: serializer.fromJson<String?>(json['narration']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionType': serializer.toJson<String>(transactionType),
      'amountKobo': serializer.toJson<BigInt>(amountKobo),
      'counterparty': serializer.toJson<String>(counterparty),
      'createdAt': serializer.toJson<BigInt>(createdAt),
      'status': serializer.toJson<String>(status),
      'reference': serializer.toJson<String?>(reference),
      'narration': serializer.toJson<String?>(narration),
    };
  }

  RemoteTransactionEntry copyWith({
    String? id,
    String? transactionType,
    BigInt? amountKobo,
    String? counterparty,
    BigInt? createdAt,
    String? status,
    Value<String?> reference = const Value.absent(),
    Value<String?> narration = const Value.absent(),
  }) => RemoteTransactionEntry(
    id: id ?? this.id,
    transactionType: transactionType ?? this.transactionType,
    amountKobo: amountKobo ?? this.amountKobo,
    counterparty: counterparty ?? this.counterparty,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    reference: reference.present ? reference.value : this.reference,
    narration: narration.present ? narration.value : this.narration,
  );
  RemoteTransactionEntry copyWithCompanion(
    RemoteTransactionsTableCompanion data,
  ) {
    return RemoteTransactionEntry(
      id: data.id.present ? data.id.value : this.id,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      amountKobo: data.amountKobo.present
          ? data.amountKobo.value
          : this.amountKobo,
      counterparty: data.counterparty.present
          ? data.counterparty.value
          : this.counterparty,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      reference: data.reference.present ? data.reference.value : this.reference,
      narration: data.narration.present ? data.narration.value : this.narration,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RemoteTransactionEntry(')
          ..write('id: $id, ')
          ..write('transactionType: $transactionType, ')
          ..write('amountKobo: $amountKobo, ')
          ..write('counterparty: $counterparty, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('reference: $reference, ')
          ..write('narration: $narration')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transactionType,
    amountKobo,
    counterparty,
    createdAt,
    status,
    reference,
    narration,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteTransactionEntry &&
          other.id == this.id &&
          other.transactionType == this.transactionType &&
          other.amountKobo == this.amountKobo &&
          other.counterparty == this.counterparty &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.reference == this.reference &&
          other.narration == this.narration);
}

class RemoteTransactionsTableCompanion
    extends UpdateCompanion<RemoteTransactionEntry> {
  final Value<String> id;
  final Value<String> transactionType;
  final Value<BigInt> amountKobo;
  final Value<String> counterparty;
  final Value<BigInt> createdAt;
  final Value<String> status;
  final Value<String?> reference;
  final Value<String?> narration;
  final Value<int> rowid;
  const RemoteTransactionsTableCompanion({
    this.id = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.amountKobo = const Value.absent(),
    this.counterparty = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.reference = const Value.absent(),
    this.narration = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemoteTransactionsTableCompanion.insert({
    required String id,
    required String transactionType,
    required BigInt amountKobo,
    required String counterparty,
    required BigInt createdAt,
    this.status = const Value.absent(),
    this.reference = const Value.absent(),
    this.narration = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transactionType = Value(transactionType),
       amountKobo = Value(amountKobo),
       counterparty = Value(counterparty),
       createdAt = Value(createdAt);
  static Insertable<RemoteTransactionEntry> custom({
    Expression<String>? id,
    Expression<String>? transactionType,
    Expression<BigInt>? amountKobo,
    Expression<String>? counterparty,
    Expression<BigInt>? createdAt,
    Expression<String>? status,
    Expression<String>? reference,
    Expression<String>? narration,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionType != null) 'transaction_type': transactionType,
      if (amountKobo != null) 'amount_kobo': amountKobo,
      if (counterparty != null) 'counterparty': counterparty,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (reference != null) 'reference': reference,
      if (narration != null) 'narration': narration,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemoteTransactionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? transactionType,
    Value<BigInt>? amountKobo,
    Value<String>? counterparty,
    Value<BigInt>? createdAt,
    Value<String>? status,
    Value<String?>? reference,
    Value<String?>? narration,
    Value<int>? rowid,
  }) {
    return RemoteTransactionsTableCompanion(
      id: id ?? this.id,
      transactionType: transactionType ?? this.transactionType,
      amountKobo: amountKobo ?? this.amountKobo,
      counterparty: counterparty ?? this.counterparty,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      reference: reference ?? this.reference,
      narration: narration ?? this.narration,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (amountKobo.present) {
      map['amount_kobo'] = Variable<BigInt>(amountKobo.value);
    }
    if (counterparty.present) {
      map['counterparty'] = Variable<String>(counterparty.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<BigInt>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (narration.present) {
      map['narration'] = Variable<String>(narration.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemoteTransactionsTableCompanion(')
          ..write('id: $id, ')
          ..write('transactionType: $transactionType, ')
          ..write('amountKobo: $amountKobo, ')
          ..write('counterparty: $counterparty, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('reference: $reference, ')
          ..write('narration: $narration, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PendingOperationsTable pendingOperations =
      $PendingOperationsTable(this);
  late final $WalletCacheTable walletCache = $WalletCacheTable(this);
  late final $TransactionsTableTable transactionsTable =
      $TransactionsTableTable(this);
  late final $SavingsGoalsTableTable savingsGoalsTable =
      $SavingsGoalsTableTable(this);
  late final $RemoteIdempotencyTableTable remoteIdempotencyTable =
      $RemoteIdempotencyTableTable(this);
  late final $RemoteWalletStateTableTable remoteWalletStateTable =
      $RemoteWalletStateTableTable(this);
  late final $RemoteTransactionsTableTable remoteTransactionsTable =
      $RemoteTransactionsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    pendingOperations,
    walletCache,
    transactionsTable,
    savingsGoalsTable,
    remoteIdempotencyTable,
    remoteWalletStateTable,
    remoteTransactionsTable,
  ];
}

typedef $$PendingOperationsTableCreateCompanionBuilder =
    PendingOperationsCompanion Function({
      required String id,
      required String idempotencyKey,
      required String operationType,
      required String payloadJson,
      required BigInt amountKobo,
      required String status,
      Value<int> attemptCount,
      required BigInt createdAt,
      Value<BigInt?> lastAttemptAt,
      Value<String?> lastErrorJson,
      Value<String?> remoteReference,
      Value<BigInt?> completedAt,
      Value<int> rowid,
    });
typedef $$PendingOperationsTableUpdateCompanionBuilder =
    PendingOperationsCompanion Function({
      Value<String> id,
      Value<String> idempotencyKey,
      Value<String> operationType,
      Value<String> payloadJson,
      Value<BigInt> amountKobo,
      Value<String> status,
      Value<int> attemptCount,
      Value<BigInt> createdAt,
      Value<BigInt?> lastAttemptAt,
      Value<String?> lastErrorJson,
      Value<String?> remoteReference,
      Value<BigInt?> completedAt,
      Value<int> rowid,
    });

class $$PendingOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableFilterComposer({
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

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get amountKobo => $composableBuilder(
    column: $table.amountKobo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorJson => $composableBuilder(
    column: $table.lastErrorJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteReference => $composableBuilder(
    column: $table.remoteReference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableOrderingComposer({
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

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get amountKobo => $composableBuilder(
    column: $table.amountKobo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorJson => $composableBuilder(
    column: $table.lastErrorJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteReference => $composableBuilder(
    column: $table.remoteReference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get amountKobo => $composableBuilder(
    column: $table.amountKobo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<BigInt> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorJson => $composableBuilder(
    column: $table.lastErrorJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteReference => $composableBuilder(
    column: $table.remoteReference,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$PendingOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingOperationsTable,
          PendingOperationEntry,
          $$PendingOperationsTableFilterComposer,
          $$PendingOperationsTableOrderingComposer,
          $$PendingOperationsTableAnnotationComposer,
          $$PendingOperationsTableCreateCompanionBuilder,
          $$PendingOperationsTableUpdateCompanionBuilder,
          (
            PendingOperationEntry,
            BaseReferences<
              _$AppDatabase,
              $PendingOperationsTable,
              PendingOperationEntry
            >,
          ),
          PendingOperationEntry,
          PrefetchHooks Function()
        > {
  $$PendingOperationsTableTableManager(
    _$AppDatabase db,
    $PendingOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingOperationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<BigInt> amountKobo = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<BigInt?> lastAttemptAt = const Value.absent(),
                Value<String?> lastErrorJson = const Value.absent(),
                Value<String?> remoteReference = const Value.absent(),
                Value<BigInt?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingOperationsCompanion(
                id: id,
                idempotencyKey: idempotencyKey,
                operationType: operationType,
                payloadJson: payloadJson,
                amountKobo: amountKobo,
                status: status,
                attemptCount: attemptCount,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                lastErrorJson: lastErrorJson,
                remoteReference: remoteReference,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String idempotencyKey,
                required String operationType,
                required String payloadJson,
                required BigInt amountKobo,
                required String status,
                Value<int> attemptCount = const Value.absent(),
                required BigInt createdAt,
                Value<BigInt?> lastAttemptAt = const Value.absent(),
                Value<String?> lastErrorJson = const Value.absent(),
                Value<String?> remoteReference = const Value.absent(),
                Value<BigInt?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingOperationsCompanion.insert(
                id: id,
                idempotencyKey: idempotencyKey,
                operationType: operationType,
                payloadJson: payloadJson,
                amountKobo: amountKobo,
                status: status,
                attemptCount: attemptCount,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                lastErrorJson: lastErrorJson,
                remoteReference: remoteReference,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingOperationsTable, PendingOperationEntry>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PendingOperationsTable,
                    PendingOperationEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingOperationsTable,
      PendingOperationEntry,
      $$PendingOperationsTableFilterComposer,
      $$PendingOperationsTableOrderingComposer,
      $$PendingOperationsTableAnnotationComposer,
      $$PendingOperationsTableCreateCompanionBuilder,
      $$PendingOperationsTableUpdateCompanionBuilder,
      (
        PendingOperationEntry,
        BaseReferences<
          _$AppDatabase,
          $PendingOperationsTable,
          PendingOperationEntry
        >,
      ),
      PendingOperationEntry,
      PrefetchHooks Function()
    >;
typedef $$WalletCacheTableCreateCompanionBuilder =
    WalletCacheCompanion Function({
      Value<int> id,
      required BigInt balanceKobo,
      required BigInt lastUpdatedAt,
    });
typedef $$WalletCacheTableUpdateCompanionBuilder =
    WalletCacheCompanion Function({
      Value<int> id,
      Value<BigInt> balanceKobo,
      Value<BigInt> lastUpdatedAt,
    });

class $$WalletCacheTableFilterComposer
    extends Composer<_$AppDatabase, $WalletCacheTable> {
  $$WalletCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get balanceKobo => $composableBuilder(
    column: $table.balanceKobo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WalletCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $WalletCacheTable> {
  $$WalletCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get balanceKobo => $composableBuilder(
    column: $table.balanceKobo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WalletCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $WalletCacheTable> {
  $$WalletCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<BigInt> get balanceKobo => $composableBuilder(
    column: $table.balanceKobo,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => column,
  );
}

class $$WalletCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WalletCacheTable,
          WalletCacheEntry,
          $$WalletCacheTableFilterComposer,
          $$WalletCacheTableOrderingComposer,
          $$WalletCacheTableAnnotationComposer,
          $$WalletCacheTableCreateCompanionBuilder,
          $$WalletCacheTableUpdateCompanionBuilder,
          (
            WalletCacheEntry,
            BaseReferences<_$AppDatabase, $WalletCacheTable, WalletCacheEntry>,
          ),
          WalletCacheEntry,
          PrefetchHooks Function()
        > {
  $$WalletCacheTableTableManager(_$AppDatabase db, $WalletCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalletCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalletCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalletCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<BigInt> balanceKobo = const Value.absent(),
                Value<BigInt> lastUpdatedAt = const Value.absent(),
              }) => WalletCacheCompanion(
                id: id,
                balanceKobo: balanceKobo,
                lastUpdatedAt: lastUpdatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required BigInt balanceKobo,
                required BigInt lastUpdatedAt,
              }) => WalletCacheCompanion.insert(
                id: id,
                balanceKobo: balanceKobo,
                lastUpdatedAt: lastUpdatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WalletCacheTable, WalletCacheEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $WalletCacheTable,
                    WalletCacheEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WalletCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WalletCacheTable,
      WalletCacheEntry,
      $$WalletCacheTableFilterComposer,
      $$WalletCacheTableOrderingComposer,
      $$WalletCacheTableAnnotationComposer,
      $$WalletCacheTableCreateCompanionBuilder,
      $$WalletCacheTableUpdateCompanionBuilder,
      (
        WalletCacheEntry,
        BaseReferences<_$AppDatabase, $WalletCacheTable, WalletCacheEntry>,
      ),
      WalletCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableTableCreateCompanionBuilder =
    TransactionsTableCompanion Function({
      required String id,
      required String transactionType,
      required BigInt amountKobo,
      required String counterparty,
      required BigInt createdAt,
      Value<String> status,
      Value<String?> reference,
      Value<String?> narration,
      Value<int> rowid,
    });
typedef $$TransactionsTableTableUpdateCompanionBuilder =
    TransactionsTableCompanion Function({
      Value<String> id,
      Value<String> transactionType,
      Value<BigInt> amountKobo,
      Value<String> counterparty,
      Value<BigInt> createdAt,
      Value<String> status,
      Value<String?> reference,
      Value<String?> narration,
      Value<int> rowid,
    });

class $$TransactionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableFilterComposer({
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

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get amountKobo => $composableBuilder(
    column: $table.amountKobo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get narration => $composableBuilder(
    column: $table.narration,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableOrderingComposer({
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

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get amountKobo => $composableBuilder(
    column: $table.amountKobo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get narration => $composableBuilder(
    column: $table.narration,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTableTable> {
  $$TransactionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get amountKobo => $composableBuilder(
    column: $table.amountKobo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get narration =>
      $composableBuilder(column: $table.narration, builder: (column) => column);
}

class $$TransactionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTableTable,
          TransactionEntry,
          $$TransactionsTableTableFilterComposer,
          $$TransactionsTableTableOrderingComposer,
          $$TransactionsTableTableAnnotationComposer,
          $$TransactionsTableTableCreateCompanionBuilder,
          $$TransactionsTableTableUpdateCompanionBuilder,
          (
            TransactionEntry,
            BaseReferences<
              _$AppDatabase,
              $TransactionsTableTable,
              TransactionEntry
            >,
          ),
          TransactionEntry,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableTableManager(
    _$AppDatabase db,
    $TransactionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
                Value<BigInt> amountKobo = const Value.absent(),
                Value<String> counterparty = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String?> narration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsTableCompanion(
                id: id,
                transactionType: transactionType,
                amountKobo: amountKobo,
                counterparty: counterparty,
                createdAt: createdAt,
                status: status,
                reference: reference,
                narration: narration,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transactionType,
                required BigInt amountKobo,
                required String counterparty,
                required BigInt createdAt,
                Value<String> status = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String?> narration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsTableCompanion.insert(
                id: id,
                transactionType: transactionType,
                amountKobo: amountKobo,
                counterparty: counterparty,
                createdAt: createdAt,
                status: status,
                reference: reference,
                narration: narration,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTableTable, TransactionEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TransactionsTableTable,
                    TransactionEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTableTable,
      TransactionEntry,
      $$TransactionsTableTableFilterComposer,
      $$TransactionsTableTableOrderingComposer,
      $$TransactionsTableTableAnnotationComposer,
      $$TransactionsTableTableCreateCompanionBuilder,
      $$TransactionsTableTableUpdateCompanionBuilder,
      (
        TransactionEntry,
        BaseReferences<
          _$AppDatabase,
          $TransactionsTableTable,
          TransactionEntry
        >,
      ),
      TransactionEntry,
      PrefetchHooks Function()
    >;
typedef $$SavingsGoalsTableTableCreateCompanionBuilder =
    SavingsGoalsTableCompanion Function({
      required String id,
      required String name,
      required BigInt targetAmountKobo,
      required BigInt savedAmountKobo,
      required BigInt targetDate,
      required BigInt createdAt,
      Value<int> rowid,
    });
typedef $$SavingsGoalsTableTableUpdateCompanionBuilder =
    SavingsGoalsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<BigInt> targetAmountKobo,
      Value<BigInt> savedAmountKobo,
      Value<BigInt> targetDate,
      Value<BigInt> createdAt,
      Value<int> rowid,
    });

class $$SavingsGoalsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTableTable> {
  $$SavingsGoalsTableTableFilterComposer({
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

  ColumnFilters<BigInt> get targetAmountKobo => $composableBuilder(
    column: $table.targetAmountKobo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get savedAmountKobo => $composableBuilder(
    column: $table.savedAmountKobo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavingsGoalsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTableTable> {
  $$SavingsGoalsTableTableOrderingComposer({
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

  ColumnOrderings<BigInt> get targetAmountKobo => $composableBuilder(
    column: $table.targetAmountKobo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get savedAmountKobo => $composableBuilder(
    column: $table.savedAmountKobo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavingsGoalsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTableTable> {
  $$SavingsGoalsTableTableAnnotationComposer({
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

  GeneratedColumn<BigInt> get targetAmountKobo => $composableBuilder(
    column: $table.targetAmountKobo,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get savedAmountKobo => $composableBuilder(
    column: $table.savedAmountKobo,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SavingsGoalsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavingsGoalsTableTable,
          SavingsGoalEntry,
          $$SavingsGoalsTableTableFilterComposer,
          $$SavingsGoalsTableTableOrderingComposer,
          $$SavingsGoalsTableTableAnnotationComposer,
          $$SavingsGoalsTableTableCreateCompanionBuilder,
          $$SavingsGoalsTableTableUpdateCompanionBuilder,
          (
            SavingsGoalEntry,
            BaseReferences<
              _$AppDatabase,
              $SavingsGoalsTableTable,
              SavingsGoalEntry
            >,
          ),
          SavingsGoalEntry,
          PrefetchHooks Function()
        > {
  $$SavingsGoalsTableTableTableManager(
    _$AppDatabase db,
    $SavingsGoalsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsGoalsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsGoalsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsGoalsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<BigInt> targetAmountKobo = const Value.absent(),
                Value<BigInt> savedAmountKobo = const Value.absent(),
                Value<BigInt> targetDate = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavingsGoalsTableCompanion(
                id: id,
                name: name,
                targetAmountKobo: targetAmountKobo,
                savedAmountKobo: savedAmountKobo,
                targetDate: targetDate,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required BigInt targetAmountKobo,
                required BigInt savedAmountKobo,
                required BigInt targetDate,
                required BigInt createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SavingsGoalsTableCompanion.insert(
                id: id,
                name: name,
                targetAmountKobo: targetAmountKobo,
                savedAmountKobo: savedAmountKobo,
                targetDate: targetDate,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavingsGoalsTableTable, SavingsGoalEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SavingsGoalsTableTable,
                    SavingsGoalEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavingsGoalsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavingsGoalsTableTable,
      SavingsGoalEntry,
      $$SavingsGoalsTableTableFilterComposer,
      $$SavingsGoalsTableTableOrderingComposer,
      $$SavingsGoalsTableTableAnnotationComposer,
      $$SavingsGoalsTableTableCreateCompanionBuilder,
      $$SavingsGoalsTableTableUpdateCompanionBuilder,
      (
        SavingsGoalEntry,
        BaseReferences<
          _$AppDatabase,
          $SavingsGoalsTableTable,
          SavingsGoalEntry
        >,
      ),
      SavingsGoalEntry,
      PrefetchHooks Function()
    >;
typedef $$RemoteIdempotencyTableTableCreateCompanionBuilder =
    RemoteIdempotencyTableCompanion Function({
      required String idempotencyKey,
      required String operationId,
      required String operationType,
      required String payloadJson,
      required String remoteReference,
      required BigInt debitAmountKobo,
      required BigInt settledAt,
      required BigInt recordedAt,
      Value<String?> metadataJson,
      Value<int> rowid,
    });
typedef $$RemoteIdempotencyTableTableUpdateCompanionBuilder =
    RemoteIdempotencyTableCompanion Function({
      Value<String> idempotencyKey,
      Value<String> operationId,
      Value<String> operationType,
      Value<String> payloadJson,
      Value<String> remoteReference,
      Value<BigInt> debitAmountKobo,
      Value<BigInt> settledAt,
      Value<BigInt> recordedAt,
      Value<String?> metadataJson,
      Value<int> rowid,
    });

class $$RemoteIdempotencyTableTableFilterComposer
    extends Composer<_$AppDatabase, $RemoteIdempotencyTableTable> {
  $$RemoteIdempotencyTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteReference => $composableBuilder(
    column: $table.remoteReference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get debitAmountKobo => $composableBuilder(
    column: $table.debitAmountKobo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get settledAt => $composableBuilder(
    column: $table.settledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemoteIdempotencyTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RemoteIdempotencyTableTable> {
  $$RemoteIdempotencyTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteReference => $composableBuilder(
    column: $table.remoteReference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get debitAmountKobo => $composableBuilder(
    column: $table.debitAmountKobo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get settledAt => $composableBuilder(
    column: $table.settledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemoteIdempotencyTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemoteIdempotencyTableTable> {
  $$RemoteIdempotencyTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteReference => $composableBuilder(
    column: $table.remoteReference,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get debitAmountKobo => $composableBuilder(
    column: $table.debitAmountKobo,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get settledAt =>
      $composableBuilder(column: $table.settledAt, builder: (column) => column);

  GeneratedColumn<BigInt> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );
}

class $$RemoteIdempotencyTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemoteIdempotencyTableTable,
          RemoteIdempotencyEntry,
          $$RemoteIdempotencyTableTableFilterComposer,
          $$RemoteIdempotencyTableTableOrderingComposer,
          $$RemoteIdempotencyTableTableAnnotationComposer,
          $$RemoteIdempotencyTableTableCreateCompanionBuilder,
          $$RemoteIdempotencyTableTableUpdateCompanionBuilder,
          (
            RemoteIdempotencyEntry,
            BaseReferences<
              _$AppDatabase,
              $RemoteIdempotencyTableTable,
              RemoteIdempotencyEntry
            >,
          ),
          RemoteIdempotencyEntry,
          PrefetchHooks Function()
        > {
  $$RemoteIdempotencyTableTableTableManager(
    _$AppDatabase db,
    $RemoteIdempotencyTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemoteIdempotencyTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RemoteIdempotencyTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RemoteIdempotencyTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> operationId = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> remoteReference = const Value.absent(),
                Value<BigInt> debitAmountKobo = const Value.absent(),
                Value<BigInt> settledAt = const Value.absent(),
                Value<BigInt> recordedAt = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemoteIdempotencyTableCompanion(
                idempotencyKey: idempotencyKey,
                operationId: operationId,
                operationType: operationType,
                payloadJson: payloadJson,
                remoteReference: remoteReference,
                debitAmountKobo: debitAmountKobo,
                settledAt: settledAt,
                recordedAt: recordedAt,
                metadataJson: metadataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String idempotencyKey,
                required String operationId,
                required String operationType,
                required String payloadJson,
                required String remoteReference,
                required BigInt debitAmountKobo,
                required BigInt settledAt,
                required BigInt recordedAt,
                Value<String?> metadataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemoteIdempotencyTableCompanion.insert(
                idempotencyKey: idempotencyKey,
                operationId: operationId,
                operationType: operationType,
                payloadJson: payloadJson,
                remoteReference: remoteReference,
                debitAmountKobo: debitAmountKobo,
                settledAt: settledAt,
                recordedAt: recordedAt,
                metadataJson: metadataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $RemoteIdempotencyTableTable,
                    RemoteIdempotencyEntry
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RemoteIdempotencyTableTable,
                    RemoteIdempotencyEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemoteIdempotencyTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemoteIdempotencyTableTable,
      RemoteIdempotencyEntry,
      $$RemoteIdempotencyTableTableFilterComposer,
      $$RemoteIdempotencyTableTableOrderingComposer,
      $$RemoteIdempotencyTableTableAnnotationComposer,
      $$RemoteIdempotencyTableTableCreateCompanionBuilder,
      $$RemoteIdempotencyTableTableUpdateCompanionBuilder,
      (
        RemoteIdempotencyEntry,
        BaseReferences<
          _$AppDatabase,
          $RemoteIdempotencyTableTable,
          RemoteIdempotencyEntry
        >,
      ),
      RemoteIdempotencyEntry,
      PrefetchHooks Function()
    >;
typedef $$RemoteWalletStateTableTableCreateCompanionBuilder =
    RemoteWalletStateTableCompanion Function({
      Value<int> id,
      required BigInt balanceKobo,
      required BigInt lastUpdatedAt,
    });
typedef $$RemoteWalletStateTableTableUpdateCompanionBuilder =
    RemoteWalletStateTableCompanion Function({
      Value<int> id,
      Value<BigInt> balanceKobo,
      Value<BigInt> lastUpdatedAt,
    });

class $$RemoteWalletStateTableTableFilterComposer
    extends Composer<_$AppDatabase, $RemoteWalletStateTableTable> {
  $$RemoteWalletStateTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get balanceKobo => $composableBuilder(
    column: $table.balanceKobo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemoteWalletStateTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RemoteWalletStateTableTable> {
  $$RemoteWalletStateTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get balanceKobo => $composableBuilder(
    column: $table.balanceKobo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemoteWalletStateTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemoteWalletStateTableTable> {
  $$RemoteWalletStateTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<BigInt> get balanceKobo => $composableBuilder(
    column: $table.balanceKobo,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => column,
  );
}

class $$RemoteWalletStateTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemoteWalletStateTableTable,
          RemoteWalletStateEntry,
          $$RemoteWalletStateTableTableFilterComposer,
          $$RemoteWalletStateTableTableOrderingComposer,
          $$RemoteWalletStateTableTableAnnotationComposer,
          $$RemoteWalletStateTableTableCreateCompanionBuilder,
          $$RemoteWalletStateTableTableUpdateCompanionBuilder,
          (
            RemoteWalletStateEntry,
            BaseReferences<
              _$AppDatabase,
              $RemoteWalletStateTableTable,
              RemoteWalletStateEntry
            >,
          ),
          RemoteWalletStateEntry,
          PrefetchHooks Function()
        > {
  $$RemoteWalletStateTableTableTableManager(
    _$AppDatabase db,
    $RemoteWalletStateTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemoteWalletStateTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RemoteWalletStateTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RemoteWalletStateTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<BigInt> balanceKobo = const Value.absent(),
                Value<BigInt> lastUpdatedAt = const Value.absent(),
              }) => RemoteWalletStateTableCompanion(
                id: id,
                balanceKobo: balanceKobo,
                lastUpdatedAt: lastUpdatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required BigInt balanceKobo,
                required BigInt lastUpdatedAt,
              }) => RemoteWalletStateTableCompanion.insert(
                id: id,
                balanceKobo: balanceKobo,
                lastUpdatedAt: lastUpdatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $RemoteWalletStateTableTable,
                    RemoteWalletStateEntry
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RemoteWalletStateTableTable,
                    RemoteWalletStateEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemoteWalletStateTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemoteWalletStateTableTable,
      RemoteWalletStateEntry,
      $$RemoteWalletStateTableTableFilterComposer,
      $$RemoteWalletStateTableTableOrderingComposer,
      $$RemoteWalletStateTableTableAnnotationComposer,
      $$RemoteWalletStateTableTableCreateCompanionBuilder,
      $$RemoteWalletStateTableTableUpdateCompanionBuilder,
      (
        RemoteWalletStateEntry,
        BaseReferences<
          _$AppDatabase,
          $RemoteWalletStateTableTable,
          RemoteWalletStateEntry
        >,
      ),
      RemoteWalletStateEntry,
      PrefetchHooks Function()
    >;
typedef $$RemoteTransactionsTableTableCreateCompanionBuilder =
    RemoteTransactionsTableCompanion Function({
      required String id,
      required String transactionType,
      required BigInt amountKobo,
      required String counterparty,
      required BigInt createdAt,
      Value<String> status,
      Value<String?> reference,
      Value<String?> narration,
      Value<int> rowid,
    });
typedef $$RemoteTransactionsTableTableUpdateCompanionBuilder =
    RemoteTransactionsTableCompanion Function({
      Value<String> id,
      Value<String> transactionType,
      Value<BigInt> amountKobo,
      Value<String> counterparty,
      Value<BigInt> createdAt,
      Value<String> status,
      Value<String?> reference,
      Value<String?> narration,
      Value<int> rowid,
    });

class $$RemoteTransactionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $RemoteTransactionsTableTable> {
  $$RemoteTransactionsTableTableFilterComposer({
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

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get amountKobo => $composableBuilder(
    column: $table.amountKobo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get narration => $composableBuilder(
    column: $table.narration,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemoteTransactionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RemoteTransactionsTableTable> {
  $$RemoteTransactionsTableTableOrderingComposer({
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

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get amountKobo => $composableBuilder(
    column: $table.amountKobo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get narration => $composableBuilder(
    column: $table.narration,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemoteTransactionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemoteTransactionsTableTable> {
  $$RemoteTransactionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get amountKobo => $composableBuilder(
    column: $table.amountKobo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get narration =>
      $composableBuilder(column: $table.narration, builder: (column) => column);
}

class $$RemoteTransactionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemoteTransactionsTableTable,
          RemoteTransactionEntry,
          $$RemoteTransactionsTableTableFilterComposer,
          $$RemoteTransactionsTableTableOrderingComposer,
          $$RemoteTransactionsTableTableAnnotationComposer,
          $$RemoteTransactionsTableTableCreateCompanionBuilder,
          $$RemoteTransactionsTableTableUpdateCompanionBuilder,
          (
            RemoteTransactionEntry,
            BaseReferences<
              _$AppDatabase,
              $RemoteTransactionsTableTable,
              RemoteTransactionEntry
            >,
          ),
          RemoteTransactionEntry,
          PrefetchHooks Function()
        > {
  $$RemoteTransactionsTableTableTableManager(
    _$AppDatabase db,
    $RemoteTransactionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemoteTransactionsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RemoteTransactionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RemoteTransactionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
                Value<BigInt> amountKobo = const Value.absent(),
                Value<String> counterparty = const Value.absent(),
                Value<BigInt> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String?> narration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemoteTransactionsTableCompanion(
                id: id,
                transactionType: transactionType,
                amountKobo: amountKobo,
                counterparty: counterparty,
                createdAt: createdAt,
                status: status,
                reference: reference,
                narration: narration,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transactionType,
                required BigInt amountKobo,
                required String counterparty,
                required BigInt createdAt,
                Value<String> status = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String?> narration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemoteTransactionsTableCompanion.insert(
                id: id,
                transactionType: transactionType,
                amountKobo: amountKobo,
                counterparty: counterparty,
                createdAt: createdAt,
                status: status,
                reference: reference,
                narration: narration,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $RemoteTransactionsTableTable,
                    RemoteTransactionEntry
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RemoteTransactionsTableTable,
                    RemoteTransactionEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemoteTransactionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemoteTransactionsTableTable,
      RemoteTransactionEntry,
      $$RemoteTransactionsTableTableFilterComposer,
      $$RemoteTransactionsTableTableOrderingComposer,
      $$RemoteTransactionsTableTableAnnotationComposer,
      $$RemoteTransactionsTableTableCreateCompanionBuilder,
      $$RemoteTransactionsTableTableUpdateCompanionBuilder,
      (
        RemoteTransactionEntry,
        BaseReferences<
          _$AppDatabase,
          $RemoteTransactionsTableTable,
          RemoteTransactionEntry
        >,
      ),
      RemoteTransactionEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PendingOperationsTableTableManager get pendingOperations =>
      $$PendingOperationsTableTableManager(_db, _db.pendingOperations);
  $$WalletCacheTableTableManager get walletCache =>
      $$WalletCacheTableTableManager(_db, _db.walletCache);
  $$TransactionsTableTableTableManager get transactionsTable =>
      $$TransactionsTableTableTableManager(_db, _db.transactionsTable);
  $$SavingsGoalsTableTableTableManager get savingsGoalsTable =>
      $$SavingsGoalsTableTableTableManager(_db, _db.savingsGoalsTable);
  $$RemoteIdempotencyTableTableTableManager get remoteIdempotencyTable =>
      $$RemoteIdempotencyTableTableTableManager(
        _db,
        _db.remoteIdempotencyTable,
      );
  $$RemoteWalletStateTableTableTableManager get remoteWalletStateTable =>
      $$RemoteWalletStateTableTableTableManager(
        _db,
        _db.remoteWalletStateTable,
      );
  $$RemoteTransactionsTableTableTableManager get remoteTransactionsTable =>
      $$RemoteTransactionsTableTableTableManager(
        _db,
        _db.remoteTransactionsTable,
      );
}
