// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'base/io.dart';
import 'base/net.dart';
import 'base/platform.dart';
import 'doctor_validator.dart';
import 'features.dart';

/// Common Flutter HTTP hosts.
const kCloudHost = 'https://storage.googleapis.com/';
const kCocoaPods = 'https://cocoapods.org/';
const kGitHub = 'https://github.com/';
const kMaven = 'https://maven.google.com/';
const kPubDev = 'https://pub.dev/';

// Overridable environment variables.
const kPubDevOverride = 'PUB_HOSTED_URL'; // https://dart.dev/tools/pub/environment-variables

// Validator that checks all provided hosts are reachable and responsive
class HttpHostValidator extends DoctorValidator {
  HttpHostValidator({
    required Platform platform,
    required FeatureFlags featureFlags,
    required HttpClient httpClient,
  }) : _platform = platform,
       _featureFlags = featureFlags,
       _httpClient = httpClient,
       super('Network resources');

  final Platform _platform;
  final FeatureFlags _featureFlags;
  final HttpClient _httpClient;

  final _activeHosts = <Uri>{};

  @override
  String get slowWarning {
    if (_activeHosts.isEmpty) {
      return 'Network resources check is taking a long time...';
    }
    return 'Attempting to reach ${_activeHosts.map((Uri url) => url.host).join(", ")}...';
  }

  /// Make a head request to the HTTP host for checking availability
  Future<String?> _checkHostAvailability(Uri host) async {
    try {
      assert(!_activeHosts.contains(host));
      _activeHosts.add(host);
      final HttpClientRequest req = await _httpClient.headUrl(host);
      await req.close();
      // HTTP host is available if no exception happened.
      return null;
    } on SocketException catch (error) {
      return 'A network error occurred while checking "$host": ${error.message}';
    } on HttpException catch (error) {
      return 'An HTTP error occurred while checking "$host": ${error.message}';
    } on HandshakeException catch (error) {
      return 'A cryptographic error occurred while checking "$host": ${error.message}\n'
          'You may be experiencing a man-in-the-middle attack, your network may be '
          'compromised, or you may have malware installed on your computer.';
    } on OSError catch (error) {
      return 'An error occurred while checking "$host": ${error.message}';
    } finally {
      _activeHosts.remove(host);
    }
  }

  static Uri? _parseUrl(String value) {
    final Uri? url = Uri.tryParse(value);
    if (url == null ||
        !url.hasScheme ||
        !url.hasAuthority ||
        (!url.hasEmptyPath && !url.hasAbsolutePath) ||
        url.hasFragment) {
      return null;
    }
    return url;
  }

  @override
  Future<ValidationResult> validateImpl() async {
    final availabilityResults = <String?>[];

    final requiredHosts = <Uri>[];
    if (_platform.environment.containsKey(kPubDevOverride)) {
      final Uri? url = _parseUrl(_platform.environment[kPubDevOverride]!);
      if (url == null) {
        availabilityResults.add(
          'Environment variable $kPubDevOverride does not specify a valid URL: "${_platform.environment[kPubDevOverride]}"\n'
          'Please see https://flutter.dev/to/use-mirror-site for an example of how to use it.',
        );
      } else {
        requiredHosts.add(url);
      }
    } else {
      requiredHosts.add(Uri.parse(kPubDev));
    }
    if (_platform.environment.containsKey(kFlutterStorageBaseUrl)) {
      final Uri? url = _parseUrl(_platform.environment[kFlutterStorageBaseUrl]!);
      if (url == null) {
        availabilityResults.add(
          'Environment variable $kFlutterStorageBaseUrl does not specify a valid URL: "${_platform.environment[kFlutterStorageBaseUrl]}"\n'
          'Please see https://flutter.dev/to/use-mirror-site for an example of how to use it.',
        );
      } else {
        requiredHosts.add(url);
      }
    } else {
      requiredHosts.add(Uri.parse(kCloudHost));
      if (_featureFlags.isAndroidEnabled) {
        // if kFlutterStorageBaseUrl is set it is used instead of Maven
        requiredHosts.add(Uri.parse(kMaven));
      }
    }
    if (_featureFlags.isMacOSEnabled) {
      requiredHosts.add(Uri.parse(kCocoaPods));
    }
    requiredHosts.add(Uri.parse(kGitHub));

    // Check all the hosts simultaneously.
    availabilityResults.addAll(
      await Future.wait<String?>(requiredHosts.map(_checkHostAvailability)),
    );

    var failures = 0;
    var successes = 0;
    final messages = <ValidationMessage>[];
    for (final message in availabilityResults) {
      if (message == null) {
        successes += 1;
      } else {
        failures += 1;
        messages.add(ValidationMessage.error(message));
      }
    }

    if (failures == 0) {
      assert(successes > 0);
      assert(messages.isEmpty);
      return ValidationResult(ValidationType.success, const <ValidationMessage>[
        ValidationMessage('All expected network resources are available.'),
      ]);
    }
    assert(messages.isNotEmpty);
    return ValidationResult(
      successes == 0 ? ValidationType.notAvailable : ValidationType.partial,
      messages,
    );
  }
}
