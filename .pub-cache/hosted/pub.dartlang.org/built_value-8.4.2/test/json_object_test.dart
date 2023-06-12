// Copyright (c) 2021, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_value/json_object.dart';
import 'package:test/test.dart';

void main() {
  group(JsonObject, () {
    test('can be instantiated from Map<dynamic, dynamic>', () {
      JsonObject({});
    });

    test('allows access to Map<String?, dynamic>', () {
      var map = JsonObject(<String?, dynamic>{'one': 1});
      expect(map.asMap['one'], 1);
    });
  });
}
