// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:xml/xml.dart' show XmlException;
import 'package:xml/xml_events.dart';

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../base/version.dart';
import '../../build_info.dart';
import '../../macos/xcode.dart';

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
  });

  final File _infoPlist;
  final Xcode _xcode;
  final EnvironmentType _environmentType;

  @override
  Future<void> migrate() async {
    if (!_infoPlist.existsSync()) {
      logger.printTrace('Info.plist not found, skipping status bar appearance migration.');
      return;
    }

    final String contents;
    try {
      contents = _infoPlist.readAsStringSync();
    } on FileSystemException catch (error) {
      logger.printTrace(
        'Unable to read Info.plist, skipping status bar appearance migration: $error',
      );
      return;
    }
    final (int, int)? legacyValue = _legacyValueRange(contents);
    if (legacyValue == null) {
      return;
    }

    // The linked SDK determines whether UIKit supports application-based status
    // bar appearance. Do not change projects that still build with older SDKs.
    // See https://github.com/flutter/flutter/issues/192842.
    final Version? sdkVersion = await _xcode.sdkPlatformVersion(_environmentType);
    if (sdkVersion == null || sdkVersion < Version(27, 0, 0)) {
      return;
    }

    final (int start, int end) = legacyValue;
    _infoPlist.writeAsStringSync(contents.replaceRange(start, end, '<true/>'));
    logger.printStatus(
      'Updating ${_infoPlist.path} to use view controller-based status bar appearance '
      'for the iOS 27 SDK or later.',
    );
  }

  (int, int)? _legacyValueRange(String contents) {
    final List<XmlEvent> events;
    try {
      events = parseEvents(
        contents,
        validateNesting: true,
        validateDocument: true,
        withLocation: true,
        withParent: true,
      ).toList();
    } on XmlException {
      logger.printTrace('Unable to parse Info.plist, skipping status bar appearance migration.');
      return null;
    }

    // Use source locations to preserve formatting and comments, and only
    // consider keys in the root dictionary, not nested or commented-out keys.
    final List<XmlStartElementEvent> entries = events
        .whereType<XmlStartElementEvent>()
        .where(
          (event) =>
              event.parent?.name == 'dict' &&
              event.parent?.parent?.name == 'plist' &&
              event.parent?.parent?.parent == null,
        )
        .toList();
    final values = <XmlStartElementEvent>[];
    for (var index = 0; index + 1 < entries.length; index += 1) {
      final XmlStartElementEvent entry = entries[index];
      if (entry.name != 'key') {
        continue;
      }
      final String key = events
          .whereType<XmlTextEvent>()
          .where((event) => identical(event.parent, entry))
          .map((event) => event.text)
          .join();
      if (key == _viewControllerBasedStatusBarAppearance) {
        values.add(entries[index + 1]);
      }
    }
    // Duplicate keys are ambiguous; leave them for the developer to resolve.
    if (values.length != 1 || values.single.name != 'false') {
      return null;
    }
    final XmlStartElementEvent value = values.single;
    final int end = value.isSelfClosing
        ? value.stop!
        : events
              .whereType<XmlEndElementEvent>()
              .singleWhere((event) => identical(event.parent, value))
              .stop!;
    return (value.start!, end);
  }
}
