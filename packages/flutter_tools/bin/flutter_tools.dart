// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools/executable.dart' as executable;

void main(List<String> args) {
  if (args.isNotEmpty && args[0] == 'run') {
    Directory.current = r'C:\Code\f\flutter\dev\integration_tests\ui\';
    args = const <String>['run', '-d', 'windows', r'lib\empty.dart'];
  }

  executable.main(args);
}
