// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage.uuid_test;

import 'package:test/test.dart';
import 'package:usage/uuid/uuid.dart';

void main() => defineTests();

void defineTests() {
  group('uuid', () {
    // xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
    test('simple', () {
      var uuid = Uuid();
      var result = uuid.generateV4();
      expect(result.length, 36);
      expect(result[8], '-');
      expect(result[13], '-');
      expect(result[18], '-');
      expect(result[23], '-');
    });

    test('can parse', () {
      var uuid = Uuid();
      var result = uuid.generateV4();
      expect(int.parse(result.substring(0, 8), radix: 16), isNotNull);
      expect(int.parse(result.substring(9, 13), radix: 16), isNotNull);
      expect(int.parse(result.substring(14, 18), radix: 16), isNotNull);
      expect(int.parse(result.substring(19, 23), radix: 16), isNotNull);
      expect(int.parse(result.substring(24, 36), radix: 16), isNotNull);
    });

    test('special bits', () {
      var uuid = Uuid();
      var result = uuid.generateV4();
      expect(result[14], '4');
      expect(result[19].toLowerCase(), isIn('89ab'));

      result = uuid.generateV4();
      expect(result[19].toLowerCase(), isIn('89ab'));

      result = uuid.generateV4();
      expect(result[19].toLowerCase(), isIn('89ab'));
    });

    test('is pretty random', () {
      var set = <String>{};

      var uuid = Uuid();
      for (var i = 0; i < 64; i++) {
        var val = uuid.generateV4();
        expect(set, isNot(contains(val)));
        set.add(val);
      }

      uuid = Uuid();
      for (var i = 0; i < 64; i++) {
        var val = uuid.generateV4();
        expect(set, isNot(contains(val)));
        set.add(val);
      }

      uuid = Uuid();
      for (var i = 0; i < 64; i++) {
        var val = uuid.generateV4();
        expect(set, isNot(contains(val)));
        set.add(val);
      }
    });
  });
}
