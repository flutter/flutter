// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library logging_test;

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  final hierarchicalLoggingEnabledDefault = hierarchicalLoggingEnabled;

  test('level comparison is a valid comparator', () {
    var level1 = const Level('NOT_REAL1', 253);
    expect(level1 == level1, isTrue);
    expect(level1 <= level1, isTrue);
    expect(level1 >= level1, isTrue);
    expect(level1 < level1, isFalse);
    expect(level1 > level1, isFalse);

    var level2 = const Level('NOT_REAL2', 455);
    expect(level1 <= level2, isTrue);
    expect(level1 < level2, isTrue);
    expect(level2 >= level1, isTrue);
    expect(level2 > level1, isTrue);

    var level3 = const Level('NOT_REAL3', 253);
    expect(level1, isNot(same(level3))); // different instances
    expect(level1, equals(level3)); // same value.
  });

  test('default levels are in order', () {
    final levels = Level.LEVELS;

    for (var i = 0; i < levels.length; i++) {
      for (var j = i + 1; j < levels.length; j++) {
        expect(levels[i] < levels[j], isTrue);
      }
    }
  });

  test('levels are comparable', () {
    final unsorted = [
      Level.INFO,
      Level.CONFIG,
      Level.FINE,
      Level.SHOUT,
      Level.OFF,
      Level.FINER,
      Level.ALL,
      Level.WARNING,
      Level.FINEST,
      Level.SEVERE,
    ];

    final sorted = Level.LEVELS;

    expect(unsorted, isNot(orderedEquals(sorted)));

    unsorted.sort();
    expect(unsorted, orderedEquals(sorted));
  });

  test('levels are hashable', () {
    var map = <Level, String>{};
    map[Level.INFO] = 'info';
    map[Level.SHOUT] = 'shout';
    expect(map[Level.INFO], same('info'));
    expect(map[Level.SHOUT], same('shout'));
  });

  test('logger name cannot start with a "." ', () {
    expect(() => Logger('.c'), throwsArgumentError);
  });

  test('root level has proper defaults', () {
    expect(Logger.root, isNotNull);
    expect(Logger.root.parent, null);
    expect(Logger.root.level, defaultLevel);
  });

  test('logger naming is hierarchical', () {
    var c = Logger('a.b.c');
    expect(c.name, equals('c'));
    expect(c.parent!.name, equals('b'));
    expect(c.parent!.parent!.name, equals('a'));
    expect(c.parent!.parent!.parent!.name, equals(''));
    expect(c.parent!.parent!.parent!.parent, isNull);
  });

  test('logger full name', () {
    var c = Logger('a.b.c');
    expect(c.fullName, equals('a.b.c'));
    expect(c.parent!.fullName, equals('a.b'));
    expect(c.parent!.parent!.fullName, equals('a'));
    expect(c.parent!.parent!.parent!.fullName, equals(''));
    expect(c.parent!.parent!.parent!.parent, isNull);
  });

  test('logger parent-child links are correct', () {
    var a = Logger('a');
    var b = Logger('a.b');
    var c = Logger('a.c');
    expect(a, same(b.parent));
    expect(a, same(c.parent));
    expect(a.children['b'], same(b));
    expect(a.children['c'], same(c));
  });

  test('loggers are singletons', () {
    var a1 = Logger('a');
    var a2 = Logger('a');
    var b = Logger('a.b');
    var root = Logger.root;
    expect(a1, same(a2));
    expect(a1, same(b.parent));
    expect(root, same(a1.parent));
    expect(root, same(Logger('')));
  });

  test('cannot directly manipulate Logger.children', () {
    var loggerAB = Logger('a.b');
    var loggerA = loggerAB.parent!;

    expect(loggerA.children['b'], same(loggerAB), reason: 'can read Children');

    expect(() {
      loggerAB.children['test'] = Logger('Fake1234');
    }, throwsUnsupportedError, reason: 'Children is read-only');
  });

  test('stackTrace gets throw to LogRecord', () {
    Logger.root.level = Level.INFO;

    var records = <LogRecord>[];

    var sub = Logger.root.onRecord.listen(records.add);

    try {
      throw UnsupportedError('test exception');
    } catch (error, stack) {
      Logger.root.log(Level.SEVERE, 'severe', error, stack);
      Logger.root.warning('warning', error, stack);
    }

    Logger.root.log(Level.SHOUT, 'shout');

    sub.cancel();

    expect(records, hasLength(3));

    var severe = records[0];
    expect(severe.message, 'severe');
    expect(severe.error is UnsupportedError, isTrue);
    expect(severe.stackTrace is StackTrace, isTrue);

    var warning = records[1];
    expect(warning.message, 'warning');
    expect(warning.error is UnsupportedError, isTrue);
    expect(warning.stackTrace is StackTrace, isTrue);

    var shout = records[2];
    expect(shout.message, 'shout');
    expect(shout.error, isNull);
    expect(shout.stackTrace, isNull);
  });

  group('zone gets recorded to LogRecord', () {
    test('root zone', () {
      var root = Logger.root;

      var recordingZone = Zone.current;
      var records = <LogRecord>[];
      root.onRecord.listen(records.add);
      root.info('hello');

      expect(records, hasLength(1));
      expect(records.first.zone, equals(recordingZone));
    });

    test('child zone', () {
      var root = Logger.root;

      late Zone recordingZone;
      var records = <LogRecord>[];
      root.onRecord.listen(records.add);

      runZoned(() {
        recordingZone = Zone.current;
        root.info('hello');
      });

      expect(records, hasLength(1));
      expect(records.first.zone, equals(recordingZone));
    });

    test('custom zone', () {
      var root = Logger.root;

      late Zone recordingZone;
      var records = <LogRecord>[];
      root.onRecord.listen(records.add);

      runZoned(() {
        recordingZone = Zone.current;
      });

      runZoned(() => root.log(Level.INFO, 'hello', null, null, recordingZone));

      expect(records, hasLength(1));
      expect(records.first.zone, equals(recordingZone));
    });
  });

  group('detached loggers', () {
    tearDown(() {
      hierarchicalLoggingEnabled = hierarchicalLoggingEnabledDefault;
      Logger.root.level = defaultLevel;
    });

    test('create new instances of Logger', () {
      var a1 = Logger.detached('a');
      var a2 = Logger.detached('a');
      var a = Logger('a');

      expect(a1, isNot(a2));
      expect(a1, isNot(a));
      expect(a2, isNot(a));
    });

    test('parent is null', () {
      var a = Logger.detached('a');
      expect(a.parent, null);
    });

    test('children is empty', () {
      var a = Logger.detached('a');
      expect(a.children, {});
    });

    test('have levels independent of the root level', () {
      void testDetachedLoggerLevel(bool withHierarchy) {
        hierarchicalLoggingEnabled = withHierarchy;

        const newRootLevel = Level.ALL;
        const newDetachedLevel = Level.OFF;

        Logger.root.level = newRootLevel;

        final detached = Logger.detached('a');
        expect(detached.level, defaultLevel);
        expect(Logger.root.level, newRootLevel);

        detached.level = newDetachedLevel;
        expect(detached.level, newDetachedLevel);
        expect(Logger.root.level, newRootLevel);
      }

      testDetachedLoggerLevel(false);
      testDetachedLoggerLevel(true);
    });

    test('log messages regardless of hierarchy', () {
      void testDetachedLoggerOnRecord(bool withHierarchy) {
        var calls = 0;
        void handler(_) => calls += 1;

        hierarchicalLoggingEnabled = withHierarchy;

        final detached = Logger.detached('a');
        detached.level = Level.ALL;
        detached.onRecord.listen(handler);

        Logger.root.info('foo');
        expect(calls, 0);

        detached.info('foo');
        detached.info('foo');
        expect(calls, 2);
      }

      testDetachedLoggerOnRecord(false);
      testDetachedLoggerOnRecord(true);
    });
  });

  group('mutating levels', () {
    var root = Logger.root;
    var a = Logger('a');
    var b = Logger('a.b');
    var c = Logger('a.b.c');
    var d = Logger('a.b.c.d');
    var e = Logger('a.b.c.d.e');

    setUp(() {
      hierarchicalLoggingEnabled = true;
      root.level = Level.INFO;
      a.level = null;
      b.level = null;
      c.level = null;
      d.level = null;
      e.level = null;
      root.clearListeners();
      a.clearListeners();
      b.clearListeners();
      c.clearListeners();
      d.clearListeners();
      e.clearListeners();
      hierarchicalLoggingEnabled = false;
      root.level = Level.INFO;
    });

    test('cannot set level if hierarchy is disabled', () {
      expect(() => a.level = Level.FINE, throwsUnsupportedError);
    });

    test('cannot set the level to null on the root logger', () {
      expect(() => root.level = null, throwsUnsupportedError);
    });

    test('cannot set the level to null on a detached logger', () {
      expect(() => Logger.detached('l').level = null, throwsUnsupportedError);
    });

    test('loggers effective level - no hierarchy', () {
      expect(root.level, equals(Level.INFO));
      expect(a.level, equals(Level.INFO));
      expect(b.level, equals(Level.INFO));

      root.level = Level.SHOUT;

      expect(root.level, equals(Level.SHOUT));
      expect(a.level, equals(Level.SHOUT));
      expect(b.level, equals(Level.SHOUT));
    });

    test('loggers effective level - with hierarchy', () {
      hierarchicalLoggingEnabled = true;
      expect(root.level, equals(Level.INFO));
      expect(a.level, equals(Level.INFO));
      expect(b.level, equals(Level.INFO));
      expect(c.level, equals(Level.INFO));

      root.level = Level.SHOUT;
      b.level = Level.FINE;

      expect(root.level, equals(Level.SHOUT));
      expect(a.level, equals(Level.SHOUT));
      expect(b.level, equals(Level.FINE));
      expect(c.level, equals(Level.FINE));
    });

    test('loggers effective level - with changing hierarchy', () {
      hierarchicalLoggingEnabled = true;
      d.level = Level.SHOUT;
      hierarchicalLoggingEnabled = false;

      expect(root.level, Level.INFO);
      expect(d.level, root.level);
      expect(e.level, root.level);
    });

    test('isLoggable is appropriate', () {
      hierarchicalLoggingEnabled = true;
      root.level = Level.SEVERE;
      c.level = Level.ALL;
      e.level = Level.OFF;

      expect(root.isLoggable(Level.SHOUT), isTrue);
      expect(root.isLoggable(Level.SEVERE), isTrue);
      expect(root.isLoggable(Level.WARNING), isFalse);
      expect(c.isLoggable(Level.FINEST), isTrue);
      expect(c.isLoggable(Level.FINE), isTrue);
      expect(e.isLoggable(Level.SHOUT), isFalse);
    });

    test('add/remove handlers - no hierarchy', () {
      var calls = 0;
      void handler(_) {
        calls++;
      }

      final sub = c.onRecord.listen(handler);
      root.info('foo');
      root.info('foo');
      expect(calls, equals(2));
      sub.cancel();
      root.info('foo');
      expect(calls, equals(2));
    });

    test('add/remove handlers - with hierarchy', () {
      hierarchicalLoggingEnabled = true;
      var calls = 0;
      void handler(_) {
        calls++;
      }

      c.onRecord.listen(handler);
      root.info('foo');
      root.info('foo');
      expect(calls, equals(0));
    });

    test('logging methods store appropriate level', () {
      root.level = Level.ALL;
      var rootMessages = [];
      root.onRecord.listen((record) {
        rootMessages.add('${record.level}: ${record.message}');
      });

      root.finest('1');
      root.finer('2');
      root.fine('3');
      root.config('4');
      root.info('5');
      root.warning('6');
      root.severe('7');
      root.shout('8');

      expect(
          rootMessages,
          equals([
            'FINEST: 1',
            'FINER: 2',
            'FINE: 3',
            'CONFIG: 4',
            'INFO: 5',
            'WARNING: 6',
            'SEVERE: 7',
            'SHOUT: 8'
          ]));
    });

    test('logging methods store exception', () {
      root.level = Level.ALL;
      var rootMessages = [];
      root.onRecord.listen((r) {
        rootMessages.add('${r.level}: ${r.message} ${r.error}');
      });

      root.finest('1');
      root.finer('2');
      root.fine('3');
      root.config('4');
      root.info('5');
      root.warning('6');
      root.severe('7');
      root.shout('8');
      root.finest('1', 'a');
      root.finer('2', 'b');
      root.fine('3', ['c']);
      root.config('4', 'd');
      root.info('5', 'e');
      root.warning('6', 'f');
      root.severe('7', 'g');
      root.shout('8', 'h');

      expect(
          rootMessages,
          equals([
            'FINEST: 1 null',
            'FINER: 2 null',
            'FINE: 3 null',
            'CONFIG: 4 null',
            'INFO: 5 null',
            'WARNING: 6 null',
            'SEVERE: 7 null',
            'SHOUT: 8 null',
            'FINEST: 1 a',
            'FINER: 2 b',
            'FINE: 3 [c]',
            'CONFIG: 4 d',
            'INFO: 5 e',
            'WARNING: 6 f',
            'SEVERE: 7 g',
            'SHOUT: 8 h'
          ]));
    });

    test('message logging - no hierarchy', () {
      root.level = Level.WARNING;
      var rootMessages = [];
      var aMessages = [];
      var cMessages = [];
      c.onRecord.listen((record) {
        cMessages.add('${record.level}: ${record.message}');
      });
      a.onRecord.listen((record) {
        aMessages.add('${record.level}: ${record.message}');
      });
      root.onRecord.listen((record) {
        rootMessages.add('${record.level}: ${record.message}');
      });

      root.info('1');
      root.fine('2');
      root.shout('3');

      b.info('4');
      b.severe('5');
      b.warning('6');
      b.fine('7');

      c.fine('8');
      c.warning('9');
      c.shout('10');

      expect(
          rootMessages,
          equals([
            // 'INFO: 1' is not loggable
            // 'FINE: 2' is not loggable
            'SHOUT: 3',
            // 'INFO: 4' is not loggable
            'SEVERE: 5',
            'WARNING: 6',
            // 'FINE: 7' is not loggable
            // 'FINE: 8' is not loggable
            'WARNING: 9',
            'SHOUT: 10'
          ]));

      // no hierarchy means we all hear the same thing.
      expect(aMessages, equals(rootMessages));
      expect(cMessages, equals(rootMessages));
    });

    test('message logging - with hierarchy', () {
      hierarchicalLoggingEnabled = true;

      b.level = Level.WARNING;

      var rootMessages = [];
      var aMessages = [];
      var cMessages = [];
      c.onRecord.listen((record) {
        cMessages.add('${record.level}: ${record.message}');
      });
      a.onRecord.listen((record) {
        aMessages.add('${record.level}: ${record.message}');
      });
      root.onRecord.listen((record) {
        rootMessages.add('${record.level}: ${record.message}');
      });

      root.info('1');
      root.fine('2');
      root.shout('3');

      b.info('4');
      b.severe('5');
      b.warning('6');
      b.fine('7');

      c.fine('8');
      c.warning('9');
      c.shout('10');

      expect(
          rootMessages,
          equals([
            'INFO: 1',
            // 'FINE: 2' is not loggable
            'SHOUT: 3',
            // 'INFO: 4' is not loggable
            'SEVERE: 5',
            'WARNING: 6',
            // 'FINE: 7' is not loggable
            // 'FINE: 8' is not loggable
            'WARNING: 9',
            'SHOUT: 10'
          ]));

      expect(
          aMessages,
          equals([
            // 1,2 and 3 are lower in the hierarchy
            // 'INFO: 4' is not loggable
            'SEVERE: 5',
            'WARNING: 6',
            // 'FINE: 7' is not loggable
            // 'FINE: 8' is not loggable
            'WARNING: 9',
            'SHOUT: 10'
          ]));

      expect(
          cMessages,
          equals([
            // 1 - 7 are lower in the hierarchy
            // 'FINE: 8' is not loggable
            'WARNING: 9',
            'SHOUT: 10'
          ]));
    });

    test('message logging - lazy functions', () {
      root.level = Level.INFO;
      var messages = [];
      root.onRecord.listen((record) {
        messages.add('${record.level}: ${record.message}');
      });

      var callCount = 0;
      String myClosure() => '${++callCount}';

      root.info(myClosure);
      root.finer(myClosure); // Should not get evaluated.
      root.warning(myClosure);

      expect(
          messages,
          equals([
            'INFO: 1',
            'WARNING: 2',
          ]));
    });

    test('message logging - calls toString', () {
      root.level = Level.INFO;
      var messages = [];
      var objects = [];
      var object = Object();
      root.onRecord.listen((record) {
        messages.add('${record.level}: ${record.message}');
        objects.add(record.object);
      });

      root.info(5);
      root.info(false);
      root.info([1, 2, 3]);
      root.info(() => 10);
      root.info(object);

      expect(
          messages,
          equals([
            'INFO: 5',
            'INFO: false',
            'INFO: [1, 2, 3]',
            'INFO: 10',
            "INFO: Instance of 'Object'"
          ]));

      expect(objects, [
        5,
        false,
        [1, 2, 3],
        10,
        object
      ]);
    });
  });

  group('recordStackTraceAtLevel', () {
    var root = Logger.root;
    tearDown(() {
      recordStackTraceAtLevel = Level.OFF;
      root.clearListeners();
    });

    test('no stack trace by default', () {
      var records = <LogRecord>[];
      root.onRecord.listen(records.add);
      root.severe('hello');
      root.warning('hello');
      root.info('hello');
      expect(records, hasLength(3));
      expect(records[0].stackTrace, isNull);
      expect(records[1].stackTrace, isNull);
      expect(records[2].stackTrace, isNull);
    });

    test('trace recorded only on requested levels', () {
      var records = <LogRecord>[];
      recordStackTraceAtLevel = Level.WARNING;
      root.onRecord.listen(records.add);
      root.severe('hello');
      root.warning('hello');
      root.info('hello');
      expect(records, hasLength(3));
      expect(records[0].stackTrace, isNotNull);
      expect(records[1].stackTrace, isNotNull);
      expect(records[2].stackTrace, isNull);
    });

    test('provided trace is used if given', () {
      var trace = StackTrace.current;
      var records = <LogRecord>[];
      recordStackTraceAtLevel = Level.WARNING;
      root.onRecord.listen(records.add);
      root.severe('hello');
      root.warning('hello', 'a', trace);
      expect(records, hasLength(2));
      expect(records[0].stackTrace, isNot(equals(trace)));
      expect(records[1].stackTrace, trace);
    });

    test('error also generated when generating a trace', () {
      var records = <LogRecord>[];
      recordStackTraceAtLevel = Level.WARNING;
      root.onRecord.listen(records.add);
      root.severe('hello');
      root.warning('hello');
      root.info('hello');
      expect(records, hasLength(3));
      expect(records[0].error, isNotNull);
      expect(records[1].error, isNotNull);
      expect(records[2].error, isNull);
    });
  });
}
