// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library gcloud.db.model_test.duplicate_property;

import 'package:gcloud/db.dart' as db;

@db.Kind()
class A extends db.Model {
  @db.IntProperty()
  int? foo;

  @db.IntProperty(propertyName: 'foo')
  int? bar;
}
