// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/pub.dart';
import 'package:source_span/source_span.dart';
import 'package:test/test.dart';

main() {
  defineTests();
}

defineTests() {
  const src = """
name: linter
version: 0.0.1
author: Dart Team <misc@dartlang.org>
authors:
  - Bill
  - Ted
description: Style linter for Dart.
documentation:
homepage: https://github.com/dart-lang/linter
dependencies:
  transmogrify:
    hosted:
      name: transmogrify
      url: http://your-package-server.com
    version: '>=0.4.0 <1.0.0'
  transmogrify_optional_name:
    hosted:
      url: http://your-package-server.com
    version: '>=0.4.0 <1.0.0'
  transmogrify_short_form:
    hosted: http://your-package-server.com
    version: '>=0.4.0 <1.0.0'
  analyzer: '0.24.0-dev.1'
  cli_util: '>=0.0.1 <0.1.0'
  semver: '>=0.2.0 <0.3.0'
  yaml: '>=2.1.2 <3.0.0'
  kittens:
    git:
      url: git://github.com/munificent/kittens.git
      ref: some-branch
  foo: any
  relative_path:
    path: ../somewhere
dev_dependencies:
  markdown: '>=0.7.1+2 <0.8.0'
  unittest: '>=0.11.0 <0.12.0'
dependency_overrides:
  foo: 1.2.0
repository: https://github.com/dart-lang/linter
issue_tracker: https://github.com/dart-lang/linter/issues
""";

  Pubspec ps = Pubspec.parse(src);

  group('pubspec', () {
    group('basic', () {
      test('toString()', () {
        // For now just confirm it doesn't blow up
        expect(ps.toString(), isNotNull);
      });
    });
    group('entries', () {
      testValue('name', ps.name, equals('linter'));
      testKeySpan('name', ps.name, startOffset: 0, endOffset: 4);
      testValueSpan('name', ps.name, startOffset: 6, endOffset: 12);
      group('documentation', () {
        test('no value', () {
          expect(ps.documentation!.value.text, isNull);
        });
      });
      testValue('homepage', ps.homepage,
          equals('https://github.com/dart-lang/linter'));
      testValue('repository', ps.repository,
          equals('https://github.com/dart-lang/linter'));
      testValue('issue_tracker', ps.issueTracker,
          equals('https://github.com/dart-lang/linter/issues'));
      testValue(
          'description', ps.description, equals('Style linter for Dart.'));
      testValue('version', ps.version, equals('0.0.1'));
      testValue('author', ps.author, equals('Dart Team <misc@dartlang.org>'));

      group('authors', () {
        PSNodeList authors = ps.authors!;
        test('contents', () {
          expect(authors, isNotNull);
          expect(authors.any((PSNode n) => n.text == 'Bill'), isTrue);
          expect(authors.any((PSNode n) => n.text == 'Ted'), isTrue);
        });
      });

      testDepListContains('dependencies', ps.dependencies, [
        {'analyzer': '0.24.0-dev.1'}
      ]);

      testDepListContains('dev_dependencies', ps.devDependencies, [
        {'markdown': '>=0.7.1+2 <0.8.0'}
      ]);

      testDepListContains('dependency_overrides', ps.dependencyOverrides, [
        {'foo': '1.2.0'}
      ]);

      group('path', () {
        PSDependency dep =
            findDependency(ps.dependencies, name: 'relative_path');
        PSEntry depPath = dep.path!;
        testValue('path', depPath, equals('../somewhere'));
      });

      group('hosted', () {
        PSDependency dep =
            findDependency(ps.dependencies, name: 'transmogrify');
        PSHost host = dep.host!;
        testValue('name', host.name, equals('transmogrify'));
        testValue('url', host.url, equals('http://your-package-server.com'));
        testKeySpan('name', host.name, startOffset: 237, endOffset: 241);
        testValueSpan('name', host.name, startOffset: 243, endOffset: 255);
      });

      group('hosted (optional name)', () {
        PSDependency dep =
            findDependency(ps.dependencies, name: 'transmogrify_optional_name');
        PSHost host = dep.host!;
        test('name', () => expect(host.name, isNull));
        testValue('url', host.url, equals('http://your-package-server.com'));
        testKeySpan('url', host.url, startOffset: 376, endOffset: 379);
        testValueSpan('url', host.url, startOffset: 381, endOffset: 411);
      });

      group('hosted (short-form)', () {
        PSDependency dep =
            findDependency(ps.dependencies, name: 'transmogrify_short_form');
        PSHost host = dep.host!;
        test('name', () => expect(host.name, isNull));
        testValue('url', host.url, equals('http://your-package-server.com'));
        testKeySpan('url', host.url, startOffset: 473, endOffset: 479);
        testValueSpan('url', host.url, startOffset: 481, endOffset: 511);
      });

      group('git', () {
        PSDependency dep = findDependency(ps.dependencies, name: 'kittens');
        PSGitRepo git = dep.git!;
        testValue('ref', git.ref, equals('some-branch'));
        testValue(
            'url', git.url, equals('git://github.com/munificent/kittens.git'));
      });
    });
//    group('visiting', () {
//      test('smoke', () {
//        var mock = new MockPubVisitor();
//        ps.accept(mock);
//        verify(mock.visitPackageAuthor(any)).called(1);
//        verify(mock.visitPackageAuthors(any)).called(1);
//        verify(mock.visitPackageDependencies(any)).called(1);
//        verify(mock.visitPackageDependency(any)).called(7);
//        verify(mock.visitPackageDescription(any)).called(1);
//        verify(mock.visitPackageDevDependencies(any)).called(1);
//        verify(mock.visitPackageDevDependency(any)).called(2);
//        verify(mock.visitPackageDocumentation(any)).called(1);
//        verify(mock.visitPackageHomepage(any)).called(1);
//        verify(mock.visitPackageName(any)).called(1);
//        verify(mock.visitPackageVersion(any)).called(1);
//      });
//    });
    // TODO(brianwilkerson) Rewrite this to use a memory resource provider.
//    group('initialization', () {
//      test('sourceUrl', () {
//        File ps = new File('test/_data/p1/_pubspec.yaml');
//        Pubspec spec = new Pubspec.parse(ps.readAsStringSync(),
//            sourceUrl: p.toUri(ps.path));
//        expect(spec.name.key.span.sourceUrl.toFilePath(windows: false),
//            equals('test/_data/p1/_pubspec.yaml'));
//      });
//    });
//    group('parsing', () {
//      test('bad yaml', () {
//        File ps = new File('test/_data/p3/_pubspec.yaml');
//        Pubspec spec = new Pubspec.parse(ps.readAsStringSync(),
//            sourceUrl: p.toUri(ps.path));
//        expect(spec.name, isNull);
//        expect(spec.description, isNull);
//      });
//    });
  });
}

PSDependency findDependency(PSDependencyList? deps, {String? name}) =>
    deps!.firstWhere((dep) => dep.name!.text == name);

testDepListContains(
    String label, PSDependencyList? list, List<Map<String, String>> exp) {
  test(label, () {
    exp.forEach((Map<String, String> entry) {
      entry.forEach((k, v) {
        PSDependency dep = findDependency(list, name: k);
        expect(dep, isNotNull);
        expect(dep.version!.value.text, equals(v));
      });
    });
  });
}

testEntry(String label, PSEntry node, Matcher m) {
  group(label, () {
    test('entry', () {
      expect(node, m);
    });
  });
}

testKeySpan(String label, PSEntry? node, {int? startOffset, int? endOffset}) {
  group(label, () {
    group('key', () {
      testSpan(node!.key!.span, startOffset: startOffset, endOffset: endOffset);
    });
  });
}

testSpan(SourceSpan span, {int? startOffset, int? endOffset}) {
  test('span', () {
    var start = span.start;
    expect(start, isNotNull);
    expect(start.offset, equals(startOffset));
    var end = span.end;
    expect(end, isNotNull);
    expect(end.offset, equals(endOffset));
  });
}

testValue(String label, PSEntry? node, Matcher m) {
  group(label, () {
    test('value', () {
      expect(node!.value.text, m);
    });
  });
}

testValueSpan(String label, PSEntry? node, {int? startOffset, int? endOffset}) {
  group(label, () {
    group('value', () {
      testSpan(node!.value.span,
          startOffset: startOffset, endOffset: endOffset);
    });
  });
}
