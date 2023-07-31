import '../exception_handler/exceptions/cli_exception.dart';

extension StringExt on String {
  /// Removes all characters.
  /// ```
  /// var bestPackage = 'GetX'.removeAll('X');
  /// print(bestPackage) // Get;
  /// ```
  String removeAll(String value) {
    var newValue = replaceAll(value, '');
    //this =  newValue;
    return newValue;
  }

  /// Append the content of dart class
  /// ``` dart
  /// var newClassContent = '''abstract class Routes {
  ///  Routes._();
  ///
  ///}
  /// abstract class _Paths {
  ///  _Paths._();
  /// }'''.appendClassContent('Routes', 'static const HOME = _Paths.HOME;' );
  /// print(newClassContent);
  /// ```
  /// abstract class Routes {
  /// Routes._();
  /// static const HOME = _Paths.HOME;
  /// }
  /// abstract class _Paths {
  ///  _Paths._();
  /// }
  ///
  String appendClassContent(String className, String value) {
    var matches =
        RegExp('class $className {.*?(^})', multiLine: true, dotAll: true)
            .allMatches(this);
    //TODO: Add exception in the translations
    if (matches.isEmpty) {
      throw CliException('The class $className is not found in the file $this');
    } else if (matches.length > 1) {
      throw CliException(
          'The class $className is found more than once in the file $this');
    }
    var match = matches.first;
    return insert(match.end - 1, value);
  }

  String insert(int index, String value) {
    var newValue = substring(0, index) + value + substring(index);
    return newValue;
  }
}
