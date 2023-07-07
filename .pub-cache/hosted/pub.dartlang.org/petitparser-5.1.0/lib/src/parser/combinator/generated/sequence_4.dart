// AUTO-GENERATED CODE: DO NOT EDIT

import 'package:meta/meta.dart';

import '../../../context/context.dart';
import '../../../context/result.dart';
import '../../../core/parser.dart';
import '../../../shared/annotations.dart';
import '../../action/map.dart';
import '../../utils/sequential.dart';

/// Creates a parser that consumes a sequence of 4 parsers and returns a
/// typed sequence [Sequence4].
Parser<Sequence4<R1, R2, R3, R4>> seq4<R1, R2, R3, R4>(
  Parser<R1> parser1,
  Parser<R2> parser2,
  Parser<R3> parser3,
  Parser<R4> parser4,
) =>
    SequenceParser4<R1, R2, R3, R4>(
      parser1,
      parser2,
      parser3,
      parser4,
    );

/// A parser that consumes a sequence of 4 typed parsers and returns a typed
/// sequence [Sequence4].
class SequenceParser4<R1, R2, R3, R4> extends Parser<Sequence4<R1, R2, R3, R4>>
    implements SequentialParser {
  SequenceParser4(this.parser1, this.parser2, this.parser3, this.parser4);

  Parser<R1> parser1;
  Parser<R2> parser2;
  Parser<R3> parser3;
  Parser<R4> parser4;

  @override
  Result<Sequence4<R1, R2, R3, R4>> parseOn(Context context) {
    final result1 = parser1.parseOn(context);
    if (result1.isFailure) return result1.failure(result1.message);
    final result2 = parser2.parseOn(result1);
    if (result2.isFailure) return result2.failure(result2.message);
    final result3 = parser3.parseOn(result2);
    if (result3.isFailure) return result3.failure(result3.message);
    final result4 = parser4.parseOn(result3);
    if (result4.isFailure) return result4.failure(result4.message);
    return result4.success(Sequence4<R1, R2, R3, R4>(
        result1.value, result2.value, result3.value, result4.value));
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
    return position;
  }

  @override
  List<Parser> get children => [parser1, parser2, parser3, parser4];

  @override
  void replace(Parser source, Parser target) {
    super.replace(source, target);
    if (parser1 == source) parser1 = target as Parser<R1>;
    if (parser2 == source) parser2 = target as Parser<R2>;
    if (parser3 == source) parser3 = target as Parser<R3>;
    if (parser4 == source) parser4 = target as Parser<R4>;
  }

  @override
  SequenceParser4<R1, R2, R3, R4> copy() =>
      SequenceParser4<R1, R2, R3, R4>(parser1, parser2, parser3, parser4);
}

/// Immutable typed sequence with 4 values.
@immutable
class Sequence4<T1, T2, T3, T4> {
  /// Constructs a sequence with 4 typed values.
  Sequence4(this.first, this.second, this.third, this.fourth);

  /// Returns the first element of this sequence.
  final T1 first;

  /// Returns the second element of this sequence.
  final T2 second;

  /// Returns the third element of this sequence.
  final T3 third;

  /// Returns the fourth element of this sequence.
  final T4 fourth;

  /// Returns the last (or fourth) element of this sequence.
  @inlineVm
  @inlineJs
  T4 get last => fourth;

  /// Converts this sequence to a new type [R] with the provided [callback].
  @inlineVm
  @inlineJs
  R map<R>(R Function(T1, T2, T3, T4) callback) =>
      callback(first, second, third, fourth);

  @override
  int get hashCode => Object.hash(first, second, third, fourth);

  @override
  bool operator ==(Object other) =>
      other is Sequence4<T1, T2, T3, T4> &&
      first == other.first &&
      second == other.second &&
      third == other.third &&
      fourth == other.fourth;

  @override
  String toString() => '${super.toString()}($first, $second, $third, $fourth)';
}

extension ParserSequenceExtension4<T1, T2, T3, T4>
    on Parser<Sequence4<T1, T2, T3, T4>> {
  /// Maps a typed sequence to [R] using the provided [callback].
  Parser<R> map4<R>(R Function(T1, T2, T3, T4) callback) =>
      map((sequence) => sequence.map(callback));
}
