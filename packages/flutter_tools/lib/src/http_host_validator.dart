// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'base/io.dart';
import 'base/platform.dart';
import 'doctor.dart';

/// Common Flutter HTTP hosts.
const List<String> commonRequiredHttpHosts = <String>[
  'https://pub.dev/',
  'https://cloud.google.com/',
  'https://maven.google.com/',
];

/// MacOS specific required HTTP hosts.
const List<String> macOSRequiredHttpHosts = <String>[
  'https://cocoapods.org/',
];

/// Verify that the required hosts stored at [commonRequiredHttpHosts] and [macOSRequiredHttpHosts] are reachable.
class HttpHostValidator extends DoctorValidator {
  HttpHostValidator({
    @required Platform platform,
    @required http.Client httpClient,
  })  : _platform = platform,
        _httpClient = httpClient,
        super('HTTP Host availability');

  final Platform _platform;
  final http.Client _httpClient;

  @override
  String get slowWarning => 'HTTP Host availability check is taking a long time...';

  /// List of required hosts for given run context
  List<String> get _requiredHosts =>
      _platform.isMacOS ? commonRequiredHttpHosts + macOSRequiredHttpHosts : commonRequiredHttpHosts;

  /// Make a head request to the HTTP host. HTTP Host is available if no exception happened
  Future<_HostValidationResult> _checkHostAvailability(String host) async {
    try {
      await _httpClient.head(host);
      // HTTP Host is available if no exception happened
      return _HostValidationResult.success(host);
    } on HttpException catch (e) {
      return _HostValidationResult.fail(
          host, 'An error occurred while checking the HTTP host: ${e.toString()}');
    }
  }

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    final Iterable<Future<_HostValidationResult>> availabilityResultFutures =
      _requiredHosts.map(_checkHostAvailability);

    final List<_HostValidationResult> availabilityResults =
      (await Future.wait(availabilityResultFutures)).toList();

    if (availabilityResults.every((_HostValidationResult result) => result.available)) {
      return ValidationResult(
          ValidationType.installed,
          messages..add(const ValidationMessage('All required HTTP hosts are available')));
    } else {
      availabilityResults.removeWhere((_HostValidationResult result) => result.available);

      for (final _HostValidationResult result in availabilityResults) {
        messages.add(ValidationMessage.error(
            'HTTP host ${result.host} is not reachable. Reason: ${result.failResultInfo}'));
      }

      return ValidationResult(ValidationType.partial, messages);
    }
  }
}

class _HostValidationResult {
  _HostValidationResult.success(this.host)
      : failResultInfo = '',
        available = true;

  _HostValidationResult.fail(this.host, this.failResultInfo)
      : available = false;

  final String failResultInfo;
  final String host;
  final bool available;
}
