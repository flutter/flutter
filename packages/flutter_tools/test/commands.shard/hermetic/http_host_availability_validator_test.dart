// @dart = 2.9
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/http_host_availability_validator.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../../src/common.dart';
import '../../src/fake_http_client.dart';

void main() {
  group('http host availability validator', () {
    const List<String> operatingSystemsToTest = <String>['windows', 'macos', 'linux'];

    test('all http hosts are available', () async {
      /// A mock HTTP client that returns a 200 Successful response for
      /// every request
      final FakeHttpClient mockClient = FakeHttpClient.any();

      // Run the check for all operating systems one by one
      for(final String operatingSystem in operatingSystemsToTest) {
        final HttpHostAvailabilityValidator httpHostValidator = HttpHostAvailabilityValidator(
          platform: FakePlatform(operatingSystem: operatingSystem),
          httpClient: mockClient,
        );

        // Run the validation check and get the results
        final ValidationResult result = await httpHostValidator.validate();

        // Check for only one information message
        expect(result.messages..removeWhere(
          (ValidationMessage message) => message.isHint || message.isError
        ), hasLength(1));
      }
    });

    test('all http hosts are not available', () async {
      // Run the check for all operating systems one by one
      for(final String operatingSystem in operatingSystemsToTest) {
        final HttpHostAvailabilityValidator httpHostValidator = HttpHostAvailabilityValidator(
          platform: FakePlatform(operatingSystem: operatingSystem),
          httpClient: FakeHttpClient.list(<FakeRequest>[
            FakeRequest(Uri.parse('https://cloud.google.com/'), method: HttpMethod.head, responseError: const OSError('Connection Reset by peer')),
            FakeRequest(Uri.parse('https://maven.google.com/'), method: HttpMethod.head, responseError: const OSError('Connection Reset by peer')),
            FakeRequest(Uri.parse('https://pub.dev/'), method: HttpMethod.head, responseError: const OSError('Connection Reset by peer')),
            FakeRequest(Uri.parse('https://cocoapods.org/'), method: HttpMethod.head, responseError: const OSError('Connection Reset by peer')),
          ]),
        );

        // Run the validation check and get the results
        final ValidationResult result = await httpHostValidator.validate();

        // Check that all messages are errors
        expect(result.messages..where(
          (ValidationMessage message) => message.isHint || message.isError
        ), equals(result.messages));
      }
    });

    test('one http host is not available', () async {
      // Run the check for all operating systems one by one
      for(final String operatingSystem in operatingSystemsToTest) {
        final HttpHostAvailabilityValidator httpHostValidator = HttpHostAvailabilityValidator(
          platform: FakePlatform(operatingSystem: operatingSystem),
          httpClient: FakeHttpClient.list(<FakeRequest>[
            FakeRequest(Uri.parse('https://cloud.google.com/'), method: HttpMethod.head, responseError: const OSError('Connection Reset by peer')),
            FakeRequest(Uri.parse('https://maven.google.com/'), method: HttpMethod.head),
            FakeRequest(Uri.parse('https://pub.dev/'), method: HttpMethod.head),
            FakeRequest(Uri.parse('https://cocoapods.org/'), method: HttpMethod.head),
          ]),
        );

        // Run the validation check and get the results
        final ValidationResult result = await httpHostValidator.validate();

        // Check that only one message is an error
        expect(result.messages..where(
          (ValidationMessage message) => message.isHint || message.isError
        ), hasLength(1));
      }
    });
  });
}