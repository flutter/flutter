import '../../core/parser.dart';
import 'parser_match.dart';
import 'parser_pattern.dart';

class PatternIterator extends Iterator<ParserMatch> {
  PatternIterator(this.pattern, this.parser, this.input, this.start);

  final ParserPattern pattern;
  final Parser parser;
  final String input;
  int start;

  @override
  late ParserMatch current;

  @override
  bool moveNext() {
    while (start <= input.length) {
      final end = parser.fastParseOn(input, start);
      if (end < 0) {
        start++;
      } else {
        current = ParserMatch(pattern, input, start, end);
        if (start == end) {
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
