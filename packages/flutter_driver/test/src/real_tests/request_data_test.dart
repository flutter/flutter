// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';

import '../../common.dart';

void main() {
  group('RequestData', () {
    test('does not insert "null" string when no message is provided', () {
      const RequestData data = RequestData(null);

      expect(data.serialize(), <String, String>{'command': 'request_data'});
    });

    test('serializes and deserializes', () {
      const RequestData data = RequestData('hello');
      final RequestData roundTrip = RequestData.deserialize(data.serialize());
      expect(roundTrip.message, 'hello');
    });
  });
}
