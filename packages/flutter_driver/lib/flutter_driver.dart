// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Provides API to test Flutter applications that run on real
/// devices and emulators.
///
/// The application runs in a separate process from the test itself.
///
/// This is Flutter's version of Selenium WebDriver (generic web),
/// Protractor (Angular), Espresso (Android) or Earl Gray (iOS).
library flutter_driver;

export 'src/common.dart' show
  testOutputsDirectory;
export 'src/driver.dart' show
  find,
  CommonFinders,
  EvaluatorFunction,
  FlutterDriver,
  TimelineStream;
export 'src/error.dart' show
  DriverError,
  LogLevel,
  LogRecord,
  flutterDriverLog;
export 'src/find.dart' show
  SerializableFinder,
  GetTextResult;
export 'src/health.dart' show
  Health,
  HealthStatus;
export 'src/message.dart' show
  Command,
  Result;
export 'src/render_tree.dart' show
  RenderTree;
export 'src/timeline.dart' show
  Timeline,
  TimelineEvent;
export 'src/timeline_summary.dart' show
  TimelineSummary,
  kBuildBudget;
