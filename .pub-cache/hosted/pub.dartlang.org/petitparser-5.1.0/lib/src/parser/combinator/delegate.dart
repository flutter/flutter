import '../../core/parser.dart';

/// An abstract parser that delegates to a parser of type [T].
abstract class DelegateParser<T, R> extends Parser<R> {
  DelegateParser(this.delegate);

  /// The parser this parser delegates to.
  Parser<T> delegate;

  @override
  List<Parser> get children => [delegate];

  @override
  void replace(Parser source, Parser target) {
    super.replace(source, target);
    if (delegate == source) {
      delegate = target as Parser<T>;
    }
  }
}
