// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  String filePath = 'bar/foo.txt';
  String filePath2 = 'foo/bar.txt';
  Directory tempDir;
  String basePath;
  MockDevFSOperations devFSOperations = new MockDevFSOperations();
  DevFS devFS;
  AssetBundle assetBundle = new AssetBundle();
  assetBundle.entries['a.txt'] = new DevFSStringContent('');
  group('devfs', () {
    testUsingContext('create local file system', () async {
      tempDir = fs.systemTempDirectory.createTempSync();
      basePath = tempDir.path;
      File file = fs.file(path.join(basePath, filePath));
      await file.parent.create(recursive: true);
      file.writeAsBytesSync(<int>[1, 2, 3]);
    });
    testUsingContext('create dev file system', () async {
      devFS = new DevFS.operations(devFSOperations, 'test', tempDir);
      await devFS.create();
      devFSOperations.expectMessages(<String>['create test']);
      expect(devFS.assetPathsToEvict, isEmpty);
    });
    testUsingContext('populate dev file system', () async {
      await devFS.update();
      devFSOperations.expectMessages(<String>['writeFile test bar/foo.txt']);
      expect(devFS.assetPathsToEvict, isEmpty);
    });
    testUsingContext('add new file to local file system', () async {
      File file = fs.file(path.join(basePath, filePath2));
      await file.parent.create(recursive: true);
      file.writeAsBytesSync(<int>[1, 2, 3, 4, 5, 6, 7]);
      await devFS.update();
      devFSOperations.expectMessages(<String>['writeFile test foo/bar.txt']);
      expect(devFS.assetPathsToEvict, isEmpty);
    });
    testUsingContext('modify existing file on local file system', () async {
      File file = fs.file(path.join(basePath, filePath));
      // Set the last modified time to 5 seconds in the past.
      updateFileModificationTime(file.path, new DateTime.now(), -5);
      await devFS.update();
      await file.writeAsBytes(<int>[1, 2, 3, 4, 5, 6]);
      await devFS.update();
      devFSOperations.expectMessages(<String>['writeFile test bar/foo.txt']);
      expect(devFS.assetPathsToEvict, isEmpty);
    });
    testUsingContext('delete a file from the local file system', () async {
      File file = fs.file(path.join(basePath, filePath));
      await file.delete();
      await devFS.update();
      devFSOperations.expectMessages(<String>['deleteFile test bar/foo.txt']);
      expect(devFS.assetPathsToEvict, isEmpty);
    });
    testUsingContext('add file in an asset bundle', () async {
      await devFS.update(bundle: assetBundle, bundleDirty: true);
      devFSOperations.expectMessages(<String>[
          'writeFile test ${getAssetBuildDirectory()}/a.txt']);
      expect(devFS.assetPathsToEvict, unorderedMatches(<String>['a.txt']));
      devFS.assetPathsToEvict.clear();
    });
    testUsingContext('add a file to the asset bundle - bundleDirty', () async {
      assetBundle.entries['b.txt'] = new DevFSStringContent('');
      await devFS.update(bundle: assetBundle, bundleDirty: true);
      // Expect entire asset bundle written because bundleDirty is true
      devFSOperations.expectMessages(<String>[
          'writeFile test ${getAssetBuildDirectory()}/a.txt',
          'writeFile test ${getAssetBuildDirectory()}/b.txt']);
      expect(devFS.assetPathsToEvict, unorderedMatches(<String>[
          'a.txt', 'b.txt']));
      devFS.assetPathsToEvict.clear();
    });
    testUsingContext('add a file to the asset bundle', () async {
      assetBundle.entries['c.txt'] = new DevFSStringContent('');
      await devFS.update(bundle: assetBundle);
      devFSOperations.expectMessages(<String>[
          'writeFile test ${getAssetBuildDirectory()}/c.txt']);
      expect(devFS.assetPathsToEvict, unorderedMatches(<String>[
          'c.txt']));
      devFS.assetPathsToEvict.clear();
    });
    testUsingContext('delete a file from the asset bundle', () async {
      assetBundle.entries.remove('c.txt');
      await devFS.update(bundle: assetBundle);
      devFSOperations.expectMessages(<String>[
          'deleteFile test ${getAssetBuildDirectory()}/c.txt']);
      expect(devFS.assetPathsToEvict, unorderedMatches(<String>['c.txt']));
      devFS.assetPathsToEvict.clear();
    });
    testUsingContext('delete all files from the asset bundle', () async {
      assetBundle.entries.clear();
      await devFS.update(bundle: assetBundle, bundleDirty: true);
      devFSOperations.expectMessages(<String>[
          'deleteFile test ${getAssetBuildDirectory()}/a.txt',
          'deleteFile test ${getAssetBuildDirectory()}/b.txt']);
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
