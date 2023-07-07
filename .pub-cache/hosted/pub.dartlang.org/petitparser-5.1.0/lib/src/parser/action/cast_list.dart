import '../../context/context.dart';
import '../../context/result.dart';
import '../../core/parser.dart';
import '../combinator/delegate.dart';

extension CastListParserExtension<T> on Parser<T> {
  /// Returns a parser that casts itself to `Parser<List<R>>`. Assumes this
  /// parser to be of type `Parser<List>`.
  Parser<List<R>> castList<R>() => CastListParser<T, R>(this);
}

/// A parser that casts a `Result<List>` to a `Result<List<R>>`.
class CastListParser<T, R> extends DelegateParser<T, List<R>> {
  CastListParser(super.delegate);

  @override
  Result<List<R>> parseOn(Context context) {
    final result = delegate.parseOn(context);
    if (result.isSuccess) {
      return result.success((result.value as List).cast<R>());
    } else {
      return result.failure(result.message);
    }
  }

  @override
  int fastParseOn(String buffer, int position) =>
      delegate.fastParseOn(buffer, position);

  @override
  CastListParser<T, R> copy() => CastListParser<T, R>(delegate);
}
