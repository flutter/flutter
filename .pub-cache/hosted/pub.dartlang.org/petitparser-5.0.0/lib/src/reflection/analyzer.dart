import '../core/parser.dart';
import '../parser/misc/epsilon.dart';
import '../shared/types.dart';
import 'internal/cycle_set.dart';
import 'internal/first_set.dart';
import 'internal/follow_set.dart';
import 'internal/path.dart';
import 'iterable.dart';

/// Helper to reflect on properties of a grammar.
class Analyzer {
  /// Constructs an analyzer on the parser graph starting at [root].
  Analyzer(this.root);

  /// The start parser of analysis.
  final Parser root;

  /// Returns a set of all parsers reachable from [root].
  Iterable<Parser> get parsers => _parsers;

  late final Set<Parser> _parsers = allParser(root).toSet();

  /// Returns a set of all deep children reachable from [parser].
  ///
  /// The returned set does only include the [parser] itself, if it is
  /// recursively calling itself.
  Set<Parser> allChildren(Parser parser) {
    assert(parsers.contains(parser), 'parser is not part of the analyzer');
    return _allChildren.putIfAbsent(
        parser,
        () => parser.children.fold(
            <Parser>{}, (result, child) => result..addAll(allParser(child))));
  }

  late final Map<Parser, Set<Parser>> _allChildren = {};

  /// Returns the shortest path from [source] that satisfies the given
  /// [predicate], if any.
  ParserPath? findPath(Parser source, Predicate<ParserPath> predicate) {
    ParserPath? path;
    for (final current in findAllPaths(source, predicate)) {
      if (path == null || current.length < path.length) {
        path = current;
      }
    }
    return path;
  }

  /// Returns the shortest path from [source] to [target], if any.
  ParserPath? findPathTo(Parser source, Parser target) {
    assert(parsers.contains(target), 'target is not part of the analyzer');
    return findPath(source, (path) => path.target == target);
  }

  /// Returns all paths starting at [source] that satisfy the given [predicate].
  Iterable<ParserPath> findAllPaths(
      Parser source, Predicate<ParserPath> predicate) {
    assert(parsers.contains(source), 'source is not part of the analyzer');
    return depthFirstSearch(ParserPath([source], []), predicate);
  }

  /// Returns all paths starting at [source] that end in [target].
  Iterable<ParserPath> findAllPathsTo(Parser source, Parser target) {
    assert(parsers.contains(target), 'target is not part of the analyzer');
    return findAllPaths(source, (path) => path.target == target);
  }

  /// Returns `true` if [parser] is transitively nullable, that is it can
  /// successfully parse nothing.
  bool isNullable(Parser parser) => _firstSets[parser]!.contains(sentinel);

  /// Returns the first-set of [parser].
  ///
  /// The first-set of a parser is the set of terminal parsers which can appear
  /// as the first element of any chain of parsers derivable from [parser].
  /// Includes [sentinel], if the set is nullable.
  Iterable<Parser> firstSet(Parser parser) => _firstSets[parser]!;

  late final Map<Parser, Set<Parser>> _firstSets =
      computeFirstSets(parsers: _parsers, sentinel: sentinel);

  /// Returns the follow-set of a [parser].
  ///
  /// The follow-set of a parser is the list of terminal parsers that can
  /// appear immediately after [parser]. Includes [sentinel], if the parse can
  /// complete when starting at [root].
  Iterable<Parser> followSet(Parser parser) => _followSet[parser]!;

  late final Map<Parser, Set<Parser>> _followSet = computeFollowSets(
      root: root, parsers: _parsers, firstSets: _firstSets, sentinel: sentinel);

  /// Returns the cycle-set of a [parser].
  Iterable<Parser> cycleSet(Parser parser) => _cycleSet[parser]!;

  late final Map<Parser, List<Parser>> _cycleSet =
      computeCycleSets(parsers: _parsers, firstSets: _firstSets);

  /// Helper to do a global replace of [source] with [target].
  void replaceAll(Parser source, Parser target) {
    for (final parent in _parsers) {
      parent.replace(source, target);
    }
  }

  /// A unique parser used as a marker in [firstSet] and [followSet]
  /// computations.
  static final EpsilonParser sentinel = EpsilonParser<void>(null);
}
