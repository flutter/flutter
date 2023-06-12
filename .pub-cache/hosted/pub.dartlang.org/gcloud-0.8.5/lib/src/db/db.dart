// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of gcloud.db;

/// A function definition for transactional functions.
///
/// The function will be given a [Transaction] object which can be used to make
/// lookups/queries and queue modifications (inserts/updates/deletes).
typedef TransactionHandler<T> = Future<T> Function(Transaction transaction);

/// A datastore transaction.
///
/// It can be used for making lookups/queries and queue modifications
/// (inserts/updates/deletes). Finally the transaction can be either committed
/// or rolled back.
class Transaction {
  static const int _transactionStarted = 0;
  static const int _transactionRolledBack = 1;
  static const int _transactionCommitted = 2;
  static const int _transactionCommitFailed = 3;

  final DatastoreDB db;
  final ds.Transaction _datastoreTransaction;

  final List<Model> _inserts = [];
  final List<Key> _deletes = [];

  int _state = _transactionStarted;

  Transaction(this.db, this._datastoreTransaction);

  /// Looks up [keys] within this transaction.
  Future<List<T?>> lookup<T extends Model>(List<Key> keys) {
    return _lookupHelper<T>(
      db,
      keys,
      datastoreTransaction: _datastoreTransaction,
    );
  }

  /// Looks up a single [key] within this transaction, and returns the
  /// associated [Model] object.
  ///
  /// If [orElse] is specified, then it will be consulted to provide a default
  /// value for the model object in the event that [key] was not found within
  /// the transaction.
  ///
  /// If the [key] is not found within the transaction and [orElse] was not
  /// specified, then a [KeyNotFoundException] will be thrown.
  Future<T> lookupValue<T extends Model>(Key key,
      {T Function()? orElse}) async {
    final values = await lookup<T>(<Key>[key]);
    assert(values.length == 1);
    var value = values.single;
    if (value == null) {
      if (orElse != null) {
        value = orElse();
      } else {
        throw KeyNotFoundException(key);
      }
    }
    return value;
  }

  /// Looks up a single [key] in the datastore, and returns the associated
  /// [Model] object.
  ///
  /// If the [key] is not found in the datastore, null will be returned.
  Future<T?> lookupOrNull<T extends Model>(Key key) async {
    final values = await lookup<T>(<Key>[key]);
    assert(values.length == 1);
    return values.single;
  }

  /// Enqueues [inserts] and [deletes] which should be committed at commit time.
  void queueMutations({List<Model>? inserts, List<Key>? deletes}) {
    _checkSealed();
    if (inserts != null) {
      _inserts.addAll(inserts);
    }
    if (deletes != null) {
      _deletes.addAll(deletes);
    }
  }

  /// Query for [kind] models with [ancestorKey].
  ///
  /// Note that [ancestorKey] is required, since a transaction is not allowed to
  /// touch/look at an arbitrary number of rows.
  Query<T> query<T extends Model>(Key ancestorKey, {Partition? partition}) {
    // TODO(#25): The `partition` element is redundant and should be removed.
    if (partition == null) {
      partition = ancestorKey.partition;
    } else if (ancestorKey.partition != partition) {
      throw ArgumentError(
          'Ancestor queries must have the same partition in the ancestor key '
          'as the partition where the query executes in.');
    }
    _checkSealed();
    return Query<T>(db,
        partition: partition,
        ancestorKey: ancestorKey,
        datastoreTransaction: _datastoreTransaction);
  }

  /// Rolls this transaction back.
  Future rollback() {
    _checkSealed(changeState: _transactionRolledBack, allowFailed: true);
    return db.datastore.rollback(_datastoreTransaction);
  }

  /// Commits this transaction including all of the queued mutations.
  Future commit() {
    _checkSealed(changeState: _transactionCommitted);
    try {
      return _commitHelper(db,
          inserts: _inserts,
          deletes: _deletes,
          datastoreTransaction: _datastoreTransaction);
    } catch (error) {
      _state = _transactionCommitFailed;
      rethrow;
    }
  }

  void _checkSealed({int? changeState, bool allowFailed = false}) {
    if (_state == _transactionCommitted) {
      throw StateError('The transaction has already been committed.');
    } else if (_state == _transactionRolledBack) {
      throw StateError('The transaction has already been rolled back.');
    } else if (_state == _transactionCommitFailed && !allowFailed) {
      throw StateError('The transaction has attempted commit and failed.');
    }
    if (changeState != null) {
      _state = changeState;
    }
  }
}

class Query<T extends Model> {
  final _relationMapping = const <String, ds.FilterRelation>{
    '<': ds.FilterRelation.LessThan,
    '<=': ds.FilterRelation.LessThanOrEqual,
    '>': ds.FilterRelation.GreatherThan,
    '>=': ds.FilterRelation.GreatherThanOrEqual,
    '=': ds.FilterRelation.Equal,
  };

  final DatastoreDB _db;
  final ds.Transaction? _transaction;
  final String _kind;

  final Partition? _partition;
  final Key? _ancestorKey;

  final List<ds.Filter> _filters = [];
  final List<ds.Order> _orders = [];
  int? _offset;
  int? _limit;

  Query(DatastoreDB dbImpl,
      {Partition? partition,
      Key? ancestorKey,
      ds.Transaction? datastoreTransaction})
      : _db = dbImpl,
        _kind = dbImpl.modelDB.kindName(T),
        _partition = partition,
        _ancestorKey = ancestorKey,
        _transaction = datastoreTransaction;

  /// Adds a filter to this [Query].
  ///
  /// [filterString] has form "name OP" where 'name' is a fieldName of the
  /// model and OP is an operator. The following operators are supported:
  ///
  ///   * '<' (less than)
  ///   * '<=' (less than or equal)
  ///   * '>' (greater than)
  ///   * '>=' (greater than or equal)
  ///   * '=' (equal)
  ///
  /// [comparisonObject] is the object for comparison.
  void filter(String filterString, Object? comparisonObject) {
    var parts = filterString.split(' ');
    if (parts.length != 2 || !_relationMapping.containsKey(parts[1])) {
      throw ArgumentError("Invalid filter string '$filterString'.");
    }

    var name = parts[0];
    var comparison = parts[1];
    var propertyName = _convertToDatastoreName(name);

    // This is for backwards compatibility: We allow [datastore.Key]s for now.
    // TODO: We should remove the condition in a major version update of
    // `package:gcloud`.
    if (comparisonObject is! ds.Key) {
      comparisonObject = _db.modelDB
          .toDatastoreValue(_kind, name, comparisonObject, forComparison: true);
    }
    _filters.add(ds.Filter(
        _relationMapping[comparison]!, propertyName, comparisonObject!));
  }

  /// Adds an order to this [Query].
  ///
  /// [orderString] has the form "-name" where 'name' is a fieldName of the model
  /// and the optional '-' says whether the order is descending or ascending.
  void order(String orderString) {
    // TODO: validate [orderString] (e.g. is name valid)
    if (orderString.startsWith('-')) {
      _orders.add(ds.Order(ds.OrderDirection.Decending,
          _convertToDatastoreName(orderString.substring(1))));
    } else {
      _orders.add(ds.Order(
          ds.OrderDirection.Ascending, _convertToDatastoreName(orderString)));
    }
  }

  /// Sets the [offset] of this [Query].
  ///
  /// When running this query, [offset] results will be skipped.
  void offset(int offset) {
    _offset = offset;
  }

  /// Sets the [limit] of this [Query].
  ///
  /// When running this query, a maximum of [limit] results will be returned.
  void limit(int limit) {
    _limit = limit;
  }

  /// Execute this [Query] on the datastore.
  ///
  /// Outside of transactions this method might return stale data or may not
  /// return the newest updates performed on the datastore since updates
  /// will be reflected in the indices in an eventual consistent way.
  Stream<T> run() {
    ds.Key? ancestorKey;
    if (_ancestorKey != null) {
      ancestorKey = _db.modelDB.toDatastoreKey(_ancestorKey!);
    }
    var query = ds.Query(
        ancestorKey: ancestorKey,
        kind: _kind,
        filters: _filters,
        orders: _orders,
        offset: _offset,
        limit: _limit);

    ds.Partition? partition;
    if (_partition != null) {
      partition = ds.Partition(_partition!.namespace);
    }

    return StreamFromPages<ds.Entity>((int pageSize) {
      if (_transaction != null) {
        if (partition != null) {
          return _db.datastore
              .query(query, transaction: _transaction!, partition: partition);
        }
        return _db.datastore.query(query, transaction: _transaction!);
      }
      if (partition != null) {
        return _db.datastore.query(query, partition: partition);
      }
      return _db.datastore.query(query);
    }).stream.map<T>((e) => _db.modelDB.fromDatastoreEntity(e)!);
  }

  // TODO:
  // - add runPaged() returning Page<Model>
  // - add run*() method once we have EntityResult{Entity,Cursor} in low-level
  //   API.

  String _convertToDatastoreName(String name) {
    var propertyName = _db.modelDB.fieldNameToPropertyName(_kind, name);
    if (propertyName == null) {
      throw ArgumentError('Field $name is not available for kind $_kind');
    }
    return propertyName;
  }
}

class DatastoreDB {
  final ds.Datastore datastore;
  final ModelDB _modelDB;
  final Partition _defaultPartition;

  DatastoreDB(this.datastore, {ModelDB? modelDB, Partition? defaultPartition})
      : _modelDB = modelDB ?? ModelDBImpl(),
        _defaultPartition = defaultPartition ?? Partition(null);

  /// The [ModelDB] used to serialize/deserialize objects.
  ModelDB get modelDB => _modelDB;

  /// Gets the empty key using the default [Partition].
  ///
  /// Model keys with parent set to [emptyKey] will create their own entity
  /// groups.
  Key get emptyKey => defaultPartition.emptyKey;

  /// Gets the default [Partition].
  Partition get defaultPartition => _defaultPartition;

  /// Creates a new [Partition] with namespace [namespace].
  Partition newPartition(String namespace) {
    return Partition(namespace);
  }

  /// Begins a new a new transaction.
  ///
  /// A transaction can touch only a limited number of entity groups. This limit
  /// is currently 5.
  // TODO: Add retries and/or auto commit/rollback.
  Future<T> withTransaction<T>(TransactionHandler<T> transactionHandler) {
    return datastore
        .beginTransaction(crossEntityGroup: true)
        .then((datastoreTransaction) {
      var transaction = Transaction(this, datastoreTransaction);
      return transactionHandler(transaction);
    });
  }

  /// Build a query for [kind] models.
  Query<T> query<T extends Model>({Partition? partition, Key? ancestorKey}) {
    // TODO(#26): There is only one case where `partition` is not redundant
    // Namely if `ancestorKey == null` and `partition != null`. We could
    // say we get rid of `partition` and enforce `ancestorKey` to
    // be `Partition.emptyKey`?
    if (partition == null) {
      if (ancestorKey != null) {
        partition = ancestorKey.partition;
      } else {
        partition = defaultPartition;
      }
    } else if (ancestorKey != null && partition != ancestorKey.partition) {
      throw ArgumentError(
          'Ancestor queries must have the same partition in the ancestor key '
          'as the partition where the query executes in.');
    }
    return Query<T>(this, partition: partition, ancestorKey: ancestorKey);
  }

  /// Looks up [keys] in the datastore and returns a list of [Model] objects.
  ///
  /// Any key that is not found in the datastore will have a corresponding
  /// value of null in the list of model objects that is returned.
  ///
  /// For transactions, please use [beginTransaction] and call the [lookup]
  /// method on it's returned [Transaction] object.
  ///
  /// See also:
  ///
  ///  * [lookupValue], which looks a single value up by its key, requiring a
  ///    successful lookup.
  Future<List<T?>> lookup<T extends Model>(List<Key> keys) {
    return _lookupHelper<T>(this, keys);
  }

  /// Looks up a single [key] in the datastore, and returns the associated
  /// [Model] object.
  ///
  /// If [orElse] is specified, then it will be consulted to provide a default
  /// value for the model object in the event that [key] was not found in the
  /// datastore.
  ///
  /// If the [key] is not found in the datastore and [orElse] was not
  /// specified, then a [KeyNotFoundException] will be thrown.
  Future<T> lookupValue<T extends Model>(Key key,
      {T Function()? orElse}) async {
    final values = await lookup<T>(<Key>[key]);
    assert(values.length == 1);
    var value = values.single;
    if (value == null) {
      if (orElse != null) {
        value = orElse();
      } else {
        throw KeyNotFoundException(key);
      }
    }
    return value;
  }

  /// Looks up a single [key] in the datastore, and returns the associated
  /// [Model] object.
  ///
  /// If the [key] is not found in the datastore, null will be returned.
  Future<T?> lookupOrNull<T extends Model>(Key key) async {
    final values = await lookup<T>(<Key>[key]);
    assert(values.length == 1);
    return values.single;
  }

  /// Add [inserts] to the datastore and remove [deletes] from it.
  ///
  /// The order of inserts and deletes is not specified. When the commit is done
  /// direct lookups will see the effect but non-ancestor queries will see the
  /// change in an eventual consistent way.
  ///
  /// For transactions, please use `beginTransaction` and it's returned
  /// [Transaction] object.
  Future commit({List<Model>? inserts, List<Key>? deletes}) {
    return _commitHelper(this, inserts: inserts, deletes: deletes);
  }
}

Future _commitHelper(DatastoreDB db,
    {List<Model>? inserts,
    List<Key>? deletes,
    ds.Transaction? datastoreTransaction}) {
  List<ds.Entity>? entityInserts, entityAutoIdInserts;
  List<ds.Key>? entityDeletes;
  late List<Model> autoIdModelInserts;
  if (inserts != null) {
    entityInserts = <ds.Entity>[];
    entityAutoIdInserts = <ds.Entity>[];
    autoIdModelInserts = <Model>[];

    for (var model in inserts) {
      // If parent was not explicitly set, we assume this model will map to
      // it's own entity group.
      model.parentKey ??= db.defaultPartition.emptyKey;
      if (model.id == null) {
        autoIdModelInserts.add(model);
        entityAutoIdInserts.add(db.modelDB.toDatastoreEntity(model));
      } else {
        entityInserts.add(db.modelDB.toDatastoreEntity(model));
      }
    }
  }
  if (deletes != null) {
    entityDeletes = deletes.map(db.modelDB.toDatastoreKey).toList();
  }
  Future<ds.CommitResult> r;
  if (datastoreTransaction != null) {
    r = db.datastore.commit(
        inserts: entityInserts ?? [],
        autoIdInserts: entityAutoIdInserts ?? [],
        deletes: entityDeletes ?? [],
        transaction: datastoreTransaction);
  } else {
    r = db.datastore.commit(
        inserts: entityInserts ?? [],
        autoIdInserts: entityAutoIdInserts ?? [],
        deletes: entityDeletes ?? []);
  }

  return r.then((ds.CommitResult result) {
    if (entityAutoIdInserts != null && entityAutoIdInserts.isNotEmpty) {
      for (var i = 0; i < result.autoIdInsertKeys.length; i++) {
        var key = db.modelDB.fromDatastoreKey(result.autoIdInsertKeys[i]);
        autoIdModelInserts[i].parentKey = key.parent;
        autoIdModelInserts[i].id = key.id;
      }
    }
  });
}

Future<List<T?>> _lookupHelper<T extends Model>(DatastoreDB db, List<Key> keys,
    {ds.Transaction? datastoreTransaction}) {
  var entityKeys = keys.map(db.modelDB.toDatastoreKey).toList();

  if (datastoreTransaction != null) {
    return db.datastore
        .lookup(entityKeys, transaction: datastoreTransaction)
        .then((List<ds.Entity?> entities) {
      return entities.map<T?>(db.modelDB.fromDatastoreEntity).toList();
    });
  }
  return db.datastore.lookup(entityKeys).then((List<ds.Entity?> entities) {
    return entities.map<T?>(db.modelDB.fromDatastoreEntity).toList();
  });
}
