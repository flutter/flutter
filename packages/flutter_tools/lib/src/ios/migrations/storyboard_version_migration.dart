// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/logger.dart';
import '../../base/project_migrator.dart';
import '../../xcode_project.dart';

// Update Main.storyboard tools versions to avoid Xcode UI hang.
class StoryboardVersionMigration extends ProjectMigrator {
  StoryboardVersionMigration(
    IosProject project,
    Logger logger,
  ) : _mainStoryboard = project.xcodeMainStoryboard,
      super(logger);

  final File _mainStoryboard;

  @override
  bool migrate() {
    if (_mainStoryboard.existsSync()) {
      processFileLines(_mainStoryboard);
    } else {
      logger.printTrace('Xcode project main storyboard not found, skipping version migration.');
    }

    return true;
  }

  @override
  String migrateLine(String line) {
    String updatedString = line;
    final List<String> originalDocumentHeaders = <String>[
      // https://github.com/flutter/flutter/commit/5f6e9cb39c
      '<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="9531"',
      // https://github.com/flutter/flutter/pull/4252
      '<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="8150"',
      // https://github.com/flutter/flutter/pull/4277
      '<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="10117"',
      // https://github.com/flutter/flutter/pull/4820
      '<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="6211"',
      // https://github.com/flutter/flutter/pull/11505
      '<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="12121"',
    ];

    if (originalDocumentHeaders.any(line.contains)) {
      const String mainReplacement = '<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="13122.16" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="BYZ-38-t0r">';
      updatedString = mainReplacement;

      logger.printStatus('Updating iOS Main.storyboard tools version.');
    }

    // Only update plugIn if the document version also needs to be updated to avoid downgrading version.
    const String originalPluginFragment = '<plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin"';
    if (migrationRequired && line.contains(originalPluginFragment)) {
      const String replacementPluginLine = '        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="13104.12"/>';
      updatedString = replacementPluginLine;
    }

    return updatedString;
  }
}
