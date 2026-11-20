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

    test('tryFromRpcError parses domain and unsupported-capability errors and strips request', () {
      final ToolExtensionException? domainError = ToolExtensionException.tryFromRpcError(
        code: ToolExtensionException.domainErrorCode,
        message: 'Non-interactive terminal.',
        data: const <Object?, Object?>{
          'request': <String, Object?>{'method': 'terminal.promptForOption'},
          42: 'ignored',
          'reason': 'non-interactive',
        },
      );
      expect(domainError?.code, ToolExtensionException.domainErrorCode);
      expect(domainError?.message, 'Non-interactive terminal.');
      expect(domainError?.data, const <String, Object?>{'reason': 'non-interactive'});

      final ToolExtensionException? unsupportedError = ToolExtensionException.tryFromRpcError(
        code: ToolExtensionException.unsupportedCapabilityErrorCode,
        message: 'Capability not implemented.',
        data: const <String, Object?>{
          'request': <String, Object?>{'method': 'device.createEmulator'},
        },
      );
      expect(unsupportedError?.code, ToolExtensionException.unsupportedCapabilityErrorCode);
      expect(unsupportedError?.data, isNull);

      expect(
        ToolExtensionException.tryFromRpcError(
          code: ToolExtensionException.domainErrorCode,
          message: 'Plain error.',
          data: 'not-a-map',
        )?.data,
        isNull,
      );
      expect(
        ToolExtensionException.tryFromRpcError(code: -32603, message: 'Internal error'),
        isNull,
      );
    });
  });
}
