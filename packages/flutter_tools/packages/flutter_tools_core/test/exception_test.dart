// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_core/json.dart';
import 'package:test/test.dart';

void main() {
  group('ToolExtensionException', () {
    test('exposes default domainErrorCode (-32001), null data, and formats toString', () {
      const exception = ToolExtensionException('Custom SDK path does not exist.');

      expect(exception.message, 'Custom SDK path does not exist.');
      expect(exception.code, ToolExtensionException.domainErrorCode);
      expect(exception.data, isNull);
      expect(ToolExtensionException.domainErrorCode, -32001);
      expect(ToolExtensionException.unsupportedCapabilityErrorCode, -32002);
      expect(exception.toString(), 'ToolExtensionException: Custom SDK path does not exist.');
    });

    test('preserves custom code and structured data', () {
      const exception = ToolExtensionException(
        'Screen recording is not supported.',
        code: ToolExtensionException.unsupportedCapabilityErrorCode,
        data: <String, Object?>{
          'capability': 'screenRecording',
          'details': <String, Object?>{'platform': 'linux'},
        },
      );

      expect(exception.message, 'Screen recording is not supported.');
      expect(exception.code, ToolExtensionException.unsupportedCapabilityErrorCode);
      expect(exception.data, const <String, Object?>{
        'capability': 'screenRecording',
        'details': <String, Object?>{'platform': 'linux'},
      });
    });
  });

  group('tryParseToolExtensionRpcError', () {
    test('strips injected request entry and non-string keys for domain errors', () {
      final ToolExtensionException? parsed = tryParseToolExtensionRpcError(
        code: ToolExtensionException.domainErrorCode,
        message: 'Domain error',
        data: const <Object?, Object?>{
          'request': <String, Object?>{'method': 'test'},
          'reason': 'missing_sdk',
          42: 'ignored',
        },
      );

      expect(parsed, isNotNull);
      expect(parsed!.code, ToolExtensionException.domainErrorCode);
      expect(parsed.message, 'Domain error');
      expect(parsed.data, const <String, Object?>{'reason': 'missing_sdk'});
    });

    test('normalizes empty, request-only, null, and non-map data to null', () {
      final ToolExtensionException? requestOnly = tryParseToolExtensionRpcError(
        code: ToolExtensionException.unsupportedCapabilityErrorCode,
        message: 'Unsupported capability',
        data: const <String, Object?>{
          'request': <String, Object?>{'method': 'test'},
        },
      );
      expect(requestOnly, isNotNull);
      expect(requestOnly!.code, ToolExtensionException.unsupportedCapabilityErrorCode);
      expect(requestOnly.message, 'Unsupported capability');
      expect(requestOnly.data, isNull);

      final ToolExtensionException? emptyMap = tryParseToolExtensionRpcError(
        code: ToolExtensionException.domainErrorCode,
        message: 'Empty data',
        data: const <String, Object?>{},
      );
      expect(emptyMap?.data, isNull);

      final ToolExtensionException? nonMap = tryParseToolExtensionRpcError(
        code: ToolExtensionException.domainErrorCode,
        message: 'Non-map data',
        data: 'raw string',
      );
      expect(nonMap?.data, isNull);

      final ToolExtensionException? nullData = tryParseToolExtensionRpcError(
        code: ToolExtensionException.domainErrorCode,
        message: 'Null data',
      );
      expect(nullData?.data, isNull);
    });

    test('returns null for non-extension JSON-RPC error codes', () {
      expect(tryParseToolExtensionRpcError(code: -32000, message: 'Server error'), isNull);
      expect(tryParseToolExtensionRpcError(code: -32601, message: 'Method not found'), isNull);
    });
  });
}
