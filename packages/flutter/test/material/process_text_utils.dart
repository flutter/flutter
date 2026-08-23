// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The ID of a fake text processing action.
const String fakeAction1Id = 'fakeActivity.fakeAction1';

/// The ID of another fake text processing action.
const String fakeAction2Id = 'fakeActivity.fakeAction2';

/// The label of a fake text processing action.
const String fakeAction1Label = 'Action1';

/// The label of another fake text processing action.
const String fakeAction2Label = 'Action2';

/// A mock handler for text processing for tests.
class MockProcessTextHandler {
  /// The ID of the last action that was called.
  String? lastCalledActionId;

  /// The text that was passed to the last action that was called.
  String? lastTextToProcess;

  /// A mock of the native text processing method call handler.
  Future<Object?> handleMethodCall(MethodCall call) async {
    if (call.method == 'ProcessText.queryTextActions') {
      // Simulate that only the Android engine will return a non-null result.
      if (defaultTargetPlatform == TargetPlatform.android) {
        return <String, String>{fakeAction1Id: fakeAction1Label, fakeAction2Id: fakeAction2Label};
      }
    }
    if (call.method == 'ProcessText.processTextAction') {
      final args = call.arguments as List<dynamic>;
      final actionId = args[0] as String;
      final textToProcess = args[1] as String;
      lastCalledActionId = actionId;
      lastTextToProcess = textToProcess;

      if (actionId == fakeAction1Id) {
        // Simulates an action that returns a transformed text.
        return '$textToProcess!!!';
      }
      // Simulates an action that failed or does not transform text.
      return null;
    }
    return null;
  }
}
