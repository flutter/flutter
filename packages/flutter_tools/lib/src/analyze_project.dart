// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'base/common.dart';

enum Status {
  error,
  warning,
  success,
}

class ProjectValidatorResult {

  ProjectValidatorResult(this.name, this.value, this._status, {this.warning});

  final String name;
  final String value;
  final String? warning;
  final Status _status;

  Status get status{
    return _status;
  }

  @override
  String toString() {
    if (_status == Status.error) {
      return 'Error: $value';
    } else {
      String resultString = '$name: $value';
      if (warning != null) {
        resultString = '$resultString. Warning: $warning';
      }
      return resultString;
    }
  }

}
