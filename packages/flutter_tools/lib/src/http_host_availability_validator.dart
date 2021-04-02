// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.9

import 'base/io.dart';
import 'base/platform.dart';
import 'doctor.dart';
import 'features.dart';

// The environment variables used to override some URLs
const String kPubHostedUrl = 'PUB_HOSTED_URL';
const String kCloudUrl = 'FLUTTER_STORAGE_BASE_URL';

/// Validation class that checks if all the given URLs are reachable
class HttpHostAvailabilityValidator extends DoctorValidator {
  HttpHostAvailabilityValidator({
    Platform platform,
    FeatureFlags featureFlags,
    HttpClient httpClient,
  })   : _platform = platform,
        _featureFlags = featureFlags,
        _httpClient = httpClient,
        super('HTTP host availability');

  final Platform _platform;
  final FeatureFlags _featureFlags;
  final HttpClient _httpClient;

  @override
  String get slowWarning => 'HTTP host availability check is taking a long time';

  /// Returns a list of URLs to check availability, different for different platforms
  List<String> get _allRequiredHosts {
    /// Hosts used by flutter
    final List<String> requiredHostUrls = <String>[
      if (_featureFlags.isAndroidEnabled)
        'https://maven.google.com/',
      if (_featureFlags.isIOSEnabled)
        'https://cocoapods.org/',
      if (_platform.environment.containsKey(kCloudUrl))
        _platform.environment[kCloudUrl]
      else
        'https://cloud.google.com/',
      if (_platform.environment.containsKey(kPubHostedUrl))
        _platform.environment[kPubHostedUrl]
      else
        'https://pub.dev/',
    ];

    return requiredHostUrls;
  }

  /// Make an HTTP HEAD request to the given URL. If there is no exception,
  /// the host is available. If there is an exception, return a failed result.
  Future<_HttpHostAvailabilityResult> _checkHostAvailability(
    String hostUrl,
  ) async {
    try {
      // Make the HEAD request
      final HttpClientRequest headReq = await _httpClient.headUrl(Uri.parse(hostUrl));
      await headReq.close();

      // If there is an error, it will be caught in the on ... catch blocks below.
      // Else return a successful result
      return _HttpHostAvailabilityResult.pass(hostUrl);
    } on SocketException catch (socketError) {
      // Return a failed result
      return _HttpHostAvailabilityResult.fail(hostUrl, socketError.message);
    } on HttpException catch (httpError) {
      // Return a failed result
      return _HttpHostAvailabilityResult.fail(hostUrl, httpError.message);
    } on OSError catch (osError) {
      // Return a failed result
      return _HttpHostAvailabilityResult.fail(hostUrl, osError.message);
    }
  }

  /// Verify that all specified host URLs are reachable
  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];

    // Run the _checkHostAvailability function for each host URL
    final List<_HttpHostAvailabilityResult> availabilityResults =
        await Future.wait(_allRequiredHosts.map(_checkHostAvailability));

    // If all tests pass, return a successfull ValidationResult
    if (availabilityResults
        .every((_HttpHostAvailabilityResult result) => result.hostAvailable)) {
      // Add a success message and then send back the result
      messages.add(const ValidationMessage('All required HTTP hosts are available'));
      return ValidationResult(
        ValidationType.installed,
        messages,
      );
    }

    // Else not all URLs are available. Get the number of URLs that are not
    // available
    final int unavailableUrls = availabilityResults
      .where((_HttpHostAvailabilityResult result) => !result.hostAvailable).length;
    final int totalUrls = availabilityResults.length;

    // Filter the list to only include those that have not passed
    availabilityResults
      .removeWhere((_HttpHostAvailabilityResult result) => result.hostAvailable);

    // Add the error messages to be displayed
    for (final _HttpHostAvailabilityResult result in availabilityResults) {
      messages.add(ValidationMessage.error('HTTP host ${result.hostUrl} is not available: ${result.errorMessage}'));
    }

    // Return a partially successfull or completely errored result
    return ValidationResult(
      unavailableUrls == totalUrls
        ? ValidationType.notAvailable
        : ValidationType.partial,
      messages
    );
  }
}

/// Result of a host availability check
class _HttpHostAvailabilityResult {
  /// Return a successful result for an available host
  _HttpHostAvailabilityResult.pass(this.hostUrl)
      : errorMessage = '',
        hostAvailable = true;
  /// Return a failed result for an unavailable host
  _HttpHostAvailabilityResult.fail(this.hostUrl, this.errorMessage)
      : hostAvailable = false;

  /// The URL
  final String hostUrl;
  // The error message, if any
  final String errorMessage;
  // Whether or not the host is available
  final bool hostAvailable;
}
