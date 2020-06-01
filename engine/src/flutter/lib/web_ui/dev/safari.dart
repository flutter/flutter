// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:io';

import 'browser.dart';
import 'safari_installation.dart';
import 'common.dart';

/// A class for running an instance of Safari.
///
/// Most of the communication with the browser is expected to happen via HTTP,
/// so this exposes a bare-bones API. The browser starts as soon as the class is
/// constructed, and is killed when [close] is called.
///
/// Any errors starting or running the process are reported through [onExit].
class Safari extends Browser {
  @override
  final name = 'Safari';

  static String version;

  static bool isMobileBrowser;

  /// Starts a new instance of Safari open to the given [url], which may be a
  /// [Uri] or a [String].
  factory Safari(Uri url, {bool debug = false}) {
    version = SafariArgParser.instance.version;
    isMobileBrowser = SafariArgParser.instance.isMobileBrowser;
    assert(version != null);
    return Safari._(() async {
      if (isMobileBrowser) {
        // iOS-Safari
        // Uses `xcrun simctl`. It is a command line utility to control the
        // Simulator. For more details on interacting with the simulator:
        // https://developer.apple.com/library/archive/documentation/IDEs/Conceptual/iOS_Simulator_Guide/InteractingwiththeiOSSimulator/InteractingwiththeiOSSimulator.html
        var process = await Process.start('xcrun', [
          'simctl',
          'openurl', // Opens the url on Safari installed on the simulator.
          'booted', // The simulator is already booted.
          '${url.toString()}'
        ]);

        return process;
      } else {
        // Desktop-Safari
        // TODO(nurhan): Configure info log for LUCI.
        final BrowserInstallation installation = await getOrInstallSafari(
          version,
          infoLog: DevNull(),
        );

        // In the macOS Catalina opening Safari browser with a file brings
        // a popup which halts the test.
        // The following list of arguments needs to be provided to the `open`
        // command to open Safari for a given URL. In summary, `open` tool opens
        // a new Safari browser (even if one is already open), opens it with no
        // persistent state and wait until it opens.
        // The details copied from `man open` on macOS.
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50809
        var process = await Process.start(installation.executable, [
          // These are flags for `open` command line tool.
          '-F', // Open a fresh Safari with no persistant state.
          '-W', // Wait until the Safari opens.
          '-n', // Open a new instance of the Safari even another one is open.
          '-b', // Specifies the bundle identifier for the application to use.
          'com.apple.Safari', // Bundle identifier for Safari.
          '${url.toString()}'
        ]);

        return process;
      }
    });
  }

  Safari._(Future<Process> startBrowser()) : super(startBrowser);
}
