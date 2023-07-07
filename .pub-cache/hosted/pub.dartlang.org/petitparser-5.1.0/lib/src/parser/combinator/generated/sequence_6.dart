// AUTO-GENERATED CODE: DO NOT EDIT

import 'package:meta/meta.dart';

import '../../../context/context.dart';
import '../../../context/result.dart';
import '../../../core/parser.dart';
import '../../../shared/annotations.dart';
import '../../action/map.dart';
import '../../utils/sequential.dart';

/// Creates a parser that consumes a sequence of 6 parsers and returns a
/// typed sequence [Sequence6].
Parser<Sequence6<R1, R2, R3, R4, R5, R6>> seq6<R1, R2, R3, R4, R5, R6>(
  Parser<R1> parser1,
  Parser<R2> parser2,
  Parser<R3> parser3,
  Parser<R4> parser4,
  Parser<R5> parser5,
  Parser<R6> parser6,
) =>
    SequenceParser6<R1, R2, R3, R4, R5, R6>(
      parser1,
      parser2,
      parser3,
      parser4,
      parser5,
      parser6,
    );

/// A parser that consumes a sequence of 6 typed parsers and returns a typed
/// sequence [Sequence6].
class SequenceParser6<R1, R2, R3, R4, R5, R6>
    extends Parser<Sequence6<R1, R2, R3, R4, R5, R6>>
    implements SequentialParser {
  SequenceParser6(this.parser1, this.parser2, this.parser3, this.parser4,
      this.parser5, this.parser6);

  Parser<R1> parser1;
  Parser<R2> parser2;
  Parser<R3> parser3;
  Parser<R4> parser4;
  Parser<R5> parser5;
  Parser<R6> parser6;

  @override
  Result<Sequence6<R1, R2, R3, R4, R5, R6>> parseOn(Context context) {
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
    return result6.success(Sequence6<R1, R2, R3, R4, R5, R6>(
        result1.value,
        result2.value,
        result3.value,
        result4.value,
        result5.value,
        result6.value));
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
    return position;
  }

  @override
  List<Parser> get children =>
      [parser1, parser2, parser3, parser4, parser5, parser6];

  @override
  void replace(Parser source, Parser target) {
    super.replace(source, target);
    if (parser1 == source) parser1 = target as Parser<R1>;
    if (parser2 == source) parser2 = target as Parser<R2>;
    if (parser3 == source) parser3 = target as Parser<R3>;
    if (parser4 == source) parser4 = target as Parser<R4>;
    if (parser5 == source) parser5 = target as Parser<R5>;
    if (parser6 == source) parser6 = target as Parser<R6>;
  }

  @override
  SequenceParser6<R1, R2, R3, R4, R5, R6> copy() =>
      SequenceParser6<R1, R2, R3, R4, R5, R6>(
          parser1, parser2, parser3, parser4, parser5, parser6);
}

/// Immutable typed sequence with 6 values.
@immutable
class Sequence6<T1, T2, T3, T4, T5, T6> {
  /// Constructs a sequence with 6 typed values.
  Sequence6(
      this.first, this.second, this.third, this.fourth, this.fifth, this.sixth);

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

  /// Returns the last (or sixth) element of this sequence.
  @inlineVm
  @inlineJs
  T6 get last => sixth;

  /// Converts this sequence to a new type [R] with the provided [callback].
  @inlineVm
  @inlineJs
  R map<R>(R Function(T1, T2, T3, T4, T5, T6) callback) =>
      callback(first, second, third, fourth, fifth, sixth);

  @override
  int get hashCode => Object.hash(first, second, third, fourth, fifth, sixth);

  @override
  bool operator ==(Object other) =>
      other is Sequence6<T1, T2, T3, T4, T5, T6> &&
      first == other.first &&
      second == other.second &&
      third == other.third &&
      fourth == other.fourth &&
      fifth == other.fifth &&
      sixth == other.sixth;

  @override
  String toString() =>
      '${super.toString()}($first, $second, $third, $fourth, $fifth, $sixth)';
}

extension ParserSequenceExtension6<T1, T2, T3, T4, T5, T6>
    on Parser<Sequence6<T1, T2, T3, T4, T5, T6>> {
  /// Maps a typed sequence to [R] using the provided [callback].
  Parser<R> map6<R>(R Function(T1, T2, T3, T4, T5, T6) callback) =>
      map((sequence) => sequence.map(callback));
}
