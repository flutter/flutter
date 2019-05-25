// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/common.dart';

import '../src/common.dart';

void main() {
  group('throwToolExit', () {
    test('throws ToolExit', () {
      expect(() => throwToolExit('message'), throwsToolExit());
    });

    test('throws ToolExit with exitCode', () {
      expect(() => throwToolExit('message', exitCode: 42), throwsToolExit(exitCode: 42));
    });

    test('throws ToolExit with message', () {
      expect(() => throwToolExit('message'), throwsToolExit(message: 'message'));
    });

    test('throws ToolExit with message and exit code', () {
      expect(() => throwToolExit('message', exitCode: 42), throwsToolExit(exitCode: 42, message: 'message'));
    });
  });
}
