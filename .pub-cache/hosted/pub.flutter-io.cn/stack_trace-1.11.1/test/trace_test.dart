// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart';

Trace getCurrentTrace([int level = 0]) => Trace.current(level);

Trace nestedGetCurrentTrace(int level) => getCurrentTrace(level);

void main() {
  // This just shouldn't crash.
  test('a native stack trace is parseable', Trace.current);

  group('.parse', () {
    test('.parse parses a V8 stack trace with eval statment correctly', () {
      var trace = Trace.parse(r'''Error
    at Object.eval (eval at Foo (main.dart.js:588), <anonymous>:3:47)''');
      expect(trace.frames[0].uri, Uri.parse('main.dart.js'));
      expect(trace.frames[0].member, equals('Object.eval'));
      expect(trace.frames[0].line, equals(588));
      expect(trace.frames[0].column, isNull);
    });

    test('.parse parses a VM stack trace correctly', () {
      var trace = Trace.parse(
        '#0      Foo._bar (file:///home/nweiz/code/stuff.dart:42:21)\n'
        '#1      zip.<anonymous closure>.zap (dart:async/future.dart:0:2)\n'
        '#2      zip.<anonymous closure>.zap (https://pub.dev/thing.dart:1:100)',
      );

      expect(trace.frames[0].uri,
          equals(Uri.parse('file:///home/nweiz/code/stuff.dart')));
      expect(trace.frames[1].uri, equals(Uri.parse('dart:async/future.dart')));
      expect(
          trace.frames[2].uri, equals(Uri.parse('https://pub.dev/thing.dart')));
    });

    test('parses a V8 stack trace correctly', () {
      var trace = Trace.parse('Error\n'
          '    at Foo._bar (https://example.com/stuff.js:42:21)\n'
          '    at https://example.com/stuff.js:0:2\n'
          '    at zip.<anonymous>.zap '
          '(https://pub.dev/thing.js:1:100)');

      expect(trace.frames[0].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(trace.frames[1].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(
          trace.frames[2].uri, equals(Uri.parse('https://pub.dev/thing.js')));

      trace = Trace.parse('Exception: foo\n'
          '    at Foo._bar (https://example.com/stuff.js:42:21)\n'
          '    at https://example.com/stuff.js:0:2\n'
          '    at zip.<anonymous>.zap '
          '(https://pub.dev/thing.js:1:100)');

      expect(trace.frames[0].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(trace.frames[1].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(
          trace.frames[2].uri, equals(Uri.parse('https://pub.dev/thing.js')));

      trace = Trace.parse('Exception: foo\n'
          '    bar\n'
          '    at Foo._bar (https://example.com/stuff.js:42:21)\n'
          '    at https://example.com/stuff.js:0:2\n'
          '    at zip.<anonymous>.zap '
          '(https://pub.dev/thing.js:1:100)');

      expect(trace.frames[0].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(trace.frames[1].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(
          trace.frames[2].uri, equals(Uri.parse('https://pub.dev/thing.js')));

      trace = Trace.parse('Exception: foo\n'
          '    bar\n'
          '    at Foo._bar (https://example.com/stuff.js:42:21)\n'
          '    at https://example.com/stuff.js:0:2\n'
          '    at (anonymous function).zip.zap '
          '(https://pub.dev/thing.js:1:100)');

      expect(trace.frames[0].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(trace.frames[1].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(trace.frames[1].member, equals('<fn>'));
      expect(
          trace.frames[2].uri, equals(Uri.parse('https://pub.dev/thing.js')));
      expect(trace.frames[2].member, equals('<fn>.zip.zap'));
    });

    // JavaScriptCore traces are just like V8, except that it doesn't have a
    // header and it starts with a tab rather than spaces.
    test('parses a JavaScriptCore stack trace correctly', () {
      var trace =
          Trace.parse('\tat Foo._bar (https://example.com/stuff.js:42:21)\n'
              '\tat https://example.com/stuff.js:0:2\n'
              '\tat zip.<anonymous>.zap '
              '(https://pub.dev/thing.js:1:100)');

      expect(trace.frames[0].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(trace.frames[1].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(
          trace.frames[2].uri, equals(Uri.parse('https://pub.dev/thing.js')));

      trace = Trace.parse('\tat Foo._bar (https://example.com/stuff.js:42:21)\n'
          '\tat \n'
          '\tat zip.<anonymous>.zap '
          '(https://pub.dev/thing.js:1:100)');

      expect(trace.frames[0].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(
          trace.frames[1].uri, equals(Uri.parse('https://pub.dev/thing.js')));
    });

    test('parses a Firefox/Safari stack trace correctly', () {
      var trace = Trace.parse('Foo._bar@https://example.com/stuff.js:42\n'
          'zip/<@https://example.com/stuff.js:0\n'
          'zip.zap(12, "@)()/<")@https://pub.dev/thing.js:1');

      expect(trace.frames[0].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(trace.frames[1].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(
          trace.frames[2].uri, equals(Uri.parse('https://pub.dev/thing.js')));

      trace = Trace.parse('zip/<@https://example.com/stuff.js:0\n'
          'Foo._bar@https://example.com/stuff.js:42\n'
          'zip.zap(12, "@)()/<")@https://pub.dev/thing.js:1');

      expect(trace.frames[0].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(trace.frames[1].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(
          trace.frames[2].uri, equals(Uri.parse('https://pub.dev/thing.js')));

      trace = Trace.parse('zip.zap(12, "@)()/<")@https://pub.dev/thing.js:1\n'
          'zip/<@https://example.com/stuff.js:0\n'
          'Foo._bar@https://example.com/stuff.js:42');

      expect(
          trace.frames[0].uri, equals(Uri.parse('https://pub.dev/thing.js')));
      expect(trace.frames[1].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(trace.frames[2].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
    });

    test('parses a Firefox/Safari stack trace containing native code correctly',
        () {
      var trace = Trace.parse('Foo._bar@https://example.com/stuff.js:42\n'
          'zip/<@https://example.com/stuff.js:0\n'
          'zip.zap(12, "@)()/<")@https://pub.dev/thing.js:1\n'
          '[native code]');

      expect(trace.frames[0].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(trace.frames[1].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(
          trace.frames[2].uri, equals(Uri.parse('https://pub.dev/thing.js')));
      expect(trace.frames.length, equals(3));
    });

    test('parses a Firefox/Safari stack trace without a method name correctly',
        () {
      var trace = Trace.parse('https://example.com/stuff.js:42\n'
          'zip/<@https://example.com/stuff.js:0\n'
          'zip.zap(12, "@)()/<")@https://pub.dev/thing.js:1');

      expect(trace.frames[0].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(trace.frames[0].member, equals('<fn>'));
      expect(trace.frames[1].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(
          trace.frames[2].uri, equals(Uri.parse('https://pub.dev/thing.js')));
    });

    test('parses a Firefox/Safari stack trace with an empty line correctly',
        () {
      var trace = Trace.parse('Foo._bar@https://example.com/stuff.js:42\n'
          '\n'
          'zip/<@https://example.com/stuff.js:0\n'
          'zip.zap(12, "@)()/<")@https://pub.dev/thing.js:1');

      expect(trace.frames[0].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(trace.frames[1].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(
          trace.frames[2].uri, equals(Uri.parse('https://pub.dev/thing.js')));
    });

    test('parses a Firefox/Safari stack trace with a column number correctly',
        () {
      var trace = Trace.parse('Foo._bar@https://example.com/stuff.js:42:2\n'
          'zip/<@https://example.com/stuff.js:0\n'
          'zip.zap(12, "@)()/<")@https://pub.dev/thing.js:1');

      expect(trace.frames[0].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(trace.frames[0].line, equals(42));
      expect(trace.frames[0].column, equals(2));
      expect(trace.frames[1].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(
          trace.frames[2].uri, equals(Uri.parse('https://pub.dev/thing.js')));
    });

    test('parses a package:stack_trace stack trace correctly', () {
      var trace =
          Trace.parse('https://dart.dev/foo/bar.dart 10:11  Foo.<fn>.bar\n'
              'https://dart.dev/foo/baz.dart        Foo.<fn>.bar');

      expect(trace.frames[0].uri,
          equals(Uri.parse('https://dart.dev/foo/bar.dart')));
      expect(trace.frames[1].uri,
          equals(Uri.parse('https://dart.dev/foo/baz.dart')));
    });

    test('parses a package:stack_trace stack chain correctly', () {
      var trace =
          Trace.parse('https://dart.dev/foo/bar.dart 10:11  Foo.<fn>.bar\n'
              'https://dart.dev/foo/baz.dart        Foo.<fn>.bar\n'
              '===== asynchronous gap ===========================\n'
              'https://dart.dev/foo/bang.dart 10:11  Foo.<fn>.bar\n'
              'https://dart.dev/foo/quux.dart        Foo.<fn>.bar');

      expect(trace.frames[0].uri,
          equals(Uri.parse('https://dart.dev/foo/bar.dart')));
      expect(trace.frames[1].uri,
          equals(Uri.parse('https://dart.dev/foo/baz.dart')));
      expect(trace.frames[2].uri,
          equals(Uri.parse('https://dart.dev/foo/bang.dart')));
      expect(trace.frames[3].uri,
          equals(Uri.parse('https://dart.dev/foo/quux.dart')));
    });

    test('parses a package:stack_trace stack chain with end gap correctly', () {
      var trace = Trace.parse(
        'https://dart.dev/foo/bar.dart 10:11  Foo.<fn>.bar\n'
        'https://dart.dev/foo/baz.dart        Foo.<fn>.bar\n'
        'https://dart.dev/foo/bang.dart 10:11  Foo.<fn>.bar\n'
        'https://dart.dev/foo/quux.dart        Foo.<fn>.bar===== asynchronous gap ===========================\n',
      );

      expect(trace.frames.length, 4);
      expect(trace.frames[0].uri,
          equals(Uri.parse('https://dart.dev/foo/bar.dart')));
      expect(trace.frames[1].uri,
          equals(Uri.parse('https://dart.dev/foo/baz.dart')));
      expect(trace.frames[2].uri,
          equals(Uri.parse('https://dart.dev/foo/bang.dart')));
      expect(trace.frames[3].uri,
          equals(Uri.parse('https://dart.dev/foo/quux.dart')));
    });

    test('parses a real package:stack_trace stack trace correctly', () {
      var traceString = Trace.current().toString();
      expect(Trace.parse(traceString).toString(), equals(traceString));
    });

    test('parses an empty string correctly', () {
      var trace = Trace.parse('');
      expect(trace.frames, isEmpty);
      expect(trace.toString(), equals(''));
    });

    test('parses trace with async gap correctly', () {
      var trace = Trace.parse('#0      bop (file:///pull.dart:42:23)\n'
          '<asynchronous suspension>\n'
          '#1      twist (dart:the/future.dart:0:2)\n'
          '#2      main (dart:my/file.dart:4:6)\n');

      expect(trace.frames.length, 3);
      expect(trace.frames[0].uri, equals(Uri.parse('file:///pull.dart')));
      expect(trace.frames[1].uri, equals(Uri.parse('dart:the/future.dart')));
      expect(trace.frames[2].uri, equals(Uri.parse('dart:my/file.dart')));
    });

    test('parses trace with async gap at end correctly', () {
      var trace = Trace.parse('#0      bop (file:///pull.dart:42:23)\n'
          '#1      twist (dart:the/future.dart:0:2)\n'
          '<asynchronous suspension>\n');

      expect(trace.frames.length, 2);
      expect(trace.frames[0].uri, equals(Uri.parse('file:///pull.dart')));
      expect(trace.frames[1].uri, equals(Uri.parse('dart:the/future.dart')));
    });
  });

  test('.toString() nicely formats the stack trace', () {
    var trace = Trace.parse('''
#0      Foo._bar (foo/bar.dart:42:21)
#1      zip.<anonymous closure>.zap (dart:async/future.dart:0:2)
#2      zip.<anonymous closure>.zap (https://pub.dev/thing.dart:1:100)
''');

    expect(trace.toString(), equals('''
${path.join('foo', 'bar.dart')} 42:21                Foo._bar
dart:async/future.dart 0:2        zip.<fn>.zap
https://pub.dev/thing.dart 1:100  zip.<fn>.zap
'''));
  });

  test('.vmTrace returns a native-style trace', () {
    var uri = path.toUri(path.absolute('foo'));
    var trace = Trace([
      Frame(uri, 10, 20, 'Foo.<fn>'),
      Frame(Uri.parse('https://dart.dev/foo.dart'), null, null, 'bar'),
      Frame(Uri.parse('dart:async'), 15, null, 'baz'),
    ]);

    expect(
        trace.vmTrace.toString(),
        equals('#1      Foo.<anonymous closure> ($uri:10:20)\n'
            '#2      bar (https://dart.dev/foo.dart:0:0)\n'
            '#3      baz (dart:async:15:0)\n'));
  });

  group('folding', () {
    group('.terse', () {
      test('folds core frames together bottom-up', () {
        var trace = Trace.parse('''
#1 top (dart:async/future.dart:0:2)
#2 bottom (dart:core/uri.dart:1:100)
#0 notCore (foo.dart:42:21)
#3 top (dart:io:5:10)
#4 bottom (dart:async-patch/future.dart:9:11)
#5 alsoNotCore (bar.dart:10:20)
''');

        expect(trace.terse.toString(), equals('''
dart:core       bottom
foo.dart 42:21  notCore
dart:async      bottom
bar.dart 10:20  alsoNotCore
'''));
      });

      test('folds empty async frames', () {
        var trace = Trace.parse('''
#0 top (dart:async/future.dart:0:2)
#1 empty.<<anonymous closure>_async_body> (bar.dart)
#2 bottom (dart:async-patch/future.dart:9:11)
#3 notCore (foo.dart:42:21)
''');

        expect(trace.terse.toString(), equals('''
dart:async      bottom
foo.dart 42:21  notCore
'''));
      });

      test('removes the bottom-most async frame', () {
        var trace = Trace.parse('''
#0 notCore (foo.dart:42:21)
#1 top (dart:async/future.dart:0:2)
#2 bottom (dart:core/uri.dart:1:100)
#3 top (dart:io:5:10)
#4 bottom (dart:async-patch/future.dart:9:11)
''');

        expect(trace.terse.toString(), equals('''
foo.dart 42:21  notCore
'''));
      });

      test("won't make a trace empty", () {
        var trace = Trace.parse('''
#1 top (dart:async/future.dart:0:2)
#2 bottom (dart:core/uri.dart:1:100)
''');

        expect(trace.terse.toString(), equals('''
dart:core  bottom
'''));
      });

      test("won't panic on an empty trace", () {
        expect(Trace.parse('').terse.toString(), equals(''));
      });
    });

    group('.foldFrames', () {
      test('folds frames together bottom-up', () {
        var trace = Trace.parse('''
#0 notFoo (foo.dart:42:21)
#1 fooTop (bar.dart:0:2)
#2 fooBottom (foo.dart:1:100)
#3 alsoNotFoo (bar.dart:10:20)
#4 fooTop (dart:io/socket.dart:5:10)
#5 fooBottom (dart:async-patch/future.dart:9:11)
''');

        var folded =
            trace.foldFrames((frame) => frame.member!.startsWith('foo'));
        expect(folded.toString(), equals('''
foo.dart 42:21                     notFoo
foo.dart 1:100                     fooBottom
bar.dart 10:20                     alsoNotFoo
dart:async-patch/future.dart 9:11  fooBottom
'''));
      });

      test('will never fold unparsed frames', () {
        var trace = Trace.parse(r'''
.g"cs$#:b";a#>sw{*{ul$"$xqwr`p
%+j-?uppx<([j@#nu{{>*+$%x-={`{
!e($b{nj)zs?cgr%!;bmw.+$j+pfj~
''');

        expect(trace.foldFrames((frame) => true).toString(), equals(r'''
.g"cs$#:b";a#>sw{*{ul$"$xqwr`p
%+j-?uppx<([j@#nu{{>*+$%x-={`{
!e($b{nj)zs?cgr%!;bmw.+$j+pfj~
'''));
      });

      group('with terse: true', () {
        test('folds core frames as well', () {
          var trace = Trace.parse('''
#0 notFoo (foo.dart:42:21)
#1 fooTop (bar.dart:0:2)
#2 coreBottom (dart:async/future.dart:0:2)
#3 alsoNotFoo (bar.dart:10:20)
#4 fooTop (foo.dart:9:11)
#5 coreBottom (dart:async-patch/future.dart:9:11)
''');

          var folded = trace.foldFrames(
              (frame) => frame.member!.startsWith('foo'),
              terse: true);
          expect(folded.toString(), equals('''
foo.dart 42:21  notFoo
dart:async      coreBottom
bar.dart 10:20  alsoNotFoo
'''));
        });

        test('shortens folded frames', () {
          var trace = Trace.parse('''
#0 notFoo (foo.dart:42:21)
#1 fooTop (bar.dart:0:2)
#2 fooBottom (package:foo/bar.dart:0:2)
#3 alsoNotFoo (bar.dart:10:20)
#4 fooTop (foo.dart:9:11)
#5 fooBottom (foo/bar.dart:9:11)
#6 againNotFoo (bar.dart:20:20)
''');

          var folded = trace.foldFrames(
              (frame) => frame.member!.startsWith('foo'),
              terse: true);
          expect(folded.toString(), equals('''
foo.dart 42:21  notFoo
package:foo     fooBottom
bar.dart 10:20  alsoNotFoo
foo             fooBottom
bar.dart 20:20  againNotFoo
'''));
        });

        test('removes the bottom-most folded frame', () {
          var trace = Trace.parse('''
#2 fooTop (package:foo/bar.dart:0:2)
#3 notFoo (bar.dart:10:20)
#5 fooBottom (foo/bar.dart:9:11)
''');

          var folded = trace.foldFrames(
              (frame) => frame.member!.startsWith('foo'),
              terse: true);
          expect(folded.toString(), equals('''
package:foo     fooTop
bar.dart 10:20  notFoo
'''));
        });
      });
    });
  });
}
