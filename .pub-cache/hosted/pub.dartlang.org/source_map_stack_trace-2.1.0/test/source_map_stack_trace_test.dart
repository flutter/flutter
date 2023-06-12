// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;
import 'package:source_maps/source_maps.dart';
import 'package:source_span/source_span.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:source_map_stack_trace/source_map_stack_trace.dart';
import 'package:test/test.dart';

/// A simple [Mapping] for tests that don't need anything special.
final _simpleMapping = parseJson((SourceMapBuilder()
      ..addSpan(
          SourceMapSpan.identifier(
              SourceLocation(1, line: 1, column: 3, sourceUrl: 'foo.dart'),
              'qux'),
          SourceSpan(SourceLocation(8, line: 5, column: 0),
              SourceLocation(18, line: 15, column: 0), '\n' * 10)))
    .build('foo.dart.js.map'));

final _packageMap = {
  'bar': Uri.parse('packages/bar'),
  'foo': Uri.parse('packages/foo'),
};

void main() {
  test('maps a JS line and column to a Dart line and span', () {
    var trace = Trace.parse('foo.dart.js 10:11  foo');
    var frame = _mapTrace(_simpleMapping, trace).frames.first;
    expect(frame.uri, equals(Uri.parse('foo.dart')));

    // These are +1 because stack_trace is 1-based whereas source_span is
    // 0-basd.
    expect(frame.line, equals(2));
    expect(frame.column, equals(4));
  });

  test('ignores JS frames without line info', () {
    var trace = Trace.parse('''
foo.dart.js 10:11  foo
foo.dart.js        bar
foo.dart.js 10:11  baz
''');
    var frames = _mapTrace(_simpleMapping, trace).frames;

    expect(frames.length, equals(2));
    expect(frames.first.member, equals('foo'));
    expect(frames.last.member, equals('baz'));
  });

  test('ignores JS frames without corresponding spans', () {
    var trace = Trace.parse('''
foo.dart.js 10:11  foo
foo.dart.js 1:1   bar
foo.dart.js 10:11  baz
''');

    var frames = _mapTrace(_simpleMapping, trace).frames;

    expect(frames.length, equals(2));
    expect(frames.first.member, equals('foo'));
    expect(frames.last.member, equals('baz'));
  });

  test('include frames from JS files not covered by the source map bundle', () {
    var trace = Trace.parse('''
foo.dart.js 10:11  foo
jquery.js 10:1  foo
bar.dart.js 10:11  foo
''');
    var builder = SourceMapBuilder()
      ..addSpan(
          SourceMapSpan.identifier(
              SourceLocation(1,
                  line: 1, column: 3, sourceUrl: 'packages/foo/foo.dart'),
              'qux'),
          SourceSpan(SourceLocation(8, line: 5, column: 0),
              SourceLocation(12, line: 9, column: 1), '\n' * 4));
    var sourceMapJson1 = builder.build('foo.dart.js.map');
    sourceMapJson1['file'] = 'foo.dart.js';

    builder = SourceMapBuilder()
      ..addSpan(
          SourceMapSpan.identifier(
              SourceLocation(1,
                  line: 1, column: 3, sourceUrl: 'packages/bar/bar.dart'),
              'qux'),
          SourceSpan(SourceLocation(8, line: 5, column: 0),
              SourceLocation(12, line: 9, column: 1), '\n' * 4));
    var sourceMapJson2 = builder.build('bar.dart.js.map');
    sourceMapJson2['file'] = 'bar.dart.js';

    var bundle = [sourceMapJson1, sourceMapJson2];
    var mapping = parseJsonExtended(bundle);
    var frames = _mapTrace(mapping, trace, packageMap: _packageMap).frames;

    expect(frames.length, equals(3));

    var frame = frames[0];
    expect(frame.uri, equals(Uri.parse('package:foo/foo.dart')));
    expect(frame.line, equals(2));
    expect(frame.column, equals(4));

    frame = frames[1];
    expect(p.basename(frame.uri.toString()), equals('jquery.js'));
    expect(frame.line, equals(10));

    frame = frames[2];
    expect(frame.uri, equals(Uri.parse('package:bar/bar.dart')));
    expect(frame.line, equals(2));
    expect(frame.column, equals(4));
  });

  test('falls back to column 0 for unlisted column', () {
    var trace = Trace.parse('foo.dart.js 10  foo');
    var builder = SourceMapBuilder()
      ..addSpan(
          SourceMapSpan.identifier(
              SourceLocation(1, line: 1, column: 3, sourceUrl: 'foo.dart'),
              'qux'),
          SourceSpan(SourceLocation(8, line: 5, column: 0),
              SourceLocation(12, line: 9, column: 1), '\n' * 4));

    var mapping = parseJson(builder.build('foo.dart.js.map'));
    var frame = _mapTrace(mapping, trace).frames.first;
    expect(frame.uri, equals(Uri.parse('foo.dart')));
    expect(frame.line, equals(2));
    expect(frame.column, equals(4));
  });

  test('uses package: URIs for frames within a packageResolver.packageMap URL',
      () {
    var trace = Trace.parse('foo.dart.js 10  foo');
    var builder = SourceMapBuilder()
      ..addSpan(
          SourceMapSpan.identifier(
              SourceLocation(1,
                  line: 1, column: 3, sourceUrl: 'packages/foo/foo.dart'),
              'qux'),
          SourceSpan(SourceLocation(8, line: 5, column: 0),
              SourceLocation(12, line: 9, column: 1), '\n' * 4));

    var mapping = parseJson(builder.build('foo.dart.js.map'));
    var mappedTrace = _mapTrace(mapping, trace, packageMap: _packageMap);
    var frame = mappedTrace.frames.first;
    expect(frame.uri, equals(Uri.parse('package:foo/foo.dart')));
    expect(frame.line, equals(2));
    expect(frame.column, equals(4));
  });

  test('uses dart: URIs for frames within sdkRoot', () {
    var trace = Trace.parse('foo.dart.js 10  foo');
    var builder = SourceMapBuilder()
      ..addSpan(
          SourceMapSpan.identifier(
              SourceLocation(1,
                  line: 1, column: 3, sourceUrl: 'sdk/lib/async/foo.dart'),
              'qux'),
          SourceSpan(SourceLocation(8, line: 5, column: 0),
              SourceLocation(12, line: 9, column: 1), '\n' * 4));

    var mapping = parseJson(builder.build('foo.dart.js.map'));
    var frame =
        _mapTrace(mapping, trace, sdkRoot: Uri.parse('sdk/')).frames.first;
    expect(frame.uri, equals(Uri.parse('dart:async/foo.dart')));
    expect(frame.line, equals(2));
    expect(frame.column, equals(4));
  });

  test('converts a stack chain', () {
    var trace = Chain([
      Trace.parse('foo.dart.js 10:11  foo'),
      Trace.parse('foo.dart.js 10:11  bar')
    ]);
    var traces = _mapChain(_simpleMapping, trace).traces;

    var frame = traces.first.frames.single;
    expect(frame.uri, equals(Uri.parse('foo.dart')));
    expect(frame.member, equals('foo'));
    expect(frame.line, equals(2));
    expect(frame.column, equals(4));

    frame = traces.last.frames.single;
    expect(frame.uri, equals(Uri.parse('foo.dart')));
    expect(frame.member, equals('bar'));
    expect(frame.line, equals(2));
    expect(frame.column, equals(4));
  });

  group('cleans up', () {
    test('Firefox junk', () {
      expect(_prettify('foo/<'), equals('foo'));
      expect(_prettify('foo<'), equals('foo'));
    });

    test('arity indicators', () {
      expect(_prettify(r'foo$1'), equals('foo'));
      expect(_prettify(r'foo$1234'), equals('foo'));
    });

    test('named arguments', () {
      expect(_prettify(r'foo$1$bar'), equals('foo'));
      expect(_prettify(r'foo$123$bar$bang$qux'), equals('foo'));
    });

    test('closures', () {
      expect(_prettify('foo_closure.call'), equals('foo.<fn>'));
    });

    test('nested closures', () {
      expect(_prettify('foo__closure.call'), equals('foo.<fn>.<fn>'));
      expect(
          _prettify('foo____closure.call'), equals('foo.<fn>.<fn>.<fn>.<fn>'));
    });

    test('.call', () {
      expect(_prettify('foo.call'), equals('foo'));
    });

    test('top-level functions', () {
      expect(_prettify('dart.foo'), equals('foo'));
    });

    test('library namespaces', () {
      expect(_prettify(r'my_library$foo'), equals('foo'));
    });

    test('static methods', () {
      expect(_prettify(r'Foo.static.foo'), equals('foo'));
    });

    test('instance methods', () {
      expect(_prettify(r'Foo_bar__baz'), equals('Foo.bar._baz'));
    });

    test('lots of stuff', () {
      expect(_prettify(r'lib$Foo.static.lib$Foo_closure.call$0/<'),
          equals('Foo.<fn>'));
    });
  });
}

/// Like [mapStackTrace], but is guaranteed to return a [Trace] so it can be
/// inspected.
Trace _mapTrace(Mapping sourceMap, StackTrace stackTrace,
    {bool minified = false, Map<String, Uri>? packageMap, Uri? sdkRoot}) {
  return Trace.from(mapStackTrace(sourceMap, stackTrace,
      minified: minified, packageMap: packageMap, sdkRoot: sdkRoot));
}

/// Like [mapStackTrace], but is guaranteed to return a [Chain] so it can be
/// inspected.
Chain _mapChain(Mapping sourceMap, StackTrace stackTrace,
    {bool minified = false, Map<String, Uri>? packageMap, Uri? sdkRoot}) {
  return Chain.forTrace(mapStackTrace(sourceMap, stackTrace,
      minified: minified, packageMap: packageMap, sdkRoot: sdkRoot));
}

/// Runs the mapper's prettification logic on [member] and returns the result.
String? _prettify(String member) {
  var trace = Trace([Frame(Uri.parse('foo.dart.js'), 10, 11, member)]);
  return _mapTrace(_simpleMapping, trace).frames.first.member;
}
