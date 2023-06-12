// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:yaml/yaml.dart';

class FieldValidator extends BasePubspecValidator {
  static const deprecatedFields = [
    'author',
    'authors',
    'transformers',
    'web',
  ];

  FieldValidator(super.provider, super.source);

  /// Validate fields.
  void validate(ErrorReporter reporter, Map<dynamic, YamlNode> contents) {
    for (var field in contents.keys) {
      var name = asString(field);
      if (name != null && deprecatedFields.contains(name)) {
        reportErrorForNode(
            reporter, field, PubspecWarningCode.DEPRECATED_FIELD, [name]);
      }
    }
  }
}
