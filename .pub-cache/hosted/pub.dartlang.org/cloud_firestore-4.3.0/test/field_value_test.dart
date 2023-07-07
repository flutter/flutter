// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('$FieldValue', () {
    test('equality', () {
      expect(FieldValue.delete() == FieldValue.delete(), isTrue);
      expect(
        FieldValue.serverTimestamp() == FieldValue.serverTimestamp(),
        isTrue,
      );
      expect(FieldValue.delete() == FieldValue.serverTimestamp(), isFalse);
    });
  });
}
