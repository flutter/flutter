// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:path/path.dart' as path;

void createSampleProject(Directory directory, { bool brokenCode: false }) {
  File pubspecFile = fs.file(path.join(directory.path, 'pubspec.yaml'));
  pubspecFile.writeAsStringSync('''
name: foo_project
''');

  File optionsFile = fs.file(path.join(directory.path, '.analysis_options'));
  optionsFile.writeAsStringSync('''
include: package:flutter/analysis_options_user.yaml
''');

  // If brokenCode flag is true, then include
  // * language error - unknown method "prints"
  // * lint defined in flutter user analysis options - avoid empty else
  File dartFile = fs.file(path.join(directory.path, 'lib', 'main.dart'));
  dartFile.parent.createSync();
  dartFile.writeAsStringSync('''
void main() {
  print('hello world');
  ${brokenCode ? 'prints("hello world");' : ''}
  ${brokenCode ? 'if (0==0) print("equals"); else;' : ''}
}
''');
}
