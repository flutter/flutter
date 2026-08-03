// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../base/logger.dart';
import '../base/process.dart';
import '../base/version.dart';
import '../convert.dart';
import '../macos/xcode.dart';

/// A class to handle preparing the device support for iOS devices.
class IOSDeviceSupport {
  IOSDeviceSupport({
    required Logger logger,
    required ProcessUtils processUtils,
    required Xcode? xcode,
  }) : _xcode = xcode,
       _logger = logger,
       _processUtils = processUtils;

  final Logger _logger;
  final ProcessUtils _processUtils;
  final Xcode? _xcode;

  /// Calls `xcodebuild -prepareDeviceSupport` for the given [deviceId] and streams the logs when
  /// copying is in progress.
  ///
  /// The command copies symbols from the iOS device to the host machine and stores them in
  /// $HOME/Library/Developer/Xcode/iOS DeviceSupport. Without these symbols, debugging is
  /// extremely slow.
  Future<void> prepareDeviceSupport(String deviceId) async {
    final Version? xcodeVersion = _xcode?.currentVersion;
    if (xcodeVersion == null || xcodeVersion < Version(16, 3, 0)) {
      // The prepareDeviceSupport command is only available on Xcode 16.3+
      return;
    }
    final command = [
      'xcrun',
      'xcodebuild',
      '-prepareDeviceSupport',
      '-destination',
      'id=$deviceId',
    ];
    try {
      final Process process = await _processUtils.start(command);

      final timer = Timer(const Duration(seconds: 10), () {
        _logger.printError(
          'Xcode is taking longer than expected to start preparing Device Support symbols...\n'
          'Connect your device via USB and try running this command manually:\n'
          '  "${command.join(' ')}"',
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
        await process.exitCode.whenComplete(() async {
          await stdoutSubscription.cancel();
          await stderrSubscription.cancel();
        });
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
}
