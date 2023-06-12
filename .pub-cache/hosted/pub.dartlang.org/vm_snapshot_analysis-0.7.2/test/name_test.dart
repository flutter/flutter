// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:vm_snapshot_analysis/name.dart';

void main() async {
  group('name', () {
    test('scrubbing', () async {
      expect(Name('[Optimized] [Stub] name').scrubbed, equals('name'),
          reason: 'Prefixes are removed');
      expect(
          Name('name@1234.of@5678.method@9').scrubbed, equals('name.of.method'),
          reason: 'Private keys are removed');
      expect(Name('name@1234.<anonymous closure @1234>').scrubbed,
          equals('name.<anonymous closure @1234>'),
          reason: 'Closure token positions are preserved');
    });

    test('stub-name-parsing', () async {
      expect(Name('[Stub] name').isStub, isTrue);
      expect(Name('[Stub] name').isAllocationStub, isFalse);
      expect(Name('[Stub] Allocate ').isStub, isTrue);
      expect(Name('[Stub] Allocate ').isAllocationStub, isTrue);
      expect(Name('[Optimized] name').isStub, isFalse);
      expect(Name('[Optimized] name').isAllocationStub, isFalse);
    });
  });
}
