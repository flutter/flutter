// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:io' as io;

import 'package:path/path.dart' as pathlib;
import 'package:web_driver_installer/chrome_driver_installer.dart';
import 'package:web_driver_installer/firefox_driver_installer.dart';
import 'package:web_driver_installer/safari_driver_runner.dart';
import 'package:yaml/yaml.dart';

import 'chrome_installer.dart';
import 'common.dart';
import 'environment.dart';
import 'utils.dart';

/// [DriverManager] implementation for Chrome.
///
/// This manager can be used for both macOS and Linux.
class ChromeDriverManager extends DriverManager {
  /// Directory which contains the Chrome's major version.
  ///
  /// On LUCI we are using the CIPD packages to control Chrome binaries we use.
  /// There will be multiple CIPD packages loaded at the same time. Yaml file
  /// `driver_version.yaml` contains the version number we want to use.
  ///
  /// Initialized to the current first to avoid the `Non-nullable` error.
  // TODO: https://github.com/flutter/flutter/issues/53179. Local integration
  // tests are still using the system Chrome.
  io.Directory _browserDriverDirWithVersion;

  ChromeDriverManager(String browser) : super(browser) {
    final io.File lockFile = io.File(pathlib.join(
        environment.webUiRootDir.path, 'dev', 'browser_lock.yaml'));
    final YamlMap _configuration =
        loadYaml(lockFile.readAsStringSync()) as YamlMap;
    final String requiredChromeDriverVersion =
        _configuration['required_driver_version']['chrome'] as String;
    print('INFO: Major version for Chrome Driver $requiredChromeDriverVersion');
    _browserDriverDirWithVersion = io.Directory(pathlib.join(
        environment.webUiDartToolDir.path,
        'drivers',
        browser,
        requiredChromeDriverVersion,
        '${browser}driver-${io.Platform.operatingSystem.toString()}'));
  }

  @override
  Future<void> _installDriver() async {
    if (_browserDriverDirWithVersion.existsSync()) {
      _browserDriverDirWithVersion.deleteSync(recursive: true);
    }

    _browserDriverDirWithVersion.createSync(recursive: true);
    temporaryDirectories.add(_drivers);

    final io.Directory temp = io.Directory.current;
    io.Directory.current = _browserDriverDirWithVersion;

    try {
      // TODO(nurhan): https://github.com/flutter/flutter/issues/53179
      final String chromeDriverVersion = await queryChromeDriverVersion();
      ChromeDriverInstaller chromeDriverInstaller =
          ChromeDriverInstaller.withVersion(chromeDriverVersion);
      await chromeDriverInstaller.install(alwaysInstall: true);
    } finally {
      io.Directory.current = temp;
    }
  }

  /// Throw an error if driver directory does not exists.
  ///
  /// Driver should already exist on LUCI as a CIPD package.
  @override
  Future<void> _verifyDriverForLUCI() {
    if (!_browserDriverDirWithVersion.existsSync()) {
      throw StateError('Failed to locate Chrome driver on LUCI on path:'
          '${_browserDriverDirWithVersion.path}');
    }
    return Future<void>.value();
  }

  @override
  Future<void> _startDriver() async {
    await startProcess('./chromedriver/chromedriver', ['--port=4444'],
        workingDirectory: _browserDriverDirWithVersion.path);
    print('INFO: Driver started');
  }
}

/// [DriverManager] implementation for Firefox.
///
/// This manager can be used for both macOS and Linux.
class FirefoxDriverManager extends DriverManager {
  FirefoxDriverManager(String browser) : super(browser);

  FirefoxDriverInstaller firefoxDriverInstaller =
      FirefoxDriverInstaller(geckoDriverVersion: getLockedGeckoDriverVersion());

  @override
  Future<void> _installDriver() async {
    if (_browserDriverDir.existsSync()) {
      _browserDriverDir.deleteSync(recursive: true);
    }

    _browserDriverDir.createSync(recursive: true);
    temporaryDirectories.add(_drivers);

    final io.Directory temp = io.Directory.current;
    io.Directory.current = _browserDriverDir;

    try {
      await firefoxDriverInstaller.install(alwaysInstall: false);
    } finally {
      io.Directory.current = temp;
    }
  }

  /// Throw an error if driver directory does not exist.
  ///
  /// Driver should already exist on LUCI as a CIPD package.
  @override
  Future<void> _verifyDriverForLUCI() {
    if (!_browserDriverDir.existsSync()) {
      throw StateError('Failed to locate Firefox driver on LUCI on path:'
          '${_browserDriverDir.path}');
    }
    return Future<void>.value();
  }

  @override
  Future<void> _startDriver() async {
    await startProcess('./firefoxdriver/geckodriver', ['--port=4444'],
        workingDirectory: _browserDriverDir.path);
    print('INFO: Driver started');
  }

  /// Get the geckodriver version to be used with [FirefoxDriverInstaller].
  ///
  /// For different versions of geckodriver. See:
  /// https://github.com/mozilla/geckodriver/releases
  static String getLockedGeckoDriverVersion() {
    final YamlMap browserLock = BrowserLock.instance.configuration;
    String geckoDriverReleaseVersion = browserLock['geckodriver'] as String;
    return geckoDriverReleaseVersion;
  }
}

/// [DriverManager] implementation for Safari.
///
/// This manager is will only be created/used for macOS.
class SafariDriverManager extends DriverManager {
  SafariDriverManager(String browser) : super(browser);

  @override
  Future<void> _installDriver() {
    // No-op.
    // macOS comes with Safari Driver installed.
    return new Future<void>.value();
  }

  @override
  Future<void> _verifyDriverForLUCI() {
    // No-op.
    // macOS comes with Safari Driver installed.
    return Future<void>.value();
  }

  @override
  Future<void> _startDriver() async {
    final SafariDriverRunner safariDriverRunner = SafariDriverRunner();

    final io.Process process =
        await safariDriverRunner.runDriver(version: 'system');

    processesToCleanUp.add(process);
  }
}

/// Abstract class for preparing the browser driver before running the integration
/// tests.
abstract class DriverManager {
  /// Installation directory for browser's driver.
  final io.Directory _browserDriverDir;

  /// This is the parent directory for all drivers.
  ///
  /// This directory is saved to [temporaryDirectories] and deleted before
  /// tests shutdown.
  final io.Directory _drivers;

  DriverManager(String browser)
      : this._browserDriverDir = io.Directory(pathlib.join(
            environment.webUiDartToolDir.path,
            'drivers',
            browser,
            '${browser}driver-${io.Platform.operatingSystem.toString()}')),
        this._drivers = io.Directory(
            pathlib.join(environment.webUiDartToolDir.path, 'drivers'));

  Future<void> prepareDriver() async {
    if (!isLuci) {
      // LUCI installs driver from CIPD, so we skip installing it on LUCI.
      await _installDriver();
    } else {
      await _verifyDriverForLUCI();
    }
    await _startDriver();
  }

  /// Always re-install since driver can change frequently.
  /// It usually changes with each the browser version changes.
  /// A better solution would be installing the browser and the driver at the
  /// same time.
  /// TODO(nurhan): https://github.com/flutter/flutter/issues/53179. Partly
  // solved. Remaining local integration tests using the locked Chrome version.
  Future<void> _installDriver();

  Future<void> _verifyDriverForLUCI();

  Future<void> _startDriver();

  static DriverManager chooseDriver(String browser) {
    if (browser == 'chrome') {
      return ChromeDriverManager(browser);
    } else if (browser == 'firefox') {
      return FirefoxDriverManager(browser);
    } else if (browser == 'safari' && io.Platform.isMacOS) {
      return SafariDriverManager(browser);
    } else {
      throw StateError('Integration tests are only supported on Firefox, Chrome'
          ' and on Safari (running on macOS)');
    }
  }
}
