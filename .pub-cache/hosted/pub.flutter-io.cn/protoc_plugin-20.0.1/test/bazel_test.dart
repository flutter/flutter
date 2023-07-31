// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:protoc_plugin/bazel.dart';
import 'package:test/test.dart';

void main() {
  group('BazelOptionParser', () {
    late BazelOptionParser optionParser;
    late Map<String, BazelPackage> packages;
    late List<String> errors;
    final optionName = 'name';
    setUp(() {
      packages = {};
      optionParser = BazelOptionParser(packages);
      errors = [];
    });

    void _onError(String message) {
      errors.add(message);
    }

    test('should call onError for null values', () {
      optionParser.parse(optionName, null, _onError);
      expect(errors, isNotEmpty);
    });

    test('should call onError for empty values', () {
      optionParser.parse(optionName, '', _onError);
      expect(errors, isNotEmpty);
    });

    test('should call onError for malformed entries', () {
      optionParser.parse(optionName, 'foo', _onError);
      optionParser.parse(optionName, 'foo|bar', _onError);
      optionParser.parse(optionName, 'foo|bar|baz|quux', _onError);
      expect(errors.length, 3);
      expect(packages, isEmpty);
    });

    test('should handle a single package|path entry', () {
      optionParser.parse(optionName, 'foo|bar/baz|wibble/wobble', _onError);
      expect(errors, isEmpty);
      expect(packages.length, 1);
      expect(packages['bar/baz']!.name, 'foo');
      expect(packages['bar/baz']!.inputRoot, 'bar/baz');
      expect(packages['bar/baz']!.outputRoot, 'wibble/wobble');
    });

    test('should handle multiple package|path entries', () {
      optionParser.parse(
          optionName,
          'foo|bar/baz|wibble/wobble;a|b/c/d|e/f;one.two|three|four/five',
          _onError);
      expect(errors, isEmpty);
      expect(packages.length, 3);
      expect(packages['bar/baz']!.name, 'foo');
      expect(packages['bar/baz']!.inputRoot, 'bar/baz');
      expect(packages['bar/baz']!.outputRoot, 'wibble/wobble');
      expect(packages['b/c/d']!.name, 'a');
      expect(packages['b/c/d']!.inputRoot, 'b/c/d');
      expect(packages['b/c/d']!.outputRoot, 'e/f');
      expect(packages['three']!.name, 'one.two');
      expect(packages['three']!.inputRoot, 'three');
      expect(packages['three']!.outputRoot, 'four/five');
    });

    test('should skip and continue past malformed entries', () {
      optionParser.parse(optionName,
          'foo|bar/baz|wibble/wobble;fizz;a.b|c/d|e/f;x|y|zz|y', _onError);
      expect(errors.length, 2);
      expect(packages.length, 2);
      expect(packages['bar/baz']!.name, 'foo');
      expect(packages['c/d']!.name, 'a.b');
    });

    test('should emit error for conflicting package names', () {
      optionParser.parse(optionName,
          'foo|bar/baz|wibble/wobble;flob|bar/baz|wibble/wobble', _onError);
      expect(errors.length, 1);
      expect(packages.length, 1);
      expect(packages['bar/baz']!.name, 'foo');
    });

    test('should emit error for conflicting outputRoots', () {
      optionParser.parse(optionName,
          'foo|bar/baz|wibble/wobble;foo|bar/baz|womble/wumble', _onError);
      expect(errors.length, 1);
      expect(packages.length, 1);
      expect(packages['bar/baz']!.outputRoot, 'wibble/wobble');
    });

    test('should normalize paths', () {
      optionParser.parse(optionName,
          'foo|bar//baz/|quux/;a|b/|c;c|d//e/f///|g//h//', _onError);
      expect(errors, isEmpty);
      expect(packages.length, 3);
      expect(packages['bar/baz']!.name, 'foo');
      expect(packages['bar/baz']!.inputRoot, 'bar/baz');
      expect(packages['bar/baz']!.outputRoot, 'quux');
      expect(packages['b']!.name, 'a');
      expect(packages['b']!.inputRoot, 'b');
      expect(packages['b']!.outputRoot, 'c');
      expect(packages['d/e/f']!.name, 'c');
      expect(packages['d/e/f']!.inputRoot, 'd/e/f');
      expect(packages['d/e/f']!.outputRoot, 'g/h');
    });
  });

  group('BazelOutputConfiguration', () {
    Map<String, BazelPackage> packages;
    late BazelOutputConfiguration config;

    setUp(() {
      packages = {
        'foo/bar': BazelPackage('a.b.c', 'foo/bar', 'baz/flob'),
        'foo/bar/baz': BazelPackage('d.e.f', 'foo/bar/baz', 'baz/flob/foo'),
        'wibble/wobble':
            BazelPackage('wibble.wobble', 'wibble/wobble', 'womble/wumble'),
      };
      config = BazelOutputConfiguration(packages);
    });

    group('outputPathForUri', () {
      test('should handle files at package root', () {
        var p =
            config.outputPathFor(Uri.parse('foo/bar/quux.proto'), '.pb.dart');
        expect(p.path, 'baz/flob/quux.pb.dart');
      });

      test('should handle files below package root', () {
        var p = config.outputPathFor(
            Uri.parse('foo/bar/a/b/quux.proto'), '.pb.dart');
        expect(p.path, 'baz/flob/a/b/quux.pb.dart');
      });

      test('should handle files in a nested package root', () {
        var p = config.outputPathFor(
            Uri.parse('foo/bar/baz/quux.proto'), '.pb.dart');
        expect(p.path, 'baz/flob/foo/quux.pb.dart');
      });

      test('should handle files below a nested package root', () {
        var p = config.outputPathFor(
            Uri.parse('foo/bar/baz/a/b/quux.proto'), '.pb.dart');
        expect(p.path, 'baz/flob/foo/a/b/quux.pb.dart');
      });

      test('should throw if unable to locate the package for an input', () {
        expect(
            () =>
                config.outputPathFor(Uri.parse('a/b/c/quux.proto'), '.pb.dart'),
            throwsArgumentError);
      });
    });

    group('resolveImport', () {
      test('should emit relative import if in same package', () {
        var target = Uri.parse('foo/bar/quux.proto');
        var source = Uri.parse('foo/bar/baz.proto');
        var uri = config.resolveImport(target, source, '.pb.dart');
        expect(uri.path, 'quux.pb.dart');
      });

      test('should emit relative import if in subdir of same package', () {
        var target = Uri.parse('foo/bar/a/b/quux.proto');
        var source = Uri.parse('foo/bar/baz.proto');
        var uri = config.resolveImport(target, source, '.pb.dart');
        expect(uri.path, 'a/b/quux.pb.dart');
      });

      test('should emit relative import if in parent dir in same package', () {
        var target = Uri.parse('foo/bar/quux.proto');
        var source = Uri.parse('foo/bar/a/b/baz.proto');
        var uri = config.resolveImport(target, source, '.pb.dart');
        expect(uri.path, '../../quux.pb.dart');
      });

      test('should emit package: import if in different package', () {
        var target = Uri.parse('wibble/wobble/quux.proto');
        var source = Uri.parse('foo/bar/baz.proto');
        var uri = config.resolveImport(target, source, '.pb.dart');
        expect(uri.scheme, 'package');
        expect(uri.path, 'wibble.wobble/quux.pb.dart');
      });

      test('should emit package: import if in subdir of different package', () {
        var target = Uri.parse('wibble/wobble/foo/bar/quux.proto');
        var source = Uri.parse('foo/bar/baz.proto');
        var uri = config.resolveImport(target, source, '.pb.dart');
        expect(uri.scheme, 'package');
        expect(uri.path, 'wibble.wobble/foo/bar/quux.pb.dart');
      });

      test('should throw if target is in unknown package', () {
        var target = Uri.parse('flob/flub/quux.proto');
        var source = Uri.parse('foo/bar/baz.proto');
        expect(() => config.resolveImport(target, source, '.pb.dart'),
            throwsA(startsWith('ERROR: cannot generate import for')));
      });
    });
  });
}
