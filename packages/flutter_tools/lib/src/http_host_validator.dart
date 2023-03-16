// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'base/io.dart';
import 'base/platform.dart';
import 'doctor_validator.dart';
import 'features.dart';

// Overridable environment variables
const String kEnvPubHostedUrl = 'PUB_HOSTED_URL';
const String kEnvCloudUrl = 'FLUTTER_STORAGE_BASE_URL';
const String kDoctorHostTimeout = 'FLUTTER_DOCTOR_HOST_TIMEOUT';

/// Common Flutter HTTP hosts.
const String kPubDevHttpHost = 'https://pub.dev/';
const String kgCloudHttpHost = 'https://cloud.google.com/';

/// MacOS specific required HTTP hosts.
const List<String> macOSRequiredHttpHosts = <String>[
  'https://cocoapods.org/',
];

/// Android specific required HTTP hosts.
List<String> androidRequiredHttpHosts(Platform platform) {
  return <String>[
    // If kEnvCloudUrl is set, it will be used as the maven host
    if (!platform.environment.containsKey(kEnvCloudUrl))
      'https://maven.google.com/',
  ];
}

// Validator that checks all provided hosts are reachable and responsive
class HttpHostValidator extends DoctorValidator {
  HttpHostValidator({
    required Platform platform,
    required FeatureFlags featureFlags,
    required HttpClient httpClient,
  }) : _platform = platform,
      _featureFlags = featureFlags,
      _httpClient = httpClient,
      super('HTTP Host Availability');

  final Platform _platform;
  final FeatureFlags _featureFlags;
  final HttpClient _httpClient;

  @override
  String get slowWarning => 'HTTP Host availability check is taking a long time...';

  List<String> get _requiredHosts => <String>[
    if (_featureFlags.isMacOSEnabled) ...macOSRequiredHttpHosts,
    if (_featureFlags.isAndroidEnabled) ...androidRequiredHttpHosts(_platform),
    _platform.environment[kEnvPubHostedUrl] ?? kPubDevHttpHost,
    _platform.environment[kEnvCloudUrl] ?? kgCloudHttpHost,
  ];

  /// Make a head request to the HTTP host for checking availability
  Future<_HostValidationResult> _checkHostAvailability(String host) async {
    late final int timeout;
    try {
      timeout = int.parse(_platform.environment[kDoctorHostTimeout] ?? '10');
      final HttpClientRequest req = await _httpClient.headUrl(Uri.parse(host));
      await req.close().timeout(Duration(seconds: timeout));
      // HTTP host is available if no exception happened
      return _HostValidationResult.success(host);
    } on TimeoutException {
      return _HostValidationResult.fail(host, 'Failed to connect to host in $timeout second${timeout == 1 ? '': 's'}');
    } on SocketException catch (e) {
      return _HostValidationResult.fail(host, 'An error occurred while checking the HTTP host: ${e.message}');
    } on HttpException catch (e) {
      return _HostValidationResult.fail(host, 'An error occurred while checking the HTTP host: ${e.message}');
    } on HandshakeException catch (e) {
      return _HostValidationResult.fail(host, 'An error occurred while checking the HTTP host: ${e.message}');
    } on OSError catch (e) {
      return _HostValidationResult.fail(host, 'An error occurred while checking the HTTP host: ${e.message}');
    } on FormatException catch (e) {
      if (e.message.contains('Invalid radix-10 number')) {
        return _HostValidationResult.fail(host, 'The value of $kDoctorHostTimeout(${_platform.environment[kDoctorHostTimeout]}) is not a valid duration in seconds');
      } else if (e.message.contains('Invalid empty scheme')){
        // Check if the invalid host is kEnvPubHostedUrl, else it must be kEnvCloudUrl
        final String? pubHostedUrl = _platform.environment[kEnvPubHostedUrl];
        if (pubHostedUrl != null && host == pubHostedUrl) {
          return _HostValidationResult.fail(host, 'The value of $kEnvPubHostedUrl(${_platform.environment[kEnvPubHostedUrl]}) could not be parsed as a valid url');
        }
        return _HostValidationResult.fail(host, 'The value of $kEnvCloudUrl(${_platform.environment[kEnvCloudUrl]}) could not be parsed as a valid url');
      }
      return _HostValidationResult.fail(host, 'An error occurred while checking the HTTP host: ${e.message}');
    } on ArgumentError catch (e) {
      final String exceptionMessage = e.message.toString();
      if (exceptionMessage.contains('No host specified')) {
        // Check if the invalid host is kEnvPubHostedUrl, else it must be kEnvCloudUrl
        final String? pubHostedUrl = _platform.environment[kEnvPubHostedUrl];
        if (pubHostedUrl != null && host == pubHostedUrl) {
          return _HostValidationResult.fail(host, 'The value of $kEnvPubHostedUrl(${_platform.environment[kEnvPubHostedUrl]}) is not a valid host');
        }
        return _HostValidationResult.fail(host, 'The value of $kEnvCloudUrl(${_platform.environment[kEnvCloudUrl]}) is not a valid host');
      }
      return _HostValidationResult.fail(host, 'An error occurred while checking the HTTP host: $exceptionMessage');
    }
  }

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    final Iterable<Future<_HostValidationResult>> availabilityResultFutures = _requiredHosts.map(_checkHostAvailability);
    final List<_HostValidationResult> availabilityResults = await Future.wait(availabilityResultFutures);

    if (availabilityResults.every((_HostValidationResult result) => result.available)) {
      return ValidationResult(
          ValidationType.installed,
          messages..add(const ValidationMessage('All required HTTP hosts are available')),
      );
    }

    availabilityResults.removeWhere((_HostValidationResult result) => result.available);

    for (final _HostValidationResult result in availabilityResults) {
      messages.add(ValidationMessage.error('HTTP host "${result.host}" is not reachable. Reason: ${result.failResultInfo}'));
    }

    return ValidationResult(
      availabilityResults.length == _requiredHosts.length
        ? ValidationType.notAvailable
        : ValidationType.partial,
      messages,
    );
  }
}

class _HostValidationResult {
  _HostValidationResult.success(this.host)
    : failResultInfo = '',
      available = true;

  _HostValidationResult.fail(this.host, this.failResultInfo) : available = false;

  final String failResultInfo;
  final String host;
  final bool available;
}
