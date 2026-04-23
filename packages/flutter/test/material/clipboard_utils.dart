// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

/// A mock clipboard implementation for testing.
class MockClipboard {
  /// Creates a [MockClipboard].
  MockClipboard({this.hasStringsThrows = false});

  /// Whether [Clipboard.hasStrings] should throw an exception.
  final bool hasStringsThrows;

  /// The current clipboard data.
  Map<String, dynamic> clipboardData = <String, dynamic>{'text': null};

  /// Handles a platform method call for clipboard operations.
  Future<Object?> handleMethodCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Clipboard.getData':
        return clipboardData;
      case 'Clipboard.hasStrings':
        if (hasStringsThrows) {
          throw Exception();
        }
        final text = clipboardData['text'] as String?;
        return <String, bool>{'value': text != null && text.isNotEmpty};
      case 'Clipboard.setData':
        clipboardData = methodCall.arguments as Map<String, dynamic>;
    }
    return null;
  }
}
