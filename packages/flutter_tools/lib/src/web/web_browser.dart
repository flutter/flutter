// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart' hide StackTrace;

/// An active web browser instance launched to execute `flutter test` web suites.
abstract interface class WebTestBrowser {
  /// Display name of the browser for diagnostic logging (e.g. `'Chrome'`, `'Firefox'`).
  String get name;

  /// Operating system process ID of the browser or driver process, if available.
  int? get pid;

  /// Completes with the process exit code when the browser terminates.
  Future<int> get onExit;

  /// URL of the remote debugger endpoint, if supported by this browser.
  Uri? get remoteDebuggerUrl;

  /// Optional Chrome DevTools Protocol connection for console forwarding and hang diagnostics.
  Future<WipConnection?>? get wipConnection;

  /// Terminates the browser and cleans up any temporary profile resources.
  Future<void> close();
}

/// Launches a [WebTestBrowser] navigated to a test host URL.
abstract interface class WebTestBrowserLauncher {
  Future<WebTestBrowser> launch(
    String url, {
    bool headless = false,
    List<String> webBrowserFlags = const <String>[],
  });
}
