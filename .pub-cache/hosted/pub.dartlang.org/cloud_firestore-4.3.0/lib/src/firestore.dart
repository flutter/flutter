// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

/// The entry point for accessing a [FirebaseFirestore].
///
/// You can get an instance by calling [FirebaseFirestore.instance]. The instance
/// can also be created with a secondary [Firebase] app by calling
/// [FirebaseFirestore.instanceFor], for example:
///
/// ```dart
/// FirebaseApp secondaryApp = Firebase.app('SecondaryApp');
///
/// FirebaseFirestore firestore = FirebaseFirestore.instanceFor(app: secondaryApp);
/// ```
class FirebaseFirestore extends FirebasePluginPlatform {
  FirebaseFirestore._({required this.app})
      : super(app.name, 'plugins.flutter.io/firebase_firestore');

  static final Map<String, FirebaseFirestore> _cachedInstances = {};

  /// Returns an instance using the default [FirebaseApp].
  static FirebaseFirestore get instance {
    return FirebaseFirestore.instanceFor(
      app: Firebase.app(),
    );
  }

  /// Returns an instance using a specified [FirebaseApp].
  static FirebaseFirestore instanceFor({required FirebaseApp app}) {
    if (_cachedInstances.containsKey(app.name)) {
      return _cachedInstances[app.name]!;
    }

    FirebaseFirestore newInstance = FirebaseFirestore._(app: app);
    _cachedInstances[app.name] = newInstance;

    return newInstance;
  }

  // Cached and lazily loaded instance of [FirestorePlatform] to avoid
  // creating a [MethodChannelFirestore] when not needed or creating an
  // instance with the default app before a user specifies an app.
  FirebaseFirestorePlatform? _delegatePackingProperty;

  FirebaseFirestorePlatform get _delegate {
    return _delegatePackingProperty ??=
        FirebaseFirestorePlatform.instanceFor(app: app);
  }

  /// The [FirebaseApp] for this current [FirebaseFirestore] instance.
  FirebaseApp app;

  /// Gets a [CollectionReference] for the specified Firestore path.
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    assert(
      collectionPath.isNotEmpty,
      'a collectionPath path must be a non-empty string',
    );
    assert(
      !collectionPath.contains('//'),
      'a collection path must not contain "//"',
    );
    assert(
      isValidCollectionPath(collectionPath),
      'a collection path must point to a valid collection.',
    );

    return _JsonCollectionReference(this, _delegate.collection(collectionPath));
  }

  /// Returns a [WriteBatch], used for performing multiple writes as a single
  /// atomic operation.
  ///
  /// Unlike [Transaction]s, [WriteBatch]es are persisted offline and therefore are
  /// preferable when you don’t need to condition your writes on read data.
  WriteBatch batch() {
    return WriteBatch._(this, _delegate.batch());
  }

  /// Clears any persisted data for the current instance.
  Future<void> clearPersistence() {
    return _delegate.clearPersistence();
  }

  /// Enable persistence of Firestore data.
  ///
  /// This is a web-only method. Use [Settings.persistenceEnabled] for non-web platforms.
  Future<void> enablePersistence([
    PersistenceSettings? persistenceSettings,
  ]) async {
    return _delegate.enablePersistence(persistenceSettings);
  }

  LoadBundleTask loadBundle(Uint8List bundle) {
    return LoadBundleTask._(_delegate.loadBundle(bundle));
  }

  /// Changes this instance to point to a FirebaseFirestore emulator running locally.
  ///
  /// Set the [host] of the local emulator, such as "localhost"
  /// Set the [port] of the local emulator, such as "8080" (port 8080 is default)
  ///
  /// Note: Must be called immediately, prior to accessing FirebaseFirestore methods.
  /// Do not use with production credentials as emulator traffic is not encrypted.
  void useFirestoreEmulator(String host, int port, {bool sslEnabled = false}) {
    if (kIsWeb) {
      // use useEmulator() API for web as settings are set immediately unlike native platforms
      try {
        _delegate.useEmulator(host, port);
      } catch (e) {
        final String code = (e as dynamic).code;
        // this catches FirebaseError from web that occurs after hot reloading & hot restarting
        if (code != 'failed-precondition') {
          rethrow;
        }
      }
    } else {
      String mappedHost = host;
      // Android considers localhost as 10.0.2.2 - automatically handle this for users.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        if (mappedHost == 'localhost' || mappedHost == '127.0.0.1') {
          // ignore: avoid_print
          print('Mapping Firestore Emulator host "$mappedHost" to "10.0.2.2".');
          mappedHost = '10.0.2.2';
        }
      }

      _delegate.settings = _delegate.settings.copyWith(
        // "sslEnabled" has to be set to false for android to work
        sslEnabled: sslEnabled,
        host: '$mappedHost:$port',
      );
    }
  }

  /// Performs a [namedQueryGet] and decode the result using [Query.withConverter].
  Future<QuerySnapshot<T>> namedQueryWithConverterGet<T>(
    String name, {
    GetOptions options = const GetOptions(),
    required FromFirestore<T> fromFirestore,
    required ToFirestore<T> toFirestore,
  }) async {
    final snapshot = await namedQueryGet(name, options: options);

    return _WithConverterQuerySnapshot<T>(snapshot, fromFirestore, toFirestore);
  }

  /// Reads a [QuerySnapshot] if a namedQuery has been retrieved and passed as a [Buffer] to [loadBundle()]. To read from cache, pass [GetOptions.source] value as [Source.cache].
  /// To read from the Firestore backend, use [GetOptions.source] as [Source.server].
  Future<QuerySnapshot<Map<String, dynamic>>> namedQueryGet(
    String name, {
    GetOptions options = const GetOptions(),
  }) async {
    QuerySnapshotPlatform snapshotDelegate =
        await _delegate.namedQueryGet(name, options: options);
    return _JsonQuerySnapshot(FirebaseFirestore.instance, snapshotDelegate);
  }

  /// Gets a [Query] for the specified collection group.
  Query<Map<String, dynamic>> collectionGroup(String collectionPath) {
    assert(
      collectionPath.isNotEmpty,
      'a collection path must be a non-empty string',
    );
    assert(
      !collectionPath.contains('/'),
      'a collection path passed to collectionGroup() cannot contain "/"',
    );

    return _JsonQuery(this, _delegate.collectionGroup(collectionPath));
  }

  /// Instructs [FirebaseFirestore] to disable the network for the instance.
  ///
  /// Once disabled, any writes will only resolve once connection has been
  /// restored. However, the local database will still be updated and any
  /// listeners will still trigger.
  Future<void> disableNetwork() {
    return _delegate.disableNetwork();
  }

  /// Gets a [DocumentReference] for the specified Firestore path.
  DocumentReference<Map<String, dynamic>> doc(String documentPath) {
    assert(
      documentPath.isNotEmpty,
      'a document path must be a non-empty string',
    );
    assert(
      !documentPath.contains('//'),
      'a collection path must not contain "//"',
    );
    assert(
      isValidDocumentPath(documentPath),
      'a document path must point to a valid document.',
    );

    return _JsonDocumentReference(this, _delegate.doc(documentPath));
  }

  /// Enables the network for this instance. Any pending local-only writes
  /// will be written to the remote servers.
  Future<void> enableNetwork() {
    return _delegate.enableNetwork();
  }

  /// Returns a [Stream] which is called each time all of the active listeners
  /// have been synchronised.
  Stream<void> snapshotsInSync() {
    return _delegate.snapshotsInSync();
  }

  /// Executes the given [TransactionHandler] and then attempts to commit the
  /// changes applied within an atomic transaction.
  ///
  /// In the [TransactionHandler], a set of reads and writes can be performed
  /// atomically using the [Transaction] object passed to the [TransactionHandler].
  /// After the [TransactionHandler] is run, [FirebaseFirestore] will attempt to apply the
  /// changes to the server. If any of the data read has been modified outside
  /// of this [Transaction] since being read, then the transaction will be
  /// retried by executing the provided [TransactionHandler] again. If the transaction still
  /// fails after 5 retries, then the transaction will fail.s
  ///
  /// The [TransactionHandler] may be executed multiple times, it should be able
  /// to handle multiple executions.
  ///
  /// Data accessed with the transaction will not reflect local changes that
  /// have not been committed. For this reason, it is required that all
  /// reads are performed before any writes. Transactions must be performed
  /// while online. Otherwise, reads will fail, and the final commit will fail.
  ///
  /// By default transactions are limited to 30 seconds of execution time. This
  /// timeout can be adjusted by setting the timeout parameter.
  ///
  /// By default transactions will retry 5 times. You can change the number of attemps
  /// with [maxAttempts]. Attempts should be at least 1.
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    late T output;
    await _delegate.runTransaction(
      (transaction) async {
        output = await transactionHandler(Transaction._(this, transaction));
      },
      timeout: timeout,
      maxAttempts: maxAttempts,
    );

    return output;
  }

  /// Specifies custom settings to be used to configure this [FirebaseFirestore] instance.
  ///
  /// You must set these before invoking any other methods on this [FirebaseFirestore] instance.
  set settings(Settings settings) {
    _delegate.settings = _delegate.settings.copyWith(
      sslEnabled: settings.sslEnabled,
      persistenceEnabled: settings.persistenceEnabled,
      host: settings.host,
      cacheSizeBytes: settings.cacheSizeBytes,
    );
  }

  /// The current [Settings] for this [FirebaseFirestore] instance.
  Settings get settings {
    return _delegate.settings;
  }

  /// Terminates this [FirebaseFirestore] instance.
  ///
  /// After calling [terminate()] only the [clearPersistence()] method may be used.
  /// Any other method will throw a [FirebaseException].
  ///
  /// Termination does not cancel any pending writes, and any promises that are
  /// awaiting a response from the server will not be resolved. If you have
  /// persistence enabled, the next time you start this instance, it will resume
  ///  sending these writes to the server.
  ///
  /// Note: Under normal circumstances, calling [terminate()] is not required.
  /// This method is useful only when you want to force this instance to release
  ///  all of its resources or in combination with [clearPersistence()] to ensure
  ///  that all local state is destroyed between test runs.
  Future<void> terminate() {
    return _delegate.terminate();
  }

  /// Waits until all currently pending writes for the active user have been
  /// acknowledged by the backend.
  ///
  /// The returned Future resolves immediately if there are no outstanding writes.
  /// Otherwise, the Promise waits for all previously issued writes (including
  /// those written in a previous app session), but it does not wait for writes
  /// that were added after the method is called. If you want to wait for
  /// additional writes, call [waitForPendingWrites] again.
  ///
  /// Any outstanding [waitForPendingWrites] calls are rejected during user changes.
  Future<void> waitForPendingWrites() {
    return _delegate.waitForPendingWrites();
  }

  /// Configures indexing for local query execution. Any previous index configuration is overridden.
  ///
  /// The index entries themselves are created asynchronously. You can continue to use queries that
  /// require indexing even if the indices are not yet available. Query execution will automatically
  /// start using the index once the index entries have been written.
  ///
  /// This API is in preview mode and is subject to change.
  @experimental
  Future<void> setIndexConfiguration({
    required List<Index> indexes,
    List<FieldOverrides>? fieldOverrides,
  }) async {
    String json = jsonEncode({
      'indexes': indexes.map((index) => index.toMap()).toList(),
      'fieldOverrides':
          fieldOverrides?.map((index) => index.toMap()).toList() ?? []
    });

    return _delegate.setIndexConfiguration(json);
  }

  /// Configures indexing for local query execution. Any previous index configuration is overridden.
  ///
  /// The index entries themselves are created asynchronously. You can continue to use queries that
  /// require indexing even if the indices are not yet available. Query execution will automatically
  /// start using the index once the index entries have been written.
  /// See Firebase documentation to learn how to configure your index configuration JSON file:
  /// https://firebase.google.com/docs/reference/firestore/indexes
  ///
  /// This API is in preview mode and is subject to change.
  @experimental
  Future<void> setIndexConfigurationFromJSON(String json) async {
    return _delegate.setIndexConfiguration(json);
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is FirebaseFirestore && other.app.name == app.name;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hash(app.name, app.options);

  @override
  String toString() => '$FirebaseFirestore(app: ${app.name})';
}
