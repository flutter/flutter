// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';

import '../convert.dart';
import 'build_system.dart';

 /// Generates an .xcfilelist from a previous build for the input and output files.
void generateXcFileList(String targetName, Environment environment, String path) {
  final List<File> stamps = buildSystem.stampFilesFor(targetName, environment);
  final StringBuffer inputFileListBuffer = StringBuffer();
  final StringBuffer outputFileListBuffer = StringBuffer();
  // Cannot include plist in the xcfilelist.
  bool notIntermediate(String path) {
    return !path.contains('plist') &&
           !path.contains('.flutter-plugins') &&
           !path.contains(environment.buildDir.path);
  }
  for (File file in stamps) {
    if (!file.existsSync()) {
      continue;
    }
    final Map<String, Object> data = json.decode(file.readAsStringSync());
    (data['inputs'] as List<Object>)
      .cast<String>()
      .where(notIntermediate)
      .forEach(inputFileListBuffer.writeln);
    (data['outputs'] as List<Object>)
      .cast<String>()
      .where(notIntermediate)
      .forEach(outputFileListBuffer.writeln);
  }
  fs.file(fs.path.join(path, 'FlutterInputs.xcfilelist'))
    ..createSync(recursive: true)
    ..writeAsStringSync(inputFileListBuffer.toString());
  fs.file(fs.path.join(path, 'FlutterOutputs.xcfilelist'))
    ..createSync(recursive: true)
    ..writeAsStringSync(outputFileListBuffer.toString());
}
