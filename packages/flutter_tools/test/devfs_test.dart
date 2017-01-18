// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';
import 'src/mocks.dart';

void main() {
  final String filePath = 'bar/foo.txt';
  final String filePath2 = 'foo/bar.txt';
  final Directory tempDir = _newTempDir();
  final String basePath = tempDir.path;
  MockDevFSOperations devFSOperations = new MockDevFSOperations();
  DevFS devFS;
  AssetBundle assetBundle = new AssetBundle();
  assetBundle.entries['a.txt'] = new DevFSStringContent('');
  group('devfs', () {
    tearDownAll(_cleanupTempDirs);

    testUsingContext('create dev file system', () async {
      // simulate workspace
      File file = fs.file(path.join(basePath, filePath));
      await file.parent.create(recursive: true);
      file.writeAsBytesSync(<int>[1, 2, 3]);

      // simulate package
      await _createPackage('somepkg', 'somefile.txt');

      devFS = new DevFS.operations(devFSOperations, 'test', tempDir);
      await devFS.create();
      devFSOperations.expectMessages(<String>['create test']);
      expect(devFS.assetPathsToEvict, isEmpty);

      await devFS.update();
      devFSOperations.expectMessages(<String>[
        'writeFile test .packages',
        'writeFile test bar/foo.txt',
        'writeFile test packages/somepkg/somefile.txt',
      ]);
      expect(devFS.assetPathsToEvict, isEmpty);
    });
    testUsingContext('add new file to local file system', () async {
      File file = fs.file(path.join(basePath, filePath2));
      await file.parent.create(recursive: true);
      file.writeAsBytesSync(<int>[1, 2, 3, 4, 5, 6, 7]);
      await devFS.update();
      devFSOperations.expectMessages(<String>[
        'writeFile test .packages',
        'writeFile test foo/bar.txt',
      ]);
      expect(devFS.assetPathsToEvict, isEmpty);
    });
    testUsingContext('modify existing file on local file system', () async {
      File file = fs.file(path.join(basePath, filePath));
      // Set the last modified time to 5 seconds in the past.
      updateFileModificationTime(file.path, new DateTime.now(), -5);
      await devFS.update();
      devFSOperations.expectMessages(<String>[
        'writeFile test .packages',
      ]);
      expect(devFS.assetPathsToEvict, isEmpty);
      await file.writeAsBytes(<int>[1, 2, 3, 4, 5, 6]);
      await devFS.update();
      devFSOperations.expectMessages(<String>[
        'writeFile test bar/foo.txt',
        'writeFile test .packages',
      ]);
      expect(devFS.assetPathsToEvict, isEmpty);
    });
    testUsingContext('delete a file from the local file system', () async {
      File file = fs.file(path.join(basePath, filePath));
      await file.delete();
      await devFS.update();
      devFSOperations.expectMessages(<String>[
        'writeFile test .packages',
        'deleteFile test bar/foo.txt',
      ]);
      expect(devFS.assetPathsToEvict, isEmpty);
    });
    testUsingContext('add new package', () async {
      await _createPackage('newpkg', 'anotherfile.txt');
      await devFS.update();
      devFSOperations.expectMessages(<String>[
        'writeFile test .packages',
        'writeFile test packages/newpkg/anotherfile.txt',
      ]);
      expect(devFS.assetPathsToEvict, isEmpty);
    });
    testUsingContext('add file in an asset bundle', () async {
      await devFS.update(bundle: assetBundle, bundleDirty: true);
      devFSOperations.expectMessages(<String>[
        'writeFile test .packages',
        'writeFile test ${getAssetBuildDirectory()}/a.txt',
      ]);
      expect(devFS.assetPathsToEvict, unorderedMatches(<String>['a.txt']));
      devFS.assetPathsToEvict.clear();
    });
    testUsingContext('add a file to the asset bundle - bundleDirty', () async {
      assetBundle.entries['b.txt'] = new DevFSStringContent('');
      await devFS.update(bundle: assetBundle, bundleDirty: true);
      // Expect entire asset bundle written because bundleDirty is true
      devFSOperations.expectMessages(<String>[
        'writeFile test .packages',
        'writeFile test ${getAssetBuildDirectory()}/a.txt',
        'writeFile test ${getAssetBuildDirectory()}/b.txt',
      ]);
      expect(devFS.assetPathsToEvict, unorderedMatches(<String>[
          'a.txt', 'b.txt']));
      devFS.assetPathsToEvict.clear();
    });
    testUsingContext('add a file to the asset bundle', () async {
      assetBundle.entries['c.txt'] = new DevFSStringContent('');
      await devFS.update(bundle: assetBundle);
      devFSOperations.expectMessages(<String>[
        'writeFile test .packages',
        'writeFile test ${getAssetBuildDirectory()}/c.txt',
      ]);
      expect(devFS.assetPathsToEvict, unorderedMatches(<String>[
          'c.txt']));
      devFS.assetPathsToEvict.clear();
    });
    testUsingContext('delete a file from the asset bundle', () async {
      assetBundle.entries.remove('c.txt');
      await devFS.update(bundle: assetBundle);
      devFSOperations.expectMessages(<String>[
        'writeFile test .packages',
        'deleteFile test ${getAssetBuildDirectory()}/c.txt',
      ]);
      expect(devFS.assetPathsToEvict, unorderedMatches(<String>['c.txt']));
      devFS.assetPathsToEvict.clear();
    });
    testUsingContext('delete all files from the asset bundle', () async {
      assetBundle.entries.clear();
      await devFS.update(bundle: assetBundle, bundleDirty: true);
      devFSOperations.expectMessages(<String>[
        'writeFile test .packages',
        'deleteFile test ${getAssetBuildDirectory()}/a.txt',
        'deleteFile test ${getAssetBuildDirectory()}/b.txt',
      ]);
      expect(devFS.assetPathsToEvict, unorderedMatches(<String>[
          'a.txt', 'b.txt'
          ]));
      devFS.assetPathsToEvict.clear();
    });
    testUsingContext('delete dev file system', () async {
      await devFS.destroy();
    });
  });
}

final List<Directory> _tempDirs = <Directory>[];
final Map <String, Directory> _packages = <String, Directory>{};

Directory _newTempDir() {
  Directory tempDir = fs.systemTempDirectory.createTempSync('devfs${_tempDirs.length}');
  _tempDirs.add(tempDir);
  return tempDir;
}

void _cleanupTempDirs() {
  while (_tempDirs.length > 0) {
    _tempDirs.removeLast().deleteSync(recursive: true);
  }
}

Future<Null> _createPackage(String pkgName, String pkgFileName) async {
  final Directory pkgTempDir = _newTempDir();
  File pkgFile = fs.file(path.join(pkgTempDir.path, pkgName, 'lib', pkgFileName));
  await pkgFile.parent.create(recursive: true);
  pkgFile.writeAsBytesSync(<int>[11, 12, 13]);
  _packages[pkgName] = pkgTempDir;
  StringBuffer sb = new StringBuffer();
  _packages.forEach((String pkgName, Directory pkgTempDir) {
    sb.writeln('$pkgName:${pkgTempDir.path}/$pkgName/lib');
  });
  fs.file(path.join(_tempDirs[0].path, '.packages')).writeAsStringSync(sb.toString());
}
