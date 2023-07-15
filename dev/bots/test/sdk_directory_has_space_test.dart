// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import 'common.dart';

void main() {
  test('We are in a directory with a space in it', () async {
    // The Flutter SDK should be in a directory with a space in it, to make sure
    // our tools support that.
    final String? expectedName = Platform.environment['FLUTTER_SDK_PATH_WITH_SPACE'];
    expect(expectedName, 'flutter sdk');
    expect(expectedName, contains(' '));
    final List<String> parts = path.split(Directory.current.absolute.path);
    expect(parts.reversed.take(3), <String?>['bots', 'dev', expectedName]);
  }, skip: true); // https://github.com/flutter/flutter/issues/87285
}
