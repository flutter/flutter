import '../../context/context.dart';
import '../../context/result.dart';
import '../../core/parser.dart';
import '../../parser/combinator/delegate.dart';

/// Handler function for the [ContinuationParser].
typedef ContinuationHandler<T, R> = Result<R> Function(
    ContinuationFunction<T> continuation, Context context);

/// Continuation function of the [ContinuationHandler].
typedef ContinuationFunction<T> = Result<T> Function(Context context);

extension ContinuationParserExtension<T> on Parser<T> {
  /// Returns a parser that when activated captures a continuation function
  /// and passes it together with the current context into the handler.
  ///
  /// Handlers are not required to call the continuation, but can completely
  /// ignore it, call it multiple times, and/or store it away for later use.
  /// Similarly handlers can modify the current context and/or modify the
  /// returned result.
  ///
  /// The following example shows a simple wrapper. Messages are printed before
  /// and after the `digit()` parser is activated:
  ///
  ///     final parser = digit().callCC((continuation, context) {
  ///       print('Parser will be activated, the context is $context.');
  ///       final result = continuation(context);
  ///       print('Parser was activated, the result is $result.');
  ///       return result;
  ///     });
  ///
  Parser<R> callCC<R>(ContinuationHandler<T, R> handler) =>
      ContinuationParser<T, R>(this, handler);
}

/// Continuation parser that when activated captures a continuation function
/// and passes it together with the current context into the handler.
class ContinuationParser<T, R> extends DelegateParser<T, R> {
  ContinuationParser(super.delegate, this.handler);

  /// Activation handler of the continuation.
  final ContinuationHandler<T, R> handler;

  @override
  Result<R> parseOn(Context context) => handler(_parseDelegateOn, context);

  Result<T> _parseDelegateOn(Context context) => delegate.parseOn(context);

  @override
  ContinuationParser<T, R> copy() =>
      ContinuationParser<T, R>(delegate, handler);

  @override
  bool hasEqualProperties(ContinuationParser<T, R> other) =>
      super.hasEqualProperties(other) && handler == other.handler;
}
