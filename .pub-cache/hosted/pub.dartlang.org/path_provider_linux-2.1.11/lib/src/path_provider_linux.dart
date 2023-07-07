// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:xdg_directories/xdg_directories.dart' as xdg;

import 'get_application_id.dart';

/// The linux implementation of [PathProviderPlatform]
///
/// This class implements the `package:path_provider` functionality for Linux.
class PathProviderLinux extends PathProviderPlatform {
  /// Constructs an instance of [PathProviderLinux]
  PathProviderLinux() : _environment = Platform.environment;

  /// Constructs an instance of [PathProviderLinux] with the given [environment]
  @visibleForTesting
  PathProviderLinux.private(
      {Map<String, String> environment = const <String, String>{},
      String? executableName,
      String? applicationId})
      : _environment = environment,
        _executableName = executableName,
        _applicationId = applicationId;

  final Map<String, String> _environment;
  String? _executableName;
  String? _applicationId;

  /// Registers this class as the default instance of [PathProviderPlatform]
  static void registerWith() {
    PathProviderPlatform.instance = PathProviderLinux();
  }

  @override
  Future<String?> getTemporaryPath() {
    final String environmentTmpDir = _environment['TMPDIR'] ?? '';
    return Future<String?>.value(
      environmentTmpDir.isEmpty ? '/tmp' : environmentTmpDir,
    );
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    final Directory directory =
        Directory(path.join(xdg.dataHome.path, await _getId()));
    if (directory.existsSync()) {
      return directory.path;
    }

    // This plugin originally used the executable name as a directory.
    // Use that if it exists for backwards compatibility.
    final Directory legacyDirectory =
        Directory(path.join(xdg.dataHome.path, await _getExecutableName()));
    if (legacyDirectory.existsSync()) {
      return legacyDirectory.path;
    }

    // Create the directory, because mobile implementations assume the directory exists.
    await directory.create(recursive: true);
    return directory.path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() {
    return Future<String?>.value(xdg.getUserDirectory('DOCUMENTS')?.path);
  }

  @override
  Future<String?> getDownloadsPath() {
    return Future<String?>.value(xdg.getUserDirectory('DOWNLOAD')?.path);
  }

  // Gets the name of this executable.
  Future<String> _getExecutableName() async {
    _executableName ??= path.basenameWithoutExtension(
        await File('/proc/self/exe').resolveSymbolicLinks());
    return _executableName!;
  }

  // Gets the unique ID for this application.
  Future<String> _getId() async {
    _applicationId ??= getApplicationId();
    // If no application ID then fall back to using the executable name.
    return _applicationId ?? await _getExecutableName();
  }
}
