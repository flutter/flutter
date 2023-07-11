// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.



import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import 'base/bot_detector.dart';
import 'base/common.dart';
import 'base/io.dart' as io;
import 'base/logger.dart';
import 'convert.dart';
import 'resident_runner.dart';

/// An implementation of the devtools launcher that uses `pub global activate` to
/// start a server instance.
class DevtoolsServerLauncher extends DevtoolsLauncher {
  DevtoolsServerLauncher({
    required ProcessManager processManager,
    required String dartExecutable,
    required Logger logger,
    required BotDetector botDetector,
  })  : _processManager = processManager,
        _dartExecutable = dartExecutable,
        _logger = logger,
        _botDetector = botDetector;

  final ProcessManager _processManager;
  final String _dartExecutable;
  final Logger _logger;
  final BotDetector _botDetector;
  final Completer<void> _processStartCompleter = Completer<void>();

  io.Process? _devToolsProcess;
  bool _devToolsProcessKilled = false;
  @visibleForTesting
  Future<void>? devToolsProcessExit;

  static final RegExp _serveDevToolsPattern =
      RegExp(r'Serving DevTools at ((http|//)[a-zA-Z0-9:/=_\-\.\[\]]+?)\.?$');

  @override
  Future<void> get processStart => _processStartCompleter.future;

  @override
  Future<void> launch(Uri? vmServiceUri, {List<String>? additionalArguments}) async {
    // Place this entire method in a try/catch that swallows exceptions because
    // this method is guaranteed not to return a Future that throws.
    try {
      _devToolsProcess = await _processManager.start(<String>[
        _dartExecutable,
        'devtools',
        '--no-launch-browser',
        if (vmServiceUri != null) '--vm-uri=$vmServiceUri',
        ...?additionalArguments,
      ]);
      _processStartCompleter.complete();
      final Completer<Uri> completer = Completer<Uri>();
      _devToolsProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String line) {
            final Match? match = _serveDevToolsPattern.firstMatch(line);
            if (match != null) {
              final String url = match[1]!;
              completer.complete(Uri.parse(url));
            }
         });
      _devToolsProcess!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_logger.printError);

      final bool runningOnBot = await _botDetector.isRunningOnBot;
      devToolsProcessExit = _devToolsProcess!.exitCode.then(
        (int exitCode) {
          if (!_devToolsProcessKilled && runningOnBot) {
            throwToolExit('DevTools process failed: exitCode=$exitCode');
          }
        }
      );

      devToolsUrl = await completer.future;
    } on Exception catch (e, st) {
      _logger.printError('Failed to launch DevTools: $e', stackTrace: st);
    }
  }

  @override
  Future<DevToolsServerAddress?> serve() async {
    if (activeDevToolsServer == null) {
      await launch(null);
    }
    return activeDevToolsServer;
  }

  @override
  Future<void> close() async {
    if (devToolsUrl != null) {
      devToolsUrl = null;
    }
    if (_devToolsProcess != null) {
      _devToolsProcessKilled = true;
      _devToolsProcess!.kill();
    }
  }
}
