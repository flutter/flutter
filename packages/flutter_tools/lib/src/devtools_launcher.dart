// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:process/process.dart';

import 'base/io.dart' as io;
import 'base/logger.dart';
import 'base/platform.dart';
import 'convert.dart';
import 'persistent_tool_state.dart';
import 'resident_runner.dart';

/// An implementation of the devtools launcher that uses the server package.
///
/// This is implemented in isolated to prevent the flutter_tool from needing
/// a devtools dep in google3.
class DevtoolsServerLauncher extends DevtoolsLauncher {
  DevtoolsServerLauncher({
    @required Platform platform,
    @required ProcessManager processManager,
    @required String pubExecutable,
    @required Logger logger,
    @required PersistentToolState persistentToolState,
  })  : _processManager = processManager,
        _pubExecutable = pubExecutable,
        _logger = logger,
        _platform = platform,
        _persistentToolState = persistentToolState;

  final ProcessManager _processManager;
  final String _pubExecutable;
  final Logger _logger;
  final Platform _platform;
  final PersistentToolState _persistentToolState;

  io.Process _devToolsProcess;

  static final RegExp _serveDevToolsPattern =
      RegExp(r'Serving DevTools at ((http|//)[a-zA-Z0-9:/=_\-\.\[\]]+)');

  @override
  Future<void> launch(Uri vmServiceUri) async {
    // Place this entire method in a try/catch that swallows exceptions because
    // we do not want to block Flutter run/attach operations on a DevTools
    // failure.
    try {
      bool offline = false;
      try {
        const String pubHostedUrlKey = 'PUB_HOSTED_URL';
        if (_platform.environment.containsKey(pubHostedUrlKey)) {
          await http.head(Uri.parse(_platform.environment[pubHostedUrlKey]));
        } else {
          await http.head(Uri.https('pub.dev', ''));
        }
      } on Exception {
        offline = true;
      }

      if (offline) {
        // TODO(kenz): we should launch an already activated version of DevTools
        // here, if available, once DevTools has offline support. DevTools does
        // not work without internet currently due to the failed request of a
        // couple scripts. See https://github.com/flutter/devtools/issues/2420.
        return;
      } else {
        final bool didActivateDevTools = await _activateDevTools();
        final bool devToolsActive = await _checkForActiveDevTools();
        if (!didActivateDevTools && !devToolsActive) {
          // At this point, we failed to activate the DevTools package and the
          // package is not already active.
          return;
        }
      }

      _devToolsProcess = await _processManager.start(<String>[
        _pubExecutable,
        'global',
        'run',
        'devtools',
        '--no-launch-browser',
        if (vmServiceUri != null) '--vm-uri=$vmServiceUri',
      ]);
      final Completer<Uri> completer = Completer<Uri>();
      _devToolsProcess.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String line) {
            final Match match = _serveDevToolsPattern.firstMatch(line);
            if (match != null) {
              // We are trying to pull "http://127.0.0.1:9101" from "Serving
              // DevTools at http://127.0.0.1:9101.". `match[1]` will return
              // "http://127.0.0.1:9101.", and we need to trim the trailing period
              // so that we don't throw an exception from `Uri.parse`.
              String uri = match[1];
              if (uri.endsWith('.')) {
                uri = uri.substring(0, uri.length - 1);
              }
              completer.complete(Uri.parse(uri));
            }
         });
      _devToolsProcess.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_logger.printError);
      devToolsUri = await completer.future
        .timeout(const Duration(seconds: 10));
    } on Exception catch (e, st) {
      _logger.printError('Failed to launch DevTools: $e', stackTrace: st);
    }
  }

  Future<bool> _checkForActiveDevTools() async {
    // We are offline, and cannot activate DevTools, so check if the DevTools
    // package is already active.
    final io.ProcessResult _pubGlobalListProcess = await _processManager.run(<String>[
      _pubExecutable,
      'global',
      'list',
    ]);

    if (_pubGlobalListProcess.stdout.toString().contains('devtools ')) {
      return true;
    }
    return false;
  }

  /// Helper method to activate the DevTools pub package.
  ///
  /// Returns a bool indicating whether or not the package was successfully
  /// activated from pub.
  Future<bool> _activateDevTools() async {
    final DateTime now = DateTime.now();
    // Only attempt to activate DevTools twice a day.
    final bool shouldActivate =
        _persistentToolState.lastDevToolsActivationTime == null ||
        now.difference(_persistentToolState.lastDevToolsActivationTime).inHours >= 12;
    if (!shouldActivate) {
      return false;
    }

    final Status status = _logger.startProgress(
      'Activating Dart DevTools...',
    );
    try {
      final io.ProcessResult _devToolsActivateProcess = await _processManager
          .run(<String>[
        _pubExecutable,
        'global',
        'activate',
        'devtools'
      ]);
      if (_devToolsActivateProcess.exitCode != 0) {
        status.cancel();
        _logger.printError('Error running `pub global activate '
            'devtools`:\n${_devToolsActivateProcess.stderr}');
        return false;
      }
      status.stop();
      _persistentToolState.lastDevToolsActivationTime = DateTime.now();
      return true;
    } on Exception catch (e, _) {
      status.stop();
      _logger.printError('Error running `pub global activate devtools`: $e');
      return false;
    }
  }

  @override
  Future<DevToolsServerAddress> serve() async {
    if (activeDevToolsServer == null) {
      await launch(null);
    }
    return activeDevToolsServer;
  }

  @override
  Future<void> close() async {
    devToolsUri = null;
    if (_devToolsProcess != null) {
      _devToolsProcess.kill();
      await _devToolsProcess.exitCode;
    }
  }
}
