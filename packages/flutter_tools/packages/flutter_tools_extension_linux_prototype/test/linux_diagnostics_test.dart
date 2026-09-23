// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension_linux_prototype/src/diagnostics.dart';
import 'package:test/test.dart';

void main() {
  group('LinuxExtensionDiagnostics', () {
    test('runDiagnostics returns successful validation result', () async {
      final diagnostics = LinuxExtensionDiagnostics();
      final List<ValidationResult> results = await diagnostics.runDiagnostics();

      expect(results, hasLength(1));
      expect(results.first.type, ValidationType.success);
      expect(results.first.statusInfo, 'Linux Prototype Extension OK');
      expect(results.first.messages, hasLength(3));
    });
  });
}
