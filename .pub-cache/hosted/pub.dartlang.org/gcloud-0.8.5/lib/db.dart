// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library gcloud.db;

import 'dart:collection';
// dart:core is imported explicitly so it is available at top-level without
//   the `core` prefix defined below.
import 'dart:core';
// Importing `dart:core` as `core` to allow access to `String` in `IdType`
//   without conflicts.
import 'dart:core' as core;
import 'dart:mirrors' as mirrors;

import 'package:meta/meta.dart';

import 'common.dart' show StreamFromPages;
import 'datastore.dart' as ds;
import 'service_scope.dart' as ss;

part 'src/db/annotations.dart';
part 'src/db/db.dart';
part 'src/db/exceptions.dart';
part 'src/db/model_db.dart';
part 'src/db/model_db_impl.dart';
part 'src/db/models.dart';

const Symbol _dbKey = #gcloud.db;

/// Access the [DatastoreDB] object available in the current service scope.
///
/// The returned object will be the one which was previously registered with
/// [registerDbService] within the current (or a parent) service scope.
///
/// Accessing this getter outside of a service scope will result in an error.
/// See the `package:gcloud/service_scope.dart` library for more information.
DatastoreDB get dbService => ss.lookup(_dbKey) as DatastoreDB;

/// Registers the [DatastoreDB] object within the current service scope.
///
/// The provided `db` object will be available via the top-level `dbService`
/// getter.
///
/// Calling this function outside of a service scope will result in an error.
/// Calling this function more than once inside the same service scope is not
/// allowed.
void registerDbService(DatastoreDB db) {
  ss.register(_dbKey, db);
}
