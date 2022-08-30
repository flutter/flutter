// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

/// Used to request a specific [DartPerformanceMode].
///
/// When a request is made to the engine via the [PlatformDispatcher] it is
/// not guaranteed to result in a specific [DartPerformanceMode]. This is best
/// effort and the engine may choose to ignore the request.
///
/// This is currently not supported on web.
class PerformanceModeHandler {
  PerformanceModeHandler._init();

  /// Returns a [PerformanceModeHandler] that can be used to request a specific
  /// [DartPerformanceMode].
  static PerformanceModeHandler get instance => _instance;
  static final PerformanceModeHandler _instance = PerformanceModeHandler._init();

  /// Request a specific [DartPerformanceMode]. `requestor` is the handle to
  /// component making the request, typically the component itself. Returns
  /// `true` is the request was successfully made to the engine, `false` otherwise.
  /// Even if the result is `true`, the engine may choose to ignore the request or
  /// the performance mode may not be guaranteed to be the one requested.
  ///
  /// If conflicting requests are made, only the first request will be honored.
  bool createRequest(dynamic requestor, DartPerformanceMode mode) {
    if (_performanceModes.isNotEmpty) {
      final DartPerformanceMode oldRequest = _performanceModes.entries.first.value;
      if (oldRequest != mode) {
        return false;
      }
    }
    _performanceModes[requestor] = mode;
    PlatformDispatcher.instance.requestDartPerformanceMode(mode);
    return true;
  }

  /// Remove a request for a specific [DartPerformanceMode]. `requestor` is the
  /// handle to component making the request, typically the component itself. If
  /// all the pending requests have been disposed, the engine will revert to the
  /// [DartPerformanceMode.balanced] performance mode.
  void disposeRequest(dynamic requestor) {
    _performanceModes.remove(requestor);
    if (_performanceModes.isEmpty) {
      PlatformDispatcher.instance.requestDartPerformanceMode(DartPerformanceMode.balanced);
    }
  }

  /// Returns the current [DartPerformanceMode] requested. If no requests have
  /// been made, returns `null`.
  DartPerformanceMode? getRequestedPerformanceMode() {
    if (_performanceModes.isEmpty) {
      return null;
    }
    return _performanceModes.entries.first.value;
  }

  final Map<dynamic, DartPerformanceMode> _performanceModes = <dynamic, DartPerformanceMode>{};
}
