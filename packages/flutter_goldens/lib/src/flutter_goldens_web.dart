// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show FutureOr;
import 'dart:convert' show json;
import 'dart:html' as html;

import 'package:flutter_test/flutter_test.dart';

import 'flaky_goldens.dart';

export 'package:flutter_goldens_client/skia_client.dart';

/// Wraps a web test, supplying a custom comparator that supports flaky goldens.
Future<void> testExecutable(FutureOr<void> Function() testMain, {String? namePrefix}) async {
  webGoldenComparator = FlutterWebGoldenComparator(webTestUri);
  await testMain();
}

/// See the io implementation of this function.
Future<void> processBrowserCommand(dynamic command) async {
  throw UnimplementedError('processBrowserCommand is not used inside the browser');
}

/// Same as [DefaultWebGoldenComparator] but supports flaky golden checks.
class FlutterWebGoldenComparator extends WebGoldenComparator with FlakyGoldenMixin {
  /// Creates a new [FlutterWebGoldenComparator] for the specified [testUri].
  ///
  /// Golden file keys will be interpreted as file paths relative to the
  /// directory in which [testUri] resides.
  ///
  /// The [testUri] URL must represent a file.
  FlutterWebGoldenComparator(this.testUri);

  /// The test file currently being executed.
  ///
  /// Golden file keys will be interpreted as file paths relative to the
  /// directory in which this file resides.
  Uri testUri;

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
