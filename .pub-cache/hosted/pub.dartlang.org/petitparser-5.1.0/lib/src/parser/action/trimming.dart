import '../../context/context.dart';
import '../../context/result.dart';
import '../../core/parser.dart';
import '../../shared/annotations.dart';
import '../character/whitespace.dart';
import '../combinator/delegate.dart';
import '../utils/sequential.dart';

extension TrimmingParserExtension<T> on Parser<T> {
  /// Returns a parser that consumes input before and after the receiver,
  /// discards the excess input and only returns the result of the receiver.
  /// The optional arguments are parsers that consume the excess input. By
  /// default `whitespace()` is used. Up to two arguments can be provided to
  /// have different parsers on the [left] and [right] side.
  ///
  /// For example, the parser `letter().plus().trim()` returns `['a', 'b']`
  /// for the input `' ab\n'` and consumes the complete input string.
  Parser<T> trim([Parser<void>? left, Parser<void>? right]) =>
      TrimmingParser<T>(this, left ??= whitespace(), right ??= left);
}

/// A parser that silently consumes input of another parser around
/// its delegate.
class TrimmingParser<R> extends DelegateParser<R, R>
    implements SequentialParser {
  TrimmingParser(super.delegate, this.left, this.right);

  /// Parser that consumes input before the delegate.
  Parser<void> left;

  /// Parser that consumes input after the delegate.
  Parser<void> right;

  @override
  Result<R> parseOn(Context context) {
    final buffer = context.buffer;

    // Trim the left part:
    final before = _trim(left, buffer, context.position);
    if (before != context.position) {
      context = Context(buffer, before);
    }

    // Consume the delegate:
    final result = delegate.parseOn(context);
    if (result.isFailure) {
      return result;
    }

    // Trim the right part:
    final after = _trim(right, buffer, result.position);
    return after == result.position
        ? result
        : result.success(result.value, after);
  }

  @override
  int fastParseOn(String buffer, int position) {
    final result = delegate.fastParseOn(buffer, _trim(left, buffer, position));
    return result < 0 ? -1 : _trim(right, buffer, result);
  }

  @inlineVm
  @inlineJs
  int _trim(Parser parser, String buffer, int position) {
    for (;;) {
      final result = parser.fastParseOn(buffer, position);
      if (result < 0) {
        break;
      }
      position = result;
    }
    return position;
  }

  @override
  TrimmingParser<R> copy() => TrimmingParser<R>(delegate, left, right);

  @override
  List<Parser> get children => [delegate, left, right];

  @override
  void replace(covariant Parser source, covariant Parser target) {
    super.replace(source, target);
    if (left == source) {
      left = target;
    }
    if (right == source) {
      right = target;
    }
  }
}
