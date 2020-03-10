// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:io';

import 'package:pedantic/pedantic.dart';

import 'package:test_core/src/util/io.dart'; // ignore: implementation_imports

import 'browser.dart';
import 'firefox_installer.dart';
import 'common.dart';

/// A class for running an instance of Firefox.
///
/// Most of the communication with the browser is expected to happen via HTTP,
/// so this exposes a bare-bones API. The browser starts as soon as the class is
/// constructed, and is killed when [close] is called.
///
/// Any errors starting or running the process are reported through [onExit].
class Firefox extends Browser {
  @override
  final name = 'Firefox';

  @override
  final Future<Uri> remoteDebuggerUrl;

  static String version;

  /// Starts a new instance of Firefox open to the given [url], which may be a
  /// [Uri] or a [String].
  factory Firefox(Uri url, {bool debug = false}) {
    version = FirefoxArgParser.instance.version;

    assert(version != null);
    var remoteDebuggerCompleter = Completer<Uri>.sync();
    return Firefox._(() async {
      final BrowserInstallation installation = await getOrInstallFirefox(
        version,
        infoLog: isCirrus ? stdout : DevNull(),
      );

      // A good source of various Firefox Command Line options:
      // https://developer.mozilla.org/en-US/docs/Mozilla/Command_Line_Options#Browser
      //
      var dir = createTempDir();
      bool isMac = Platform.isMacOS;
      var args = [
        url.toString(),
        '--headless',
        '-width $kMaxScreenshotWidth',
        '-height $kMaxScreenshotHeight',
        isMac ? '--new-window' : '-new-window',
        isMac ? '--new-instance' : '-new-instance',
        '--start-debugger-server $kDevtoolsPort',
      ];

      final Process process =
          await Process.start(installation.executable, args,
            workingDirectory: dir);

      remoteDebuggerCompleter.complete(
          getRemoteDebuggerUrl(Uri.parse('http://localhost:$kDevtoolsPort')));

      unawaited(process.exitCode
          .then((_) => Directory(dir).deleteSync(recursive: true)));

      return process;
    }, remoteDebuggerCompleter.future);
  }

  Firefox._(Future<Process> startBrowser(), this.remoteDebuggerUrl)
      : super(startBrowser);
}
