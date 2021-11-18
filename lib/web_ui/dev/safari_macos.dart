// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:io';

import 'package:path/path.dart' as pathlib;
import 'package:test_api/src/backend/runtime.dart';

import 'browser.dart';
import 'utils.dart';

/// Provides an environment for the desktop variant of Safari running on macOS.
class SafariMacOsEnvironment implements BrowserEnvironment {
  @override
  Browser launchBrowserInstance(Uri url, {bool debug = false}) {
    return SafariMacOs(url);
  }

  @override
  Runtime get packageTestRuntime => Runtime.safari;

  @override
  Future<void> prepare() async {
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
  final String name = 'Safari macOS';

  /// Starts a new instance of Safari open to the given [url].
  factory SafariMacOs(Uri url) {
    return SafariMacOs._(() async {
      // This hack to programmatically launch a test in Safari is borrowed from
      // Karma: https://github.com/karma-runner/karma-safari-launcher/issues/29
      //
      // The issue is that opening an HTML file directly causes Safari to pop up
      // a UI prompt to confirm the opening of a file. However, files under
      // Library/Containers/com.apple.Safari/Data are exempt from this pop up.
      // We create a "trampoline" file in this directory. The trampoline
      // redirects the browser to the test URL in a <script>.
      final String homePath = Platform.environment['HOME']!;
      final Directory safariDataDirectory = Directory(pathlib.join(
        homePath,
        'Library/Containers/com.apple.Safari/Data',
      ));
      final Directory trampolineDirectory = await safariDataDirectory.createTemp('web-engine-test-trampoline-');

      // Clean up trampoline files/directories before exiting felt.
      cleanupCallbacks.add(() async {
        if (trampolineDirectory.existsSync()) {
          trampolineDirectory.delete(recursive: true);
        }
      });

      final File trampoline = File(
        pathlib.join(trampolineDirectory.path, 'trampoline.html'),
      );
      await trampoline.writeAsString('''
<script>
  location = ${json.encode(url.toString())};
</script>
      ''');

      final Process process = await Process.start(
        '/Applications/Safari.app/Contents/MacOS/Safari',
        <String>[trampoline.path],
      );

      return process;
    });
  }

  SafariMacOs._(Future<Process> Function() startBrowser) : super(startBrowser);
}
