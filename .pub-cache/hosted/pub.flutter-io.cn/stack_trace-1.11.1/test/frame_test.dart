// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart';

void main() {
  group('.parseVM', () {
    test('parses a stack frame with column correctly', () {
      var frame = Frame.parseVM('#1      Foo._bar '
          '(file:///home/nweiz/code/stuff.dart:42:21)');
      expect(
          frame.uri, equals(Uri.parse('file:///home/nweiz/code/stuff.dart')));
      expect(frame.line, equals(42));
      expect(frame.column, equals(21));
      expect(frame.member, equals('Foo._bar'));
    });

    test('parses a stack frame without column correctly', () {
      var frame = Frame.parseVM('#1      Foo._bar '
          '(file:///home/nweiz/code/stuff.dart:24)');
      expect(
          frame.uri, equals(Uri.parse('file:///home/nweiz/code/stuff.dart')));
      expect(frame.line, equals(24));
      expect(frame.column, null);
      expect(frame.member, equals('Foo._bar'));
    });

    // This can happen with async stack traces. See issue 22009.
    test('parses a stack frame without line or column correctly', () {
      var frame = Frame.parseVM('#1      Foo._bar '
          '(file:///home/nweiz/code/stuff.dart)');
      expect(
          frame.uri, equals(Uri.parse('file:///home/nweiz/code/stuff.dart')));
      expect(frame.line, isNull);
      expect(frame.column, isNull);
      expect(frame.member, equals('Foo._bar'));
    });

    test('converts "<anonymous closure>" to "<fn>"', () {
      String? parsedMember(String member) =>
          Frame.parseVM('#0 $member (foo:0:0)').member;

      expect(parsedMember('Foo.<anonymous closure>'), equals('Foo.<fn>'));
      expect(parsedMember('<anonymous closure>.<anonymous closure>.bar'),
          equals('<fn>.<fn>.bar'));
    });

    test('converts "<<anonymous closure>_async_body>" to "<async>"', () {
      var frame =
          Frame.parseVM('#0 Foo.<<anonymous closure>_async_body> (foo:0:0)');
      expect(frame.member, equals('Foo.<async>'));
    });

    test('converts "<function_name_async_body>" to "<async>"', () {
      var frame = Frame.parseVM('#0 Foo.<function_name_async_body> (foo:0:0)');
      expect(frame.member, equals('Foo.<async>'));
    });

    test('parses a folded frame correctly', () {
      var frame = Frame.parseVM('...');

      expect(frame.member, equals('...'));
      expect(frame.uri, equals(Uri()));
      expect(frame.line, isNull);
      expect(frame.column, isNull);
    });
  });

  group('.parseV8', () {
    test('returns an UnparsedFrame for malformed frames', () {
      expectIsUnparsed(Frame.parseV8, '');
      expectIsUnparsed(Frame.parseV8, '#1');
      expectIsUnparsed(Frame.parseV8, '#1      Foo');
      expectIsUnparsed(Frame.parseV8, '#1      (dart:async/future.dart:10:15)');
      expectIsUnparsed(Frame.parseV8, 'Foo (dart:async/future.dart:10:15)');
    });

    test('parses a stack frame correctly', () {
      var frame = Frame.parseV8('    at VW.call\$0 '
          '(https://example.com/stuff.dart.js:560:28)');
      expect(frame.uri, equals(Uri.parse('https://example.com/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with a : in the authority', () {
      var frame = Frame.parseV8('    at VW.call\$0 '
          '(http://localhost:8080/stuff.dart.js:560:28)');
      expect(
          frame.uri, equals(Uri.parse('http://localhost:8080/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with an absolute POSIX path correctly', () {
      var frame = Frame.parseV8('    at VW.call\$0 '
          '(/path/to/stuff.dart.js:560:28)');
      expect(frame.uri, equals(Uri.parse('file:///path/to/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with an absolute Windows path correctly', () {
      var frame = Frame.parseV8('    at VW.call\$0 '
          r'(C:\path\to\stuff.dart.js:560:28)');
      expect(frame.uri, equals(Uri.parse('file:///C:/path/to/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with a Windows UNC path correctly', () {
      var frame = Frame.parseV8('    at VW.call\$0 '
          r'(\\mount\path\to\stuff.dart.js:560:28)');
      expect(
          frame.uri, equals(Uri.parse('file://mount/path/to/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with a relative POSIX path correctly', () {
      var frame = Frame.parseV8('    at VW.call\$0 '
          '(path/to/stuff.dart.js:560:28)');
      expect(frame.uri, equals(Uri.parse('path/to/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with a relative Windows path correctly', () {
      var frame = Frame.parseV8('    at VW.call\$0 '
          r'(path\to\stuff.dart.js:560:28)');
      expect(frame.uri, equals(Uri.parse('path/to/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses an anonymous stack frame correctly', () {
      var frame =
          Frame.parseV8('    at https://example.com/stuff.dart.js:560:28');
      expect(frame.uri, equals(Uri.parse('https://example.com/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('<fn>'));
    });

    test('parses a native stack frame correctly', () {
      var frame = Frame.parseV8('    at Object.stringify (native)');
      expect(frame.uri, Uri.parse('native'));
      expect(frame.line, isNull);
      expect(frame.column, isNull);
      expect(frame.member, equals('Object.stringify'));
    });

    test('parses a stack frame with [as ...] correctly', () {
      // Ignore "[as ...]", since other stack trace formats don't support a
      // similar construct.
      var frame = Frame.parseV8('    at VW.call\$0 [as call\$4] '
          '(https://example.com/stuff.dart.js:560:28)');
      expect(frame.uri, equals(Uri.parse('https://example.com/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a basic eval stack frame correctly', () {
      var frame = Frame.parseV8('    at eval (eval at <anonymous> '
          '(https://example.com/stuff.dart.js:560:28))');
      expect(frame.uri, equals(Uri.parse('https://example.com/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('eval'));
    });

    test('parses an IE10 eval stack frame correctly', () {
      var frame = Frame.parseV8('    at eval (eval at Anonymous function '
          '(https://example.com/stuff.dart.js:560:28))');
      expect(frame.uri, equals(Uri.parse('https://example.com/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('eval'));
    });

    test('parses an eval stack frame with inner position info correctly', () {
      var frame = Frame.parseV8('    at eval (eval at <anonymous> '
          '(https://example.com/stuff.dart.js:560:28), <anonymous>:3:28)');
      expect(frame.uri, equals(Uri.parse('https://example.com/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('eval'));
    });

    test('parses a nested eval stack frame correctly', () {
      var frame = Frame.parseV8('    at eval (eval at <anonymous> '
          '(eval at sub (https://example.com/stuff.dart.js:560:28)))');
      expect(frame.uri, equals(Uri.parse('https://example.com/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, equals(28));
      expect(frame.member, equals('eval'));
    });

    test('converts "<anonymous>" to "<fn>"', () {
      String? parsedMember(String member) =>
          Frame.parseV8('    at $member (foo:0:0)').member;

      expect(parsedMember('Foo.<anonymous>'), equals('Foo.<fn>'));
      expect(
          parsedMember('<anonymous>.<anonymous>.bar'), equals('<fn>.<fn>.bar'));
    });

    test('returns an UnparsedFrame for malformed frames', () {
      expectIsUnparsed(Frame.parseV8, '');
      expectIsUnparsed(Frame.parseV8, '    at');
      expectIsUnparsed(Frame.parseV8, '    at Foo');
      expectIsUnparsed(Frame.parseV8, '    at Foo (dart:async/future.dart)');
      expectIsUnparsed(Frame.parseV8, '    at (dart:async/future.dart:10:15)');
      expectIsUnparsed(Frame.parseV8, 'Foo (dart:async/future.dart:10:15)');
      expectIsUnparsed(Frame.parseV8, '    at dart:async/future.dart');
      expectIsUnparsed(Frame.parseV8, 'dart:async/future.dart:10:15');
    });
  });

  group('.parseFirefox/.parseSafari', () {
    test('parses a Firefox stack trace with anonymous function', () {
      var trace = Trace.parse('''
Foo._bar@https://example.com/stuff.js:18056:12
anonymous/<@https://example.com/stuff.js line 693 > Function:3:40
baz@https://pub.dev/buz.js:56355:55
        ''');
      expect(trace.frames[0].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(trace.frames[0].line, equals(18056));
      expect(trace.frames[0].column, equals(12));
      expect(trace.frames[0].member, equals('Foo._bar'));
      expect(trace.frames[1].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(trace.frames[1].line, equals(693));
      expect(trace.frames[1].column, isNull);
      expect(trace.frames[1].member, equals('<fn>'));
      expect(trace.frames[2].uri, equals(Uri.parse('https://pub.dev/buz.js')));
      expect(trace.frames[2].line, equals(56355));
      expect(trace.frames[2].column, equals(55));
      expect(trace.frames[2].member, equals('baz'));
    });

    test('parses a Firefox stack trace with nested evals in anonymous function',
        () {
      var trace = Trace.parse('''
        Foo._bar@https://example.com/stuff.js:18056:12
        anonymous@file:///C:/example.html line 7 > eval line 1 > eval:1:1
        anonymous@file:///C:/example.html line 45 > Function:1:1
        ''');
      expect(trace.frames[0].uri,
          equals(Uri.parse('https://example.com/stuff.js')));
      expect(trace.frames[0].line, equals(18056));
      expect(trace.frames[0].column, equals(12));
      expect(trace.frames[0].member, equals('Foo._bar'));
      expect(trace.frames[1].uri, equals(Uri.parse('file:///C:/example.html')));
      expect(trace.frames[1].line, equals(7));
      expect(trace.frames[1].column, isNull);
      expect(trace.frames[1].member, equals('<fn>'));
      expect(trace.frames[2].uri, equals(Uri.parse('file:///C:/example.html')));
      expect(trace.frames[2].line, equals(45));
      expect(trace.frames[2].column, isNull);
      expect(trace.frames[2].member, equals('<fn>'));
    });

    test('parses a simple stack frame correctly', () {
      var frame = Frame.parseFirefox(
          '.VW.call\$0@https://example.com/stuff.dart.js:560');
      expect(frame.uri, equals(Uri.parse('https://example.com/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with an absolute POSIX path correctly', () {
      var frame = Frame.parseFirefox('.VW.call\$0@/path/to/stuff.dart.js:560');
      expect(frame.uri, equals(Uri.parse('file:///path/to/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with an absolute Windows path correctly', () {
      var frame =
          Frame.parseFirefox(r'.VW.call$0@C:\path\to\stuff.dart.js:560');
      expect(frame.uri, equals(Uri.parse('file:///C:/path/to/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with a Windows UNC path correctly', () {
      var frame =
          Frame.parseFirefox(r'.VW.call$0@\\mount\path\to\stuff.dart.js:560');
      expect(
          frame.uri, equals(Uri.parse('file://mount/path/to/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with a relative POSIX path correctly', () {
      var frame = Frame.parseFirefox('.VW.call\$0@path/to/stuff.dart.js:560');
      expect(frame.uri, equals(Uri.parse('path/to/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a stack frame with a relative Windows path correctly', () {
      var frame = Frame.parseFirefox(r'.VW.call$0@path\to\stuff.dart.js:560');
      expect(frame.uri, equals(Uri.parse('path/to/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('VW.call\$0'));
    });

    test('parses a simple anonymous stack frame correctly', () {
      var frame = Frame.parseFirefox('@https://example.com/stuff.dart.js:560');
      expect(frame.uri, equals(Uri.parse('https://example.com/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('<fn>'));
    });

    test('parses a nested anonymous stack frame correctly', () {
      var frame =
          Frame.parseFirefox('.foo/<@https://example.com/stuff.dart.js:560');
      expect(frame.uri, equals(Uri.parse('https://example.com/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('foo.<fn>'));

      frame = Frame.parseFirefox('.foo/@https://example.com/stuff.dart.js:560');
      expect(frame.uri, equals(Uri.parse('https://example.com/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('foo.<fn>'));
    });

    test('parses a named nested anonymous stack frame correctly', () {
      var frame = Frame.parseFirefox(
          '.foo/.name<@https://example.com/stuff.dart.js:560');
      expect(frame.uri, equals(Uri.parse('https://example.com/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('foo.<fn>'));

      frame = Frame.parseFirefox(
          '.foo/.name@https://example.com/stuff.dart.js:560');
      expect(frame.uri, equals(Uri.parse('https://example.com/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('foo.<fn>'));
    });

    test('parses a stack frame with parameters correctly', () {
      var frame = Frame.parseFirefox(
          '.foo(12, "@)()/<")@https://example.com/stuff.dart.js:560');
      expect(frame.uri, equals(Uri.parse('https://example.com/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('foo'));
    });

    test('parses a nested anonymous stack frame with parameters correctly', () {
      var frame = Frame.parseFirefox(
        '.foo(12, "@)()/<")/.fn<@https://example.com/stuff.dart.js:560',
      );
      expect(frame.uri, equals(Uri.parse('https://example.com/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('foo.<fn>'));
    });

    test(
        'parses a deeply-nested anonymous stack frame with parameters '
        'correctly', () {
      var frame = Frame.parseFirefox('.convertDartClosureToJS/\$function</<@'
          'https://example.com/stuff.dart.js:560');
      expect(frame.uri, equals(Uri.parse('https://example.com/stuff.dart.js')));
      expect(frame.line, equals(560));
      expect(frame.column, isNull);
      expect(frame.member, equals('convertDartClosureToJS.<fn>.<fn>'));
    });

    test('returns an UnparsedFrame for malformed frames', () {
      expectIsUnparsed(Frame.parseFirefox, '');
      expectIsUnparsed(Frame.parseFirefox, '.foo');
      expectIsUnparsed(Frame.parseFirefox, '.foo@dart:async/future.dart');
      expectIsUnparsed(Frame.parseFirefox, '.foo(@dart:async/future.dart:10');
      expectIsUnparsed(Frame.parseFirefox, '@dart:async/future.dart');
    });

    test('parses a simple stack frame correctly', () {
      var frame =
          Frame.parseFirefox('foo\$bar@https://dart.dev/foo/bar.dart:10:11');
      expect(frame.uri, equals(Uri.parse('https://dart.dev/foo/bar.dart')));
      expect(frame.line, equals(10));
      expect(frame.column, equals(11));
      expect(frame.member, equals('foo\$bar'));
    });

    test('parses an anonymous stack frame correctly', () {
      var frame = Frame.parseFirefox('https://dart.dev/foo/bar.dart:10:11');
      expect(frame.uri, equals(Uri.parse('https://dart.dev/foo/bar.dart')));
      expect(frame.line, equals(10));
      expect(frame.column, equals(11));
      expect(frame.member, equals('<fn>'));
    });

    test('parses a stack frame with no line correctly', () {
      var frame =
          Frame.parseFirefox('foo\$bar@https://dart.dev/foo/bar.dart::11');
      expect(frame.uri, equals(Uri.parse('https://dart.dev/foo/bar.dart')));
      expect(frame.line, isNull);
      expect(frame.column, equals(11));
      expect(frame.member, equals('foo\$bar'));
    });

    test('parses a stack frame with no column correctly', () {
      var frame =
          Frame.parseFirefox('foo\$bar@https://dart.dev/foo/bar.dart:10:');
      expect(frame.uri, equals(Uri.parse('https://dart.dev/foo/bar.dart')));
      expect(frame.line, equals(10));
      expect(frame.column, isNull);
      expect(frame.member, equals('foo\$bar'));
    });

    test('parses a stack frame with no line or column correctly', () {
      var frame =
          Frame.parseFirefox('foo\$bar@https://dart.dev/foo/bar.dart:10:11');
      expect(frame.uri, equals(Uri.parse('https://dart.dev/foo/bar.dart')));
      expect(frame.line, equals(10));
      expect(frame.column, equals(11));
      expect(frame.member, equals('foo\$bar'));
    });
  });

  group('.parseFriendly', () {
    test('parses a simple stack frame correctly', () {
      var frame = Frame.parseFriendly(
          'https://dart.dev/foo/bar.dart 10:11  Foo.<fn>.bar');
      expect(frame.uri, equals(Uri.parse('https://dart.dev/foo/bar.dart')));
      expect(frame.line, equals(10));
      expect(frame.column, equals(11));
      expect(frame.member, equals('Foo.<fn>.bar'));
    });

    test('parses a stack frame with no line or column correctly', () {
      var frame =
          Frame.parseFriendly('https://dart.dev/foo/bar.dart  Foo.<fn>.bar');
      expect(frame.uri, equals(Uri.parse('https://dart.dev/foo/bar.dart')));
      expect(frame.line, isNull);
      expect(frame.column, isNull);
      expect(frame.member, equals('Foo.<fn>.bar'));
    });

    test('parses a stack frame with no column correctly', () {
      var frame =
          Frame.parseFriendly('https://dart.dev/foo/bar.dart 10  Foo.<fn>.bar');
      expect(frame.uri, equals(Uri.parse('https://dart.dev/foo/bar.dart')));
      expect(frame.line, equals(10));
      expect(frame.column, isNull);
      expect(frame.member, equals('Foo.<fn>.bar'));
    });

    test('parses a stack frame with a relative path correctly', () {
      var frame = Frame.parseFriendly('foo/bar.dart 10:11    Foo.<fn>.bar');
      expect(frame.uri,
          equals(path.toUri(path.absolute(path.join('foo', 'bar.dart')))));
      expect(frame.line, equals(10));
      expect(frame.column, equals(11));
      expect(frame.member, equals('Foo.<fn>.bar'));
    });

    test('returns an UnparsedFrame for malformed frames', () {
      expectIsUnparsed(Frame.parseFriendly, '');
      expectIsUnparsed(Frame.parseFriendly, 'foo/bar.dart');
      expectIsUnparsed(Frame.parseFriendly, 'foo/bar.dart 10:11');
    });

    test('parses a data url stack frame with no line or column correctly', () {
      var frame = Frame.parseFriendly('data:...  main');
      expect(frame.uri.scheme, equals('data'));
      expect(frame.line, isNull);
      expect(frame.column, isNull);
      expect(frame.member, equals('main'));
    });

    test('parses a data url stack frame correctly', () {
      var frame = Frame.parseFriendly('data:... 10:11    main');
      expect(frame.uri.scheme, equals('data'));
      expect(frame.line, equals(10));
      expect(frame.column, equals(11));
      expect(frame.member, equals('main'));
    });

    test('parses a stack frame with spaces in the member name correctly', () {
      var frame = Frame.parseFriendly(
          'foo/bar.dart 10:11    (anonymous function).dart.fn');
      expect(frame.uri,
          equals(path.toUri(path.absolute(path.join('foo', 'bar.dart')))));
      expect(frame.line, equals(10));
      expect(frame.column, equals(11));
      expect(frame.member, equals('(anonymous function).dart.fn'));
    });

    test(
        'parses a stack frame with spaces in the member name and no line or '
        'column correctly', () {
      var frame = Frame.parseFriendly(
          'https://dart.dev/foo/bar.dart  (anonymous function).dart.fn');
      expect(frame.uri, equals(Uri.parse('https://dart.dev/foo/bar.dart')));
      expect(frame.line, isNull);
      expect(frame.column, isNull);
      expect(frame.member, equals('(anonymous function).dart.fn'));
    });
  });

  test('only considers dart URIs to be core', () {
    bool isCore(String library) =>
        Frame.parseVM('#0 Foo ($library:0:0)').isCore;

    expect(isCore('dart:core'), isTrue);
    expect(isCore('dart:async'), isTrue);
    expect(isCore('dart:core/uri.dart'), isTrue);
    expect(isCore('dart:async/future.dart'), isTrue);
    expect(isCore('bart:core'), isFalse);
    expect(isCore('sdart:core'), isFalse);
    expect(isCore('darty:core'), isFalse);
    expect(isCore('bart:core/uri.dart'), isFalse);
  });

  group('.library', () {
    test('returns the URI string for non-file URIs', () {
      expect(Frame.parseVM('#0 Foo (dart:async/future.dart:0:0)').library,
          equals('dart:async/future.dart'));
      expect(
          Frame.parseVM('#0 Foo '
                  '(https://dart.dev/stuff/thing.dart:0:0)')
              .library,
          equals('https://dart.dev/stuff/thing.dart'));
    });

    test('returns the relative path for file URIs', () {
      expect(Frame.parseVM('#0 Foo (foo/bar.dart:0:0)').library,
          equals(path.join('foo', 'bar.dart')));
    });

    test('truncates legacy data: URIs', () {
      var frame = Frame.parseVM(
          '#0 Foo (data:application/dart;charset=utf-8,blah:0:0)');
      expect(frame.library, equals('data:...'));
    });

    test('truncates data: URIs', () {
      var frame = Frame.parseVM(
          '#0      main (<data:application/dart;charset=utf-8>:1:15)');
      expect(frame.library, equals('data:...'));
    });
  });

  group('.location', () {
    test(
        'returns the library and line/column numbers for non-core '
        'libraries', () {
      expect(
          Frame.parseVM('#0 Foo '
                  '(https://dart.dev/thing.dart:5:10)')
              .location,
          equals('https://dart.dev/thing.dart 5:10'));
      expect(Frame.parseVM('#0 Foo (foo/bar.dart:1:2)').location,
          equals('${path.join('foo', 'bar.dart')} 1:2'));
    });
  });

  group('.package', () {
    test('returns null for non-package URIs', () {
      expect(
          Frame.parseVM('#0 Foo (dart:async/future.dart:0:0)').package, isNull);
      expect(
          Frame.parseVM('#0 Foo '
                  '(https://dart.dev/stuff/thing.dart:0:0)')
              .package,
          isNull);
    });

    test('returns the package name for package: URIs', () {
      expect(Frame.parseVM('#0 Foo (package:foo/foo.dart:0:0)').package,
          equals('foo'));
      expect(Frame.parseVM('#0 Foo (package:foo/zap/bar.dart:0:0)').package,
          equals('foo'));
    });
  });

  group('.toString()', () {
    test(
        'returns the library and line/column numbers for non-core '
        'libraries', () {
      expect(
          Frame.parseVM('#0 Foo (https://dart.dev/thing.dart:5:10)').toString(),
          equals('https://dart.dev/thing.dart 5:10 in Foo'));
    });

    test('converts "<anonymous closure>" to "<fn>"', () {
      expect(
          Frame.parseVM('#0 Foo.<anonymous closure> '
                  '(dart:core/uri.dart:5:10)')
              .toString(),
          equals('dart:core/uri.dart 5:10 in Foo.<fn>'));
    });

    test('prints a frame without a column correctly', () {
      expect(Frame.parseVM('#0 Foo (dart:core/uri.dart:5)').toString(),
          equals('dart:core/uri.dart 5 in Foo'));
    });

    test('prints relative paths as relative', () {
      var relative = path.normalize('relative/path/to/foo.dart');
      expect(Frame.parseFriendly('$relative 5:10  Foo').toString(),
          equals('$relative 5:10 in Foo'));
    });
  });
}

void expectIsUnparsed(Frame Function(String) constructor, String text) {
  var frame = constructor(text);
  expect(frame, isA<UnparsedFrame>());
  expect(frame.toString(), equals(text));
}
