// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:test/test.dart';

import '../src/context.dart';

void main() {
  group('doctor', () {
    testUsingContext('intellij validator', () async {
      final ValidationResult result = await new IntelliJValidatorTestTarget('Test').validate();
      expect(result.type, ValidationType.partial);
      expect(result.statusInfo, 'version test.test.test');
      expect(result.messages, hasLength(3));

      ValidationMessage message = result.messages
          .firstWhere((ValidationMessage m) => m.message.startsWith('Dart '));
      expect(message.message, 'Dart plugin version 162.2485');

      message = result.messages
          .firstWhere((ValidationMessage m) => m.message.startsWith('Flutter '));
      expect(message.message, contains('Flutter plugin version 0.1.3'));
      expect(message.message, contains('recommended minimum version'));
    });
  });
}

class IntelliJValidatorTestTarget extends IntelliJValidator {
  IntelliJValidatorTestTarget(String title) : super(title);

  @override
  String get pluginsPath => fs.path.join('test', 'data', 'intellij', 'plugins');

  @override
  String get version => 'test.test.test';
}
