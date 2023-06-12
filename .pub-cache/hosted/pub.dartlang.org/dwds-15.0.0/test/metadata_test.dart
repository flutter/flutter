// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:dwds/dwds.dart';
import 'package:dwds/src/debugging/metadata/module_metadata.dart';
import 'package:test/test.dart';

const _emptySourceMetadata =
    '{"version":"1.0.0","name":"web/main","closureName":"load__web__main",'
    '"sourceMapUri":"foo/web/main.ddc.js.map",'
    '"moduleUri":"foo/web/main.ddc.js",'
    '"soundNullSafety":true,'
    '"libraries":[{"name":"main",'
    '"importUri":"org-dartlang-app:///web/main.dart",'
    '"fileUri":"org-dartlang-app:///web/main.dart","partUris":[]}]}\n'
    '// intentionally empty: package blah has no dart sources';

const _noNullSafetyMetadata =
    '{"version":"1.0.0","name":"web/main","closureName":"load__web__main",'
    '"sourceMapUri":"foo/web/main.ddc.js.map",'
    '"moduleUri":"foo/web/main.ddc.js",'
    '"libraries":[{"name":"main",'
    '"importUri":"org-dartlang-app:///web/main.dart",'
    '"fileUri":"org-dartlang-app:///web/main.dart","partUris":[]}]}\n'
    '// intentionally empty: package blah has no dart sources';

const _fileUriMetadata =
    '{"version":"1.0.0","name":"web/main","closureName":"load__web__main",'
    '"sourceMapUri":"foo/web/main.ddc.js.map",'
    '"moduleUri":"foo/web/main.ddc.js",'
    '"soundNullSafety":true,'
    '"libraries":[{"name":"main",'
    '"importUri":"file:/Users/foo/blah/sample/lib/bar.dart",'
    '"fileUri":"org-dartlang-app:///web/main.dart","partUris":[]}]}\n'
    '// intentionally empty: package blah has no dart sources';

class FakeAssetReader implements AssetReader {
  final String _metadata;
  FakeAssetReader(this._metadata);
  @override
  Future<String> dartSourceContents(String serverPath) =>
      throw UnimplementedError();

  @override
  Future<String> metadataContents(String serverPath) async => _metadata;

  @override
  Future<String> sourceMapContents(String serverPath) =>
      throw UnimplementedError();

  @override
  Future<void> close() async {}
}

void main() {
  test('can parse metadata with empty sources', () async {
    final provider = MetadataProvider(
      'foo.bootstrap.js',
      FakeAssetReader(_emptySourceMetadata),
    );
    expect(await provider.libraries,
        contains('org-dartlang-app:///web/main.dart'));
    expect(await provider.soundNullSafety, isNotNull);
  });

  test('can parse metadata with no null safety information', () async {
    final provider = MetadataProvider(
      'foo.bootstrap.js',
      FakeAssetReader(_noNullSafetyMetadata),
    );
    expect(await provider.libraries,
        contains('org-dartlang-app:///web/main.dart'));
    expect(await provider.soundNullSafety, false);
  });

  test('throws on metadata with absolute import uris', () async {
    final provider = MetadataProvider(
      'foo.bootstrap.js',
      FakeAssetReader(_fileUriMetadata),
    );
    await expectLater(provider.libraries,
        throwsA(const TypeMatcher<AbsoluteImportUriException>()));
  });

  test('creates metadata from json', () async {
    const json = {
      'version': '1.0.0',
      'name': 'web/main',
      'closureName': 'load__web__main',
      'sourceMapUri': 'foo/web/main.ddc.js.map',
      'moduleUri': 'foo/web/main.ddc.js',
      'libraries': [
        {
          'name': 'main',
          'importUri': 'org-dartlang-app:///web/main.dart',
          'partUris': ['org-dartlang-app:///web/main.dart']
        }
      ]
    };

    final metadata = ModuleMetadata.fromJson(json);
    expect(metadata.version, '1.0.0');
    expect(metadata.name, 'web/main');
    expect(metadata.closureName, 'load__web__main');
    expect(metadata.sourceMapUri, 'foo/web/main.ddc.js.map');
    expect(metadata.moduleUri, 'foo/web/main.ddc.js');
    final libraries = metadata.libraries;
    expect(libraries.length, 1);
    for (var lib in libraries.values) {
      expect(lib.name, 'main');
      expect(lib.importUri, 'org-dartlang-app:///web/main.dart');
      final parts = lib.partUris;
      expect(parts.length, 1);
      expect(parts[0], 'org-dartlang-app:///web/main.dart');
    }
    expect(metadata.soundNullSafety, false);
  });
}
