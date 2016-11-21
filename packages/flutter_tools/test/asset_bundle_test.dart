// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import 'package:flutter_tools/src/asset.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main()  {
  // Create a temporary directory and write a single file into it.
  Directory tempDir = Directory.systemTemp.createTempSync();
  String projectRoot = tempDir.path;
  String assetPath = 'banana.txt';
  String assetContents = 'banana';
  File tempFile = new File(path.join(projectRoot, assetPath));
  tempFile.parent.createSync(recursive: true);
  tempFile.writeAsBytesSync(UTF8.encode(assetContents));

  // Fixed asset bundle tests.
  group('AssetBundle.fixed', () {
    test('empty strings', () async {
      expect(new AssetBundle.fixed(null, null), isNotNull);
      expect(new AssetBundle.fixed('', ''), isNotNull);
      expect(new AssetBundle.fixed(null, null).entries, isEmpty);
    });
    test('does not need a rebuild', () async {
      expect(new AssetBundle.fixed(null, null).needsBuild(), isFalse);
    });
    test('empty string', () async {
      AssetBundle ab = new AssetBundle.fixed('', '');
      expect(ab.entries, isEmpty);
    });
    test('single entry', () async {
      AssetBundle ab = new AssetBundle.fixed('', 'apple.txt');
      expect(ab.entries, isNotEmpty);
      expect(ab.entries.length, 1);
      AssetBundleEntry entry = ab.entries.first;
      expect(entry, isNotNull);
      expect(entry.archivePath, 'apple.txt');
    });
    test('two entries', () async {
      AssetBundle ab = new AssetBundle.fixed('', 'apple.txt,packages/flutter_gallery_assets/shrine/products/heels.png');
      expect(ab.entries, isNotEmpty);
      expect(ab.entries.length, 2);
      AssetBundleEntry firstEntry = ab.entries.first;
      expect(firstEntry, isNotNull);
      expect(firstEntry.archivePath, 'apple.txt');
      AssetBundleEntry lastEntry = ab.entries.last;
      expect(lastEntry, isNotNull);
      expect(lastEntry.archivePath, 'packages/flutter_gallery_assets/shrine/products/heels.png');
    });
    test('file contents', () async {
      AssetBundle ab = new AssetBundle.fixed(projectRoot, assetPath);
      expect(ab.entries, isNotEmpty);
      expect(ab.entries.length, 1);
      AssetBundleEntry entry = ab.entries.first;
      expect(entry, isNotNull);
      expect(entry.archivePath, assetPath);
      expect(assetContents, UTF8.decode(entry.contentsAsBytes()));
    });
  });
}
