// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_tools/src/isolated/native_assets/native_assets_manifest.dart';

import '../../src/common.dart';

void main() {
  // The paths in the manifest are paths on the target device, which is not
  // necessarily the host the tool runs on. They must not be reinterpreted with
  // the host's path semantics, e.g. `@rpath/Foo.framework/Foo` must not become
  // `@rpath\Foo.framework\Foo` when the tool runs on Windows.
  test('paths are not rewritten with host path semantics', () {
    const manifestJson = '''
{
  "format-version": [1, 0, 0],
  "native-assets": {
    "ios_arm64": {
      "package:project/asset1": ["absolute", "@rpath/Foo.framework/Foo"],
      "package:project/asset2": ["system", "/usr/lib/libsqlite3.dylib"],
      "package:project/asset3": ["process"],
      "package:project/asset4": ["executable"]
    }
  }
}
''';

    final manifest = NativeAssetsManifest.fromJson(
      json.decode(manifestJson) as Map<String, Object?>,
    );

    expect(manifest.assets['ios_arm64'], <String, NativeAssetPath>{
      'package:project/asset1': const NativeAssetAbsolutePath('@rpath/Foo.framework/Foo'),
      'package:project/asset2': const NativeAssetSystemPath('/usr/lib/libsqlite3.dylib'),
      'package:project/asset3': const NativeAssetInProcess(),
      'package:project/asset4': const NativeAssetInExecutable(),
    });

    // Serializing the parsed manifest reproduces the original paths.
    expect(
      manifest.toJson(),
      json.decode(manifestJson),
      reason: 'Parsing and serializing should round-trip on all host platforms.',
    );
  });

  test('throws on unknown path type', () {
    expect(
      () => NativeAssetPath.fromJson(const <Object?>['unknown', 'foo']),
      throwsA(isA<FormatException>()),
    );
  });

  test('throws on malformed targetAssets or pathInfo in manifest JSON', () {
    expect(
      () => NativeAssetsManifest.fromJson(const <String, Object?>{
        'native-assets': <String, Object?>{'ios_arm64': 'not-a-map'},
      }),
      throwsA(isA<FormatException>()),
    );

    expect(
      () => NativeAssetsManifest.fromJson(const <String, Object?>{
        'native-assets': <String, Object?>{
          'ios_arm64': <String, Object?>{'package:project/asset1': 'not-a-list'},
        },
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
