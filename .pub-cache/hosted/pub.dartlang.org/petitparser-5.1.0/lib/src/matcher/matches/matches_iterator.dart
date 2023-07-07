import '../../context/context.dart';
import '../../core/parser.dart';

class MatchesIterator<T> extends Iterator<T> {
  MatchesIterator(this.parser, this.input, this.start, this.overlapping);

  final Parser<T> parser;
  final String input;
  final bool overlapping;

  int start;

  @override
  late T current;

  @override
  bool moveNext() {
    while (start <= input.length) {
      final end = parser.fastParseOn(input, start);
      if (end < 0) {
        start++;
      } else {
        current = parser.parseOn(Context(input, start)).value;
        if (overlapping || start == end) {
          start++;
        } else {
          start = end;
        }
        return true;
      }
    }
    return false;
  }
}
