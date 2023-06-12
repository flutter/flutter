// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

@TestOn('vm')
import 'package:dwds/src/utilities/objects.dart';
import 'package:test/test.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

void main() {
  group('Property', () {
    final exampleMap = {'objectId': '1234', 'value': 'abcd'};

    test('from a map', () {
      // Verify that we behave the same whether created from a Map
      // or from a RemoteObject.
      final property = Property({'name': 'prop', 'value': exampleMap});
      expect(property.rawValue, exampleMap);
      expect(property.value.objectId, '1234');
      expect(property.value.value, 'abcd');
      expect(property.name, 'prop');
    });
    test('from a RemoteObject', () {
      final remoteObject = RemoteObject({'objectId': '1234', 'value': 'abcd'});
      final property = Property({'name': 'prop', 'value': remoteObject});
      expect(property.rawValue, remoteObject);
      expect(property.value.objectId, '1234');
      expect(property.value.value, 'abcd');
      expect(property.name, 'prop');
    });

    test('stripping the "Symbol(" from a private field', () {
      final property =
          Property({'name': 'Symbol(_privateThing)', 'value': exampleMap});
      expect(property.name, '_privateThing');
    });
  });
}
