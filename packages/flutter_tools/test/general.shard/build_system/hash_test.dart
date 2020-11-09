// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_tools/src/build_system/hash.dart';

import '../../src/common.dart';

// The exact hash values are not important. Md5Hash is currently only a
// partial implementation of the hash algorithm.
void main() {
  testWithoutContext('Can hash bytes less than 512 length', () {
    final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6]);
    final Md5Hash hashA = Md5Hash();
    hashA.addChunk(bytes);

    expect(hashA.finalize(), <int>[1612744810, 621056961, 47724712, 3970165526]);

    final Md5Hash hashB = Md5Hash();
    hashB.addChunk(bytes);

    expect(hashB.finalize(), <int>[1612744810, 621056961, 47724712, 3970165526]);
  });

  testWithoutContext('Can hash bytes exactly 512 length', () {
    final Uint8List bytes = Uint8List.fromList(List<int>.filled(512, 2));
    final Md5Hash hashA = Md5Hash();
    hashA.addChunk(bytes);

    expect(hashA.finalize(), <int>[2835007686, 3619227869, 2508241819, 593340697]);

    final Md5Hash hashB = Md5Hash();
    hashB.addChunk(bytes);

    expect(hashB.finalize(), <int>[2835007686, 3619227869, 2508241819, 593340697]);
  });

  testWithoutContext('Can hash bytes more than 512 length', () {
    final Uint8List bytes = Uint8List.fromList(List<int>.filled(514, 2));
    final Md5Hash hashA = Md5Hash();
    hashA.addChunk(bytes);

    expect(hashA.finalize(), <int>[1611508367, 2487599003, 3736490415, 1528151435]);

    final Md5Hash hashB = Md5Hash();
    hashB.addChunk(bytes);

    expect(hashB.finalize(), <int>[1611508367, 2487599003, 3736490415, 1528151435]);
  });
}
