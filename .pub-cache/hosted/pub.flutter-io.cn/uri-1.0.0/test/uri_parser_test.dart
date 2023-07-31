// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library uri.uri_parser_test;

import 'package:test/test.dart';
import 'package:uri/uri.dart';

void main() {
  group('UriParser.parse', () {
    test('should parse simple variables', () {
      expectParse('/head/{a}/{b}/tail', '/head/x/y/tail', {'a': 'x', 'b': 'y'},
          reverse: true);
    });

    test('should parse variables with non-alpha characters', () {
      final unreserved = ['-', '.', '_', '~'];
      for (var c in unreserved) {
        expectParse('/{a}', '/one${c}two', {'a': 'one${c}two'}, reverse: true);
        expectParse('/{+a}', '/one${c}two', {'a': 'one${c}two'}, reverse: true);
      }
    });

    test('should parse multiple variables per expression', () {
      expectParse('{a,b}', 'xx,yy', {'a': 'xx', 'b': 'yy'}, reverse: true);
    });

    test('should ignore explode and prefix modifiers', () {
      // TODO(justin): should a prefix modifier affect matching?
      expectParse('/head/{a*}/{b:3}', '/head/x/y', {'a': 'x', 'b': 'y'},
          reverse: true);
    });

    test('should parse reserved variables', () {
      expectParse('/head/{+a}/tail', '/head/xx/yy/tail', {'a': 'xx/yy'},
          reverse: true);
      // ?, #, [,  and ] cannot appear in URI paths, so don't include them in
      // the reserved char set
      // there's a problem with ":" in SDK 1.3
      const reservedChars = r"/@!$&'()*+,;=";
      for (var c in reservedChars.split('')) {
        expectParse('{+a}', c, {'a': c}, reverse: true);
      }
    });

    test('should parse query variables', () {
      expectParse('/foo{?a,b}', '/foo?a=xx&b=yy', {'a': 'xx', 'b': 'yy'});
      expectParse('/foo{?a,b}', '/foo?b=yy&a=xx', {'a': 'xx', 'b': 'yy'});
      expectParse('/foo{?a,b}', '/foo?b=yy&a=xx&c=zz', {'a': 'xx', 'b': 'yy'});
    });

    test('should parse a mix of query expressions and specified values', () {
      expectParse('/foo?a=x{&b}', '/foo?a=x&b=y', {'b': 'y'});
    });

    test('should parse fragment variables', () {
      expectParse('/foo{#a}', '/foo#xx', {'a': 'xx'});
      expectParse('/foo{#a,b}', '/foo#xx,yy', {'a': 'xx', 'b': 'yy'});
      expectParse('/foo{#a,b}', '/foo#xx,', {'a': 'xx', 'b': ''});
    });

    test('should parse path and query expressions', () {
      expectParse('/foo/{a}{?b}', '/foo/xx?b=yy', {'a': 'xx', 'b': 'yy'});
    });

    test('should match path and fragment expressions', () {
      expectParse('/foo/{a}{#b}', '/foo/xx#yy', {'a': 'xx', 'b': 'yy'});
    });

    test('should parse query and fragment expressions', () {
      expectParse('/foo{?a}{#b}', '/foo?a=xx#yy', {'a': 'xx', 'b': 'yy'});
    });
  });

  group('UriParser.match', () {
    group('on paths', () {
      test('should match a simple path', () {
        expectParsePrefix('/foo', '/foo', {}, restPath: '');
      });

      test('should match a path prefix', () {
        expectParsePrefix('/foo', '/foo/bar', {}, restPath: 'bar');
      });

      test('should not match a partial prefix', () {
        expectNonMatch('/fo', '/foo/bar');
      });

      test('should not match a non-mathcing path', () {
        expectParsePrefix('/foo', '/bar/baz', {}, matches: false);
      });

      test('should match a path prefix with expressions', () {
        expectParsePrefix('/foo/{a}', '/foo/bar/baz', {'a': 'bar'},
            restPath: 'baz');
        expectParsePrefix('/fo{a}', '/foo/bar/baz', {'a': 'o'},
            restPath: 'bar/baz');
        expectParsePrefix(
            '/foo/{a}/baz/{b}', '/foo/bar/baz/qux', {'a': 'bar', 'b': 'qux'},
            restPath: '');
      });

      test('should preserve query parameters in UriMatch.rest', () {
        expectParsePrefix('/foo', '/foo/bar?baz=blah', {},
            restPath: 'bar', restQuery: 'baz=blah');
      });
    });

    group('on fragments', () {
      test('should match a simple fragment', () {
        expectParsePrefix('/foo#bar', '/foo#bar', {});
      });

      test('should not match a non-mathcing fragment', () {
        expectParsePrefix('/foo#bar', '/foo#baz', {}, matches: false);
      });

      // proposed behavior: perform a prefix match when the fragment
      // contains path seperators: '/' or '.'
      test('should match a fragment prefix', () {
        expectParsePrefix('/foo#bar', '/foo#bar/baz', {},
            restPath: '', restFragment: 'baz');
        expectParsePrefix('/foo#bar', '/foo#bar.baz', {},
            restPath: '', restFragment: 'baz');
        expectParsePrefix('/foo#bar/', '/foo#bar/baz', {},
            restPath: '', restFragment: 'baz');
        expectParsePrefix('/foo#bar', '/foo#bar/baz/qux', {},
            restPath: '', restFragment: 'baz/qux');
        expectParsePrefix('/foo#bar', '/foo#bar.baz.qux', {},
            restPath: '', restFragment: 'baz.qux');
      });

      // proposed behavior: prefix matches must match an entire path segment
      test('should not match a partial fragment prefix', () {
        expectParsePrefix('/foo#ba', '/foo#bar/baz', {}, matches: false);
        expectParsePrefix('/foo#ba', '/foo#bar.baz', {}, matches: false);
      });

      test('should match a fragment prefix with expressions', () {
        expectParsePrefix('/foo#bar/{#a}', '/foo#bar/baz/qux', {'a': 'baz'},
            restPath: '', restFragment: 'qux');
        expectParsePrefix('/foo#bar/{#a}/qux/{#b}', '/foo#bar/baz/qux/quux',
            {'a': 'baz', 'b': 'quux'},
            restPath: '', restFragment: '');
      });
    });

    test('should not match a non-mathcing query', () {
      expectParsePrefix('/foo?a=x', '/foo?b=y', {}, matches: false);
    });
  });

  group('UriParser.matches', () {
    // expressionless cases
    test('should match path literals', () {
      expectMatch('/foo', '/foo');
    });

    test('should not match non-matching path literals', () {
      expectNonMatch('/foo', '/bar');
    });

    // TODO(justinfagnani) reenable when we figure out how to support both
    // prefixed and non-prefixed paths
    test('should not perform partial matches', () {
      expectNonMatch('/foo', '/foo2');
      expectNonMatch('/foo', '/foo/bar');
    },
        skip: 'TODO(justinfagnani) reenable when we figure out how to support '
            'both prefixed and non-prefixed paths');

    test('should match fragments literals', () {
      expectMatch('/foo#xx', '/foo#xx');
    });

    test('should not match non-matching fragments', () {
      expectNonMatch('/foo#xx', '/foo#yy');
      expectNonMatch('/foo#xx', '/foo#xxy');
    });

    test('should match on specified query values', () {
      expectMatch('/foo?a=x&b=y', '/foo?a=x&b=y');
      expectMatch('/foo?b=y&a=x', '/foo?a=x&b=y');
      expectMatch('/foo?a=x&b=y', '/foo?b=y&a=x');
      expectMatch('/foo?a=x&b=y', '/foo?a=x&b=y&c=z');
    });

    test('should not match on if query values don\'t match', () {
      expectNonMatch('/foo?a=x&b=y', '/foo?a=a&b=b');
      expectNonMatch('/foo?a=x&b=y', '/foo?a=a&b=y');
    });

    test('should match query and fragment literals', () {
      expectMatch('/foo?a=x&b=y#c', '/foo?a=x&b=y#c');
    });

    test('should throw on out-of-order URI parts', () {
      expect(() => UriParser(UriTemplate('/foo#c?a=x&b=y')),
          throwsA(const TypeMatcher<ParseException>()));
    });

    test('should match paths using simple variables', () {
      expectMatch('/head/{a}/{b}/tail', '/head/xx/yy/tail');
    });

    test('should match query expressions', () {
      expectMatch('/foo{?a}', '/foo?a=x');
    });

    test('should not match if query parameters not present', () {
      expectNonMatch('/foo{?a}', '/foo');
      expectNonMatch('/foo{?a,b}', '/foo?a=x');
    });

    test(
      'should match if query parameters not present when '
      'queryParamsAreOptional is true',
      () {
        expectMatch('/foo{?a}', '/foo', queryParamsAreOptional: true);
        expectMatch('/foo{?a,b}', '/foo?a=x', queryParamsAreOptional: true);
      },
    );

    test('should match a mix of query expressions and specified values', () {
      expectMatch('/foo?a=x{&b}', '/foo?a=x&b=y');
      expectMatch('/foo?a=x{&b}', '/foo?b=y&a=x');
    });

    test('should match fragment expressions', () {
      expectMatch('/foo{#a}', '/foo#xx');
      expectMatch('/foo{#a,b}', '/foo#xx,yy');
      expectMatch('/foo{#a}suffix', '/foo#xxsuffix');
      expectMatch('/foo#prefix{#a}', '/foo#prefixxx');
    });

    test('should not match fragment expressions on URIs with no fragment', () {
      expectNonMatch('/foo{#a}', '/foo');
    });

    test('should match path and query expressions', () {
      expectMatch('/foo/{a}{?b}', '/foo/xx?b=yy');
    });

    test('should match path and fragment expressions', () {
      expectMatch('/foo/{a}{#b}', '/foo/xx#yy');
    });

    test('should match query and fragment expressions', () {
      expectMatch('/foo{?a}{#b}', '/foo?a=xx#yy');
    });
  });
}

void expectParse(
  String template,
  String uriString,
  Map<String, Object> variables, {
  bool reverse = false,
}) {
  final uri = Uri.parse(uriString);
  final uriTemplate = UriTemplate(template);
  final parser = UriParser(uriTemplate);

  expect(parser.parse(uri), equals(variables));
  expect(parser.matches(uri), true);
  if (reverse) {
    expect(uriTemplate.expand(variables), uri.toString());
  }
}

void expectParsePrefix(
  String template,
  String uriString,
  Object? variables, {
  Object? restPath,
  Object? restFragment,
  Object? restQuery,
  bool matches = true,
}) {
  final uri = Uri.parse(uriString);
  final parser = UriParser(UriTemplate(template));
  final match = parser.match(uri);
  expect(match == null, !matches);
  if (match != null) {
    if (restPath != null) expect(match.rest.path, restPath);
    if (restQuery != null) expect(match.rest.query, restQuery);
    if (restFragment != null) expect(match.rest.fragment, restFragment);
    expect(match.parameters, variables);
  }
}

void expectMatch(String template, String uriString,
    {bool queryParamsAreOptional = false}) {
  final uri = Uri.parse(uriString);
  final parser = UriParser(UriTemplate(template),
      queryParamsAreOptional: queryParamsAreOptional);
  expect(parser.matches(uri), true, reason: '${parser.pathRegex}');
}

void expectNonMatch(String template, String uriString) {
  final uri = Uri.parse(uriString);
  expect(UriParser(UriTemplate(template)).matches(uri), false);
}
