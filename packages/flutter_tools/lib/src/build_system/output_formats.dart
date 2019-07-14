// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';

import '../convert.dart';
import 'build_system.dart';

 /// Generates an .xcfilelist from a previous build for the input and output files.
void generateXcFileList(String targetName, Environment environment, String path) {
  final List<File> stamps = buildSystem.stampFilesFor(targetName, environment);
  final Set<String> inputFiles = <String>{};
  final Set<String> outputFiles = <String>{};
  for (File file in stamps) {
    if (!file.existsSync()) {
      continue;
    }
    final Map<String, Object> data = json.decode(file.readAsStringSync());
    (data['inputs'] as List<Object>)
      .cast<String>()
      .where((String path) {
        // Cannot include plist, plugins, or intermediates in the input xcfilelist.
        return !path.contains('plist') &&
               !path.contains(fs.path.split(environment.buildDir.path).last) &&
               !path.contains('flutter-plugins') &&
               !path.contains('project.pbxproj') &&
               !path.contains('xcconfig');
      })
      .forEach(inputFiles.add);
    (data['outputs'] as List<Object>)
      .cast<String>()
      .where((String value) {
        return !value.contains('flutter-plugins') &&
               !value.contains('ephemeral');
      })
      .forEach(outputFiles.add);
  }
  // XCode is dumb and will assume that if the file was edited that the inputs
  // changed.
  final String inputSource = inputFiles.join('\n');
  final String outputSource = outputFiles.join('\n');
  final File inputFile = fs.file(fs.path.join(path, 'FlutterInputs.xcfilelist'));
  final File outputFile = fs.file(fs.path.join(path, 'FlutterOutputs.xcfilelist'));
  if (!inputFile.existsSync() || inputFile.readAsStringSync() != inputSource) {
    fs.file(inputFile)
      ..createSync(recursive: true)
      ..writeAsStringSync(inputSource);
  }
  if (!outputFile.existsSync() || outputFile.readAsStringSync() != outputSource) {
    fs.file(outputFile)
      ..createSync(recursive: true)
      ..writeAsStringSync(outputSource);
  }
}
