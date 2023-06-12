// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:coverage/src/resolver.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  group('Default Resolver', () {
    setUp(() async {
      final String sandboxUriPath = p.toUri(d.sandbox).toString();
      await d.dir('bar', [
        d.dir('lib', [
          d.file('bar.dart', 'final fizz = "bar";'),
        ])
      ]).create();

      await d.dir('foo', [
        d.dir('.dart_tool', [
          d.file('bad_package_config.json', 'thisIsntAPackageConfigFile!'),
          d.file('package_config.json', '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "foo",
      "rootUri": "../",
      "packageUri": "lib/"
    },
    {
      "name": "bar",
      "rootUri": "$sandboxUriPath/bar",
      "packageUri": "lib/"
    }
  ]
}
'''),
        ]),
        d.dir('lib', [
          d.file('foo.dart', 'final foo = "bar";'),
        ]),
      ]).create();

      await d.dir('sdk', [
        d.dir('io', [
          d.file('io.dart', 'final io = "hello";'),
        ]),
        d.dir('io_patch', [
          d.file('io.dart', 'final patch = true;'),
        ]),
        d.dir('io_dev', [
          d.file('io.dart', 'final dev = true;'),
        ]),
      ]).create();
    });

    test('can be created from a package_config.json', () async {
      final resolver = await Resolver.create(
          packagesPath:
              p.join(d.sandbox, 'foo', '.dart_tool', 'package_config.json'));
      expect(resolver.resolve('package:foo/foo.dart'),
          p.join(d.sandbox, 'foo', 'lib', 'foo.dart'));
      expect(resolver.resolve('package:bar/bar.dart'),
          p.join(d.sandbox, 'bar', 'lib', 'bar.dart'));
    });

    test('can be created from a package directory', () async {
      final resolver =
          await Resolver.create(packagePath: p.join(d.sandbox, 'foo'));
      expect(resolver.resolve('package:foo/foo.dart'),
          p.join(d.sandbox, 'foo', 'lib', 'foo.dart'));
    });

    test('errors if the packagesFile is an unknown format', () async {
      expect(
          () async => await Resolver.create(
              packagesPath: p.join(
                  d.sandbox, 'foo', '.dart_tool', 'bad_package_config.json')),
          throwsA(isA<FormatException>()));
    });

    test('resolves dart: URIs', () async {
      final resolver = await Resolver.create(
          packagePath: p.join(d.sandbox, 'foo'),
          sdkRoot: p.join(d.sandbox, 'sdk'));
      expect(resolver.resolve('dart:io'),
          p.join(d.sandbox, 'sdk', 'io', 'io.dart'));
      expect(resolver.resolve('dart:io-patch/io.dart'), null);
      expect(resolver.resolve('dart:io-dev/io.dart'),
          p.join(d.sandbox, 'sdk', 'io_dev', 'io.dart'));
    });

    test('cannot resolve SDK URIs if sdkRoot is null', () async {
      final resolver =
          await Resolver.create(packagePath: p.join(d.sandbox, 'foo'));
      expect(resolver.resolve('dart:convert'), null);
    });

    test('cannot resolve package URIs if packagePath is null', () async {
      // ignore: deprecated_member_use_from_same_package
      final resolver = Resolver();
      expect(resolver.resolve('package:foo/foo.dart'), null);
    });

    test('cannot resolve package URIs if packagePath is not found', () async {
      final resolver =
          await Resolver.create(packagePath: p.join(d.sandbox, 'foo'));
      expect(resolver.resolve('package:baz/baz.dart'), null);
    });

    test('cannot resolve unexpected URI schemes', () async {
      final resolver =
          await Resolver.create(packagePath: p.join(d.sandbox, 'foo'));
      expect(resolver.resolve('thing:foo/foo.dart'), null);
    });
  });

  group('Bazel resolver', () {
    const workspace = 'foo';
    final resolver = BazelResolver(workspacePath: workspace);

    test('does not resolve SDK URIs', () {
      expect(resolver.resolve('dart:convert'), null);
    });

    test('resolves third-party package URIs', () {
      expect(resolver.resolve('package:foo/bar.dart'),
          'third_party/dart/foo/lib/bar.dart');
      expect(resolver.resolve('package:foo/src/bar.dart'),
          'third_party/dart/foo/lib/src/bar.dart');
    });

    test('resolves non-third-party package URIs', () {
      expect(
          resolver.resolve('package:foo.bar/baz.dart'), 'foo/bar/lib/baz.dart');
      expect(resolver.resolve('package:foo.bar/src/baz.dart'),
          'foo/bar/lib/src/baz.dart');
    });

    test('resolves file URIs', () {
      expect(
          resolver
              .resolve('file://x/y/z.runfiles/$workspace/foo/bar/lib/baz.dart'),
          'foo/bar/lib/baz.dart');
      expect(
          resolver.resolve(
              'file://x/y/z.runfiles/$workspace/foo/bar/lib/src/baz.dart'),
          'foo/bar/lib/src/baz.dart');
    });

    test('resolves HTTPS URIs containing /packages/', () {
      expect(resolver.resolve('https://host:8080/a/b/packages/foo/bar.dart'),
          'third_party/dart/foo/lib/bar.dart');
      expect(
          resolver.resolve('https://host:8080/a/b/packages/foo/src/bar.dart'),
          'third_party/dart/foo/lib/src/bar.dart');
      expect(
          resolver.resolve('https://host:8080/a/b/packages/foo.bar/baz.dart'),
          'foo/bar/lib/baz.dart');
      expect(
          resolver
              .resolve('https://host:8080/a/b/packages/foo.bar/src/baz.dart'),
          'foo/bar/lib/src/baz.dart');
    });

    test('resolves HTTP URIs containing /packages/', () {
      expect(resolver.resolve('http://host:8080/a/b/packages/foo/bar.dart'),
          'third_party/dart/foo/lib/bar.dart');
      expect(resolver.resolve('http://host:8080/a/b/packages/foo/src/bar.dart'),
          'third_party/dart/foo/lib/src/bar.dart');
      expect(resolver.resolve('http://host:8080/a/b/packages/foo.bar/baz.dart'),
          'foo/bar/lib/baz.dart');
      expect(
          resolver
              .resolve('http://host:8080/a/b/packages/foo.bar/src/baz.dart'),
          'foo/bar/lib/src/baz.dart');
    });

    test('resolves HTTPS URIs without /packages/', () {
      expect(
          resolver
              .resolve('https://host:8080/third_party/dart/foo/lib/bar.dart'),
          'third_party/dart/foo/lib/bar.dart');
      expect(
          resolver.resolve(
              'https://host:8080/third_party/dart/foo/lib/src/bar.dart'),
          'third_party/dart/foo/lib/src/bar.dart');
      expect(resolver.resolve('https://host:8080/foo/lib/bar.dart'),
          'foo/lib/bar.dart');
      expect(resolver.resolve('https://host:8080/foo/lib/src/bar.dart'),
          'foo/lib/src/bar.dart');
    });

    test('resolves HTTP URIs without /packages/', () {
      expect(
          resolver
              .resolve('http://host:8080/third_party/dart/foo/lib/bar.dart'),
          'third_party/dart/foo/lib/bar.dart');
      expect(
          resolver.resolve(
              'http://host:8080/third_party/dart/foo/lib/src/bar.dart'),
          'third_party/dart/foo/lib/src/bar.dart');
      expect(resolver.resolve('http://host:8080/foo/lib/bar.dart'),
          'foo/lib/bar.dart');
      expect(resolver.resolve('http://host:8080/foo/lib/src/bar.dart'),
          'foo/lib/src/bar.dart');
    });
  });
}
