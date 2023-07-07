// Copyright 2020 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.9

import 'package:dwds/dwds.dart';
import 'package:dwds/src/debugging/location.dart';
import 'package:dwds/src/debugging/modules.dart';
import 'package:dwds/src/loaders/strategy.dart';
import 'package:dwds/src/utilities/dart_uri.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

import 'debugger_test.dart';

void main() {
  const lines = 100;
  const lineLength = 150;

  globalLoadStrategy = MockLoadStrategy();
  final dartUri = DartUri('org-dartlang://web/main.dart');

  final assetReader = FakeAssetReader();
  final modules = MockModules();
  final locations = Locations(assetReader, modules, '');
  locations.initialize('fake_entrypoint');

  group('JS locations |', () {
    group('location |', () {
      test('is zero based', () async {
        final loc = JsLocation.fromZeroBased(_module, 0, 0);
        expect(loc, _matchJsLocation(0, 0));
      });

      test('can compare to other location', () async {
        final loc00 = JsLocation.fromZeroBased(_module, 0, 0);
        final loc01 = JsLocation.fromZeroBased(_module, 0, 1);
        final loc10 = JsLocation.fromZeroBased(_module, 1, 0);
        final loc11 = JsLocation.fromZeroBased(_module, 1, 1);

        expect(loc00.compareTo(loc01), isNegative);
        expect(loc00.compareTo(loc10), isNegative);
        expect(loc00.compareTo(loc10), isNegative);
        expect(loc00.compareTo(loc11), isNegative);

        expect(loc00.compareTo(loc00), isZero);
        expect(loc11.compareTo(loc00), isPositive);
      });
    });

    group('best location |', () {
      test('does not return location for setup code', () async {
        final location = await locations.locationForJs(_module, 0, 0);
        expect(location, isNull);
      });

      test('prefers precise match', () async {
        final location = await locations.locationForJs(_module, 37, 0);
        expect(location, _matchLocationForJs(37, 0));
      });

      test('finds a match in the beginning of the line', () async {
        final location = await locations.locationForJs(_module, 39, 4);
        expect(location, _matchLocationForJs(39, 0));
      });

      test('finds a match in the middle of the line', () async {
        final location = await locations.locationForJs(_module, 39, 10);
        expect(location, _matchLocationForJs(39, 6));
      });

      test('finds a match on a previous line', () async {
        final location = await locations.locationForJs(_module, 44, 0);
        expect(location, _matchLocationForJs(43, 18));
      });

      test('finds a match on a previous line with a closer match after',
          () async {
        final location =
            await locations.locationForJs(_module, 44, lineLength - 1);
        expect(location, _matchLocationForJs(43, 18));
      });

      test('finds a match on the last line', () async {
        final location =
            await locations.locationForJs(_module, lines - 1, lineLength - 1);
        expect(location, _matchLocationForJs(50, 2));
      });

      test('finds a match on invalid line', () async {
        final location =
            await locations.locationForJs(_module, lines, lineLength - 1);
        expect(location, _matchLocationForJs(50, 2));
      });

      test('finds a match on invalid column on the same line', () async {
        final location = await locations.locationForJs(_module, 50, lineLength);
        expect(location, _matchLocationForJs(50, 2));
      });

      test('finds a match on invalid column on a previous line', () async {
        final location =
            await locations.locationForJs(_module, lines - 1, lineLength);
        expect(location, _matchLocationForJs(50, 2));
      });
    });
  });

  group('Dart locations |', () {
    group('location |', () {
      test('is one based', () async {
        final loc = DartLocation.fromZeroBased(dartUri, 0, 0);
        expect(loc, _matchDartLocation(1, 1));
      });

      test('can compare to other locations', () async {
        final loc00 = DartLocation.fromZeroBased(dartUri, 0, 0);
        final loc01 = DartLocation.fromZeroBased(dartUri, 0, 1);
        final loc10 = DartLocation.fromZeroBased(dartUri, 1, 0);
        final loc11 = DartLocation.fromZeroBased(dartUri, 1, 1);

        expect(loc00.compareTo(loc01), isNegative);
        expect(loc00.compareTo(loc10), isNegative);
        expect(loc00.compareTo(loc10), isNegative);
        expect(loc00.compareTo(loc11), isNegative);

        expect(loc00.compareTo(loc00), isZero);
        expect(loc11.compareTo(loc00), isPositive);
      });
    });

    group('best location |', () {
      test('does not return location for dart lines not mapped to JS',
          () async {
        final location = await locations.locationForDart(dartUri, 0, 0);
        expect(location, isNull);
      });

      test('returns location after on the same line', () async {
        final location = await locations.locationForDart(dartUri, 11, 0);
        expect(location, _matchLocationForDart(11, 3));
      });

      test('return null on invalid line', () async {
        final location = await locations.locationForDart(dartUri, lines, 0);
        expect(location, isNull);
      });

      test('return null on invalid column', () async {
        final location =
            await locations.locationForDart(dartUri, lines - 1, lineLength);
        expect(location, isNull);
      });
    });
  });
}

Matcher _matchLocationForDart(int line, int column) => isA<Location>().having(
    (l) => l.dartLocation, 'dartLocation', _matchDartLocation(line, column));

Matcher _matchLocationForJs(int line, int column) => isA<Location>()
    .having((l) => l.jsLocation, 'jsLocation', _matchJsLocation(line, column));

Matcher _matchDartLocation(int line, int column) => isA<DartLocation>()
    .having((l) => l.line, 'line', line)
    .having((l) => l.column, 'column', column);

Matcher _matchJsLocation(int line, int column) => isA<JsLocation>()
    .having((l) => l.line, 'line', line)
    .having((l) => l.column, 'column', column);

const _module = 'packages/module';
const _serverPath = 'package/module.js';
const _sourceMapPath = 'packages/module.js.map';

class MockLoadStrategy implements LoadStrategy {
  @override
  Future<String> bootstrapFor(String entrypoint) async => 'dummy_bootstrap';

  @override
  shelf.Handler get handler =>
      (request) => (request.url.path == 'someDummyPath')
          ? shelf.Response.ok('some dummy response')
          : null;

  @override
  String get id => 'dummy-id';

  @override
  String get moduleFormat => 'dummy-format';

  @override
  String get loadLibrariesModule => '';

  @override
  String get loadLibrariesSnippet => '';

  @override
  String loadLibrarySnippet(String libraryUri) => '';

  @override
  String get loadModuleSnippet => '';

  @override
  ReloadConfiguration get reloadConfiguration => ReloadConfiguration.none;

  @override
  String loadClientSnippet(String clientScript) => 'dummy-load-client-snippet';

  @override
  Future<String> moduleForServerPath(
          String entrypoint, String serverPath) async =>
      _module;

  @override
  Future<String> serverPathForModule(String entrypoint, String module) async =>
      _serverPath;

  @override
  Future<String> sourceMapPathForModule(
          String entrypoint, String module) async =>
      _sourceMapPath;

  @override
  String serverPathForAppUri(String appUri) => _serverPath;

  @override
  MetadataProvider metadataProviderFor(String entrypoint) => null;

  @override
  void trackEntrypoint(String entrypoint) {}

  @override
  Future<Map<String, ModuleInfo>> moduleInfoForEntrypoint(String entrypoint) =>
      throw UnimplementedError();
}

class MockModules implements Modules {
  @override
  void initialize(String entrypoint) {}

  @override
  Future<Uri> libraryForSource(String serverPath) {
    throw UnimplementedError();
  }

  @override
  Future<String> moduleForSource(String serverPath) async => _module;

  @override
  Future<Map<String, String>> modules() {
    throw UnimplementedError();
  }

  @override
  Future<String> moduleForlibrary(String libraryUri) {
    throw UnimplementedError();
  }
}
