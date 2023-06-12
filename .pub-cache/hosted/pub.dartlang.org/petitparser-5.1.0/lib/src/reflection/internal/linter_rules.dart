import '../../core/parser.dart';
import '../../parser/action/cast.dart';
import '../../parser/action/cast_list.dart';
import '../../parser/action/flatten.dart';
import '../../parser/action/map.dart';
import '../../parser/action/permute.dart';
import '../../parser/action/pick.dart';
import '../../parser/action/token.dart';
import '../../parser/action/where.dart';
import '../../parser/combinator/choice.dart';
import '../../parser/combinator/settable.dart';
import '../../parser/misc/failure.dart';
import '../../parser/repeater/repeating.dart';
import '../../parser/utils/resolvable.dart';
import '../../parser/utils/sequential.dart';
import '../analyzer.dart';
import '../linter.dart';
import 'utilities.dart';

class UnresolvedSettable extends LinterRule {
  const UnresolvedSettable() : super(LinterType.error, 'Unresolved settable');

  @override
  void run(Analyzer analyzer, Parser parser, LinterCallback callback) {
    if (parser is SettableParser && parser.delegate is FailureParser) {
      callback(LinterIssue(
          this,
          parser,
          'This error is typically a bug in the code where a recursive '
          'grammar was created with `undefined()` that has not been '
          'resolved.'));
    }
  }
}

class UnnecessaryResolvable extends LinterRule {
  const UnnecessaryResolvable()
      : super(LinterType.warning, 'Unnecessary resolvable');

  @override
  void run(Analyzer analyzer, Parser parser, LinterCallback callback) {
    if (parser is ResolvableParser) {
      callback(LinterIssue(
          this,
          parser,
          'Resolvable parsers are used during construction of recursive '
          'grammars. While they typically dispatch to their delegate, '
          'they add unnecessary overhead and can be avoided by removing '
          'them before parsing using `resolve(parser)`.',
          () => analyzer.replaceAll(parser, parser.resolve())));
    }
  }
}

class NestedChoice extends LinterRule {
  const NestedChoice() : super(LinterType.info, 'Nested choice');

  @override
  void run(Analyzer analyzer, Parser parser, LinterCallback callback) {
    if (parser is ChoiceParser) {
      final children = parser.children;
      for (var i = 0; i < children.length - 1; i++) {
        if (children[i] is ChoiceParser) {
          callback(LinterIssue(
              this,
              parser,
              'The choice at index $i is another choice that adds unnecessary '
              'overhead that can be avoided by flattening it into the '
              'parent.',
              () => analyzer.replaceAll(
                  parser,
                  parser.captureResultGeneric(<T>(_) => <Parser<T>>[
                        ...children.sublist(0, i).cast<Parser<T>>(),
                        ...children[i].children.cast<Parser<T>>(),
                        ...children.sublist(i + 1).cast<Parser<T>>(),
                      ].toChoiceParser()))));
        }
      }
    }
  }
}

class RepeatedChoice extends LinterRule {
  const RepeatedChoice() : super(LinterType.warning, 'Repeated choice');

  @override
  void run(Analyzer analyzer, Parser parser, LinterCallback callback) {
    if (parser is ChoiceParser) {
      final children = parser.children;
      for (var i = 0; i < children.length; i++) {
        for (var j = i + 1; j < children.length; j++) {
          if (children[i].isEqualTo(children[j])) {
            callback(LinterIssue(
                this,
                parser,
                'The choices at index $i and $j are identical '
                '(${children[i]}). The second choice can never succeed and '
                'can therefore be removed.',
                () => analyzer.replaceAll(
                    parser,
                    parser.captureResultGeneric(<T>(_) => <Parser<T>>[
                          ...children.sublist(0, i).cast<Parser<T>>(),
                          ...children.sublist(i + 1).cast<Parser<T>>(),
                        ].toChoiceParser()))));
          }
        }
      }
    }
  }
}

class OverlappingChoice extends LinterRule {
  const OverlappingChoice() : super(LinterType.info, 'Overlapping choice');

  @override
  void run(Analyzer analyzer, Parser parser, LinterCallback callback) {
    if (parser is ChoiceParser) {
      final children = parser.children;
      for (var i = 0; i < children.length; i++) {
        final firstI = analyzer.firstSet(children[i]);
        for (var j = i + 1; j < children.length; j++) {
          final firstJ = analyzer.firstSet(children[j]);
          if (isParserIterableEqual(firstI, firstJ)) {
            callback(LinterIssue(
                this,
                parser,
                'The choices at index $i and $j have overlapping first-sets '
                '(${firstI.join(', ')}), which can be an indication of '
                'an inefficient grammar. If possible, try extracting '
                'common prefixes from choices.'));
          }
        }
      }
    }
  }
}

class UnreachableChoice extends LinterRule {
  const UnreachableChoice() : super(LinterType.warning, 'Unreachable choice');

  @override
  void run(Analyzer analyzer, Parser parser, LinterCallback callback) {
    if (parser is ChoiceParser) {
      final children = parser.children;
      for (var i = 0; i < children.length - 1; i++) {
        if (analyzer.isNullable(children[i])) {
          callback(LinterIssue(
              this,
              parser,
              'The choice at index $i is nullable (${children[i]}), thus the '
              'choices after that (${children.sublist(i + 1).join(', ')}) '
              'can never be reached and can be removed.',
              () => analyzer.replaceAll(
                  parser, children.sublist(0, i + 1).toChoiceParser())));
        }
      }
    }
  }
}

class NullableRepeater extends LinterRule {
  const NullableRepeater() : super(LinterType.error, 'Nullable repeater');

  @override
  void run(Analyzer analyzer, Parser parser, LinterCallback callback) {
    if (parser is RepeatingParser) {
      final isNullable = parser is SequentialParser
          ? parser.children.every((each) => analyzer.isNullable(each))
          : analyzer.isNullable(parser.delegate);
      if (isNullable) {
        callback(LinterIssue(
            this,
            parser,
            'A repeater that delegates to a nullable parser causes an infinite '
            'loop when parsing.'));
      }
    }
  }
}

class LeftRecursion extends LinterRule {
  const LeftRecursion() : super(LinterType.error, 'Left recursion');

  @override
  void run(Analyzer analyzer, Parser parser, LinterCallback callback) {
    if (analyzer.cycleSet(parser).isNotEmpty) {
      callback(LinterIssue(
          this,
          parser,
          'The parsers directly or indirectly refers to itself without '
          'consuming input: ${analyzer.cycleSet(parser)}. This causes an '
          'infinite loop when parsing.'));
    }
  }
}

class UnusedResult extends LinterRule {
  const UnusedResult() : super(LinterType.info, 'Unused result');

  @override
  void run(Analyzer analyzer, Parser parser, LinterCallback callback) {
    if (parser is FlattenParser) {
      final deepChildren = analyzer.allChildren(parser);
      final ignoredResults = deepChildren
          .where((parser) =>
              parser is CastParser ||
              parser is CastListParser ||
              parser is FlattenParser ||
              parser is MapParser ||
              parser is PermuteParser ||
              parser is PickParser ||
              parser is TokenParser ||
              parser is WhereParser)
          .toSet();
      if (ignoredResults.isNotEmpty) {
        final path = analyzer.findPath(
            parser, (path) => ignoredResults.contains(path.target))!;
        final description = [
          for (var i = 0; i < path.indexes.length; i++)
            '${path.indexes[i]}: ${path.parsers[i + 1]}'
        ].join(', ');
        callback(LinterIssue(
            this,
            parser,
            'The flatten parser discards the result of its children and '
            'instead returns the consumed input. Yet this flatten parser '
            'refers (indirectly) to one or more other parsers that explicitly '
            'produce a result which is then ignored when called from this '
            'context: $description. This might point to an inefficient grammar '
            'or a possible bug.'));
      }
    }
  }
}
