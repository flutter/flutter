// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_tools/executable.dart' as tools;
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/os.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  Cache.disableLocking();

  int exitCode;
  setExitFunctionForTests((int code) {
    exitCode = code;
  });

  group('--bug-report', () {
    testUsingContext('generates valid zip file', () async {
      await tools.main(<String>['devices', '--bug-report']);
      expect(exitCode, 0);
      verify(os.zip(any, argThat(hasPath(matches(r'bugreport_01\.zip')))));
    });
  });
}
