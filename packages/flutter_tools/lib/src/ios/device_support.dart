import 'dart:async';
import 'dart:io';

import '../base/logger.dart';
import '../base/process.dart';
import '../base/version.dart';
import '../convert.dart';
import '../macos/xcode.dart';

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

  Future<void> prepareDeviceSupport(String deviceId) async {
    final Version? xcodeVersion = _xcode?.currentVersion;
    if (xcodeVersion == null || xcodeVersion < Version(16, 3, 0)) {
      // The prepareDeviceSupport command is only available on Xcode 16.3+
      return;
    }

    final Process process = await _processUtils.start([
      'xcrun',
      'xcodebuild',
      '-prepareDeviceSupport',
      '-destination',
      'id=$deviceId',
    ]);
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
          }
          if (printToTrace) {
            _logger.printTrace(text);
          } else {
            _logger.printStatus(text, newline: false);
          }
        });

    final StreamSubscription<String> stderrSubscription = process.stderr
        .transform(utf8.decoder)
        .listen((String line) {
          _logger.printError(line);
        });

    // Wait for stdout and stderr to be fully processed
    // because process.exitCode may complete first.
    await Future.wait<void>(<Future<void>>[
      stdoutSubscription.asFuture<void>(),
      stderrSubscription.asFuture<void>(),
    ]);

    // Print an empty line so that next prints aren't inline with logs from here.
    if (!printToTrace) {
      _logger.printStatus('');
    }

    await process.exitCode.whenComplete(() async {
      await stdoutSubscription.cancel();
      await stderrSubscription.cancel();
    });
  }
}
