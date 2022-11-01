// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show FutureOr;
import 'dart:convert' show json;
import 'dart:html' as html;

import 'package:flutter_test/flutter_test.dart';

export 'package:flutter_goldens_client/skia_client.dart';

/// See documentation in `flutter_goldens_io.dart`.
AsyncMatcher matchesFlutterGolden(Object key, { int? version, bool isFlaky = false }) {
  assert(
    webGoldenComparator is _FlutterWebGoldenComparator,
    'matchesFlutterGolden can only be used with FlutterGoldenFileComparator '
    'but found ${goldenFileComparator.runtimeType}.'
  );

  if (isFlaky) {
    (webGoldenComparator as _FlutterWebGoldenComparator).enableFlakyMode();
  }

  return matchesGoldenFile(key, version: version);
}

/// Wraps a web test, supplying a custom comparator that supports flaky goldens.
Future<void> testExecutable(FutureOr<void> Function() testMain, {String? namePrefix}) async {
  webGoldenComparator = _FlutterWebGoldenComparator(webTestUri);
  await testMain();
}

/// See the io implementation of this function.
Future<void> processBrowserCommand(dynamic command) async {
  throw UnimplementedError('processCommand is not used inside the browser');
}

/// Same as [DefaultWebGoldenComparator] but supports flaky golden checks.
class _FlutterWebGoldenComparator extends WebGoldenComparator {
  /// Creates a new [_FlutterWebGoldenComparator] for the specified [testUri].
  ///
  /// Golden file keys will be interpreted as file paths relative to the
  /// directory in which [testUri] resides.
  ///
  /// The [testUri] URL must represent a file.
  _FlutterWebGoldenComparator(this.testUri);

  /// The test file currently being executed.
  ///
  /// Golden file keys will be interpreted as file paths relative to the
  /// directory in which this file resides.
  Uri testUri;

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

  @override
  Future<bool> compare(double width, double height, Uri golden) async {
    final bool isFlaky = getAndResetFlakyMode();
    final String key = golden.toString();
    final html.HttpRequest request = await html.HttpRequest.request(
      'flutter_goldens',
      method: 'POST',
      sendData: json.encode(<String, Object>{
        'testUri': testUri.toString(),
        'key': key,
        'width': width.round(),
        'height': height.round(),
        'customProperties': <String, dynamic>{
          'isFlaky': isFlaky,
        },
      }),
    );
    final String response = request.response as String;
    if (response == 'true') {
      return true;
    }
    fail(response);
  }

  @override
  Future<void> update(double width, double height, Uri golden) async {
    // Update is handled on the server side, just use the same logic here
    await compare(width, height, golden);
  }
}
