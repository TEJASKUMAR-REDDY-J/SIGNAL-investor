// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $InstrumentsTable extends Instruments
    with TableInfo<$InstrumentsTable, Instrument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstrumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yahooTickerMeta = const VerificationMeta(
    'yahooTicker',
  );
  @override
  late final GeneratedColumn<String> yahooTicker = GeneratedColumn<String>(
    'yahoo_ticker',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nseSymbolMeta = const VerificationMeta(
    'nseSymbol',
  );
  @override
  late final GeneratedColumn<String> nseSymbol = GeneratedColumn<String>(
    'nse_symbol',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _schemeCodeMeta = const VerificationMeta(
    'schemeCode',
  );
  @override
  late final GeneratedColumn<String> schemeCode = GeneratedColumn<String>(
    'scheme_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _aliasesMeta = const VerificationMeta(
    'aliases',
  );
  @override
  late final GeneratedColumn<String> aliases = GeneratedColumn<String>(
    'aliases',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    yahooTicker,
    nseSymbol,
    schemeCode,
    name,
    aliases,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'instruments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Instrument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('yahoo_ticker')) {
      context.handle(
        _yahooTickerMeta,
        yahooTicker.isAcceptableOrUnknown(
          data['yahoo_ticker']!,
          _yahooTickerMeta,
        ),
      );
    }
    if (data.containsKey('nse_symbol')) {
      context.handle(
        _nseSymbolMeta,
        nseSymbol.isAcceptableOrUnknown(data['nse_symbol']!, _nseSymbolMeta),
      );
    }
    if (data.containsKey('scheme_code')) {
      context.handle(
        _schemeCodeMeta,
        schemeCode.isAcceptableOrUnknown(data['scheme_code']!, _schemeCodeMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('aliases')) {
      context.handle(
        _aliasesMeta,
        aliases.isAcceptableOrUnknown(data['aliases']!, _aliasesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Instrument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Instrument(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      yahooTicker: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}yahoo_ticker'],
      ),
      nseSymbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nse_symbol'],
      ),
      schemeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheme_code'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      aliases: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aliases'],
      )!,
    );
  }

  @override
  $InstrumentsTable createAlias(String alias) {
    return $InstrumentsTable(attachedDatabase, alias);
  }
}

class Instrument extends DataClass implements Insertable<Instrument> {
  final int id;
  final String kind;
  final String? yahooTicker;
  final String? nseSymbol;
  final String? schemeCode;
  final String name;
  final String aliases;
  const Instrument({
    required this.id,
    required this.kind,
    this.yahooTicker,
    this.nseSymbol,
    this.schemeCode,
    required this.name,
    required this.aliases,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || yahooTicker != null) {
      map['yahoo_ticker'] = Variable<String>(yahooTicker);
    }
    if (!nullToAbsent || nseSymbol != null) {
      map['nse_symbol'] = Variable<String>(nseSymbol);
    }
    if (!nullToAbsent || schemeCode != null) {
      map['scheme_code'] = Variable<String>(schemeCode);
    }
    map['name'] = Variable<String>(name);
    map['aliases'] = Variable<String>(aliases);
    return map;
  }

  InstrumentsCompanion toCompanion(bool nullToAbsent) {
    return InstrumentsCompanion(
      id: Value(id),
      kind: Value(kind),
      yahooTicker: yahooTicker == null && nullToAbsent
          ? const Value.absent()
          : Value(yahooTicker),
      nseSymbol: nseSymbol == null && nullToAbsent
          ? const Value.absent()
          : Value(nseSymbol),
      schemeCode: schemeCode == null && nullToAbsent
          ? const Value.absent()
          : Value(schemeCode),
      name: Value(name),
      aliases: Value(aliases),
    );
  }

  factory Instrument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Instrument(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      yahooTicker: serializer.fromJson<String?>(json['yahooTicker']),
      nseSymbol: serializer.fromJson<String?>(json['nseSymbol']),
      schemeCode: serializer.fromJson<String?>(json['schemeCode']),
      name: serializer.fromJson<String>(json['name']),
      aliases: serializer.fromJson<String>(json['aliases']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'yahooTicker': serializer.toJson<String?>(yahooTicker),
      'nseSymbol': serializer.toJson<String?>(nseSymbol),
      'schemeCode': serializer.toJson<String?>(schemeCode),
      'name': serializer.toJson<String>(name),
      'aliases': serializer.toJson<String>(aliases),
    };
  }

  Instrument copyWith({
    int? id,
    String? kind,
    Value<String?> yahooTicker = const Value.absent(),
    Value<String?> nseSymbol = const Value.absent(),
    Value<String?> schemeCode = const Value.absent(),
    String? name,
    String? aliases,
  }) => Instrument(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    yahooTicker: yahooTicker.present ? yahooTicker.value : this.yahooTicker,
    nseSymbol: nseSymbol.present ? nseSymbol.value : this.nseSymbol,
    schemeCode: schemeCode.present ? schemeCode.value : this.schemeCode,
    name: name ?? this.name,
    aliases: aliases ?? this.aliases,
  );
  Instrument copyWithCompanion(InstrumentsCompanion data) {
    return Instrument(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      yahooTicker: data.yahooTicker.present
          ? data.yahooTicker.value
          : this.yahooTicker,
      nseSymbol: data.nseSymbol.present ? data.nseSymbol.value : this.nseSymbol,
      schemeCode: data.schemeCode.present
          ? data.schemeCode.value
          : this.schemeCode,
      name: data.name.present ? data.name.value : this.name,
      aliases: data.aliases.present ? data.aliases.value : this.aliases,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Instrument(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('yahooTicker: $yahooTicker, ')
          ..write('nseSymbol: $nseSymbol, ')
          ..write('schemeCode: $schemeCode, ')
          ..write('name: $name, ')
          ..write('aliases: $aliases')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, kind, yahooTicker, nseSymbol, schemeCode, name, aliases);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Instrument &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.yahooTicker == this.yahooTicker &&
          other.nseSymbol == this.nseSymbol &&
          other.schemeCode == this.schemeCode &&
          other.name == this.name &&
          other.aliases == this.aliases);
}

class InstrumentsCompanion extends UpdateCompanion<Instrument> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String?> yahooTicker;
  final Value<String?> nseSymbol;
  final Value<String?> schemeCode;
  final Value<String> name;
  final Value<String> aliases;
  const InstrumentsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.yahooTicker = const Value.absent(),
    this.nseSymbol = const Value.absent(),
    this.schemeCode = const Value.absent(),
    this.name = const Value.absent(),
    this.aliases = const Value.absent(),
  });
  InstrumentsCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    this.yahooTicker = const Value.absent(),
    this.nseSymbol = const Value.absent(),
    this.schemeCode = const Value.absent(),
    required String name,
    this.aliases = const Value.absent(),
  }) : kind = Value(kind),
       name = Value(name);
  static Insertable<Instrument> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? yahooTicker,
    Expression<String>? nseSymbol,
    Expression<String>? schemeCode,
    Expression<String>? name,
    Expression<String>? aliases,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (yahooTicker != null) 'yahoo_ticker': yahooTicker,
      if (nseSymbol != null) 'nse_symbol': nseSymbol,
      if (schemeCode != null) 'scheme_code': schemeCode,
      if (name != null) 'name': name,
      if (aliases != null) 'aliases': aliases,
    });
  }

  InstrumentsCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String?>? yahooTicker,
    Value<String?>? nseSymbol,
    Value<String?>? schemeCode,
    Value<String>? name,
    Value<String>? aliases,
  }) {
    return InstrumentsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      yahooTicker: yahooTicker ?? this.yahooTicker,
      nseSymbol: nseSymbol ?? this.nseSymbol,
      schemeCode: schemeCode ?? this.schemeCode,
      name: name ?? this.name,
      aliases: aliases ?? this.aliases,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (yahooTicker.present) {
      map['yahoo_ticker'] = Variable<String>(yahooTicker.value);
    }
    if (nseSymbol.present) {
      map['nse_symbol'] = Variable<String>(nseSymbol.value);
    }
    if (schemeCode.present) {
      map['scheme_code'] = Variable<String>(schemeCode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (aliases.present) {
      map['aliases'] = Variable<String>(aliases.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstrumentsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('yahooTicker: $yahooTicker, ')
          ..write('nseSymbol: $nseSymbol, ')
          ..write('schemeCode: $schemeCode, ')
          ..write('name: $name, ')
          ..write('aliases: $aliases')
          ..write(')'))
        .toString();
  }
}

class $PricesTable extends Prices with TableInfo<$PricesTable, Price> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PricesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _instrumentIdMeta = const VerificationMeta(
    'instrumentId',
  );
  @override
  late final GeneratedColumn<int> instrumentId = GeneratedColumn<int>(
    'instrument_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closeE4Meta = const VerificationMeta(
    'closeE4',
  );
  @override
  late final GeneratedColumn<int> closeE4 = GeneratedColumn<int>(
    'close_e4',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    instrumentId,
    date,
    closeE4,
    source,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prices';
  @override
  VerificationContext validateIntegrity(
    Insertable<Price> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('instrument_id')) {
      context.handle(
        _instrumentIdMeta,
        instrumentId.isAcceptableOrUnknown(
          data['instrument_id']!,
          _instrumentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instrumentIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('close_e4')) {
      context.handle(
        _closeE4Meta,
        closeE4.isAcceptableOrUnknown(data['close_e4']!, _closeE4Meta),
      );
    } else if (isInserting) {
      context.missing(_closeE4Meta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {instrumentId, date, source};
  @override
  Price map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Price(
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}instrument_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      closeE4: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}close_e4'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $PricesTable createAlias(String alias) {
    return $PricesTable(attachedDatabase, alias);
  }
}

class Price extends DataClass implements Insertable<Price> {
  final int instrumentId;
  final String date;
  final int closeE4;
  final String source;
  final DateTime fetchedAt;
  const Price({
    required this.instrumentId,
    required this.date,
    required this.closeE4,
    required this.source,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['instrument_id'] = Variable<int>(instrumentId);
    map['date'] = Variable<String>(date);
    map['close_e4'] = Variable<int>(closeE4);
    map['source'] = Variable<String>(source);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  PricesCompanion toCompanion(bool nullToAbsent) {
    return PricesCompanion(
      instrumentId: Value(instrumentId),
      date: Value(date),
      closeE4: Value(closeE4),
      source: Value(source),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory Price.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Price(
      instrumentId: serializer.fromJson<int>(json['instrumentId']),
      date: serializer.fromJson<String>(json['date']),
      closeE4: serializer.fromJson<int>(json['closeE4']),
      source: serializer.fromJson<String>(json['source']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'instrumentId': serializer.toJson<int>(instrumentId),
      'date': serializer.toJson<String>(date),
      'closeE4': serializer.toJson<int>(closeE4),
      'source': serializer.toJson<String>(source),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  Price copyWith({
    int? instrumentId,
    String? date,
    int? closeE4,
    String? source,
    DateTime? fetchedAt,
  }) => Price(
    instrumentId: instrumentId ?? this.instrumentId,
    date: date ?? this.date,
    closeE4: closeE4 ?? this.closeE4,
    source: source ?? this.source,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  Price copyWithCompanion(PricesCompanion data) {
    return Price(
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      date: data.date.present ? data.date.value : this.date,
      closeE4: data.closeE4.present ? data.closeE4.value : this.closeE4,
      source: data.source.present ? data.source.value : this.source,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Price(')
          ..write('instrumentId: $instrumentId, ')
          ..write('date: $date, ')
          ..write('closeE4: $closeE4, ')
          ..write('source: $source, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(instrumentId, date, closeE4, source, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Price &&
          other.instrumentId == this.instrumentId &&
          other.date == this.date &&
          other.closeE4 == this.closeE4 &&
          other.source == this.source &&
          other.fetchedAt == this.fetchedAt);
}

class PricesCompanion extends UpdateCompanion<Price> {
  final Value<int> instrumentId;
  final Value<String> date;
  final Value<int> closeE4;
  final Value<String> source;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const PricesCompanion({
    this.instrumentId = const Value.absent(),
    this.date = const Value.absent(),
    this.closeE4 = const Value.absent(),
    this.source = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PricesCompanion.insert({
    required int instrumentId,
    required String date,
    required int closeE4,
    required String source,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : instrumentId = Value(instrumentId),
       date = Value(date),
       closeE4 = Value(closeE4),
       source = Value(source),
       fetchedAt = Value(fetchedAt);
  static Insertable<Price> custom({
    Expression<int>? instrumentId,
    Expression<String>? date,
    Expression<int>? closeE4,
    Expression<String>? source,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (instrumentId != null) 'instrument_id': instrumentId,
      if (date != null) 'date': date,
      if (closeE4 != null) 'close_e4': closeE4,
      if (source != null) 'source': source,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PricesCompanion copyWith({
    Value<int>? instrumentId,
    Value<String>? date,
    Value<int>? closeE4,
    Value<String>? source,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return PricesCompanion(
      instrumentId: instrumentId ?? this.instrumentId,
      date: date ?? this.date,
      closeE4: closeE4 ?? this.closeE4,
      source: source ?? this.source,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (instrumentId.present) {
      map['instrument_id'] = Variable<int>(instrumentId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (closeE4.present) {
      map['close_e4'] = Variable<int>(closeE4.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PricesCompanion(')
          ..write('instrumentId: $instrumentId, ')
          ..write('date: $date, ')
          ..write('closeE4: $closeE4, ')
          ..write('source: $source, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NewsItemsTable extends NewsItems
    with TableInfo<$NewsItemsTable, NewsItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NewsItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _urlHashMeta = const VerificationMeta(
    'urlHash',
  );
  @override
  late final GeneratedColumn<String> urlHash = GeneratedColumn<String>(
    'url_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publisherMeta = const VerificationMeta(
    'publisher',
  );
  @override
  late final GeneratedColumn<String> publisher = GeneratedColumn<String>(
    'publisher',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _instrumentIdMeta = const VerificationMeta(
    'instrumentId',
  );
  @override
  late final GeneratedColumn<int> instrumentId = GeneratedColumn<int>(
    'instrument_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    urlHash,
    url,
    title,
    publisher,
    publishedAt,
    instrumentId,
    label,
    confidence,
    reason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'news_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<NewsItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('url_hash')) {
      context.handle(
        _urlHashMeta,
        urlHash.isAcceptableOrUnknown(data['url_hash']!, _urlHashMeta),
      );
    } else if (isInserting) {
      context.missing(_urlHashMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('publisher')) {
      context.handle(
        _publisherMeta,
        publisher.isAcceptableOrUnknown(data['publisher']!, _publisherMeta),
      );
    } else if (isInserting) {
      context.missing(_publisherMeta);
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publishedAtMeta);
    }
    if (data.containsKey('instrument_id')) {
      context.handle(
        _instrumentIdMeta,
        instrumentId.isAcceptableOrUnknown(
          data['instrument_id']!,
          _instrumentIdMeta,
        ),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {urlHash};
  @override
  NewsItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NewsItem(
      urlHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url_hash'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      publisher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publisher'],
      )!,
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}published_at'],
      )!,
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}instrument_id'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
    );
  }

  @override
  $NewsItemsTable createAlias(String alias) {
    return $NewsItemsTable(attachedDatabase, alias);
  }
}

class NewsItem extends DataClass implements Insertable<NewsItem> {
  final String urlHash;
  final String url;
  final String title;
  final String publisher;
  final DateTime publishedAt;
  final int? instrumentId;
  final String? label;
  final double? confidence;
  final String? reason;
  const NewsItem({
    required this.urlHash,
    required this.url,
    required this.title,
    required this.publisher,
    required this.publishedAt,
    this.instrumentId,
    this.label,
    this.confidence,
    this.reason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['url_hash'] = Variable<String>(urlHash);
    map['url'] = Variable<String>(url);
    map['title'] = Variable<String>(title);
    map['publisher'] = Variable<String>(publisher);
    map['published_at'] = Variable<DateTime>(publishedAt);
    if (!nullToAbsent || instrumentId != null) {
      map['instrument_id'] = Variable<int>(instrumentId);
    }
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    return map;
  }

  NewsItemsCompanion toCompanion(bool nullToAbsent) {
    return NewsItemsCompanion(
      urlHash: Value(urlHash),
      url: Value(url),
      title: Value(title),
      publisher: Value(publisher),
      publishedAt: Value(publishedAt),
      instrumentId: instrumentId == null && nullToAbsent
          ? const Value.absent()
          : Value(instrumentId),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
    );
  }

  factory NewsItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NewsItem(
      urlHash: serializer.fromJson<String>(json['urlHash']),
      url: serializer.fromJson<String>(json['url']),
      title: serializer.fromJson<String>(json['title']),
      publisher: serializer.fromJson<String>(json['publisher']),
      publishedAt: serializer.fromJson<DateTime>(json['publishedAt']),
      instrumentId: serializer.fromJson<int?>(json['instrumentId']),
      label: serializer.fromJson<String?>(json['label']),
      confidence: serializer.fromJson<double?>(json['confidence']),
      reason: serializer.fromJson<String?>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'urlHash': serializer.toJson<String>(urlHash),
      'url': serializer.toJson<String>(url),
      'title': serializer.toJson<String>(title),
      'publisher': serializer.toJson<String>(publisher),
      'publishedAt': serializer.toJson<DateTime>(publishedAt),
      'instrumentId': serializer.toJson<int?>(instrumentId),
      'label': serializer.toJson<String?>(label),
      'confidence': serializer.toJson<double?>(confidence),
      'reason': serializer.toJson<String?>(reason),
    };
  }

  NewsItem copyWith({
    String? urlHash,
    String? url,
    String? title,
    String? publisher,
    DateTime? publishedAt,
    Value<int?> instrumentId = const Value.absent(),
    Value<String?> label = const Value.absent(),
    Value<double?> confidence = const Value.absent(),
    Value<String?> reason = const Value.absent(),
  }) => NewsItem(
    urlHash: urlHash ?? this.urlHash,
    url: url ?? this.url,
    title: title ?? this.title,
    publisher: publisher ?? this.publisher,
    publishedAt: publishedAt ?? this.publishedAt,
    instrumentId: instrumentId.present ? instrumentId.value : this.instrumentId,
    label: label.present ? label.value : this.label,
    confidence: confidence.present ? confidence.value : this.confidence,
    reason: reason.present ? reason.value : this.reason,
  );
  NewsItem copyWithCompanion(NewsItemsCompanion data) {
    return NewsItem(
      urlHash: data.urlHash.present ? data.urlHash.value : this.urlHash,
      url: data.url.present ? data.url.value : this.url,
      title: data.title.present ? data.title.value : this.title,
      publisher: data.publisher.present ? data.publisher.value : this.publisher,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      label: data.label.present ? data.label.value : this.label,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NewsItem(')
          ..write('urlHash: $urlHash, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('publisher: $publisher, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('label: $label, ')
          ..write('confidence: $confidence, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    urlHash,
    url,
    title,
    publisher,
    publishedAt,
    instrumentId,
    label,
    confidence,
    reason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NewsItem &&
          other.urlHash == this.urlHash &&
          other.url == this.url &&
          other.title == this.title &&
          other.publisher == this.publisher &&
          other.publishedAt == this.publishedAt &&
          other.instrumentId == this.instrumentId &&
          other.label == this.label &&
          other.confidence == this.confidence &&
          other.reason == this.reason);
}

class NewsItemsCompanion extends UpdateCompanion<NewsItem> {
  final Value<String> urlHash;
  final Value<String> url;
  final Value<String> title;
  final Value<String> publisher;
  final Value<DateTime> publishedAt;
  final Value<int?> instrumentId;
  final Value<String?> label;
  final Value<double?> confidence;
  final Value<String?> reason;
  final Value<int> rowid;
  const NewsItemsCompanion({
    this.urlHash = const Value.absent(),
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.publisher = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.instrumentId = const Value.absent(),
    this.label = const Value.absent(),
    this.confidence = const Value.absent(),
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NewsItemsCompanion.insert({
    required String urlHash,
    required String url,
    required String title,
    required String publisher,
    required DateTime publishedAt,
    this.instrumentId = const Value.absent(),
    this.label = const Value.absent(),
    this.confidence = const Value.absent(),
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : urlHash = Value(urlHash),
       url = Value(url),
       title = Value(title),
       publisher = Value(publisher),
       publishedAt = Value(publishedAt);
  static Insertable<NewsItem> custom({
    Expression<String>? urlHash,
    Expression<String>? url,
    Expression<String>? title,
    Expression<String>? publisher,
    Expression<DateTime>? publishedAt,
    Expression<int>? instrumentId,
    Expression<String>? label,
    Expression<double>? confidence,
    Expression<String>? reason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (urlHash != null) 'url_hash': urlHash,
      if (url != null) 'url': url,
      if (title != null) 'title': title,
      if (publisher != null) 'publisher': publisher,
      if (publishedAt != null) 'published_at': publishedAt,
      if (instrumentId != null) 'instrument_id': instrumentId,
      if (label != null) 'label': label,
      if (confidence != null) 'confidence': confidence,
      if (reason != null) 'reason': reason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NewsItemsCompanion copyWith({
    Value<String>? urlHash,
    Value<String>? url,
    Value<String>? title,
    Value<String>? publisher,
    Value<DateTime>? publishedAt,
    Value<int?>? instrumentId,
    Value<String?>? label,
    Value<double?>? confidence,
    Value<String?>? reason,
    Value<int>? rowid,
  }) {
    return NewsItemsCompanion(
      urlHash: urlHash ?? this.urlHash,
      url: url ?? this.url,
      title: title ?? this.title,
      publisher: publisher ?? this.publisher,
      publishedAt: publishedAt ?? this.publishedAt,
      instrumentId: instrumentId ?? this.instrumentId,
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      reason: reason ?? this.reason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (urlHash.present) {
      map['url_hash'] = Variable<String>(urlHash.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (publisher.present) {
      map['publisher'] = Variable<String>(publisher.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (instrumentId.present) {
      map['instrument_id'] = Variable<int>(instrumentId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NewsItemsCompanion(')
          ..write('urlHash: $urlHash, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('publisher: $publisher, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('label: $label, ')
          ..write('confidence: $confidence, ')
          ..write('reason: $reason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FilingsTable extends Filings with TableInfo<$FilingsTable, Filing> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _instrumentIdMeta = const VerificationMeta(
    'instrumentId',
  );
  @override
  late final GeneratedColumn<int> instrumentId = GeneratedColumn<int>(
    'instrument_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    instrumentId,
    date,
    category,
    subject,
    url,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'filings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Filing> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('instrument_id')) {
      context.handle(
        _instrumentIdMeta,
        instrumentId.isAcceptableOrUnknown(
          data['instrument_id']!,
          _instrumentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instrumentIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Filing map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Filing(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}instrument_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
    );
  }

  @override
  $FilingsTable createAlias(String alias) {
    return $FilingsTable(attachedDatabase, alias);
  }
}

class Filing extends DataClass implements Insertable<Filing> {
  final int id;
  final int instrumentId;
  final String date;
  final String category;
  final String subject;
  final String url;
  const Filing({
    required this.id,
    required this.instrumentId,
    required this.date,
    required this.category,
    required this.subject,
    required this.url,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['instrument_id'] = Variable<int>(instrumentId);
    map['date'] = Variable<String>(date);
    map['category'] = Variable<String>(category);
    map['subject'] = Variable<String>(subject);
    map['url'] = Variable<String>(url);
    return map;
  }

  FilingsCompanion toCompanion(bool nullToAbsent) {
    return FilingsCompanion(
      id: Value(id),
      instrumentId: Value(instrumentId),
      date: Value(date),
      category: Value(category),
      subject: Value(subject),
      url: Value(url),
    );
  }

  factory Filing.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Filing(
      id: serializer.fromJson<int>(json['id']),
      instrumentId: serializer.fromJson<int>(json['instrumentId']),
      date: serializer.fromJson<String>(json['date']),
      category: serializer.fromJson<String>(json['category']),
      subject: serializer.fromJson<String>(json['subject']),
      url: serializer.fromJson<String>(json['url']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'instrumentId': serializer.toJson<int>(instrumentId),
      'date': serializer.toJson<String>(date),
      'category': serializer.toJson<String>(category),
      'subject': serializer.toJson<String>(subject),
      'url': serializer.toJson<String>(url),
    };
  }

  Filing copyWith({
    int? id,
    int? instrumentId,
    String? date,
    String? category,
    String? subject,
    String? url,
  }) => Filing(
    id: id ?? this.id,
    instrumentId: instrumentId ?? this.instrumentId,
    date: date ?? this.date,
    category: category ?? this.category,
    subject: subject ?? this.subject,
    url: url ?? this.url,
  );
  Filing copyWithCompanion(FilingsCompanion data) {
    return Filing(
      id: data.id.present ? data.id.value : this.id,
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      date: data.date.present ? data.date.value : this.date,
      category: data.category.present ? data.category.value : this.category,
      subject: data.subject.present ? data.subject.value : this.subject,
      url: data.url.present ? data.url.value : this.url,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Filing(')
          ..write('id: $id, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('subject: $subject, ')
          ..write('url: $url')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, instrumentId, date, category, subject, url);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Filing &&
          other.id == this.id &&
          other.instrumentId == this.instrumentId &&
          other.date == this.date &&
          other.category == this.category &&
          other.subject == this.subject &&
          other.url == this.url);
}

class FilingsCompanion extends UpdateCompanion<Filing> {
  final Value<int> id;
  final Value<int> instrumentId;
  final Value<String> date;
  final Value<String> category;
  final Value<String> subject;
  final Value<String> url;
  const FilingsCompanion({
    this.id = const Value.absent(),
    this.instrumentId = const Value.absent(),
    this.date = const Value.absent(),
    this.category = const Value.absent(),
    this.subject = const Value.absent(),
    this.url = const Value.absent(),
  });
  FilingsCompanion.insert({
    this.id = const Value.absent(),
    required int instrumentId,
    required String date,
    required String category,
    required String subject,
    required String url,
  }) : instrumentId = Value(instrumentId),
       date = Value(date),
       category = Value(category),
       subject = Value(subject),
       url = Value(url);
  static Insertable<Filing> custom({
    Expression<int>? id,
    Expression<int>? instrumentId,
    Expression<String>? date,
    Expression<String>? category,
    Expression<String>? subject,
    Expression<String>? url,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (instrumentId != null) 'instrument_id': instrumentId,
      if (date != null) 'date': date,
      if (category != null) 'category': category,
      if (subject != null) 'subject': subject,
      if (url != null) 'url': url,
    });
  }

  FilingsCompanion copyWith({
    Value<int>? id,
    Value<int>? instrumentId,
    Value<String>? date,
    Value<String>? category,
    Value<String>? subject,
    Value<String>? url,
  }) {
    return FilingsCompanion(
      id: id ?? this.id,
      instrumentId: instrumentId ?? this.instrumentId,
      date: date ?? this.date,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      url: url ?? this.url,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (instrumentId.present) {
      map['instrument_id'] = Variable<int>(instrumentId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilingsCompanion(')
          ..write('id: $id, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('subject: $subject, ')
          ..write('url: $url')
          ..write(')'))
        .toString();
  }
}

class $FetchLogTable extends FetchLog
    with TableInfo<$FetchLogTable, FetchLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FetchLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastOkAtMeta = const VerificationMeta(
    'lastOkAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastOkAt = GeneratedColumn<DateTime>(
    'last_ok_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rowsMeta = const VerificationMeta('rows');
  @override
  late final GeneratedColumn<int> rows = GeneratedColumn<int>(
    'rows',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    source,
    lastOkAt,
    lastAttemptAt,
    lastError,
    rows,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fetch_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<FetchLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('last_ok_at')) {
      context.handle(
        _lastOkAtMeta,
        lastOkAt.isAcceptableOrUnknown(data['last_ok_at']!, _lastOkAtMeta),
      );
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
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('rows')) {
      context.handle(
        _rowsMeta,
        rows.isAcceptableOrUnknown(data['rows']!, _rowsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {source};
  @override
  FetchLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FetchLogData(
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      lastOkAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_ok_at'],
      ),
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      rows: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rows'],
      )!,
    );
  }

  @override
  $FetchLogTable createAlias(String alias) {
    return $FetchLogTable(attachedDatabase, alias);
  }
}

class FetchLogData extends DataClass implements Insertable<FetchLogData> {
  final String source;
  final DateTime? lastOkAt;
  final DateTime? lastAttemptAt;
  final String? lastError;
  final int rows;
  const FetchLogData({
    required this.source,
    this.lastOkAt,
    this.lastAttemptAt,
    this.lastError,
    required this.rows,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || lastOkAt != null) {
      map['last_ok_at'] = Variable<DateTime>(lastOkAt);
    }
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['rows'] = Variable<int>(rows);
    return map;
  }

  FetchLogCompanion toCompanion(bool nullToAbsent) {
    return FetchLogCompanion(
      source: Value(source),
      lastOkAt: lastOkAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOkAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      rows: Value(rows),
    );
  }

  factory FetchLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FetchLogData(
      source: serializer.fromJson<String>(json['source']),
      lastOkAt: serializer.fromJson<DateTime?>(json['lastOkAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      rows: serializer.fromJson<int>(json['rows']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source': serializer.toJson<String>(source),
      'lastOkAt': serializer.toJson<DateTime?>(lastOkAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'rows': serializer.toJson<int>(rows),
    };
  }

  FetchLogData copyWith({
    String? source,
    Value<DateTime?> lastOkAt = const Value.absent(),
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    int? rows,
  }) => FetchLogData(
    source: source ?? this.source,
    lastOkAt: lastOkAt.present ? lastOkAt.value : this.lastOkAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    rows: rows ?? this.rows,
  );
  FetchLogData copyWithCompanion(FetchLogCompanion data) {
    return FetchLogData(
      source: data.source.present ? data.source.value : this.source,
      lastOkAt: data.lastOkAt.present ? data.lastOkAt.value : this.lastOkAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      rows: data.rows.present ? data.rows.value : this.rows,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FetchLogData(')
          ..write('source: $source, ')
          ..write('lastOkAt: $lastOkAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('rows: $rows')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(source, lastOkAt, lastAttemptAt, lastError, rows);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FetchLogData &&
          other.source == this.source &&
          other.lastOkAt == this.lastOkAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.lastError == this.lastError &&
          other.rows == this.rows);
}

class FetchLogCompanion extends UpdateCompanion<FetchLogData> {
  final Value<String> source;
  final Value<DateTime?> lastOkAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<String?> lastError;
  final Value<int> rows;
  final Value<int> rowid;
  const FetchLogCompanion({
    this.source = const Value.absent(),
    this.lastOkAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rows = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FetchLogCompanion.insert({
    required String source,
    this.lastOkAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rows = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : source = Value(source);
  static Insertable<FetchLogData> custom({
    Expression<String>? source,
    Expression<DateTime>? lastOkAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<String>? lastError,
    Expression<int>? rows,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (source != null) 'source': source,
      if (lastOkAt != null) 'last_ok_at': lastOkAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (rows != null) 'rows': rows,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FetchLogCompanion copyWith({
    Value<String>? source,
    Value<DateTime?>? lastOkAt,
    Value<DateTime?>? lastAttemptAt,
    Value<String?>? lastError,
    Value<int>? rows,
    Value<int>? rowid,
  }) {
    return FetchLogCompanion(
      source: source ?? this.source,
      lastOkAt: lastOkAt ?? this.lastOkAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: lastError ?? this.lastError,
      rows: rows ?? this.rows,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (lastOkAt.present) {
      map['last_ok_at'] = Variable<DateTime>(lastOkAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rows.present) {
      map['rows'] = Variable<int>(rows.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FetchLogCompanion(')
          ..write('source: $source, ')
          ..write('lastOkAt: $lastOkAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('rows: $rows, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HolidaysTable extends Holidays with TableInfo<$HolidaysTable, Holiday> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HolidaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
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
  @override
  List<GeneratedColumn> get $columns => [date, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'holidays';
  @override
  VerificationContext validateIntegrity(
    Insertable<Holiday> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  Holiday map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Holiday(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $HolidaysTable createAlias(String alias) {
    return $HolidaysTable(attachedDatabase, alias);
  }
}

class Holiday extends DataClass implements Insertable<Holiday> {
  final String date;
  final String name;
  const Holiday({required this.date, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['name'] = Variable<String>(name);
    return map;
  }

  HolidaysCompanion toCompanion(bool nullToAbsent) {
    return HolidaysCompanion(date: Value(date), name: Value(name));
  }

  factory Holiday.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Holiday(
      date: serializer.fromJson<String>(json['date']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'name': serializer.toJson<String>(name),
    };
  }

  Holiday copyWith({String? date, String? name}) =>
      Holiday(date: date ?? this.date, name: name ?? this.name);
  Holiday copyWithCompanion(HolidaysCompanion data) {
    return Holiday(
      date: data.date.present ? data.date.value : this.date,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Holiday(')
          ..write('date: $date, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Holiday && other.date == this.date && other.name == this.name);
}

class HolidaysCompanion extends UpdateCompanion<Holiday> {
  final Value<String> date;
  final Value<String> name;
  final Value<int> rowid;
  const HolidaysCompanion({
    this.date = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HolidaysCompanion.insert({
    required String date,
    required String name,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       name = Value(name);
  static Insertable<Holiday> custom({
    Expression<String>? date,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HolidaysCompanion copyWith({
    Value<String>? date,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return HolidaysCompanion(
      date: date ?? this.date,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HolidaysCompanion(')
          ..write('date: $date, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UniverseTable extends Universe with TableInfo<$UniverseTable, Listing> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UniverseTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
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
  static const VerificationMeta _industryMeta = const VerificationMeta(
    'industry',
  );
  @override
  late final GeneratedColumn<String> industry = GeneratedColumn<String>(
    'industry',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isinMeta = const VerificationMeta('isin');
  @override
  late final GeneratedColumn<String> isin = GeneratedColumn<String>(
    'isin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nifty500Meta = const VerificationMeta(
    'nifty500',
  );
  @override
  late final GeneratedColumn<bool> nifty500 = GeneratedColumn<bool>(
    'nifty500',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("nifty500" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    symbol,
    name,
    industry,
    isin,
    nifty500,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'universe';
  @override
  VerificationContext validateIntegrity(
    Insertable<Listing> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('industry')) {
      context.handle(
        _industryMeta,
        industry.isAcceptableOrUnknown(data['industry']!, _industryMeta),
      );
    }
    if (data.containsKey('isin')) {
      context.handle(
        _isinMeta,
        isin.isAcceptableOrUnknown(data['isin']!, _isinMeta),
      );
    }
    if (data.containsKey('nifty500')) {
      context.handle(
        _nifty500Meta,
        nifty500.isAcceptableOrUnknown(data['nifty500']!, _nifty500Meta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {symbol};
  @override
  Listing map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Listing(
      symbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      industry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}industry'],
      )!,
      isin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isin'],
      )!,
      nifty500: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}nifty500'],
      )!,
    );
  }

  @override
  $UniverseTable createAlias(String alias) {
    return $UniverseTable(attachedDatabase, alias);
  }
}

class Listing extends DataClass implements Insertable<Listing> {
  final String symbol;
  final String name;
  final String industry;
  final String isin;
  final bool nifty500;
  const Listing({
    required this.symbol,
    required this.name,
    required this.industry,
    required this.isin,
    required this.nifty500,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['symbol'] = Variable<String>(symbol);
    map['name'] = Variable<String>(name);
    map['industry'] = Variable<String>(industry);
    map['isin'] = Variable<String>(isin);
    map['nifty500'] = Variable<bool>(nifty500);
    return map;
  }

  UniverseCompanion toCompanion(bool nullToAbsent) {
    return UniverseCompanion(
      symbol: Value(symbol),
      name: Value(name),
      industry: Value(industry),
      isin: Value(isin),
      nifty500: Value(nifty500),
    );
  }

  factory Listing.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Listing(
      symbol: serializer.fromJson<String>(json['symbol']),
      name: serializer.fromJson<String>(json['name']),
      industry: serializer.fromJson<String>(json['industry']),
      isin: serializer.fromJson<String>(json['isin']),
      nifty500: serializer.fromJson<bool>(json['nifty500']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'symbol': serializer.toJson<String>(symbol),
      'name': serializer.toJson<String>(name),
      'industry': serializer.toJson<String>(industry),
      'isin': serializer.toJson<String>(isin),
      'nifty500': serializer.toJson<bool>(nifty500),
    };
  }

  Listing copyWith({
    String? symbol,
    String? name,
    String? industry,
    String? isin,
    bool? nifty500,
  }) => Listing(
    symbol: symbol ?? this.symbol,
    name: name ?? this.name,
    industry: industry ?? this.industry,
    isin: isin ?? this.isin,
    nifty500: nifty500 ?? this.nifty500,
  );
  Listing copyWithCompanion(UniverseCompanion data) {
    return Listing(
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      name: data.name.present ? data.name.value : this.name,
      industry: data.industry.present ? data.industry.value : this.industry,
      isin: data.isin.present ? data.isin.value : this.isin,
      nifty500: data.nifty500.present ? data.nifty500.value : this.nifty500,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Listing(')
          ..write('symbol: $symbol, ')
          ..write('name: $name, ')
          ..write('industry: $industry, ')
          ..write('isin: $isin, ')
          ..write('nifty500: $nifty500')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(symbol, name, industry, isin, nifty500);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Listing &&
          other.symbol == this.symbol &&
          other.name == this.name &&
          other.industry == this.industry &&
          other.isin == this.isin &&
          other.nifty500 == this.nifty500);
}

class UniverseCompanion extends UpdateCompanion<Listing> {
  final Value<String> symbol;
  final Value<String> name;
  final Value<String> industry;
  final Value<String> isin;
  final Value<bool> nifty500;
  final Value<int> rowid;
  const UniverseCompanion({
    this.symbol = const Value.absent(),
    this.name = const Value.absent(),
    this.industry = const Value.absent(),
    this.isin = const Value.absent(),
    this.nifty500 = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UniverseCompanion.insert({
    required String symbol,
    required String name,
    this.industry = const Value.absent(),
    this.isin = const Value.absent(),
    this.nifty500 = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : symbol = Value(symbol),
       name = Value(name);
  static Insertable<Listing> custom({
    Expression<String>? symbol,
    Expression<String>? name,
    Expression<String>? industry,
    Expression<String>? isin,
    Expression<bool>? nifty500,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (symbol != null) 'symbol': symbol,
      if (name != null) 'name': name,
      if (industry != null) 'industry': industry,
      if (isin != null) 'isin': isin,
      if (nifty500 != null) 'nifty500': nifty500,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UniverseCompanion copyWith({
    Value<String>? symbol,
    Value<String>? name,
    Value<String>? industry,
    Value<String>? isin,
    Value<bool>? nifty500,
    Value<int>? rowid,
  }) {
    return UniverseCompanion(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      industry: industry ?? this.industry,
      isin: isin ?? this.isin,
      nifty500: nifty500 ?? this.nifty500,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (industry.present) {
      map['industry'] = Variable<String>(industry.value);
    }
    if (isin.present) {
      map['isin'] = Variable<String>(isin.value);
    }
    if (nifty500.present) {
      map['nifty500'] = Variable<bool>(nifty500.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UniverseCompanion(')
          ..write('symbol: $symbol, ')
          ..write('name: $name, ')
          ..write('industry: $industry, ')
          ..write('isin: $isin, ')
          ..write('nifty500: $nifty500, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FundamentalsTable extends Fundamentals
    with TableInfo<$FundamentalsTable, Fundamental> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FundamentalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [symbol, json, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fundamentals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Fundamental> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {symbol};
  @override
  Fundamental map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Fundamental(
      symbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $FundamentalsTable createAlias(String alias) {
    return $FundamentalsTable(attachedDatabase, alias);
  }
}

class Fundamental extends DataClass implements Insertable<Fundamental> {
  final String symbol;
  final String json;
  final DateTime fetchedAt;
  const Fundamental({
    required this.symbol,
    required this.json,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['symbol'] = Variable<String>(symbol);
    map['json'] = Variable<String>(json);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  FundamentalsCompanion toCompanion(bool nullToAbsent) {
    return FundamentalsCompanion(
      symbol: Value(symbol),
      json: Value(json),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory Fundamental.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Fundamental(
      symbol: serializer.fromJson<String>(json['symbol']),
      json: serializer.fromJson<String>(json['json']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'symbol': serializer.toJson<String>(symbol),
      'json': serializer.toJson<String>(json),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  Fundamental copyWith({String? symbol, String? json, DateTime? fetchedAt}) =>
      Fundamental(
        symbol: symbol ?? this.symbol,
        json: json ?? this.json,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  Fundamental copyWithCompanion(FundamentalsCompanion data) {
    return Fundamental(
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      json: data.json.present ? data.json.value : this.json,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Fundamental(')
          ..write('symbol: $symbol, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(symbol, json, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Fundamental &&
          other.symbol == this.symbol &&
          other.json == this.json &&
          other.fetchedAt == this.fetchedAt);
}

class FundamentalsCompanion extends UpdateCompanion<Fundamental> {
  final Value<String> symbol;
  final Value<String> json;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const FundamentalsCompanion({
    this.symbol = const Value.absent(),
    this.json = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FundamentalsCompanion.insert({
    required String symbol,
    required String json,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : symbol = Value(symbol),
       json = Value(json),
       fetchedAt = Value(fetchedAt);
  static Insertable<Fundamental> custom({
    Expression<String>? symbol,
    Expression<String>? json,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (symbol != null) 'symbol': symbol,
      if (json != null) 'json': json,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FundamentalsCompanion copyWith({
    Value<String>? symbol,
    Value<String>? json,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return FundamentalsCompanion(
      symbol: symbol ?? this.symbol,
      json: json ?? this.json,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FundamentalsCompanion(')
          ..write('symbol: $symbol, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AgentTradesTable extends AgentTrades
    with TableInfo<$AgentTradesTable, AgentTrade> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgentTradesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _agentMeta = const VerificationMeta('agent');
  @override
  late final GeneratedColumn<String> agent = GeneratedColumn<String>(
    'agent',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _instrumentIdMeta = const VerificationMeta(
    'instrumentId',
  );
  @override
  late final GeneratedColumn<int> instrumentId = GeneratedColumn<int>(
    'instrument_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sideMeta = const VerificationMeta('side');
  @override
  late final GeneratedColumn<String> side = GeneratedColumn<String>(
    'side',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitsE4Meta = const VerificationMeta(
    'unitsE4',
  );
  @override
  late final GeneratedColumn<int> unitsE4 = GeneratedColumn<int>(
    'units_e4',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceE4Meta = const VerificationMeta(
    'priceE4',
  );
  @override
  late final GeneratedColumn<int> priceE4 = GeneratedColumn<int>(
    'price_e4',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feesPaiseMeta = const VerificationMeta(
    'feesPaise',
  );
  @override
  late final GeneratedColumn<int> feesPaise = GeneratedColumn<int>(
    'fees_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    agent,
    instrumentId,
    date,
    at,
    side,
    unitsE4,
    priceE4,
    feesPaise,
    reason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_trades';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgentTrade> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('agent')) {
      context.handle(
        _agentMeta,
        agent.isAcceptableOrUnknown(data['agent']!, _agentMeta),
      );
    } else if (isInserting) {
      context.missing(_agentMeta);
    }
    if (data.containsKey('instrument_id')) {
      context.handle(
        _instrumentIdMeta,
        instrumentId.isAcceptableOrUnknown(
          data['instrument_id']!,
          _instrumentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instrumentIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('side')) {
      context.handle(
        _sideMeta,
        side.isAcceptableOrUnknown(data['side']!, _sideMeta),
      );
    } else if (isInserting) {
      context.missing(_sideMeta);
    }
    if (data.containsKey('units_e4')) {
      context.handle(
        _unitsE4Meta,
        unitsE4.isAcceptableOrUnknown(data['units_e4']!, _unitsE4Meta),
      );
    } else if (isInserting) {
      context.missing(_unitsE4Meta);
    }
    if (data.containsKey('price_e4')) {
      context.handle(
        _priceE4Meta,
        priceE4.isAcceptableOrUnknown(data['price_e4']!, _priceE4Meta),
      );
    } else if (isInserting) {
      context.missing(_priceE4Meta);
    }
    if (data.containsKey('fees_paise')) {
      context.handle(
        _feesPaiseMeta,
        feesPaise.isAcceptableOrUnknown(data['fees_paise']!, _feesPaiseMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgentTrade map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentTrade(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      agent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent'],
      )!,
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}instrument_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      side: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}side'],
      )!,
      unitsE4: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}units_e4'],
      )!,
      priceE4: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_e4'],
      )!,
      feesPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fees_paise'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
    );
  }

  @override
  $AgentTradesTable createAlias(String alias) {
    return $AgentTradesTable(attachedDatabase, alias);
  }
}

class AgentTrade extends DataClass implements Insertable<AgentTrade> {
  final int id;
  final String agent;
  final int instrumentId;
  final String date;
  final DateTime at;
  final String side;
  final int unitsE4;
  final int priceE4;
  final int feesPaise;
  final String reason;
  const AgentTrade({
    required this.id,
    required this.agent,
    required this.instrumentId,
    required this.date,
    required this.at,
    required this.side,
    required this.unitsE4,
    required this.priceE4,
    required this.feesPaise,
    required this.reason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['agent'] = Variable<String>(agent);
    map['instrument_id'] = Variable<int>(instrumentId);
    map['date'] = Variable<String>(date);
    map['at'] = Variable<DateTime>(at);
    map['side'] = Variable<String>(side);
    map['units_e4'] = Variable<int>(unitsE4);
    map['price_e4'] = Variable<int>(priceE4);
    map['fees_paise'] = Variable<int>(feesPaise);
    map['reason'] = Variable<String>(reason);
    return map;
  }

  AgentTradesCompanion toCompanion(bool nullToAbsent) {
    return AgentTradesCompanion(
      id: Value(id),
      agent: Value(agent),
      instrumentId: Value(instrumentId),
      date: Value(date),
      at: Value(at),
      side: Value(side),
      unitsE4: Value(unitsE4),
      priceE4: Value(priceE4),
      feesPaise: Value(feesPaise),
      reason: Value(reason),
    );
  }

  factory AgentTrade.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentTrade(
      id: serializer.fromJson<int>(json['id']),
      agent: serializer.fromJson<String>(json['agent']),
      instrumentId: serializer.fromJson<int>(json['instrumentId']),
      date: serializer.fromJson<String>(json['date']),
      at: serializer.fromJson<DateTime>(json['at']),
      side: serializer.fromJson<String>(json['side']),
      unitsE4: serializer.fromJson<int>(json['unitsE4']),
      priceE4: serializer.fromJson<int>(json['priceE4']),
      feesPaise: serializer.fromJson<int>(json['feesPaise']),
      reason: serializer.fromJson<String>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'agent': serializer.toJson<String>(agent),
      'instrumentId': serializer.toJson<int>(instrumentId),
      'date': serializer.toJson<String>(date),
      'at': serializer.toJson<DateTime>(at),
      'side': serializer.toJson<String>(side),
      'unitsE4': serializer.toJson<int>(unitsE4),
      'priceE4': serializer.toJson<int>(priceE4),
      'feesPaise': serializer.toJson<int>(feesPaise),
      'reason': serializer.toJson<String>(reason),
    };
  }

  AgentTrade copyWith({
    int? id,
    String? agent,
    int? instrumentId,
    String? date,
    DateTime? at,
    String? side,
    int? unitsE4,
    int? priceE4,
    int? feesPaise,
    String? reason,
  }) => AgentTrade(
    id: id ?? this.id,
    agent: agent ?? this.agent,
    instrumentId: instrumentId ?? this.instrumentId,
    date: date ?? this.date,
    at: at ?? this.at,
    side: side ?? this.side,
    unitsE4: unitsE4 ?? this.unitsE4,
    priceE4: priceE4 ?? this.priceE4,
    feesPaise: feesPaise ?? this.feesPaise,
    reason: reason ?? this.reason,
  );
  AgentTrade copyWithCompanion(AgentTradesCompanion data) {
    return AgentTrade(
      id: data.id.present ? data.id.value : this.id,
      agent: data.agent.present ? data.agent.value : this.agent,
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      date: data.date.present ? data.date.value : this.date,
      at: data.at.present ? data.at.value : this.at,
      side: data.side.present ? data.side.value : this.side,
      unitsE4: data.unitsE4.present ? data.unitsE4.value : this.unitsE4,
      priceE4: data.priceE4.present ? data.priceE4.value : this.priceE4,
      feesPaise: data.feesPaise.present ? data.feesPaise.value : this.feesPaise,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentTrade(')
          ..write('id: $id, ')
          ..write('agent: $agent, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('date: $date, ')
          ..write('at: $at, ')
          ..write('side: $side, ')
          ..write('unitsE4: $unitsE4, ')
          ..write('priceE4: $priceE4, ')
          ..write('feesPaise: $feesPaise, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    agent,
    instrumentId,
    date,
    at,
    side,
    unitsE4,
    priceE4,
    feesPaise,
    reason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentTrade &&
          other.id == this.id &&
          other.agent == this.agent &&
          other.instrumentId == this.instrumentId &&
          other.date == this.date &&
          other.at == this.at &&
          other.side == this.side &&
          other.unitsE4 == this.unitsE4 &&
          other.priceE4 == this.priceE4 &&
          other.feesPaise == this.feesPaise &&
          other.reason == this.reason);
}

class AgentTradesCompanion extends UpdateCompanion<AgentTrade> {
  final Value<int> id;
  final Value<String> agent;
  final Value<int> instrumentId;
  final Value<String> date;
  final Value<DateTime> at;
  final Value<String> side;
  final Value<int> unitsE4;
  final Value<int> priceE4;
  final Value<int> feesPaise;
  final Value<String> reason;
  const AgentTradesCompanion({
    this.id = const Value.absent(),
    this.agent = const Value.absent(),
    this.instrumentId = const Value.absent(),
    this.date = const Value.absent(),
    this.at = const Value.absent(),
    this.side = const Value.absent(),
    this.unitsE4 = const Value.absent(),
    this.priceE4 = const Value.absent(),
    this.feesPaise = const Value.absent(),
    this.reason = const Value.absent(),
  });
  AgentTradesCompanion.insert({
    this.id = const Value.absent(),
    required String agent,
    required int instrumentId,
    required String date,
    required DateTime at,
    required String side,
    required int unitsE4,
    required int priceE4,
    this.feesPaise = const Value.absent(),
    this.reason = const Value.absent(),
  }) : agent = Value(agent),
       instrumentId = Value(instrumentId),
       date = Value(date),
       at = Value(at),
       side = Value(side),
       unitsE4 = Value(unitsE4),
       priceE4 = Value(priceE4);
  static Insertable<AgentTrade> custom({
    Expression<int>? id,
    Expression<String>? agent,
    Expression<int>? instrumentId,
    Expression<String>? date,
    Expression<DateTime>? at,
    Expression<String>? side,
    Expression<int>? unitsE4,
    Expression<int>? priceE4,
    Expression<int>? feesPaise,
    Expression<String>? reason,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (agent != null) 'agent': agent,
      if (instrumentId != null) 'instrument_id': instrumentId,
      if (date != null) 'date': date,
      if (at != null) 'at': at,
      if (side != null) 'side': side,
      if (unitsE4 != null) 'units_e4': unitsE4,
      if (priceE4 != null) 'price_e4': priceE4,
      if (feesPaise != null) 'fees_paise': feesPaise,
      if (reason != null) 'reason': reason,
    });
  }

  AgentTradesCompanion copyWith({
    Value<int>? id,
    Value<String>? agent,
    Value<int>? instrumentId,
    Value<String>? date,
    Value<DateTime>? at,
    Value<String>? side,
    Value<int>? unitsE4,
    Value<int>? priceE4,
    Value<int>? feesPaise,
    Value<String>? reason,
  }) {
    return AgentTradesCompanion(
      id: id ?? this.id,
      agent: agent ?? this.agent,
      instrumentId: instrumentId ?? this.instrumentId,
      date: date ?? this.date,
      at: at ?? this.at,
      side: side ?? this.side,
      unitsE4: unitsE4 ?? this.unitsE4,
      priceE4: priceE4 ?? this.priceE4,
      feesPaise: feesPaise ?? this.feesPaise,
      reason: reason ?? this.reason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (agent.present) {
      map['agent'] = Variable<String>(agent.value);
    }
    if (instrumentId.present) {
      map['instrument_id'] = Variable<int>(instrumentId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (side.present) {
      map['side'] = Variable<String>(side.value);
    }
    if (unitsE4.present) {
      map['units_e4'] = Variable<int>(unitsE4.value);
    }
    if (priceE4.present) {
      map['price_e4'] = Variable<int>(priceE4.value);
    }
    if (feesPaise.present) {
      map['fees_paise'] = Variable<int>(feesPaise.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentTradesCompanion(')
          ..write('id: $id, ')
          ..write('agent: $agent, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('date: $date, ')
          ..write('at: $at, ')
          ..write('side: $side, ')
          ..write('unitsE4: $unitsE4, ')
          ..write('priceE4: $priceE4, ')
          ..write('feesPaise: $feesPaise, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }
}

class $AgentRunsTable extends AgentRuns
    with TableInfo<$AgentRunsTable, AgentRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgentRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _agentMeta = const VerificationMeta('agent');
  @override
  late final GeneratedColumn<String> agent = GeneratedColumn<String>(
    'agent',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valuePaiseMeta = const VerificationMeta(
    'valuePaise',
  );
  @override
  late final GeneratedColumn<int> valuePaise = GeneratedColumn<int>(
    'value_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cashPaiseMeta = const VerificationMeta(
    'cashPaise',
  );
  @override
  late final GeneratedColumn<int> cashPaise = GeneratedColumn<int>(
    'cash_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aiMeta = const VerificationMeta('ai');
  @override
  late final GeneratedColumn<bool> ai = GeneratedColumn<bool>(
    'ai',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ai" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    agent,
    date,
    at,
    summary,
    valuePaise,
    cashPaise,
    ai,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgentRun> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('agent')) {
      context.handle(
        _agentMeta,
        agent.isAcceptableOrUnknown(data['agent']!, _agentMeta),
      );
    } else if (isInserting) {
      context.missing(_agentMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('value_paise')) {
      context.handle(
        _valuePaiseMeta,
        valuePaise.isAcceptableOrUnknown(data['value_paise']!, _valuePaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_valuePaiseMeta);
    }
    if (data.containsKey('cash_paise')) {
      context.handle(
        _cashPaiseMeta,
        cashPaise.isAcceptableOrUnknown(data['cash_paise']!, _cashPaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_cashPaiseMeta);
    }
    if (data.containsKey('ai')) {
      context.handle(_aiMeta, ai.isAcceptableOrUnknown(data['ai']!, _aiMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgentRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentRun(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      agent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      valuePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value_paise'],
      )!,
      cashPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cash_paise'],
      )!,
      ai: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ai'],
      )!,
    );
  }

  @override
  $AgentRunsTable createAlias(String alias) {
    return $AgentRunsTable(attachedDatabase, alias);
  }
}

class AgentRun extends DataClass implements Insertable<AgentRun> {
  final int id;
  final String agent;
  final String date;
  final DateTime at;
  final String summary;
  final int valuePaise;
  final int cashPaise;
  final bool ai;
  const AgentRun({
    required this.id,
    required this.agent,
    required this.date,
    required this.at,
    required this.summary,
    required this.valuePaise,
    required this.cashPaise,
    required this.ai,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['agent'] = Variable<String>(agent);
    map['date'] = Variable<String>(date);
    map['at'] = Variable<DateTime>(at);
    map['summary'] = Variable<String>(summary);
    map['value_paise'] = Variable<int>(valuePaise);
    map['cash_paise'] = Variable<int>(cashPaise);
    map['ai'] = Variable<bool>(ai);
    return map;
  }

  AgentRunsCompanion toCompanion(bool nullToAbsent) {
    return AgentRunsCompanion(
      id: Value(id),
      agent: Value(agent),
      date: Value(date),
      at: Value(at),
      summary: Value(summary),
      valuePaise: Value(valuePaise),
      cashPaise: Value(cashPaise),
      ai: Value(ai),
    );
  }

  factory AgentRun.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentRun(
      id: serializer.fromJson<int>(json['id']),
      agent: serializer.fromJson<String>(json['agent']),
      date: serializer.fromJson<String>(json['date']),
      at: serializer.fromJson<DateTime>(json['at']),
      summary: serializer.fromJson<String>(json['summary']),
      valuePaise: serializer.fromJson<int>(json['valuePaise']),
      cashPaise: serializer.fromJson<int>(json['cashPaise']),
      ai: serializer.fromJson<bool>(json['ai']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'agent': serializer.toJson<String>(agent),
      'date': serializer.toJson<String>(date),
      'at': serializer.toJson<DateTime>(at),
      'summary': serializer.toJson<String>(summary),
      'valuePaise': serializer.toJson<int>(valuePaise),
      'cashPaise': serializer.toJson<int>(cashPaise),
      'ai': serializer.toJson<bool>(ai),
    };
  }

  AgentRun copyWith({
    int? id,
    String? agent,
    String? date,
    DateTime? at,
    String? summary,
    int? valuePaise,
    int? cashPaise,
    bool? ai,
  }) => AgentRun(
    id: id ?? this.id,
    agent: agent ?? this.agent,
    date: date ?? this.date,
    at: at ?? this.at,
    summary: summary ?? this.summary,
    valuePaise: valuePaise ?? this.valuePaise,
    cashPaise: cashPaise ?? this.cashPaise,
    ai: ai ?? this.ai,
  );
  AgentRun copyWithCompanion(AgentRunsCompanion data) {
    return AgentRun(
      id: data.id.present ? data.id.value : this.id,
      agent: data.agent.present ? data.agent.value : this.agent,
      date: data.date.present ? data.date.value : this.date,
      at: data.at.present ? data.at.value : this.at,
      summary: data.summary.present ? data.summary.value : this.summary,
      valuePaise: data.valuePaise.present
          ? data.valuePaise.value
          : this.valuePaise,
      cashPaise: data.cashPaise.present ? data.cashPaise.value : this.cashPaise,
      ai: data.ai.present ? data.ai.value : this.ai,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentRun(')
          ..write('id: $id, ')
          ..write('agent: $agent, ')
          ..write('date: $date, ')
          ..write('at: $at, ')
          ..write('summary: $summary, ')
          ..write('valuePaise: $valuePaise, ')
          ..write('cashPaise: $cashPaise, ')
          ..write('ai: $ai')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, agent, date, at, summary, valuePaise, cashPaise, ai);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentRun &&
          other.id == this.id &&
          other.agent == this.agent &&
          other.date == this.date &&
          other.at == this.at &&
          other.summary == this.summary &&
          other.valuePaise == this.valuePaise &&
          other.cashPaise == this.cashPaise &&
          other.ai == this.ai);
}

class AgentRunsCompanion extends UpdateCompanion<AgentRun> {
  final Value<int> id;
  final Value<String> agent;
  final Value<String> date;
  final Value<DateTime> at;
  final Value<String> summary;
  final Value<int> valuePaise;
  final Value<int> cashPaise;
  final Value<bool> ai;
  const AgentRunsCompanion({
    this.id = const Value.absent(),
    this.agent = const Value.absent(),
    this.date = const Value.absent(),
    this.at = const Value.absent(),
    this.summary = const Value.absent(),
    this.valuePaise = const Value.absent(),
    this.cashPaise = const Value.absent(),
    this.ai = const Value.absent(),
  });
  AgentRunsCompanion.insert({
    this.id = const Value.absent(),
    required String agent,
    required String date,
    required DateTime at,
    required String summary,
    required int valuePaise,
    required int cashPaise,
    this.ai = const Value.absent(),
  }) : agent = Value(agent),
       date = Value(date),
       at = Value(at),
       summary = Value(summary),
       valuePaise = Value(valuePaise),
       cashPaise = Value(cashPaise);
  static Insertable<AgentRun> custom({
    Expression<int>? id,
    Expression<String>? agent,
    Expression<String>? date,
    Expression<DateTime>? at,
    Expression<String>? summary,
    Expression<int>? valuePaise,
    Expression<int>? cashPaise,
    Expression<bool>? ai,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (agent != null) 'agent': agent,
      if (date != null) 'date': date,
      if (at != null) 'at': at,
      if (summary != null) 'summary': summary,
      if (valuePaise != null) 'value_paise': valuePaise,
      if (cashPaise != null) 'cash_paise': cashPaise,
      if (ai != null) 'ai': ai,
    });
  }

  AgentRunsCompanion copyWith({
    Value<int>? id,
    Value<String>? agent,
    Value<String>? date,
    Value<DateTime>? at,
    Value<String>? summary,
    Value<int>? valuePaise,
    Value<int>? cashPaise,
    Value<bool>? ai,
  }) {
    return AgentRunsCompanion(
      id: id ?? this.id,
      agent: agent ?? this.agent,
      date: date ?? this.date,
      at: at ?? this.at,
      summary: summary ?? this.summary,
      valuePaise: valuePaise ?? this.valuePaise,
      cashPaise: cashPaise ?? this.cashPaise,
      ai: ai ?? this.ai,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (agent.present) {
      map['agent'] = Variable<String>(agent.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (valuePaise.present) {
      map['value_paise'] = Variable<int>(valuePaise.value);
    }
    if (cashPaise.present) {
      map['cash_paise'] = Variable<int>(cashPaise.value);
    }
    if (ai.present) {
      map['ai'] = Variable<bool>(ai.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentRunsCompanion(')
          ..write('id: $id, ')
          ..write('agent: $agent, ')
          ..write('date: $date, ')
          ..write('at: $at, ')
          ..write('summary: $summary, ')
          ..write('valuePaise: $valuePaise, ')
          ..write('cashPaise: $cashPaise, ')
          ..write('ai: $ai')
          ..write(')'))
        .toString();
  }
}

class $AgentNotesTable extends AgentNotes
    with TableInfo<$AgentNotesTable, AgentNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AgentNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agentMeta = const VerificationMeta('agent');
  @override
  late final GeneratedColumn<String> agent = GeneratedColumn<String>(
    'agent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, at, body, agent];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgentNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('agent')) {
      context.handle(
        _agentMeta,
        agent.isAcceptableOrUnknown(data['agent']!, _agentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgentNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      agent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent'],
      ),
    );
  }

  @override
  $AgentNotesTable createAlias(String alias) {
    return $AgentNotesTable(attachedDatabase, alias);
  }
}

class AgentNote extends DataClass implements Insertable<AgentNote> {
  final int id;
  final DateTime at;
  final String body;
  final String? agent;
  const AgentNote({
    required this.id,
    required this.at,
    required this.body,
    this.agent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || agent != null) {
      map['agent'] = Variable<String>(agent);
    }
    return map;
  }

  AgentNotesCompanion toCompanion(bool nullToAbsent) {
    return AgentNotesCompanion(
      id: Value(id),
      at: Value(at),
      body: Value(body),
      agent: agent == null && nullToAbsent
          ? const Value.absent()
          : Value(agent),
    );
  }

  factory AgentNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentNote(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      body: serializer.fromJson<String>(json['body']),
      agent: serializer.fromJson<String?>(json['agent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'body': serializer.toJson<String>(body),
      'agent': serializer.toJson<String?>(agent),
    };
  }

  AgentNote copyWith({
    int? id,
    DateTime? at,
    String? body,
    Value<String?> agent = const Value.absent(),
  }) => AgentNote(
    id: id ?? this.id,
    at: at ?? this.at,
    body: body ?? this.body,
    agent: agent.present ? agent.value : this.agent,
  );
  AgentNote copyWithCompanion(AgentNotesCompanion data) {
    return AgentNote(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      body: data.body.present ? data.body.value : this.body,
      agent: data.agent.present ? data.agent.value : this.agent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentNote(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('body: $body, ')
          ..write('agent: $agent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, at, body, agent);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentNote &&
          other.id == this.id &&
          other.at == this.at &&
          other.body == this.body &&
          other.agent == this.agent);
}

class AgentNotesCompanion extends UpdateCompanion<AgentNote> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<String> body;
  final Value<String?> agent;
  const AgentNotesCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.body = const Value.absent(),
    this.agent = const Value.absent(),
  });
  AgentNotesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required String body,
    this.agent = const Value.absent(),
  }) : at = Value(at),
       body = Value(body);
  static Insertable<AgentNote> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<String>? body,
    Expression<String>? agent,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (body != null) 'body': body,
      if (agent != null) 'agent': agent,
    });
  }

  AgentNotesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<String>? body,
    Value<String?>? agent,
  }) {
    return AgentNotesCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      body: body ?? this.body,
      agent: agent ?? this.agent,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (agent.present) {
      map['agent'] = Variable<String>(agent.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentNotesCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('body: $body, ')
          ..write('agent: $agent')
          ..write(')'))
        .toString();
  }
}

abstract class _$MarketDb extends GeneratedDatabase {
  _$MarketDb(QueryExecutor e) : super(e);
  $MarketDbManager get managers => $MarketDbManager(this);
  late final $InstrumentsTable instruments = $InstrumentsTable(this);
  late final $PricesTable prices = $PricesTable(this);
  late final $NewsItemsTable newsItems = $NewsItemsTable(this);
  late final $FilingsTable filings = $FilingsTable(this);
  late final $FetchLogTable fetchLog = $FetchLogTable(this);
  late final $HolidaysTable holidays = $HolidaysTable(this);
  late final $UniverseTable universe = $UniverseTable(this);
  late final $FundamentalsTable fundamentals = $FundamentalsTable(this);
  late final $AgentTradesTable agentTrades = $AgentTradesTable(this);
  late final $AgentRunsTable agentRuns = $AgentRunsTable(this);
  late final $AgentNotesTable agentNotes = $AgentNotesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    instruments,
    prices,
    newsItems,
    filings,
    fetchLog,
    holidays,
    universe,
    fundamentals,
    agentTrades,
    agentRuns,
    agentNotes,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$InstrumentsTableCreateCompanionBuilder =
    InstrumentsCompanion Function({
      Value<int> id,
      required String kind,
      Value<String?> yahooTicker,
      Value<String?> nseSymbol,
      Value<String?> schemeCode,
      required String name,
      Value<String> aliases,
    });
typedef $$InstrumentsTableUpdateCompanionBuilder =
    InstrumentsCompanion Function({
      Value<int> id,
      Value<String> kind,
      Value<String?> yahooTicker,
      Value<String?> nseSymbol,
      Value<String?> schemeCode,
      Value<String> name,
      Value<String> aliases,
    });

class $$InstrumentsTableFilterComposer
    extends Composer<_$MarketDb, $InstrumentsTable> {
  $$InstrumentsTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get yahooTicker => $composableBuilder(
    column: $table.yahooTicker,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nseSymbol => $composableBuilder(
    column: $table.nseSymbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schemeCode => $composableBuilder(
    column: $table.schemeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aliases => $composableBuilder(
    column: $table.aliases,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InstrumentsTableOrderingComposer
    extends Composer<_$MarketDb, $InstrumentsTable> {
  $$InstrumentsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get yahooTicker => $composableBuilder(
    column: $table.yahooTicker,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nseSymbol => $composableBuilder(
    column: $table.nseSymbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schemeCode => $composableBuilder(
    column: $table.schemeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aliases => $composableBuilder(
    column: $table.aliases,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InstrumentsTableAnnotationComposer
    extends Composer<_$MarketDb, $InstrumentsTable> {
  $$InstrumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get yahooTicker => $composableBuilder(
    column: $table.yahooTicker,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nseSymbol =>
      $composableBuilder(column: $table.nseSymbol, builder: (column) => column);

  GeneratedColumn<String> get schemeCode => $composableBuilder(
    column: $table.schemeCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get aliases =>
      $composableBuilder(column: $table.aliases, builder: (column) => column);
}

class $$InstrumentsTableTableManager
    extends
        RootTableManager<
          _$MarketDb,
          $InstrumentsTable,
          Instrument,
          $$InstrumentsTableFilterComposer,
          $$InstrumentsTableOrderingComposer,
          $$InstrumentsTableAnnotationComposer,
          $$InstrumentsTableCreateCompanionBuilder,
          $$InstrumentsTableUpdateCompanionBuilder,
          (
            Instrument,
            BaseReferences<_$MarketDb, $InstrumentsTable, Instrument>,
          ),
          Instrument,
          PrefetchHooks Function()
        > {
  $$InstrumentsTableTableManager(_$MarketDb db, $InstrumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstrumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstrumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstrumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> yahooTicker = const Value.absent(),
                Value<String?> nseSymbol = const Value.absent(),
                Value<String?> schemeCode = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> aliases = const Value.absent(),
              }) => InstrumentsCompanion(
                id: id,
                kind: kind,
                yahooTicker: yahooTicker,
                nseSymbol: nseSymbol,
                schemeCode: schemeCode,
                name: name,
                aliases: aliases,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                Value<String?> yahooTicker = const Value.absent(),
                Value<String?> nseSymbol = const Value.absent(),
                Value<String?> schemeCode = const Value.absent(),
                required String name,
                Value<String> aliases = const Value.absent(),
              }) => InstrumentsCompanion.insert(
                id: id,
                kind: kind,
                yahooTicker: yahooTicker,
                nseSymbol: nseSymbol,
                schemeCode: schemeCode,
                name: name,
                aliases: aliases,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InstrumentsTable, Instrument>(table),
                  BaseReferences<_$MarketDb, $InstrumentsTable, Instrument>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InstrumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDb,
      $InstrumentsTable,
      Instrument,
      $$InstrumentsTableFilterComposer,
      $$InstrumentsTableOrderingComposer,
      $$InstrumentsTableAnnotationComposer,
      $$InstrumentsTableCreateCompanionBuilder,
      $$InstrumentsTableUpdateCompanionBuilder,
      (Instrument, BaseReferences<_$MarketDb, $InstrumentsTable, Instrument>),
      Instrument,
      PrefetchHooks Function()
    >;
typedef $$PricesTableCreateCompanionBuilder = PricesCompanion Function({
  required int instrumentId,
  required String date,
  required int closeE4,
  required String source,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$PricesTableUpdateCompanionBuilder = PricesCompanion Function({
  Value<int> instrumentId,
  Value<String> date,
  Value<int> closeE4,
  Value<String> source,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

class $$PricesTableFilterComposer extends Composer<_$MarketDb, $PricesTable> {
  $$PricesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get closeE4 => $composableBuilder(
    column: $table.closeE4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PricesTableOrderingComposer extends Composer<_$MarketDb, $PricesTable> {
  $$PricesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get closeE4 => $composableBuilder(
    column: $table.closeE4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PricesTableAnnotationComposer
    extends Composer<_$MarketDb, $PricesTable> {
  $$PricesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get closeE4 =>
      $composableBuilder(column: $table.closeE4, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$PricesTableTableManager
    extends
        RootTableManager<
          _$MarketDb,
          $PricesTable,
          Price,
          $$PricesTableFilterComposer,
          $$PricesTableOrderingComposer,
          $$PricesTableAnnotationComposer,
          $$PricesTableCreateCompanionBuilder,
          $$PricesTableUpdateCompanionBuilder,
          (Price, BaseReferences<_$MarketDb, $PricesTable, Price>),
          Price,
          PrefetchHooks Function()
        > {
  $$PricesTableTableManager(_$MarketDb db, $PricesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PricesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PricesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PricesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> instrumentId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> closeE4 = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PricesCompanion(
                instrumentId: instrumentId,
                date: date,
                closeE4: closeE4,
                source: source,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int instrumentId,
                required String date,
                required int closeE4,
                required String source,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => PricesCompanion.insert(
                instrumentId: instrumentId,
                date: date,
                closeE4: closeE4,
                source: source,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PricesTable, Price>(table),
                  BaseReferences<_$MarketDb, $PricesTable, Price>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PricesTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDb,
      $PricesTable,
      Price,
      $$PricesTableFilterComposer,
      $$PricesTableOrderingComposer,
      $$PricesTableAnnotationComposer,
      $$PricesTableCreateCompanionBuilder,
      $$PricesTableUpdateCompanionBuilder,
      (Price, BaseReferences<_$MarketDb, $PricesTable, Price>),
      Price,
      PrefetchHooks Function()
    >;
typedef $$NewsItemsTableCreateCompanionBuilder = NewsItemsCompanion Function({
  required String urlHash,
  required String url,
  required String title,
  required String publisher,
  required DateTime publishedAt,
  Value<int?> instrumentId,
  Value<String?> label,
  Value<double?> confidence,
  Value<String?> reason,
  Value<int> rowid,
});
typedef $$NewsItemsTableUpdateCompanionBuilder = NewsItemsCompanion Function({
  Value<String> urlHash,
  Value<String> url,
  Value<String> title,
  Value<String> publisher,
  Value<DateTime> publishedAt,
  Value<int?> instrumentId,
  Value<String?> label,
  Value<double?> confidence,
  Value<String?> reason,
  Value<int> rowid,
});

class $$NewsItemsTableFilterComposer
    extends Composer<_$MarketDb, $NewsItemsTable> {
  $$NewsItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get urlHash => $composableBuilder(
    column: $table.urlHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NewsItemsTableOrderingComposer
    extends Composer<_$MarketDb, $NewsItemsTable> {
  $$NewsItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get urlHash => $composableBuilder(
    column: $table.urlHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NewsItemsTableAnnotationComposer
    extends Composer<_$MarketDb, $NewsItemsTable> {
  $$NewsItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get urlHash =>
      $composableBuilder(column: $table.urlHash, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get publisher =>
      $composableBuilder(column: $table.publisher, builder: (column) => column);

  GeneratedColumn<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);
}

class $$NewsItemsTableTableManager
    extends
        RootTableManager<
          _$MarketDb,
          $NewsItemsTable,
          NewsItem,
          $$NewsItemsTableFilterComposer,
          $$NewsItemsTableOrderingComposer,
          $$NewsItemsTableAnnotationComposer,
          $$NewsItemsTableCreateCompanionBuilder,
          $$NewsItemsTableUpdateCompanionBuilder,
          (NewsItem, BaseReferences<_$MarketDb, $NewsItemsTable, NewsItem>),
          NewsItem,
          PrefetchHooks Function()
        > {
  $$NewsItemsTableTableManager(_$MarketDb db, $NewsItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NewsItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NewsItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NewsItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> urlHash = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> publisher = const Value.absent(),
                Value<DateTime> publishedAt = const Value.absent(),
                Value<int?> instrumentId = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NewsItemsCompanion(
                urlHash: urlHash,
                url: url,
                title: title,
                publisher: publisher,
                publishedAt: publishedAt,
                instrumentId: instrumentId,
                label: label,
                confidence: confidence,
                reason: reason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String urlHash,
                required String url,
                required String title,
                required String publisher,
                required DateTime publishedAt,
                Value<int?> instrumentId = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NewsItemsCompanion.insert(
                urlHash: urlHash,
                url: url,
                title: title,
                publisher: publisher,
                publishedAt: publishedAt,
                instrumentId: instrumentId,
                label: label,
                confidence: confidence,
                reason: reason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NewsItemsTable, NewsItem>(table),
                  BaseReferences<_$MarketDb, $NewsItemsTable, NewsItem>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NewsItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDb,
      $NewsItemsTable,
      NewsItem,
      $$NewsItemsTableFilterComposer,
      $$NewsItemsTableOrderingComposer,
      $$NewsItemsTableAnnotationComposer,
      $$NewsItemsTableCreateCompanionBuilder,
      $$NewsItemsTableUpdateCompanionBuilder,
      (NewsItem, BaseReferences<_$MarketDb, $NewsItemsTable, NewsItem>),
      NewsItem,
      PrefetchHooks Function()
    >;
typedef $$FilingsTableCreateCompanionBuilder = FilingsCompanion Function({
  Value<int> id,
  required int instrumentId,
  required String date,
  required String category,
  required String subject,
  required String url,
});
typedef $$FilingsTableUpdateCompanionBuilder = FilingsCompanion Function({
  Value<int> id,
  Value<int> instrumentId,
  Value<String> date,
  Value<String> category,
  Value<String> subject,
  Value<String> url,
});

class $$FilingsTableFilterComposer extends Composer<_$MarketDb, $FilingsTable> {
  $$FilingsTableFilterComposer({
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

  ColumnFilters<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FilingsTableOrderingComposer
    extends Composer<_$MarketDb, $FilingsTable> {
  $$FilingsTableOrderingComposer({
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

  ColumnOrderings<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FilingsTableAnnotationComposer
    extends Composer<_$MarketDb, $FilingsTable> {
  $$FilingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);
}

class $$FilingsTableTableManager
    extends
        RootTableManager<
          _$MarketDb,
          $FilingsTable,
          Filing,
          $$FilingsTableFilterComposer,
          $$FilingsTableOrderingComposer,
          $$FilingsTableAnnotationComposer,
          $$FilingsTableCreateCompanionBuilder,
          $$FilingsTableUpdateCompanionBuilder,
          (Filing, BaseReferences<_$MarketDb, $FilingsTable, Filing>),
          Filing,
          PrefetchHooks Function()
        > {
  $$FilingsTableTableManager(_$MarketDb db, $FilingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> instrumentId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> url = const Value.absent(),
              }) => FilingsCompanion(
                id: id,
                instrumentId: instrumentId,
                date: date,
                category: category,
                subject: subject,
                url: url,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int instrumentId,
                required String date,
                required String category,
                required String subject,
                required String url,
              }) => FilingsCompanion.insert(
                id: id,
                instrumentId: instrumentId,
                date: date,
                category: category,
                subject: subject,
                url: url,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FilingsTable, Filing>(table),
                  BaseReferences<_$MarketDb, $FilingsTable, Filing>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FilingsTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDb,
      $FilingsTable,
      Filing,
      $$FilingsTableFilterComposer,
      $$FilingsTableOrderingComposer,
      $$FilingsTableAnnotationComposer,
      $$FilingsTableCreateCompanionBuilder,
      $$FilingsTableUpdateCompanionBuilder,
      (Filing, BaseReferences<_$MarketDb, $FilingsTable, Filing>),
      Filing,
      PrefetchHooks Function()
    >;
typedef $$FetchLogTableCreateCompanionBuilder = FetchLogCompanion Function({
  required String source,
  Value<DateTime?> lastOkAt,
  Value<DateTime?> lastAttemptAt,
  Value<String?> lastError,
  Value<int> rows,
  Value<int> rowid,
});
typedef $$FetchLogTableUpdateCompanionBuilder = FetchLogCompanion Function({
  Value<String> source,
  Value<DateTime?> lastOkAt,
  Value<DateTime?> lastAttemptAt,
  Value<String?> lastError,
  Value<int> rows,
  Value<int> rowid,
});

class $$FetchLogTableFilterComposer
    extends Composer<_$MarketDb, $FetchLogTable> {
  $$FetchLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOkAt => $composableBuilder(
    column: $table.lastOkAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rows => $composableBuilder(
    column: $table.rows,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FetchLogTableOrderingComposer
    extends Composer<_$MarketDb, $FetchLogTable> {
  $$FetchLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOkAt => $composableBuilder(
    column: $table.lastOkAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rows => $composableBuilder(
    column: $table.rows,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FetchLogTableAnnotationComposer
    extends Composer<_$MarketDb, $FetchLogTable> {
  $$FetchLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOkAt =>
      $composableBuilder(column: $table.lastOkAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get rows =>
      $composableBuilder(column: $table.rows, builder: (column) => column);
}

class $$FetchLogTableTableManager
    extends
        RootTableManager<
          _$MarketDb,
          $FetchLogTable,
          FetchLogData,
          $$FetchLogTableFilterComposer,
          $$FetchLogTableOrderingComposer,
          $$FetchLogTableAnnotationComposer,
          $$FetchLogTableCreateCompanionBuilder,
          $$FetchLogTableUpdateCompanionBuilder,
          (
            FetchLogData,
            BaseReferences<_$MarketDb, $FetchLogTable, FetchLogData>,
          ),
          FetchLogData,
          PrefetchHooks Function()
        > {
  $$FetchLogTableTableManager(_$MarketDb db, $FetchLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FetchLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FetchLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FetchLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> source = const Value.absent(),
                Value<DateTime?> lastOkAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rows = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FetchLogCompanion(
                source: source,
                lastOkAt: lastOkAt,
                lastAttemptAt: lastAttemptAt,
                lastError: lastError,
                rows: rows,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String source,
                Value<DateTime?> lastOkAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rows = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FetchLogCompanion.insert(
                source: source,
                lastOkAt: lastOkAt,
                lastAttemptAt: lastAttemptAt,
                lastError: lastError,
                rows: rows,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FetchLogTable, FetchLogData>(table),
                  BaseReferences<_$MarketDb, $FetchLogTable, FetchLogData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FetchLogTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDb,
      $FetchLogTable,
      FetchLogData,
      $$FetchLogTableFilterComposer,
      $$FetchLogTableOrderingComposer,
      $$FetchLogTableAnnotationComposer,
      $$FetchLogTableCreateCompanionBuilder,
      $$FetchLogTableUpdateCompanionBuilder,
      (FetchLogData, BaseReferences<_$MarketDb, $FetchLogTable, FetchLogData>),
      FetchLogData,
      PrefetchHooks Function()
    >;
typedef $$HolidaysTableCreateCompanionBuilder = HolidaysCompanion Function({
  required String date,
  required String name,
  Value<int> rowid,
});
typedef $$HolidaysTableUpdateCompanionBuilder = HolidaysCompanion Function({
  Value<String> date,
  Value<String> name,
  Value<int> rowid,
});

class $$HolidaysTableFilterComposer
    extends Composer<_$MarketDb, $HolidaysTable> {
  $$HolidaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HolidaysTableOrderingComposer
    extends Composer<_$MarketDb, $HolidaysTable> {
  $$HolidaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HolidaysTableAnnotationComposer
    extends Composer<_$MarketDb, $HolidaysTable> {
  $$HolidaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$HolidaysTableTableManager
    extends
        RootTableManager<
          _$MarketDb,
          $HolidaysTable,
          Holiday,
          $$HolidaysTableFilterComposer,
          $$HolidaysTableOrderingComposer,
          $$HolidaysTableAnnotationComposer,
          $$HolidaysTableCreateCompanionBuilder,
          $$HolidaysTableUpdateCompanionBuilder,
          (Holiday, BaseReferences<_$MarketDb, $HolidaysTable, Holiday>),
          Holiday,
          PrefetchHooks Function()
        > {
  $$HolidaysTableTableManager(_$MarketDb db, $HolidaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HolidaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HolidaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HolidaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> date = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => HolidaysCompanion(date: date, name: name, rowid: rowid),
          createCompanionCallback: ({
            required String date,
            required String name,
            Value<int> rowid = const Value.absent(),
          }) => HolidaysCompanion.insert(date: date, name: name, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HolidaysTable, Holiday>(table),
                  BaseReferences<_$MarketDb, $HolidaysTable, Holiday>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HolidaysTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDb,
      $HolidaysTable,
      Holiday,
      $$HolidaysTableFilterComposer,
      $$HolidaysTableOrderingComposer,
      $$HolidaysTableAnnotationComposer,
      $$HolidaysTableCreateCompanionBuilder,
      $$HolidaysTableUpdateCompanionBuilder,
      (Holiday, BaseReferences<_$MarketDb, $HolidaysTable, Holiday>),
      Holiday,
      PrefetchHooks Function()
    >;
typedef $$UniverseTableCreateCompanionBuilder = UniverseCompanion Function({
  required String symbol,
  required String name,
  Value<String> industry,
  Value<String> isin,
  Value<bool> nifty500,
  Value<int> rowid,
});
typedef $$UniverseTableUpdateCompanionBuilder = UniverseCompanion Function({
  Value<String> symbol,
  Value<String> name,
  Value<String> industry,
  Value<String> isin,
  Value<bool> nifty500,
  Value<int> rowid,
});

class $$UniverseTableFilterComposer
    extends Composer<_$MarketDb, $UniverseTable> {
  $$UniverseTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get industry => $composableBuilder(
    column: $table.industry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isin => $composableBuilder(
    column: $table.isin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get nifty500 => $composableBuilder(
    column: $table.nifty500,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UniverseTableOrderingComposer
    extends Composer<_$MarketDb, $UniverseTable> {
  $$UniverseTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get industry => $composableBuilder(
    column: $table.industry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isin => $composableBuilder(
    column: $table.isin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get nifty500 => $composableBuilder(
    column: $table.nifty500,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UniverseTableAnnotationComposer
    extends Composer<_$MarketDb, $UniverseTable> {
  $$UniverseTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get industry =>
      $composableBuilder(column: $table.industry, builder: (column) => column);

  GeneratedColumn<String> get isin =>
      $composableBuilder(column: $table.isin, builder: (column) => column);

  GeneratedColumn<bool> get nifty500 =>
      $composableBuilder(column: $table.nifty500, builder: (column) => column);
}

class $$UniverseTableTableManager
    extends
        RootTableManager<
          _$MarketDb,
          $UniverseTable,
          Listing,
          $$UniverseTableFilterComposer,
          $$UniverseTableOrderingComposer,
          $$UniverseTableAnnotationComposer,
          $$UniverseTableCreateCompanionBuilder,
          $$UniverseTableUpdateCompanionBuilder,
          (Listing, BaseReferences<_$MarketDb, $UniverseTable, Listing>),
          Listing,
          PrefetchHooks Function()
        > {
  $$UniverseTableTableManager(_$MarketDb db, $UniverseTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UniverseTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UniverseTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UniverseTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> symbol = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> industry = const Value.absent(),
                Value<String> isin = const Value.absent(),
                Value<bool> nifty500 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UniverseCompanion(
                symbol: symbol,
                name: name,
                industry: industry,
                isin: isin,
                nifty500: nifty500,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String symbol,
                required String name,
                Value<String> industry = const Value.absent(),
                Value<String> isin = const Value.absent(),
                Value<bool> nifty500 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UniverseCompanion.insert(
                symbol: symbol,
                name: name,
                industry: industry,
                isin: isin,
                nifty500: nifty500,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UniverseTable, Listing>(table),
                  BaseReferences<_$MarketDb, $UniverseTable, Listing>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UniverseTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDb,
      $UniverseTable,
      Listing,
      $$UniverseTableFilterComposer,
      $$UniverseTableOrderingComposer,
      $$UniverseTableAnnotationComposer,
      $$UniverseTableCreateCompanionBuilder,
      $$UniverseTableUpdateCompanionBuilder,
      (Listing, BaseReferences<_$MarketDb, $UniverseTable, Listing>),
      Listing,
      PrefetchHooks Function()
    >;
typedef $$FundamentalsTableCreateCompanionBuilder =
    FundamentalsCompanion Function({
      required String symbol,
      required String json,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$FundamentalsTableUpdateCompanionBuilder =
    FundamentalsCompanion Function({
      Value<String> symbol,
      Value<String> json,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$FundamentalsTableFilterComposer
    extends Composer<_$MarketDb, $FundamentalsTable> {
  $$FundamentalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FundamentalsTableOrderingComposer
    extends Composer<_$MarketDb, $FundamentalsTable> {
  $$FundamentalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FundamentalsTableAnnotationComposer
    extends Composer<_$MarketDb, $FundamentalsTable> {
  $$FundamentalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$FundamentalsTableTableManager
    extends
        RootTableManager<
          _$MarketDb,
          $FundamentalsTable,
          Fundamental,
          $$FundamentalsTableFilterComposer,
          $$FundamentalsTableOrderingComposer,
          $$FundamentalsTableAnnotationComposer,
          $$FundamentalsTableCreateCompanionBuilder,
          $$FundamentalsTableUpdateCompanionBuilder,
          (
            Fundamental,
            BaseReferences<_$MarketDb, $FundamentalsTable, Fundamental>,
          ),
          Fundamental,
          PrefetchHooks Function()
        > {
  $$FundamentalsTableTableManager(_$MarketDb db, $FundamentalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FundamentalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FundamentalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FundamentalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> symbol = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FundamentalsCompanion(
                symbol: symbol,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String symbol,
                required String json,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => FundamentalsCompanion.insert(
                symbol: symbol,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FundamentalsTable, Fundamental>(table),
                  BaseReferences<_$MarketDb, $FundamentalsTable, Fundamental>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FundamentalsTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDb,
      $FundamentalsTable,
      Fundamental,
      $$FundamentalsTableFilterComposer,
      $$FundamentalsTableOrderingComposer,
      $$FundamentalsTableAnnotationComposer,
      $$FundamentalsTableCreateCompanionBuilder,
      $$FundamentalsTableUpdateCompanionBuilder,
      (
        Fundamental,
        BaseReferences<_$MarketDb, $FundamentalsTable, Fundamental>,
      ),
      Fundamental,
      PrefetchHooks Function()
    >;
typedef $$AgentTradesTableCreateCompanionBuilder =
    AgentTradesCompanion Function({
      Value<int> id,
      required String agent,
      required int instrumentId,
      required String date,
      required DateTime at,
      required String side,
      required int unitsE4,
      required int priceE4,
      Value<int> feesPaise,
      Value<String> reason,
    });
typedef $$AgentTradesTableUpdateCompanionBuilder =
    AgentTradesCompanion Function({
      Value<int> id,
      Value<String> agent,
      Value<int> instrumentId,
      Value<String> date,
      Value<DateTime> at,
      Value<String> side,
      Value<int> unitsE4,
      Value<int> priceE4,
      Value<int> feesPaise,
      Value<String> reason,
    });

class $$AgentTradesTableFilterComposer
    extends Composer<_$MarketDb, $AgentTradesTable> {
  $$AgentTradesTableFilterComposer({
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

  ColumnFilters<String> get agent => $composableBuilder(
    column: $table.agent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get side => $composableBuilder(
    column: $table.side,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitsE4 => $composableBuilder(
    column: $table.unitsE4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceE4 => $composableBuilder(
    column: $table.priceE4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get feesPaise => $composableBuilder(
    column: $table.feesPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AgentTradesTableOrderingComposer
    extends Composer<_$MarketDb, $AgentTradesTable> {
  $$AgentTradesTableOrderingComposer({
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

  ColumnOrderings<String> get agent => $composableBuilder(
    column: $table.agent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get side => $composableBuilder(
    column: $table.side,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitsE4 => $composableBuilder(
    column: $table.unitsE4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceE4 => $composableBuilder(
    column: $table.priceE4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get feesPaise => $composableBuilder(
    column: $table.feesPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AgentTradesTableAnnotationComposer
    extends Composer<_$MarketDb, $AgentTradesTable> {
  $$AgentTradesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get agent =>
      $composableBuilder(column: $table.agent, builder: (column) => column);

  GeneratedColumn<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get side =>
      $composableBuilder(column: $table.side, builder: (column) => column);

  GeneratedColumn<int> get unitsE4 =>
      $composableBuilder(column: $table.unitsE4, builder: (column) => column);

  GeneratedColumn<int> get priceE4 =>
      $composableBuilder(column: $table.priceE4, builder: (column) => column);

  GeneratedColumn<int> get feesPaise =>
      $composableBuilder(column: $table.feesPaise, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);
}

class $$AgentTradesTableTableManager
    extends
        RootTableManager<
          _$MarketDb,
          $AgentTradesTable,
          AgentTrade,
          $$AgentTradesTableFilterComposer,
          $$AgentTradesTableOrderingComposer,
          $$AgentTradesTableAnnotationComposer,
          $$AgentTradesTableCreateCompanionBuilder,
          $$AgentTradesTableUpdateCompanionBuilder,
          (
            AgentTrade,
            BaseReferences<_$MarketDb, $AgentTradesTable, AgentTrade>,
          ),
          AgentTrade,
          PrefetchHooks Function()
        > {
  $$AgentTradesTableTableManager(_$MarketDb db, $AgentTradesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgentTradesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgentTradesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgentTradesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> agent = const Value.absent(),
                Value<int> instrumentId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String> side = const Value.absent(),
                Value<int> unitsE4 = const Value.absent(),
                Value<int> priceE4 = const Value.absent(),
                Value<int> feesPaise = const Value.absent(),
                Value<String> reason = const Value.absent(),
              }) => AgentTradesCompanion(
                id: id,
                agent: agent,
                instrumentId: instrumentId,
                date: date,
                at: at,
                side: side,
                unitsE4: unitsE4,
                priceE4: priceE4,
                feesPaise: feesPaise,
                reason: reason,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String agent,
                required int instrumentId,
                required String date,
                required DateTime at,
                required String side,
                required int unitsE4,
                required int priceE4,
                Value<int> feesPaise = const Value.absent(),
                Value<String> reason = const Value.absent(),
              }) => AgentTradesCompanion.insert(
                id: id,
                agent: agent,
                instrumentId: instrumentId,
                date: date,
                at: at,
                side: side,
                unitsE4: unitsE4,
                priceE4: priceE4,
                feesPaise: feesPaise,
                reason: reason,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AgentTradesTable, AgentTrade>(table),
                  BaseReferences<_$MarketDb, $AgentTradesTable, AgentTrade>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AgentTradesTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDb,
      $AgentTradesTable,
      AgentTrade,
      $$AgentTradesTableFilterComposer,
      $$AgentTradesTableOrderingComposer,
      $$AgentTradesTableAnnotationComposer,
      $$AgentTradesTableCreateCompanionBuilder,
      $$AgentTradesTableUpdateCompanionBuilder,
      (AgentTrade, BaseReferences<_$MarketDb, $AgentTradesTable, AgentTrade>),
      AgentTrade,
      PrefetchHooks Function()
    >;
typedef $$AgentRunsTableCreateCompanionBuilder = AgentRunsCompanion Function({
  Value<int> id,
  required String agent,
  required String date,
  required DateTime at,
  required String summary,
  required int valuePaise,
  required int cashPaise,
  Value<bool> ai,
});
typedef $$AgentRunsTableUpdateCompanionBuilder = AgentRunsCompanion Function({
  Value<int> id,
  Value<String> agent,
  Value<String> date,
  Value<DateTime> at,
  Value<String> summary,
  Value<int> valuePaise,
  Value<int> cashPaise,
  Value<bool> ai,
});

class $$AgentRunsTableFilterComposer
    extends Composer<_$MarketDb, $AgentRunsTable> {
  $$AgentRunsTableFilterComposer({
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

  ColumnFilters<String> get agent => $composableBuilder(
    column: $table.agent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get valuePaise => $composableBuilder(
    column: $table.valuePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cashPaise => $composableBuilder(
    column: $table.cashPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ai => $composableBuilder(
    column: $table.ai,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AgentRunsTableOrderingComposer
    extends Composer<_$MarketDb, $AgentRunsTable> {
  $$AgentRunsTableOrderingComposer({
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

  ColumnOrderings<String> get agent => $composableBuilder(
    column: $table.agent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valuePaise => $composableBuilder(
    column: $table.valuePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cashPaise => $composableBuilder(
    column: $table.cashPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ai => $composableBuilder(
    column: $table.ai,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AgentRunsTableAnnotationComposer
    extends Composer<_$MarketDb, $AgentRunsTable> {
  $$AgentRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get agent =>
      $composableBuilder(column: $table.agent, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<int> get valuePaise => $composableBuilder(
    column: $table.valuePaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cashPaise =>
      $composableBuilder(column: $table.cashPaise, builder: (column) => column);

  GeneratedColumn<bool> get ai =>
      $composableBuilder(column: $table.ai, builder: (column) => column);
}

class $$AgentRunsTableTableManager
    extends
        RootTableManager<
          _$MarketDb,
          $AgentRunsTable,
          AgentRun,
          $$AgentRunsTableFilterComposer,
          $$AgentRunsTableOrderingComposer,
          $$AgentRunsTableAnnotationComposer,
          $$AgentRunsTableCreateCompanionBuilder,
          $$AgentRunsTableUpdateCompanionBuilder,
          (AgentRun, BaseReferences<_$MarketDb, $AgentRunsTable, AgentRun>),
          AgentRun,
          PrefetchHooks Function()
        > {
  $$AgentRunsTableTableManager(_$MarketDb db, $AgentRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgentRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgentRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgentRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> agent = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<int> valuePaise = const Value.absent(),
                Value<int> cashPaise = const Value.absent(),
                Value<bool> ai = const Value.absent(),
              }) => AgentRunsCompanion(
                id: id,
                agent: agent,
                date: date,
                at: at,
                summary: summary,
                valuePaise: valuePaise,
                cashPaise: cashPaise,
                ai: ai,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String agent,
                required String date,
                required DateTime at,
                required String summary,
                required int valuePaise,
                required int cashPaise,
                Value<bool> ai = const Value.absent(),
              }) => AgentRunsCompanion.insert(
                id: id,
                agent: agent,
                date: date,
                at: at,
                summary: summary,
                valuePaise: valuePaise,
                cashPaise: cashPaise,
                ai: ai,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AgentRunsTable, AgentRun>(table),
                  BaseReferences<_$MarketDb, $AgentRunsTable, AgentRun>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AgentRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDb,
      $AgentRunsTable,
      AgentRun,
      $$AgentRunsTableFilterComposer,
      $$AgentRunsTableOrderingComposer,
      $$AgentRunsTableAnnotationComposer,
      $$AgentRunsTableCreateCompanionBuilder,
      $$AgentRunsTableUpdateCompanionBuilder,
      (AgentRun, BaseReferences<_$MarketDb, $AgentRunsTable, AgentRun>),
      AgentRun,
      PrefetchHooks Function()
    >;
typedef $$AgentNotesTableCreateCompanionBuilder = AgentNotesCompanion Function({
  Value<int> id,
  required DateTime at,
  required String body,
  Value<String?> agent,
});
typedef $$AgentNotesTableUpdateCompanionBuilder = AgentNotesCompanion Function({
  Value<int> id,
  Value<DateTime> at,
  Value<String> body,
  Value<String?> agent,
});

class $$AgentNotesTableFilterComposer
    extends Composer<_$MarketDb, $AgentNotesTable> {
  $$AgentNotesTableFilterComposer({
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

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agent => $composableBuilder(
    column: $table.agent,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AgentNotesTableOrderingComposer
    extends Composer<_$MarketDb, $AgentNotesTable> {
  $$AgentNotesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agent => $composableBuilder(
    column: $table.agent,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AgentNotesTableAnnotationComposer
    extends Composer<_$MarketDb, $AgentNotesTable> {
  $$AgentNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get agent =>
      $composableBuilder(column: $table.agent, builder: (column) => column);
}

class $$AgentNotesTableTableManager
    extends
        RootTableManager<
          _$MarketDb,
          $AgentNotesTable,
          AgentNote,
          $$AgentNotesTableFilterComposer,
          $$AgentNotesTableOrderingComposer,
          $$AgentNotesTableAnnotationComposer,
          $$AgentNotesTableCreateCompanionBuilder,
          $$AgentNotesTableUpdateCompanionBuilder,
          (AgentNote, BaseReferences<_$MarketDb, $AgentNotesTable, AgentNote>),
          AgentNote,
          PrefetchHooks Function()
        > {
  $$AgentNotesTableTableManager(_$MarketDb db, $AgentNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AgentNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AgentNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AgentNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String?> agent = const Value.absent(),
          }) => AgentNotesCompanion(id: id, at: at, body: body, agent: agent),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required String body,
                Value<String?> agent = const Value.absent(),
              }) => AgentNotesCompanion.insert(
                id: id,
                at: at,
                body: body,
                agent: agent,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AgentNotesTable, AgentNote>(table),
                  BaseReferences<_$MarketDb, $AgentNotesTable, AgentNote>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AgentNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$MarketDb,
      $AgentNotesTable,
      AgentNote,
      $$AgentNotesTableFilterComposer,
      $$AgentNotesTableOrderingComposer,
      $$AgentNotesTableAnnotationComposer,
      $$AgentNotesTableCreateCompanionBuilder,
      $$AgentNotesTableUpdateCompanionBuilder,
      (AgentNote, BaseReferences<_$MarketDb, $AgentNotesTable, AgentNote>),
      AgentNote,
      PrefetchHooks Function()
    >;

class $MarketDbManager {
  final _$MarketDb _db;
  $MarketDbManager(this._db);
  $$InstrumentsTableTableManager get instruments =>
      $$InstrumentsTableTableManager(_db, _db.instruments);
  $$PricesTableTableManager get prices =>
      $$PricesTableTableManager(_db, _db.prices);
  $$NewsItemsTableTableManager get newsItems =>
      $$NewsItemsTableTableManager(_db, _db.newsItems);
  $$FilingsTableTableManager get filings =>
      $$FilingsTableTableManager(_db, _db.filings);
  $$FetchLogTableTableManager get fetchLog =>
      $$FetchLogTableTableManager(_db, _db.fetchLog);
  $$HolidaysTableTableManager get holidays =>
      $$HolidaysTableTableManager(_db, _db.holidays);
  $$UniverseTableTableManager get universe =>
      $$UniverseTableTableManager(_db, _db.universe);
  $$FundamentalsTableTableManager get fundamentals =>
      $$FundamentalsTableTableManager(_db, _db.fundamentals);
  $$AgentTradesTableTableManager get agentTrades =>
      $$AgentTradesTableTableManager(_db, _db.agentTrades);
  $$AgentRunsTableTableManager get agentRuns =>
      $$AgentRunsTableTableManager(_db, _db.agentRuns);
  $$AgentNotesTableTableManager get agentNotes =>
      $$AgentNotesTableTableManager(_db, _db.agentNotes);
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<String> targetDate = GeneratedColumn<String>(
    'target_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetPaiseMeta = const VerificationMeta(
    'targetPaise',
  );
  @override
  late final GeneratedColumn<int> targetPaise = GeneratedColumn<int>(
    'target_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitNameMeta = const VerificationMeta(
    'unitName',
  );
  @override
  late final GeneratedColumn<String> unitName = GeneratedColumn<String>(
    'unit_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitPaiseMeta = const VerificationMeta(
    'unitPaise',
  );
  @override
  late final GeneratedColumn<int> unitPaise = GeneratedColumn<int>(
    'unit_paise',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    targetDate,
    targetPaise,
    unitName,
    unitPaise,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Goal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDateMeta);
    }
    if (data.containsKey('target_paise')) {
      context.handle(
        _targetPaiseMeta,
        targetPaise.isAcceptableOrUnknown(
          data['target_paise']!,
          _targetPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetPaiseMeta);
    }
    if (data.containsKey('unit_name')) {
      context.handle(
        _unitNameMeta,
        unitName.isAcceptableOrUnknown(data['unit_name']!, _unitNameMeta),
      );
    }
    if (data.containsKey('unit_paise')) {
      context.handle(
        _unitPaiseMeta,
        unitPaise.isAcceptableOrUnknown(data['unit_paise']!, _unitPaiseMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_date'],
      )!,
      targetPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_paise'],
      )!,
      unitName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_name'],
      ),
      unitPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_paise'],
      ),
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final int id;
  final String name;
  final String targetDate;
  final int targetPaise;
  final String? unitName;
  final int? unitPaise;
  const Goal({
    required this.id,
    required this.name,
    required this.targetDate,
    required this.targetPaise,
    this.unitName,
    this.unitPaise,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['target_date'] = Variable<String>(targetDate);
    map['target_paise'] = Variable<int>(targetPaise);
    if (!nullToAbsent || unitName != null) {
      map['unit_name'] = Variable<String>(unitName);
    }
    if (!nullToAbsent || unitPaise != null) {
      map['unit_paise'] = Variable<int>(unitPaise);
    }
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      name: Value(name),
      targetDate: Value(targetDate),
      targetPaise: Value(targetPaise),
      unitName: unitName == null && nullToAbsent
          ? const Value.absent()
          : Value(unitName),
      unitPaise: unitPaise == null && nullToAbsent
          ? const Value.absent()
          : Value(unitPaise),
    );
  }

  factory Goal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      targetDate: serializer.fromJson<String>(json['targetDate']),
      targetPaise: serializer.fromJson<int>(json['targetPaise']),
      unitName: serializer.fromJson<String?>(json['unitName']),
      unitPaise: serializer.fromJson<int?>(json['unitPaise']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'targetDate': serializer.toJson<String>(targetDate),
      'targetPaise': serializer.toJson<int>(targetPaise),
      'unitName': serializer.toJson<String?>(unitName),
      'unitPaise': serializer.toJson<int?>(unitPaise),
    };
  }

  Goal copyWith({
    int? id,
    String? name,
    String? targetDate,
    int? targetPaise,
    Value<String?> unitName = const Value.absent(),
    Value<int?> unitPaise = const Value.absent(),
  }) => Goal(
    id: id ?? this.id,
    name: name ?? this.name,
    targetDate: targetDate ?? this.targetDate,
    targetPaise: targetPaise ?? this.targetPaise,
    unitName: unitName.present ? unitName.value : this.unitName,
    unitPaise: unitPaise.present ? unitPaise.value : this.unitPaise,
  );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      targetPaise: data.targetPaise.present
          ? data.targetPaise.value
          : this.targetPaise,
      unitName: data.unitName.present ? data.unitName.value : this.unitName,
      unitPaise: data.unitPaise.present ? data.unitPaise.value : this.unitPaise,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetDate: $targetDate, ')
          ..write('targetPaise: $targetPaise, ')
          ..write('unitName: $unitName, ')
          ..write('unitPaise: $unitPaise')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, targetDate, targetPaise, unitName, unitPaise);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.name == this.name &&
          other.targetDate == this.targetDate &&
          other.targetPaise == this.targetPaise &&
          other.unitName == this.unitName &&
          other.unitPaise == this.unitPaise);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> targetDate;
  final Value<int> targetPaise;
  final Value<String?> unitName;
  final Value<int?> unitPaise;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.targetPaise = const Value.absent(),
    this.unitName = const Value.absent(),
    this.unitPaise = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String targetDate,
    required int targetPaise,
    this.unitName = const Value.absent(),
    this.unitPaise = const Value.absent(),
  }) : name = Value(name),
       targetDate = Value(targetDate),
       targetPaise = Value(targetPaise);
  static Insertable<Goal> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? targetDate,
    Expression<int>? targetPaise,
    Expression<String>? unitName,
    Expression<int>? unitPaise,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (targetDate != null) 'target_date': targetDate,
      if (targetPaise != null) 'target_paise': targetPaise,
      if (unitName != null) 'unit_name': unitName,
      if (unitPaise != null) 'unit_paise': unitPaise,
    });
  }

  GoalsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? targetDate,
    Value<int>? targetPaise,
    Value<String?>? unitName,
    Value<int?>? unitPaise,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      targetDate: targetDate ?? this.targetDate,
      targetPaise: targetPaise ?? this.targetPaise,
      unitName: unitName ?? this.unitName,
      unitPaise: unitPaise ?? this.unitPaise,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<String>(targetDate.value);
    }
    if (targetPaise.present) {
      map['target_paise'] = Variable<int>(targetPaise.value);
    }
    if (unitName.present) {
      map['unit_name'] = Variable<String>(unitName.value);
    }
    if (unitPaise.present) {
      map['unit_paise'] = Variable<int>(unitPaise.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('targetDate: $targetDate, ')
          ..write('targetPaise: $targetPaise, ')
          ..write('unitName: $unitName, ')
          ..write('unitPaise: $unitPaise')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _instrumentIdMeta = const VerificationMeta(
    'instrumentId',
  );
  @override
  late final GeneratedColumn<int> instrumentId = GeneratedColumn<int>(
    'instrument_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitsE4Meta = const VerificationMeta(
    'unitsE4',
  );
  @override
  late final GeneratedColumn<int> unitsE4 = GeneratedColumn<int>(
    'units_e4',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceE4Meta = const VerificationMeta(
    'priceE4',
  );
  @override
  late final GeneratedColumn<int> priceE4 = GeneratedColumn<int>(
    'price_e4',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feesPaiseMeta = const VerificationMeta(
    'feesPaise',
  );
  @override
  late final GeneratedColumn<int> feesPaise = GeneratedColumn<int>(
    'fees_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<int> goalId = GeneratedColumn<int>(
    'goal_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sttPaiseMeta = const VerificationMeta(
    'sttPaise',
  );
  @override
  late final GeneratedColumn<int> sttPaise = GeneratedColumn<int>(
    'stt_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    instrumentId,
    date,
    type,
    unitsE4,
    priceE4,
    feesPaise,
    goalId,
    note,
    sttPaise,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('instrument_id')) {
      context.handle(
        _instrumentIdMeta,
        instrumentId.isAcceptableOrUnknown(
          data['instrument_id']!,
          _instrumentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instrumentIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('units_e4')) {
      context.handle(
        _unitsE4Meta,
        unitsE4.isAcceptableOrUnknown(data['units_e4']!, _unitsE4Meta),
      );
    } else if (isInserting) {
      context.missing(_unitsE4Meta);
    }
    if (data.containsKey('price_e4')) {
      context.handle(
        _priceE4Meta,
        priceE4.isAcceptableOrUnknown(data['price_e4']!, _priceE4Meta),
      );
    } else if (isInserting) {
      context.missing(_priceE4Meta);
    }
    if (data.containsKey('fees_paise')) {
      context.handle(
        _feesPaiseMeta,
        feesPaise.isAcceptableOrUnknown(data['fees_paise']!, _feesPaiseMeta),
      );
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('stt_paise')) {
      context.handle(
        _sttPaiseMeta,
        sttPaise.isAcceptableOrUnknown(data['stt_paise']!, _sttPaiseMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}instrument_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      unitsE4: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}units_e4'],
      )!,
      priceE4: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_e4'],
      )!,
      feesPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fees_paise'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      sttPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stt_paise'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final int id;
  final int instrumentId;
  final String date;
  final String type;
  final int unitsE4;
  final int priceE4;
  final int feesPaise;
  final int? goalId;
  final String note;
  final int sttPaise;
  const Transaction({
    required this.id,
    required this.instrumentId,
    required this.date,
    required this.type,
    required this.unitsE4,
    required this.priceE4,
    required this.feesPaise,
    this.goalId,
    required this.note,
    required this.sttPaise,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['instrument_id'] = Variable<int>(instrumentId);
    map['date'] = Variable<String>(date);
    map['type'] = Variable<String>(type);
    map['units_e4'] = Variable<int>(unitsE4);
    map['price_e4'] = Variable<int>(priceE4);
    map['fees_paise'] = Variable<int>(feesPaise);
    if (!nullToAbsent || goalId != null) {
      map['goal_id'] = Variable<int>(goalId);
    }
    map['note'] = Variable<String>(note);
    map['stt_paise'] = Variable<int>(sttPaise);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      instrumentId: Value(instrumentId),
      date: Value(date),
      type: Value(type),
      unitsE4: Value(unitsE4),
      priceE4: Value(priceE4),
      feesPaise: Value(feesPaise),
      goalId: goalId == null && nullToAbsent
          ? const Value.absent()
          : Value(goalId),
      note: Value(note),
      sttPaise: Value(sttPaise),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<int>(json['id']),
      instrumentId: serializer.fromJson<int>(json['instrumentId']),
      date: serializer.fromJson<String>(json['date']),
      type: serializer.fromJson<String>(json['type']),
      unitsE4: serializer.fromJson<int>(json['unitsE4']),
      priceE4: serializer.fromJson<int>(json['priceE4']),
      feesPaise: serializer.fromJson<int>(json['feesPaise']),
      goalId: serializer.fromJson<int?>(json['goalId']),
      note: serializer.fromJson<String>(json['note']),
      sttPaise: serializer.fromJson<int>(json['sttPaise']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'instrumentId': serializer.toJson<int>(instrumentId),
      'date': serializer.toJson<String>(date),
      'type': serializer.toJson<String>(type),
      'unitsE4': serializer.toJson<int>(unitsE4),
      'priceE4': serializer.toJson<int>(priceE4),
      'feesPaise': serializer.toJson<int>(feesPaise),
      'goalId': serializer.toJson<int?>(goalId),
      'note': serializer.toJson<String>(note),
      'sttPaise': serializer.toJson<int>(sttPaise),
    };
  }

  Transaction copyWith({
    int? id,
    int? instrumentId,
    String? date,
    String? type,
    int? unitsE4,
    int? priceE4,
    int? feesPaise,
    Value<int?> goalId = const Value.absent(),
    String? note,
    int? sttPaise,
  }) => Transaction(
    id: id ?? this.id,
    instrumentId: instrumentId ?? this.instrumentId,
    date: date ?? this.date,
    type: type ?? this.type,
    unitsE4: unitsE4 ?? this.unitsE4,
    priceE4: priceE4 ?? this.priceE4,
    feesPaise: feesPaise ?? this.feesPaise,
    goalId: goalId.present ? goalId.value : this.goalId,
    note: note ?? this.note,
    sttPaise: sttPaise ?? this.sttPaise,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      unitsE4: data.unitsE4.present ? data.unitsE4.value : this.unitsE4,
      priceE4: data.priceE4.present ? data.priceE4.value : this.priceE4,
      feesPaise: data.feesPaise.present ? data.feesPaise.value : this.feesPaise,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      note: data.note.present ? data.note.value : this.note,
      sttPaise: data.sttPaise.present ? data.sttPaise.value : this.sttPaise,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('unitsE4: $unitsE4, ')
          ..write('priceE4: $priceE4, ')
          ..write('feesPaise: $feesPaise, ')
          ..write('goalId: $goalId, ')
          ..write('note: $note, ')
          ..write('sttPaise: $sttPaise')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    instrumentId,
    date,
    type,
    unitsE4,
    priceE4,
    feesPaise,
    goalId,
    note,
    sttPaise,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.instrumentId == this.instrumentId &&
          other.date == this.date &&
          other.type == this.type &&
          other.unitsE4 == this.unitsE4 &&
          other.priceE4 == this.priceE4 &&
          other.feesPaise == this.feesPaise &&
          other.goalId == this.goalId &&
          other.note == this.note &&
          other.sttPaise == this.sttPaise);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<int> id;
  final Value<int> instrumentId;
  final Value<String> date;
  final Value<String> type;
  final Value<int> unitsE4;
  final Value<int> priceE4;
  final Value<int> feesPaise;
  final Value<int?> goalId;
  final Value<String> note;
  final Value<int> sttPaise;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.instrumentId = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.unitsE4 = const Value.absent(),
    this.priceE4 = const Value.absent(),
    this.feesPaise = const Value.absent(),
    this.goalId = const Value.absent(),
    this.note = const Value.absent(),
    this.sttPaise = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required int instrumentId,
    required String date,
    required String type,
    required int unitsE4,
    required int priceE4,
    this.feesPaise = const Value.absent(),
    this.goalId = const Value.absent(),
    this.note = const Value.absent(),
    this.sttPaise = const Value.absent(),
  }) : instrumentId = Value(instrumentId),
       date = Value(date),
       type = Value(type),
       unitsE4 = Value(unitsE4),
       priceE4 = Value(priceE4);
  static Insertable<Transaction> custom({
    Expression<int>? id,
    Expression<int>? instrumentId,
    Expression<String>? date,
    Expression<String>? type,
    Expression<int>? unitsE4,
    Expression<int>? priceE4,
    Expression<int>? feesPaise,
    Expression<int>? goalId,
    Expression<String>? note,
    Expression<int>? sttPaise,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (instrumentId != null) 'instrument_id': instrumentId,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (unitsE4 != null) 'units_e4': unitsE4,
      if (priceE4 != null) 'price_e4': priceE4,
      if (feesPaise != null) 'fees_paise': feesPaise,
      if (goalId != null) 'goal_id': goalId,
      if (note != null) 'note': note,
      if (sttPaise != null) 'stt_paise': sttPaise,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<int>? instrumentId,
    Value<String>? date,
    Value<String>? type,
    Value<int>? unitsE4,
    Value<int>? priceE4,
    Value<int>? feesPaise,
    Value<int?>? goalId,
    Value<String>? note,
    Value<int>? sttPaise,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      instrumentId: instrumentId ?? this.instrumentId,
      date: date ?? this.date,
      type: type ?? this.type,
      unitsE4: unitsE4 ?? this.unitsE4,
      priceE4: priceE4 ?? this.priceE4,
      feesPaise: feesPaise ?? this.feesPaise,
      goalId: goalId ?? this.goalId,
      note: note ?? this.note,
      sttPaise: sttPaise ?? this.sttPaise,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (instrumentId.present) {
      map['instrument_id'] = Variable<int>(instrumentId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (unitsE4.present) {
      map['units_e4'] = Variable<int>(unitsE4.value);
    }
    if (priceE4.present) {
      map['price_e4'] = Variable<int>(priceE4.value);
    }
    if (feesPaise.present) {
      map['fees_paise'] = Variable<int>(feesPaise.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<int>(goalId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (sttPaise.present) {
      map['stt_paise'] = Variable<int>(sttPaise.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('unitsE4: $unitsE4, ')
          ..write('priceE4: $priceE4, ')
          ..write('feesPaise: $feesPaise, ')
          ..write('goalId: $goalId, ')
          ..write('note: $note, ')
          ..write('sttPaise: $sttPaise')
          ..write(')'))
        .toString();
  }
}

class $SipPlansTable extends SipPlans with TableInfo<$SipPlansTable, SipPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SipPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _instrumentIdMeta = const VerificationMeta(
    'instrumentId',
  );
  @override
  late final GeneratedColumn<int> instrumentId = GeneratedColumn<int>(
    'instrument_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayOfMonthMeta = const VerificationMeta(
    'dayOfMonth',
  );
  @override
  late final GeneratedColumn<int> dayOfMonth = GeneratedColumn<int>(
    'day_of_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<String> start = GeneratedColumn<String>(
    'start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<String> end = GeneratedColumn<String>(
    'end',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    instrumentId,
    amountPaise,
    dayOfMonth,
    start,
    end,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sip_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<SipPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('instrument_id')) {
      context.handle(
        _instrumentIdMeta,
        instrumentId.isAcceptableOrUnknown(
          data['instrument_id']!,
          _instrumentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instrumentIdMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('day_of_month')) {
      context.handle(
        _dayOfMonthMeta,
        dayOfMonth.isAcceptableOrUnknown(
          data['day_of_month']!,
          _dayOfMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dayOfMonthMeta);
    }
    if (data.containsKey('start')) {
      context.handle(
        _startMeta,
        start.isAcceptableOrUnknown(data['start']!, _startMeta),
      );
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('end')) {
      context.handle(
        _endMeta,
        end.isAcceptableOrUnknown(data['end']!, _endMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SipPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SipPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}instrument_id'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      dayOfMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_month'],
      )!,
      start: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start'],
      )!,
      end: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $SipPlansTable createAlias(String alias) {
    return $SipPlansTable(attachedDatabase, alias);
  }
}

class SipPlan extends DataClass implements Insertable<SipPlan> {
  final int id;
  final int instrumentId;
  final int amountPaise;
  final int dayOfMonth;
  final String start;
  final String? end;
  final bool active;
  const SipPlan({
    required this.id,
    required this.instrumentId,
    required this.amountPaise,
    required this.dayOfMonth,
    required this.start,
    this.end,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['instrument_id'] = Variable<int>(instrumentId);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['day_of_month'] = Variable<int>(dayOfMonth);
    map['start'] = Variable<String>(start);
    if (!nullToAbsent || end != null) {
      map['end'] = Variable<String>(end);
    }
    map['active'] = Variable<bool>(active);
    return map;
  }

  SipPlansCompanion toCompanion(bool nullToAbsent) {
    return SipPlansCompanion(
      id: Value(id),
      instrumentId: Value(instrumentId),
      amountPaise: Value(amountPaise),
      dayOfMonth: Value(dayOfMonth),
      start: Value(start),
      end: end == null && nullToAbsent ? const Value.absent() : Value(end),
      active: Value(active),
    );
  }

  factory SipPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SipPlan(
      id: serializer.fromJson<int>(json['id']),
      instrumentId: serializer.fromJson<int>(json['instrumentId']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      dayOfMonth: serializer.fromJson<int>(json['dayOfMonth']),
      start: serializer.fromJson<String>(json['start']),
      end: serializer.fromJson<String?>(json['end']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'instrumentId': serializer.toJson<int>(instrumentId),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'dayOfMonth': serializer.toJson<int>(dayOfMonth),
      'start': serializer.toJson<String>(start),
      'end': serializer.toJson<String?>(end),
      'active': serializer.toJson<bool>(active),
    };
  }

  SipPlan copyWith({
    int? id,
    int? instrumentId,
    int? amountPaise,
    int? dayOfMonth,
    String? start,
    Value<String?> end = const Value.absent(),
    bool? active,
  }) => SipPlan(
    id: id ?? this.id,
    instrumentId: instrumentId ?? this.instrumentId,
    amountPaise: amountPaise ?? this.amountPaise,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    start: start ?? this.start,
    end: end.present ? end.value : this.end,
    active: active ?? this.active,
  );
  SipPlan copyWithCompanion(SipPlansCompanion data) {
    return SipPlan(
      id: data.id.present ? data.id.value : this.id,
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      dayOfMonth: data.dayOfMonth.present
          ? data.dayOfMonth.value
          : this.dayOfMonth,
      start: data.start.present ? data.start.value : this.start,
      end: data.end.present ? data.end.value : this.end,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SipPlan(')
          ..write('id: $id, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    instrumentId,
    amountPaise,
    dayOfMonth,
    start,
    end,
    active,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SipPlan &&
          other.id == this.id &&
          other.instrumentId == this.instrumentId &&
          other.amountPaise == this.amountPaise &&
          other.dayOfMonth == this.dayOfMonth &&
          other.start == this.start &&
          other.end == this.end &&
          other.active == this.active);
}

class SipPlansCompanion extends UpdateCompanion<SipPlan> {
  final Value<int> id;
  final Value<int> instrumentId;
  final Value<int> amountPaise;
  final Value<int> dayOfMonth;
  final Value<String> start;
  final Value<String?> end;
  final Value<bool> active;
  const SipPlansCompanion({
    this.id = const Value.absent(),
    this.instrumentId = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.active = const Value.absent(),
  });
  SipPlansCompanion.insert({
    this.id = const Value.absent(),
    required int instrumentId,
    required int amountPaise,
    required int dayOfMonth,
    required String start,
    this.end = const Value.absent(),
    this.active = const Value.absent(),
  }) : instrumentId = Value(instrumentId),
       amountPaise = Value(amountPaise),
       dayOfMonth = Value(dayOfMonth),
       start = Value(start);
  static Insertable<SipPlan> custom({
    Expression<int>? id,
    Expression<int>? instrumentId,
    Expression<int>? amountPaise,
    Expression<int>? dayOfMonth,
    Expression<String>? start,
    Expression<String>? end,
    Expression<bool>? active,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (instrumentId != null) 'instrument_id': instrumentId,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (active != null) 'active': active,
    });
  }

  SipPlansCompanion copyWith({
    Value<int>? id,
    Value<int>? instrumentId,
    Value<int>? amountPaise,
    Value<int>? dayOfMonth,
    Value<String>? start,
    Value<String?>? end,
    Value<bool>? active,
  }) {
    return SipPlansCompanion(
      id: id ?? this.id,
      instrumentId: instrumentId ?? this.instrumentId,
      amountPaise: amountPaise ?? this.amountPaise,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      start: start ?? this.start,
      end: end ?? this.end,
      active: active ?? this.active,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (instrumentId.present) {
      map['instrument_id'] = Variable<int>(instrumentId.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (start.present) {
      map['start'] = Variable<String>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<String>(end.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SipPlansCompanion(')
          ..write('id: $id, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }
}

class $ThesesTable extends Theses with TableInfo<$ThesesTable, Thesis> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ThesesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _instrumentIdMeta = const VerificationMeta(
    'instrumentId',
  );
  @override
  late final GeneratedColumn<int> instrumentId = GeneratedColumn<int>(
    'instrument_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _whyBoughtMeta = const VerificationMeta(
    'whyBought',
  );
  @override
  late final GeneratedColumn<String> whyBought = GeneratedColumn<String>(
    'why_bought',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _breaksIfMeta = const VerificationMeta(
    'breaksIf',
  );
  @override
  late final GeneratedColumn<String> breaksIf = GeneratedColumn<String>(
    'breaks_if',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewDateMeta = const VerificationMeta(
    'reviewDate',
  );
  @override
  late final GeneratedColumn<String> reviewDate = GeneratedColumn<String>(
    'review_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brokenMeta = const VerificationMeta('broken');
  @override
  late final GeneratedColumn<bool> broken = GeneratedColumn<bool>(
    'broken',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("broken" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    instrumentId,
    whyBought,
    breaksIf,
    reviewDate,
    broken,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'theses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Thesis> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('instrument_id')) {
      context.handle(
        _instrumentIdMeta,
        instrumentId.isAcceptableOrUnknown(
          data['instrument_id']!,
          _instrumentIdMeta,
        ),
      );
    }
    if (data.containsKey('why_bought')) {
      context.handle(
        _whyBoughtMeta,
        whyBought.isAcceptableOrUnknown(data['why_bought']!, _whyBoughtMeta),
      );
    } else if (isInserting) {
      context.missing(_whyBoughtMeta);
    }
    if (data.containsKey('breaks_if')) {
      context.handle(
        _breaksIfMeta,
        breaksIf.isAcceptableOrUnknown(data['breaks_if']!, _breaksIfMeta),
      );
    } else if (isInserting) {
      context.missing(_breaksIfMeta);
    }
    if (data.containsKey('review_date')) {
      context.handle(
        _reviewDateMeta,
        reviewDate.isAcceptableOrUnknown(data['review_date']!, _reviewDateMeta),
      );
    }
    if (data.containsKey('broken')) {
      context.handle(
        _brokenMeta,
        broken.isAcceptableOrUnknown(data['broken']!, _brokenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {instrumentId};
  @override
  Thesis map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Thesis(
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}instrument_id'],
      )!,
      whyBought: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}why_bought'],
      )!,
      breaksIf: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}breaks_if'],
      )!,
      reviewDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_date'],
      ),
      broken: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}broken'],
      )!,
    );
  }

  @override
  $ThesesTable createAlias(String alias) {
    return $ThesesTable(attachedDatabase, alias);
  }
}

class Thesis extends DataClass implements Insertable<Thesis> {
  final int instrumentId;
  final String whyBought;
  final String breaksIf;
  final String? reviewDate;
  final bool broken;
  const Thesis({
    required this.instrumentId,
    required this.whyBought,
    required this.breaksIf,
    this.reviewDate,
    required this.broken,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['instrument_id'] = Variable<int>(instrumentId);
    map['why_bought'] = Variable<String>(whyBought);
    map['breaks_if'] = Variable<String>(breaksIf);
    if (!nullToAbsent || reviewDate != null) {
      map['review_date'] = Variable<String>(reviewDate);
    }
    map['broken'] = Variable<bool>(broken);
    return map;
  }

  ThesesCompanion toCompanion(bool nullToAbsent) {
    return ThesesCompanion(
      instrumentId: Value(instrumentId),
      whyBought: Value(whyBought),
      breaksIf: Value(breaksIf),
      reviewDate: reviewDate == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewDate),
      broken: Value(broken),
    );
  }

  factory Thesis.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Thesis(
      instrumentId: serializer.fromJson<int>(json['instrumentId']),
      whyBought: serializer.fromJson<String>(json['whyBought']),
      breaksIf: serializer.fromJson<String>(json['breaksIf']),
      reviewDate: serializer.fromJson<String?>(json['reviewDate']),
      broken: serializer.fromJson<bool>(json['broken']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'instrumentId': serializer.toJson<int>(instrumentId),
      'whyBought': serializer.toJson<String>(whyBought),
      'breaksIf': serializer.toJson<String>(breaksIf),
      'reviewDate': serializer.toJson<String?>(reviewDate),
      'broken': serializer.toJson<bool>(broken),
    };
  }

  Thesis copyWith({
    int? instrumentId,
    String? whyBought,
    String? breaksIf,
    Value<String?> reviewDate = const Value.absent(),
    bool? broken,
  }) => Thesis(
    instrumentId: instrumentId ?? this.instrumentId,
    whyBought: whyBought ?? this.whyBought,
    breaksIf: breaksIf ?? this.breaksIf,
    reviewDate: reviewDate.present ? reviewDate.value : this.reviewDate,
    broken: broken ?? this.broken,
  );
  Thesis copyWithCompanion(ThesesCompanion data) {
    return Thesis(
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      whyBought: data.whyBought.present ? data.whyBought.value : this.whyBought,
      breaksIf: data.breaksIf.present ? data.breaksIf.value : this.breaksIf,
      reviewDate: data.reviewDate.present
          ? data.reviewDate.value
          : this.reviewDate,
      broken: data.broken.present ? data.broken.value : this.broken,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Thesis(')
          ..write('instrumentId: $instrumentId, ')
          ..write('whyBought: $whyBought, ')
          ..write('breaksIf: $breaksIf, ')
          ..write('reviewDate: $reviewDate, ')
          ..write('broken: $broken')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(instrumentId, whyBought, breaksIf, reviewDate, broken);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Thesis &&
          other.instrumentId == this.instrumentId &&
          other.whyBought == this.whyBought &&
          other.breaksIf == this.breaksIf &&
          other.reviewDate == this.reviewDate &&
          other.broken == this.broken);
}

class ThesesCompanion extends UpdateCompanion<Thesis> {
  final Value<int> instrumentId;
  final Value<String> whyBought;
  final Value<String> breaksIf;
  final Value<String?> reviewDate;
  final Value<bool> broken;
  const ThesesCompanion({
    this.instrumentId = const Value.absent(),
    this.whyBought = const Value.absent(),
    this.breaksIf = const Value.absent(),
    this.reviewDate = const Value.absent(),
    this.broken = const Value.absent(),
  });
  ThesesCompanion.insert({
    this.instrumentId = const Value.absent(),
    required String whyBought,
    required String breaksIf,
    this.reviewDate = const Value.absent(),
    this.broken = const Value.absent(),
  }) : whyBought = Value(whyBought),
       breaksIf = Value(breaksIf);
  static Insertable<Thesis> custom({
    Expression<int>? instrumentId,
    Expression<String>? whyBought,
    Expression<String>? breaksIf,
    Expression<String>? reviewDate,
    Expression<bool>? broken,
  }) {
    return RawValuesInsertable({
      if (instrumentId != null) 'instrument_id': instrumentId,
      if (whyBought != null) 'why_bought': whyBought,
      if (breaksIf != null) 'breaks_if': breaksIf,
      if (reviewDate != null) 'review_date': reviewDate,
      if (broken != null) 'broken': broken,
    });
  }

  ThesesCompanion copyWith({
    Value<int>? instrumentId,
    Value<String>? whyBought,
    Value<String>? breaksIf,
    Value<String?>? reviewDate,
    Value<bool>? broken,
  }) {
    return ThesesCompanion(
      instrumentId: instrumentId ?? this.instrumentId,
      whyBought: whyBought ?? this.whyBought,
      breaksIf: breaksIf ?? this.breaksIf,
      reviewDate: reviewDate ?? this.reviewDate,
      broken: broken ?? this.broken,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (instrumentId.present) {
      map['instrument_id'] = Variable<int>(instrumentId.value);
    }
    if (whyBought.present) {
      map['why_bought'] = Variable<String>(whyBought.value);
    }
    if (breaksIf.present) {
      map['breaks_if'] = Variable<String>(breaksIf.value);
    }
    if (reviewDate.present) {
      map['review_date'] = Variable<String>(reviewDate.value);
    }
    if (broken.present) {
      map['broken'] = Variable<bool>(broken.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ThesesCompanion(')
          ..write('instrumentId: $instrumentId, ')
          ..write('whyBought: $whyBought, ')
          ..write('breaksIf: $breaksIf, ')
          ..write('reviewDate: $reviewDate, ')
          ..write('broken: $broken')
          ..write(')'))
        .toString();
  }
}

class $SignalsTable extends Signals with TableInfo<$SignalsTable, Signal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _instrumentIdMeta = const VerificationMeta(
    'instrumentId',
  );
  @override
  late final GeneratedColumn<int> instrumentId = GeneratedColumn<int>(
    'instrument_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleMeta = const VerificationMeta('rule');
  @override
  late final GeneratedColumn<int> rule = GeneratedColumn<int>(
    'rule',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputsJsonMeta = const VerificationMeta(
    'inputsJson',
  );
  @override
  late final GeneratedColumn<String> inputsJson = GeneratedColumn<String>(
    'inputs_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleVersionMeta = const VerificationMeta(
    'ruleVersion',
  );
  @override
  late final GeneratedColumn<String> ruleVersion = GeneratedColumn<String>(
    'rule_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _userActionMeta = const VerificationMeta(
    'userAction',
  );
  @override
  late final GeneratedColumn<String> userAction = GeneratedColumn<String>(
    'user_action',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actedAtMeta = const VerificationMeta(
    'actedAt',
  );
  @override
  late final GeneratedColumn<DateTime> actedAt = GeneratedColumn<DateTime>(
    'acted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    instrumentId,
    rule,
    createdAt,
    inputsJson,
    ruleVersion,
    status,
    userAction,
    actedAt,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Signal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('instrument_id')) {
      context.handle(
        _instrumentIdMeta,
        instrumentId.isAcceptableOrUnknown(
          data['instrument_id']!,
          _instrumentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instrumentIdMeta);
    }
    if (data.containsKey('rule')) {
      context.handle(
        _ruleMeta,
        rule.isAcceptableOrUnknown(data['rule']!, _ruleMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('inputs_json')) {
      context.handle(
        _inputsJsonMeta,
        inputsJson.isAcceptableOrUnknown(data['inputs_json']!, _inputsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_inputsJsonMeta);
    }
    if (data.containsKey('rule_version')) {
      context.handle(
        _ruleVersionMeta,
        ruleVersion.isAcceptableOrUnknown(
          data['rule_version']!,
          _ruleVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ruleVersionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('user_action')) {
      context.handle(
        _userActionMeta,
        userAction.isAcceptableOrUnknown(data['user_action']!, _userActionMeta),
      );
    }
    if (data.containsKey('acted_at')) {
      context.handle(
        _actedAtMeta,
        actedAt.isAcceptableOrUnknown(data['acted_at']!, _actedAtMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Signal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Signal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}instrument_id'],
      )!,
      rule: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rule'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      inputsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inputs_json'],
      )!,
      ruleVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_version'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      userAction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_action'],
      ),
      actedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}acted_at'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  $SignalsTable createAlias(String alias) {
    return $SignalsTable(attachedDatabase, alias);
  }
}

class Signal extends DataClass implements Insertable<Signal> {
  final int id;
  final int instrumentId;
  final int rule;
  final DateTime createdAt;
  final String inputsJson;
  final String ruleVersion;
  final String status;
  final String? userAction;
  final DateTime? actedAt;
  final String note;
  const Signal({
    required this.id,
    required this.instrumentId,
    required this.rule,
    required this.createdAt,
    required this.inputsJson,
    required this.ruleVersion,
    required this.status,
    this.userAction,
    this.actedAt,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['instrument_id'] = Variable<int>(instrumentId);
    map['rule'] = Variable<int>(rule);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['inputs_json'] = Variable<String>(inputsJson);
    map['rule_version'] = Variable<String>(ruleVersion);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || userAction != null) {
      map['user_action'] = Variable<String>(userAction);
    }
    if (!nullToAbsent || actedAt != null) {
      map['acted_at'] = Variable<DateTime>(actedAt);
    }
    map['note'] = Variable<String>(note);
    return map;
  }

  SignalsCompanion toCompanion(bool nullToAbsent) {
    return SignalsCompanion(
      id: Value(id),
      instrumentId: Value(instrumentId),
      rule: Value(rule),
      createdAt: Value(createdAt),
      inputsJson: Value(inputsJson),
      ruleVersion: Value(ruleVersion),
      status: Value(status),
      userAction: userAction == null && nullToAbsent
          ? const Value.absent()
          : Value(userAction),
      actedAt: actedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(actedAt),
      note: Value(note),
    );
  }

  factory Signal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Signal(
      id: serializer.fromJson<int>(json['id']),
      instrumentId: serializer.fromJson<int>(json['instrumentId']),
      rule: serializer.fromJson<int>(json['rule']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      inputsJson: serializer.fromJson<String>(json['inputsJson']),
      ruleVersion: serializer.fromJson<String>(json['ruleVersion']),
      status: serializer.fromJson<String>(json['status']),
      userAction: serializer.fromJson<String?>(json['userAction']),
      actedAt: serializer.fromJson<DateTime?>(json['actedAt']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'instrumentId': serializer.toJson<int>(instrumentId),
      'rule': serializer.toJson<int>(rule),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'inputsJson': serializer.toJson<String>(inputsJson),
      'ruleVersion': serializer.toJson<String>(ruleVersion),
      'status': serializer.toJson<String>(status),
      'userAction': serializer.toJson<String?>(userAction),
      'actedAt': serializer.toJson<DateTime?>(actedAt),
      'note': serializer.toJson<String>(note),
    };
  }

  Signal copyWith({
    int? id,
    int? instrumentId,
    int? rule,
    DateTime? createdAt,
    String? inputsJson,
    String? ruleVersion,
    String? status,
    Value<String?> userAction = const Value.absent(),
    Value<DateTime?> actedAt = const Value.absent(),
    String? note,
  }) => Signal(
    id: id ?? this.id,
    instrumentId: instrumentId ?? this.instrumentId,
    rule: rule ?? this.rule,
    createdAt: createdAt ?? this.createdAt,
    inputsJson: inputsJson ?? this.inputsJson,
    ruleVersion: ruleVersion ?? this.ruleVersion,
    status: status ?? this.status,
    userAction: userAction.present ? userAction.value : this.userAction,
    actedAt: actedAt.present ? actedAt.value : this.actedAt,
    note: note ?? this.note,
  );
  Signal copyWithCompanion(SignalsCompanion data) {
    return Signal(
      id: data.id.present ? data.id.value : this.id,
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      rule: data.rule.present ? data.rule.value : this.rule,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      inputsJson: data.inputsJson.present
          ? data.inputsJson.value
          : this.inputsJson,
      ruleVersion: data.ruleVersion.present
          ? data.ruleVersion.value
          : this.ruleVersion,
      status: data.status.present ? data.status.value : this.status,
      userAction: data.userAction.present
          ? data.userAction.value
          : this.userAction,
      actedAt: data.actedAt.present ? data.actedAt.value : this.actedAt,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Signal(')
          ..write('id: $id, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('rule: $rule, ')
          ..write('createdAt: $createdAt, ')
          ..write('inputsJson: $inputsJson, ')
          ..write('ruleVersion: $ruleVersion, ')
          ..write('status: $status, ')
          ..write('userAction: $userAction, ')
          ..write('actedAt: $actedAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    instrumentId,
    rule,
    createdAt,
    inputsJson,
    ruleVersion,
    status,
    userAction,
    actedAt,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Signal &&
          other.id == this.id &&
          other.instrumentId == this.instrumentId &&
          other.rule == this.rule &&
          other.createdAt == this.createdAt &&
          other.inputsJson == this.inputsJson &&
          other.ruleVersion == this.ruleVersion &&
          other.status == this.status &&
          other.userAction == this.userAction &&
          other.actedAt == this.actedAt &&
          other.note == this.note);
}

class SignalsCompanion extends UpdateCompanion<Signal> {
  final Value<int> id;
  final Value<int> instrumentId;
  final Value<int> rule;
  final Value<DateTime> createdAt;
  final Value<String> inputsJson;
  final Value<String> ruleVersion;
  final Value<String> status;
  final Value<String?> userAction;
  final Value<DateTime?> actedAt;
  final Value<String> note;
  const SignalsCompanion({
    this.id = const Value.absent(),
    this.instrumentId = const Value.absent(),
    this.rule = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.inputsJson = const Value.absent(),
    this.ruleVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.userAction = const Value.absent(),
    this.actedAt = const Value.absent(),
    this.note = const Value.absent(),
  });
  SignalsCompanion.insert({
    this.id = const Value.absent(),
    required int instrumentId,
    required int rule,
    required DateTime createdAt,
    required String inputsJson,
    required String ruleVersion,
    required String status,
    this.userAction = const Value.absent(),
    this.actedAt = const Value.absent(),
    this.note = const Value.absent(),
  }) : instrumentId = Value(instrumentId),
       rule = Value(rule),
       createdAt = Value(createdAt),
       inputsJson = Value(inputsJson),
       ruleVersion = Value(ruleVersion),
       status = Value(status);
  static Insertable<Signal> custom({
    Expression<int>? id,
    Expression<int>? instrumentId,
    Expression<int>? rule,
    Expression<DateTime>? createdAt,
    Expression<String>? inputsJson,
    Expression<String>? ruleVersion,
    Expression<String>? status,
    Expression<String>? userAction,
    Expression<DateTime>? actedAt,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (instrumentId != null) 'instrument_id': instrumentId,
      if (rule != null) 'rule': rule,
      if (createdAt != null) 'created_at': createdAt,
      if (inputsJson != null) 'inputs_json': inputsJson,
      if (ruleVersion != null) 'rule_version': ruleVersion,
      if (status != null) 'status': status,
      if (userAction != null) 'user_action': userAction,
      if (actedAt != null) 'acted_at': actedAt,
      if (note != null) 'note': note,
    });
  }

  SignalsCompanion copyWith({
    Value<int>? id,
    Value<int>? instrumentId,
    Value<int>? rule,
    Value<DateTime>? createdAt,
    Value<String>? inputsJson,
    Value<String>? ruleVersion,
    Value<String>? status,
    Value<String?>? userAction,
    Value<DateTime?>? actedAt,
    Value<String>? note,
  }) {
    return SignalsCompanion(
      id: id ?? this.id,
      instrumentId: instrumentId ?? this.instrumentId,
      rule: rule ?? this.rule,
      createdAt: createdAt ?? this.createdAt,
      inputsJson: inputsJson ?? this.inputsJson,
      ruleVersion: ruleVersion ?? this.ruleVersion,
      status: status ?? this.status,
      userAction: userAction ?? this.userAction,
      actedAt: actedAt ?? this.actedAt,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (instrumentId.present) {
      map['instrument_id'] = Variable<int>(instrumentId.value);
    }
    if (rule.present) {
      map['rule'] = Variable<int>(rule.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (inputsJson.present) {
      map['inputs_json'] = Variable<String>(inputsJson.value);
    }
    if (ruleVersion.present) {
      map['rule_version'] = Variable<String>(ruleVersion.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (userAction.present) {
      map['user_action'] = Variable<String>(userAction.value);
    }
    if (actedAt.present) {
      map['acted_at'] = Variable<DateTime>(actedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignalsCompanion(')
          ..write('id: $id, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('rule: $rule, ')
          ..write('createdAt: $createdAt, ')
          ..write('inputsJson: $inputsJson, ')
          ..write('ruleVersion: $ruleVersion, ')
          ..write('status: $status, ')
          ..write('userAction: $userAction, ')
          ..write('actedAt: $actedAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $AuditLogTable extends AuditLog
    with TableInfo<$AuditLogTable, AuditLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, at, action, detail];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    } else if (isInserting) {
      context.missing(_detailMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      )!,
    );
  }

  @override
  $AuditLogTable createAlias(String alias) {
    return $AuditLogTable(attachedDatabase, alias);
  }
}

class AuditLogData extends DataClass implements Insertable<AuditLogData> {
  final int id;
  final DateTime at;
  final String action;
  final String detail;
  const AuditLogData({
    required this.id,
    required this.at,
    required this.action,
    required this.detail,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['action'] = Variable<String>(action);
    map['detail'] = Variable<String>(detail);
    return map;
  }

  AuditLogCompanion toCompanion(bool nullToAbsent) {
    return AuditLogCompanion(
      id: Value(id),
      at: Value(at),
      action: Value(action),
      detail: Value(detail),
    );
  }

  factory AuditLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogData(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      action: serializer.fromJson<String>(json['action']),
      detail: serializer.fromJson<String>(json['detail']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'action': serializer.toJson<String>(action),
      'detail': serializer.toJson<String>(detail),
    };
  }

  AuditLogData copyWith({
    int? id,
    DateTime? at,
    String? action,
    String? detail,
  }) => AuditLogData(
    id: id ?? this.id,
    at: at ?? this.at,
    action: action ?? this.action,
    detail: detail ?? this.detail,
  );
  AuditLogData copyWithCompanion(AuditLogCompanion data) {
    return AuditLogData(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      action: data.action.present ? data.action.value : this.action,
      detail: data.detail.present ? data.detail.value : this.detail,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogData(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('action: $action, ')
          ..write('detail: $detail')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, at, action, detail);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogData &&
          other.id == this.id &&
          other.at == this.at &&
          other.action == this.action &&
          other.detail == this.detail);
}

class AuditLogCompanion extends UpdateCompanion<AuditLogData> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<String> action;
  final Value<String> detail;
  const AuditLogCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.action = const Value.absent(),
    this.detail = const Value.absent(),
  });
  AuditLogCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required String action,
    required String detail,
  }) : at = Value(at),
       action = Value(action),
       detail = Value(detail);
  static Insertable<AuditLogData> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<String>? action,
    Expression<String>? detail,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (action != null) 'action': action,
      if (detail != null) 'detail': detail,
    });
  }

  AuditLogCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<String>? action,
    Value<String>? detail,
  }) {
    return AuditLogCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      action: action ?? this.action,
      detail: detail ?? this.detail,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('action: $action, ')
          ..write('detail: $detail')
          ..write(')'))
        .toString();
  }
}

class $HoldingPrefsTable extends HoldingPrefs
    with TableInfo<$HoldingPrefsTable, HoldingPref> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HoldingPrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _instrumentIdMeta = const VerificationMeta(
    'instrumentId',
  );
  @override
  late final GeneratedColumn<int> instrumentId = GeneratedColumn<int>(
    'instrument_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bucketMeta = const VerificationMeta('bucket');
  @override
  late final GeneratedColumn<String> bucket = GeneratedColumn<String>(
    'bucket',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('core'),
  );
  @override
  List<GeneratedColumn> get $columns => [instrumentId, bucket];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'holding_prefs';
  @override
  VerificationContext validateIntegrity(
    Insertable<HoldingPref> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('instrument_id')) {
      context.handle(
        _instrumentIdMeta,
        instrumentId.isAcceptableOrUnknown(
          data['instrument_id']!,
          _instrumentIdMeta,
        ),
      );
    }
    if (data.containsKey('bucket')) {
      context.handle(
        _bucketMeta,
        bucket.isAcceptableOrUnknown(data['bucket']!, _bucketMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {instrumentId};
  @override
  HoldingPref map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HoldingPref(
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}instrument_id'],
      )!,
      bucket: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bucket'],
      )!,
    );
  }

  @override
  $HoldingPrefsTable createAlias(String alias) {
    return $HoldingPrefsTable(attachedDatabase, alias);
  }
}

class HoldingPref extends DataClass implements Insertable<HoldingPref> {
  final int instrumentId;
  final String bucket;
  const HoldingPref({required this.instrumentId, required this.bucket});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['instrument_id'] = Variable<int>(instrumentId);
    map['bucket'] = Variable<String>(bucket);
    return map;
  }

  HoldingPrefsCompanion toCompanion(bool nullToAbsent) {
    return HoldingPrefsCompanion(
      instrumentId: Value(instrumentId),
      bucket: Value(bucket),
    );
  }

  factory HoldingPref.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HoldingPref(
      instrumentId: serializer.fromJson<int>(json['instrumentId']),
      bucket: serializer.fromJson<String>(json['bucket']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'instrumentId': serializer.toJson<int>(instrumentId),
      'bucket': serializer.toJson<String>(bucket),
    };
  }

  HoldingPref copyWith({int? instrumentId, String? bucket}) => HoldingPref(
    instrumentId: instrumentId ?? this.instrumentId,
    bucket: bucket ?? this.bucket,
  );
  HoldingPref copyWithCompanion(HoldingPrefsCompanion data) {
    return HoldingPref(
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      bucket: data.bucket.present ? data.bucket.value : this.bucket,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HoldingPref(')
          ..write('instrumentId: $instrumentId, ')
          ..write('bucket: $bucket')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(instrumentId, bucket);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HoldingPref &&
          other.instrumentId == this.instrumentId &&
          other.bucket == this.bucket);
}

class HoldingPrefsCompanion extends UpdateCompanion<HoldingPref> {
  final Value<int> instrumentId;
  final Value<String> bucket;
  const HoldingPrefsCompanion({
    this.instrumentId = const Value.absent(),
    this.bucket = const Value.absent(),
  });
  HoldingPrefsCompanion.insert({
    this.instrumentId = const Value.absent(),
    this.bucket = const Value.absent(),
  });
  static Insertable<HoldingPref> custom({
    Expression<int>? instrumentId,
    Expression<String>? bucket,
  }) {
    return RawValuesInsertable({
      if (instrumentId != null) 'instrument_id': instrumentId,
      if (bucket != null) 'bucket': bucket,
    });
  }

  HoldingPrefsCompanion copyWith({
    Value<int>? instrumentId,
    Value<String>? bucket,
  }) {
    return HoldingPrefsCompanion(
      instrumentId: instrumentId ?? this.instrumentId,
      bucket: bucket ?? this.bucket,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (instrumentId.present) {
      map['instrument_id'] = Variable<int>(instrumentId.value);
    }
    if (bucket.present) {
      map['bucket'] = Variable<String>(bucket.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HoldingPrefsCompanion(')
          ..write('instrumentId: $instrumentId, ')
          ..write('bucket: $bucket')
          ..write(')'))
        .toString();
  }
}

class $ProfileSettingsTable extends ProfileSettings
    with TableInfo<$ProfileSettingsTable, ProfileSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'profile_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileSetting> instance, {
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
  ProfileSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileSetting(
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
  $ProfileSettingsTable createAlias(String alias) {
    return $ProfileSettingsTable(attachedDatabase, alias);
  }
}

class ProfileSetting extends DataClass implements Insertable<ProfileSetting> {
  final String key;
  final String value;
  const ProfileSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  ProfileSettingsCompanion toCompanion(bool nullToAbsent) {
    return ProfileSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory ProfileSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileSetting(
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

  ProfileSetting copyWith({String? key, String? value}) =>
      ProfileSetting(key: key ?? this.key, value: value ?? this.value);
  ProfileSetting copyWithCompanion(ProfileSettingsCompanion data) {
    return ProfileSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileSetting(')
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
      (other is ProfileSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class ProfileSettingsCompanion extends UpdateCompanion<ProfileSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const ProfileSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfileSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<ProfileSetting> custom({
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

  ProfileSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return ProfileSettingsCompanion(
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
    return (StringBuffer('ProfileSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaperTradesTable extends PaperTrades
    with TableInfo<$PaperTradesTable, PaperTrade> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaperTradesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _instrumentIdMeta = const VerificationMeta(
    'instrumentId',
  );
  @override
  late final GeneratedColumn<int> instrumentId = GeneratedColumn<int>(
    'instrument_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitsE4Meta = const VerificationMeta(
    'unitsE4',
  );
  @override
  late final GeneratedColumn<int> unitsE4 = GeneratedColumn<int>(
    'units_e4',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceE4Meta = const VerificationMeta(
    'priceE4',
  );
  @override
  late final GeneratedColumn<int> priceE4 = GeneratedColumn<int>(
    'price_e4',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    instrumentId,
    date,
    type,
    unitsE4,
    priceE4,
    reason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'paper_trades';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaperTrade> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('instrument_id')) {
      context.handle(
        _instrumentIdMeta,
        instrumentId.isAcceptableOrUnknown(
          data['instrument_id']!,
          _instrumentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instrumentIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('units_e4')) {
      context.handle(
        _unitsE4Meta,
        unitsE4.isAcceptableOrUnknown(data['units_e4']!, _unitsE4Meta),
      );
    } else if (isInserting) {
      context.missing(_unitsE4Meta);
    }
    if (data.containsKey('price_e4')) {
      context.handle(
        _priceE4Meta,
        priceE4.isAcceptableOrUnknown(data['price_e4']!, _priceE4Meta),
      );
    } else if (isInserting) {
      context.missing(_priceE4Meta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaperTrade map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaperTrade(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}instrument_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      unitsE4: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}units_e4'],
      )!,
      priceE4: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_e4'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
    );
  }

  @override
  $PaperTradesTable createAlias(String alias) {
    return $PaperTradesTable(attachedDatabase, alias);
  }
}

class PaperTrade extends DataClass implements Insertable<PaperTrade> {
  final int id;
  final int instrumentId;
  final String date;
  final String type;
  final int unitsE4;
  final int priceE4;
  final String reason;
  const PaperTrade({
    required this.id,
    required this.instrumentId,
    required this.date,
    required this.type,
    required this.unitsE4,
    required this.priceE4,
    required this.reason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['instrument_id'] = Variable<int>(instrumentId);
    map['date'] = Variable<String>(date);
    map['type'] = Variable<String>(type);
    map['units_e4'] = Variable<int>(unitsE4);
    map['price_e4'] = Variable<int>(priceE4);
    map['reason'] = Variable<String>(reason);
    return map;
  }

  PaperTradesCompanion toCompanion(bool nullToAbsent) {
    return PaperTradesCompanion(
      id: Value(id),
      instrumentId: Value(instrumentId),
      date: Value(date),
      type: Value(type),
      unitsE4: Value(unitsE4),
      priceE4: Value(priceE4),
      reason: Value(reason),
    );
  }

  factory PaperTrade.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaperTrade(
      id: serializer.fromJson<int>(json['id']),
      instrumentId: serializer.fromJson<int>(json['instrumentId']),
      date: serializer.fromJson<String>(json['date']),
      type: serializer.fromJson<String>(json['type']),
      unitsE4: serializer.fromJson<int>(json['unitsE4']),
      priceE4: serializer.fromJson<int>(json['priceE4']),
      reason: serializer.fromJson<String>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'instrumentId': serializer.toJson<int>(instrumentId),
      'date': serializer.toJson<String>(date),
      'type': serializer.toJson<String>(type),
      'unitsE4': serializer.toJson<int>(unitsE4),
      'priceE4': serializer.toJson<int>(priceE4),
      'reason': serializer.toJson<String>(reason),
    };
  }

  PaperTrade copyWith({
    int? id,
    int? instrumentId,
    String? date,
    String? type,
    int? unitsE4,
    int? priceE4,
    String? reason,
  }) => PaperTrade(
    id: id ?? this.id,
    instrumentId: instrumentId ?? this.instrumentId,
    date: date ?? this.date,
    type: type ?? this.type,
    unitsE4: unitsE4 ?? this.unitsE4,
    priceE4: priceE4 ?? this.priceE4,
    reason: reason ?? this.reason,
  );
  PaperTrade copyWithCompanion(PaperTradesCompanion data) {
    return PaperTrade(
      id: data.id.present ? data.id.value : this.id,
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      unitsE4: data.unitsE4.present ? data.unitsE4.value : this.unitsE4,
      priceE4: data.priceE4.present ? data.priceE4.value : this.priceE4,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaperTrade(')
          ..write('id: $id, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('unitsE4: $unitsE4, ')
          ..write('priceE4: $priceE4, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, instrumentId, date, type, unitsE4, priceE4, reason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaperTrade &&
          other.id == this.id &&
          other.instrumentId == this.instrumentId &&
          other.date == this.date &&
          other.type == this.type &&
          other.unitsE4 == this.unitsE4 &&
          other.priceE4 == this.priceE4 &&
          other.reason == this.reason);
}

class PaperTradesCompanion extends UpdateCompanion<PaperTrade> {
  final Value<int> id;
  final Value<int> instrumentId;
  final Value<String> date;
  final Value<String> type;
  final Value<int> unitsE4;
  final Value<int> priceE4;
  final Value<String> reason;
  const PaperTradesCompanion({
    this.id = const Value.absent(),
    this.instrumentId = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.unitsE4 = const Value.absent(),
    this.priceE4 = const Value.absent(),
    this.reason = const Value.absent(),
  });
  PaperTradesCompanion.insert({
    this.id = const Value.absent(),
    required int instrumentId,
    required String date,
    required String type,
    required int unitsE4,
    required int priceE4,
    this.reason = const Value.absent(),
  }) : instrumentId = Value(instrumentId),
       date = Value(date),
       type = Value(type),
       unitsE4 = Value(unitsE4),
       priceE4 = Value(priceE4);
  static Insertable<PaperTrade> custom({
    Expression<int>? id,
    Expression<int>? instrumentId,
    Expression<String>? date,
    Expression<String>? type,
    Expression<int>? unitsE4,
    Expression<int>? priceE4,
    Expression<String>? reason,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (instrumentId != null) 'instrument_id': instrumentId,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (unitsE4 != null) 'units_e4': unitsE4,
      if (priceE4 != null) 'price_e4': priceE4,
      if (reason != null) 'reason': reason,
    });
  }

  PaperTradesCompanion copyWith({
    Value<int>? id,
    Value<int>? instrumentId,
    Value<String>? date,
    Value<String>? type,
    Value<int>? unitsE4,
    Value<int>? priceE4,
    Value<String>? reason,
  }) {
    return PaperTradesCompanion(
      id: id ?? this.id,
      instrumentId: instrumentId ?? this.instrumentId,
      date: date ?? this.date,
      type: type ?? this.type,
      unitsE4: unitsE4 ?? this.unitsE4,
      priceE4: priceE4 ?? this.priceE4,
      reason: reason ?? this.reason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (instrumentId.present) {
      map['instrument_id'] = Variable<int>(instrumentId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (unitsE4.present) {
      map['units_e4'] = Variable<int>(unitsE4.value);
    }
    if (priceE4.present) {
      map['price_e4'] = Variable<int>(priceE4.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaperTradesCompanion(')
          ..write('id: $id, ')
          ..write('instrumentId: $instrumentId, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('unitsE4: $unitsE4, ')
          ..write('priceE4: $priceE4, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }
}

class $WatchlistTable extends Watchlist with TableInfo<$WatchlistTable, Watch> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchlistTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _instrumentIdMeta = const VerificationMeta(
    'instrumentId',
  );
  @override
  late final GeneratedColumn<int> instrumentId = GeneratedColumn<int>(
    'instrument_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [instrumentId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watchlist';
  @override
  VerificationContext validateIntegrity(
    Insertable<Watch> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('instrument_id')) {
      context.handle(
        _instrumentIdMeta,
        instrumentId.isAcceptableOrUnknown(
          data['instrument_id']!,
          _instrumentIdMeta,
        ),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {instrumentId};
  @override
  Watch map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Watch(
      instrumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}instrument_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $WatchlistTable createAlias(String alias) {
    return $WatchlistTable(attachedDatabase, alias);
  }
}

class Watch extends DataClass implements Insertable<Watch> {
  final int instrumentId;
  final DateTime addedAt;
  const Watch({required this.instrumentId, required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['instrument_id'] = Variable<int>(instrumentId);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  WatchlistCompanion toCompanion(bool nullToAbsent) {
    return WatchlistCompanion(
      instrumentId: Value(instrumentId),
      addedAt: Value(addedAt),
    );
  }

  factory Watch.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Watch(
      instrumentId: serializer.fromJson<int>(json['instrumentId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'instrumentId': serializer.toJson<int>(instrumentId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  Watch copyWith({int? instrumentId, DateTime? addedAt}) => Watch(
    instrumentId: instrumentId ?? this.instrumentId,
    addedAt: addedAt ?? this.addedAt,
  );
  Watch copyWithCompanion(WatchlistCompanion data) {
    return Watch(
      instrumentId: data.instrumentId.present
          ? data.instrumentId.value
          : this.instrumentId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Watch(')
          ..write('instrumentId: $instrumentId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(instrumentId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Watch &&
          other.instrumentId == this.instrumentId &&
          other.addedAt == this.addedAt);
}

class WatchlistCompanion extends UpdateCompanion<Watch> {
  final Value<int> instrumentId;
  final Value<DateTime> addedAt;
  const WatchlistCompanion({
    this.instrumentId = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  WatchlistCompanion.insert({
    this.instrumentId = const Value.absent(),
    required DateTime addedAt,
  }) : addedAt = Value(addedAt);
  static Insertable<Watch> custom({
    Expression<int>? instrumentId,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (instrumentId != null) 'instrument_id': instrumentId,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  WatchlistCompanion copyWith({
    Value<int>? instrumentId,
    Value<DateTime>? addedAt,
  }) {
    return WatchlistCompanion(
      instrumentId: instrumentId ?? this.instrumentId,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (instrumentId.present) {
      map['instrument_id'] = Variable<int>(instrumentId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchlistCompanion(')
          ..write('instrumentId: $instrumentId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$ProfileDb extends GeneratedDatabase {
  _$ProfileDb(QueryExecutor e) : super(e);
  $ProfileDbManager get managers => $ProfileDbManager(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $SipPlansTable sipPlans = $SipPlansTable(this);
  late final $ThesesTable theses = $ThesesTable(this);
  late final $SignalsTable signals = $SignalsTable(this);
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final $HoldingPrefsTable holdingPrefs = $HoldingPrefsTable(this);
  late final $ProfileSettingsTable profileSettings = $ProfileSettingsTable(
    this,
  );
  late final $PaperTradesTable paperTrades = $PaperTradesTable(this);
  late final $WatchlistTable watchlist = $WatchlistTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    goals,
    transactions,
    sipPlans,
    theses,
    signals,
    auditLog,
    holdingPrefs,
    profileSettings,
    paperTrades,
    watchlist,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  required String name,
  required String targetDate,
  required int targetPaise,
  Value<String?> unitName,
  Value<int?> unitPaise,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> targetDate,
  Value<int> targetPaise,
  Value<String?> unitName,
  Value<int?> unitPaise,
});

class $$GoalsTableFilterComposer extends Composer<_$ProfileDb, $GoalsTable> {
  $$GoalsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetPaise => $composableBuilder(
    column: $table.targetPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitName => $composableBuilder(
    column: $table.unitName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPaise => $composableBuilder(
    column: $table.unitPaise,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalsTableOrderingComposer extends Composer<_$ProfileDb, $GoalsTable> {
  $$GoalsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetPaise => $composableBuilder(
    column: $table.targetPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitName => $composableBuilder(
    column: $table.unitName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPaise => $composableBuilder(
    column: $table.unitPaise,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$ProfileDb, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetPaise => $composableBuilder(
    column: $table.targetPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitName =>
      $composableBuilder(column: $table.unitName, builder: (column) => column);

  GeneratedColumn<int> get unitPaise =>
      $composableBuilder(column: $table.unitPaise, builder: (column) => column);
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$ProfileDb,
          $GoalsTable,
          Goal,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (Goal, BaseReferences<_$ProfileDb, $GoalsTable, Goal>),
          Goal,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$ProfileDb db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> targetDate = const Value.absent(),
                Value<int> targetPaise = const Value.absent(),
                Value<String?> unitName = const Value.absent(),
                Value<int?> unitPaise = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                name: name,
                targetDate: targetDate,
                targetPaise: targetPaise,
                unitName: unitName,
                unitPaise: unitPaise,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String targetDate,
                required int targetPaise,
                Value<String?> unitName = const Value.absent(),
                Value<int?> unitPaise = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                name: name,
                targetDate: targetDate,
                targetPaise: targetPaise,
                unitName: unitName,
                unitPaise: unitPaise,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GoalsTable, Goal>(table),
                  BaseReferences<_$ProfileDb, $GoalsTable, Goal>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProfileDb,
      $GoalsTable,
      Goal,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (Goal, BaseReferences<_$ProfileDb, $GoalsTable, Goal>),
      Goal,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      required int instrumentId,
      required String date,
      required String type,
      required int unitsE4,
      required int priceE4,
      Value<int> feesPaise,
      Value<int?> goalId,
      Value<String> note,
      Value<int> sttPaise,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<int> instrumentId,
      Value<String> date,
      Value<String> type,
      Value<int> unitsE4,
      Value<int> priceE4,
      Value<int> feesPaise,
      Value<int?> goalId,
      Value<String> note,
      Value<int> sttPaise,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$ProfileDb, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
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

  ColumnFilters<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitsE4 => $composableBuilder(
    column: $table.unitsE4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceE4 => $composableBuilder(
    column: $table.priceE4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get feesPaise => $composableBuilder(
    column: $table.feesPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sttPaise => $composableBuilder(
    column: $table.sttPaise,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$ProfileDb, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
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

  ColumnOrderings<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitsE4 => $composableBuilder(
    column: $table.unitsE4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceE4 => $composableBuilder(
    column: $table.priceE4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get feesPaise => $composableBuilder(
    column: $table.feesPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sttPaise => $composableBuilder(
    column: $table.sttPaise,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$ProfileDb, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get unitsE4 =>
      $composableBuilder(column: $table.unitsE4, builder: (column) => column);

  GeneratedColumn<int> get priceE4 =>
      $composableBuilder(column: $table.priceE4, builder: (column) => column);

  GeneratedColumn<int> get feesPaise =>
      $composableBuilder(column: $table.feesPaise, builder: (column) => column);

  GeneratedColumn<int> get goalId =>
      $composableBuilder(column: $table.goalId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get sttPaise =>
      $composableBuilder(column: $table.sttPaise, builder: (column) => column);
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$ProfileDb,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            Transaction,
            BaseReferences<_$ProfileDb, $TransactionsTable, Transaction>,
          ),
          Transaction,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$ProfileDb db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> instrumentId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> unitsE4 = const Value.absent(),
                Value<int> priceE4 = const Value.absent(),
                Value<int> feesPaise = const Value.absent(),
                Value<int?> goalId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> sttPaise = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                instrumentId: instrumentId,
                date: date,
                type: type,
                unitsE4: unitsE4,
                priceE4: priceE4,
                feesPaise: feesPaise,
                goalId: goalId,
                note: note,
                sttPaise: sttPaise,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int instrumentId,
                required String date,
                required String type,
                required int unitsE4,
                required int priceE4,
                Value<int> feesPaise = const Value.absent(),
                Value<int?> goalId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> sttPaise = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                instrumentId: instrumentId,
                date: date,
                type: type,
                unitsE4: unitsE4,
                priceE4: priceE4,
                feesPaise: feesPaise,
                goalId: goalId,
                note: note,
                sttPaise: sttPaise,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTable, Transaction>(table),
                  BaseReferences<_$ProfileDb, $TransactionsTable, Transaction>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProfileDb,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        Transaction,
        BaseReferences<_$ProfileDb, $TransactionsTable, Transaction>,
      ),
      Transaction,
      PrefetchHooks Function()
    >;
typedef $$SipPlansTableCreateCompanionBuilder = SipPlansCompanion Function({
  Value<int> id,
  required int instrumentId,
  required int amountPaise,
  required int dayOfMonth,
  required String start,
  Value<String?> end,
  Value<bool> active,
});
typedef $$SipPlansTableUpdateCompanionBuilder = SipPlansCompanion Function({
  Value<int> id,
  Value<int> instrumentId,
  Value<int> amountPaise,
  Value<int> dayOfMonth,
  Value<String> start,
  Value<String?> end,
  Value<bool> active,
});

class $$SipPlansTableFilterComposer
    extends Composer<_$ProfileDb, $SipPlansTable> {
  $$SipPlansTableFilterComposer({
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

  ColumnFilters<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SipPlansTableOrderingComposer
    extends Composer<_$ProfileDb, $SipPlansTable> {
  $$SipPlansTableOrderingComposer({
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

  ColumnOrderings<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SipPlansTableAnnotationComposer
    extends Composer<_$ProfileDb, $SipPlansTable> {
  $$SipPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<String> get end =>
      $composableBuilder(column: $table.end, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);
}

class $$SipPlansTableTableManager
    extends
        RootTableManager<
          _$ProfileDb,
          $SipPlansTable,
          SipPlan,
          $$SipPlansTableFilterComposer,
          $$SipPlansTableOrderingComposer,
          $$SipPlansTableAnnotationComposer,
          $$SipPlansTableCreateCompanionBuilder,
          $$SipPlansTableUpdateCompanionBuilder,
          (SipPlan, BaseReferences<_$ProfileDb, $SipPlansTable, SipPlan>),
          SipPlan,
          PrefetchHooks Function()
        > {
  $$SipPlansTableTableManager(_$ProfileDb db, $SipPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SipPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SipPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SipPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> instrumentId = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<int> dayOfMonth = const Value.absent(),
                Value<String> start = const Value.absent(),
                Value<String?> end = const Value.absent(),
                Value<bool> active = const Value.absent(),
              }) => SipPlansCompanion(
                id: id,
                instrumentId: instrumentId,
                amountPaise: amountPaise,
                dayOfMonth: dayOfMonth,
                start: start,
                end: end,
                active: active,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int instrumentId,
                required int amountPaise,
                required int dayOfMonth,
                required String start,
                Value<String?> end = const Value.absent(),
                Value<bool> active = const Value.absent(),
              }) => SipPlansCompanion.insert(
                id: id,
                instrumentId: instrumentId,
                amountPaise: amountPaise,
                dayOfMonth: dayOfMonth,
                start: start,
                end: end,
                active: active,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SipPlansTable, SipPlan>(table),
                  BaseReferences<_$ProfileDb, $SipPlansTable, SipPlan>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SipPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$ProfileDb,
      $SipPlansTable,
      SipPlan,
      $$SipPlansTableFilterComposer,
      $$SipPlansTableOrderingComposer,
      $$SipPlansTableAnnotationComposer,
      $$SipPlansTableCreateCompanionBuilder,
      $$SipPlansTableUpdateCompanionBuilder,
      (SipPlan, BaseReferences<_$ProfileDb, $SipPlansTable, SipPlan>),
      SipPlan,
      PrefetchHooks Function()
    >;
typedef $$ThesesTableCreateCompanionBuilder = ThesesCompanion Function({
  Value<int> instrumentId,
  required String whyBought,
  required String breaksIf,
  Value<String?> reviewDate,
  Value<bool> broken,
});
typedef $$ThesesTableUpdateCompanionBuilder = ThesesCompanion Function({
  Value<int> instrumentId,
  Value<String> whyBought,
  Value<String> breaksIf,
  Value<String?> reviewDate,
  Value<bool> broken,
});

class $$ThesesTableFilterComposer extends Composer<_$ProfileDb, $ThesesTable> {
  $$ThesesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get whyBought => $composableBuilder(
    column: $table.whyBought,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get breaksIf => $composableBuilder(
    column: $table.breaksIf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewDate => $composableBuilder(
    column: $table.reviewDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get broken => $composableBuilder(
    column: $table.broken,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ThesesTableOrderingComposer
    extends Composer<_$ProfileDb, $ThesesTable> {
  $$ThesesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get whyBought => $composableBuilder(
    column: $table.whyBought,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get breaksIf => $composableBuilder(
    column: $table.breaksIf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewDate => $composableBuilder(
    column: $table.reviewDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get broken => $composableBuilder(
    column: $table.broken,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ThesesTableAnnotationComposer
    extends Composer<_$ProfileDb, $ThesesTable> {
  $$ThesesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get whyBought =>
      $composableBuilder(column: $table.whyBought, builder: (column) => column);

  GeneratedColumn<String> get breaksIf =>
      $composableBuilder(column: $table.breaksIf, builder: (column) => column);

  GeneratedColumn<String> get reviewDate => $composableBuilder(
    column: $table.reviewDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get broken =>
      $composableBuilder(column: $table.broken, builder: (column) => column);
}

class $$ThesesTableTableManager
    extends
        RootTableManager<
          _$ProfileDb,
          $ThesesTable,
          Thesis,
          $$ThesesTableFilterComposer,
          $$ThesesTableOrderingComposer,
          $$ThesesTableAnnotationComposer,
          $$ThesesTableCreateCompanionBuilder,
          $$ThesesTableUpdateCompanionBuilder,
          (Thesis, BaseReferences<_$ProfileDb, $ThesesTable, Thesis>),
          Thesis,
          PrefetchHooks Function()
        > {
  $$ThesesTableTableManager(_$ProfileDb db, $ThesesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ThesesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ThesesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ThesesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> instrumentId = const Value.absent(),
                Value<String> whyBought = const Value.absent(),
                Value<String> breaksIf = const Value.absent(),
                Value<String?> reviewDate = const Value.absent(),
                Value<bool> broken = const Value.absent(),
              }) => ThesesCompanion(
                instrumentId: instrumentId,
                whyBought: whyBought,
                breaksIf: breaksIf,
                reviewDate: reviewDate,
                broken: broken,
              ),
          createCompanionCallback:
              ({
                Value<int> instrumentId = const Value.absent(),
                required String whyBought,
                required String breaksIf,
                Value<String?> reviewDate = const Value.absent(),
                Value<bool> broken = const Value.absent(),
              }) => ThesesCompanion.insert(
                instrumentId: instrumentId,
                whyBought: whyBought,
                breaksIf: breaksIf,
                reviewDate: reviewDate,
                broken: broken,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ThesesTable, Thesis>(table),
                  BaseReferences<_$ProfileDb, $ThesesTable, Thesis>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ThesesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProfileDb,
      $ThesesTable,
      Thesis,
      $$ThesesTableFilterComposer,
      $$ThesesTableOrderingComposer,
      $$ThesesTableAnnotationComposer,
      $$ThesesTableCreateCompanionBuilder,
      $$ThesesTableUpdateCompanionBuilder,
      (Thesis, BaseReferences<_$ProfileDb, $ThesesTable, Thesis>),
      Thesis,
      PrefetchHooks Function()
    >;
typedef $$SignalsTableCreateCompanionBuilder = SignalsCompanion Function({
  Value<int> id,
  required int instrumentId,
  required int rule,
  required DateTime createdAt,
  required String inputsJson,
  required String ruleVersion,
  required String status,
  Value<String?> userAction,
  Value<DateTime?> actedAt,
  Value<String> note,
});
typedef $$SignalsTableUpdateCompanionBuilder = SignalsCompanion Function({
  Value<int> id,
  Value<int> instrumentId,
  Value<int> rule,
  Value<DateTime> createdAt,
  Value<String> inputsJson,
  Value<String> ruleVersion,
  Value<String> status,
  Value<String?> userAction,
  Value<DateTime?> actedAt,
  Value<String> note,
});

class $$SignalsTableFilterComposer
    extends Composer<_$ProfileDb, $SignalsTable> {
  $$SignalsTableFilterComposer({
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

  ColumnFilters<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rule => $composableBuilder(
    column: $table.rule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputsJson => $composableBuilder(
    column: $table.inputsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleVersion => $composableBuilder(
    column: $table.ruleVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userAction => $composableBuilder(
    column: $table.userAction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actedAt => $composableBuilder(
    column: $table.actedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SignalsTableOrderingComposer
    extends Composer<_$ProfileDb, $SignalsTable> {
  $$SignalsTableOrderingComposer({
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

  ColumnOrderings<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rule => $composableBuilder(
    column: $table.rule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputsJson => $composableBuilder(
    column: $table.inputsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleVersion => $composableBuilder(
    column: $table.ruleVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userAction => $composableBuilder(
    column: $table.userAction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actedAt => $composableBuilder(
    column: $table.actedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SignalsTableAnnotationComposer
    extends Composer<_$ProfileDb, $SignalsTable> {
  $$SignalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rule =>
      $composableBuilder(column: $table.rule, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get inputsJson => $composableBuilder(
    column: $table.inputsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ruleVersion => $composableBuilder(
    column: $table.ruleVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get userAction => $composableBuilder(
    column: $table.userAction,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get actedAt =>
      $composableBuilder(column: $table.actedAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$SignalsTableTableManager
    extends
        RootTableManager<
          _$ProfileDb,
          $SignalsTable,
          Signal,
          $$SignalsTableFilterComposer,
          $$SignalsTableOrderingComposer,
          $$SignalsTableAnnotationComposer,
          $$SignalsTableCreateCompanionBuilder,
          $$SignalsTableUpdateCompanionBuilder,
          (Signal, BaseReferences<_$ProfileDb, $SignalsTable, Signal>),
          Signal,
          PrefetchHooks Function()
        > {
  $$SignalsTableTableManager(_$ProfileDb db, $SignalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> instrumentId = const Value.absent(),
                Value<int> rule = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> inputsJson = const Value.absent(),
                Value<String> ruleVersion = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> userAction = const Value.absent(),
                Value<DateTime?> actedAt = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => SignalsCompanion(
                id: id,
                instrumentId: instrumentId,
                rule: rule,
                createdAt: createdAt,
                inputsJson: inputsJson,
                ruleVersion: ruleVersion,
                status: status,
                userAction: userAction,
                actedAt: actedAt,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int instrumentId,
                required int rule,
                required DateTime createdAt,
                required String inputsJson,
                required String ruleVersion,
                required String status,
                Value<String?> userAction = const Value.absent(),
                Value<DateTime?> actedAt = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => SignalsCompanion.insert(
                id: id,
                instrumentId: instrumentId,
                rule: rule,
                createdAt: createdAt,
                inputsJson: inputsJson,
                ruleVersion: ruleVersion,
                status: status,
                userAction: userAction,
                actedAt: actedAt,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SignalsTable, Signal>(table),
                  BaseReferences<_$ProfileDb, $SignalsTable, Signal>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SignalsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProfileDb,
      $SignalsTable,
      Signal,
      $$SignalsTableFilterComposer,
      $$SignalsTableOrderingComposer,
      $$SignalsTableAnnotationComposer,
      $$SignalsTableCreateCompanionBuilder,
      $$SignalsTableUpdateCompanionBuilder,
      (Signal, BaseReferences<_$ProfileDb, $SignalsTable, Signal>),
      Signal,
      PrefetchHooks Function()
    >;
typedef $$AuditLogTableCreateCompanionBuilder = AuditLogCompanion Function({
  Value<int> id,
  required DateTime at,
  required String action,
  required String detail,
});
typedef $$AuditLogTableUpdateCompanionBuilder = AuditLogCompanion Function({
  Value<int> id,
  Value<DateTime> at,
  Value<String> action,
  Value<String> detail,
});

class $$AuditLogTableFilterComposer
    extends Composer<_$ProfileDb, $AuditLogTable> {
  $$AuditLogTableFilterComposer({
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

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditLogTableOrderingComposer
    extends Composer<_$ProfileDb, $AuditLogTable> {
  $$AuditLogTableOrderingComposer({
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

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditLogTableAnnotationComposer
    extends Composer<_$ProfileDb, $AuditLogTable> {
  $$AuditLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);
}

class $$AuditLogTableTableManager
    extends
        RootTableManager<
          _$ProfileDb,
          $AuditLogTable,
          AuditLogData,
          $$AuditLogTableFilterComposer,
          $$AuditLogTableOrderingComposer,
          $$AuditLogTableAnnotationComposer,
          $$AuditLogTableCreateCompanionBuilder,
          $$AuditLogTableUpdateCompanionBuilder,
          (
            AuditLogData,
            BaseReferences<_$ProfileDb, $AuditLogTable, AuditLogData>,
          ),
          AuditLogData,
          PrefetchHooks Function()
        > {
  $$AuditLogTableTableManager(_$ProfileDb db, $AuditLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> detail = const Value.absent(),
              }) => AuditLogCompanion(
                id: id,
                at: at,
                action: action,
                detail: detail,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required String action,
                required String detail,
              }) => AuditLogCompanion.insert(
                id: id,
                at: at,
                action: action,
                detail: detail,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AuditLogTable, AuditLogData>(table),
                  BaseReferences<_$ProfileDb, $AuditLogTable, AuditLogData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditLogTableProcessedTableManager =
    ProcessedTableManager<
      _$ProfileDb,
      $AuditLogTable,
      AuditLogData,
      $$AuditLogTableFilterComposer,
      $$AuditLogTableOrderingComposer,
      $$AuditLogTableAnnotationComposer,
      $$AuditLogTableCreateCompanionBuilder,
      $$AuditLogTableUpdateCompanionBuilder,
      (AuditLogData, BaseReferences<_$ProfileDb, $AuditLogTable, AuditLogData>),
      AuditLogData,
      PrefetchHooks Function()
    >;
typedef $$HoldingPrefsTableCreateCompanionBuilder =
    HoldingPrefsCompanion Function({
      Value<int> instrumentId,
      Value<String> bucket,
    });
typedef $$HoldingPrefsTableUpdateCompanionBuilder =
    HoldingPrefsCompanion Function({
      Value<int> instrumentId,
      Value<String> bucket,
    });

class $$HoldingPrefsTableFilterComposer
    extends Composer<_$ProfileDb, $HoldingPrefsTable> {
  $$HoldingPrefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bucket => $composableBuilder(
    column: $table.bucket,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HoldingPrefsTableOrderingComposer
    extends Composer<_$ProfileDb, $HoldingPrefsTable> {
  $$HoldingPrefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bucket => $composableBuilder(
    column: $table.bucket,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HoldingPrefsTableAnnotationComposer
    extends Composer<_$ProfileDb, $HoldingPrefsTable> {
  $$HoldingPrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bucket =>
      $composableBuilder(column: $table.bucket, builder: (column) => column);
}

class $$HoldingPrefsTableTableManager
    extends
        RootTableManager<
          _$ProfileDb,
          $HoldingPrefsTable,
          HoldingPref,
          $$HoldingPrefsTableFilterComposer,
          $$HoldingPrefsTableOrderingComposer,
          $$HoldingPrefsTableAnnotationComposer,
          $$HoldingPrefsTableCreateCompanionBuilder,
          $$HoldingPrefsTableUpdateCompanionBuilder,
          (
            HoldingPref,
            BaseReferences<_$ProfileDb, $HoldingPrefsTable, HoldingPref>,
          ),
          HoldingPref,
          PrefetchHooks Function()
        > {
  $$HoldingPrefsTableTableManager(_$ProfileDb db, $HoldingPrefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HoldingPrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HoldingPrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HoldingPrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> instrumentId = const Value.absent(),
                Value<String> bucket = const Value.absent(),
              }) => HoldingPrefsCompanion(
                instrumentId: instrumentId,
                bucket: bucket,
              ),
          createCompanionCallback:
              ({
                Value<int> instrumentId = const Value.absent(),
                Value<String> bucket = const Value.absent(),
              }) => HoldingPrefsCompanion.insert(
                instrumentId: instrumentId,
                bucket: bucket,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HoldingPrefsTable, HoldingPref>(table),
                  BaseReferences<_$ProfileDb, $HoldingPrefsTable, HoldingPref>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HoldingPrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProfileDb,
      $HoldingPrefsTable,
      HoldingPref,
      $$HoldingPrefsTableFilterComposer,
      $$HoldingPrefsTableOrderingComposer,
      $$HoldingPrefsTableAnnotationComposer,
      $$HoldingPrefsTableCreateCompanionBuilder,
      $$HoldingPrefsTableUpdateCompanionBuilder,
      (
        HoldingPref,
        BaseReferences<_$ProfileDb, $HoldingPrefsTable, HoldingPref>,
      ),
      HoldingPref,
      PrefetchHooks Function()
    >;
typedef $$ProfileSettingsTableCreateCompanionBuilder =
    ProfileSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$ProfileSettingsTableUpdateCompanionBuilder =
    ProfileSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$ProfileSettingsTableFilterComposer
    extends Composer<_$ProfileDb, $ProfileSettingsTable> {
  $$ProfileSettingsTableFilterComposer({
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

class $$ProfileSettingsTableOrderingComposer
    extends Composer<_$ProfileDb, $ProfileSettingsTable> {
  $$ProfileSettingsTableOrderingComposer({
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

class $$ProfileSettingsTableAnnotationComposer
    extends Composer<_$ProfileDb, $ProfileSettingsTable> {
  $$ProfileSettingsTableAnnotationComposer({
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

class $$ProfileSettingsTableTableManager
    extends
        RootTableManager<
          _$ProfileDb,
          $ProfileSettingsTable,
          ProfileSetting,
          $$ProfileSettingsTableFilterComposer,
          $$ProfileSettingsTableOrderingComposer,
          $$ProfileSettingsTableAnnotationComposer,
          $$ProfileSettingsTableCreateCompanionBuilder,
          $$ProfileSettingsTableUpdateCompanionBuilder,
          (
            ProfileSetting,
            BaseReferences<_$ProfileDb, $ProfileSettingsTable, ProfileSetting>,
          ),
          ProfileSetting,
          PrefetchHooks Function()
        > {
  $$ProfileSettingsTableTableManager(
    _$ProfileDb db,
    $ProfileSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => ProfileSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => ProfileSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfileSettingsTable, ProfileSetting>(table),
                  BaseReferences<
                    _$ProfileDb,
                    $ProfileSettingsTable,
                    ProfileSetting
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfileSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProfileDb,
      $ProfileSettingsTable,
      ProfileSetting,
      $$ProfileSettingsTableFilterComposer,
      $$ProfileSettingsTableOrderingComposer,
      $$ProfileSettingsTableAnnotationComposer,
      $$ProfileSettingsTableCreateCompanionBuilder,
      $$ProfileSettingsTableUpdateCompanionBuilder,
      (
        ProfileSetting,
        BaseReferences<_$ProfileDb, $ProfileSettingsTable, ProfileSetting>,
      ),
      ProfileSetting,
      PrefetchHooks Function()
    >;
typedef $$PaperTradesTableCreateCompanionBuilder =
    PaperTradesCompanion Function({
      Value<int> id,
      required int instrumentId,
      required String date,
      required String type,
      required int unitsE4,
      required int priceE4,
      Value<String> reason,
    });
typedef $$PaperTradesTableUpdateCompanionBuilder =
    PaperTradesCompanion Function({
      Value<int> id,
      Value<int> instrumentId,
      Value<String> date,
      Value<String> type,
      Value<int> unitsE4,
      Value<int> priceE4,
      Value<String> reason,
    });

class $$PaperTradesTableFilterComposer
    extends Composer<_$ProfileDb, $PaperTradesTable> {
  $$PaperTradesTableFilterComposer({
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

  ColumnFilters<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitsE4 => $composableBuilder(
    column: $table.unitsE4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceE4 => $composableBuilder(
    column: $table.priceE4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaperTradesTableOrderingComposer
    extends Composer<_$ProfileDb, $PaperTradesTable> {
  $$PaperTradesTableOrderingComposer({
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

  ColumnOrderings<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitsE4 => $composableBuilder(
    column: $table.unitsE4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceE4 => $composableBuilder(
    column: $table.priceE4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaperTradesTableAnnotationComposer
    extends Composer<_$ProfileDb, $PaperTradesTable> {
  $$PaperTradesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get unitsE4 =>
      $composableBuilder(column: $table.unitsE4, builder: (column) => column);

  GeneratedColumn<int> get priceE4 =>
      $composableBuilder(column: $table.priceE4, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);
}

class $$PaperTradesTableTableManager
    extends
        RootTableManager<
          _$ProfileDb,
          $PaperTradesTable,
          PaperTrade,
          $$PaperTradesTableFilterComposer,
          $$PaperTradesTableOrderingComposer,
          $$PaperTradesTableAnnotationComposer,
          $$PaperTradesTableCreateCompanionBuilder,
          $$PaperTradesTableUpdateCompanionBuilder,
          (
            PaperTrade,
            BaseReferences<_$ProfileDb, $PaperTradesTable, PaperTrade>,
          ),
          PaperTrade,
          PrefetchHooks Function()
        > {
  $$PaperTradesTableTableManager(_$ProfileDb db, $PaperTradesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaperTradesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaperTradesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaperTradesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> instrumentId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> unitsE4 = const Value.absent(),
                Value<int> priceE4 = const Value.absent(),
                Value<String> reason = const Value.absent(),
              }) => PaperTradesCompanion(
                id: id,
                instrumentId: instrumentId,
                date: date,
                type: type,
                unitsE4: unitsE4,
                priceE4: priceE4,
                reason: reason,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int instrumentId,
                required String date,
                required String type,
                required int unitsE4,
                required int priceE4,
                Value<String> reason = const Value.absent(),
              }) => PaperTradesCompanion.insert(
                id: id,
                instrumentId: instrumentId,
                date: date,
                type: type,
                unitsE4: unitsE4,
                priceE4: priceE4,
                reason: reason,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PaperTradesTable, PaperTrade>(table),
                  BaseReferences<_$ProfileDb, $PaperTradesTable, PaperTrade>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaperTradesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProfileDb,
      $PaperTradesTable,
      PaperTrade,
      $$PaperTradesTableFilterComposer,
      $$PaperTradesTableOrderingComposer,
      $$PaperTradesTableAnnotationComposer,
      $$PaperTradesTableCreateCompanionBuilder,
      $$PaperTradesTableUpdateCompanionBuilder,
      (PaperTrade, BaseReferences<_$ProfileDb, $PaperTradesTable, PaperTrade>),
      PaperTrade,
      PrefetchHooks Function()
    >;
typedef $$WatchlistTableCreateCompanionBuilder = WatchlistCompanion Function({
  Value<int> instrumentId,
  required DateTime addedAt,
});
typedef $$WatchlistTableUpdateCompanionBuilder = WatchlistCompanion Function({
  Value<int> instrumentId,
  Value<DateTime> addedAt,
});

class $$WatchlistTableFilterComposer
    extends Composer<_$ProfileDb, $WatchlistTable> {
  $$WatchlistTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WatchlistTableOrderingComposer
    extends Composer<_$ProfileDb, $WatchlistTable> {
  $$WatchlistTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WatchlistTableAnnotationComposer
    extends Composer<_$ProfileDb, $WatchlistTable> {
  $$WatchlistTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get instrumentId => $composableBuilder(
    column: $table.instrumentId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$WatchlistTableTableManager
    extends
        RootTableManager<
          _$ProfileDb,
          $WatchlistTable,
          Watch,
          $$WatchlistTableFilterComposer,
          $$WatchlistTableOrderingComposer,
          $$WatchlistTableAnnotationComposer,
          $$WatchlistTableCreateCompanionBuilder,
          $$WatchlistTableUpdateCompanionBuilder,
          (Watch, BaseReferences<_$ProfileDb, $WatchlistTable, Watch>),
          Watch,
          PrefetchHooks Function()
        > {
  $$WatchlistTableTableManager(_$ProfileDb db, $WatchlistTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchlistTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchlistTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchlistTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> instrumentId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => WatchlistCompanion(
                instrumentId: instrumentId,
                addedAt: addedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> instrumentId = const Value.absent(),
                required DateTime addedAt,
              }) => WatchlistCompanion.insert(
                instrumentId: instrumentId,
                addedAt: addedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WatchlistTable, Watch>(table),
                  BaseReferences<_$ProfileDb, $WatchlistTable, Watch>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WatchlistTableProcessedTableManager =
    ProcessedTableManager<
      _$ProfileDb,
      $WatchlistTable,
      Watch,
      $$WatchlistTableFilterComposer,
      $$WatchlistTableOrderingComposer,
      $$WatchlistTableAnnotationComposer,
      $$WatchlistTableCreateCompanionBuilder,
      $$WatchlistTableUpdateCompanionBuilder,
      (Watch, BaseReferences<_$ProfileDb, $WatchlistTable, Watch>),
      Watch,
      PrefetchHooks Function()
    >;

class $ProfileDbManager {
  final _$ProfileDb _db;
  $ProfileDbManager(this._db);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$SipPlansTableTableManager get sipPlans =>
      $$SipPlansTableTableManager(_db, _db.sipPlans);
  $$ThesesTableTableManager get theses =>
      $$ThesesTableTableManager(_db, _db.theses);
  $$SignalsTableTableManager get signals =>
      $$SignalsTableTableManager(_db, _db.signals);
  $$AuditLogTableTableManager get auditLog =>
      $$AuditLogTableTableManager(_db, _db.auditLog);
  $$HoldingPrefsTableTableManager get holdingPrefs =>
      $$HoldingPrefsTableTableManager(_db, _db.holdingPrefs);
  $$ProfileSettingsTableTableManager get profileSettings =>
      $$ProfileSettingsTableTableManager(_db, _db.profileSettings);
  $$PaperTradesTableTableManager get paperTrades =>
      $$PaperTradesTableTableManager(_db, _db.paperTrades);
  $$WatchlistTableTableManager get watchlist =>
      $$WatchlistTableTableManager(_db, _db.watchlist);
}
