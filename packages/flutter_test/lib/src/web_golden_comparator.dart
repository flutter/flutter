import 'dart:convert';
import 'dart:html' as html;

import 'package:matcher/expect.dart' show fail;

import 'goldens.dart';

/// The default [WebGoldenComparator] implementation for `flutter test`.
///
/// This comparator will send a request to the test server for golden comparison
/// which will then defer the comparison to [goldenFileComparator].
///
/// See also:
///
///   * [matchesGoldenFile], the function from [flutter_test] that invokes the
///    comparator.
class DefaultWebGoldenComparator extends WebGoldenComparator {
  /// Creates a new [DefaultWebGoldenComparator] for the specified [testFile].
  ///
  /// Golden file keys will be interpreted as file paths relative to the
  /// directory in which [testFile] resides.
  ///
  /// The [testFile] URL must represent a file.
  DefaultWebGoldenComparator(this.testUri);

  /// The test file currently being executed.
  ///
  /// Golden file keys will be interpreted as file paths relative to the
  /// directory in which this file resides.
  Uri testUri;

  @override
  Future<bool> compare(double width, double height, Uri golden) async {
    final html.HttpRequest request = await html.HttpRequest.request(
      'flutter_screenshot',
      sendData: json.encode(<String, Object>{
        'width': width.round(),
        'height': height.round(),
      }),
    );
    final String response = request.response as String;
    if (response == 'true') {
      return true;
    }
    fail(response);
  }

  @override
  Future<void> update(double width, double height, Uri golden) async {
    // Update is handled on the server side, just use the same logic here
    await compare(width, height, golden);
  }
}
