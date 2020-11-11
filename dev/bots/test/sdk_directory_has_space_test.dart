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
    const String expectedName = 'flutter sdk';
    final List<String> parts = path.split(Directory.current.absolute.path);
    expect(
      parts,
      contains(expectedName),
      reason: 'CI tests should run in a directory with a space',
    );
  });
}
