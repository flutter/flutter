// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/src/types/javascript_channel.dart';

void main() {
  final List<String> validChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_'.split('');
  final List<String> commonInvalidChars =
      r'`~!@#$%^&*()-=+[]{}\|"' ':;/?<>,. '.split('');
  final List<int> digits = List<int>.generate(10, (int index) => index++);

  test(
      'ctor should create JavascriptChannel when name starts with a valid character followed by a number.',
      () {
    for (final String char in validChars) {
      for (final int digit in digits) {
        final JavascriptChannel channel =
            JavascriptChannel(name: '$char$digit', onMessageReceived: (_) {});

        expect(channel.name, '$char$digit');
      }
    }
  });

  test('ctor should assert when channel name starts with a number.', () {
    for (final int i in digits) {
      expect(
        () => JavascriptChannel(name: '$i', onMessageReceived: (_) {}),
        throwsAssertionError,
      );
    }
  });

  test('ctor should assert when channel contains invalid char.', () {
    for (final String validChar in validChars) {
      for (final String invalidChar in commonInvalidChars) {
        expect(
          () => JavascriptChannel(
              name: validChar + invalidChar, onMessageReceived: (_) {}),
          throwsAssertionError,
        );
      }
    }
  });
}
