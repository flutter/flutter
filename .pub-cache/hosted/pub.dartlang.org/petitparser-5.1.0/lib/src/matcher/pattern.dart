import '../core/parser.dart';
import 'pattern/parser_pattern.dart';

extension PatternParserExtension<T> on Parser<T> {
  /// Converts this [Parser] into a [Pattern] for basic searches within strings.
  Pattern toPattern() => ParserPattern(this);
}
