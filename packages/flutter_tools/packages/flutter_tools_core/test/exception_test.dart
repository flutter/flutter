// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

void main() {
  group('ToolExtensionException', () {
    test('exposes domainErrorCode (-32001) and formats toString', () {
      const exception = ToolExtensionException('Custom SDK path does not exist.');

      expect(exception.message, 'Custom SDK path does not exist.');
      expect(ToolExtensionException.domainErrorCode, -32001);
      expect(exception.toString(), 'ToolExtensionException: Custom SDK path does not exist.');
    });
  });
}
