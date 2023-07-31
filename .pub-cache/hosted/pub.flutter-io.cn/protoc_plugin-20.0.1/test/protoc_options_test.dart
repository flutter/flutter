#!/usr/bin/env dart
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:protoc_plugin/src/generated/plugin.pb.dart';
import 'package:protoc_plugin/src/options.dart';
import 'package:test/test.dart';

void main() {
  test('testValidGeneratorOptions', () {
    void checkValid(String? parameter) {
      var request = CodeGeneratorRequest();
      if (parameter != null) request.parameter = parameter;
      var response = CodeGeneratorResponse();
      var options = parseGenerationOptions(request, response);
      expect(options, TypeMatcher<GenerationOptions>());
      expect(response.error, '');
    }

    checkValid(null);
    checkValid('');
    checkValid(',');
    checkValid(',,,');
    checkValid('  , , ,');
  });

  test('testInvalidGeneratorOptions', () {
    checkInvalid(String parameter) {
      var request = CodeGeneratorRequest();
      request.parameter = parameter;
      var response = CodeGeneratorResponse();
      var options = parseGenerationOptions(request, response);
      expect(options, isNull);
    }

    checkInvalid('abc');
    checkInvalid('abc,def');
  });
}
