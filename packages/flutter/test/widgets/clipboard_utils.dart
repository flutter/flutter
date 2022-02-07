// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';

class MockClipboard {
  MockClipboard({
    this.hasStringsThrows = false,
  });

  final bool hasStringsThrows;

  dynamic _clipboardData = <String, dynamic>{
    'text': null,
  };

  Future<Object?> handleMethodCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Clipboard.getData':
        return _clipboardData;
      case 'Clipboard.hasStrings':
        if (hasStringsThrows)
          throw Exception();
        final Map<String, dynamic>? clipboardDataMap = _clipboardData as Map<String, dynamic>?;
        final String? text = clipboardDataMap?['text'] as String?;
        return <String, bool>{'value': text != null && text.isNotEmpty};
      case 'Clipboard.setData':
        _clipboardData = methodCall.arguments;
        break;
    }
  }
}
