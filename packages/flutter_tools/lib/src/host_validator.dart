// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/doctor.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

/// Common required hosts for flutter.
/// For flutter build for example
const List<String> commonRequiredHosts = <String>[
  'https://pub.dev/',
  'https://cloud.google.com/',
  'https://maven.google.com/',
];

/// MacOS specific required hosts.
/// For flutter build ios for example
const List<String> macOSRequiredHosts = <String>[
  'https://cocoapods.org/',
];

/// Verify that the required hosts
/// ( they are stored at [commonRequiredHosts] and [macOSRequiredHosts] ) are reachable
class HostValidator extends DoctorValidator {
  HostValidator({
    @required Platform platform,
    http.Client httpClient,
  })  : _platform = platform,
        _httpClient = httpClient ?? http.Client(),
        super('Host availability');

  @override
  String get slowWarning => 'Host availability check is taking a long time...';

  final Platform _platform;
  final http.Client _httpClient;

  /// Hosts which are required for flutter
  List<String> get _requiredHosts {
    final List<String> hosts = commonRequiredHosts.toList();
    if (_platform.isMacOS) {
      hosts.addAll(macOSRequiredHosts);
    }
    return commonRequiredHosts;
  }

  /// Make a head request to the host.
  /// Host is available if no exception happened
  Future<_HostValidationResult> _checkHostAvailability(String host) async {
    try {
      await _httpClient.head(host);

      // Host is available if no exception happened
      return _HostValidationResult.success(host);
    } on Exception catch (e) {
      return _HostValidationResult.fail(
          host, 'An error occurred while checking the host: ${e.toString()}');
    }
  }

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    final Iterable<Future<_HostValidationResult>> availabilityResultFuture =
        _requiredHosts.map(_checkHostAvailability);

    final List<_HostValidationResult> availabilityResult =
        (await Future.wait(availabilityResultFuture)).toList();

    // if every hosts are reachable
    if (availabilityResult
        .every((_HostValidationResult result) => result.available)) {
      return ValidationResult(
          ValidationType.installed,
          messages
            ..add(const ValidationMessage('All required hosts are available')));
    } else {
      availabilityResult
          .removeWhere((_HostValidationResult result) => result.available);

      for (final _HostValidationResult result in availabilityResult) {
        messages.add(ValidationMessage.error(
            '${result.host} host is not reachable. Reason: ${result.failResultInfo}'));
      }

      return ValidationResult(ValidationType.partial, messages);
    }
  }
}

class _HostValidationResult {
  _HostValidationResult.fail(this.host, this.failResultInfo)
      : available = false;

  _HostValidationResult.success(this.host)
      : failResultInfo = '',
        available = true;

  /// Some information about fail result. Exception type for example.
  /// Is not used yet.
  final String failResultInfo;
  final String host;
  final bool available;
}
