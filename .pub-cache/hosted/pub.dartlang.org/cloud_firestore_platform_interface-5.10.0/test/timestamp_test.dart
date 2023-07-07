// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

const int _kBillion = 1000000000;
const int _kStartOfTime = -62135596800;
const int _kEndOfTime = 253402300800;
const int int64MaxValue = 9223372036854775807;

void main() {
  group('$Timestamp', () {
    test('equality', () {
      expect(Timestamp(0, 0), equals(Timestamp(0, 0)));
      expect(Timestamp(123, 456), equals(Timestamp(123, 456)));
    });

    test('validation', () {
      expect(() => Timestamp(0, -1), throwsArgumentError);
      expect(() => Timestamp(0, _kBillion + 1), throwsArgumentError);
      expect(() => Timestamp(_kStartOfTime - 1, 123), throwsArgumentError);
      expect(() => Timestamp(_kEndOfTime + 1, 123), throwsArgumentError);
    });

    test('returns properties', () {
      Timestamp t = Timestamp(123, 456);
      expect(t.seconds, equals(123));
      expect(t.nanoseconds, equals(456));
    });

    // https://github.com/firebase/flutterfire/issues/1222
    test('does not exceed range', () {
      Timestamp maxTimestamp = Timestamp(_kEndOfTime - 1, _kBillion - 1);
      Timestamp.fromMicrosecondsSinceEpoch(maxTimestamp.microsecondsSinceEpoch);
    });

    test('fromMillisecondsSinceEpoch throws max out of range exception', () {
      expect(() => Timestamp.fromMillisecondsSinceEpoch(int64MaxValue),
          throwsArgumentError);
    });

    test('fromMillisecondsSinceEpoch can handle current timestamp', () {
      int currentEpoch = DateTime.now().millisecondsSinceEpoch;
      Timestamp t = Timestamp.fromMillisecondsSinceEpoch(currentEpoch);

      expect(t.toDate().year > 1970, equals(true));
    });

    test('fromMillisecondsSinceEpoch can handle future date', () {
      int currentEpoch = DateTime.now().millisecondsSinceEpoch + 999999999;
      Timestamp t = Timestamp.fromMillisecondsSinceEpoch(currentEpoch);

      expect(
          t.toDate().millisecondsSinceEpoch >
              DateTime.now().millisecondsSinceEpoch,
          equals(true));
    });

    test('fromMillisecondsSinceEpoch can handle 0', () {
      Timestamp t = Timestamp.fromMillisecondsSinceEpoch(0);
      expect(t.toDate().toUtc().year, 1970);
      expect(t.toDate().toUtc().month, 1);
      expect(t.toDate().toUtc().day, 1);
    });

    test('fromMillisecondsSinceEpoch can handle negative millisecond values',
        () {
      Timestamp t = Timestamp.fromMillisecondsSinceEpoch(-9999999999);

      expect(t.toDate().toUtc().year, 1969);
      expect(t.toDate().toUtc().month, 9);
    });

    test('millisecondsSinceEpoch returns correct negative epoch value', () {
      Timestamp t = Timestamp.fromMillisecondsSinceEpoch(-9999999999);
      int epoch = t.millisecondsSinceEpoch;

      expect(epoch, equals(-9999999999));
    });
  });
}
