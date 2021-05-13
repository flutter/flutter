// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';
import 'package:zircon/zircon.dart';

void main() {
  test('store the disposition arguments correctly', () {
    final Handle handle = System.channelCreate().first;
    final HandleDisposition disposition = HandleDisposition(1, handle, 2, 3);
    expect(disposition.operation, equals(1));
    expect(disposition.handle, equals(handle));
    expect(disposition.type, equals(2));
    expect(disposition.rights, equals(3));
    expect(disposition.result, equals(ZX.OK));
  });
}
