// Copyright (c) 2016, Alexandre Roux Tekartik. All rights reserved. Use of this source code

// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:synchronized/extension.dart';
import 'package:synchronized/src/basic_lock.dart';
import 'package:synchronized/src/extension_impl.dart';
import 'package:test/test.dart';

void main() {
  group('extension_impl', () {
    test('cache', () async {
      expect(cacheLocks, isEmpty);
      await 'test'.synchronized(() {
        expect(cacheLocks['test'], const TypeMatcher<BasicLock>());
      });
      expect(cacheLocks, isEmpty);
    });
  });
}
