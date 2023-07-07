import '../../context/context.dart';
import '../../context/result.dart';
import '../../core/parser.dart';

/// Returns a parser that accepts any input element.
///
/// For example, `any()` succeeds and consumes any given letter. It only
/// fails for an empty input.
Parser<String> any([String message = 'input expected']) => AnyParser(message);

/// A parser that accepts any input element.
class AnyParser extends Parser<String> {
  AnyParser(this.message);

  /// Error message to annotate parse failures with.
  final String message;

  @override
  Result<String> parseOn(Context context) {
    final buffer = context.buffer;
    final position = context.position;
    return position < buffer.length
        ? context.success(buffer[position], position + 1)
        : context.failure(message);
  }

  @override
  int fastParseOn(String buffer, int position) =>
      position < buffer.length ? position + 1 : -1;

  @override
  AnyParser copy() => AnyParser(message);

  @override
  bool hasEqualProperties(AnyParser other) =>
      super.hasEqualProperties(other) && message == other.message;
}
