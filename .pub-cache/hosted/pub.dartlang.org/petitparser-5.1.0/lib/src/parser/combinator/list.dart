import '../../core/parser.dart';

/// Abstract parser that parses a list of things in some way.
abstract class ListParser<T, R> extends Parser<R> {
  ListParser(Iterable<Parser<T>> children)
      : children = List<Parser<T>>.of(children, growable: false);

  /// The children parsers being delegated to.
  @override
  final List<Parser<T>> children;

  @override
  void replace(Parser source, Parser target) {
    super.replace(source, target);
    for (var i = 0; i < children.length; i++) {
      if (children[i] == source) {
        children[i] = target as Parser<T>;
      }
    }
  }
}
