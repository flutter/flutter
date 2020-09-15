// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:simulators/simulator_manager.dart';
import 'package:yaml/yaml.dart';

import 'common.dart';
import 'utils.dart';

class SafariArgParser extends BrowserArgParser {
  static final SafariArgParser _singletonInstance = SafariArgParser._();

  /// The [SafariArgParser] singleton.
  static SafariArgParser get instance => _singletonInstance;

  String _version;

  SafariArgParser._();

  @override
  void populateOptions(ArgParser argParser) {
    argParser
      ..addOption(
        'safari-version',
        defaultsTo: 'system',
        help: 'The Safari version to use while running tests. The Safari '
            'browser installed on the system is used as the only option now.'
            'Soon we will add support for using different versions using the '
            'tech previews.',
      );

    // Populate options for Ios Safari.
    IosSafariArgParser.instance.populateOptions(argParser);
  }

  @override
  void parseOptions(ArgResults argResults) {
    _version = argResults['safari-version'] as String;
    assert(_version == 'system');
    final String browser = argResults['browser'] as String;
    _isMobileBrowser = browser == 'ios-safari' ? true : false;
  }

  @override
  String get version => _version;

  bool _isMobileBrowser;
  bool get isMobileBrowser => _isMobileBrowser;
}

class IosSafariArgParser extends BrowserArgParser {
  static final IosSafariArgParser _singletonInstance = IosSafariArgParser._();

  /// The [IosSafariArgParser] singleton.
  static IosSafariArgParser get instance => _singletonInstance;

  String get version => 'iOS ${iosMajorVersion}.${iosMinorVersion}';

  int _pinnedIosMajorVersion;
  int _iosMajorVersion;
  int get iosMajorVersion => _iosMajorVersion ?? _pinnedIosMajorVersion;

  int _pinnedIosMinorVersion;
  int _iosMinorVersion;
  int get iosMinorVersion => _iosMinorVersion ?? _pinnedIosMinorVersion;

  String _pinnedIosDevice;
  String _iosDevice;
  String get iosDevice => _iosDevice ?? _pinnedIosDevice;

  IosSafariArgParser._();

  /// Returns [IosSimulator] if the [Platform] is `macOS` and simulator
  /// is started.
  ///
  /// Throws an [StateError] if these two conditions are not met.
  IosSimulator get iosSimulator => io.Platform.isMacOS
      ? (_iosSimulator != null
          ? _iosSimulator
          : throw StateError('iosSimulator not started. Please first call '
              'initIOSSimulator method'))
      : throw StateError('iOS Simulator is only avaliable on macOS machines.');

  IosSimulator _iosSimulator;

  /// Inializes and boots an [IosSimulator] using the [iosMajorVersion],
  /// [iosMinorVersion] and [iosDevice] arguments.
  Future<void> initIosSimulator() async {
    if (_iosSimulator != null) {
      throw StateError('_iosSimulator can only be initialized once');
    }
    final IosSimulatorManager iosSimulatorManager = IosSimulatorManager();
    try {
      _iosSimulator = await iosSimulatorManager.getSimulator(
        iosMajorVersion,
        iosMinorVersion,
        iosDevice,
      );
    } catch (e) {
      throw Exception('Error getting requested simulator. Try running '
          '`felt create` command first before running the tests. Exception: '
          '$e');
    }

    if (!_iosSimulator.booted) {
      await _iosSimulator.boot();
      print('INFO: Simulator ${_iosSimulator.id} booted.');
      cleanupCallbacks.add(() async {
        await _iosSimulator.shutdown();
        print('INFO: Simulator ${_iosSimulator.id} shutdown.');
      });
    }
  }

  @override
  void populateOptions(ArgParser argParser) {
    final YamlMap browserLock = BrowserLock.instance.configuration;
    _pinnedIosMajorVersion = browserLock['ios-safari']['majorVersion'] as int;
    _pinnedIosMinorVersion = browserLock['ios-safari']['minorVersion'] as int;
    final pinnedIosVersion =
        '${_pinnedIosMajorVersion}.${_pinnedIosMinorVersion}';
    _pinnedIosDevice = browserLock['ios-safari']['device'] as String;
    argParser
      ..addOption('version',
          defaultsTo: '$pinnedIosVersion',
          help: 'The version for the iOS operating system the iOS Simulator '
              'will use for tests. For example for testing with iOS 13.2, '
              'use `13.2`. Use command: '
              '`xcrun simctl list runtimes` to list available versions. Use '
              'XCode to install more versions: Xcode > Preferences > Components'
              'If this value is not filled version locked in the '
              'browser_lock.yaml file will be user.')
      ..addOption('device',
          defaultsTo: '$_pinnedIosDevice',
          help: 'The device to be used for the iOS Simulator during the tests. '
              'Use `.` instead of space for seperating the words. '
              'Common examples: iPhone.8, iPhone.8.Plus, iPhone.11, '
              'iPhone 11 Pro. Use command: '
              '`xcrun simctl list devices` for listing the available '
              'devices. If this value is not filled device locked in the '
              'browser_lock.yaml file will be user.');
  }

  @override
  void parseOptions(ArgResults argResults) {
    final String iosVersion = argResults['version'] as String;
    // The version will contain major and minor version seperated by a comma,
    // for example: 13.1, 12.2
    assert(iosVersion.split('.').length == 2,
        'The version should be in format 13.5');
    _iosMajorVersion = int.parse(iosVersion.split('.')[0]);
    _iosMinorVersion = int.parse(iosVersion.split('.')[1]);
    _iosDevice = (argResults['device'] as String).replaceAll('.', ' ');
  }
}

/// Returns the installation of Safari.
///
/// Currently uses the Safari version installed on the operating system.
///
/// Latest Safari version for Catalina, Mojave, High Siera is 13.
///
/// Latest Safari version for Sierra is 12.
// TODO(nurhan): user latest version to download and install the latest
// technology preview.
Future<BrowserInstallation> getOrInstallSafari(
  String requestedVersion, {
  StringSink infoLog,
}) async {
  // These tests are aimed to run only on macOS machines local or on LUCI.
  if (!io.Platform.isMacOS) {
    throw UnimplementedError('Safari on ${io.Platform.operatingSystem} is'
        ' not supported. Safari is only supported on macOS.');
  }

  infoLog ??= io.stdout;

  if (requestedVersion == 'system') {
    // Since Safari is included in macOS, always assume there will be one on the
    // system.
    infoLog.writeln('Using the system version that is already installed.');
    return BrowserInstallation(
      version: 'system',
      executable: PlatformBinding.instance.getMacApplicationLauncher(),
    );
  } else {
    infoLog.writeln('Unsupported version $requestedVersion.');
    throw UnimplementedError();
  }
}
