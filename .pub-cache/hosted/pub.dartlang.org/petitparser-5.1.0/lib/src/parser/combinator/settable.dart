import '../../context/context.dart';
import '../../context/result.dart';
import '../../core/parser.dart';
import '../combinator/delegate.dart';
import '../misc/failure.dart';
import '../utils/resolvable.dart';

extension SettableParserExtension<T> on Parser<T> {
  /// Returns a parser that points to the receiver, but can be changed to point
  /// to something else at a later point in time.
  ///
  /// For example, the parser `letter().settable()` behaves exactly the same
  /// as `letter()`, but it can be replaced with another parser using
  /// [SettableParser.set].
  SettableParser<T> settable() => SettableParser<T>(this);
}

/// Returns a parser that is not defined, but that can be set at a later
/// point in time.
///
/// For example, the following code sets up a parser that points to itself
/// and that accepts a sequence of a's ended with the letter b.
///
///     final p = undefined();
///     p.set(char('a').seq(p).or(char('b')));
SettableParser<R> undefined<R>([String message = 'undefined parser']) =>
    failure<R>(message).settable();

/// A parser that is not defined, but that can be set at a later
/// point in time.
class SettableParser<R> extends DelegateParser<R, R>
    implements ResolvableParser<R> {
  SettableParser(super.delegate);

  /// Sets the receiver to delegate to [parser].
  void set(Parser<R> parser) => replace(children[0], parser);

  @override
  Parser<R> resolve() => delegate;

  @override
  Result<R> parseOn(Context context) => delegate.parseOn(context);

  @override
  int fastParseOn(String buffer, int position) =>
      delegate.fastParseOn(buffer, position);

  @override
  SettableParser<R> copy() => SettableParser<R>(delegate);
}
