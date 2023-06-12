// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:yaml/yaml.dart';

class NameValidator extends BasePubspecValidator {
  NameValidator(super.provider, super.source);

  /// Validate the value of the required `name` field.
  void validate(ErrorReporter reporter, Map<dynamic, YamlNode> contents) {
    var nameField = contents[PubspecField.NAME_FIELD];
    if (nameField == null) {
      reporter.reportErrorForOffset(PubspecWarningCode.MISSING_NAME, 0, 0);
    } else if (nameField is! YamlScalar || nameField.value is! String) {
      reportErrorForNode(
          reporter, nameField, PubspecWarningCode.NAME_NOT_STRING);
    }
  }
}
