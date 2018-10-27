// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';

import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';

import 'src/common.dart';
import 'src/context.dart';
import 'src/pubspec_schema.dart';

void main() {
  String fixPath(String path) {
    // The in-memory file system is strict about slashes on Windows being the
    // correct way so until https://github.com/google/file.dart/issues/112 is
    // fixed we fix them here.
    // TODO(dantup): Remove this function once the above issue is fixed and
    // rolls into Flutter.
    return path?.replaceAll('/', fs.path.separator);
  }

  group('AssetBundle asset variants', () {
    FileSystem testFileSystem;
    setUp(() async {
      testFileSystem = MemoryFileSystem(
        style: platform.isWindows
          ? FileSystemStyle.windows
          : FileSystemStyle.posix,
      );
      testFileSystem.currentDirectory = testFileSystem.systemTempDirectory.createTempSync('flutter_asset_bundle_variant_test.');
    });

    testUsingContext('main asset and variants', () async {
      // Setting flutterRoot here so that it picks up the MemoryFileSystem's
      // path separator.
      Cache.flutterRoot = getFlutterRoot();
      writeEmptySchemaFile(fs);

      fs.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync(
'''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
  assets:
    - a/b/c/foo
'''
      );
      fs.file('.packages')..createSync();

      final List<String> assets = <String>[
        'a/b/c/foo',
        'a/b/c/var1/foo',
        'a/b/c/var2/foo',
        'a/b/c/var3/foo',
      ];
      for (String asset in assets) {
        fs.file(fixPath(asset))
          ..createSync(recursive: true)
          ..writeAsStringSync(asset);
      }

      AssetBundle bundle = AssetBundleFactory.instance.createBundle();
      await bundle.build(manifestPath: 'pubspec.yaml');

      // The main asset file, /a/b/c/foo, and its variants exist.
      for (String asset in assets) {
        expect(bundle.entries.containsKey(asset), true);
        expect(utf8.decode(await bundle.entries[asset].contentsAsBytes()), asset);
      }

      fs.file(fixPath('a/b/c/foo')).deleteSync();
      bundle = AssetBundleFactory.instance.createBundle();
      await bundle.build(manifestPath: 'pubspec.yaml');

      // Now the main asset file, /a/b/c/foo, does not exist. This is OK because
      // the /a/b/c/*/foo variants do exist.
      expect(bundle.entries.containsKey('a/b/c/foo'), false);
      for (String asset in assets.skip(1)) {
        expect(bundle.entries.containsKey(asset), true);
        expect(utf8.decode(await bundle.entries[asset].contentsAsBytes()), asset);
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => testFileSystem,
    });
  });
}
