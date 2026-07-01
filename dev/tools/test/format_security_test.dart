// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  final String repoRoot = path.normalize(Directory.current.path);
  final String scriptPath = path.join(repoRoot, 'dev', 'tools', 'format.sh');

  test('format.sh uses quoted tool invocation', () {
    final String content = File(scriptPath).readAsStringSync();
    expect(content, contains('"\$DART"'));
    expect(content, contains('"\$@"'));
  });

}