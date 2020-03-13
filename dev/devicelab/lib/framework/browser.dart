// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:meta/meta.dart';

import 'utils.dart' show forwardStandardStreams;

/// Options passed to Chrome when launching it.
class ChromeOptions {
  ChromeOptions({
    this.userDataDirectory,
    this.url,
    this.windowWidth = 1024,
    this.windowHeight = 1024,
    this.headless,
    this.debugPort,
  });

  /// If not null passed as `--user-data-dir`.
  final String userDataDirectory;

  /// If not null launches a Chrome tab at this URL.
  final String url;

  /// The width of the Chrome window.
  ///
  /// This is important for screenshots and benchmarks.
  final int windowWidth;

  /// The height of the Chrome window.
  ///
  /// This is important for screenshots and benchmarks.
  final int windowHeight;

  /// Launches code in "headless" mode, which allows running Chrome in
  /// environments without a display, such as LUCI and Cirrus.
  final bool headless;

  /// The port Chrome will use for its debugging protocol.
  ///
  /// If null, Chrome is launched without debugging. When running in headless
  /// mode without a debug port, Chrome quits immediately. For most tests it is
  /// typical to set [headless] to true and set a non-null debug port.
  final int debugPort;
}

/// A function called when the Chrome process encounters an error.
typedef ChromeErrorCallback = void Function(String);

/// Manages a single Chrome process.
class Chrome {
  Chrome._(this._chromeProcess, this._onError) {
    // If the Chrome process quits before it was asked to quit, notify the
    // error listener.
    _chromeProcess.exitCode.then((int exitCode) {
      if (!_isStopped) {
        _onError('Chrome process exited prematurely with exit code $exitCode');
      }
    });
  }

  /// Launches Chrome with the give [options].
  ///
  /// The [onError] callback is called with an error message when the Chrome
  /// process encounters an error. In particular, [onError] is called when the
  /// Chrome process exits prematurely, i.e. before [stop] is called.
  static Future<Chrome> launch(ChromeOptions options, { String workingDirectory, @required ChromeErrorCallback onError }) async {
    final io.ProcessResult versionResult = io.Process.runSync(_findSystemChromeExecutable(), const <String>['--version']);
    print('Launching ${versionResult.stdout}');

    final List<String> args = <String>[
      if (options.userDataDirectory != null)
        '--user-data-dir=${options.userDataDirectory}',
      if (options.url != null)
        options.url,
      if (io.Platform.environment['CHROME_NO_SANDBOX'] == 'true')
        '--no-sandbox',
      if (options.headless)
        '--headless',
      if (options.debugPort != null)
        '--remote-debugging-port=${options.debugPort}',
      '--window-size=${options.windowWidth},${options.windowHeight}',
      '--disable-extensions',
      '--disable-popup-blocking',
      // Indicates that the browser is in "browse without sign-in" (Guest session) mode.
      '--bwsi',
      '--no-first-run',
      '--no-default-browser-check',
      '--disable-default-apps',
      '--disable-translate',
    ];
    final io.Process chromeProcess = await io.Process.start(
      _findSystemChromeExecutable(),
      args,
      workingDirectory: workingDirectory,
    );
    forwardStandardStreams(chromeProcess);
    return Chrome._(chromeProcess, onError);
  }

  final io.Process _chromeProcess;
  final ChromeErrorCallback _onError;
  bool _isStopped = false;

  /// Stops the Chrome process.
  void stop() {
    _isStopped = true;
    _chromeProcess.kill();
  }
}

String _findSystemChromeExecutable() {
  // On some environments, such as the Dart HHH tester, Chrome resides in a
  // non-standard location and is provided via the following environment
  // variable.
  final String envExecutable = io.Platform.environment['CHROME_EXECUTABLE'];
  if (envExecutable != null) {
    return envExecutable;
  }

  if (io.Platform.isLinux) {
    final io.ProcessResult which =
        io.Process.runSync('which', <String>['google-chrome']);

    if (which.exitCode != 0) {
      throw Exception('Failed to locate system Chrome installation.');
    }

    return (which.stdout as String).trim();
  } else if (io.Platform.isMacOS) {
    return '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
  } else {
    throw Exception('Web benchmarks cannot run on ${io.Platform.operatingSystem} yet.');
  }
}
