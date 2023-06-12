// AUTO-GENERATED CODE: DO NOT EDIT

import 'package:meta/meta.dart';

import '../../../context/context.dart';
import '../../../context/result.dart';
import '../../../core/parser.dart';
import '../../../shared/annotations.dart';
import '../../action/map.dart';
import '../../utils/sequential.dart';

/// Creates a parser that consumes a sequence of 2 parsers and returns a
/// typed sequence [Sequence2].
Parser<Sequence2<R1, R2>> seq2<R1, R2>(
  Parser<R1> parser1,
  Parser<R2> parser2,
) =>
    SequenceParser2<R1, R2>(
      parser1,
      parser2,
    );

/// A parser that consumes a sequence of 2 typed parsers and returns a typed
/// sequence [Sequence2].
class SequenceParser2<R1, R2> extends Parser<Sequence2<R1, R2>>
    implements SequentialParser {
  SequenceParser2(this.parser1, this.parser2);

  Parser<R1> parser1;
  Parser<R2> parser2;

  @override
  Result<Sequence2<R1, R2>> parseOn(Context context) {
    final result1 = parser1.parseOn(context);
    if (result1.isFailure) return result1.failure(result1.message);
    final result2 = parser2.parseOn(result1);
    if (result2.isFailure) return result2.failure(result2.message);
    return result2.success(Sequence2<R1, R2>(result1.value, result2.value));
  }

  @override
  int fastParseOn(String buffer, int position) {
    position = parser1.fastParseOn(buffer, position);
    if (position < 0) return -1;
    position = parser2.fastParseOn(buffer, position);
    if (position < 0) return -1;
    return position;
  }

  @override
  List<Parser> get children => [parser1, parser2];

  @override
  void replace(Parser source, Parser target) {
    super.replace(source, target);
    if (parser1 == source) parser1 = target as Parser<R1>;
    if (parser2 == source) parser2 = target as Parser<R2>;
  }

  @override
  SequenceParser2<R1, R2> copy() => SequenceParser2<R1, R2>(parser1, parser2);
}

/// Immutable typed sequence with 2 values.
@immutable
class Sequence2<T1, T2> {
  /// Constructs a sequence with 2 typed values.
  Sequence2(this.first, this.second);

  /// Returns the first element of this sequence.
  final T1 first;

  /// Returns the second element of this sequence.
  final T2 second;

  /// Returns the last (or second) element of this sequence.
  @inlineVm
  @inlineJs
  T2 get last => second;

  /// Converts this sequence to a new type [R] with the provided [callback].
  @inlineVm
  @inlineJs
  R map<R>(R Function(T1, T2) callback) => callback(first, second);

  @override
  int get hashCode => Object.hash(first, second);

  @override
  bool operator ==(Object other) =>
      other is Sequence2<T1, T2> &&
      first == other.first &&
      second == other.second;

  @override
  String toString() => '${super.toString()}($first, $second)';
}

extension ParserSequenceExtension2<T1, T2> on Parser<Sequence2<T1, T2>> {
  /// Maps a typed sequence to [R] using the provided [callback].
  Parser<R> map2<R>(R Function(T1, T2) callback) =>
      map((sequence) => sequence.map(callback));
}
