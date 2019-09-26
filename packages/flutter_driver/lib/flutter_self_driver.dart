// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Provides API to test Flutter applications that run on real devices and
/// emulators.
///
/// The flutter applications test themselves with no separate process needed.
///
/// This is Flutter's version of Selenium WebDriver (generic web),
/// Protractor (Angular), Espresso (Android) or Earl Gray (iOS).
library flutter_self_driver;

export 'src/driver/timeline.dart' show
  Timeline,
  TimelineEvent;
export 'src/driver/timeline_summary.dart' show
  TimelineSummary;
export 'src/self_driver/self_driver.dart' show TimelineStream, FlutterSelfDriver;
