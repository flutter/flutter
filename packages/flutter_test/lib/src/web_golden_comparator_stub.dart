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
  Future<bool> compare(double width, double height, Uri golden) {
    throw UnimplementedError('stub');
  }

  @override
  Future<void> update(double width, double height, Uri golden) {
    throw UnimplementedError('stub');
  }
}
