// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The Index class follows the [Index definition](https://firebase.google.com/docs/reference/firestore/indexes/#indexes).
class Index {
  Index({
    required this.collectionGroup,
    required this.fields,
    required this.queryScope,
  });

  final String collectionGroup;
  final QueryScope queryScope;
  final List<IndexField> fields;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'collectionGroup': collectionGroup,
      'fields': fields.map((IndexField field) => field.toMap()).toList(),
      'queryScope': queryScope == QueryScope.collection
          ? 'COLLECTION'
          : 'COLLECTION_GROUP',
    };
  }
}

class IndexField {
  IndexField({required this.fieldPath, this.order, this.arrayConfig});

  final String fieldPath;
  final Order? order;
  final ArrayConfig? arrayConfig;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fieldPath': fieldPath,
      if (order != null)
        'order': order == Order.ascending ? 'ASCENDING' : 'DESCENDING',
      if (arrayConfig != null) 'arrayConfig': 'CONTAINS',
    };
  }
}

/// The FieldOverrides class follows the [FieldOverrides definition](https://firebase.google.com/docs/reference/firestore/indexes/#fieldoverrides).
class FieldOverrides {
  FieldOverrides({
    required this.collectionGroup,
    required this.fieldPath,
    required this.indexes,
  });

  final String collectionGroup;
  final String fieldPath;
  final List<FieldOverrideIndex> indexes;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'collectionGroup': collectionGroup,
      'fieldPath': fieldPath,
      'indexes':
          indexes.map((FieldOverrideIndex index) => index.toMap()).toList(),
    };
  }
}

class FieldOverrideIndex {
  FieldOverrideIndex({required this.queryScope, this.order, this.arrayConfig});

  final String queryScope;
  final Order? order;
  final ArrayConfig? arrayConfig;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'queryScope': queryScope,
      if (order != null)
        'order': order == Order.ascending ? 'ASCENDING' : 'DESCENDING',
      if (arrayConfig != null) 'arrayConfig': 'CONTAINS',
    };
  }
}

enum Order {
  ascending,
  descending,
}

enum ArrayConfig {
  contains,
}

enum QueryScope {
  collection,
  collectionGroup,
}
