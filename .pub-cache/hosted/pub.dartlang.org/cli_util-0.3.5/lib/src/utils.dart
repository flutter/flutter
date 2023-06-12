// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

bool isSdkDir(Directory dir) =>
    FileSystemEntity.isFileSync(path.join(dir.path, 'version'));
