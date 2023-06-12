// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:usage/usage_io.dart';

import 'file_system.dart';

/// Access the file '~/.flutter'.
class FlutterUsage {
  FlutterUsage({String settingsName = 'flutter'}) {
    _analytics = AnalyticsIO('', settingsName, '');
  }

  late Analytics _analytics;

  /// Does the .flutter store exist?
  static bool get doesStoreExist {
    return LocalFileSystem.flutterStoreExists();
  }

  bool get isFirstRun => _analytics.firstRun;

  bool get enabled => _analytics.enabled;

  set enabled(bool value) => _analytics.enabled = value;

  String get clientId => _analytics.clientId;
}

// Access the DevTools on disk store (~/.devtools/.devtools).
class DevToolsUsage {
  DevToolsUsage() {
    LocalFileSystem.maybeMoveLegacyDevToolsStore();

    properties = IOPersistentProperties(
      storeName,
      documentDirPath: LocalFileSystem.devToolsDir(),
    );
  }

  static const storeName = '.devtools';

  /// The activeSurvey is the property name of a top-level property
  /// existing or created in the file ~/.devtools
  /// If the property doesn't exist it is created with default survey values:
  ///
  ///   properties[activeSurvey]['surveyActionTaken'] = false;
  ///   properties[activeSurvey]['surveyShownCount'] = 0;
  ///
  /// It is a requirement that the API apiSetActiveSurvey must be called before
  /// calling any survey method on DevToolsUsage (addSurvey, rewriteActiveSurvey,
  /// surveyShownCount, incrementSurveyShownCount, or surveyActionTaken).
  String? _activeSurvey;

  late IOPersistentProperties properties;

  static const _surveyActionTaken = 'surveyActionTaken';
  static const _surveyShownCount = 'surveyShownCount';

  void reset() {
    // TODO(kenz): remove this in Feb 2022. See
    // https://github.com/flutter/devtools/issues/3264. The `firstRun` property
    // has been replaced by `isFirstRun`. This is to force all users to answer
    // the analytics dialog again. The 'enabled' property has been replaced by
    // 'analyticsEnabled' for better naming.
    properties.remove('firstRun');
    properties.remove('enabled');

    properties.remove('firstDevToolsRun');
    properties['analyticsEnabled'] = false;
  }

  bool get isFirstRun {
    // TODO(kenz): remove this in Feb 2022. See
    // https://github.com/flutter/devtools/issues/3264.The `firstRun` property
    // has been replaced by `isFirstRun`. This is to force all users to answer
    // the analytics dialog again.
    properties.remove('firstRun');

    properties['isFirstRun'] = properties['isFirstRun'] == null;
    return properties['isFirstRun'];
  }

  bool get analyticsEnabled {
    // TODO(kenz): remove this in Feb 2022. See
    // https://github.com/flutter/devtools/issues/3264. The `enabled` property
    // has been replaced by `analyticsEnabled` for better naming.
    if (properties['enabled'] != null) {
      properties['analyticsEnabled'] = properties['enabled'];
      properties.remove('enabled');
    }

    if (properties['analyticsEnabled'] == null) {
      properties['analyticsEnabled'] = false;
    }
    return properties['analyticsEnabled'];
  }

  set analyticsEnabled(bool value) {
    properties['analyticsEnabled'] = value;
    return properties['analyticsEnabled'];
  }

  bool surveyNameExists(String surveyName) => properties[surveyName] != null;

  void _addSurvey(String surveyName) {
    assert(activeSurvey != null);
    assert(activeSurvey == surveyName);
    rewriteActiveSurvey(false, 0);
  }

  String? get activeSurvey => _activeSurvey;

  set activeSurvey(String? surveyName) {
    assert(surveyName != null);
    _activeSurvey = surveyName;

    if (!surveyNameExists(activeSurvey!)) {
      // Create the survey if property is non-existent in ~/.devtools
      _addSurvey(activeSurvey!);
    }
  }

  /// Need to rewrite the entire survey structure for property to be persisted.
  void rewriteActiveSurvey(bool actionTaken, int shownCount) {
    assert(activeSurvey != null);
    properties[activeSurvey!] = {
      _surveyActionTaken: actionTaken,
      _surveyShownCount: shownCount,
    };
  }

  int get surveyShownCount {
    assert(activeSurvey != null);
    final prop = properties[activeSurvey!];
    if (prop[_surveyShownCount] == null) {
      rewriteActiveSurvey(prop[_surveyActionTaken], 0);
    }
    return properties[activeSurvey!][_surveyShownCount];
  }

  void incrementSurveyShownCount() {
    assert(activeSurvey != null);
    surveyShownCount; // Ensure surveyShownCount has been initialized.
    final prop = properties[activeSurvey!];
    rewriteActiveSurvey(prop[_surveyActionTaken], prop[_surveyShownCount] + 1);
  }

  bool get surveyActionTaken {
    assert(activeSurvey != null);
    return properties[activeSurvey!][_surveyActionTaken] == true;
  }

  set surveyActionTaken(bool value) {
    assert(activeSurvey != null);
    final prop = properties[activeSurvey!];
    rewriteActiveSurvey(value, prop[_surveyShownCount]);
  }

  String get lastReleaseNotesVersion {
    final version = properties['lastReleaseNotesVersion'] ??= '';
    return version;
  }

  set lastReleaseNotesVersion(String value) {
    properties['lastReleaseNotesVersion'] = value;
  }
}

abstract class PersistentProperties {
  PersistentProperties(this.name);

  final String name;

  dynamic operator [](String key);

  void operator []=(String key, dynamic value);

  /// Re-read settings from the backing store.
  ///
  /// May be a no-op on some platforms.
  void syncSettings();
}

const JsonEncoder _jsonEncoder = JsonEncoder.withIndent('  ');

class IOPersistentProperties extends PersistentProperties {
  IOPersistentProperties(
    String name, {
    String? documentDirPath,
  }) : super(name) {
    final String fileName = name.replaceAll(' ', '_');
    documentDirPath ??= LocalFileSystem.devToolsDir();
    _file = File(path.join(documentDirPath, fileName));
    if (!_file.existsSync()) {
      _file.createSync(recursive: true);
    }
    syncSettings();
  }

  IOPersistentProperties.fromFile(File file) : super(path.basename(file.path)) {
    _file = file;
    if (!_file.existsSync()) {
      _file.createSync(recursive: true);
    }
    syncSettings();
  }

  late File _file;

  late Map _map;

  @override
  dynamic operator [](String key) => _map[key];

  @override
  void operator []=(String key, dynamic value) {
    if (value == null && !_map.containsKey(key)) return;
    if (_map[key] == value) return;

    if (value == null) {
      _map.remove(key);
    } else {
      _map[key] = value;
    }

    try {
      _file.writeAsStringSync(_jsonEncoder.convert(_map) + '\n');
    } catch (_) {}
  }

  @override
  void syncSettings() {
    try {
      String contents = _file.readAsStringSync();
      if (contents.isEmpty) contents = '{}';
      _map = jsonDecode(contents);
    } catch (_) {
      _map = {};
    }
  }

  void remove(String propertyName) {
    _map.remove(propertyName);
  }
}
