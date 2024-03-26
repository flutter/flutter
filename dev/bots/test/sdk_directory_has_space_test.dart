// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

import 'common.dart';

void main() {
  test('We are in a directory with a space in it', () async {
    // This only matters in CI. Ignore this test when running tests locally.
    expect(path.split(Directory.current.absolute.path).reversed.take(2), <String>['bots', 'dev']);
    expect(path.split(Directory.current.absolute.path).reversed.take(3).skip(2).single, contains(' '));
  });
}
