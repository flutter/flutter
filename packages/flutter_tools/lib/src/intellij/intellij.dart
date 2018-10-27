// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:archive/archive.dart';

import '../base/file_system.dart';
import '../base/version.dart';
import '../doctor.dart';

class IntelliJPlugins {
  IntelliJPlugins(this.pluginsPath);

  final String pluginsPath;

  static final Version kMinFlutterPluginVersion = Version(16, 0, 0);

  void validatePackage(
      List<ValidationMessage> messages, List<String> packageNames, String title,
      {Version minVersion}) {
    for (String packageName in packageNames) {
      if (!_hasPackage(packageName)) {
        continue;
      }

      final String versionText = _readPackageVersion(packageName);
      final Version version = Version.parse(versionText);
      if (version != null && minVersion != null && version < minVersion) {
        messages.add(ValidationMessage.error(
            '$title plugin version $versionText - the recommended minimum version is $minVersion'));
      } else {
        messages.add(ValidationMessage(
            '$title plugin ${version != null ? "version $version" : "installed"}'));
      }

      return;
    }

    messages.add(ValidationMessage.error(
        '$title plugin not installed; this adds $title specific functionality.'));
  }

  bool _hasPackage(String packageName) {
    final String packagePath = fs.path.join(pluginsPath, packageName);
    if (packageName.endsWith('.jar'))
      return fs.isFileSync(packagePath);
    return fs.isDirectorySync(packagePath);
  }

  String _readPackageVersion(String packageName) {
    final String jarPath = packageName.endsWith('.jar')
        ? fs.path.join(pluginsPath, packageName)
        : fs.path.join(pluginsPath, packageName, 'lib', '$packageName.jar');
    // TODO(danrubel): look for a better way to extract a single 2K file from the zip
    // rather than reading the entire file into memory.
    try {
      final Archive archive =
          ZipDecoder().decodeBytes(fs.file(jarPath).readAsBytesSync());
      final ArchiveFile file = archive.findFile('META-INF/plugin.xml');
      final String content = utf8.decode(file.content);
      const String versionStartTag = '<version>';
      final int start = content.indexOf(versionStartTag);
      final int end = content.indexOf('</version>', start);
      return content.substring(start + versionStartTag.length, end);
    } catch (_) {
      return null;
    }
  }
}
