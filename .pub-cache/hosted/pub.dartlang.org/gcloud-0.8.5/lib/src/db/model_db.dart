// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of gcloud.db;

/// A database of all registered models.
///
/// Responsible for converting between dart model objects and datastore entities.
abstract class ModelDB {
  /// Converts a [ds.Key] to a [Key].
  Key fromDatastoreKey(ds.Key datastoreKey);

  /// Converts a [Key] to a [ds.Key].
  ds.Key toDatastoreKey(Key dbKey);

  /// Converts a [Model] instance to a [ds.Entity].
  ds.Entity toDatastoreEntity(Model model);

  /// Converts a [ds.Entity] to a [Model] instance.
  T? fromDatastoreEntity<T extends Model>(ds.Entity? entity);

  /// Returns the kind name for instances of [type].
  String kindName(Type type);

  /// Returns the property name used for [fieldName]
  // TODO: Get rid of this eventually.
  String? fieldNameToPropertyName(String kind, String fieldName);

  /// Converts [value] according to the [Property] named [fieldName] in [kind].
  Object? toDatastoreValue(String kind, String fieldName, Object? value,
      {bool forComparison = false});
}
