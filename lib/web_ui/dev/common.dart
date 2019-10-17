// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

class BrowserInstallerException implements Exception {
  BrowserInstallerException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class PlatformBinding {
  static PlatformBinding get instance {
    if (_instance == null) {
      if (io.Platform.isLinux) {
        _instance = _LinuxBinding();
      } else if (io.Platform.isMacOS) {
        _instance = _MacBinding();
      } else {
        throw '${io.Platform.operatingSystem} is not supported';
      }
    }
    return _instance;
  }

  static PlatformBinding _instance;

  int getChromeBuild(YamlMap chromeLock);
  String getChromeDownloadUrl(String version);
  String getChromeExecutablePath(io.Directory versionDir);
}

const String _kBaseDownloadUrl =
    'https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o';

class _LinuxBinding implements PlatformBinding {
  @override
  int getChromeBuild(YamlMap browserLock) {
    final YamlMap chromeMap = browserLock['chrome'];
    return chromeMap['Linux'];
  }

  @override
  String getChromeDownloadUrl(String version) =>
      '$_kBaseDownloadUrl/Linux_x64%2F$version%2Fchrome-linux.zip?alt=media';

  @override
  String getChromeExecutablePath(io.Directory versionDir) =>
      path.join(versionDir.path, 'chrome-linux', 'chrome');
}

class _MacBinding implements PlatformBinding {
  @override
  int getChromeBuild(YamlMap browserLock) {
    final YamlMap chromeMap = browserLock['chrome'];
    return chromeMap['Mac'];
  }

  @override
  String getChromeDownloadUrl(String version) =>
      '$_kBaseDownloadUrl/Mac%2F$version%2Fchrome-mac.zip?alt=media';

  @override
  String getChromeExecutablePath(io.Directory versionDir) => path.join(
      versionDir.path,
      'chrome-mac',
      'Chromium.app',
      'Contents',
      'MacOS',
      'Chromium');
}
