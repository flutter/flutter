import '../core/parser.dart';

/// Returns a lazy iterable over all parsers reachable from [root] using
/// a [depth-first traversal](https://en.wikipedia.org/wiki/Depth-first_search)
/// over the connected parser graph.
///
/// For example, the following code prints the two parsers of the
/// defined grammar:
///
///     final parser = range('0', '9').star();
///     allParser(parser).forEach((each) {
///       print(each);
///     });
///
Iterable<Parser> allParser(Parser root) => _ParserIterable(root);

class _ParserIterable extends Iterable<Parser> {
  _ParserIterable(this.root);

  final Parser root;

  @override
  Iterator<Parser> get iterator => _ParserIterator(root);
}

class _ParserIterator extends Iterator<Parser> {
  _ParserIterator(Parser root)
      : todo = [root],
        seen = {root};

  final List<Parser> todo;
  final Set<Parser> seen;

  @override
  late Parser current;

  @override
  bool moveNext() {
    if (todo.isEmpty) {
      seen.clear();
      return false;
    }
    current = todo.removeLast();
    for (final parser in current.children.reversed) {
      if (seen.add(parser)) {
        todo.add(parser);
      }
    }
    return true;
  }
}
