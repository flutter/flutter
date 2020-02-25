// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/process.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../project.dart';

// Return null if line should be deleted.
typedef _ProjectFileLineProcessor = String Function(String line);

class IOSProjectMigration {
  IOSProjectMigration(IosProject project, Logger logger) :
        _xcodeProjectInfoFile = project.xcodeProjectInfoFile,
        _podfile = project.podfile,
        _logger = logger;

  final File _xcodeProjectInfoFile;
  final File _podfile;
  final Logger _logger;

  void run() {
    _migrateXcodeProjectInfoFile();
    _migratePodfile();
  }

  void _migrateXcodeProjectInfoFile() {
    if (!_xcodeProjectInfoFile.existsSync()) {
      _logger.printTrace('Xcode project not found, skipping migration');
      return;
    }

    _processFileLines(_xcodeProjectInfoFile, (String line) {
      // App.framework Frameworks reference.
      // isa = PBXFrameworksBuildPhase;
      // files = (
      //    3B80C3941E831B6300D905FE /* App.framework in Frameworks */,
      if (line.contains('3B80C3941E831B6300D905FE')) {
        return null;
      }

      // App.framework Embed Framework reference (build phase to embed framework).
      // 3B80C3951E831B6300D905FE /* App.framework in Embed Frameworks */,
      if (line.contains('3B80C3951E831B6300D905FE')
          || line.contains('741F496821356857001E2961')) { // Ephemeral add-to-app variant.
        return null;
      }

      // App.framework project file reference (seen in Xcode navigator pane).
      // isa = PBXGroup;
      // children = (
      //	 3B80C3931E831B6300D905FE /* App.framework */,
      if (line.contains('3B80C3931E831B6300D905FE')
          || line.contains('741F496521356807001E2961')) { // Ephemeral add-to-app variant.
        return null;
      }

      // Flutter.framework Frameworks reference.
      // isa = PBXFrameworksBuildPhase;
      // files = (
      //   9705A1C61CF904A100538489 /* Flutter.framework in Frameworks */,
      if (line.contains('9705A1C61CF904A100538489')) {
        return null;
      }

      // Flutter.framework Embed Framework reference (build phase to embed framework).
      // 9705A1C71CF904A300538489 /* Flutter.framework in Embed Frameworks */,
      if (line.contains('9705A1C71CF904A300538489')
          || line.contains('741F496221355F47001E2961')) { // Ephemeral add-to-app variant.
        return null;
      }

      // Flutter.framework project file reference (seen in Xcode navigator pane).
      // isa = PBXGroup;
      // children = (
      //	 9740EEBA1CF902C7004384FC /* Flutter.framework */,
      if (line.contains('9740EEBA1CF902C7004384FC')
          || line.contains('741F495E21355F27001E2961')) { // Ephemeral add-to-app variant.
        return null;
      }

      // Embed and thin frameworks in a script instead of using Xcode's link / embed build phases.
      const String thinBinaryScript = 'xcode_backend.sh\\" thin';
      if (line.contains(thinBinaryScript)) {
        return line.replaceFirst(thinBinaryScript, 'xcode_backend.sh\\" embed_and_thin');
      }

      return line;
    });
  }

  void _migratePodfile() {
    if (!_podfile.existsSync()) {
      _logger.printTrace('Podfile not found, skipping migration');
      return;
    }

    _processFileLines(_podfile, (String line) {
      // # Prevent Cocoapods from embedding a second Flutter framework and causing an error with the new Xcode build system.
      // install! 'cocoapods', :disable_input_output_paths => true
      if (line.contains('Prevent Cocoapods from embedding a second Flutter framework and causing an error with the new Xcode build system.')) {
        return null;
      }
      if (line.contains('install! \'cocoapods\', :disable_input_output_paths => true')) {
        return null;
      }

      return line;
    });
  }

  void _processFileLines(File file, _ProjectFileLineProcessor processLine) {
    final List<String> lines = file.readAsLinesSync();

    final StringBuffer newProjectContents = StringBuffer();
    final String basename = file.basename;

    bool migrationRequired = false;
    for (final String line in lines) {
      final String newProjectLine = processLine(line);
      if (newProjectLine == null) {
        _logger.printTrace('Migrating $basename, removing:\n    $line');
        migrationRequired = true;
        continue;
      }
      if (newProjectLine != line) {
        _logger.printTrace('Migrating $basename, replacing:\n    $line\nwith:    $newProjectLine');
        migrationRequired = true;
      }
      newProjectContents.writeln(newProjectLine);
    }

    if (migrationRequired) {
      file.writeAsStringSync(newProjectContents.toString());
    }
  }
}
