import 'package:meta/meta.dart';
import 'package:petitparser/core.dart' show Token;

/// Mixin for exceptions that follow the [FormatException] of Dart.
mixin XmlFormatException implements FormatException {
  /// The input buffer which caused the error, or `null` if not available.
  String? get buffer;

  /// The offset in [buffer] where the error was detected, or `null` if no
  /// location information is available.
  int? get position;

  /// The line number where the parser error was detected, or `0` if no
  /// location information is available.
  late final int line = _lineAndColumn[0];

  /// The column number where the parser error was detected, or `0` if no
  /// location information is available.
  late final int column = _lineAndColumn[1];

  /// Internal cache of line and column of the error.
  late final List<int> _lineAndColumn = buffer != null && position != null
      ? Token.lineAndColumnOf(buffer!, position!)
      : const [0, 0];

  @internal
  String get locationString =>
      buffer != null && position != null ? '$line:$column' : '$position';

  @override
  String? get source => buffer;

  @override
  int? get offset => position;
}
