// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_tools/src/base/io.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:http/http.dart' as http;
// ignore: import_of_legacy_library_into_null_safe
import 'base/platform.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'doctor.dart';

/// Hosts used by flutter on all machines
const List<String> commonRequiredHostUrls = <String>[
  'https://cloud.google.com/',
  'https://maven.google.com/',
  'https://pub.dev/',
];

/// Hosts used only on MacOS
const List<String> macOsRequiredHostUrls = <String>[
  'https://cocoapods.org/',
];

/// Validation class that checks if all the given URLs are reachable
class HttpHostAvailabilityValidator extends DoctorValidator {
  HttpHostAvailabilityValidator({
    required Platform platform,
    required http.Client httpClient,
  })   : _platform = platform,
        _httpClient = httpClient,
        super('Host availability');

  final Platform _platform;
  final http.Client _httpClient;

  @override
  String get slowWarning => 'Host availability check is taking a long time';

  /// Returns a list of URLs to check availability, different for different platforms
  List<String> get _allRequiredHosts {
    if (_platform.isMacOS) {
      return commonRequiredHostUrls + macOsRequiredHostUrls;
    } else {
      return commonRequiredHostUrls;
    }
  }

  /// Make an HTTP HEAD request to the given URL. If there is no exception,
  /// the host is available. If there is an exception, return a failed result.
  Future<_HttpHostAvailabilityResult> _checkHostAvailability(
    String hostUrl,
  ) async {
    try {
      // Make the HEAD request
      await _httpClient.head(hostUrl);
      // If there is an error, it will be caught in the on ... catch blocks below.
      // Else return a successful result
      return _HttpHostAvailabilityResult.pass(hostUrl);
    } on SocketException catch (socketError) {
      // Return a failed result
      return _HttpHostAvailabilityResult.fail(hostUrl, socketError.toString());
    } on HttpException catch (httpError) {
      // Return a failed result
      return _HttpHostAvailabilityResult.fail(hostUrl, httpError.toString());
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
      messages.add(const ValidationMessage('All required hosts are available'));
      return ValidationResult(
        ValidationType.installed,
        messages,
      );
    } else {
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
        messages.add(ValidationMessage.error('${result.hostUrl} is not available due to the following error: ${result.errorMessage}'));
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
