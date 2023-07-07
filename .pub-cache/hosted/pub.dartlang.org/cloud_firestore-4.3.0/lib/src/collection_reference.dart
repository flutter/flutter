// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_firestore;

@immutable
// `extends Object?` so that type inference defaults to `Object?` instead of `dynamic`
abstract class CollectionReference<T extends Object?> implements Query<T> {
  /// Returns the ID of the referenced collection.
  String get id;

  /// Returns the parent [DocumentReference] of this collection or `null`.
  ///
  /// If this collection is a root collection, `null` is returned.
  // This always returns a DocumentReference even when using withConverter
  // because we do not know what is the correct type for the parent doc. @override
  DocumentReference<Map<String, dynamic>>? get parent;

  /// A string containing the slash-separated path to this  CollectionReference
  /// (relative to the root of the database).
  String get path;

  /// Returns a `DocumentReference` with an auto-generated ID, after
  /// populating it with provided [data].
  ///
  /// The unique key generated is prefixed with a client-generated timestamp
  /// so that the resulting list will be chronologically-sorted.
  Future<DocumentReference<T>> add(T data);

  /// {@template cloud_firestore.collection_reference.doc}
  /// Returns a `DocumentReference` with the provided path.
  ///
  /// If no [path] is provided, an auto-generated ID is used.
  ///
  /// The unique key generated is prefixed with a client-generated timestamp
  /// so that the resulting list will be chronologically-sorted.
  /// {@endtemplate}
  DocumentReference<T> doc([String? path]);

  /// Transforms a [CollectionReference] to manipulate a custom object instead
  /// of a `Map<String, dynamic>`.
  ///
  /// This makes both read and write operations type-safe.
  ///
  /// ```dart
  /// final modelsRef = FirebaseFirestore
  ///     .instance
  ///     .collection('models')
  ///     .withConverter<Model>(
  ///       fromFirestore: (snapshot, _) => Model.fromJson(snapshot.data()!),
  ///       toFirestore: (model, _) => model.toJson(),
  ///     );
  ///
  /// Future<void> main() async {
  ///   // Writes now take a Model as parameter instead of a Map
  ///   await modelsRef.add(Model());
  ///
  ///   // Reads now return a Model instead of a Map
  ///   final Model model = await modelsRef.doc('123').get().then((s) => s.data());
  /// }
  /// ```
  // `extends Object?` so that type inference defaults to `Object?` instead of `dynamic`
  @override
  CollectionReference<R> withConverter<R extends Object?>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  });
}

/// A [CollectionReference] object can be used for adding documents, getting
/// [DocumentReference]s, and querying for documents (using the methods
/// inherited from [Query]).
@immutable
class _JsonCollectionReference extends _JsonQuery
    implements CollectionReference<Map<String, dynamic>> {
  _JsonCollectionReference(
    FirebaseFirestore firestore,
    CollectionReferencePlatform _delegate,
  ) : super(firestore, _delegate);

  @override
  CollectionReferencePlatform get _delegate =>
      super._delegate as CollectionReferencePlatform;

  @override
  String get id => _delegate.id;

  @override
  DocumentReference<Map<String, dynamic>>? get parent {
    DocumentReferencePlatform? _documentReferencePlatform = _delegate.parent;

    // Only subcollections have a parent
    if (_documentReferencePlatform == null) {
      return null;
    }

    return _JsonDocumentReference(firestore, _documentReferencePlatform);
  }

  @override
  String get path => _delegate.path;

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(
    Map<String, dynamic> data,
  ) async {
    final newDocument = doc();
    await newDocument.set(data);
    return newDocument;
  }

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    if (path != null) {
      assert(path.isNotEmpty, 'a document path must be a non-empty string');
      assert(!path.contains('//'), 'a document path must not contain "//"');
      assert(path != '/', 'a document path must point to a valid document');
    }

    return _JsonDocumentReference(firestore, _delegate.doc(path));
  }

  @override
  CollectionReference<R> withConverter<R extends Object?>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  }) {
    return _WithConverterCollectionReference(
      this,
      fromFirestore,
      toFirestore,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _JsonCollectionReference &&
      other.runtimeType == runtimeType &&
      other.firestore == firestore &&
      other.path == path;

  @override
  int get hashCode => Object.hash(firestore, path);

  @override
  String toString() => 'CollectionReference<Map<String, dynamic>>($path)';
}

/// A [CollectionReference] object can be used for adding documents, getting
/// [DocumentReference]s, and querying for documents (using the methods
/// inherited from [Query]).
@immutable
class _WithConverterCollectionReference<T extends Object?>
    extends _WithConverterQuery<T> implements CollectionReference<T> {
  _WithConverterCollectionReference(
    CollectionReference<Map<String, dynamic>> collectionReference,
    FromFirestore<T> fromFirestore,
    ToFirestore<T> toFirestore,
  ) : super(collectionReference, fromFirestore, toFirestore);

  CollectionReference<Map<String, dynamic>>
      get _originalCollectionReferenceQuery {
    return super._originalQuery as CollectionReference<Map<String, dynamic>>;
  }

  @override
  String get id => _originalCollectionReferenceQuery.id;

  @override
  DocumentReference<Map<String, dynamic>>? get parent {
    return _originalCollectionReferenceQuery.parent;
  }

  @override
  String get path => _originalCollectionReferenceQuery.path;

  @override
  Future<DocumentReference<T>> add(T data) async {
    final snapshot = await _originalCollectionReferenceQuery.add(
      _toFirestore(data, null),
    );

    return _WithConverterDocumentReference<T>(
      snapshot,
      _fromFirestore,
      _toFirestore,
    );
  }

  @override
  DocumentReference<T> doc([String? path]) {
    return _WithConverterDocumentReference<T>(
      _originalCollectionReferenceQuery.doc(path),
      _fromFirestore,
      _toFirestore,
    );
  }

  @override
  CollectionReference<R> withConverter<R extends Object?>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  }) {
    return _WithConverterCollectionReference(
      _originalCollectionReferenceQuery,
      fromFirestore,
      toFirestore,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _WithConverterCollectionReference<T> &&
      other.runtimeType == runtimeType &&
      other._originalCollectionReferenceQuery ==
          _originalCollectionReferenceQuery &&
      other._fromFirestore == _fromFirestore &&
      other._toFirestore == _toFirestore;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        _originalCollectionReferenceQuery,
        _fromFirestore,
        _toFirestore,
      );

  @override
  String toString() => 'CollectionReference<$T>($path)';
}
