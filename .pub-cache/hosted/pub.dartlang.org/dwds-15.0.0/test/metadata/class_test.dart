// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:dwds/src/debugging/metadata/class.dart';
import 'package:test/test.dart';

void main() {
  test('Gracefully handles invalid length objects', () async {
    var metadata = ClassMetaData(length: null);
    expect(metadata.length, isNull);

    metadata = ClassMetaData(length: {});
    expect(metadata.length, isNull);

    metadata = ClassMetaData(length: '{}');
    expect(metadata.length, isNull);

    metadata = ClassMetaData(length: 0);
    expect(metadata.length, equals(0));
  });
}
