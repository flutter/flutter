import '../core/parser.dart';
import '../parser/action/map.dart';
import '../parser/combinator/and.dart';
import '../parser/combinator/choice.dart';
import '../parser/combinator/sequence.dart';
import '../parser/predicate/any.dart';
import '../parser/repeater/possessive.dart';
import 'matches_skipping.dart';

extension MatchesParser<T> on Parser<T> {
  /// Returns a list of all successful overlapping parses of the [input].
  ///
  /// For example, `letter().plus().matches('abc de')` results in the list
  /// `[['a', 'b', 'c'], ['b', 'c'], ['c'], ['d', 'e'], ['e']]`. See
  /// [matchesSkipping] to retrieve non-overlapping parse results.
  List<T> matches(String input) {
    final list = <T>[];
    and().map(list.add).seq(any()).or(any()).star().fastParseOn(input, 0);
    return list;
  }
}
