// Copyright (c) 2016, Alexandre Roux Tekartik. All rights reserved. Use of this source code

// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:synchronized/extension.dart';
import 'package:synchronized/src/utils.dart';
import 'package:test/test.dart';

class MyClass {
  MyClass(this.text);

  final String text;

  /// Perform a long action that won't be called more than once at a time.
  Future<void> performClassAction() {
    // Lock at the class level
    return runtimeType.synchronized(() async {
      // ...uninterrupted action
    });
  }

  /// Perform a long action that won't be called more than once at a time.
  Future<void> performAction() {
    // Lock at the class level
    return synchronized(() async {
      // ...uninterrupted action
    });
  }

  @override
  int get hashCode => text.hashCode;

  @override
  bool operator ==(other) {
    if (other is MyClass) {
      return (other.text == text);
    }
    return false;
  }
}

void main() {
  group('extension', () {
    test('order', () async {
      final lock = 'test';
      final list = <int>[];
      final future1 = lock.synchronized(() async {
        list.add(1);
      });
      final future2 = ('${'te'}${'st'}').synchronized(() async {
        await sleep(10);
        list.add(2);
        return 'text';
      });
      final future3 = lock.synchronized(() {
        list.add(3);
        return 1234;
      });
      expect(list, [1]);
      await Future.wait([future1, future2, future3]);
      expect(await future1, isNull);
      expect(await future2, 'text');
      expect(await future3, 1234);
      expect(list, [1, 2, 3]);
    });

    test('non-reentrant', () async {
      Object? exception;
      await 'non-reentrant'.synchronized(() async {
        try {
          await 'non-reentrant'
              .synchronized(() {}, timeout: const Duration(seconds: 1));
        } catch (e) {
          exception = e;
        }
      });
      expect(exception, const TypeMatcher<TimeoutException>());
    });

    test('Myclass non-reentrant', () async {
      await MyClass('non-reentrant').synchronized(() async {
        await MyClass('non-reentrant-distinct')
            .synchronized(() {}, timeout: const Duration(seconds: 1));
      });
    });

    test('doc', () async {
      var myObject = MyClass('doc');

      // ignore: unawaited_futures
      myObject.synchronized(() async {
        // ...uninterrupted action
      });
    });
  });
}
