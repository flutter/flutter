import '../../core/parser.dart';
import '../combinator/delegate.dart';
import 'unbounded.dart';

/// An abstract parser that repeatedly parses between 'min' and 'max' instances
/// of its delegate.
abstract class RepeatingParser<R> extends DelegateParser<R, List<R>> {
  RepeatingParser(Parser<R> parser, this.min, this.max) : super(parser) {
    if (min < 0) {
      throw ArgumentError(
          'Minimum repetitions must be positive, but got $min.');
    }
    if (max < min) {
      throw ArgumentError(
          'Maximum repetitions must be larger than $min, but got $max.');
    }
  }

  /// The minimum amount of repetitions.
  final int min;

  /// The maximum amount of repetitions, or [unbounded].
  final int max;

  @override
  String toString() =>
      '${super.toString()}[$min..${max == unbounded ? '*' : max}]';

  @override
  bool hasEqualProperties(RepeatingParser<R> other) =>
      super.hasEqualProperties(other) && min == other.min && max == other.max;
}
