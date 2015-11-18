// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

/// Create the ancestor directories of a file path if they do not already exist.
void ensureDirectoryExists(String filePath) {
  String dirPath = path.dirname(filePath);
  if (FileSystemEntity.isDirectorySync(dirPath))
    return;
  new Directory(dirPath).createSync(recursive: true);
}
