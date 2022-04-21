// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

enum StatusProjectValidator {
  error,
  warning,
  success,
  crash,
}

class ProjectValidatorResult {

  const ProjectValidatorResult({
    required String name,
    required String value,
    required StatusProjectValidator status,
    String? warning,
  }) : name = name,
       value = value,
       warning = warning,
       status = status;

  final String name;
  final String value;
  final String? warning;
  final StatusProjectValidator status;

  @override
  String toString() {
    if (status == StatusProjectValidator.error) {
      return 'Error: $value';
    }
    if (warning != null) {
      return '$name: $value (warning: $warning)';
    }
    return '$name: $value';
  }

  static ProjectValidatorResult crash(Object exception, StackTrace trace) {
    return ProjectValidatorResult(
        name: exception.toString(),
        value: trace.toString(),
        status: StatusProjectValidator.crash
    );
  }
}
