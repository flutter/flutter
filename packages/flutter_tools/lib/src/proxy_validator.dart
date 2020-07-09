// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import 'base/platform.dart';
import 'doctor.dart';

/// A validator that displays configured HTTP_PROXY environment variables.
///
/// if the `HTTP_PROXY` environment variable is non-empty, the contents are
/// validated along with `NO_PROXY`.
class ProxyValidator extends DoctorValidator {
  ProxyValidator({
    @required Platform platform,
  })  : shouldShow = _getEnv('HTTP_PROXY', platform).isNotEmpty,
        _httpProxy = _getEnv('HTTP_PROXY', platform),
        _noProxy = _getEnv('NO_PROXY', platform),
        super('Proxy Configuration');

  final bool shouldShow;
  final String _httpProxy;
  final String _noProxy;

  /// Gets a trimmed, non-null environment variable. If the variable is not set
  /// an empty string will be returned. Checks for the lowercase version of the
  /// environment variable first, then uppercase to match Dart's HTTP implementation.
  static String _getEnv(String key, Platform platform) =>
    platform.environment[key.toLowerCase()]?.trim() ??
    platform.environment[key.toUpperCase()]?.trim() ??
    '';

  @override
  Future<ValidationResult> validate() async {
    if (_httpProxy.isEmpty) {
      return const ValidationResult(
          ValidationType.installed, <ValidationMessage>[]);
    }

    final List<ValidationMessage> messages = <ValidationMessage>[
      const ValidationMessage('HTTP_PROXY is set'),
      if (_noProxy.isEmpty)
        const ValidationMessage.hint('NO_PROXY is not set')
      else
        ...<ValidationMessage>[
          ValidationMessage('NO_PROXY is $_noProxy'),
          for (String host in const <String>['127.0.0.1', 'localhost'])
            if (_noProxy.contains(host))
              ValidationMessage('NO_PROXY contains $host')
            else
              ValidationMessage.hint('NO_PROXY does not contain $host'),
        ],
    ];

    final bool hasIssues = messages.any(
      (ValidationMessage msg) => msg.isHint || msg.isError);

    return ValidationResult(
      hasIssues ? ValidationType.partial : ValidationType.installed,
      messages,
    );
  }
}
