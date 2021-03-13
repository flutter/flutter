// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_tools/src/base/io.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/http_host_availability_validator.dart';
import 'package:flutter_tools/src/base/platform.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:http/http.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:http/testing.dart';

// ignore: import_of_legacy_library_into_null_safe
import '../../src/common.dart';

void main() {
  group('http host availability validator', () {
    const List<String> operatingSystemsToTest = <String>['windows', 'macos', 'linux'];

    test('all http hosts are available', () async {
      /// A mock HTTP client that returns a 200 Successful response for
      /// every request
      final Client mockClient = MockClient((Request request) async {
        return Response('', 200);
      });

      // Run the check for all operating systems one by one
      for(final String operatingSystem in operatingSystemsToTest) {
        final HttpHostAvailabilityValidator httpHostValidator = HttpHostAvailabilityValidator(
          platform: FakePlatform(operatingSystem: operatingSystem),
          httpClient: mockClient,
        );

        // Run the validation check and get the results
        final ValidationResult result = await httpHostValidator.validate();

        // Check for only one information message
        expect(result.messages..where(
          (ValidationMessage message) => message.isHint || message.isError
        ), hasLength(0));
      }
    });

    test('all http hosts are not available', () async {
      /// A mock HTTP client that returns an error for every request
      final Client mockClient = MockClient((Request request) async {
        throw const SocketException('No internet connection');
      });

      // Run the check for all operating systems one by one
      for(final String operatingSystem in operatingSystemsToTest) {
        final HttpHostAvailabilityValidator httpHostValidator = HttpHostAvailabilityValidator(
          platform: FakePlatform(operatingSystem: operatingSystem),
          httpClient: mockClient,
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
      bool throwExceptionForThisCase = false;
      // A mock client that throws an exception for only the first
      // request made
      final Client mockClient = MockClient((Request request) async {
        if (throwExceptionForThisCase) {
          return Response('', 200);
        } else {
          throwExceptionForThisCase = true;
          throw const SocketException('No internet connection');
        }
      });

      // Run the check for all operating systems one by one
      for(final String operatingSystem in operatingSystemsToTest) {
        final HttpHostAvailabilityValidator httpHostValidator = HttpHostAvailabilityValidator(
          platform: FakePlatform(operatingSystem: operatingSystem),
          httpClient: mockClient,
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