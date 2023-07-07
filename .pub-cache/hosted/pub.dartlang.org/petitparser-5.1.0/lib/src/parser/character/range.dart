import '../../core/parser.dart';
import 'code.dart';
import 'parser.dart';
import 'predicate.dart';

/// Returns a parser that accepts any character in the range
/// between [start] and [stop].
Parser<String> range(String start, String stop, [String? message]) =>
    CharacterParser(
        RangeCharPredicate(toCharCode(start), toCharCode(stop)),
        message ??
            '[${toReadableString(start)}-${toReadableString(stop)}] expected');

class RangeCharPredicate implements CharacterPredicate {
  RangeCharPredicate(this.start, this.stop) {
    if (start > stop) {
      throw ArgumentError('Invalid range: $start-$stop');
    }
  }

  final int start;
  final int stop;

  @override
  bool test(int value) => start <= value && value <= stop;

  @override
  bool isEqualTo(CharacterPredicate other) =>
      other is RangeCharPredicate && other.start == start && other.stop == stop;
}
