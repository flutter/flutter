// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/run_hot.dart';
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  group('validateReloadReport', () {
    testUsingContext('invalid', () async {
      expect(HotRunner.validateReloadReport(<String, dynamic>{}), false);
      expect(HotRunner.validateReloadReport(
          <String, dynamic>{'type': 'ReloadReport', 'success': true, 'details': <String, dynamic>{}}),
          true);
    });
  });
}
