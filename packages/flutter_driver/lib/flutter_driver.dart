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

export 'src/common/error.dart' show
  DriverError,
  LogLevel,
  LogRecord,
  flutterDriverLog;
export 'src/common/find.dart' show
  SerializableFinder;
export 'src/common/health.dart' show
  Health,
  HealthStatus;
export 'src/common/message.dart' show
  Command,
  Result;
export 'src/common/render_tree.dart' show
  RenderTree;
export 'src/driver/common.dart' show
  testOutputsDirectory;
export 'src/driver/driver.dart' show
  find,
  CommonFinders,
  EvaluatorFunction,
  FlutterDriver,
  TimelineStream;
export 'src/driver/timeline.dart' show
  Timeline,
  TimelineEvent;
export 'src/driver/timeline_summary.dart' show
  TimelineSummary,
  kBuildBudget;
