import '../../context/context.dart';
import '../../context/result.dart';
import '../../core/parser.dart';
import '../combinator/delegate.dart';

extension CastParserExtension<T> on Parser<T> {
  /// Returns a parser that casts itself to `Parser<R>`.
  Parser<R> cast<R>() => CastParser<T, R>(this);
}

/// A parser that casts a `Result` to a `Result<R>`.
class CastParser<T, R> extends DelegateParser<T, R> {
  CastParser(super.delegate);

  @override
  Result<R> parseOn(Context context) {
    final result = delegate.parseOn(context);
    if (result.isSuccess) {
      return result.success(result.value as R);
    } else {
      return result.failure(result.message);
    }
  }

  @override
  int fastParseOn(String buffer, int position) =>
      delegate.fastParseOn(buffer, position);

  @override
  CastParser<T, R> copy() => CastParser<T, R>(delegate);
}
