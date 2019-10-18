// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:meta/meta.dart';
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
  String getFirefoxDownloadUrl(String version);
  String getChromeExecutablePath(io.Directory versionDir);
  String getFirefoxExecutablePath(io.Directory versionDir);
  String getFirefoxLatestVersionUrl();
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

  @override
  String getFirefoxDownloadUrl(String version) {
    return 'https://download-installer.cdn.mozilla.net/pub/firefox/releases/${version}/linux-x86_64/en-US/firefox-${version}.tar.bz2';
  }

  @override
  String getFirefoxExecutablePath(io.Directory versionDir) {
    // TODO: implement getFirefoxExecutablePath
    return null;
  }

  @override
  String getFirefoxLatestVersionUrl() {
    return 'https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US';
  }
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

  @override
  String getFirefoxDownloadUrl(String version) {
    // TODO: implement getFirefoxDownloadUrl
    return null;
  }

  @override
  String getFirefoxExecutablePath(io.Directory versionDir) {
    // TODO: implement getFirefoxExecutablePath
    return null;
  }

  @override
  String getFirefoxLatestVersionUrl() {
    return 'https://download.mozilla.org/?product=firefox-latest&os=osx&lang=en-US';
  }
}

class BrowserInstallation {
  const BrowserInstallation({
    @required this.version,
    @required this.executable,
  });

  /// Browser version.
  final String version;

  /// Path the the browser executable.
  final String executable;
}
