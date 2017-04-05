// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:test/test.dart';

void main() {
  group('AnsiLogger', () {
    test('should support color on Windows version >= 10.0.10586', () {
      final String name = new OperatingSystemUtils().name;
      final String versionString = new RegExp(r'\d+\.\d+\.\d+').firstMatch(name).group(0);
      final Version version = new Version.parse(versionString);
      final bool shouldSupportColor = version >= new Version.parse('10.0.10586');

      expect(new AnsiTerminal().supportsColor, shouldSupportColor);
    }, testOn: 'windows');
  });
}
