// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart';

import 'utils.dart';

typedef ChainErrorCallback = void Function(dynamic stack, Chain chain);

void main() {
  group('Chain.parse()', () {
    test('parses a real Chain', () {
      return captureFuture(() => inMicrotask(() => throw 'error'))
          .then((chain) {
        expect(
            Chain.parse(chain.toString()).toString(), equals(chain.toString()));
      });
    });

    test('parses an empty string', () {
      var chain = Chain.parse('');
      expect(chain.traces, isEmpty);
    });

    test('parses a chain containing empty traces', () {
      var chain =
          Chain.parse('===== asynchronous gap ===========================\n'
              '===== asynchronous gap ===========================\n');
      expect(chain.traces, hasLength(3));
      expect(chain.traces[0].frames, isEmpty);
      expect(chain.traces[1].frames, isEmpty);
      expect(chain.traces[2].frames, isEmpty);
    });

    test('parses a chain with VM gaps', () {
      final chain =
          Chain.parse('#1      MyClass.run (package:my_lib.dart:134:5)\n'
              '<asynchronous suspension>\n'
              '#2      main (file:///my_app.dart:9:3)\n'
              '<asynchronous suspension>\n');
      expect(chain.traces, hasLength(2));
      expect(chain.traces[0].frames, hasLength(1));
      expect(chain.traces[0].frames[0].toString(),
          equals('package:my_lib.dart 134:5 in MyClass.run'));
      expect(chain.traces[1].frames, hasLength(1));
      expect(
        chain.traces[1].frames[0].toString(),
        anyOf(
          equals('/my_app.dart 9:3 in main'), // VM
          equals('file:///my_app.dart 9:3 in main'), // Browser
        ),
      );
    });
  });

  group('Chain.capture()', () {
    test('with onError blocks errors', () {
      Chain.capture(() {
        return Future.error('oh no');
      }, onError: expectAsync2((error, chain) {
        expect(error, equals('oh no'));
        expect(chain, isA<Chain>());
      })).then(expectAsync1((_) {}, count: 0),
          onError: expectAsync2((_, __) {}, count: 0));
    });

    test('with no onError blocks errors', () {
      runZonedGuarded(() {
        Chain.capture(() => Future.error('oh no')).then(
            expectAsync1((_) {}, count: 0),
            onError: expectAsync2((_, __) {}, count: 0));
      }, expectAsync2((error, chain) {
        expect(error, equals('oh no'));
        expect(chain, isA<Chain>());
      }));
    });

    test("with errorZone: false doesn't block errors", () {
      expect(Chain.capture(() => Future.error('oh no'), errorZone: false),
          throwsA('oh no'));
    });

    test("doesn't allow onError and errorZone: false", () {
      expect(() => Chain.capture(() {}, onError: (_, __) {}, errorZone: false),
          throwsArgumentError);
    });

    group('with when: false', () {
      test("with no onError doesn't block errors", () {
        expect(Chain.capture(() => Future.error('oh no'), when: false),
            throwsA('oh no'));
      });

      test('with onError blocks errors', () {
        Chain.capture(() {
          return Future.error('oh no');
        }, onError: expectAsync2((error, chain) {
          expect(error, equals('oh no'));
          expect(chain, isA<Chain>());
        }), when: false);
      });

      test("doesn't enable chain-tracking", () {
        return Chain.disable(() {
          return Chain.capture(() {
            var completer = Completer<Chain>();
            inMicrotask(() {
              completer.complete(Chain.current());
            });

            return completer.future.then((chain) {
              expect(chain.traces, hasLength(1));
            });
          }, when: false);
        });
      });
    });
  });

  test('Chain.capture() with custom zoneValues', () {
    return Chain.capture(() {
      expect(Zone.current[#enabled], true);
    }, zoneValues: {#enabled: true});
  });

  group('Chain.disable()', () {
    test('disables chain-tracking', () {
      return Chain.disable(() {
        var completer = Completer<Chain>();
        inMicrotask(() => completer.complete(Chain.current()));

        return completer.future.then((chain) {
          expect(chain.traces, hasLength(1));
        });
      });
    });

    test('Chain.capture() re-enables chain-tracking', () {
      return Chain.disable(() {
        return Chain.capture(() {
          var completer = Completer<Chain>();
          inMicrotask(() => completer.complete(Chain.current()));

          return completer.future.then((chain) {
            expect(chain.traces, hasLength(2));
          });
        });
      });
    });

    test('preserves parent zones of the capture zone', () {
      // The outer disable call turns off the test package's chain-tracking.
      return Chain.disable(() {
        return runZoned(() {
          return Chain.capture(() {
            expect(Chain.disable(() => Zone.current[#enabled]), isTrue);
          });
        }, zoneValues: {#enabled: true});
      });
    });

    test('preserves child zones of the capture zone', () {
      // The outer disable call turns off the test package's chain-tracking.
      return Chain.disable(() {
        return Chain.capture(() {
          return runZoned(() {
            expect(Chain.disable(() => Zone.current[#enabled]), isTrue);
          }, zoneValues: {#enabled: true});
        });
      });
    });

    test("with when: false doesn't disable", () {
      return Chain.capture(() {
        return Chain.disable(() {
          var completer = Completer<Chain>();
          inMicrotask(() => completer.complete(Chain.current()));

          return completer.future.then((chain) {
            expect(chain.traces, hasLength(2));
          });
        }, when: false);
      });
    });
  });

  test('toString() ensures that all traces are aligned', () {
    var chain = Chain([
      Trace.parse('short 10:11  Foo.bar\n'),
      Trace.parse('loooooooooooong 10:11  Zop.zoop')
    ]);

    expect(
        chain.toString(),
        equals('short 10:11            Foo.bar\n'
            '===== asynchronous gap ===========================\n'
            'loooooooooooong 10:11  Zop.zoop\n'));
  });

  var userSlashCode = p.join('user', 'code.dart');
  group('Chain.terse', () {
    test('makes each trace terse', () {
      var chain = Chain([
        Trace.parse('dart:core 10:11       Foo.bar\n'
            'dart:core 10:11       Bar.baz\n'
            'user/code.dart 10:11  Bang.qux\n'
            'dart:core 10:11       Zip.zap\n'
            'dart:core 10:11       Zop.zoop'),
        Trace.parse('user/code.dart 10:11                        Bang.qux\n'
            'dart:core 10:11                             Foo.bar\n'
            'package:stack_trace/stack_trace.dart 10:11  Bar.baz\n'
            'dart:core 10:11                             Zip.zap\n'
            'user/code.dart 10:11                        Zop.zoop')
      ]);

      expect(
          chain.terse.toString(),
          equals('dart:core             Bar.baz\n'
              '$userSlashCode 10:11  Bang.qux\n'
              '===== asynchronous gap ===========================\n'
              '$userSlashCode 10:11  Bang.qux\n'
              'dart:core             Zip.zap\n'
              '$userSlashCode 10:11  Zop.zoop\n'));
    });

    test('eliminates internal-only traces', () {
      var chain = Chain([
        Trace.parse('user/code.dart 10:11  Foo.bar\n'
            'dart:core 10:11       Bar.baz'),
        Trace.parse('dart:core 10:11                             Foo.bar\n'
            'package:stack_trace/stack_trace.dart 10:11  Bar.baz\n'
            'dart:core 10:11                             Zip.zap'),
        Trace.parse('user/code.dart 10:11  Foo.bar\n'
            'dart:core 10:11       Bar.baz')
      ]);

      expect(
          chain.terse.toString(),
          equals('$userSlashCode 10:11  Foo.bar\n'
              '===== asynchronous gap ===========================\n'
              '$userSlashCode 10:11  Foo.bar\n'));
    });

    test("doesn't return an empty chain", () {
      var chain = Chain([
        Trace.parse('dart:core 10:11                             Foo.bar\n'
            'package:stack_trace/stack_trace.dart 10:11  Bar.baz\n'
            'dart:core 10:11                             Zip.zap'),
        Trace.parse('dart:core 10:11                             A.b\n'
            'package:stack_trace/stack_trace.dart 10:11  C.d\n'
            'dart:core 10:11                             E.f')
      ]);

      expect(chain.terse.toString(), equals('dart:core  E.f\n'));
    });

    // Regression test for #9
    test("doesn't crash on empty traces", () {
      var chain = Chain([
        Trace.parse('user/code.dart 10:11  Bang.qux'),
        Trace([]),
        Trace.parse('user/code.dart 10:11  Bang.qux')
      ]);

      expect(
          chain.terse.toString(),
          equals('$userSlashCode 10:11  Bang.qux\n'
              '===== asynchronous gap ===========================\n'
              '$userSlashCode 10:11  Bang.qux\n'));
    });
  });

  group('Chain.foldFrames', () {
    test('folds each trace', () {
      var chain = Chain([
        Trace.parse('a.dart 10:11  Foo.bar\n'
            'a.dart 10:11  Bar.baz\n'
            'b.dart 10:11  Bang.qux\n'
            'a.dart 10:11  Zip.zap\n'
            'a.dart 10:11  Zop.zoop'),
        Trace.parse('a.dart 10:11  Foo.bar\n'
            'a.dart 10:11  Bar.baz\n'
            'a.dart 10:11  Bang.qux\n'
            'a.dart 10:11  Zip.zap\n'
            'b.dart 10:11  Zop.zoop')
      ]);

      var folded = chain.foldFrames((frame) => frame.library == 'a.dart');
      expect(
          folded.toString(),
          equals('a.dart 10:11  Bar.baz\n'
              'b.dart 10:11  Bang.qux\n'
              'a.dart 10:11  Zop.zoop\n'
              '===== asynchronous gap ===========================\n'
              'a.dart 10:11  Zip.zap\n'
              'b.dart 10:11  Zop.zoop\n'));
    });

    test('with terse: true, folds core frames as well', () {
      var chain = Chain([
        Trace.parse('a.dart 10:11                        Foo.bar\n'
            'dart:async-patch/future.dart 10:11  Zip.zap\n'
            'b.dart 10:11                        Bang.qux\n'
            'dart:core 10:11                     Bar.baz\n'
            'a.dart 10:11                        Zop.zoop'),
        Trace.parse('a.dart 10:11  Foo.bar\n'
            'a.dart 10:11  Bar.baz\n'
            'a.dart 10:11  Bang.qux\n'
            'a.dart 10:11  Zip.zap\n'
            'b.dart 10:11  Zop.zoop')
      ]);

      var folded =
          chain.foldFrames((frame) => frame.library == 'a.dart', terse: true);
      expect(
          folded.toString(),
          equals('dart:async    Zip.zap\n'
              'b.dart 10:11  Bang.qux\n'
              '===== asynchronous gap ===========================\n'
              'a.dart        Zip.zap\n'
              'b.dart 10:11  Zop.zoop\n'));
    });

    test('eliminates completely-folded traces', () {
      var chain = Chain([
        Trace.parse('a.dart 10:11  Foo.bar\n'
            'b.dart 10:11  Bang.qux'),
        Trace.parse('a.dart 10:11  Foo.bar\n'
            'a.dart 10:11  Bang.qux'),
        Trace.parse('a.dart 10:11  Zip.zap\n'
            'b.dart 10:11  Zop.zoop')
      ]);

      var folded = chain.foldFrames((frame) => frame.library == 'a.dart');
      expect(
          folded.toString(),
          equals('a.dart 10:11  Foo.bar\n'
              'b.dart 10:11  Bang.qux\n'
              '===== asynchronous gap ===========================\n'
              'a.dart 10:11  Zip.zap\n'
              'b.dart 10:11  Zop.zoop\n'));
    });

    test("doesn't return an empty trace", () {
      var chain = Chain([
        Trace.parse('a.dart 10:11  Foo.bar\n'
            'a.dart 10:11  Bang.qux')
      ]);

      var folded = chain.foldFrames((frame) => frame.library == 'a.dart');
      expect(folded.toString(), equals('a.dart 10:11  Bang.qux\n'));
    });
  });

  test('Chain.toTrace eliminates asynchronous gaps', () {
    var trace = Chain([
      Trace.parse('user/code.dart 10:11  Foo.bar\n'
          'dart:core 10:11       Bar.baz'),
      Trace.parse('user/code.dart 10:11  Foo.bar\n'
          'dart:core 10:11       Bar.baz')
    ]).toTrace();

    expect(
        trace.toString(),
        equals('$userSlashCode 10:11  Foo.bar\n'
            'dart:core 10:11       Bar.baz\n'
            '$userSlashCode 10:11  Foo.bar\n'
            'dart:core 10:11       Bar.baz\n'));
  });
}
