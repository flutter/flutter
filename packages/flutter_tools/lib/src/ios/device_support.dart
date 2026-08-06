// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/version.dart';
import '../convert.dart';
import '../macos/xcode.dart';

/// A class to handle preparing the device support for an iOS/iPad device.
class IOSDeviceSupport {
  IOSDeviceSupport({
    required Logger logger,
    required ProcessUtils processUtils,
    required Xcode? xcode,
    required String deviceId,
    required Directory? homeDirectory,
    required String? modelCode,
    required String? operatingSystemVersion,
    required String? cpuArchitectureString,
  }) : _xcode = xcode,
       _logger = logger,
       _processUtils = processUtils,
       _deviceId = deviceId,
       _homeDirectory = homeDirectory,
       _modelCode = modelCode,
       _operatingSystemVersion = operatingSystemVersion,
       _cpuArchitectureString = cpuArchitectureString;

  final Logger _logger;
  final ProcessUtils _processUtils;
  final Xcode? _xcode;

  final String _deviceId;
  final Directory? _homeDirectory;
  final String? _modelCode;
  final String? _operatingSystemVersion;
  final String? _cpuArchitectureString;

  /// The directory that contains iOS Device Support symbols for all devices.
  ///
  /// Return null if the $HOME directory cannot be found.
  late final Directory? _deviceSupportDirectory = _homeDirectory
      ?.childDirectory('Library')
      .childDirectory('Developer')
      .childDirectory('Xcode')
      .childDirectory('iOS DeviceSupport');

  /// Command to copy device support symbols from device to host machine.
  List<String> get _prepareDeviceSupportCommand => [
    'xcrun',
    'xcodebuild',
    '-prepareDeviceSupport',
    '-destination',
    'id=$_deviceId',
  ];

  /// Whether the prepareDeviceSupport command is available. Available on Xcode 16.3+.
  late final bool _prepareDeviceSupportCommandAvailable = () {
    final Version? xcodeVersion = _xcode?.currentVersion;
    if (xcodeVersion == null || xcodeVersion < Version(16, 3, 0)) {
      return false;
    }
    return true;
  }();

  /// Calls `xcodebuild -prepareDeviceSupport` and streams the logs when copying is in progress.
  ///
  /// The command copies symbols from the iOS device to the host machine and stores them in
  /// $HOME/Library/Developer/Xcode/iOS DeviceSupport. Without these symbols, debugging is
  /// extremely slow.
  Future<void> prepareDeviceSupport() async {
    if (!_prepareDeviceSupportCommandAvailable) {
      return;
    }

    try {
      final Process process = await _processUtils.start(_prepareDeviceSupportCommand);

      final timer = Timer(const Duration(seconds: 10), () {
        _logger.printError(
          'Xcode is taking longer than expected to start preparing Device Support symbols...\n'
          'Connect your device via USB and try running this command manually:\n'
          '  "${_prepareDeviceSupportCommand.join(' ')}"',
        );
      });

      var printToTrace = true;
      final StreamSubscription<String> stdoutSubscription = process.stdout
          .transform(utf8.decoder)
          .listen((String text) {
            if (text.contains('Copying')) {
              printToTrace = false;
              _logger.printStatus(
                'Copying Device Support symbols. This may take several minutes to complete...\n'
                'Please do not connect or disconnect your device until finished.',
              );
              timer.cancel();
            }
            if (printToTrace) {
              _logger.printTrace(text);
            } else {
              _logger.printStatus(text, newline: false);
            }
          });

      final StreamSubscription<String> stderrSubscription = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String line) {
            _logger.printError(line);
          });

      try {
        // Wait for stdout and stderr to be fully processed
        // because process.exitCode may complete first.
        await Future.wait<void>(<Future<void>>[
          stdoutSubscription.asFuture<void>(),
          stderrSubscription.asFuture<void>(),
        ]);

        unawaited(stdoutSubscription.cancel());
        unawaited(stderrSubscription.cancel());

        final int exitCode = await process.exitCode;
        if (exitCode != 0) {
          _logger.printError('xcodebuild -prepareDeviceSupport exited with code $exitCode');
        }
      } finally {
        timer.cancel();
      }

      // Print an empty line so that next prints aren't inline with logs from here.
      if (!printToTrace) {
        _logger.printStatus('');
      }
    } on ProcessException catch (exception, stackTrace) {
      _logger.printError(
        'Process exception running "xcodebuild -prepareDeviceSupport": $exception',
      );
      _logger.printTrace('$stackTrace');
    }
  }

  /// Returns the directory for existing Device Support symbols. If there is not an existing
  /// directory, returns null.
  late final Directory? existingDeviceSupportSymbols = () {
    final (Directory? symbolDirectory, Directory? archSymbolDirectory) = _findSymbolDirectories();
    if (archSymbolDirectory != null && archSymbolDirectory.existsSync()) {
      return archSymbolDirectory;
    }
    if (symbolDirectory != null && symbolDirectory.existsSync()) {
      return symbolDirectory;
    }
    return null;
  }();

  /// Returns a warning describing the status of Device Support symbols and guided actions to
  /// resolve issues.
  String? missingSymbolsWarning({bool warnWhenSymbolsExist = false}) {
    const reducePerformance =
        'This will likely reduce debugging performance and may cause the app to hang on a white '
        'screen during launch.';
    const expectedPath =
        r'Once Device Support symbols are finished being copied, they are expected to be found at';

    if (existingDeviceSupportSymbols != null) {
      if (warnWhenSymbolsExist) {
        final String action;
        if (_prepareDeviceSupportCommandAvailable) {
          action =
              'Connect the device via USB and trigger a copy:\n'
              '     ${_prepareDeviceSupportCommand.join(' ')}';
        } else {
          action =
              'Connect the device via USB, close and then re-open Xcode. It may take several '
              'minutes for Xcode to copy symbols from the device. $expectedPath ${existingDeviceSupportSymbols!.path}';
        }
        return 'Xcode Device Support symbols exist for this device, but are being read from '
            'process memory. $reducePerformance\n'
            'To re-copy symbols from your device, complete the following steps:\n'
            '  1. Remove cached symbols:\n'
            '     rm -rf "${existingDeviceSupportSymbols!.parent.path}"\n'
            '  2. $action';
      }
      return null;
    }

    final (Directory? symbolDirectory, Directory? archSymbolDirectory) = _findSymbolDirectories();

    const unableToFind = 'Xcode Device Support was not found for this device.';
    const incompleteCopy = 'Xcode has not finished copying Device Support symbols for this device.';
    final String action;
    if (_prepareDeviceSupportCommandAvailable) {
      action =
          'To trigger Device Symbols to be copied, connect the device via USB, and run this command:\n'
          '  "${_prepareDeviceSupportCommand.join(' ')}"';
    } else {
      action =
          'To trigger Device Symbols to be copied, connect the device via USB, close and then '
          're-open Xcode. It may take several minutes for Xcode to copy symbols from the device.';
    }

    const retryAction = 'Please retry "flutter run" once symbols are finished being copied.';

    // The symbol directory may be null if the home directory could not be determined.
    if (symbolDirectory == null) {
      return '$unableToFind $reducePerformance\n$action\n$expectedPath '
          '\$HOME/Library/Developer/Xcode/iOS DeviceSupport\n$retryAction';
    }

    // If the device's directory exists, it means Xcode has at least started copying symbols.
    final bool deviceDirExists = symbolDirectory.parent.existsSync();
    final status = deviceDirExists ? incompleteCopy : unableToFind;
    final archPath = archSymbolDirectory != null ? ' or ${archSymbolDirectory.path}' : '';

    return '$status $reducePerformance\n$action\n$expectedPath ${symbolDirectory.path}$archPath\n'
        '$retryAction';
  }

  /// Helper method to find the Device Support Symbols directories for a given device.
  ///
  /// Returns a tuple of the symbol directory and the architecture-specific symbol directory.
  /// If the paths to the directories cannot be constructed, returns (null, null).
  ///
  /// The architecture-specific symbol directory is only present on newer versions of iOS (27+).
  (Directory?, Directory?) _findSymbolDirectories() {
    if (_deviceSupportDirectory == null || _modelCode == null || _operatingSystemVersion == null) {
      return (null, null);
    }
    final Directory deviceDirectory = _deviceSupportDirectory.childDirectory(
      '$_modelCode $_operatingSystemVersion',
    );
    final Directory symbolDirectory = deviceDirectory.childDirectory('Symbols');

    // iOS 27+ devices seem to store the symbol directory in a sub-directory
    // /Users/username/Library/Developer/Xcode/iOS DeviceSupport/iPad14,3 27.0 (24A5380h)/arm64e/Symbols
    final Directory? archSymbolDirectory =
        _cpuArchitectureString != null && _cpuArchitectureString.isNotEmpty
        ? deviceDirectory.childDirectory(_cpuArchitectureString).childDirectory('Symbols')
        : null;

    return (symbolDirectory, archSymbolDirectory);
  }
}
