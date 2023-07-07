// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:googleapis_auth/src/crypto/rsa.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

/// 2 << 64
final _bigNumber = BigInt.parse('20000000000000000', radix: 16);

void main() {
  group('rsa-algorithm', () {
    test('integer-to-bytes', () {
      expect(RSAAlgorithm.integer2Bytes(BigInt.one, 1), equals([1]));
      expect(RSAAlgorithm.integer2Bytes(_bigNumber, 9),
          equals([2, 0, 0, 0, 0, 0, 0, 0, 0]));
      expect(RSAAlgorithm.integer2Bytes(_bigNumber, 12),
          equals([0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0]));
      expect(() => RSAAlgorithm.integer2Bytes(BigInt.zero, 1),
          throwsA(isArgumentError));
    });

    test('bytes-to-integer', () {
      expect(RSAAlgorithm.bytes2BigInt([1]), equals(BigInt.one));
      expect(
          RSAAlgorithm.bytes2BigInt([2, 0, 0, 0, 0, 0, 0, 0, 0]), _bigNumber);
    });

    test('encrypt', () {
      final encryptedData = [
        155, 24, 116, 247, 12, 118, 240, 206, 240, 138, 136, 193, 3, 73, //!!
        241, 63, 212, 100, 97, 46, 55, 113, 119, 95, 240, 219, 136, 211, 3, 4,
        43, 137, 213, 92, 233, 57, 172, 80, 179, 117, 83, 88, 249, 75, 17, 20,
        195, 51, 25, 97, 248, 217, 41, 117, 55, 63, 5, 252, 42, 133, 82, 73, 52,
        219, 255, 38, 137, 209, 83, 57, 245, 188, 180, 233, 249, 144, 100, 153,
        145, 14, 94, 2, 229, 165, 131, 178, 195, 178, 95, 244, 153, 196, 130,
        39, 158, 143, 98, 181, 223, 184, 68, 198, 201, 203, 89, 15, 41, 185,
        226, 64, 226, 161, 43, 228, 90, 58, 152, 203, 142, 133, 113, 120, 97,
        78, 149, 86, 214, 135, 29, 29, 190, 16, 47, 210, 1, 213, 86, 100, 116,
        187, 11, 255, 224, 6, 6, 206, 60, 138, 24, 179, 245, 248, 200, 45, 167,
        100, 78, 131, 204, 120, 22, 73, 116, 127, 65, 201, 15, 177, 250, 4, 73,
        245, 67, 119, 21, 54, 255, 227, 206, 37, 216, 13, 8, 109, 238, 215, 22,
        63, 163, 155, 33, 148, 254, 113, 17, 68, 65, 48, 82, 43, 240, 249, 87,
        19, 87, 162, 148, 169, 93, 22, 135, 125, 134, 187, 48, 93, 52, 20, 182,
        56, 93, 0, 175, 193, 213, 144, 29, 44, 240, 226, 91, 54, 178, 241, 240,
        85, 53, 148, 172, 138, 107, 131, 14, 157, 183, 137, 46, 130, 51, 233,
        26, 217, 230, 133, 217, 76
      ];
      expect(
          RSAAlgorithm.encrypt(
              testPrivateKey, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 256),
          equals(encryptedData));
    });
  });
}
