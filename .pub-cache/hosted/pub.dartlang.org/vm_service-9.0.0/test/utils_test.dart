// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/utils.dart';

void main() {
  test('convertToWebSocketUrl maps URIs correctly', () {
    final testCases = {
      'http://localhost:123/': 'ws://localhost:123/ws',
      'https://localhost:123/': 'wss://localhost:123/ws',
      'ws://localhost:123/': 'ws://localhost:123/ws',
      'wss://localhost:123/': 'wss://localhost:123/ws',
      'http://localhost:123/ABCDEF=/': 'ws://localhost:123/ABCDEF=/ws',
      'https://localhost:123/ABCDEF=/': 'wss://localhost:123/ABCDEF=/ws',
      'ws://localhost:123/ABCDEF=/': 'ws://localhost:123/ABCDEF=/ws',
      'wss://localhost:123/ABCDEF=/': 'wss://localhost:123/ABCDEF=/ws',
      'http://localhost:123': 'ws://localhost:123/ws',
      'https://localhost:123': 'wss://localhost:123/ws',
      'ws://localhost:123': 'ws://localhost:123/ws',
      'wss://localhost:123': 'wss://localhost:123/ws',
      'http://localhost:123/ABCDEF=': 'ws://localhost:123/ABCDEF=/ws',
      'https://localhost:123/ABCDEF=': 'wss://localhost:123/ABCDEF=/ws',
      'ws://localhost:123/ABCDEF=': 'ws://localhost:123/ABCDEF=/ws',
      'wss://localhost:123/ABCDEF=': 'wss://localhost:123/ABCDEF=/ws',
    };

    testCases.forEach((String input, String expected) {
      final inputUri = Uri.parse(input);
      final actualUri = convertToWebSocketUrl(serviceProtocolUrl: inputUri);
      expect(actualUri.toString(), equals(expected));
    });
  });
}
