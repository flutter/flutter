// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' hide Platform;

import 'package:mockito/mockito.dart';

import '../test.dart';
import 'common.dart';

class MockFile extends Mock implements File {}

void main() {
  MockFile file;
  setUp(() {
    file = MockFile();
    when(file.existsSync()).thenReturn(true);
  });
  group('verifyVersion()', () {
    test('passes for valid version strings', () async {
      const List<String> valid_versions = <String>[
        '1.2.3',
        '12.34.56',
        '1.2.3-pre.1',
        '1.2.3+hotfix.1',
        '1.2.3+hotfix.12-pre.12',
      ];
      for (String version in valid_versions) {
        when(file.readAsString()).thenAnswer((Invocation invocation) => Future<String>.value(version));
        expect(await verifyVersion(version, file), isTrue, reason: '$version is invalid');
      }
    });

    test('fails for invalid version strings', () async {
      const List<String> invalid_versions = <String>[
        '1.2.3.4',
        '1.2.3.',
        '1.2-pre.1',
        '1.2.3-pre',
        '1.2.3-pre.1+hotfix.1',
        '  1.2.3',
      ];
      for (String version in invalid_versions) {
        when(file.readAsString()).thenAnswer((Invocation invocation) => Future<String>.value(version));
        expect(await verifyVersion(version, file), isFalse);
      }
    });
  });
}
