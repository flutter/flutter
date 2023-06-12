import '../../core/parser.dart';
import '../action/map.dart';
import 'sequence.dart';

extension SkipParserExtension<T> on Parser<T> {
  /// Returns a parser that consumes input [before] and [after] the receiver,
  /// but discards the parse results of [before] and [after] and only returns
  /// the result of the receiver.
  ///
  /// For example, the parser `digit().skip(char('['), char(']'))`
  /// returns `'3'` for the input `'[3]'`.
  Parser<T> skip({Parser<void>? before, Parser<void>? after}) => before == null
      ? after == null
          ? this
          : [this, after].toSequenceParser().map((list) => list[0] as T)
      : after == null
          ? [before, this].toSequenceParser().map((list) => list[1] as T)
          : [before, this, after]
              .toSequenceParser()
              .map((list) => list[1] as T);
}
