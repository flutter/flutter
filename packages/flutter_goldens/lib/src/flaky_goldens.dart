// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// flutter_ignore_for_file: golden_tag (see analyze.dart)

import 'package:flutter_test/flutter_test.dart';

/// Similar to [matchesGoldenFile] but specialized for Flutter's own tests when
/// they are flaky.
///
/// Asserts that a [Finder], [Future<ui.Image>], or [ui.Image] - the [key] -
/// matches the golden image file identified by [goldenFile].
///
/// For the case of a [Finder], the [Finder] must match exactly one widget and
/// the rendered image of the first [RepaintBoundary] ancestor of the widget is
/// treated as the image for the widget. As such, you may choose to wrap a test
/// widget in a [RepaintBoundary] to specify a particular focus for the test.
///
/// The [goldenFile] may be either a [Uri] or a [String] representation of a URL.
///
/// Flaky golden file tests are always uploaded to Skia Gold for manual
/// inspection. This allows contributors to validate when a test is no longer
/// flaky by visiting https://flutter-gold.skia.org/list,
/// and clicking on the respective golden test name. The UI will show the
/// history of generated goldens over time. Each unique golden gets a unique
/// color. If the color is the same for all commits in the recent history, the
/// golden is likely no longer flaky and the standard [matchesGoldenFile] can be
/// used in the given test. If the color changes from commit to commit then it
/// is still flaky.
Future<void> expectFlakyGolden(Object key, String goldenFile) {
  if (isBrowser) {
    _setFlakyForWeb();
  } else {
    _setFlakyForIO();
  }
  return expectLater(key, matchesGoldenFile(goldenFile));
}

void _setFlakyForWeb() {
  assert(
    webGoldenComparator is FlakyGoldenMixin,
    'expectFlakyGolden can only be used with a comparator with the FlakyGoldenMixin '
    'but found ${webGoldenComparator.runtimeType}.'
  );
  (webGoldenComparator as FlakyGoldenMixin).enableFlakyMode();
}

void _setFlakyForIO() {
  assert(
    goldenFileComparator is FlakyGoldenMixin,
    'expectFlakyGolden can only be used with a comparator with the FlakyGoldenMixin '
    'but found ${goldenFileComparator.runtimeType}.'
  );
  (goldenFileComparator as FlakyGoldenMixin).enableFlakyMode();
}

/// Allows flaky test handling for the Flutter framework.
///
/// Mixed in with the [FlutterGoldenFileComparator] and
/// [_FlutterWebGoldenComparator].
mixin FlakyGoldenMixin  {
  /// Whether this comparator allows flaky goldens.
  ///
  /// If set to true, concrete implementations of this class are expected to
  /// generate the golden and submit it for review, but not fail the test.
  bool _isFlakyModeEnabled = false;

  /// Puts this comparator into flaky comparison mode.
  ///
  /// After calling this method the next invocation of [compare] will allow
  /// incorrect golden to pass the check.
  ///
  /// Concrete implementations of [compare] must call [getAndResetFlakyMode] so
  /// that subsequent tests can run in non-flaky mode. If a subsequent test
  /// needs to run in a flaky mode, it must call this method again.
  void enableFlakyMode() {
    assert(
      !_isFlakyModeEnabled,
      'Test is already marked as flaky. Call `getAndResetFlakyMode` to reset the '
      'flag before calling this method again.',
    );
    _isFlakyModeEnabled = true;
  }

  /// Returns whether flaky comparison mode was enabled via [enableFlakyMode],
  /// and if it was, resets the comparator back to non-flaky mode.
  bool getAndResetFlakyMode() {
    if (!_isFlakyModeEnabled) {
      // Not in flaky mode. Nothing to do.
      return false;
    }

    // In flaky mode. Reset it and return true.
    _isFlakyModeEnabled = false;
    return true;
  }
}
