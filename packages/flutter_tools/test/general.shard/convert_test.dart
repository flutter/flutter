// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' as cnv;

import 'package:flutter_tools/src/convert.dart';

import '../src/common.dart';

void main() {
  late String passedString;
  late String nonpassString;

  const decoder = Utf8Decoder();

  setUp(() {
    passedString = 'normal string';
    nonpassString = 'malformed string => \u{FFFD}';
  });

  testWithoutContext('Decode a normal string', () async {
    expect(decoder.convert(passedString.codeUnits), passedString);
  });

  testWithoutContext('Decode a malformed string without throwing', () async {
    expect(utf8AllowMalformed.decode(nonpassString.codeUnits), nonpassString);
  });

  testWithoutContext('Decode invalid UTF-8 bytes from external source', () async {
    final bytes = <int>[
      91,
      78,
      111,
      116,
      105,
      102,
      105,
      99,
      97,
      116,
      105,
      111,
      110,
      93,
      32,
      113,
      117,
      101,
      117,
      101,
      100,
      58,
      32,
      97,
      100,
      118,
      101,
      114,
      116,
      32,
      40,
      240,
      159,
      165,
      168,
      75,
      73,
      52,
      79,
      84,
      75,
      32,
      66,
      97,
      99,
      107,
      112,
      97,
      99,
      107,
      32,
      239,
      191,
      189,
      41,
      10,
    ];

    // Should not throw, should return the decoded string
    final String result = utf8AllowMalformed.decode(bytes);
    expect(result, isA<String>());
    expect(result, contains('\u{FFFD}'));
  });

  testWithoutContext('Decode with reportErrors: false does not warn', () async {
    const silentDecoder = Utf8Decoder(reportErrors: false);
    final String result = silentDecoder.convert(nonpassString.codeUnits);
    expect(result, nonpassString);
  });

  testWithoutContext('Decode empty input', () async {
    expect(decoder.convert(<int>[]), '');
  });

  testWithoutContext('Decode with start and end parameters', () async {
    const input = 'hello world';
    final List<int> bytes = input.codeUnits;
    expect(decoder.convert(bytes, 6, 11), 'world');
  });

  testWithoutContext('Decode multiple replacement characters', () async {
    // Multiple invalid byte sequences
    final bytes = <int>[239, 191, 189, 65, 239, 191, 189];
    final String result = utf8AllowMalformed.decode(bytes);
    expect(result, contains('\u{FFFD}'));
    expect(result, contains('A'));
  });

  testWithoutContext('Decode valid UTF-8 without replacement characters', () async {
    // Valid UTF-8: "hello"
    final bytes = <int>[104, 101, 108, 108, 111];
    final String result = decoder.convert(bytes);
    expect(result, 'hello');
    expect(result.contains('\u{FFFD}'), isFalse);
  });

  group('utf8AllowMalformed constant', () {
    testWithoutContext('utf8AllowMalformed decodes malformed UTF-8 silently', () async {
      final bytes = <int>[239, 191, 189]; // Invalid UTF-8 sequence
      final String result = utf8AllowMalformed.decode(bytes);
      // Should decode to replacement character without warnings
      expect(result, contains('\u{FFFD}'));
    });

    testWithoutContext('utf8AllowMalformed decodes valid UTF-8 correctly', () async {
      const input = 'Hello, World!';
      final List<int> bytes = input.codeUnits;
      final String result = utf8AllowMalformed.decode(bytes);
      expect(result, input);
    });

    testWithoutContext('utf8AllowMalformed handles mixed valid/invalid UTF-8', () async {
      // Mix of valid ASCII and invalid UTF-8
      final bytes = <int>[72, 101, 108, 108, 111, 239, 191, 189, 87, 111, 114, 108, 100];
      final String result = utf8AllowMalformed.decode(bytes);
      expect(result, contains('Hello'));
      expect(result, contains('World'));
      expect(result, contains('\u{FFFD}'));
    });
  });

  group('VM Service log decoding scenario', () {
    testWithoutContext('Decode base64-encoded invalid UTF-8 from VM Service event', () async {
      // Simulate VM Service event with base64-encoded app log containing invalid UTF-8
      // This is raw bytes that would come from a VM Service event: "App log with error: [invalid byte]"
      final rawBytes = <int>[
        65,
        112,
        112,
        32,
        108,
        111,
        103,
        32,
        119,
        105,
        116,
        104,
        32,
        101,
        114,
        114,
        111,
        114,
        58,
        32,
        239,
        191,
        189,
      ];
      final String base64Encoded = cnv.base64.encode(rawBytes);

      // This simulates what processVmServiceMessage does
      final String decoded = utf8AllowMalformed.decode(cnv.base64.decode(base64Encoded));
      expect(decoded, contains('App log'));
      expect(decoded, contains('\u{FFFD}'));
    });

    testWithoutContext('Decode app log with emoji from Bluetooth device', () async {
      // Simulate Bluetooth device sending emoji (might be malformed)
      // Emoji 🎵 is F0 9F 8E B5 in UTF-8
      final bytes = <int>[
        65, // 'A'
        32,
        240, // Start of emoji bytes (might be incomplete)
        159,
        168, // Incomplete emoji sequence
        32,
        66, // 'B'
      ];

      final String decoded = utf8AllowMalformed.decode(bytes);
      // Should not crash, should contain replacement characters for invalid sequences
      expect(decoded, isA<String>());
      expect(decoded.contains('A'), isTrue);
      expect(decoded.contains('B'), isTrue);
    });
  });
}
