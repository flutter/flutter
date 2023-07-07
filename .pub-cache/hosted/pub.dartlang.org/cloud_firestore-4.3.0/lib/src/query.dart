// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

/// Represents a [Query] over the data at a particular location.
///
/// Can construct refined [Query] objects by adding filters and ordering.
// `extends Object?` so that type inference defaults to `Object?` instead of `dynamic`
@sealed
@immutable
abstract class Query<T extends Object?> {
  /// The [FirebaseFirestore] instance of this query.
  FirebaseFirestore get firestore;

  /// Exposes the [parameters] on the query delegate.
  ///
  /// This should only be used for testing to ensure that all
  /// query modifiers are correctly set on the underlying delegate
  /// when being tested from a different package.
  Map<String, dynamic> get parameters;

  /// Creates and returns a new [Query] that ends at the provided document
  /// (inclusive). The end position is relative to the order of the query.
  /// The document must contain all of the fields provided in the orderBy of
  /// this query.
  ///
  /// Cannot be used in combination with [endBefore], [endBeforeDocument], or
  /// [endAt], but can be used in combination with [startAt],
  /// [startAfter], [startAtDocument] and [startAfterDocument].
  ///
  /// See also:
  ///
  ///  * [startAfterDocument] for a query that starts after a document.
  ///  * [startAtDocument] for a query that starts at a document.
  ///  * [endBeforeDocument] for a query that ends before a document.
  Query<T> endAtDocument(
    // Voluntarily accepts any DocumentSnapshot<T>
    DocumentSnapshot documentSnapshot,
  );

  /// Takes a list of [values], creates and returns a new [Query] that ends at the
  /// provided fields relative to the order of the query.
  ///
  /// The [values] must be in order of [orderBy] filters.
  ///
  /// Calling this method will replace any existing cursor "end" query modifiers.
  Query<T> endAt(List<Object?> values);

  /// Creates and returns a new [Query] that ends before the provided document
  /// snapshot (exclusive). The end position is relative to the order of the query.
  /// The document must contain all of the fields provided in the orderBy of
  /// this query.
  ///
  /// Calling this method will replace any existing cursor "end" query modifiers.
  Query<T> endBeforeDocument(
    // Voluntarily accepts any DocumentSnapshot<T>
    DocumentSnapshot documentSnapshot,
  );

  /// Takes a list of [values], creates and returns a new [Query] that ends before
  /// the provided fields relative to the order of the query.
  ///
  /// The [values] must be in order of [orderBy] filters.
  ///
  /// Calling this method will replace any existing cursor "end" query modifiers.
  Query<T> endBefore(List<Object?> values);

  /// Fetch the documents for this query.
  ///
  /// To modify how the query is fetched, the [options] parameter can be provided
  /// with a [GetOptions] instance.
  Future<QuerySnapshot<T>> get([GetOptions? options]);

  /// Creates and returns a new Query that's additionally limited to only return up
  /// to the specified number of documents.
  Query<T> limit(int limit);

  /// Creates and returns a new Query that only returns the last matching documents.
  ///
  /// You must specify at least one orderBy clause for limitToLast queries,
  /// otherwise an exception will be thrown during execution.
  Query<T> limitToLast(int limit);

  /// Notifies of query results at this location.
  Stream<QuerySnapshot<T>> snapshots({bool includeMetadataChanges = false});

  /// Creates and returns a new [Query] that's additionally sorted by the specified
  /// [field].
  /// The field may be a [String] representing a single field name or a [FieldPath].
  ///
  /// After a [FieldPath.documentId] order by call, you cannot add any more [orderBy]
  /// calls.
  ///
  /// Furthermore, you may not use [orderBy] on the [FieldPath.documentId] [field] when
  /// using [startAfterDocument], [startAtDocument], [endBeforeDocument],
  /// or [endAtDocument] because the order by clause on the document id
  /// is added by these methods implicitly.
  Query<T> orderBy(Object field, {bool descending = false});

  /// Creates and returns a new [Query] that starts after the provided document
  /// (exclusive). The starting position is relative to the order of the query.
  /// The [documentSnapshot] must contain all of the fields provided in the orderBy of
  /// this query.
  ///
  /// Calling this method will replace any existing cursor "start" query modifiers.
  Query<T> startAfterDocument(
    // Voluntarily accepts any DocumentSnapshot<T>
    DocumentSnapshot documentSnapshot,
  );

  /// Takes a list of [values], creates and returns a new [Query] that starts
  /// after the provided fields relative to the order of the query.
  ///
  /// The [values] must be in order of [orderBy] filters.
  ///
  /// Calling this method will replace any existing cursor "start" query modifiers.
  Query<T> startAfter(List<Object?> values);

  /// Creates and returns a new [Query] that starts at the provided document
  /// (inclusive). The starting position is relative to the order of the query.
  /// The document must contain all of the fields provided in the orderBy of
  /// this query.
  ///
  /// Calling this method will replace any existing cursor "start" query modifiers.
  Query<T> startAtDocument(
    // Voluntarily accepts any DocumentSnapshot<T>
    DocumentSnapshot documentSnapshot,
  );

  /// Takes a list of [values], creates and returns a new [Query] that starts at
  /// the provided fields relative to the order of the query.
  ///
  /// The [values] must be in order of [orderBy] filters.
  ///
  /// Calling this method will replace any existing cursor "start" query modifiers.
  Query<T> startAt(List<Object?> values);

  /// Creates and returns a new [Query] with additional filter on specified
  /// [field]. [field] refers to a field in a document.
  ///
  /// The [field] may be a [String] consisting of a single field name
  /// (referring to a top level field in the document),
  /// or a series of field names separated by dots '.'
  /// (referring to a nested field in the document).
  /// Alternatively, the [field] can also be a [FieldPath].
  ///
  /// Only documents satisfying provided condition are included in the result
  /// set.
  Query<T> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    List<Object?>? arrayContainsAny,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
    bool? isNull,
  });

  /// Transforms a [Query] to manipulate a custom object instead
  /// of a `Map<String, dynamic>`.
  ///
  /// This makes both read and write operations type-safe.
  ///
  /// ```dart
  /// final personsRef = FirebaseFirestore
  ///     .instance
  ///     .collection('persons')
  ///     .where('age', isGreaterThan: 0)
  ///     .withConverter<Person>(
  ///       fromFirestore: (snapshot, _) => Person.fromJson(snapshot.data()!),
  ///       toFirestore: (person, _) => person.toJson(),
  ///     );
  ///
  /// Future<void> main() async {
  ///   List<QuerySnapshot<Person>> persons = await personsRef.get().then((s) => s.docs);
  /// }
  /// ```
  Query<R> withConverter<R>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  });

  AggregateQuery count();
}

/// Represents a [Query] over the data at a particular location.
///
/// Can construct refined [Query] objects by adding filters and ordering.
class _JsonQuery implements Query<Map<String, dynamic>> {
  _JsonQuery(
    this.firestore,
    this._delegate,
  ) {
    QueryPlatform.verify(_delegate);
  }

  @override
  final FirebaseFirestore firestore;

  final QueryPlatform _delegate;

  /// Exposes the [parameters] on the query delegate.
  ///
  /// This should only be used for testing to ensure that all
  /// query modifiers are correctly set on the underlying delegate
  /// when being tested from a different package.
  @override
  Map<String, dynamic> get parameters {
    return _delegate.parameters;
  }

  /// Returns whether the current query has a "start" cursor query.
  bool _hasStartCursor() {
    return parameters['startAt'] != null || parameters['startAfter'] != null;
  }

  /// Returns whether the current query has a "end" cursor query.
  bool _hasEndCursor() {
    return parameters['endAt'] != null || parameters['endBefore'] != null;
  }

  /// Returns whether the current operator is an inequality operator.
  bool _isInequality(String operator) {
    return operator == '<' ||
        operator == '<=' ||
        operator == '>' ||
        operator == '>=' ||
        operator == '!=';
  }

  bool isNotIn(String operator) {
    return operator == 'not-in';
  }

  /// Asserts that a [DocumentSnapshot] can be used within the current
  /// query.
  ///
  /// Since a native DocumentSnapshot cannot be created without additional
  /// database calls, any ordered values are extracted from the document and
  /// passed to the query.
  Map<String, dynamic> _assertQueryCursorSnapshot(
    DocumentSnapshot documentSnapshot,
  ) {
    assert(
      documentSnapshot.exists,
      'a document snapshot must exist to be used within a query',
    );

    List<List<dynamic>> orders = List.from(parameters['orderBy']);
    List<dynamic> values = [];

    for (final List<dynamic> order in orders) {
      dynamic field = order[0];

      // All order by fields must exist within the snapshot
      if (field != FieldPath.documentId) {
        try {
          values.add(documentSnapshot.get(field));
        } on StateError {
          throw "You are trying to start or end a query using a document for which the field '$field' (used as the orderBy) does not exist.";
        }
      }
    }

    // Any time you construct a query and don't include 'name' in the orderBys,
    // Firestore will implicitly assume an additional .orderBy('__name__', DIRECTION)
    // where DIRECTION will match the last orderBy direction of your query (or 'asc' if you have no orderBys).
    if (orders.isNotEmpty) {
      List<dynamic> lastOrder = orders.last;

      if (lastOrder[0] != FieldPath.documentId) {
        orders.add([FieldPath.documentId, lastOrder[1]]);
      }
    } else {
      orders.add([FieldPath.documentId, false]);
    }

    if (_delegate.isCollectionGroupQuery) {
      values.add(documentSnapshot.reference.path);
    } else {
      values.add(documentSnapshot.id);
    }

    return <String, dynamic>{
      'orders': orders,
      'values': values,
    };
  }

  /// Common handler for all non-document based cursor queries.
  List<dynamic> _assertQueryCursorValues(List<Object?> fields) {
    List<List<Object?>> orders = List.from(parameters['orderBy']);

    assert(
      fields.length <= orders.length,
      'Too many arguments provided. '
      'The number of arguments must be less than or equal to the number of orderBy() clauses.',
    );

    return fields;
  }

  /// Asserts that the query [field] is either a String or a [FieldPath].
  void _assertValidFieldType(Object field) {
    assert(
      field is String || field is FieldPath || field == FieldPath.documentId,
      'Supported [field] types are [String] and [FieldPath].',
    );
  }

  /// Creates and returns a new [Query] that ends at the provided document
  /// (inclusive). The end position is relative to the order of the query.
  /// The document must contain all of the fields provided in the orderBy of
  /// this query.
  ///
  /// Cannot be used in combination with [endBefore], [endBeforeDocument], or
  /// [endAt], but can be used in combination with [startAt],
  /// [startAfter], [startAtDocument] and [startAfterDocument].
  ///
  /// See also:
  ///
  ///  * [startAfterDocument] for a query that starts after a document.
  ///  * [startAtDocument] for a query that starts at a document.
  ///  * [endBeforeDocument] for a query that ends before a document.
  @override
  Query<Map<String, dynamic>> endAtDocument(DocumentSnapshot documentSnapshot) {
    Map<String, dynamic> results = _assertQueryCursorSnapshot(documentSnapshot);
    return _JsonQuery(
      firestore,
      _delegate.endAtDocument(results['orders'], results['values']),
    );
  }

  /// Takes a list of [values], creates and returns a new [Query] that ends at the
  /// provided fields relative to the order of the query.
  ///
  /// The [values] must be in order of [orderBy] filters.
  ///
  /// Calling this method will replace any existing cursor "end" query modifiers.
  @override
  Query<Map<String, dynamic>> endAt(List<Object?> values) {
    _assertQueryCursorValues(values);
    return _JsonQuery(firestore, _delegate.endAt(values));
  }

  /// Creates and returns a new [Query] that ends before the provided document
  /// snapshot (exclusive). The end position is relative to the order of the query.
  /// The document must contain all of the fields provided in the orderBy of
  /// this query.
  ///
  /// Calling this method will replace any existing cursor "end" query modifiers.
  @override
  Query<Map<String, dynamic>> endBeforeDocument(
    DocumentSnapshot documentSnapshot,
  ) {
    Map<String, dynamic> results = _assertQueryCursorSnapshot(documentSnapshot);
    return _JsonQuery(
      firestore,
      _delegate.endBeforeDocument(results['orders'], results['values']),
    );
  }

  /// Takes a list of [values], creates and returns a new [Query] that ends before
  /// the provided fields relative to the order of the query.
  ///
  /// The [values] must be in order of [orderBy] filters.
  ///
  /// Calling this method will replace any existing cursor "end" query modifiers.
  @override
  Query<Map<String, dynamic>> endBefore(List<Object?> values) {
    _assertQueryCursorValues(values);
    return _JsonQuery(
      firestore,
      _delegate.endBefore(values),
    );
  }

  /// Fetch the documents for this query.
  ///
  /// To modify how the query is fetched, the [options] parameter can be provided
  /// with a [GetOptions] instance.
  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    QuerySnapshotPlatform snapshotDelegate =
        await _delegate.get(options ?? const GetOptions());
    return _JsonQuerySnapshot(firestore, snapshotDelegate);
  }

  /// Creates and returns a new Query that's additionally limited to only return up
  /// to the specified number of documents.
  @override
  Query<Map<String, dynamic>> limit(int limit) {
    assert(limit > 0, 'limit must be a positive number greater than 0');
    return _JsonQuery(firestore, _delegate.limit(limit));
  }

  /// Creates and returns a new Query that only returns the last matching documents.
  ///
  /// You must specify at least one orderBy clause for limitToLast queries,
  /// otherwise an exception will be thrown during execution.
  @override
  Query<Map<String, dynamic>> limitToLast(int limit) {
    assert(limit > 0, 'limit must be a positive number greater than 0');
    List<List<dynamic>> orders = List.from(parameters['orderBy']);
    assert(
      orders.isNotEmpty,
      'limitToLast() queries require specifying at least one orderBy() clause',
    );
    return _JsonQuery(firestore, _delegate.limitToLast(limit));
  }

  /// Notifies of query results at this location.
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
  }) {
    return _delegate
        .snapshots(includeMetadataChanges: includeMetadataChanges)
        .map((item) => _JsonQuerySnapshot(firestore, item));
  }

  /// Creates and returns a new [Query] that's additionally sorted by the specified
  /// [field].
  /// The field may be a [String] representing a single field name or a [FieldPath].
  ///
  /// After a [FieldPath.documentId] order by call, you cannot add any more [orderBy]
  /// calls.
  ///
  /// Furthermore, you may not use [orderBy] on the [FieldPath.documentId] [field] when
  /// using [startAfterDocument], [startAtDocument], [endBeforeDocument],
  /// or [endAtDocument] because the order by clause on the document id
  /// is added by these methods implicitly.
  @override
  Query<Map<String, dynamic>> orderBy(
    Object field, {
    bool descending = false,
  }) {
    _assertValidFieldType(field);
    assert(
      !_hasStartCursor(),
      'Invalid query. '
      'You must not call startAt(), startAtDocument(), '
      'startAfter() or startAfterDocument() before calling orderBy()',
    );
    assert(
      !_hasEndCursor(),
      'Invalid query. '
      'You must not call endAt(), endAtDocument(), '
      'endBefore() or endBeforeDocument() before calling orderBy()',
    );

    final List<List<dynamic>> orders =
        List<List<dynamic>>.from(parameters['orderBy']);

    assert(
      orders.where((List<dynamic> item) => field == item[0]).isEmpty,
      'OrderBy field "$field" already exists in this query',
    );

    if (field == FieldPath.documentId) {
      orders.add([field, descending]);
    } else {
      FieldPath fieldPath =
          field is String ? FieldPath.fromString(field) : field as FieldPath;
      orders.add([fieldPath, descending]);
    }

    final List<List<dynamic>> conditions =
        List<List<dynamic>>.from(parameters['where']);

    if (conditions.isNotEmpty) {
      for (final dynamic condition in conditions) {
        dynamic conditionField = condition[0];
        String operator = condition[1];

        // Initial orderBy() parameter has to match every where() fieldPath parameter when
        // inequality or 'not-in' operator is invoked
        if (_isInequality(operator) || isNotIn(operator)) {
          assert(
            conditionField == orders[0][0],
            'The initial orderBy() field "$orders[0][0]" has to be the same as '
            'the where() field parameter "$conditionField" when an inequality operator is invoked.',
          );
        }

        for (final dynamic order in orders) {
          dynamic orderField = order[0];

          // Any where() fieldPath parameter cannot match any orderBy() parameter when
          // '==' operand is invoked
          if (operator == '==') {
            assert(
              conditionField != orderField,
              "The '$orderField' cannot be the same as your where() field parameter '$conditionField'.",
            );
          }

          if (conditionField == FieldPath.documentId) {
            assert(
              orderField == FieldPath.documentId,
              "'[FieldPath.documentId]' cannot be used in conjunction with a different orderBy() parameter.",
            );
          }
        }
      }
    }

    return _JsonQuery(firestore, _delegate.orderBy(orders));
  }

  /// Creates and returns a new [Query] that starts after the provided document
  /// (exclusive). The starting position is relative to the order of the query.
  /// The [documentSnapshot] must contain all of the fields provided in the orderBy of
  /// this query.
  ///
  /// Calling this method will replace any existing cursor "start" query modifiers.
  @override
  Query<Map<String, dynamic>> startAfterDocument(
    DocumentSnapshot documentSnapshot,
  ) {
    Map<String, dynamic> results = _assertQueryCursorSnapshot(documentSnapshot);

    return _JsonQuery(
      firestore,
      _delegate.startAfterDocument(results['orders'], results['values']),
    );
  }

  /// Takes a list of [values], creates and returns a new [Query] that starts
  /// after the provided fields relative to the order of the query.
  ///
  /// The [values] must be in order of [orderBy] filters.
  ///
  /// Calling this method will replace any existing cursor "start" query modifiers.
  @override
  Query<Map<String, dynamic>> startAfter(List<Object?> values) {
    _assertQueryCursorValues(values);
    return _JsonQuery(firestore, _delegate.startAfter(values));
  }

  /// Creates and returns a new [Query] that starts at the provided document
  /// (inclusive). The starting position is relative to the order of the query.
  /// The document must contain all of the fields provided in the orderBy of
  /// this query.
  ///
  /// Calling this method will replace any existing cursor "start" query modifiers.
  @override
  Query<Map<String, dynamic>> startAtDocument(
    DocumentSnapshot documentSnapshot,
  ) {
    Map<String, dynamic> results = _assertQueryCursorSnapshot(documentSnapshot);

    return _JsonQuery(
      firestore,
      _delegate.startAtDocument(results['orders'], results['values']),
    );
  }

  /// Takes a list of [values], creates and returns a new [Query] that starts at
  /// the provided fields relative to the order of the query.
  ///
  /// The [values] must be in order of [orderBy] filters.
  ///
  /// Calling this method will replace any existing cursor "start" query modifiers.
  @override
  Query<Map<String, dynamic>> startAt(List<Object?> values) {
    _assertQueryCursorValues(values);
    return _JsonQuery(firestore, _delegate.startAt(values));
  }

  /// Creates and returns a new [Query] with additional filter on specified
  /// [field]. [field] refers to a field in a document.
  ///
  /// The [field] may be a [String] consisting of a single field name
  /// (referring to a top level field in the document),
  /// or a series of field names separated by dots '.'
  /// (referring to a nested field in the document).
  /// Alternatively, the [field] can also be a [FieldPath].
  ///
  /// Only documents satisfying provided condition are included in the result
  /// set.
  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    List<Object?>? arrayContainsAny,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
    bool? isNull,
  }) {
    _assertValidFieldType(field);

    const ListEquality<dynamic> equality = ListEquality<dynamic>();
    final List<List<dynamic>> conditions =
        List<List<dynamic>>.from(parameters['where']);

    // Conditions can be chained from other [Query] instances
    void addCondition(dynamic field, String operator, dynamic value) {
      List<dynamic> condition;
      dynamic codecValue = _CodecUtility.valueEncode(value);

      if (field == FieldPath.documentId) {
        condition = <dynamic>[field, operator, codecValue];
      } else {
        FieldPath fieldPath =
            field is String ? FieldPath.fromString(field) : field as FieldPath;
        condition = <dynamic>[fieldPath, operator, codecValue];
      }

      assert(
        conditions
            .where((List<dynamic> item) => equality.equals(condition, item))
            .isEmpty,
        'Condition $condition already exists in this query.',
      );
      conditions.add(condition);
    }

    if (isEqualTo != null) addCondition(field, '==', isEqualTo);
    if (isNotEqualTo != null) addCondition(field, '!=', isNotEqualTo);
    if (isLessThan != null) addCondition(field, '<', isLessThan);
    if (isLessThanOrEqualTo != null) {
      addCondition(field, '<=', isLessThanOrEqualTo);
    }
    if (isGreaterThan != null) addCondition(field, '>', isGreaterThan);
    if (isGreaterThanOrEqualTo != null) {
      addCondition(field, '>=', isGreaterThanOrEqualTo);
    }
    if (arrayContains != null) {
      addCondition(field, 'array-contains', arrayContains);
    }
    if (arrayContainsAny != null) {
      addCondition(field, 'array-contains-any', arrayContainsAny);
    }
    if (whereIn != null) addCondition(field, 'in', whereIn);
    if (whereNotIn != null) addCondition(field, 'not-in', whereNotIn);
    if (isNull != null) {
      if (isNull == true) {
        addCondition(field, '==', null);
      } else {
        addCondition(field, '!=', null);
      }
    }

    dynamic hasInequality;
    bool hasIn = false;
    bool hasNotIn = false;
    bool hasNotEqualTo = false;
    bool hasNotEqualToOperatorAndNotDocumentIdField = false;
    bool hasArrayContains = false;
    bool hasArrayContainsAny = false;
    bool hasDocumentIdField = false;

    // Once all conditions have been set, we must now check them to ensure the
    // query is valid.
    for (final dynamic condition in conditions) {
      dynamic field = condition[0]; // FieldPath or FieldPathType
      String operator = condition[1];
      dynamic value = condition[2];

      // Initial orderBy() parameter has to match every where() fieldPath parameter when
      // inequality operator is invoked
      List<List<dynamic>> orders = List.from(parameters['orderBy']);
      if (_isInequality(operator) && orders.isNotEmpty) {
        assert(
          field == orders[0][0],
          "The initial orderBy() field '$orders[0][0]' has to be the same as "
          "the where() field parameter '$field' when an inequality operator is invoked.",
        );
      }

      if (field != FieldPath.documentId && hasDocumentIdField) {
        assert(
          operator != '!=',
          "You cannot use '!=' filters whilst using a FieldPath.documentId field in another filter.",
        );
      }

      if (field == FieldPath.documentId) {
        assert(
          !hasNotEqualToOperatorAndNotDocumentIdField,
          "You cannot use FieldPath.documentId field whilst using a '!=' filter on a different field.",
        );
        hasDocumentIdField = true;
      }

      if (operator == 'in' ||
          operator == 'array-contains-any' ||
          isNotIn(operator)) {
        assert(
          value is List,
          "A non-empty [List] is required for '$operator' filters.",
        );
        assert(
          (value as List).length <= 10,
          "'$operator' filters support a maximum of 10 elements in the value [List].",
        );
        assert(
          (value as List).isNotEmpty,
          "'$operator' filters require a non-empty [List].",
        );
        assert(
          (value as List).where((value) => value == null).isEmpty,
          "'$operator' filters cannot contain 'null' in the [List].",
        );
      }

      if (operator == '!=') {
        assert(!hasNotEqualTo, "You cannot use '!=' filters more than once.");
        assert(!hasNotIn, "You cannot use '!=' filters with 'not-in' filters.");

        hasNotEqualTo = true;

        if (field != FieldPath.documentId) {
          hasNotEqualToOperatorAndNotDocumentIdField = true;
        }
      }

      if (isNotIn(operator)) {
        assert(!hasNotIn, "You cannot use 'not-in' filters more than once.");
        assert(
          !hasNotEqualTo,
          "You cannot use 'not-in' filters with '!=' filters.",
        );
      }

      if (operator == 'in') {
        assert(!hasIn, "You cannot use 'whereIn' filters more than once.");
        hasIn = true;
      }

      if (operator == 'array-contains') {
        assert(
          !hasArrayContains,
          "You cannot use 'array-contains' filters more than once.",
        );
        hasArrayContains = true;
      }

      if (operator == 'array-contains-any') {
        assert(
          !hasArrayContainsAny,
          "You cannot use 'array-contains-any' filters more than once.",
        );
        hasArrayContainsAny = true;
      }

      if (operator == 'array-contains-any' || operator == 'in') {
        assert(
          !(hasIn && hasArrayContainsAny),
          "You cannot use 'in' filters with 'array-contains-any' filters.",
        );
      }

      if (operator == 'array-contains' || operator == 'array-contains-any') {
        assert(
          !(hasArrayContains && hasArrayContainsAny),
          "You cannot use both 'array-contains-any' or 'array-contains' filters together.",
        );
      }

      if (_isInequality(operator)) {
        if (hasInequality == null) {
          hasInequality = field;
        } else {
          assert(
            hasInequality == field,
            'All where filters with an inequality (<, <=, >, or >=) must be '
            "on the same field. But you have inequality filters on '$hasInequality' and '$field'.",
          );
        }
      }
    }

    return _JsonQuery(firestore, _delegate.where(conditions));
  }

  @override
  Query<R> withConverter<R extends Object?>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  }) {
    return _WithConverterQuery(
      this,
      fromFirestore,
      toFirestore,
    );
  }

  @override
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType &&
        other is _JsonQuery &&
        other.firestore == firestore &&
        other._delegate == _delegate;
  }

  @override
  int get hashCode => Object.hash(runtimeType, firestore, _delegate);

  /// Represents an [AggregateQuery] over the data at a particular location for retrieving metadata
  /// without retrieving the actual documents.
  @override
  AggregateQuery count() {
    return AggregateQuery._(_delegate.count(), this);
  }
}

class _WithConverterQuery<T extends Object?> implements Query<T> {
  _WithConverterQuery(
    this._originalQuery,
    this._fromFirestore,
    this._toFirestore,
  );

  final Query<Map<String, dynamic>> _originalQuery;
  final FromFirestore<T> _fromFirestore;
  final ToFirestore<T> _toFirestore;

  @override
  FirebaseFirestore get firestore => _originalQuery.firestore;

  @override
  Map<String, dynamic> get parameters => _originalQuery.parameters;

  Query<T> _mapQuery(Query<Map<String, dynamic>> newOriginalQuery) {
    return _WithConverterQuery<T>(
      newOriginalQuery,
      _fromFirestore,
      _toFirestore,
    );
  }

  @override
  Future<QuerySnapshot<T>> get([GetOptions? options]) async {
    final snapshot = await _originalQuery.get(options);
    return _WithConverterQuerySnapshot<T>(
      snapshot,
      _fromFirestore,
      _toFirestore,
    );
  }

  @override
  Stream<QuerySnapshot<T>> snapshots({bool includeMetadataChanges = false}) {
    return _originalQuery
        .snapshots(includeMetadataChanges: includeMetadataChanges)
        .map(
          (snapshot) => _WithConverterQuerySnapshot<T>(
            snapshot,
            _fromFirestore,
            _toFirestore,
          ),
        );
  }

  @override
  Query<T> endAt(List<Object?> values) {
    return _mapQuery(_originalQuery.endAt(values));
  }

  @override
  Query<T> endAtDocument(DocumentSnapshot documentSnapshot) {
    return _mapQuery(_originalQuery.endAtDocument(documentSnapshot));
  }

  @override
  Query<T> endBefore(List<Object?> values) {
    return _mapQuery(_originalQuery.endBefore(values));
  }

  @override
  Query<T> endBeforeDocument(DocumentSnapshot documentSnapshot) {
    return _mapQuery(_originalQuery.endBeforeDocument(documentSnapshot));
  }

  @override
  Query<T> limit(int limit) {
    return _mapQuery(_originalQuery.limit(limit));
  }

  @override
  Query<T> limitToLast(int limit) {
    return _mapQuery(_originalQuery.limitToLast(limit));
  }

  @override
  Query<T> orderBy(Object field, {bool descending = false}) {
    return _mapQuery(_originalQuery.orderBy(field, descending: descending));
  }

  @override
  Query<T> startAfter(List<Object?> values) {
    return _mapQuery(_originalQuery.startAfter(values));
  }

  @override
  Query<T> startAfterDocument(DocumentSnapshot documentSnapshot) {
    return _mapQuery(_originalQuery.startAfterDocument(documentSnapshot));
  }

  @override
  Query<T> startAt(List<Object?> values) {
    return _mapQuery(_originalQuery.startAt(values));
  }

  @override
  Query<T> startAtDocument(DocumentSnapshot documentSnapshot) {
    return _mapQuery(_originalQuery.startAtDocument(documentSnapshot));
  }

  @override
  Query<T> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    List<Object?>? arrayContainsAny,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
    bool? isNull,
  }) {
    return _mapQuery(
      _originalQuery.where(
        field,
        isEqualTo: isEqualTo,
        isNotEqualTo: isNotEqualTo,
        isLessThan: isLessThan,
        isLessThanOrEqualTo: isLessThanOrEqualTo,
        isGreaterThan: isGreaterThan,
        isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
        arrayContains: arrayContains,
        arrayContainsAny: arrayContainsAny,
        whereIn: whereIn,
        whereNotIn: whereNotIn,
        isNull: isNull,
      ),
    );
  }

  @override
  Query<R> withConverter<R extends Object?>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  }) {
    return _WithConverterQuery(
      _originalQuery,
      fromFirestore,
      toFirestore,
    );
  }

  @override
  bool operator ==(Object other) {
    return runtimeType == other.runtimeType &&
        other is _WithConverterQuery<T> &&
        other._fromFirestore == _fromFirestore &&
        other._toFirestore == _toFirestore &&
        other._originalQuery == _originalQuery;
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, _fromFirestore, _toFirestore, _originalQuery);

  /// Represents an [AggregateQuery] over the data at a particular location for retrieving metadata
  /// without retrieving the actual documents.
  @override
  AggregateQuery count() {
    return _originalQuery.count();
  }
}
