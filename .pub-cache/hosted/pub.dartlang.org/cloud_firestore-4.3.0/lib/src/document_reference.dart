// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

/// A [DocumentReference] refers to a document location in a [FirebaseFirestore] database
/// and can be used to write, read, or listen to the location.
///
/// The document at the referenced location may or may not exist.
/// A [DocumentReference] can also be used to create a [CollectionReference]
/// to a subcollection.
@sealed
@immutable
abstract class DocumentReference<T extends Object?> {
  DocumentReferencePlatform get _delegate;

  /// The Firestore instance associated with this document reference.
  FirebaseFirestore get firestore;

  /// This document's given ID within the collection.
  String get id;

  /// The parent [CollectionReference] of this document.
  CollectionReference<T> get parent;

  /// A string representing the path of the referenced document (relative to the
  /// root of the database).
  String get path;

  /// Gets a [CollectionReference] instance that refers to the collection at the
  /// specified path, relative from this [DocumentReference].
  CollectionReference<Map<String, dynamic>> collection(String collectionPath);

  /// Deletes the current document from the collection.
  Future<void> delete();

  /// Updates data on the document. Data will be merged with any existing
  /// document data.
  ///
  /// If no document exists yet, the update will fail.
  Future<void> update(Map<String, Object?> data);

  /// Reads the document referenced by this [DocumentReference].
  ///
  /// By providing [options], this method can be configured to fetch results only
  /// from the server, only from the local cache or attempt to fetch results
  /// from the server and fall back to the cache (which is the default).
  Future<DocumentSnapshot<T>> get([GetOptions? options]);

  /// Notifies of document updates at this location.
  ///
  /// An initial event is immediately sent, and further events will be
  /// sent whenever the document is modified.
  Stream<DocumentSnapshot<T>> snapshots({bool includeMetadataChanges = false});

  /// Sets data on the document, overwriting any existing data. If the document
  /// does not yet exist, it will be created.
  ///
  /// If [SetOptions] are provided, the data will be merged into an existing
  /// document instead of overwriting.
  Future<void> set(T data, [SetOptions? options]);

  /// Transforms a [DocumentReference] to manipulate a custom object instead
  /// of a `Map<String, dynamic>`.
  ///
  /// This makes both read and write operations type-safe.
  ///
  /// ```dart
  /// final modelRef = FirebaseFirestore
  ///     .instance
  ///     .collection('models')
  ///     .doc('123')
  ///     .withConverter<Model>(
  ///       fromFirestore: (snapshot, _) => Model.fromJson(snapshot.data()!),
  ///       toFirestore: (model, _) => model.toJson(),
  ///     );
  ///
  /// Future<void> main() async {
  ///   // Writes now take a Model as parameter instead of a Map
  ///   await modelRef.set(Model());
  ///
  ///   // Reads now return a Model instead of a Map
  ///   final Model model = await modelRef.get().then((s) => s.data());
  /// }
  /// ```
  DocumentReference<R> withConverter<R>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  });
}

@immutable
class _JsonDocumentReference
    implements DocumentReference<Map<String, dynamic>> {
  _JsonDocumentReference(this.firestore, this._delegate) {
    DocumentReferencePlatform.verify(_delegate);
  }

  @override
  final DocumentReferencePlatform _delegate;

  @override
  final FirebaseFirestore firestore;

  @override
  String get id => _delegate.id;

  @override
  CollectionReference<Map<String, dynamic>> get parent =>
      _JsonCollectionReference(firestore, _delegate.parent);

  @override
  String get path => _delegate.path;

  @override
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

    return _JsonCollectionReference(
      firestore,
      _delegate.collection(collectionPath),
    );
  }

  @override
  Future<void> delete() => _delegate.delete();

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    return _JsonDocumentSnapshot(
      firestore,
      await _delegate.get(
        options ?? const GetOptions(),
      ),
    );
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
  }) {
    return _delegate
        .snapshots(includeMetadataChanges: includeMetadataChanges)
        .map(
          (delegateSnapshot) =>
              _JsonDocumentSnapshot(firestore, delegateSnapshot),
        );
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) {
    return _delegate.set(
      _CodecUtility.replaceValueWithDelegatesInMap(data)!,
      options,
    );
  }

  @override
  Future<void> update(Map<String, Object?> data) {
    return _delegate
        .update(_CodecUtility.replaceValueWithDelegatesInMap(data)!);
  }

  @override
  DocumentReference<T> withConverter<T>({
    required FromFirestore<T> fromFirestore,
    required ToFirestore<T> toFirestore,
  }) {
    return _WithConverterDocumentReference(this, fromFirestore, toFirestore);
  }

  @override
  bool operator ==(Object other) =>
      other is DocumentReference &&
      other.firestore == firestore &&
      other.path == path;

  @override
  int get hashCode => Object.hash(firestore, path);

  @override
  String toString() => 'DocumentReference<Map<String, dynamic>>($path)';
}

/// A [DocumentReference] refers to a document location in a [FirebaseFirestore] database
/// and can be used to write, read, or listen to the location.
///
/// The document at the referenced location may or may not exist.
/// A [DocumentReference] can also be used to create a [CollectionReference]
/// to a subcollection.
@immutable
class _WithConverterDocumentReference<T extends Object?>
    implements DocumentReference<T> {
  _WithConverterDocumentReference(
    this._originalDocumentReference,
    this._fromFirestore,
    this._toFirestore,
  );

  final DocumentReference<Map<String, dynamic>> _originalDocumentReference;
  final FromFirestore<T> _fromFirestore;
  final ToFirestore<T> _toFirestore;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _originalDocumentReference.collection(collectionPath);
  }

  @override
  Future<void> delete() {
    return _originalDocumentReference.delete();
  }

  @override
  Future<_WithConverterDocumentSnapshot<T>> get([GetOptions? options]) {
    return _originalDocumentReference.get(options).then((snapshot) {
      return _WithConverterDocumentSnapshot<T>(
        snapshot,
        _fromFirestore,
        _toFirestore,
      );
    });
  }

  @override
  DocumentReferencePlatform get _delegate =>
      _originalDocumentReference._delegate;

  @override
  FirebaseFirestore get firestore => _originalDocumentReference.firestore;

  @override
  String get id => _originalDocumentReference.id;

  @override
  CollectionReference<T> get parent {
    return _WithConverterCollectionReference<T>(
      _originalDocumentReference.parent,
      _fromFirestore,
      _toFirestore,
    );
  }

  @override
  String get path => _originalDocumentReference.path;

  @override
  Future<void> set(T data, [SetOptions? options]) {
    return _originalDocumentReference.set(
      _toFirestore(data, options),
      options,
    );
  }

  @override
  Stream<_WithConverterDocumentSnapshot<T>> snapshots({
    bool includeMetadataChanges = false,
  }) {
    return _originalDocumentReference
        .snapshots(includeMetadataChanges: includeMetadataChanges)
        .map((snapshot) {
      return _WithConverterDocumentSnapshot<T>(
        snapshot,
        _fromFirestore,
        _toFirestore,
      );
    });
  }

  @override
  Future<void> update(Map<String, Object?> data) {
    return _originalDocumentReference.update(data);
  }

  @override
  DocumentReference<R> withConverter<R>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  }) {
    return _WithConverterDocumentReference(
      _originalDocumentReference,
      fromFirestore,
      toFirestore,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _WithConverterDocumentReference<T> &&
      other.runtimeType == runtimeType &&
      other._originalDocumentReference == _originalDocumentReference &&
      other._fromFirestore == _fromFirestore &&
      other._toFirestore == _toFirestore;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        _originalDocumentReference,
        _fromFirestore,
        _toFirestore,
      );

  @override
  String toString() => 'DocumentReference<$T>($path)';
}
