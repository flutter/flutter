// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';
import 'flutter_command_test.dart';

void main() {
  group('FlutterCommandRunner', () {
    testUsingContext('checks that Flutter installation is up-to-date', () async {
      final MockFlutterVersion version = FlutterVersion.instance;
      bool versionChecked = false;
      when(version.checkFlutterVersionFreshness()).thenAnswer((_) async {
        versionChecked = true;
      });

      await createTestCommandRunner(new DummyFlutterCommand(shouldUpdateCache: false))
          .run(<String>['dummy']);

      expect(versionChecked, isTrue);
    });
  });
}
