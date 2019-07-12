// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';

import '../convert.dart';
import 'build_system.dart';

/// Generates an .xcfilelist from a previous build for the input and output files.
void generateXcFileList(String targetName, Environment environment, String inputsPath, String outputsPath) {
  final List<File> stamps = buildSystem.stampFilesFor(targetName, environment);
  final StringBuffer inputFileListBuffer = StringBuffer();
  final StringBuffer outputFileListBuffer = StringBuffer();
  for (File file in stamps) {
    final Map<String, Object> data = json.decode(file.readAsStringSync());
    (data['inputs'] as List<Object>)
      .cast<String>()
      .where((String path) {
        // Cannot include plist in the xcfilelist.
        return !path.contains('plist') &&
               !path.contains('.flutter-plugins') &&
               !path.contains('build');
      })
      .forEach(inputFileListBuffer.writeln);
    (data['outputs'] as List<Object>)
      .cast<String>()
      .where((String path) {
         // Cannot include plist in the xcfilelist.
        return !path.contains('plist') &&
               !path.contains('.flutter-plugins') &&
               !path.contains('build');
      })
      .forEach(outputFileListBuffer.writeln);
  }
  fs.file(inputsPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(inputFileListBuffer.toString());
  fs.file(outputsPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(outputFileListBuffer.toString());
}