// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/local.dart' as local;
import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';

void main() {
  test(r'shared.bat does not contain $git typo', () {
    const FileSystem fs = local.LocalFileSystem();
    final String flutterRootPath = getFlutterRoot();
    final File sharedBat = fs
        .directory(flutterRootPath)
        .childDirectory('bin')
        .childDirectory('internal')
        .childFile('shared.bat');

    expect(sharedBat.existsSync(), true);

    final String content = sharedBat.readAsStringSync();

    // Verify that we don't have $git in the git rev-parse command.
    expect(content, isNot(contains(r'$git rev-parse')));
  });
}
