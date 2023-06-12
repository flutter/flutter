// AUTO-GENERATED CODE: DO NOT EDIT

import 'package:meta/meta.dart';

import '../../../context/context.dart';
import '../../../context/result.dart';
import '../../../core/parser.dart';
import '../../../shared/annotations.dart';
import '../../action/map.dart';
import '../../utils/sequential.dart';

/// Creates a parser that consumes a sequence of 8 parsers and returns a
/// typed sequence [Sequence8].
Parser<Sequence8<R1, R2, R3, R4, R5, R6, R7, R8>>
    seq8<R1, R2, R3, R4, R5, R6, R7, R8>(
  Parser<R1> parser1,
  Parser<R2> parser2,
  Parser<R3> parser3,
  Parser<R4> parser4,
  Parser<R5> parser5,
  Parser<R6> parser6,
  Parser<R7> parser7,
  Parser<R8> parser8,
) =>
        SequenceParser8<R1, R2, R3, R4, R5, R6, R7, R8>(
          parser1,
          parser2,
          parser3,
          parser4,
          parser5,
          parser6,
          parser7,
          parser8,
        );

/// A parser that consumes a sequence of 8 typed parsers and returns a typed
/// sequence [Sequence8].
class SequenceParser8<R1, R2, R3, R4, R5, R6, R7, R8>
    extends Parser<Sequence8<R1, R2, R3, R4, R5, R6, R7, R8>>
    implements SequentialParser {
  SequenceParser8(this.parser1, this.parser2, this.parser3, this.parser4,
      this.parser5, this.parser6, this.parser7, this.parser8);

  Parser<R1> parser1;
  Parser<R2> parser2;
  Parser<R3> parser3;
  Parser<R4> parser4;
  Parser<R5> parser5;
  Parser<R6> parser6;
  Parser<R7> parser7;
  Parser<R8> parser8;

  @override
  Result<Sequence8<R1, R2, R3, R4, R5, R6, R7, R8>> parseOn(Context context) {
    final result1 = parser1.parseOn(context);
    if (result1.isFailure) return result1.failure(result1.message);
    final result2 = parser2.parseOn(result1);
    if (result2.isFailure) return result2.failure(result2.message);
    final result3 = parser3.parseOn(result2);
    if (result3.isFailure) return result3.failure(result3.message);
    final result4 = parser4.parseOn(result3);
    if (result4.isFailure) return result4.failure(result4.message);
    final result5 = parser5.parseOn(result4);
    if (result5.isFailure) return result5.failure(result5.message);
    final result6 = parser6.parseOn(result5);
    if (result6.isFailure) return result6.failure(result6.message);
    final result7 = parser7.parseOn(result6);
    if (result7.isFailure) return result7.failure(result7.message);
    final result8 = parser8.parseOn(result7);
    if (result8.isFailure) return result8.failure(result8.message);
    return result8.success(Sequence8<R1, R2, R3, R4, R5, R6, R7, R8>(
        result1.value,
        result2.value,
        result3.value,
        result4.value,
        result5.value,
        result6.value,
        result7.value,
        result8.value));
  }

  @override
  int fastParseOn(String buffer, int position) {
    position = parser1.fastParseOn(buffer, position);
    if (position < 0) return -1;
    position = parser2.fastParseOn(buffer, position);
    if (position < 0) return -1;
    position = parser3.fastParseOn(buffer, position);
    if (position < 0) return -1;
    position = parser4.fastParseOn(buffer, position);
    if (position < 0) return -1;
    position = parser5.fastParseOn(buffer, position);
    if (position < 0) return -1;
    position = parser6.fastParseOn(buffer, position);
    if (position < 0) return -1;
    position = parser7.fastParseOn(buffer, position);
    if (position < 0) return -1;
    position = parser8.fastParseOn(buffer, position);
    if (position < 0) return -1;
    return position;
  }

  @override
  List<Parser> get children =>
      [parser1, parser2, parser3, parser4, parser5, parser6, parser7, parser8];

  @override
  void replace(Parser source, Parser target) {
    super.replace(source, target);
    if (parser1 == source) parser1 = target as Parser<R1>;
    if (parser2 == source) parser2 = target as Parser<R2>;
    if (parser3 == source) parser3 = target as Parser<R3>;
    if (parser4 == source) parser4 = target as Parser<R4>;
    if (parser5 == source) parser5 = target as Parser<R5>;
    if (parser6 == source) parser6 = target as Parser<R6>;
    if (parser7 == source) parser7 = target as Parser<R7>;
    if (parser8 == source) parser8 = target as Parser<R8>;
  }

  @override
  SequenceParser8<R1, R2, R3, R4, R5, R6, R7, R8> copy() =>
      SequenceParser8<R1, R2, R3, R4, R5, R6, R7, R8>(parser1, parser2, parser3,
          parser4, parser5, parser6, parser7, parser8);
}

/// Immutable typed sequence with 8 values.
@immutable
class Sequence8<T1, T2, T3, T4, T5, T6, T7, T8> {
  /// Constructs a sequence with 8 typed values.
  Sequence8(this.first, this.second, this.third, this.fourth, this.fifth,
      this.sixth, this.seventh, this.eighth);

  /// Returns the first element of this sequence.
  final T1 first;

  /// Returns the second element of this sequence.
  final T2 second;

  /// Returns the third element of this sequence.
  final T3 third;

  /// Returns the fourth element of this sequence.
  final T4 fourth;

  /// Returns the fifth element of this sequence.
  final T5 fifth;

  /// Returns the sixth element of this sequence.
  final T6 sixth;

  /// Returns the seventh element of this sequence.
  final T7 seventh;

  /// Returns the eighth element of this sequence.
  final T8 eighth;

  /// Returns the last (or eighth) element of this sequence.
  @inlineVm
  @inlineJs
  T8 get last => eighth;

  /// Converts this sequence to a new type [R] with the provided [callback].
  @inlineVm
  @inlineJs
  R map<R>(R Function(T1, T2, T3, T4, T5, T6, T7, T8) callback) =>
      callback(first, second, third, fourth, fifth, sixth, seventh, eighth);

  @override
  int get hashCode =>
      Object.hash(first, second, third, fourth, fifth, sixth, seventh, eighth);

  @override
  bool operator ==(Object other) =>
      other is Sequence8<T1, T2, T3, T4, T5, T6, T7, T8> &&
      first == other.first &&
      second == other.second &&
      third == other.third &&
      fourth == other.fourth &&
      fifth == other.fifth &&
      sixth == other.sixth &&
      seventh == other.seventh &&
      eighth == other.eighth;

  @override
  String toString() =>
      '${super.toString()}($first, $second, $third, $fourth, $fifth, $sixth, $seventh, $eighth)';
}

extension ParserSequenceExtension8<T1, T2, T3, T4, T5, T6, T7, T8>
    on Parser<Sequence8<T1, T2, T3, T4, T5, T6, T7, T8>> {
  /// Maps a typed sequence to [R] using the provided [callback].
  Parser<R> map8<R>(R Function(T1, T2, T3, T4, T5, T6, T7, T8) callback) =>
      map((sequence) => sequence.map(callback));
}
