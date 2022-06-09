// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:test_api/src/backend/runtime.dart';

import 'webdriver_browser.dart';

/// Provides an environment for the desktop variant of Safari running on macOS.
class SafariMacOsEnvironment extends WebDriverBrowserEnvironment {
  @override
  final String name = 'Safari macOS';

  @override
  Runtime get packageTestRuntime => Runtime.safari;

  @override
  String get packageTestConfigurationYamlFile => 'dart_test_safari.yaml';

  @override
  Uri get driverUri => Uri(scheme: 'http', host: 'localhost', port: portNumber);

  @override
  Future<Process> spawnDriverProcess() => Process.start('safaridriver', <String>['-p', portNumber.toString()]);
}
