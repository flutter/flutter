// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools/src/asset.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

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
  assetBundle.entries.add(new AssetBundleEntry.fromString('a.txt', ''));
  group('devfs', () {
    testUsingContext('create local file system', () async {
      tempDir = Directory.systemTemp.createTempSync();
      basePath = tempDir.path;
      File file = new File(path.join(basePath, filePath));
      await file.parent.create(recursive: true);
      file.writeAsBytesSync(<int>[1, 2, 3]);
    });
    testUsingContext('create dev file system', () async {
      devFS = new DevFS.operations(devFSOperations, 'test', tempDir);
      await devFS.create();
      expect(devFSOperations.contains('create test'), isTrue);
    });
    testUsingContext('populate dev file system', () async {
      await devFS.update();
      expect(devFSOperations.contains('writeFile test bar/foo.txt'), isTrue);
    });
    testUsingContext('modify existing file on local file system', () async {
      File file = new File(path.join(basePath, filePath));
      file.writeAsBytesSync(<int>[1, 2, 3, 4, 5, 6]);
      await devFS.update();
      expect(devFSOperations.contains('writeFile test bar/foo.txt'), isTrue);
    });
    testUsingContext('add new file to local file system', () async {
      File file = new File(path.join(basePath, filePath2));
      await file.parent.create(recursive: true);
      file.writeAsBytesSync(<int>[1, 2, 3, 4, 5, 6, 7]);
      await devFS.update();
      expect(devFSOperations.contains('writeFile test foo/bar.txt'), isTrue);
    });
    testUsingContext('delete a file from the local file system', () async {
      File file = new File(path.join(basePath, filePath));
      await file.delete();
      await devFS.update();
      expect(devFSOperations.contains('deleteFile test bar/foo.txt'), isTrue);
    });
    testUsingContext('add file in an asset bundle', () async {
      await devFS.update(bundle: assetBundle);
      expect(devFSOperations.contains('writeFile test build/flx/a.txt'), isTrue);
    });
    testUsingContext('add a file to the asset bundle', () async {
      assetBundle.entries.add(new AssetBundleEntry.fromString('b.txt', ''));
      await devFS.update(bundle: assetBundle);
      expect(devFSOperations.contains('writeFile test build/flx/b.txt'), isTrue);
    });
    testUsingContext('delete a file from the asset bundle', () async {
      assetBundle.entries.clear();
      await devFS.update(bundle: assetBundle);
      expect(devFSOperations.contains('deleteFile test build/flx/b.txt'), isTrue);
    });
    testUsingContext('delete dev file system', () async {
      await devFS.destroy();
    });
  });
}
