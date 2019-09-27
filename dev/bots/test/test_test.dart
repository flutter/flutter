// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' hide Platform;
import 'dart:typed_data';

import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart' show FakePlatform;

import '../test.dart';
import 'common.dart';
import 'fake_process_manager.dart';

void main() {
  group('verifyVersion()', () {
    testUsingContext('passes for valid version strings', () async {
      const List<String> valid_versions = <String>[
        '1.2.3',
        '12.34.56',
        '1.2.3-pre.1',
        '1.2.3+hotfix.1',
        '1.2.3+hotfix.12-pre.12',
      ];
      for (String version in valid_versions) {
        expect(await verifyVersion(version), isTrue, reason: '$version is invalid');
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
        expect(await verifyVersion(version), isFalse);
      }
    });
  });
}
