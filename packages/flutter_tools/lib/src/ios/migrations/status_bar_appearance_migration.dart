// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../base/version.dart';
import '../../build_info.dart';
import '../../macos/xcode.dart';
import '../plist_parser.dart';

const _viewControllerBasedStatusBarAppearance = 'UIViewControllerBasedStatusBarAppearance';

/// Migrates legacy application-based status bar appearance for the iOS 27 SDK.
///
/// This updates the source Info.plist selected by the build configuration.
/// Builds started directly from Xcode require updating the plist manually.
class StatusBarAppearanceMigration extends ProjectMigrator {
  StatusBarAppearanceMigration(
    this._infoPlist,
    super.logger, {
    required this._xcode,
    required this._environmentType,
    required this._plistParser,
  });

  final File _infoPlist;
  final Xcode _xcode;
  final EnvironmentType _environmentType;
  final PlistParser _plistParser;

  @override
  Future<void> migrate() async {
    if (!_infoPlist.existsSync()) {
      logger.printTrace('Info.plist not found, skipping status bar appearance migration.');
      return;
    }

    if (_plistParser.getValueFromFile<Object>(
          _infoPlist.path,
          _viewControllerBasedStatusBarAppearance,
        ) !=
        false) {
      return;
    }

    // The linked SDK determines whether UIKit supports application-based status
    // bar appearance. Do not change projects that still build with older SDKs.
    // See https://github.com/flutter/flutter/issues/192842.
    final Version? sdkVersion = await _xcode.sdkPlatformVersion(_environmentType);
    if (sdkVersion == null || sdkVersion < Version(27, 0, 0)) {
      return;
    }

    if (!_plistParser.replaceKeyWithBoolean(
      _infoPlist.path,
      key: _viewControllerBasedStatusBarAppearance,
      value: true,
    )) {
      logger.printTrace('Unable to update Info.plist, skipping status bar appearance migration.');
      return;
    }
    logger.printStatus(
      'Updating ${_infoPlist.path} to use view controller-based status bar appearance '
      'for the iOS 27 SDK or later.',
    );
  }
}
