// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

void main() {
  group('ToolExtensionException', () {
    test(
      'exposes domainErrorCode (-32001), unsupportedCapabilityErrorCode (-32002), and defaults',
      () {
        const exception = ToolExtensionException('Custom SDK path does not exist.');

        expect(exception.message, 'Custom SDK path does not exist.');
        expect(exception.code, ToolExtensionException.domainErrorCode);
        expect(exception.data, isNull);
        expect(ToolExtensionException.domainErrorCode, -32001);
        expect(ToolExtensionException.unsupportedCapabilityErrorCode, -32002);
        expect(exception.toString(), 'ToolExtensionException: Custom SDK path does not exist.');
      },
    );

    test('supports custom error code, structured diagnostic data, and deep equality', () {
      const exception = ToolExtensionException(
        'Emulator creation is not supported.',
        code: ToolExtensionException.unsupportedCapabilityErrorCode,
        data: <String, Object?>{'capability': 'createEmulator'},
      );
      final nonConstData = <String, Object?>{'capability': 'createEmulator'};
      final equalCopy = ToolExtensionException(
        'Emulator creation is not supported.',
        code: ToolExtensionException.unsupportedCapabilityErrorCode,
        data: nonConstData,
      );
      const differentData = ToolExtensionException(
        'Emulator creation is not supported.',
        code: ToolExtensionException.unsupportedCapabilityErrorCode,
        data: <String, Object?>{'capability': 'other'},
      );

      expect(exception.message, 'Emulator creation is not supported.');
      expect(exception.code, -32002);
      expect(exception.data, const <String, Object?>{'capability': 'createEmulator'});
      expect(exception, equals(equalCopy));
      expect(exception.hashCode, equals(equalCopy.hashCode));
      expect(exception, isNot(equals(differentData)));
    });
  });
}
