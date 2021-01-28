// Copyright 2014 The Flutter Authors. All rights reserved.
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

export 'src/common/deserialization_factory.dart';
export 'src/common/diagnostics_tree.dart';
export 'src/common/enum_util.dart';
export 'src/common/error.dart';
export 'src/common/find.dart';
export 'src/common/frame_sync.dart';
export 'src/common/fuchsia_compat.dart';
export 'src/common/geometry.dart';
export 'src/common/gesture.dart';
export 'src/common/health.dart';
export 'src/common/message.dart';
export 'src/common/render_tree.dart';
export 'src/common/request_data.dart';
export 'src/common/semantics.dart';
export 'src/common/text.dart';
export 'src/common/wait.dart';
export 'src/driver/common.dart';
export 'src/driver/driver.dart';
export 'src/driver/timeline.dart';
export 'src/driver/timeline_summary.dart';
