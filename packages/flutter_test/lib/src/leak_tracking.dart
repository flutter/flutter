// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';

/// Handler to collect leak information.
///
/// Used by [LeakTrackingFlutterTestConfig.onLeaks].
/// The parameter [leaks] contains details about found leaks.
typedef LeaksCallback = void Function(Leaks leaks);

const String _nonBackwardCompatibleApiWarning = 'Backward compatibility of this API is not guaranteed.';

/// Configuration for leak trecking in unit tests.
///
/// The configuration is needed only for test debugging,
/// not for regular test run.
///
/// Do not submit usage of the constructor to the repository,
/// because backward compatibility of its API is not guaranteed.
@Deprecated(_nonBackwardCompatibleApiWarning)
class LeakTrackingFlutterTestConfig {
  /// Creates a new instance of [LeakTrackingFlutterTestConfig].
  @Deprecated(_nonBackwardCompatibleApiWarning)
  const LeakTrackingFlutterTestConfig({
    this.stackTraceCollectionConfig = const StackTraceCollectionConfig(),
    this.onLeaks,
    this.failTestOnLeaks = true,
  });

  /// When to collect stack trace information.
  ///
  /// You may need to know call stack to troubleshoot memory leaks.
  /// Custonize this parameter to collect stack traces when needed.
  final StackTraceCollectionConfig stackTraceCollectionConfig;

  /// Handler to obtain details about collected leaks.
  ///
  /// Use the handler to process the collected leak
  /// details programmatically.
  final LeaksCallback? onLeaks;

  /// If true, the test will fail if leaks are found.
  ///
  /// Set it to false if you want the test to pass, in order
  /// to analyze the found leaks after the test execution.
  final bool failTestOnLeaks;
}
