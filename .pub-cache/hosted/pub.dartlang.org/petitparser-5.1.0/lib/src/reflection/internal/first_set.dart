import '../../core/parser.dart';
import 'utilities.dart';

Map<Parser, Set<Parser>> computeFirstSets({
  required Iterable<Parser> parsers,
  required Parser sentinel,
}) {
  final firstSets = {
    for (final parser in parsers)
      parser: {
        if (isTerminal(parser)) parser,
        if (isNullable(parser)) sentinel,
      }
  };
  var changed = false;
  do {
    changed = false;
    for (final parser in parsers) {
      changed |= expandFirstSet(
          parser: parser, firstSets: firstSets, sentinel: sentinel);
    }
  } while (changed);
  return firstSets;
}

bool expandFirstSet({
  required Parser parser,
  required Map<Parser, Set<Parser>> firstSets,
  required Parser sentinel,
}) {
  var changed = false;
  final firstSet = firstSets[parser]!;
  if (isSequence(parser)) {
    for (final child in parser.children) {
      var nullable = false;
      for (final first in firstSets[child]!) {
        if (isNullable(first)) {
          nullable = true;
        } else {
          changed |= firstSet.add(first);
        }
      }
      if (!nullable) {
        return changed;
      }
    }
    changed |= firstSet.add(sentinel);
  } else {
    for (final child in parser.children) {
      changed |= addAll(firstSet, firstSets[child]!);
    }
  }
  return changed;
}
