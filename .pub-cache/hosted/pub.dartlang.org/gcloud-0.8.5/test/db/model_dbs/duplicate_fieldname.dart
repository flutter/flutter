// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library gcloud.db.model_test.duplicate_fieldname;

import 'package:gcloud/db.dart' as db;

@db.Kind()
class A extends db.Model {
  @db.IntProperty()
  int? foo;
}

@db.Kind()
class B extends A {
  @override
  @db.IntProperty(propertyName: 'bar')
  // ignore: overridden_fields
  int? foo;
}
