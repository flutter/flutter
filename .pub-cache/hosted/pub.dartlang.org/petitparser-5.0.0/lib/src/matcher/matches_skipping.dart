import '../core/parser.dart';
import '../parser/action/map.dart';
import '../parser/combinator/choice.dart';
import '../parser/predicate/any.dart';
import '../parser/repeater/possessive.dart';
import 'matches.dart';

extension MatchesSkippingParser<T> on Parser<T> {
  /// Returns a list of all successful non-overlapping parses of the input.
  ///
  /// For example, `letter().plus().matchesSkipping('abc de')` results in the
  /// list `[['a', 'b', 'c'], ['d', 'e']]`. See [matches] to retrieve
  /// overlapping parse results.
  List<T> matchesSkipping(String input) {
    final list = <T>[];
    map(list.add).or(any()).star().fastParseOn(input, 0);
    return list;
  }
}
