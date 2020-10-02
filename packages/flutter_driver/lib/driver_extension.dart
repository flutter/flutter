// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This library provides a Dart VM service extension that is required for
/// tests that use `package:flutter_driver` to drive applications from a
/// separate process, similar to Selenium (web), Espresso (Android) and UI
/// Automation (iOS).
///
/// The extension must be installed in the same process (isolate) with your
/// application.
///
/// To enable the extension call [enableFlutterDriverExtension] early in your
/// program, prior to running your application, e.g. before you call `runApp`.
///
/// Example:
///
///     import 'package:flutter/material.dart';
///     import 'package:flutter_driver/driver_extension.dart';
///
///     main() {
///       enableFlutterDriverExtension();
///       runApp(new ExampleApp());
///     }
library flutter_driver_extension;

export 'src/extension/extension.dart';
