// @dart = 2.9
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/http_host_availability_validator.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../../src/common.dart';
import '../../src/fake_http_client.dart';

// The environment variables used to override some URLs
const String kPubHostedUrl = 'PUB_HOSTED_URL';
const String kCloudUrl = 'FLUTTER_STORAGE_BASE_URL';

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

        // Check for a ValidationType.installed result
        expect(result.type, equals(ValidationType.installed));
      }
    });

    test('all http hosts are not available', () async {
      // Run the check for all operating systems one by one
      for(final String operatingSystem in operatingSystemsToTest) {
        final HttpHostAvailabilityValidator httpHostValidator = HttpHostAvailabilityValidator(
          platform: FakePlatform(operatingSystem: operatingSystem),
          httpClient: FakeHttpClient.list(<FakeRequest>[
            FakeRequest(Uri.parse('https://cloud.google.com/'), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
            FakeRequest(Uri.parse('https://maven.google.com/'), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
            FakeRequest(Uri.parse('https://pub.dev/'), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
            FakeRequest(Uri.parse('https://cocoapods.org/'), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
          ]),
        );

        // Run the validation check and get the results
        final ValidationResult result = await httpHostValidator.validate();

        // Check for a ValidationType.notAvailable result
        expect(result.type, equals(ValidationType.notAvailable));
      }
    });

    test('one http host is not available', () async {
      // Run the check for all operating systems one by one
      for(final String operatingSystem in operatingSystemsToTest) {
        final HttpHostAvailabilityValidator httpHostValidator = HttpHostAvailabilityValidator(
          platform: FakePlatform(operatingSystem: operatingSystem),
          httpClient: FakeHttpClient.list(<FakeRequest>[
            FakeRequest(Uri.parse('https://cloud.google.com/'), method: HttpMethod.head, responseError: const OSError('Name or service not known', -2)),
            FakeRequest(Uri.parse('https://maven.google.com/'), method: HttpMethod.head),
            FakeRequest(Uri.parse('https://pub.dev/'), method: HttpMethod.head),
            FakeRequest(Uri.parse('https://cocoapods.org/'), method: HttpMethod.head),
          ]),
        );

        // Run the validation check and get the results
        final ValidationResult result = await httpHostValidator.validate();

        // Check for a ValidationType.partial result
        expect(result.type, equals(ValidationType.partial));
      }
    });
  });
}
