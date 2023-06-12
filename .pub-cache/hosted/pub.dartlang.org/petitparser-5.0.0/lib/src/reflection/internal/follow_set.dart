import '../../core/parser.dart';
import '../../parser/repeater/repeating.dart';
import 'utilities.dart';

Map<Parser, Set<Parser>> computeFollowSets({
  required Parser root,
  required Iterable<Parser> parsers,
  required Map<Parser, Set<Parser>> firstSets,
  required Parser sentinel,
}) {
  final followSets = {
    for (final parser in parsers)
      parser: {
        if (parser == root) sentinel,
      }
  };
  var changed = false;
  do {
    changed = false;
    for (final parser in parsers) {
      changed |= expandFollowSet(
          parser: parser, followSets: followSets, firstSets: firstSets);
    }
  } while (changed);
  return followSets;
}

bool expandFollowSet({
  required Parser parser,
  required Map<Parser, Set<Parser>> followSets,
  required Map<Parser, Set<Parser>> firstSets,
}) {
  if (isSequence(parser)) {
    return expandFollowSetOfSequence(
      parser: parser,
      children: parser.children,
      followSets: followSets,
      firstSets: firstSets,
    );
  } else if (parser is RepeatingParser) {
    return expandFollowSetOfSequence(
      parser: parser,
      children: [
        parser.children[0],
        ...parser.children,
      ],
      followSets: followSets,
      firstSets: firstSets,
    );
  } else {
    var changed = false;
    for (final child in parser.children) {
      changed |= addAll(followSets[child]!, followSets[parser]!);
    }
    return changed;
  }
}

bool expandFollowSetOfSequence({
  required Parser parser,
  required List<Parser> children,
  required Map<Parser, Set<Parser>> followSets,
  required Map<Parser, Set<Parser>> firstSets,
}) {
  var changed = false;
  for (var i = 0; i < children.length; i++) {
    if (i == children.length - 1) {
      changed |= addAll(followSets[children[i]]!, followSets[parser]!);
    } else {
      final firstSet = <Parser>{};
      var j = i + 1;
      for (; j < children.length; j++) {
        firstSet.addAll(firstSets[children[j]]!);
        if (!firstSets[children[j]]!.any(isNullable)) {
          break;
        }
      }
      if (j == children.length) {
        changed |= addAll(followSets[children[i]]!, followSets[parser]!);
      }
      changed |= addAll(followSets[children[i]]!,
          firstSet.where((each) => !isNullable(each)));
    }
  }
  return changed;
}
