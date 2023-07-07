// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

// Regression test for https://github.com/dart-lang/sdk/issues/48521.

void main() {
  const expectedUris = <String?>[
    'file:///a/b/c',
    'dart:io',
    'package:foo/bar.dart',
    null,
  ];

  test('UriList serialization', () {
    final uriList = UriList(uris: expectedUris);
    final serialized = uriList.toJson();
    expect(serialized['type'], 'UriList');
    expect(serialized['uris'], isA<List>());
    final uris = serialized['uris'].cast<String?>();
    expect(uris.length, 4);
    for (int i = 0; i < uris.length; ++i) {
      expect(expectedUris[i], uris[i]);
    }
  });

  test('UriList deserialization', () {
    final json = <String, dynamic>{
      'type': 'UriList',
      'uris': expectedUris,
    };

    final uriList = UriList.parse(json);
    expect(uriList, isNotNull);
    expect(uriList!.uris, expectedUris);
  });
}
