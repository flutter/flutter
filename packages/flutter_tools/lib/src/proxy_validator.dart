// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'base/io.dart';
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
      messages.add(const ValidationMessage('HTTP_PROXY is set'));

      if (_noProxy.isEmpty) {
        messages.add(const ValidationMessage.hint('NO_PROXY is not set'));
      } else {
        messages.add(ValidationMessage('NO_PROXY is $_noProxy'));
        final List<String> loopBackAddresses = await _getLoopbackAddresses();
        for (final String host in loopBackAddresses) {
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

  Future<List<String>> _getLoopbackAddresses() async {
    final List<NetworkInterface> networkInterfaces =
        await listNetworkInterfaces(includeLinkLocal: true, includeLoopback: true);
    final List<String> loopBackAddresses = <String>['localhost'];
    for (final NetworkInterface networkInterface in networkInterfaces) {
      for (final InternetAddress internetAddress in networkInterface.addresses) {
        if (internetAddress.isLoopback) {
          loopBackAddresses.add(internetAddress.address);
        }
      }
    }
    return loopBackAddresses;
  }
}
