// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library gcloud.db.meta_model;

import '../db.dart' as db;

@db.Kind(name: '__namespace__')
class Namespace extends db.ExpandoModel {
  // ignore: constant_identifier_names
  static const int EmptyNamespaceId = 1;

  String? get name {
    // The default namespace will be reported with id 1.
    if (id == Namespace.EmptyNamespaceId) return null;
    return id as String;
  }
}

@db.Kind(name: '__kind__')
class Kind extends db.Model {
  String get name => id as String;
}
