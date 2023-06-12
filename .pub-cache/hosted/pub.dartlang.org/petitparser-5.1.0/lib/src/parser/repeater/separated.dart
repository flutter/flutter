import 'dart:math' as math;

import '../../context/context.dart';
import '../../context/result.dart';
import '../../core/parser.dart';
import '../utils/sequential.dart';
import 'repeating.dart';
import 'unbounded.dart';

extension SeparatedRepeatingParserExtension<R> on Parser<R> {
  /// Returns a parser that consumes the receiver zero or more times separated
  /// by the [separator] parser. The resulting parser returns a [SeparatedList]
  /// containing collections of both the elements of type [R] as well as the
  /// separators of type [S].
  ///
  /// For example, the parser `digit().starSeparated(anyOf(',;'))` returns a
  /// parser that consumes input like `'1,2;3'` and that returns a
  /// [SeparatedList] with elements `['1', '2', '3']` as well as the separators
  /// [`,`, `;`].
  Parser<SeparatedList<R, S>> starSeparated<S>(Parser<S> separator) =>
      repeatSeparated<S>(separator, 0, unbounded);

  /// Returns a parser that consumes the receiver one or more times separated
  /// by the [separator] parser. The resulting parser returns a [SeparatedList]
  /// containing collections of both the elements of type [R] as well as the
  /// separators of type [S].
  Parser<SeparatedList<R, S>> plusSeparated<S>(Parser<S> separator) =>
      repeatSeparated<S>(separator, 1, unbounded);

  /// Returns a parser that consumes the receiver [count] times separated
  /// by the [separator] parser. The resulting parser returns a [SeparatedList]
  /// containing collections of both the elements of type [R] as well as the
  /// separators of type [S].
  Parser<SeparatedList<R, S>> timesSeparated<S>(
          Parser<S> separator, int count) =>
      repeatSeparated<S>(separator, count, count);

  /// Returns a parser that consumes the receiver between [min] and [max] times
  /// separated by the [separator] parser. The resulting parser returns a
  /// [SeparatedList] containing collections of both the elements of type [R] as
  /// well as the separators of type [S].
  Parser<SeparatedList<R, S>> repeatSeparated<S>(
          Parser<S> separator, int min, int max) =>
      SeparatedRepeatingParser<R, S>(this, separator, min, max);
}

/// A parser that consumes the [delegate] between [min] and [max] times
/// separated by the [separator] parser.
class SeparatedRepeatingParser<R, S>
    extends RepeatingParser<R, SeparatedList<R, S>>
    implements SequentialParser {
  SeparatedRepeatingParser(
      super.delegate, this.separator, super.min, super.max);

  /// Parser consuming input between the repeated elements.
  Parser<S> separator;

  @override
  Result<SeparatedList<R, S>> parseOn(Context context) {
    var current = context;
    final elements = <R>[];
    final separators = <S>[];
    while (elements.length < min) {
      if (elements.isNotEmpty) {
        final separation = separator.parseOn(current);
        if (separation.isFailure) {
          return separation.failure(separation.message);
        }
        current = separation;
        separators.add(separation.value);
      }
      final result = delegate.parseOn(current);
      if (result.isFailure) {
        return result.failure(result.message);
      }
      current = result;
      elements.add(result.value);
    }
    while (elements.length < max) {
      final previous = current;
      if (elements.isNotEmpty) {
        final separation = separator.parseOn(current);
        if (separation.isFailure) {
          return current.success(SeparatedList(elements, separators));
        }
        current = separation;
        separators.add(separation.value);
      }
      final result = delegate.parseOn(current);
      if (result.isFailure) {
        if (elements.isNotEmpty) separators.removeLast();
        return previous.success(SeparatedList(elements, separators));
      }
      current = result;
      elements.add(result.value);
    }
    return current.success(SeparatedList(elements, separators));
  }

  @override
  int fastParseOn(String buffer, int position) {
    var count = 0;
    var current = position;
    while (count < min) {
      if (count > 0) {
        final separation = separator.fastParseOn(buffer, current);
        if (separation < 0) {
          return -1;
        }
        current = separation;
      }
      final result = delegate.fastParseOn(buffer, current);
      if (result < 0) {
        return -1;
      }
      count++;
      current = result;
    }
    while (count < max) {
      final previous = current;
      if (count > 0) {
        final separation = separator.fastParseOn(buffer, current);
        if (separation < 0) {
          return current;
        }
        current = separation;
      }
      final result = delegate.fastParseOn(buffer, current);
      if (result < 0) {
        return previous;
      }
      count++;
      current = result;
    }
    return current;
  }

  @override
  List<Parser> get children => [delegate, separator];

  @override
  void replace(Parser source, Parser target) {
    super.replace(source, target);
    if (separator == source) {
      separator = target as Parser<S>;
    }
  }

  @override
  SeparatedRepeatingParser<R, S> copy() =>
      SeparatedRepeatingParser<R, S>(delegate, separator, min, max);
}

/// A list of [elements] and its [separators].
class SeparatedList<R, S> {
  SeparatedList(this.elements, this.separators)
      : assert(
          math.max(0, elements.length - 1) == separators.length,
          'Inconsistent number of elements ($elements) and separators ($separators)',
        );

  /// The parsed elements.
  final List<R> elements;

  /// The parsed separators.
  final List<S> separators;

  /// An (untyped) iterable over the [elements] and the interleaved [separators]
  /// in order of appearance.
  Iterable get sequential sync* {
    for (var i = 0; i < elements.length; i++) {
      yield elements[i];
      if (i < separators.length) {
        yield separators[i];
      }
    }
  }

  /// Combines the [elements] by grouping the elements from the left and
  /// calling [callback] on all consecutive elements with the corresponding
  /// [separator].
  ///
  /// For example, if the elements are numbers and the separators are
  /// subtraction operations sequential values `1 - 2 - 3` are grouped like
  /// `(1 - 2) - 3`.
  R foldLeft(R Function(R left, S seperator, R right) callback) {
    var result = elements.first;
    for (var i = 1; i < elements.length; i++) {
      result = callback(result, separators[i - 1], elements[i]);
    }
    return result;
  }

  /// Combines the [elements] by grouping the elements from the right and
  /// calling [callback] on all consecutive elements with the corresponding
  /// [separator].
  ///
  /// For example, if the elements are numbers and the separators are
  /// exponentiation operations sequential values `1 ^ 2 ^ 3` are grouped like
  /// `1 ^ (2 ^ 3)`.
  R foldRight(R Function(R left, S seperator, R right) callback) {
    var result = elements.last;
    for (var i = elements.length - 2; i >= 0; i--) {
      result = callback(elements[i], separators[i], result);
    }
    return result;
  }

  @override
  String toString() => 'SeparatedList$sequential';
}
