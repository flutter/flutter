// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'base/common.dart';
import 'base/logger.dart';

class AnalyzeProject {
  AnalyzeProject({
    required Logger logger,
  }) : _logger = logger;

  final Logger _logger;

  Future<bool> diagnose() async {
    _logger.printStatus('test log');
    return true;
  }
}

enum Status {
  error,
  warning,
  success,
}

class ProjectValidatorResult {
  ProjectValidatorResult(this.name);
  final String name;

  String _error = '';
  Status? _status;
  String _value = '';
  String _warning = '';

  void setSuccess(String value, {String? warning}) {
    _status = Status.success;
    _value = value;
    if (warning != null) {
      _warning = warning;
    }
  }

  void setError(String error) {
    _status = Status.error;
    _error = error;
  }

  @override
  String toString() {
    // ensure toString is not called before a value or error is set
    if (_status == null) {
      throwToolExit('ProjectValidatorResult status not set');
    }

    String s;
    if (_status == Status.error) {
      s = _error;
    } else {
      s = '$name: $_value';
      if (_warning.isNotEmpty) {
        s = '$s. $_warning';
      }
    }

    return s;
  }

}