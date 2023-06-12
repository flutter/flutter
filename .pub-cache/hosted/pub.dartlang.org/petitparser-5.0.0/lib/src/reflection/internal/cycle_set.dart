import '../../core/parser.dart';
import 'utilities.dart';

Map<Parser, List<Parser>> computeCycleSets({
  required Iterable<Parser> parsers,
  required Map<Parser, Set<Parser>> firstSets,
}) {
  final cycleSets = <Parser, List<Parser>>{};
  for (final parser in parsers) {
    computeCycleSet(parser: parser, firstSets: firstSets, cycleSets: cycleSets);
  }
  return cycleSets;
}

void computeCycleSet({
  required Parser parser,
  required Map<Parser, Set<Parser>> firstSets,
  required Map<Parser, List<Parser>> cycleSets,
  List<Parser>? stack,
}) {
  if (cycleSets.containsKey(parser)) {
    return;
  }
  if (isTerminal(parser)) {
    cycleSets[parser] = const <Parser>[];
    return;
  }
  stack ??= <Parser>[parser];
  final children = computeCycleChildren(parser: parser, firstSets: firstSets);
  for (final child in children) {
    final index = stack.indexOf(child);
    if (index >= 0) {
      final cycle = stack.sublist(index);
      for (final parser in cycle) {
        cycleSets[parser] = cycle;
      }
      return;
    } else {
      stack.add(child);
      computeCycleSet(
          parser: child,
          firstSets: firstSets,
          cycleSets: cycleSets,
          stack: stack);
      stack.removeLast();
    }
  }
  if (!cycleSets.containsKey(parser)) {
    cycleSets[parser] = const <Parser>[];
    return;
  }
}

List<Parser> computeCycleChildren({
  required Parser parser,
  required Map<Parser, Set<Parser>> firstSets,
}) {
  if (isSequence(parser)) {
    final children = <Parser>[];
    for (final child in parser.children) {
      children.add(child);
      if (!firstSets[child]!.any(isNullable)) {
        break;
      }
    }
    return children;
  }
  return parser.children;
}
