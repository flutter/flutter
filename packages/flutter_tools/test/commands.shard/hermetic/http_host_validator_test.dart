// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
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
          final Platform platform = FakePlatform(operatingSystem: os);
          final HttpHostValidator httpHostValidator = HttpHostValidator(
            platform: platform,
            featureFlags: TestFeatureFlags(),
            httpClient: FakeHttpClient.list(<FakeRequest>[
              FakeRequest(Uri.parse(kgCloudHttpHost), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
              FakeRequest(Uri.parse(androidRequiredHttpHosts(platform)[0]), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
              FakeRequest(Uri.parse(kPubDevHttpHost), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
              FakeRequest(Uri.parse(macOSRequiredHttpHosts[0]), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
            ]),
          );

          // Run the validation check and get the results
          final ValidationResult result = await httpHostValidator.validate();

          // Check for a ValidationType.notAvailable result
          expect(result.type, equals(ValidationType.notAvailable));
        }
      });

      testWithoutContext('one http host is not available', () async {
        // Run the check for all operating systems one by one
        for(final String os in osTested) {
          final Platform platform = FakePlatform(operatingSystem: os);
          final HttpHostValidator httpHostValidator = HttpHostValidator(
            platform: platform,
            featureFlags: TestFeatureFlags(),
            httpClient: FakeHttpClient.list(<FakeRequest>[
              FakeRequest(Uri.parse(kgCloudHttpHost), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
              FakeRequest(Uri.parse(androidRequiredHttpHosts(platform)[0]), method: HttpMethod.head),
              FakeRequest(Uri.parse(kPubDevHttpHost), method: HttpMethod.head),
              FakeRequest(Uri.parse(macOSRequiredHttpHosts[0]), method: HttpMethod.head),
            ]),
          );

          // Run the validation check and get the results
          final ValidationResult result = await httpHostValidator.validate();

          // Check for a ValidationType.partial result
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
          final Platform platform = FakePlatform(operatingSystem: os, environment: kTestEnvironment);
          final HttpHostValidator httpHostValidator = HttpHostValidator(
            platform: platform,
            featureFlags: TestFeatureFlags(),
            httpClient: FakeHttpClient.list(<FakeRequest>[
              FakeRequest(Uri.parse(kTestEnvGCloudHost), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
              FakeRequest(Uri.parse(kTestEnvPubHost), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
              FakeRequest(Uri.parse(macOSRequiredHttpHosts[0]), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
            ]),
          );

          // Run the validation check and get the results
          final ValidationResult result = await httpHostValidator.validate();

          // Check for a ValidationType.notAvailable result
          expect(result.type, equals(ValidationType.notAvailable));
        }
      });

      testWithoutContext('one http host is not available', () async {
        // Run the check for all operating systems one by one
        for(final String os in osTested) {
          final Platform platform = FakePlatform(operatingSystem: os, environment: kTestEnvironment);
          final HttpHostValidator httpHostValidator = HttpHostValidator(
            platform: platform,
            featureFlags: TestFeatureFlags(),
            httpClient: FakeHttpClient.list(<FakeRequest>[
              FakeRequest(Uri.parse(kTestEnvGCloudHost), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
              FakeRequest(Uri.parse(kTestEnvPubHost), method: HttpMethod.head),
              FakeRequest(Uri.parse(macOSRequiredHttpHosts[0]), method: HttpMethod.head),
            ]),
          );

          // Run the validation check and get the results
          final ValidationResult result = await httpHostValidator.validate();

          // Check for a ValidationType.partial result
          expect(result.type, equals(ValidationType.partial));
        }
      });

      testWithoutContext('does not throw on invalid user-defined timeout', () async {
        final HttpHostValidator httpHostValidator = HttpHostValidator(
          platform: FakePlatform(
            environment: <String,String> {
              'PUB_HOSTED_URL': kTestEnvPubHost,
              'FLUTTER_STORAGE_BASE_URL': kTestEnvGCloudHost,
              'FLUTTER_DOCTOR_HOST_TIMEOUT' : 'deadbeef',
            },
          ),
          featureFlags: TestFeatureFlags(isAndroidEnabled: false),
          httpClient: FakeHttpClient.any(),
        );

        // Run the validation check and get the results
        final ValidationResult result = await httpHostValidator.validate();

        expect(result.type, equals(ValidationType.notAvailable));
        expect(
          result.messages,
          contains(const ValidationMessage.error(
            'HTTP host "$kTestEnvPubHost" is not reachable. '
            'Reason: The value of FLUTTER_DOCTOR_HOST_TIMEOUT(deadbeef) is not a valid duration in seconds',
          )),
        );
      });

      testWithoutContext('does not throw on unparseable user-defined host uri', () async {
        final HttpHostValidator httpHostValidator = HttpHostValidator(
          platform: FakePlatform(
            environment: <String,String> {
              'PUB_HOSTED_URL': '::Not A Uri::',
              'FLUTTER_STORAGE_BASE_URL': kTestEnvGCloudHost,
              'FLUTTER_DOCTOR_HOST_TIMEOUT' : '1',
            },
          ),
          featureFlags: TestFeatureFlags(isAndroidEnabled: false),
          httpClient: FakeHttpClient.any(),
        );

        // Run the validation check and get the results
        final ValidationResult result = await httpHostValidator.validate();

        expect(result.type, equals(ValidationType.partial));
        expect(
          result.messages,
          contains(const ValidationMessage.error(
            'HTTP host "::Not A Uri::" is not reachable. '
            'Reason: The value of PUB_HOSTED_URL(::Not A Uri::) could not be parsed as a valid url',
          )),
        );
      });

      testWithoutContext('does not throw on invalid user-defined host', () async {
        final HttpHostValidator httpHostValidator = HttpHostValidator(
          platform: FakePlatform(
            environment: <String,String> {
              'PUB_HOSTED_URL': kTestEnvPubHost,
              'FLUTTER_STORAGE_BASE_URL': '',
              'FLUTTER_DOCTOR_HOST_TIMEOUT' : '1',
            },
          ),
          featureFlags: TestFeatureFlags(isAndroidEnabled: false),
          httpClient: FakeHttpClient.any(),
        );

        // Run the validation check and get the results
        final ValidationResult result = await httpHostValidator.validate();

        expect(result.type, equals(ValidationType.partial));
        expect(
          result.messages,
          contains(const ValidationMessage.error(
            'HTTP host "" is not reachable. '
            'Reason: The value of FLUTTER_STORAGE_BASE_URL() is not a valid host',
          )),
        );
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
          final Platform platform = FakePlatform(operatingSystem: os);
          final HttpHostValidator httpHostValidator = HttpHostValidator(
            platform: platform,
            featureFlags: TestFeatureFlags(isIOSEnabled: false),
            httpClient: FakeHttpClient.list(<FakeRequest>[
              FakeRequest(Uri.parse(kgCloudHttpHost), method: HttpMethod.head),
              FakeRequest(Uri.parse(kPubDevHttpHost), method: HttpMethod.head),
              FakeRequest(Uri.parse(androidRequiredHttpHosts(platform)[0]), method: HttpMethod.head),
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

  testWithoutContext('Does not throw on HandshakeException', () async {
    const String handshakeMessage = '''
Handshake error in client (OS Error:
        BLOCK_TYPE_IS_NOT_01(../../third_party/boringssl/src/crypto/fipsmodule/rsa/padding.c:108)
        PADDING_CHECK_FAILED(../../third_party/boringssl/src/crypto/fipsmodule/rsa/rsa_impl.c:676)
        public key routines(../../third_party/boringssl/src/crypto/x509/a_verify.c:108)
        CERTIFICATE_VERIFY_FAILED: certificate signature failure(../../third_party/boringssl/src/ssl/handshake.cc:393))
''';
    final HttpHostValidator httpHostValidator = HttpHostValidator(
      platform: FakePlatform(environment: kTestEnvironment),
      featureFlags: TestFeatureFlags(isAndroidEnabled: false),
      httpClient: FakeHttpClient.list(<FakeRequest>[
        FakeRequest(
          Uri.parse(kTestEnvPubHost),
          method: HttpMethod.head,
          responseError: const HandshakeException(handshakeMessage),
        ),
        FakeRequest(Uri.parse(kTestEnvGCloudHost), method: HttpMethod.head),
      ]),
    );

    // Run the validation check and get the results
    final ValidationResult result = await httpHostValidator.validate();

    expect(
      result.messages.first,
      isA<ValidationMessage>().having(
        (ValidationMessage msg) => msg.message,
        'message',
        contains(handshakeMessage),
      ),
    );
  });

  testWithoutContext('Http host validator timeout message includes timeout duration.', () async {
    final HttpHostValidator httpHostValidator = HttpHostValidator(
      platform: FakePlatform(environment: kTestEnvironment),
      featureFlags: TestFeatureFlags(isAndroidEnabled: false),
      httpClient: FakeHttpClient.list(<FakeRequest>[
        FakeRequest(Uri.parse(kTestEnvPubHost), method: HttpMethod.head, responseError: TimeoutException('Timeout error')),
        FakeRequest(Uri.parse(kTestEnvGCloudHost), method: HttpMethod.head),
      ]),
    );

    // Run the validation check and get the results
    final ValidationResult result = await httpHostValidator.validate();

    // Timeout duration for tests is set to 1 second
    expect(
      result.messages,
      contains(const ValidationMessage.error('HTTP host "$kTestEnvPubHost" is not reachable. Reason: Failed to connect to host in 1 second')),
    );
  });
}
