// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'dart:async';

import 'package:build/build.dart';
import 'package:test/test.dart';

void main() {
  late ResourceManager resourceManager;
  setUp(() {
    resourceManager = ResourceManager();
  });

  tearDown(() async {
    await resourceManager.disposeAll();
  });

  group('ResourceManager', () {
    test('gives the same instance until disposed', () async {
      var last = 0;
      var intResource = Resource(() => last++);
      var first = await resourceManager.fetch(intResource);
      expect(first, 0);
      var second = await resourceManager.fetch(intResource);
      expect(second, first);
      await resourceManager.disposeAll();
      var third = await resourceManager.fetch(intResource);
      expect(third, 1);
    });

    test('calls dispose callback with last instance', () async {
      var disposed = false;
      var last = 0;
      var intResource = Resource(() => last, dispose: (int instance) {
        expect(instance, last);
        last++;
        disposed = true;
      });
      var first = await resourceManager.fetch(intResource);
      expect(first, 0);
      await resourceManager.disposeAll();
      expect(disposed, true);
      var second = await resourceManager.fetch(intResource);
      expect(second, 1);
    });

    test('can asynchronously get resources', () async {
      var last = 0;
      var intResource = Resource(() => Future.value(++last));
      var actual = await resourceManager.fetch(intResource);
      expect(actual, last);
    });

    test('can asynchronously dispose resources', () async {
      var disposed = false;
      var intResource = Resource(() => 0, dispose: (_) async {
        await Future<void>.delayed(Duration(milliseconds: 20));
        disposed = true;
      });
      await resourceManager.fetch(intResource);
      await resourceManager.disposeAll();
      expect(disposed, true);
    });

    test('can fetch and dispose multiple resources', () async {
      var numDisposed = 0;
      final length = 10;
      var resources = List<Resource<int>>.generate(
          length,
          (i) => Resource(() => i, dispose: (instance) {
                expect(instance, i);
                numDisposed++;
              }));
      var values =
          await Future.wait(resources.map((r) => resourceManager.fetch(r)));
      expect(values, List<int>.generate(length, (i) => i));
      await resourceManager.disposeAll();
      expect(numDisposed, length);
    });

    test('doesn\'t share resources with other ResourceManagers', () async {
      var otherManager = ResourceManager();
      var last = 0;
      var intResource = Resource(() => last++);

      var original = await resourceManager.fetch(intResource);
      var other = await otherManager.fetch(intResource);
      expect(original, isNot(other));
    });
  });
}
