// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'doctor.dart';
import 'globals.dart' as globals;

class ProxyValidator extends DoctorValidator {
  ProxyValidator() : super('Proxy Configuration');

  static bool get shouldShow => _getEnv('HTTP_PROXY').isNotEmpty;

  final String _httpProxy = _getEnv('HTTP_PROXY');
  final String _noProxy = _getEnv('NO_PROXY');

  /// Gets a trimmed, non-null environment variable. If the variable is not set
  /// an empty string will be returned. Checks for the lowercase version of the
  /// environment variable first, then uppercase to match Dart's HTTP implementation.
  static String _getEnv(String key) =>
      globals.platform.environment[key.toLowerCase()]?.trim() ??
      globals.platform.environment[key.toUpperCase()]?.trim() ??
      '';

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];

    if (_httpProxy.isNotEmpty) {
      messages.add(ValidationMessage('HTTP_PROXY is set'));

      if (_noProxy.isEmpty) {
        messages.add(ValidationMessage.hint('NO_PROXY is not set'));
      } else {
        messages.add(ValidationMessage('NO_PROXY is $_noProxy'));
        for (String host in const <String>['127.0.0.1', 'localhost']) {
          final ValidationMessage msg = _noProxy.contains(host)
              ? ValidationMessage('NO_PROXY contains $host')
              : ValidationMessage.hint('NO_PROXY does not contain $host');

          messages.add(msg);
        }
      }
    }

    final bool hasIssues =
        messages.any((ValidationMessage msg) => msg.isHint || msg.isHint);

    return ValidationResult(
      hasIssues ? ValidationType.partial : ValidationType.installed,
      messages,
    );
  }
}
