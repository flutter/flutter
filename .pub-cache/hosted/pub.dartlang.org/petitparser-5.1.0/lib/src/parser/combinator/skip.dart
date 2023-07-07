import '../../core/parser.dart';
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
          : seq2(this, after).map2((value, _) => value)
      : after == null
          ? seq2(before, this).map2((_, value) => value)
          : seq3(before, this, after).map3((_, value, __) => value);
}
