// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;

import 'dart:_js_helper' show JS, jsStringToDartString;
import 'dart:_string';
import 'dart:_wasm';

@patch
class DateTime {
  @patch
  static int _getCurrentMicros() =>
      (JS<double>("Date.now") * Duration.microsecondsPerMillisecond).toInt();

  @patch
  static String _timeZoneNameForClampedSeconds(int secondsSinceEpoch) =>
      jsStringToDartString(
          JSStringImpl(JS<WasmExternRef>(r"""secondsSinceEpoch => {
        const date = new Date(secondsSinceEpoch * 1000);
        const match = /\((.*)\)/.exec(date.toString());
        if (match == null) {
            // This should never happen on any recent browser.
            return '';
        }
        return match[1];
      }""", secondsSinceEpoch.toDouble())));

  // In Dart, the offset is the difference between local time and UTC,
  // while in JS, the offset is the difference between UTC and local time.
  // As a result, the signs are opposite, so we negate the value returned by JS.
  @patch
  static int _timeZoneOffsetInSecondsForClampedSeconds(int secondsSinceEpoch) =>
      -JS<double>("s => new Date(s * 1000).getTimezoneOffset() * 60 ",
              secondsSinceEpoch.toDouble())
          .toInt();
}
