// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_web/firebase_core_web_interop.dart'
    hide jsify, dartify;
import 'package:js/js.dart';

import 'firestore_interop.dart' as firestore_interop;
import 'utils/utils.dart';

export 'firestore_interop.dart';

/// Given an AppJSImp, return the Firestore instance.
Firestore getFirestoreInstance(
    [App? app, firestore_interop.Settings? settings]) {
  if (app != null && settings != null) {
    return Firestore.getInstance(
        firestore_interop.initializeFirestore(app.jsObject, settings));
  }

  return Firestore.getInstance(app != null
      ? firestore_interop.getFirestore(app.jsObject)
      : firestore_interop.getFirestore());
}

/// The Cloud Firestore service interface.
///
/// See: <https://firebase.google.com/docs/reference/js/firebase.firestore.Firestore>.
class Firestore extends JsObjectWrapper<firestore_interop.FirestoreJsImpl> {
  static final _expando = Expando<Firestore>();

  /// Non-null App for this instance of firestore service.
  App get app => App.getInstance(jsObject.app);

  /// Creates a new Firestore from a [jsObject].
  static Firestore getInstance(firestore_interop.FirestoreJsImpl jsObject) {
    return _expando[jsObject] ??= Firestore._fromJsObject(jsObject);
  }

  Firestore._fromJsObject(firestore_interop.FirestoreJsImpl jsObject)
      : super.fromJsObject(jsObject);

  WriteBatch? batch() =>
      WriteBatch.getInstance(firestore_interop.writeBatch(jsObject));

  CollectionReference collection(String collectionPath) =>
      CollectionReference.getInstance(
          firestore_interop.collection(jsObject, collectionPath));

  Query collectionGroup(String collectionId) => Query.fromJsObject(
      firestore_interop.collectionGroup(jsObject, collectionId));

  DocumentReference doc(String documentPath) => DocumentReference.getInstance(
      firestore_interop.doc(jsObject, documentPath));

  Future<void> enablePersistence(
      [firestore_interop.PersistenceSettings? settings]) {
    if (settings != null && settings.synchronizeTabs == true) {
      return handleThenable(
          firestore_interop.enableMultiTabIndexedDbPersistence(jsObject));
    }
    return handleThenable(
        firestore_interop.enableIndexedDbPersistence(jsObject));
  }

  Stream<void> snapshotsInSync() {
    late StreamController<void> controller;
    late ZoneCallback onSnapshotsInSyncUnsubscribe;
    var nextWrapper = allowInterop((Object? noValue) {
      controller.add(null);
    });

    void startListen() {
      onSnapshotsInSyncUnsubscribe =
          firestore_interop.onSnapshotsInSync(jsObject, nextWrapper);
    }

    void stopListen() {
      onSnapshotsInSyncUnsubscribe();
      controller.close();
    }

    controller = StreamController<void>.broadcast(
      onListen: startListen,
      onCancel: stopListen,
    );

    return controller.stream;
  }

  Future<void> clearPersistence() =>
      handleThenable(firestore_interop.clearIndexedDbPersistence(jsObject));

  Future runTransaction(
      Function(Transaction?) updateFunction, int maxAttempts) {
    var updateFunctionWrap = allowInterop((transaction) =>
        handleFutureWithMapper(
            updateFunction(Transaction.getInstance(transaction)), jsify));

    return handleThenable(firestore_interop.runTransaction(
            jsObject,
            updateFunctionWrap,
            firestore_interop.TransactionOptionsJsImpl(
                maxAttempts: maxAttempts)))
        .then((value) => dartify(null));
  }

  void useEmulator(String host, int port) =>
      firestore_interop.connectFirestoreEmulator(jsObject, host, port);

  Future enableNetwork() =>
      handleThenable(firestore_interop.enableNetwork(jsObject));

  Future disableNetwork() =>
      handleThenable(firestore_interop.disableNetwork(jsObject));

  Future<void> terminate() =>
      handleThenable(firestore_interop.terminate(jsObject));

  Future<void> waitForPendingWrites() =>
      handleThenable(firestore_interop.waitForPendingWrites(jsObject));

  LoadBundleTask loadBundle(Uint8List bundle) {
    return LoadBundleTask.getInstance(
        firestore_interop.loadBundle(jsObject, bundle));
  }

  Future<void> setIndexConfiguration(String indexConfiguration) =>
      handleThenable(firestore_interop.setIndexConfiguration(
          jsObject, indexConfiguration));

  Future<Query> namedQuery(String name) async {
    firestore_interop.QueryJsImpl? query =
        await handleThenable(firestore_interop.namedQuery(jsObject, name));

    if (query == null) {
      // same error as iOS & android to maintain consistency
      throw FirebaseException(
          plugin: 'cloud_firestore',
          message:
              'Named query has not been found. Please check it has been loaded properly via loadBundle().',
          code: 'non-existent-named-query');
    }

    return Query.fromJsObject(query);
  }

  bool refEqual(dynamic /* DocumentReference | CollectionReference */ left,
      dynamic /* DocumentReference | CollectionReference */ right) {
    return firestore_interop.refEqual(left, right);
  }
}

class LoadBundleTask
    extends JsObjectWrapper<firestore_interop.LoadBundleTaskJsImpl> {
  LoadBundleTask._fromJsObject(firestore_interop.LoadBundleTaskJsImpl jsObject)
      : super.fromJsObject(jsObject);

  static final _expando = Expando<LoadBundleTask>();

  /// Creates a new LoadBundleTask from a [jsObject].
  static LoadBundleTask getInstance(
    firestore_interop.LoadBundleTaskJsImpl jsObject,
  ) {
    return _expando[jsObject] ??= LoadBundleTask._fromJsObject(jsObject);
  }

  ///Tracks progress of loadBundle snapshots as the documents are loaded into cache
  Stream<LoadBundleTaskProgress> get stream {
    late StreamController<LoadBundleTaskProgress> controller;
    controller = StreamController<LoadBundleTaskProgress>(onListen: () {
      /// Calls underlying onProgress method on a LoadBundleTask [jsObject].
      jsObject.onProgress(
          allowInterop((firestore_interop.LoadBundleTaskProgressJsImpl data) {
        LoadBundleTaskProgress taskProgress =
            LoadBundleTaskProgress._fromJsObject(data);

        if (LoadBundleTaskState.error != taskProgress.taskState) {
          // Error handled in addError() call below.
          controller.add(taskProgress);
        }
      }));

      jsObject.then(allowInterop((value) {
        controller.close();
      }), allowInterop((error) {
        controller.addError(
          FirebaseException(
            plugin: 'cloud_firestore',
            message: error.message,
            code: 'load-bundle-error',
            stackTrace: StackTrace.fromString(error.stack),
          ),
        );
        controller.close();
      }));
    }, onCancel: () {
      controller.close();
    });

    return controller.stream;
  }
}

class LoadBundleTaskProgress
    extends JsObjectWrapper<firestore_interop.LoadBundleTaskProgressJsImpl> {
  LoadBundleTaskProgress._fromJsObject(
    firestore_interop.LoadBundleTaskProgressJsImpl jsObject,
  )   : taskState = convertToTaskState(jsObject.taskState.toLowerCase()),
        bytesLoaded = int.parse(jsObject.bytesLoaded),
        documentsLoaded = jsObject.documentsLoaded,
        totalBytes = int.parse(jsObject.totalBytes),
        totalDocuments = jsObject.totalDocuments,
        super.fromJsObject(jsObject);

  static final _expando = Expando<LoadBundleTaskProgress>();

  /// Creates a new LoadBundleTaskProgress from a [jsObject].
  static LoadBundleTaskProgress getInstance(
    firestore_interop.LoadBundleTaskProgressJsImpl jsObject,
  ) {
    return _expando[jsObject] ??=
        LoadBundleTaskProgress._fromJsObject(jsObject);
  }

  final LoadBundleTaskState taskState;
  final int bytesLoaded;
  final int documentsLoaded;
  final int totalBytes;
  final int totalDocuments;
}

class WriteBatch extends JsObjectWrapper<firestore_interop.WriteBatchJsImpl>
    with _Updatable {
  static final _expando = Expando<WriteBatch>();

  /// Creates a new WriteBatch from a [jsObject].
  static WriteBatch getInstance(firestore_interop.WriteBatchJsImpl jsObject) {
    return _expando[jsObject] ??= WriteBatch._fromJsObject(jsObject);
  }

  WriteBatch._fromJsObject(firestore_interop.WriteBatchJsImpl jsObject)
      : super.fromJsObject(jsObject);

  Future<void> commit() => handleThenable(jsObject.commit());

  WriteBatch delete(DocumentReference documentRef) =>
      WriteBatch.getInstance(jsObject.delete(documentRef.jsObject));

  WriteBatch set(DocumentReference documentRef, Map<String, dynamic> data,
      [firestore_interop.SetOptions? options]) {
    var jsObjectSet = (options != null)
        ? jsObject.set(documentRef.jsObject, jsify(data), options)
        : jsObject.set(documentRef.jsObject, jsify(data));
    return WriteBatch.getInstance(jsObjectSet);
  }

  WriteBatch update(DocumentReference documentRef, Map<String, dynamic> data) =>
      WriteBatch.getInstance(
          _wrapUpdateFunctionCall(jsObject, data, documentRef));
}

class DocumentReference
    extends JsObjectWrapper<firestore_interop.DocumentReferenceJsImpl>
    with _Updatable {
  static final _expando = Expando<DocumentReference>();

  /// Non-null [Firestore] the document is in.
  /// This is useful for performing transactions, for example.
  Firestore get firestore => Firestore.getInstance(jsObject.firestore);

  String get id => jsObject.id;

  CollectionReference? get parent =>
      CollectionReference.getInstance(jsObject.parent);

  String get path => jsObject.path;

  /// Creates a new DocumentReference from a [jsObject].
  static DocumentReference getInstance(
      firestore_interop.DocumentReferenceJsImpl jsObject) {
    return _expando[jsObject] ??= DocumentReference._fromJsObject(jsObject);
  }

  DocumentReference._fromJsObject(
      firestore_interop.DocumentReferenceJsImpl jsObject)
      : super.fromJsObject(jsObject);

  CollectionReference? collection(String collectionPath) {
    return CollectionReference.getInstance(firestore_interop.collection(
        firestore.jsObject, '$path/$collectionPath'));
  }

  Future<void> delete() =>
      handleThenable(firestore_interop.deleteDoc(jsObject));

  Future<DocumentSnapshot> get([firestore_interop.GetOptions? options]) {
    if (options == null || options.source == 'default') {
      return handleThenable(firestore_interop.getDoc(jsObject))
          .then(DocumentSnapshot.getInstance);
    } else if (options.source == 'server') {
      return handleThenable(firestore_interop.getDocFromServer(jsObject))
          .then(DocumentSnapshot.getInstance);
    } else {
      return handleThenable(firestore_interop.getDocFromCache(jsObject))
          .then(DocumentSnapshot.getInstance);
    }
  }

  /// Attaches a listener for [DocumentSnapshot] events.
  Stream<DocumentSnapshot> get onSnapshot => _createSnapshotStream().stream;

  Stream<DocumentSnapshot> get onMetadataChangesSnapshot {
    return _createSnapshotStream(
      firestore_interop.DocumentListenOptions(includeMetadataChanges: true),
    ).stream;
  }

  StreamController<DocumentSnapshot> _createSnapshotStream([
    firestore_interop.DocumentListenOptions? options,
  ]) {
    late ZoneCallback onSnapshotUnsubscribe;
    // ignore: close_sinks, the controler is returned
    late StreamController<DocumentSnapshot> controller;

    final nextWrapper =
        allowInterop((firestore_interop.DocumentSnapshotJsImpl snapshot) {
      controller.add(DocumentSnapshot.getInstance(snapshot));
    });

    final errorWrapper = allowInterop((e) => controller.addError(e));

    void startListen() {
      onSnapshotUnsubscribe = (options != null)
          ? firestore_interop.onSnapshot(
              jsObject, options, nextWrapper, errorWrapper)
          : firestore_interop.onSnapshot(jsObject, nextWrapper, errorWrapper);
    }

    void stopListen() {
      onSnapshotUnsubscribe();
    }

    return controller = StreamController<DocumentSnapshot>.broadcast(
      onListen: startListen,
      onCancel: stopListen,
      sync: true,
    );
  }

  Future<void> set(Map<String, dynamic> data,
      [firestore_interop.SetOptions? options]) {
    var jsObjectSet = (options != null)
        ? firestore_interop.setDoc(jsObject, jsify(data), options)
        : firestore_interop.setDoc(jsObject, jsify(data));

    return handleThenable(jsObjectSet);
  }

  Future<void> update(Map<String, dynamic> data) =>
      handleThenable(firestore_interop.updateDoc(jsObject, jsify(data)));
}

class Query<T extends firestore_interop.QueryJsImpl>
    extends JsObjectWrapper<T> {
  Firestore get firestore => Firestore.getInstance(jsObject.firestore);

  /// Creates a new Query from a [jsObject].
  Query.fromJsObject(T jsObject) : super.fromJsObject(jsObject);

  Query endAt({DocumentSnapshot? snapshot, List<dynamic>? fieldValues}) =>
      Query.fromJsObject(firestore_interop.query(
          jsObject,
          _createQueryConstraint(
              firestore_interop.endAt, snapshot, fieldValues)));

  Query endBefore({DocumentSnapshot? snapshot, List<dynamic>? fieldValues}) =>
      Query.fromJsObject(firestore_interop.query(
          jsObject,
          _createQueryConstraint(
              firestore_interop.endBefore, snapshot, fieldValues)));

  Future<QuerySnapshot> get([firestore_interop.GetOptions? options]) {
    if (options == null || options.source == 'default') {
      return handleThenable(firestore_interop.getDocs(jsObject))
          .then(QuerySnapshot.getInstance);
    } else if (options.source == 'server') {
      return handleThenable(firestore_interop.getDocsFromServer(jsObject))
          .then(QuerySnapshot.getInstance);
    } else {
      return handleThenable(firestore_interop.getDocsFromCache(jsObject))
          .then(QuerySnapshot.getInstance);
    }
  }

  Query limit(num limit) => Query.fromJsObject(
      firestore_interop.query(jsObject, firestore_interop.limit(limit)));

  Query limitToLast(num limit) => Query.fromJsObject(
      firestore_interop.query(jsObject, firestore_interop.limitToLast(limit)));

  late final Stream<QuerySnapshot> onSnapshot =
      _createSnapshotStream(false).stream;

  late final Stream<QuerySnapshot> onSnapshotMetadata =
      _createSnapshotStream(true).stream;

  StreamController<QuerySnapshot> _createSnapshotStream(
    bool includeMetadataChanges,
  ) {
    late ZoneCallback onSnapshotUnsubscribe;
    // ignore: close_sinks, the controller is returned
    late StreamController<QuerySnapshot> controller;

    final nextWrapper =
        allowInterop((firestore_interop.QuerySnapshotJsImpl snapshot) {
      controller.add(QuerySnapshot._fromJsObject(snapshot));
    });
    final errorWrapper = allowInterop((e) => controller.addError(e));
    final options = firestore_interop.SnapshotListenOptions(
        includeMetadataChanges: includeMetadataChanges);

    void startListen() {
      onSnapshotUnsubscribe = firestore_interop.onSnapshot(
          jsObject, options, nextWrapper, errorWrapper);
    }

    void stopListen() {
      onSnapshotUnsubscribe();
    }

    return controller = StreamController<QuerySnapshot>.broadcast(
      onListen: startListen,
      onCancel: stopListen,
      sync: true,
    );
  }

  Query orderBy(/*String|FieldPath*/ dynamic fieldPath,
      [String? /*'desc'|'asc'*/ directionStr]) {
    var jsObjectOrderBy = (directionStr != null)
        ? firestore_interop.orderBy(fieldPath, directionStr)
        : firestore_interop.orderBy(fieldPath);

    return Query.fromJsObject(
        firestore_interop.query(jsObject, jsObjectOrderBy));
  }

  Query startAfter({DocumentSnapshot? snapshot, List<dynamic>? fieldValues}) =>
      Query.fromJsObject(firestore_interop.query(
          jsObject,
          _createQueryConstraint(
              firestore_interop.startAfter, snapshot, fieldValues)));

  Query startAt({DocumentSnapshot? snapshot, List<dynamic>? fieldValues}) =>
      Query.fromJsObject(firestore_interop.query(
          jsObject,
          _createQueryConstraint(
              firestore_interop.startAt, snapshot, fieldValues)));

  Query where(dynamic fieldPath, String opStr, dynamic value) =>
      Query.fromJsObject(firestore_interop.query(
          jsObject, firestore_interop.where(fieldPath, opStr, jsify(value))));

  /// Calls js paginating [method] with [DocumentSnapshot] or List of
  /// [fieldValues].
  /// We need to call this method in all paginating methods to fix that Dart
  /// doesn't support varargs - we need to use [List] to call js function.
  S? _createQueryConstraint<S>(
      Object method, DocumentSnapshot? snapshot, List<dynamic>? fieldValues) {
    if (snapshot == null && fieldValues == null) {
      throw ArgumentError(
          'Please provide either snapshot or fieldValues parameter.');
    }

    var args = (snapshot != null)
        ? [snapshot.jsObject]
        : fieldValues!.map(jsify).toList();

    return callMethod(method, 'apply', [null, jsify(args)]);
  }
}

class CollectionReference<T extends firestore_interop.CollectionReferenceJsImpl>
    extends Query<T> {
  static final _expando = Expando<CollectionReference>();

  String get id => jsObject.id;

  DocumentReference? get parent =>
      DocumentReference.getInstance(jsObject.parent);

  String get path => jsObject.path;

  /// Creates a new CollectionReference from a [jsObject].
  static CollectionReference getInstance(
      firestore_interop.CollectionReferenceJsImpl jsObject) {
    return _expando[jsObject] ??= CollectionReference._fromJsObject(jsObject);
  }

  factory CollectionReference() => CollectionReference._fromJsObject(
      firestore_interop.CollectionReferenceJsImpl());

  CollectionReference._fromJsObject(
      firestore_interop.CollectionReferenceJsImpl jsObject)
      : super.fromJsObject(jsObject as T);

  Future<DocumentReference> add(Map<String, dynamic> data) =>
      handleThenable<firestore_interop.DocumentReferenceJsImpl>(
              firestore_interop.addDoc(jsObject, jsify(data)))
          .then(DocumentReference.getInstance);

  DocumentReference doc([String? documentPath]) {
    final ref = documentPath != null
        ? firestore_interop.doc(jsObject, documentPath)
        : firestore_interop.doc(jsObject);

    return DocumentReference.getInstance(ref);
  }

  bool isEqual(CollectionReference other) =>
      firestore_interop.queryEqual(jsObject, other.jsObject);
}

class DocumentChange
    extends JsObjectWrapper<firestore_interop.DocumentChangeJsImpl> {
  static final _expando = Expando<DocumentChange>();

  String get type => jsObject.type;

  DocumentSnapshot? get doc => DocumentSnapshot.getInstance(jsObject.doc);

  num get oldIndex => jsObject.oldIndex;

  num get newIndex => jsObject.newIndex;

  /// Creates a new DocumentChange from a [jsObject].
  static DocumentChange getInstance(
      firestore_interop.DocumentChangeJsImpl jsObject) {
    return _expando[jsObject] ??= DocumentChange._fromJsObject(jsObject);
  }

  DocumentChange._fromJsObject(firestore_interop.DocumentChangeJsImpl jsObject)
      : super.fromJsObject(jsObject);
}

class DocumentSnapshot
    extends JsObjectWrapper<firestore_interop.DocumentSnapshotJsImpl> {
  static final _expando = Expando<DocumentSnapshot>();

  bool get exists => jsObject.exists();

  String get id => jsObject.id;

  firestore_interop.SnapshotMetadata get metadata => jsObject.metadata;

  DocumentReference? get ref => DocumentReference.getInstance(jsObject.ref);

  /// Creates a new DocumentSnapshot from a [jsObject].
  static DocumentSnapshot getInstance(
      firestore_interop.DocumentSnapshotJsImpl jsObject) {
    return _expando[jsObject] ??= DocumentSnapshot._fromJsObject(jsObject);
  }

  DocumentSnapshot._fromJsObject(
      firestore_interop.DocumentSnapshotJsImpl jsObject)
      : super.fromJsObject(jsObject);

  Map<String, dynamic>? data([firestore_interop.SnapshotOptions? options]) =>
      dartify(jsObject.data(options));

  dynamic get(/*String|FieldPath*/ dynamic fieldPath) =>
      dartify(jsObject.get(fieldPath));

  bool isEqual(DocumentSnapshot other) =>
      firestore_interop.snapshotEqual(jsObject, other.jsObject);
}

class QuerySnapshot
    extends JsObjectWrapper<firestore_interop.QuerySnapshotJsImpl> {
  static final _expando = Expando<QuerySnapshot>();

  // TODO: [SnapshotListenOptions options]
  List<DocumentChange> docChanges(
      [firestore_interop.SnapshotListenOptions? options]) {
    List<firestore_interop.DocumentChangeJsImpl> changes = options != null
        ? jsObject.docChanges(jsify(options))
        : jsObject.docChanges();

    return changes
        // explicitly typing the param as dynamic to work-around
        // https://github.com/dart-lang/sdk/issues/33537
        // ignore: unnecessary_lambdas
        .map((dynamic e) => DocumentChange.getInstance(e))
        .toList();
  }

  List<DocumentSnapshot?> get docs => jsObject.docs
      // explicitly typing the param as dynamic to work-around
      // https://github.com/dart-lang/sdk/issues/33537
      // ignore: unnecessary_lambdas
      .map((dynamic e) => DocumentSnapshot.getInstance(e))
      .toList();

  bool get empty => jsObject.empty;

  firestore_interop.SnapshotMetadata get metadata => jsObject.metadata;

  Query get query => Query.fromJsObject(jsObject.query);

  num get size => jsObject.size;

  static QuerySnapshot getInstance(
      firestore_interop.QuerySnapshotJsImpl jsObject) {
    return _expando[jsObject] ??= QuerySnapshot._fromJsObject(jsObject);
  }

  QuerySnapshot._fromJsObject(firestore_interop.QuerySnapshotJsImpl jsObject)
      : super.fromJsObject(jsObject);

  void forEach(Function(DocumentSnapshot?) callback) {
    var callbackWrap =
        allowInterop((s) => callback(DocumentSnapshot.getInstance(s)));
    return jsObject.forEach(callbackWrap);
  }

  bool isEqual(QuerySnapshot other) =>
      firestore_interop.snapshotEqual(jsObject, other.jsObject);
}

class Transaction extends JsObjectWrapper<firestore_interop.TransactionJsImpl>
    with _Updatable {
  static final _expando = Expando<Transaction>();

  /// Creates a new Transaction from a [jsObject].
  static Transaction getInstance(firestore_interop.TransactionJsImpl jsObject) {
    return _expando[jsObject] ??= Transaction._fromJsObject(jsObject);
  }

  Transaction._fromJsObject(firestore_interop.TransactionJsImpl jsObject)
      : super.fromJsObject(jsObject);

  Transaction delete(DocumentReference documentRef) =>
      Transaction.getInstance(jsObject.delete(documentRef.jsObject));

  Future<DocumentSnapshot> get(DocumentReference documentRef) =>
      handleThenable<firestore_interop.DocumentSnapshotJsImpl>(
              jsObject.get(documentRef.jsObject))
          .then(DocumentSnapshot.getInstance);

  Transaction set(DocumentReference documentRef, Map<String, dynamic> data,
      [firestore_interop.SetOptions? options]) {
    var jsObjectSet = (options != null)
        ? jsObject.set(documentRef.jsObject, jsify(data), options)
        : jsObject.set(documentRef.jsObject, jsify(data));
    return Transaction.getInstance(jsObjectSet);
  }

  Transaction update(
          DocumentReference documentRef, Map<String, dynamic> data) =>
      Transaction.getInstance(
          _wrapUpdateFunctionCall(jsObject, data, documentRef));
}

/// Mixin class for all classes with the [update()] method. We need to call
/// [_wrapUpdateFunctionCall()] in all [update()] methods to fix that Dart
/// doesn't support varargs - we need to use [List] to call js function.
abstract class _Updatable {
  /// Calls js [:update():] method on [jsObject] with [data] or list of
  /// [fieldsAndValues] and optionally [documentRef].
  T? _wrapUpdateFunctionCall<T>(jsObject, Map<String, dynamic> data,
      [DocumentReference? documentRef]) {
    var args = [jsify(data)];
    // documentRef has to be the first parameter in list of args
    if (documentRef != null) {
      args.insert(0, documentRef.jsObject);
    }
    return callMethod(jsObject, 'update', args);
  }
}

class _FieldValueDelete implements FieldValue {
  @override
  firestore_interop.FieldValue _jsify() => firestore_interop.deleteField();

  @override
  String toString() => 'FieldValue.delete()';
}

class _FieldValueServerTimestamp implements FieldValue {
  @override
  firestore_interop.FieldValue _jsify() => firestore_interop.serverTimestamp();

  @override
  String toString() => 'FieldValue.serverTimestamp()';
}

abstract class _FieldValueArray implements FieldValue {
  final List? elements;

  _FieldValueArray(this.elements);
}

class _FieldValueArrayUnion extends _FieldValueArray {
  _FieldValueArrayUnion(List? elements) : super(elements);

  @override
  firestore_interop.FieldValue? _jsify() {
    // This uses var arg so cannot use js package
    return callMethod(
        firestore_interop.arrayUnion, 'apply', [null, jsify(elements)]);
  }

  @override
  String toString() => 'FieldValue.arrayUnion($elements)';
}

class _FieldValueArrayRemove extends _FieldValueArray {
  _FieldValueArrayRemove(List? elements) : super(elements);

  @override
  firestore_interop.FieldValue? _jsify() {
    // This uses var arg so cannot use js package
    return callMethod(
        firestore_interop.arrayRemove, 'apply', [null, jsify(elements)]);
  }

  @override
  String toString() => 'FieldValue.arrayRemove($elements)';
}

class _FieldValueIncrement implements FieldValue {
  final num n;

  _FieldValueIncrement(this.n);

  @override
  firestore_interop.FieldValue _jsify() => firestore_interop.increment(n);

  @override
  String toString() => 'FieldValue.increment($n)';
}

dynamic jsifyFieldValue(FieldValue fieldValue) => fieldValue._jsify();

/// Sentinel values that can be used when writing document fields with set()
/// or update().
abstract class FieldValue {
  firestore_interop.FieldValue? _jsify() {
    throw UnimplementedError('_jsify() has not been implemented');
  }

  static FieldValue serverTimestamp() => _serverTimestamp;

  static FieldValue delete() => _delete;

  static FieldValue arrayUnion(List? elements) =>
      _FieldValueArrayUnion(elements);

  static FieldValue arrayRemove(List? elements) =>
      _FieldValueArrayRemove(elements);

  // If either the operand or the current field value uses floating point
  // precision, all arithmetic follows IEEE 754 semantics. If both values are
  // integers, values outside of JavaScript's safe number range
  // (Number.MIN_SAFE_INTEGER to Number.MAX_SAFE_INTEGER) are also subject
  // to precision loss. Furthermore, once processed by the Firestore backend,
  // all integer operations are capped between -2^63 and 2^63-1.
  static FieldValue increment(num n) => _FieldValueIncrement(n);

  FieldValue._();

  static final FieldValue _serverTimestamp = _FieldValueServerTimestamp();
  static final FieldValue _delete = _FieldValueDelete();
}

class AggregateQuery {
  AggregateQuery(Query query) : _jsQuery = query.jsObject;
  final firestore_interop.QueryJsImpl _jsQuery;
  Future<AggregateQuerySnapshot> get() async {
    return handleThenable<firestore_interop.AggregateQuerySnapshotJsImpl>(
            firestore_interop.getCountFromServer(_jsQuery))
        .then(AggregateQuerySnapshot.getInstance);
  }
}

class AggregateQuerySnapshot
    extends JsObjectWrapper<firestore_interop.AggregateQuerySnapshotJsImpl> {
  static final _expando = Expando<AggregateQuerySnapshot>();
  late final Map<String, Object> _data;

  /// Creates a new [AggregateQuerySnapshot] from a [jsObject].
  static AggregateQuerySnapshot getInstance(
      firestore_interop.AggregateQuerySnapshotJsImpl jsObject) {
    return _expando[jsObject] ??=
        AggregateQuerySnapshot._fromJsObject(jsObject);
  }

  AggregateQuerySnapshot._fromJsObject(
      firestore_interop.AggregateQuerySnapshotJsImpl jsObject)
      : _data = Map.from(dartify(jsObject.data())),
        super.fromJsObject(jsObject);

  int get count => _data['count']! as int;
}
