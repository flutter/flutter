// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Runs example code for README.md.
Future<List<Directory?>> readmeSnippets() async {
  // #docregion Example
  final Directory tempDir = await getTemporaryDirectory();

  final Directory appDocumentsDir = await getApplicationDocumentsDirectory();

  final Directory? downloadsDir = await getDownloadsDirectory();
  // #enddocregion Example

  return <Directory?>[tempDir, appDocumentsDir, downloadsDir];
}
