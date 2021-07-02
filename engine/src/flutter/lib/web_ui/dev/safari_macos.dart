// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:test_api/src/backend/runtime.dart';

import 'browser.dart';
import 'common.dart';
import 'safari_installation.dart';

/// Provides an environment for the desktop variant of Safari running on macOS.
class SafariMacOsEnvironment implements BrowserEnvironment {
  @override
  Browser launchBrowserInstance(Uri url, {bool debug = false}) {
    return SafariMacOs(url);
  }

  @override
  Runtime get packageTestRuntime => Runtime.safari;

  @override
  Future<void> prepareEnvironment() async {
    // Nothing extra to prepare for desktop Safari.
  }

  // We do not yet support screenshots on desktop Safari.
  @override
  ScreenshotManager? getScreenshotManager() => null;

  @override
  String get packageTestConfigurationYamlFile => 'dart_test_safari.yaml';
}

/// Runs an instance of Safari for macOS (i.e. desktop Safari).
///
/// Most of the communication with the browser is expected to happen via HTTP,
/// so this exposes a bare-bones API. The browser starts as soon as the class is
/// constructed, and is killed when [close] is called.
///
/// Any errors starting or running the process are reported through [onExit].
class SafariMacOs extends Browser {
  @override
  final name = 'Safari macOS';

  /// Starts a new instance of Safari open to the given [url], which may be a
  /// [Uri].
  factory SafariMacOs(Uri url) {
    final String version = SafariArgParser.instance.version;
    return SafariMacOs._(() async {
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
        '-F', // Open a fresh Safari with no persistent state.
        '-W', // Wait until the Safari opens.
        '-n', // Open a new instance of the Safari even another one is open.
        '-b', // Specifies the bundle identifier for the application to use.
        'com.apple.Safari', // Bundle identifier for Safari.
        '${url.toString()}'
      ]);

      return process;
    });
  }

  SafariMacOs._(Future<Process> startBrowser()) : super(startBrowser);
}
