// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/http_host_validator.dart';

import '../../src/common.dart';
import '../../src/fake_http_client.dart';
import '../../src/fakes.dart';

// The environment variables used to override some URLs
const String kTestEnvPubHost = 'https://pub.flutter-io.cn';
const String kTestEnvGCloudHost = 'https://storage.flutter-io.cn';
const Map<String, String> kTestEnvironment = <String, String>{
  'PUB_HOSTED_URL': kTestEnvPubHost,
  'FLUTTER_STORAGE_BASE_URL': kTestEnvGCloudHost,
  'FLUTTER_DOCTOR_HOST_TIMEOUT': '1',
};

void main() {
  group('http host validator', () {
    const List<String> osTested = <String>['windows', 'macos', 'linux'];

    group('no env variables', () {
      testWithoutContext('all http hosts are available', () async {
        final FakeHttpClient mockClient = FakeHttpClient.any();

        // Run the check for all operating systems one by one
        for(final String os in osTested) {
          final HttpHostValidator httpHostValidator = HttpHostValidator(
            platform: FakePlatform(operatingSystem: os),
            featureFlags: TestFeatureFlags(),
            httpClient: mockClient,
          );

          // Run the validation check and get the results
          final ValidationResult result = await httpHostValidator.validate();

          // Check for a ValidationType.installed result
          expect(result.type, equals(ValidationType.installed));
        }
      });

      testWithoutContext('all http hosts are not available', () async {
        // Run the check for all operating systems one by one
        for(final String os in osTested) {
          final HttpHostValidator httpHostValidator = HttpHostValidator(
            platform: FakePlatform(operatingSystem: os),
            featureFlags: TestFeatureFlags(),
            httpClient: FakeHttpClient.list(<FakeRequest>[
              FakeRequest(Uri.parse(kgCloudHttpHost), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
              FakeRequest(Uri.parse(androidRequiredHttpHosts[0]), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
              FakeRequest(Uri.parse(kPubDevHttpHost), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
              FakeRequest(Uri.parse(macOSRequiredHttpHosts[0]), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
            ]),
          );

          // Run the validation check and get the results
          final ValidationResult result = await httpHostValidator.validate();

          // Check for a ValidationType.installed result
          expect(result.type, equals(ValidationType.notAvailable));
        }
      });

      testWithoutContext('one http hosts are not available', () async {
        // Run the check for all operating systems one by one
        for(final String os in osTested) {
          final HttpHostValidator httpHostValidator = HttpHostValidator(
            platform: FakePlatform(operatingSystem: os),
            featureFlags: TestFeatureFlags(),
            httpClient: FakeHttpClient.list(<FakeRequest>[
              FakeRequest(Uri.parse(kgCloudHttpHost), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
              FakeRequest(Uri.parse(androidRequiredHttpHosts[0]), method: HttpMethod.head),
              FakeRequest(Uri.parse(kPubDevHttpHost), method: HttpMethod.head),
              FakeRequest(Uri.parse(macOSRequiredHttpHosts[0]), method: HttpMethod.head),
            ]),
          );

          // Run the validation check and get the results
          final ValidationResult result = await httpHostValidator.validate();

          // Check for a ValidationType.installed result
          expect(result.type, equals(ValidationType.partial));
        }
      });

      testWithoutContext('one http hosts are not available', () async {
        // Run the check for all operating systems one by one
        for(final String os in osTested) {
          final HttpHostValidator httpHostValidator = HttpHostValidator(
            platform: FakePlatform(operatingSystem: os),
            featureFlags: TestFeatureFlags(),
            httpClient: FakeHttpClient.list(<FakeRequest>[
              FakeRequest(Uri.parse(kgCloudHttpHost), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
              FakeRequest(Uri.parse(androidRequiredHttpHosts[0]), method: HttpMethod.head),
              FakeRequest(Uri.parse(kPubDevHttpHost), method: HttpMethod.head),
              FakeRequest(Uri.parse(macOSRequiredHttpHosts[0]), method: HttpMethod.head),
            ]),
          );

          // Run the validation check and get the results
          final ValidationResult result = await httpHostValidator.validate();

          // Check for a ValidationType.installed result
          expect(result.type, equals(ValidationType.partial));
        }
      });
    });

    group('with env variables', () {
      testWithoutContext('all http hosts are available', () async {
        final FakeHttpClient mockClient = FakeHttpClient.any();

        // Run the check for all operating systems one by one
        for(final String os in osTested) {
          final HttpHostValidator httpHostValidator = HttpHostValidator(
            platform: FakePlatform(operatingSystem: os, environment: kTestEnvironment),
            featureFlags: TestFeatureFlags(),
            httpClient: mockClient,
          );

          // Run the validation check and get the results
          final ValidationResult result = await httpHostValidator.validate();

          // Check for a ValidationType.installed result
          expect(result.type, equals(ValidationType.installed));
        }
      });

      testWithoutContext('all http hosts are not available', () async {
        // Run the check for all operating systems one by one
        for(final String os in osTested) {
          final HttpHostValidator httpHostValidator = HttpHostValidator(
            platform: FakePlatform(operatingSystem: os, environment: kTestEnvironment),
            featureFlags: TestFeatureFlags(),
            httpClient: FakeHttpClient.list(<FakeRequest>[
              FakeRequest(Uri.parse(kTestEnvGCloudHost), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
              FakeRequest(Uri.parse(androidRequiredHttpHosts[0]), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
              FakeRequest(Uri.parse(kTestEnvPubHost), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
              FakeRequest(Uri.parse(macOSRequiredHttpHosts[0]), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
            ]),
          );

          // Run the validation check and get the results
          final ValidationResult result = await httpHostValidator.validate();

          // Check for a ValidationType.installed result
          expect(result.type, equals(ValidationType.notAvailable));
        }
      });

      testWithoutContext('one http hosts are not available', () async {
        // Run the check for all operating systems one by one
        for(final String os in osTested) {
          final HttpHostValidator httpHostValidator = HttpHostValidator(
            platform: FakePlatform(operatingSystem: os, environment: kTestEnvironment),
            featureFlags: TestFeatureFlags(),
            httpClient: FakeHttpClient.list(<FakeRequest>[
              FakeRequest(Uri.parse(kTestEnvGCloudHost), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
              FakeRequest(Uri.parse(androidRequiredHttpHosts[0]), method: HttpMethod.head),
              FakeRequest(Uri.parse(kTestEnvPubHost), method: HttpMethod.head),
              FakeRequest(Uri.parse(macOSRequiredHttpHosts[0]), method: HttpMethod.head),
            ]),
          );

          // Run the validation check and get the results
          final ValidationResult result = await httpHostValidator.validate();

          // Check for a ValidationType.installed result
          expect(result.type, equals(ValidationType.partial));
        }
      });

      testWithoutContext('one http hosts are not available', () async {
        // Run the check for all operating systems one by one
        for(final String os in osTested) {
          final HttpHostValidator httpHostValidator = HttpHostValidator(
            platform: FakePlatform(operatingSystem: os, environment: kTestEnvironment),
            featureFlags: TestFeatureFlags(),
            httpClient: FakeHttpClient.list(<FakeRequest>[
              FakeRequest(Uri.parse(kTestEnvGCloudHost), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
              FakeRequest(Uri.parse(androidRequiredHttpHosts[0]), method: HttpMethod.head),
              FakeRequest(Uri.parse(kTestEnvPubHost), method: HttpMethod.head),
              FakeRequest(Uri.parse(macOSRequiredHttpHosts[0]), method: HttpMethod.head),
            ]),
          );

          // Run the validation check and get the results
          final ValidationResult result = await httpHostValidator.validate();

          // Check for a ValidationType.installed result
          expect(result.type, equals(ValidationType.partial));
        }
      });
    });

    group('specific os disabled', () {
      testWithoutContext('all http hosts are available - android disabled', () async {
        // Run the check for all operating systems one by one
        for(final String os in osTested) {
          final HttpHostValidator httpHostValidator = HttpHostValidator(
            platform: FakePlatform(operatingSystem: os),
            featureFlags: TestFeatureFlags(isAndroidEnabled: false),
            httpClient: FakeHttpClient.list(<FakeRequest>[
              FakeRequest(Uri.parse(kgCloudHttpHost), method: HttpMethod.head),
              FakeRequest(Uri.parse(kPubDevHttpHost), method: HttpMethod.head),
              FakeRequest(Uri.parse(macOSRequiredHttpHosts[0]), method: HttpMethod.head),
            ]),
          );

          // Run the validation check and get the results
          final ValidationResult result = await httpHostValidator.validate();

          // Check for a ValidationType.installed result
          expect(result.type, equals(ValidationType.installed));
        }
      });

      testWithoutContext('all http hosts are available - iOS disabled', () async {
        // Run the check for all operating systems one by one
        for(final String os in osTested) {
          final HttpHostValidator httpHostValidator = HttpHostValidator(
            platform: FakePlatform(operatingSystem: os),
            featureFlags: TestFeatureFlags(isIOSEnabled: false),
            httpClient: FakeHttpClient.list(<FakeRequest>[
              FakeRequest(Uri.parse(kgCloudHttpHost), method: HttpMethod.head),
              FakeRequest(Uri.parse(kPubDevHttpHost), method: HttpMethod.head),
              FakeRequest(Uri.parse(androidRequiredHttpHosts[0]), method: HttpMethod.head),
            ]),
          );

          // Run the validation check and get the results
          final ValidationResult result = await httpHostValidator.validate();

          // Check for a ValidationType.installed result
          expect(result.type, equals(ValidationType.installed));
        }
      });

      testWithoutContext('all http hosts are available - android, iOS disabled', () async {
        // Run the check for all operating systems one by one
        for(final String os in osTested) {
          final HttpHostValidator httpHostValidator = HttpHostValidator(
            platform: FakePlatform(operatingSystem: os),
            featureFlags: TestFeatureFlags(isAndroidEnabled: false, isIOSEnabled: false),
            httpClient: FakeHttpClient.list(<FakeRequest>[
              FakeRequest(Uri.parse(kgCloudHttpHost), method: HttpMethod.head),
              FakeRequest(Uri.parse(kPubDevHttpHost), method: HttpMethod.head),
            ]),
          );

          // Run the validation check and get the results
          final ValidationResult result = await httpHostValidator.validate();

          // Check for a ValidationType.installed result
          expect(result.type, equals(ValidationType.installed));
        }
      });
    });
  });
}
