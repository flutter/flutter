// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library gcloud.test.service_scope_test;

import 'dart:async';

import 'package:gcloud/service_scope.dart' as ss;
import 'package:test/test.dart';

void main() {
  test('no-service-scope', () {
    expect(() => ss.register(1, 'foobar'), throwsA(isStateError));
    expect(
        () => ss.registerScopeExitCallback(() => null), throwsA(isStateError));
    expect(() => ss.lookup(1), throwsA(isStateError));

    var c = Completer.sync();
    ss.fork(expectAsync0(() {
      c.complete();
      return Future.value();
    }));

    // Assert that after fork()ing we still don't have a service scope outside
    // of the zone created by the fork()ing.
    c.future.then(expectAsync1((_) {
      expect(() => ss.register(1, 'foobar'), throwsA(isStateError));
      expect(() => ss.registerScopeExitCallback(() => null),
          throwsA(isStateError));
      expect(() => ss.lookup(1), throwsA(isStateError));
    }));
  });

  test('non-existent-key', () {
    return ss.fork(expectAsync0(() {
      expect(ss.lookup(1), isNull);
      return Future.value();
    }));
  });

  test('error-on-double-insert', () {
    // Ensure that inserting twice with the same key results in an error.
    return ss.fork(expectAsync0(() => Future.sync(() {
          ss.register(1, 'firstValue');
          expect(() => ss.register(1, 'firstValue'), throwsA(isArgumentError));
        })));
  });

  test('only-cleanup', () {
    return ss.fork(expectAsync0(() => Future.sync(() {
          ss.registerScopeExitCallback(expectAsync0(() => null));
        })));
  });

  test('correct-insertion-and-cleanup-order', () {
    // Ensure cleanup functions are called in the reverse order of inserting
    // their entries.
    var insertions = 0;
    return ss.fork(expectAsync0(() => Future.value(() {
          var num = 10;

          for (var i = 0; i < num; i++) {
            var key = i;

            insertions++;
            ss.register(key, 'value$i');
            ss.registerScopeExitCallback(expectAsync0(() {
              expect(insertions, equals(i + 1));
              insertions--;
              return null;
            }));

            for (var j = 0; j <= num; j++) {
              if (j <= i) {
                expect(ss.lookup(key), 'value$i');
              } else {
                expect(ss.lookup(key), isNull);
              }
            }
          }
        })));
  });

  test('onion-cleanup', () {
    // Ensures that a cleanup method can look up things registered before it.
    return ss.fork(expectAsync0(() {
      ss.registerScopeExitCallback(expectAsync0(() {
        expect(ss.lookup(1), isNull);
        expect(ss.lookup(2), isNull);
        return null;
      }));
      ss.register(1, 'value1');
      ss.registerScopeExitCallback(expectAsync0(() {
        expect(ss.lookup(1), equals('value1'));
        expect(ss.lookup(2), isNull);
        return null;
      }));
      ss.register(2, 'value2', onScopeExit: expectAsync0(() {
        expect(ss.lookup(1), equals('value1'));
        expect(ss.lookup(2), isNull);
        return null;
      }));
      ss.registerScopeExitCallback(expectAsync0(() {
        expect(ss.lookup(1), 'value1');
        expect(ss.lookup(2), 'value2');
        return null;
      }));
      return Future.value();
    }));
  });

  test('correct-insertion-and-cleanup-order--errors', () {
    // Ensure that all cleanup functions will be called - even if some of them
    // result in an error.
    // Ensure the fork() error message contains all error messages from the
    // failed cleanup() calls.
    var insertions = 0;
    return ss
        .fork(() => Future.sync(() {
              for (var i = 0; i < 10; i++) {
                insertions++;
                ss.register(i, 'value$i');
                ss.registerScopeExitCallback(() {
                  expect(insertions, equals(i + 1));
                  insertions--;
                  if (i.isEven) throw 'xx${i}yy';
                  return null;
                });
              }
            }))
        .catchError(expectAsync2((e, _) {
      for (var i = 0; i < 10; i++) {
        expect('$e'.contains('xx${i}yy'), equals(i.isEven));
      }
    }));
  });

  test('service-scope-destroyed-after-callback-completes', () {
    // Ensure that once the closure passed to fork() completes, the service
    // scope is destroyed.
    return ss.fork(expectAsync0(() => Future.sync(() {
          var key = 1;
          ss.register(key, 'firstValue');
          ss.registerScopeExitCallback(Zone.current.bindCallback(() {
            // Spawn an async task which will be run after the cleanups to ensure
            // the service scope got destroyed.
            Timer.run(expectAsync0(() {
              expect(() => ss.lookup(key), throwsA(isStateError));
              expect(() => ss.register(2, 'value'), throwsA(isStateError));
              expect(() => ss.registerScopeExitCallback(() => null),
                  throwsA(isStateError));
            }));
            return null;
          }));
          expect(ss.lookup(key), equals('firstValue'));
        })));
  });

  test('override-parent-value', () {
    // Ensure that once the closure passed to fork() completes, the service
    // scope is destroyed.
    return ss.fork(expectAsync0(() => Future.sync(() {
          var key = 1;
          ss.register(key, 'firstValue');
          expect(ss.lookup(key), equals('firstValue'));

          return ss.fork(expectAsync0(() => Future.sync(() {
                ss.register(key, 'secondValue');
                expect(ss.lookup(key), equals('secondValue'));
              })));
        })));
  });

  test('fork-onError-handler', () {
    // Ensure that once the closure passed to fork() completes, the service
    // scope is destroyed.
    ss.fork(expectAsync0(() {
      Timer.run(() => throw StateError('foobar'));
      return Future.value();
    }), onError: expectAsync2((error, _) {
      expect(error, isStateError);
    }));
  });

  test('nested-fork-and-insert', () {
    // Ensure that independently fork()ed serice scopes can insert keys
    // independently and they cannot see each others values but can see parent
    // service scope values.
    var rootKey = 1;
    var subKey = 2;
    var subKey1 = 3;
    var subKey2 = 4;

    return ss.fork(expectAsync0(() {
      var cleanupFork1 = 0;
      var cleanupFork2 = 0;

      ss.register(rootKey, 'root');
      ss.registerScopeExitCallback(expectAsync0(() {
        expect(cleanupFork1, equals(2));
        expect(cleanupFork2, equals(2));
        return null;
      }));
      expect(ss.lookup(rootKey), equals('root'));

      Future spawnChild(Object ownSubKey, Object otherSubKey, int i,
          ss.ScopeExitCallback cleanup) {
        return ss.fork(expectAsync0(() => Future.sync(() {
              ss.register(subKey, 'fork$i');
              ss.registerScopeExitCallback(cleanup);
              ss.register(ownSubKey, 'sub$i');
              ss.registerScopeExitCallback(cleanup);

              expect(ss.lookup(rootKey), equals('root'));
              expect(ss.lookup(subKey), equals('fork$i'));
              expect(ss.lookup(ownSubKey), equals('sub$i'));
              expect(ss.lookup(otherSubKey), isNull);
            })));
      }

      return Future.wait([
        spawnChild(subKey1, subKey2, 1, () {
          cleanupFork1++;
          return null;
        }),
        spawnChild(subKey2, subKey1, 2, () {
          cleanupFork2++;
          return null;
        }),
      ]);
    }));
  });
}
