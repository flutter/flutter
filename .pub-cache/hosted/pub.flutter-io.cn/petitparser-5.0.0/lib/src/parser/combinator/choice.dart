import '../../context/context.dart';
import '../../context/failure.dart';
import '../../context/result.dart';
import '../../core/parser.dart';
import '../utils/failure_joiner.dart';
import 'list.dart';

extension ChoiceParserExtension on Parser {
  /// Returns a parser that accepts the receiver or [other]. The resulting
  /// parser returns the parse result of the receiver, if the receiver fails
  /// it returns the parse result of [other] (exclusive ordered choice).
  ///
  /// An optional [failureJoiner] can be specified that determines which
  /// [Failure] to return in case both parsers fail. By default the last
  /// failure is returned [selectLast], but [selectFarthest] is another
  /// common choice that usually gives better error messages.
  ///
  /// For example, the parser `letter().or(digit())` accepts a letter or a
  /// digit. An example where the order matters is the following choice between
  /// overlapping parsers: `letter().or(char('a'))`. In the example the parser
  /// `char('a')` will never be activated, because the input is always consumed
  /// `letter()`. This can be problematic if the author intended to attach a
  /// production action to `char('a')`.
  ///
  /// Due to https://github.com/dart-lang/language/issues/1557 the resulting
  /// parser cannot be properly typed. Please use [ChoiceIterableExtension]
  /// as a workaround: `[first, second].toChoiceParser()`.
  ChoiceParser or(Parser other, {FailureJoiner? failureJoiner}) {
    final self = this;
    return self is ChoiceParser
        ? ChoiceParser([...self.children, other],
            failureJoiner: failureJoiner ?? self.failureJoiner)
        : ChoiceParser([this, other], failureJoiner: failureJoiner);
  }

  /// Convenience operator returning a parser that accepts the receiver or
  /// [other]. See [or] for details.
  ChoiceParser operator |(Parser other) => or(other);
}

extension ChoiceIterableExtension<T> on Iterable<Parser<T>> {
  /// Converts the parser in this iterable to a choice of parsers.
  ChoiceParser<T> toChoiceParser({FailureJoiner<T>? failureJoiner}) =>
      ChoiceParser<T>(this, failureJoiner: failureJoiner);
}

/// A parser that uses the first parser that succeeds.
class ChoiceParser<T> extends ListParser<T, T> {
  ChoiceParser(Iterable<Parser<T>> children, {FailureJoiner<T>? failureJoiner})
      : failureJoiner = failureJoiner ?? selectLast,
        super(children) {
    if (children.isEmpty) {
      throw ArgumentError('Choice parser cannot be empty.');
    }
  }

  /// Strategy to join multiple parse errors.
  final FailureJoiner<T> failureJoiner;

  /// Switches the failure joining strategy.
  ChoiceParser<T> withFailureJoiner(FailureJoiner<T> failureJoiner) =>
      ChoiceParser<T>(children, failureJoiner: failureJoiner);

  @override
  Result<T> parseOn(Context context) {
    Failure<T>? failure;
    for (var i = 0; i < children.length; i++) {
      final result = children[i].parseOn(context);
      if (result is Failure<T>) {
        failure = failure == null ? result : failureJoiner(failure, result);
      } else {
        return result;
      }
    }
    return failure!;
  }

  @override
  int fastParseOn(String buffer, int position) {
    var result = -1;
    for (var i = 0; i < children.length; i++) {
      result = children[i].fastParseOn(buffer, position);
      if (result >= 0) {
        return result;
      }
    }
    return result;
  }

  @override
  bool hasEqualProperties(ChoiceParser<T> other) =>
      super.hasEqualProperties(other) && failureJoiner == other.failureJoiner;

  @override
  ChoiceParser<T> copy() =>
      ChoiceParser<T>(children, failureJoiner: failureJoiner);
}
