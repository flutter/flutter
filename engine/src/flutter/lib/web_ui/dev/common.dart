// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'environment.dart';

/// The port number for debugging.
const int kDevtoolsPort = 12345;
const int kMaxScreenshotWidth = 1024;
const int kMaxScreenshotHeight = 1024;
const double kMaxDiffRateFailure = 0.28 / 100; // 0.28%

abstract class PlatformBinding {
  static PlatformBinding get instance {
    if (_instance == null) {
      if (io.Platform.isLinux) {
        _instance = _LinuxBinding();
      } else if (io.Platform.isMacOS) {
        _instance = _MacBinding();
      } else if (io.Platform.isWindows) {
        _instance = _WindowsBinding();
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
  String getFirefoxDownloadFilename(String version);
  String getChromeExecutablePath(io.Directory versionDir);
  String getFirefoxExecutablePath(io.Directory versionDir);
  String getFirefoxLatestVersionUrl();
  String getMacApplicationLauncher();
  String getCommandToRunEdge();
}

const String _kBaseDownloadUrl =
    'https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o';

class _WindowsBinding implements PlatformBinding {
  @override
  int getChromeBuild(YamlMap browserLock) {
    final YamlMap chromeMap = browserLock['chrome'] as YamlMap;
    return chromeMap['Win'] as int;
  }

  @override
  String getChromeDownloadUrl(String version) =>
      'https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Win%2F${version}%2Fchrome-win32.zip?alt=media';

  @override
  String getChromeExecutablePath(io.Directory versionDir) =>
      path.join(versionDir.path, 'chrome-win32', 'chrome');

  @override
  String getFirefoxDownloadUrl(String version) =>
      'https://download-installer.cdn.mozilla.net/pub/firefox/releases/${version}/win64/en-US/'
      '${getFirefoxDownloadFilename(version)}';

  @override
  String getFirefoxDownloadFilename(String version) => 'firefox-${version}.exe';

  @override
  String getFirefoxExecutablePath(io.Directory versionDir) =>
      path.join(versionDir.path, 'firefox', 'firefox');

  @override
  String getFirefoxLatestVersionUrl() =>
      'https://download.mozilla.org/?product=firefox-latest&os=win&lang=en-US';

  @override
  String getMacApplicationLauncher() =>
      throw UnsupportedError('Safari is not supported on Windows');

  @override
  String getCommandToRunEdge() => 'MicrosoftEdgeLauncher';
}

class _LinuxBinding implements PlatformBinding {
  @override
  int getChromeBuild(YamlMap browserLock) {
    final YamlMap chromeMap = browserLock['chrome'] as YamlMap;
    return chromeMap['Linux'] as int;
  }

  @override
  String getChromeDownloadUrl(String version) =>
      '$_kBaseDownloadUrl/Linux_x64%2F$version%2Fchrome-linux.zip?alt=media';

  @override
  String getChromeExecutablePath(io.Directory versionDir) =>
      path.join(versionDir.path, 'chrome-linux', 'chrome');

  @override
  String getFirefoxDownloadUrl(String version) =>
      'https://download-installer.cdn.mozilla.net/pub/firefox/releases/${version}/linux-x86_64/en-US/'
      '${getFirefoxDownloadFilename(version)}';

  @override
  String getFirefoxDownloadFilename(String version) =>
      'firefox-${version}.tar.bz2';

  @override
  String getFirefoxExecutablePath(io.Directory versionDir) =>
      path.join(versionDir.path, 'firefox', 'firefox');

  @override
  String getFirefoxLatestVersionUrl() =>
      'https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US';

  @override
  String getMacApplicationLauncher() =>
      throw UnsupportedError('Safari is not supported on Linux');

  @override
  String getCommandToRunEdge() =>
      throw UnsupportedError('Edge is not supported on Linux');
}

class _MacBinding implements PlatformBinding {
  @override
  int getChromeBuild(YamlMap browserLock) {
    final YamlMap chromeMap = browserLock['chrome'] as YamlMap;
    return chromeMap['Mac'] as int;
  }

  @override
  String getChromeDownloadUrl(String version) =>
      '$_kBaseDownloadUrl/Mac%2F$version%2Fchrome-mac.zip?alt=media';

  String getChromeExecutablePath(io.Directory versionDir) => path.join(
      versionDir.path,
      'chrome-mac',
      'Chromium.app',
      'Contents',
      'MacOS',
      'Chromium');

  @override
  String getFirefoxDownloadUrl(String version) =>
      'https://download-installer.cdn.mozilla.net/pub/firefox/releases/${version}/mac/en-US/'
      '${getFirefoxDownloadFilename(version)}';

  @override
  String getFirefoxDownloadFilename(String version) => 'Firefox ${version}.dmg';

  @override
  String getFirefoxExecutablePath(io.Directory versionDir) =>
      path.join(versionDir.path, 'Firefox.app', 'Contents', 'MacOS', 'firefox');

  @override
  String getFirefoxLatestVersionUrl() =>
      'https://download.mozilla.org/?product=firefox-latest&os=osx&lang=en-US';

  @override
  String getMacApplicationLauncher() => 'open';

  @override
  String getCommandToRunEdge() =>
      throw UnimplementedError('Tests for Edge are not implemented for MacOS.');
}

class BrowserInstallation {
  const BrowserInstallation({
    @required this.version,
    @required this.executable,
  });

  /// Browser version.
  final String version;

  /// Path the browser executable.
  final String executable;
}

abstract class BrowserArgParser {
  const BrowserArgParser();

  /// Populate options specific to a browser to the [ArgParser].
  void populateOptions(ArgParser argParser);

  /// Populate browser with results of the arguments passed.
  void parseOptions(ArgResults argResults);

  String get version;
}

/// Provides access to the contents of the `browser_lock.yaml` file.
class BrowserLock {
  /// Initializes the [BrowserLock] singleton.
  static final BrowserLock _singletonInstance = BrowserLock._();

  /// The [Keyboard] singleton.
  static BrowserLock get instance => _singletonInstance;

  YamlMap _configuration = YamlMap();
  YamlMap get configuration => _configuration;

  BrowserLock._() {
    final io.File lockFile = io.File(
        path.join(environment.webUiRootDir.path, 'dev', 'browser_lock.yaml'));
    this._configuration = loadYaml(lockFile.readAsStringSync()) as YamlMap;
  }
}

/// A string sink that swallows all input.
class DevNull implements StringSink {
  @override
  void write(Object obj) {}

  @override
  void writeAll(Iterable objects, [String separator = ""]) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object obj = ""]) {}
}

/// Whether the felt command is running on Cirrus CI.
bool get isCirrus => io.Platform.environment['CIRRUS_CI'] == 'true';

/// Whether the felt command is running on LUCI.
bool get isLuci => io.Platform.environment['LUCI_CONTEXT'] != null;

/// Whether the felt command is running on one of the Continuous Integration
/// environements.
bool get isCi => isCirrus || isLuci;
