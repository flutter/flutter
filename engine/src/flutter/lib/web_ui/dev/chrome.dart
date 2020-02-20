// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:io';

import 'package:pedantic/pedantic.dart';

import 'package:test_core/src/util/io.dart'; // ignore: implementation_imports

import 'browser.dart';
import 'chrome_installer.dart';
import 'common.dart';

/// A class for running an instance of Chrome.
///
/// Most of the communication with the browser is expected to happen via HTTP,
/// so this exposes a bare-bones API. The browser starts as soon as the class is
/// constructed, and is killed when [close] is called.
///
/// Any errors starting or running the process are reported through [onExit].
class Chrome extends Browser {
  @override
  final name = 'Chrome';

  @override
  final Future<Uri> remoteDebuggerUrl;

  static String version;

  /// Starts a new instance of Chrome open to the given [url], which may be a
  /// [Uri] or a [String].
  factory Chrome(Uri url, {bool debug = false}) {
    version = ChromeArgParser.instance.version;

    assert(version != null);
    var remoteDebuggerCompleter = Completer<Uri>.sync();
    return Chrome._(() async {
      final BrowserInstallation installation = await getOrInstallChrome(
        version,
        infoLog: isCirrus ? stdout : DevNull(),
      );

      // A good source of various Chrome CLI options:
      // https://peter.sh/experiments/chromium-command-line-switches/
      //
      // Things to try:
      // --font-render-hinting
      // --enable-font-antialiasing
      // --gpu-rasterization-msaa-sample-count
      // --disable-gpu
      // --disallow-non-exact-resource-reuse
      // --disable-font-subpixel-positioning
      final bool isChromeNoSandbox =
          Platform.environment['CHROME_NO_SANDBOX'] == 'true';
      var dir = createTempDir();
      var args = [
        '--user-data-dir=$dir',
        url.toString(),
        if (!debug)
          '--headless',
        if (isChromeNoSandbox)
          '--no-sandbox',
        '--window-size=$kMaxScreenshotWidth,$kMaxScreenshotHeight', // When headless, this is the actual size of the viewport
        '--disable-extensions',
        '--disable-popup-blocking',
        // Indicates that the browser is in "browse without sign-in" (Guest session) mode.
        '--bwsi',
        '--no-first-run',
        '--no-default-browser-check',
        '--disable-default-apps',
        '--disable-translate',
        '--remote-debugging-port=$kDevtoolsPort',
      ];

      final Process process =
          await Process.start(installation.executable, args);

      remoteDebuggerCompleter.complete(
          getRemoteDebuggerUrl(Uri.parse('http://localhost:${kDevtoolsPort}')));

      unawaited(process.exitCode
          .then((_) => Directory(dir).deleteSync(recursive: true)));

      return process;
    }, remoteDebuggerCompleter.future);
  }

  Chrome._(Future<Process> startBrowser(), this.remoteDebuggerUrl)
      : super(startBrowser);
}
