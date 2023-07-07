import 'package:meta/meta.dart';

import '../../core/parser.dart';
import '../../shared/types.dart';

/// A continuous path through the parser graph.
class ParserPath {
  /// Constructs a path from a list of parsers and indexes.
  ParserPath(this.parsers, this.indexes)
      : assert(parsers.isNotEmpty, 'parsers cannot be empty'),
        assert(indexes.length == parsers.length - 1, 'indexes wrong size'),
        assert((() {
          for (var i = 0; i < indexes.length; i++) {
            if (parsers[i].children[indexes[i]] != parsers[i + 1]) {
              return false;
            }
          }
          return true;
        })(), 'indexes invalid');

  /// The non-empty list of parsers in this path.
  final List<Parser> parsers;

  /// The parser where this path starts.
  Parser get source => parsers.first;

  /// The parser where this path ends.
  Parser get target => parsers.last;

  /// The number of parsers in this path.
  int get length => parsers.length;

  /// The child-indexes that navigate from one parser to the next one. This
  /// collection contains one element less than the number of parsers in the
  /// path.
  final List<int> indexes;

  void _push(Parser parser, int index) {
    parsers.add(parser);
    indexes.add(index);
  }

  void _pop() {
    parsers.removeLast();
    indexes.removeLast();
  }
}

@internal
Iterable<ParserPath> depthFirstSearch(
    ParserPath path, Predicate<ParserPath> predicate) sync* {
  if (predicate(path)) {
    yield ParserPath(List.from(path.parsers), List.from(path.indexes));
  } else {
    final children = path.target.children;
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      if (!path.parsers.contains(child)) {
        path._push(child, i);
        yield* depthFirstSearch(path, predicate);
        path._pop();
      }
    }
  }
}
