import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:petitparser/src/reflection/internal/linter_rules.dart';
import 'package:test/test.dart';

// Güting, Erwig, Übersetzerbau, Springer (p.63)
Map<Symbol, Parser> createUebersetzerbau() {
  final grammar = <Symbol, Parser>{};
  grammar[#a] = char('a');
  grammar[#b] = char('b');
  grammar[#c] = char('c');
  grammar[#d] = char('d');
  grammar[#e] = epsilon();
  grammar[#B] = grammar[#b]! | grammar[#e]!;
  grammar[#A] = grammar[#a]! | grammar[#B]!;
  grammar[#S] = grammar[#A]! & grammar[#B]! & grammar[#c]! & grammar[#d]!;
  return grammar;
}

// The canonical grammar to exercise first- and follow-set calculation,
// likely originally from the dragon-book.
Map<Symbol, Parser> createDragon() {
  final grammar = <Symbol, SettableParser>{
    for (final symbol in [#E, #Ep, #T, #Tp, #F]) symbol: undefined(),
  };
  grammar[#E]!.set(grammar[#T]! & grammar[#Ep]!);
  grammar[#Ep]!.set((char('+') & grammar[#T]! & grammar[#Ep]!).optional());
  grammar[#T]!.set(grammar[#F]! & grammar[#Tp]!);
  grammar[#Tp]!.set((char('*') & grammar[#F]! & grammar[#Tp]!).optional());
  grammar[#F]!.set((char('(') & grammar[#E]! & char(')')) | char('i'));
  return grammar;
}

// A highly ambiguous grammar by Saichaitanya Jampana. Exploring the problem of
// ambiguity in context-free grammars.
Map<Symbol, Parser> createAmbiguous() {
  final grammar = <Symbol, SettableParser>{
    for (final symbol in [#S, #A, #a, #B, #b]) symbol: undefined(),
  };
  grammar[#S]!.set((grammar[#A]! & grammar[#B]!) | grammar[#a]!);
  grammar[#A]!.set((grammar[#S]! & grammar[#B]!) | grammar[#b]!);
  grammar[#a]!.set(char('a'));
  grammar[#B]!.set((grammar[#B]! & grammar[#A]!) | grammar[#a]!);
  grammar[#b]!.set(char('b'));
  return grammar;
}

// A highly recursive parser.
Map<Symbol, Parser> createRecursive() {
  final grammar = <Symbol, SettableParser>{
    for (final symbol in [#S, #P, #p, #+]) symbol: undefined(),
  };
  grammar[#S]!.set(grammar[#P]! | grammar[#p]!);
  grammar[#P]!.set(grammar[#S]! & grammar[#+]! & grammar[#S]!);
  grammar[#p]!.set(char('p'));
  grammar[#+]!.set(char('+'));
  return grammar;
}

// A parser that references itself.
Parser createSelfReference() {
  final parser = undefined();
  parser.set(parser);
  return parser;
}

void expectTerminals(Iterable<Parser> parsers, Iterable<String> inputs) {
  final expectedInputs = {...inputs};
  final actualInputs = {
    for (final parser in [for (final parser in parsers) parser.end()])
      for (final character in [
        for (var code = 32; code <= 126; code++) String.fromCharCode(code),
        '',
      ])
        if (parser.accept(character)) character
  };
  expect(actualInputs, expectedInputs);
}

class PluggableLinterRule extends LinterRule {
  const PluggableLinterRule(super.type, super.title, this._run);

  final void Function(LinterRule rule, Analyzer, Parser, LinterCallback) _run;

  @override
  void run(Analyzer analyzer, Parser parser, LinterCallback callback) =>
      _run(this, analyzer, parser, callback);
}

// ignore_for_file: deprecated_member_use_from_same_package
void main() {
  group('analyzer', () {
    test('root', () {
      final parser = char('a').plus();
      final analyzer = Analyzer(parser);
      expect(analyzer.root, parser);
    });
    test('parsers', () {
      final parser = char('a').plus();
      final analyzer = Analyzer(parser);
      expect(analyzer.parsers, {parser, parser.children.first});
    });
    group('allChildren', () {
      test('single', () {
        final inner = char('a');
        final parser = inner.plus();
        final analyzer = Analyzer(parser);
        expect(analyzer.allChildren(parser), {inner});
        expect(analyzer.allChildren(inner), isEmpty);
      });
      test('multiple', () {
        final inner1 = char('a');
        final inner2 = char('b');
        final parser = inner1 & inner2;
        final analyzer = Analyzer(parser);
        expect(analyzer.allChildren(parser), {inner1, inner2});
        expect(analyzer.allChildren(inner1), isEmpty);
        expect(analyzer.allChildren(inner2), isEmpty);
      });
      test('repeated', () {
        final inner1 = char('a');
        final inner2 = char('b');
        final parser = inner1 | inner2 | inner2;
        final analyzer = Analyzer(parser);
        expect(analyzer.allChildren(parser), {inner1, inner2});
        expect(analyzer.allChildren(inner1), isEmpty);
        expect(analyzer.allChildren(inner2), isEmpty);
      });
      test('recursive', () {
        final inner1 = char('a');
        final inner2 = undefined();
        final parser = inner1 | inner2;
        inner2.set(parser);
        final analyzer = Analyzer(parser);
        expect(analyzer.allChildren(parser), {inner1, inner2, parser});
        expect(analyzer.allChildren(inner1), isEmpty);
        expect(analyzer.allChildren(inner2), {inner1, inner2, parser});
      });
      test('übersetzerbau grammar', () {
        final parsers = createUebersetzerbau();
        final analyzer = Analyzer(parsers[#S]!);
        expect(analyzer.allChildren(parsers[#S]!), {
          parsers[#A],
          parsers[#B],
          parsers[#a],
          parsers[#b],
          parsers[#c],
          parsers[#d],
          parsers[#e],
        });
        expect(analyzer.allChildren(parsers[#A]!), {
          parsers[#B],
          parsers[#a],
          parsers[#b],
          parsers[#e],
        });
        expect(analyzer.allChildren(parsers[#B]!), {
          parsers[#b],
          parsers[#e],
        });
        expect(analyzer.allChildren(parsers[#a]!), isEmpty);
        expect(analyzer.allChildren(parsers[#b]!), isEmpty);
        expect(analyzer.allChildren(parsers[#c]!), isEmpty);
        expect(analyzer.allChildren(parsers[#d]!), isEmpty);
        expect(analyzer.allChildren(parsers[#e]!), isEmpty);
      });
      test('recursive grammar', () {
        final parsers = createRecursive();
        final analyzer = Analyzer(parsers[#S]!);
        expect(analyzer.allChildren(parsers[#S]!), analyzer.parsers);
        expect(analyzer.allChildren(parsers[#P]!), analyzer.parsers);
        expect(analyzer.allChildren(parsers[#p]!), {
          parsers[#p]!.children.first,
        });
        expect(analyzer.allChildren(parsers[#+]!), {
          parsers[#+]!.children.first,
        });
      });
      test('self reference', () {
        final parser = createSelfReference();
        final analyzer = Analyzer(parser);
        expect(analyzer.allChildren(parser), {parser});
      });
    });
    group('findPath', () {
      test('simple', () {
        final parser = char('a');
        final analyzer = Analyzer(parser);
        final path = analyzer.findPathTo(parser, parser)!;
        expect(path.source, parser);
        expect(path.target, parser);
        expect(path.parsers, [parser]);
        expect(path.indexes, []);
        final paths = analyzer.findAllPathsTo(parser, parser).toList();
        expect(paths, hasLength(1));
        expect(paths[0].parsers, [parser]);
        expect(paths[0].indexes, []);
      });
      test('choice', () {
        final terminal = char('a');
        final parser = terminal | terminal;
        final analyzer = Analyzer(parser);
        final path = analyzer.findPathTo(parser, terminal)!;
        expect(path.source, parser);
        expect(path.target, terminal);
        expect(path.parsers, [parser, terminal]);
        expect(path.indexes, [0]);
        final paths = analyzer.findAllPathsTo(parser, terminal).toList();
        expect(paths, hasLength(2));
        expect(paths[0].parsers, [parser, terminal]);
        expect(paths[0].indexes, [0]);
        expect(paths[1].parsers, [parser, terminal]);
        expect(paths[1].indexes, [1]);
      });
      test('length', () {
        final terminal = char('a');
        final repeated = terminal.star();
        final parser = repeated | terminal;
        final analyzer = Analyzer(parser);
        final path = analyzer.findPathTo(parser, terminal)!;
        expect(path.source, parser);
        expect(path.target, terminal);
        expect(path.parsers, [parser, terminal]);
        expect(path.indexes, [1]);
        final paths = analyzer.findAllPathsTo(parser, terminal).toList();
        expect(paths, hasLength(2));
        expect(paths[0].parsers, [parser, repeated, terminal]);
        expect(paths[0].indexes, [0, 0]);
        expect(paths[1].parsers, [parser, terminal]);
        expect(paths[1].indexes, [1]);
      });
      test('recursive grammar', () {
        final parsers = createRecursive();
        final analyzer = Analyzer(parsers[#S]!);
        expect(
            analyzer.findAllPaths(analyzer.root, (target) => false), isEmpty);
      });
      test('self reference', () {
        final parser = createSelfReference();
        final analyzer = Analyzer(parser);
        expect(
            analyzer.findAllPaths(analyzer.root, (target) => false), isEmpty);
      });
    });
    group('isNullable', () {
      test('plus', () {
        final parser = char('a').plus();
        final analyzer = Analyzer(parser);
        expect(analyzer.isNullable(parser), isFalse);
      });
      test('star', () {
        final parser = char('a').star();
        final analyzer = Analyzer(parser);
        expect(analyzer.isNullable(parser), isTrue);
      });
      test('optional', () {
        final parser = char('a').optional();
        final analyzer = Analyzer(parser);
        expect(analyzer.isNullable(parser), isTrue);
      });
      test('choice', () {
        final parser = char('a').or(char('b'));
        final analyzer = Analyzer(parser);
        expect(analyzer.isNullable(parser), isFalse);
      });
      test('epsilon choice', () {
        final parser = char('a').or(epsilon());
        final analyzer = Analyzer(parser);
        expect(analyzer.isNullable(parser), isTrue);
      });
      test('sequence', () {
        final parser = char('a').seq(char('b'));
        final analyzer = Analyzer(parser);
        expect(analyzer.isNullable(parser), isFalse);
      });
      test('epsilon sequence', () {
        final parser = epsilon().seq(char('a'));
        final analyzer = Analyzer(parser);
        expect(analyzer.isNullable(parser), isFalse);
      });
      test('optional sequence', () {
        final parser = char('a').optional().seq(char('b'));
        final analyzer = Analyzer(parser);
        expect(analyzer.isNullable(parser), isFalse);
      });
      test('übersetzerbau grammar', () {
        final parsers = createUebersetzerbau();
        final analyzer = Analyzer(parsers[#S]!);
        expect(analyzer.isNullable(parsers[#S]!), isFalse);
        expect(analyzer.isNullable(parsers[#A]!), isTrue);
        expect(analyzer.isNullable(parsers[#B]!), isTrue);
        expect(analyzer.isNullable(parsers[#a]!), isFalse);
        expect(analyzer.isNullable(parsers[#b]!), isFalse);
        expect(analyzer.isNullable(parsers[#c]!), isFalse);
        expect(analyzer.isNullable(parsers[#d]!), isFalse);
        expect(analyzer.isNullable(parsers[#e]!), isTrue);
      });
      test('dragon grammar', () {
        final parsers = createDragon();
        final analyzer = Analyzer(parsers[#E]!);
        expect(analyzer.isNullable(parsers[#E]!), isFalse);
        expect(analyzer.isNullable(parsers[#Ep]!), isTrue);
        expect(analyzer.isNullable(parsers[#T]!), isFalse);
        expect(analyzer.isNullable(parsers[#Tp]!), isTrue);
        expect(analyzer.isNullable(parsers[#F]!), isFalse);
      });
      test('ambiguous grammar', () {
        final parsers = createAmbiguous();
        final analyzer = Analyzer(parsers[#S]!);
        expect(analyzer.isNullable(parsers[#S]!), isFalse);
        expect(analyzer.isNullable(parsers[#A]!), isFalse);
        expect(analyzer.isNullable(parsers[#B]!), isFalse);
        expect(analyzer.isNullable(parsers[#a]!), isFalse);
        expect(analyzer.isNullable(parsers[#b]!), isFalse);
      });
      test('recursive grammar', () {
        final parsers = createRecursive();
        final analyzer = Analyzer(parsers[#S]!);
        expect(analyzer.isNullable(parsers[#S]!), isFalse);
        expect(analyzer.isNullable(parsers[#P]!), isFalse);
        expect(analyzer.isNullable(parsers[#p]!), isFalse);
      });
      test('self reference', () {
        final parser = createSelfReference();
        final analyzer = Analyzer(parser);
        expect(analyzer.isNullable(parser), isFalse);
      });
    });
    group('first-set', () {
      test('plus', () {
        final parser = char('a').plus();
        final analyzer = Analyzer(parser);
        expectTerminals(analyzer.firstSet(parser), ['a']);
      });
      test('star', () {
        final parser = char('a').star();
        final analyzer = Analyzer(parser);
        expectTerminals(analyzer.firstSet(parser), ['a', '']);
      });
      test('optional', () {
        final parser = char('a').optional();
        final analyzer = Analyzer(parser);
        expectTerminals(analyzer.firstSet(parser), ['a', '']);
      });
      test('choice', () {
        final parser = char('a').or(char('b'));
        final analyzer = Analyzer(parser);
        expectTerminals(analyzer.firstSet(parser), ['a', 'b']);
      });
      test('epsilon choice', () {
        final parser = char('a').or(epsilon());
        final analyzer = Analyzer(parser);
        expectTerminals(analyzer.firstSet(parser), ['a', '']);
      });
      test('sequence', () {
        final parser = char('a').seq(char('b'));
        final analyzer = Analyzer(parser);
        expectTerminals(analyzer.firstSet(parser), ['a']);
      });
      test('epsilon sequence', () {
        final parser = epsilon().seq(char('a'));
        final analyzer = Analyzer(parser);
        expectTerminals(analyzer.firstSet(parser), ['a']);
      });
      test('optional sequence', () {
        final parser = char('a').optional().seq(char('b'));
        final analyzer = Analyzer(parser);
        expectTerminals(analyzer.firstSet(parser), ['a', 'b']);
      });
      test('übersetzerbau grammar', () {
        final parsers = createUebersetzerbau();
        final analyzer = Analyzer(parsers[#S]!);
        expectTerminals(analyzer.firstSet(parsers[#S]!), ['a', 'b', 'c']);
        expectTerminals(analyzer.firstSet(parsers[#A]!), ['a', 'b', '']);
        expectTerminals(analyzer.firstSet(parsers[#B]!), ['b', '']);
        expectTerminals(analyzer.firstSet(parsers[#a]!), ['a']);
        expectTerminals(analyzer.firstSet(parsers[#b]!), ['b']);
        expectTerminals(analyzer.firstSet(parsers[#c]!), ['c']);
        expectTerminals(analyzer.firstSet(parsers[#d]!), ['d']);
        expectTerminals(analyzer.firstSet(parsers[#e]!), ['']);
      });
      test('dragon grammar', () {
        final parsers = createDragon();
        final analyzer = Analyzer(parsers[#E]!);
        expectTerminals(analyzer.firstSet(parsers[#E]!), ['(', 'i']);
        expectTerminals(analyzer.firstSet(parsers[#Ep]!), ['+', '']);
        expectTerminals(analyzer.firstSet(parsers[#T]!), ['(', 'i']);
        expectTerminals(analyzer.firstSet(parsers[#Tp]!), ['*', '']);
        expectTerminals(analyzer.firstSet(parsers[#F]!), ['(', 'i']);
      });
      test('ambiguous grammar', () {
        final parsers = createAmbiguous();
        final analyzer = Analyzer(parsers[#S]!);
        expectTerminals(analyzer.firstSet(parsers[#S]!), ['a', 'b']);
        expectTerminals(analyzer.firstSet(parsers[#A]!), ['a', 'b']);
        expectTerminals(analyzer.firstSet(parsers[#B]!), ['a']);
        expectTerminals(analyzer.firstSet(parsers[#a]!), ['a']);
        expectTerminals(analyzer.firstSet(parsers[#b]!), ['b']);
      });
      test('recursive grammar', () {
        final parsers = createRecursive();
        final analyzer = Analyzer(parsers[#S]!);
        expectTerminals(analyzer.firstSet(parsers[#S]!), ['p']);
        expectTerminals(analyzer.firstSet(parsers[#P]!), ['p']);
        expectTerminals(analyzer.firstSet(parsers[#p]!), ['p']);
      });
      test('self reference', () {
        final parser = createSelfReference();
        final analyzer = Analyzer(parser);
        expectTerminals(analyzer.firstSet(parser), []);
      });
    });
    group('follow-set', () {
      test('plus', () {
        final parser = char('a').plus();
        final analyzer = Analyzer(parser);
        expectTerminals(analyzer.followSet(parser), ['']);
        expectTerminals(analyzer.followSet(parser.children[0]), ['a', '']);
      });
      test('star', () {
        final parser = char('a').star();
        final analyzer = Analyzer(parser);
        expectTerminals(analyzer.followSet(parser), ['']);
        expectTerminals(analyzer.followSet(parser.children[0]), ['a', '']);
      });
      test('optional', () {
        final parser = char('a').optional();
        final analyzer = Analyzer(parser);
        expectTerminals(analyzer.followSet(parser), ['']);
        expectTerminals(analyzer.followSet(parser.children[0]), ['']);
      });
      test('choice', () {
        final parser = char('a').or(char('b'));
        final analyzer = Analyzer(parser);
        expectTerminals(analyzer.followSet(parser), ['']);
        expectTerminals(analyzer.followSet(parser.children[0]), ['']);
        expectTerminals(analyzer.followSet(parser.children[1]), ['']);
      });
      test('epsilon choice', () {
        final parser = char('a').or(epsilon());
        final analyzer = Analyzer(parser);
        expectTerminals(analyzer.followSet(parser), ['']);
        expectTerminals(analyzer.followSet(parser.children[0]), ['']);
        expectTerminals(analyzer.followSet(parser.children[1]), ['']);
      });
      test('sequence', () {
        final parser = char('a').seq(char('b'));
        final analyzer = Analyzer(parser);
        expectTerminals(analyzer.followSet(parser), ['']);
        expectTerminals(analyzer.followSet(parser.children[0]), ['b']);
        expectTerminals(analyzer.followSet(parser.children[1]), ['']);
      });
      test('epsilon sequence', () {
        final parser = epsilon().seq(char('a'));
        final analyzer = Analyzer(parser);
        expectTerminals(analyzer.followSet(parser), ['']);
        expectTerminals(analyzer.followSet(parser.children[0]), ['a']);
        expectTerminals(analyzer.followSet(parser.children[1]), ['']);
      });
      test('optional sequence', () {
        final parser = char('a').seq(char('b').optional());
        final analyzer = Analyzer(parser);
        expectTerminals(analyzer.followSet(parser), ['']);
        expectTerminals(analyzer.followSet(parser.children[0]), ['b', '']);
        expectTerminals(analyzer.followSet(parser.children[1]), ['']);
      });
      test('übersetzerbau grammar', () {
        final parsers = createUebersetzerbau();
        final analyzer = Analyzer(parsers[#S]!);
        expectTerminals(analyzer.followSet(parsers[#S]!), ['']);
        expectTerminals(analyzer.followSet(parsers[#A]!), ['b', 'c']);
        expectTerminals(analyzer.followSet(parsers[#B]!), ['b', 'c']);
        expectTerminals(analyzer.followSet(parsers[#a]!), ['b', 'c']);
        expectTerminals(analyzer.followSet(parsers[#b]!), ['b', 'c']);
        expectTerminals(analyzer.followSet(parsers[#c]!), ['d']);
        expectTerminals(analyzer.followSet(parsers[#d]!), ['']);
        expectTerminals(analyzer.followSet(parsers[#e]!), ['b', 'c']);
      });
      test('dragon grammar', () {
        final parsers = createDragon();
        final analyzer = Analyzer(parsers[#E]!);
        expectTerminals(analyzer.followSet(parsers[#E]!), [')', '']);
        expectTerminals(analyzer.followSet(parsers[#Ep]!), [')', '']);
        expectTerminals(analyzer.followSet(parsers[#T]!), [')', '+', '']);
        expectTerminals(analyzer.followSet(parsers[#Tp]!), [')', '+', '']);
        expectTerminals(analyzer.followSet(parsers[#F]!), [')', '+', '*', '']);
      });
      test('ambiguous grammar', () {
        final parsers = createAmbiguous();
        final analyzer = Analyzer(parsers[#S]!);
        expectTerminals(analyzer.followSet(parsers[#S]!), ['a', '']);
        expectTerminals(analyzer.followSet(parsers[#A]!), ['a', 'b', '']);
        expectTerminals(analyzer.followSet(parsers[#B]!), ['a', 'b', '']);
        expectTerminals(analyzer.followSet(parsers[#a]!), ['a', 'b', '']);
        expectTerminals(analyzer.followSet(parsers[#b]!), ['a', 'b', '']);
      });
      test('recursive grammar', () {
        final parsers = createRecursive();
        final analyzer = Analyzer(parsers[#S]!);
        expectTerminals(analyzer.followSet(parsers[#S]!), ['+', '']);
        expectTerminals(analyzer.followSet(parsers[#P]!), ['+', '']);
        expectTerminals(analyzer.followSet(parsers[#p]!), ['+', '']);
      });
      test('self reference', () {
        final parser = createSelfReference();
        final analyzer = Analyzer(parser);
        expectTerminals(analyzer.followSet(parser), ['']);
      });
    });
    group('cycle-set', () {
      test('übersetzerbau grammar', () {
        final parsers = createUebersetzerbau();
        final analyzer = Analyzer(parsers[#S]!);
        for (final parser in parsers.values) {
          expect(analyzer.cycleSet(parser), isEmpty);
        }
      });
      test('dragon grammar', () {
        final parsers = createDragon();
        final analyzer = Analyzer(parsers[#E]!);
        for (final parser in parsers.values) {
          expect(analyzer.cycleSet(parser), isEmpty);
        }
      });
      test('ambiguous grammar', () {
        final parsers = createAmbiguous();
        final analyzer = Analyzer(parsers[#S]!);
        expect(analyzer.cycleSet(parsers[#S]!),
            allOf(hasLength(6), containsAll([parsers[#S]!, parsers[#A]!])));
        expect(analyzer.cycleSet(parsers[#A]!),
            allOf(hasLength(6), containsAll([parsers[#S]!, parsers[#A]!])));
        expect(analyzer.cycleSet(parsers[#B]!),
            allOf(hasLength(3), containsAll([parsers[#B]!])));
        expect(analyzer.cycleSet(parsers[#a]!), isEmpty);
        expect(analyzer.cycleSet(parsers[#b]!), isEmpty);
      });
      test('recursive grammar', () {
        final parsers = createRecursive();
        final analyzer = Analyzer(parsers[#S]!);
        expect(analyzer.cycleSet(parsers[#S]!),
            allOf(hasLength(4), containsAll([parsers[#S]!, parsers[#P]!])));
        expect(analyzer.cycleSet(parsers[#P]!),
            allOf(hasLength(4), containsAll([parsers[#S]!, parsers[#P]!])));
        expect(analyzer.cycleSet(parsers[#p]!), isEmpty);
      });
      test('self reference', () {
        final parser = createSelfReference();
        final analyzer = Analyzer(parser);
        expect(analyzer.cycleSet(parser),
            allOf(hasLength(1), containsAll([parser])));
      });
    });
  });
  group('iterable', () {
    test('single', () {
      final parser1 = lowercase();
      final parsers = allParser(parser1).toList();
      expect(parsers, [parser1]);
    });
    test('nested', () {
      final parser3 = lowercase();
      final parser2 = parser3.star();
      final parser1 = parser2.flatten();
      final parsers = allParser(parser1).toList();
      expect(parsers, [parser1, parser2, parser3]);
    });
    test('branched', () {
      final parser3 = lowercase();
      final parser2 = uppercase();
      final parser1 = parser2.seq(parser3);
      final parsers = allParser(parser1).toList();
      expect(parsers, [parser1, parser2, parser3]);
    });
    test('duplicated', () {
      final parser2 = uppercase();
      final parser1 = parser2.seq(parser2);
      final parsers = allParser(parser1).toList();
      expect(parsers, [parser1, parser2]);
    });
    test('knot', () {
      final parser1 = undefined();
      parser1.set(parser1);
      final parsers = allParser(parser1).toList();
      expect(parsers, [parser1]);
    });
    test('looping', () {
      final parser1 = undefined();
      final parser2 = undefined();
      final parser3 = undefined();
      parser1.set(parser2);
      parser2.set(parser3);
      parser3.set(parser1);
      final parsers = allParser(parser1).toList();
      expect(parsers, [parser1, parser2, parser3]);
    });
  });
  group('linter', () {
    test('rules called on all parsers', () {
      final seen = <Parser>{};
      final input = char('a') | char('b');
      final rule = PluggableLinterRule(LinterType.error, 'Fake Rule',
          (rule, analyzer, parser, callback) => seen.add(parser));
      final results = linter(input,
          rules: [rule], callback: (issue) => fail('Unexpected callback'));
      expect(results, isEmpty);
      expect(seen, {input, input.children[0], input.children[1]});
    });
    test('issue triggered', () {
      final input = 'trigger'.toParser();
      final called = <LinterIssue>[];
      final rule = PluggableLinterRule(LinterType.error, 'Fake Rule',
          (rule, analyzer, parser, callback) {
        expect(parser, same(input));
        callback(LinterIssue(rule, parser, 'Described'));
      });
      expect(rule.toString(),
          'LinterRule(type: LinterType.error, title: Fake Rule)');
      final results = linter(input, rules: [rule], callback: called.add);
      expect(results, [
        isA<LinterIssue>()
            .having((issue) => issue.rule, 'rule', same(rule))
            .having((issue) => issue.type, 'type', LinterType.error)
            .having((issue) => issue.title, 'title', 'Fake Rule')
            .having((issue) => issue.parser, 'parser', same(input))
            .having((issue) => issue.description, 'description', 'Described')
            .having((issue) => issue.fixer, 'fixer', isNull)
            .having(
                (issue) => issue.toString(),
                'toString',
                'LinterIssue(type: LinterType.error, title: Fake Rule, '
                    'parser: Instance of \'PredicateParser\'["trigger" '
                    'expected], description: Described)')
      ]);
      expect(called, results);
    });
    group('rules', () {
      test('unresolved settable', () {
        final parser = undefined().optional();
        final results = linter(parser, rules: const [UnresolvedSettable()]);
        expect(results, hasLength(1));
        final result = results[0];
        expect(result.parser, parser.children[0]);
        expect(result.type, LinterType.error);
        expect(result.title, 'Unresolved settable');
      });
      test('unnecessary resolvable', () {
        final parser = char('a').settable().optional();
        final results = linter(parser, rules: const [UnnecessaryResolvable()]);
        expect(results, hasLength(1));
        final result = results[0];
        expect(result.parser, parser.children[0]);
        expect(result.type, LinterType.warning);
        expect(result.title, 'Unnecessary resolvable');
        result.fixer!();
        expect(parser.isEqualTo(char('a').optional()), isTrue);
      });
      test('nested choice', () {
        final parser = [
          char('1'),
          [char('2'), char('3')].toChoiceParser(),
          char('4'),
        ].toChoiceParser().optional();
        final results = linter(parser, rules: const [NestedChoice()]);
        expect(results, hasLength(1));
        final result = results[0];
        expect(result.parser, parser.children[0]);
        expect(result.type, LinterType.info);
        expect(result.title, 'Nested choice');
        result.fixer!();
        expect(
            parser.children[0].children,
            pairwiseCompare<Parser, Parser>(
                [char('1'), char('2'), char('3'), char('4')],
                (a, b) => a.isEqualTo(b),
                'Equal parsers'));
      });
      test('repeated choice', () {
        final parser = [
          char('1'),
          char('2'),
          char('3'),
          char('2'),
          char('4'),
        ].toChoiceParser().optional();
        final results = linter(parser, rules: const [RepeatedChoice()]);
        expect(results, hasLength(1));
        final result = results[0];
        expect(result.parser, parser.children[0]);
        expect(result.type, LinterType.warning);
        expect(result.title, 'Repeated choice');
        result.fixer!();
        expect(
            parser.children[0].children,
            pairwiseCompare<Parser, Parser>(
                [char('1'), char('3'), char('2'), char('4')],
                (a, b) => a.isEqualTo(b),
                'Equal parsers'));
      });
      test('overlapping choice', () {
        final parser = [
          char('1'),
          char('2') & char('a'),
          char('2') & char('b'),
          char('3'),
        ].toChoiceParser().optional();
        final results = linter(parser, rules: const [OverlappingChoice()]);
        expect(results, hasLength(1));
        final result = results[0];
        expect(result.parser, parser.children[0]);
        expect(result.type, LinterType.info);
        expect(result.title, 'Overlapping choice');
      });
      test('unreachable choice', () {
        final parser = [
          char('1'),
          char('2'),
          epsilon(),
          char('3'),
        ].toChoiceParser().optional();
        final results = linter(parser, rules: const [UnreachableChoice()]);
        expect(results, hasLength(1));
        final result = results[0];
        expect(result.parser, parser.children[0]);
        expect(result.type, LinterType.warning);
        expect(result.title, 'Unreachable choice');
        result.fixer!();
        expect(
            parser.children[0].children,
            pairwiseCompare<Parser, Parser>([char('1'), char('2'), epsilon()],
                (a, b) => a.isEqualTo(b), 'Equal parsers'));
      });
      test('nullable repeater', () {
        final parser = epsilon().star().optional();
        final results = linter(parser, rules: const [NullableRepeater()]);
        expect(results, hasLength(1));
        final result = results[0];
        expect(result.parser, parser.children[0]);
        expect(result.type, LinterType.error);
        expect(result.title, 'Nullable repeater');
      });
      test('left recursion', () {
        final parser = createSelfReference().optional();
        final results = linter(parser, rules: const [LeftRecursion()]);
        expect(results, hasLength(1));
        final result = results[0];
        expect(result.parser, parser.children[0]);
        expect(result.type, LinterType.error);
        expect(result.title, 'Left recursion');
      });
      test('unused result', () {
        final parser = digit().map(int.parse).star().flatten();
        final results = linter(parser, rules: const [UnusedResult()]);
        expect(results, hasLength(1));
        final result = results[0];
        expect(result.parser, parser);
        expect(result.type, LinterType.info);
        expect(result.title, 'Unused result');
      });
    });
    group('regressions', () {
      test('separatedBy and nullable repeater', () {
        const rules = [NullableRepeater()];
        // Both repeater and separator are nullable, this might cause an
        // infinite loop.
        expect(linter(epsilon().starSeparated(epsilon()), rules: rules),
            hasLength(1));
        // If either the repeater or the separator is non-nullable, everything
        // is fine.
        expect(linter(epsilon().starSeparated(any()), rules: rules), isEmpty);
        expect(linter(any().starSeparated(epsilon()), rules: rules), isEmpty);
      });
    });
  });
  group('transform', () {
    test('copy', () {
      final input = lowercase().settable();
      final output = transformParser(input, <T>(parser) => parser);
      expect(input, isNot(output));
      expect(input.isEqualTo(output), isTrue);
      expect(input.children.single, isNot(output.children.single));
    });
    test('root', () {
      final source = lowercase();
      final input = source;
      final target = uppercase();
      final output = transformParser(input, <T>(parser) {
        return source.isEqualTo(parser) ? target as Parser<T> : parser;
      });
      expect(input, isNot(output));
      expect(input.isEqualTo(output), isFalse);
      expect(input, source);
      expect(output, target);
    });
    test('single', () {
      final source = lowercase();
      final input = source.settable();
      final target = uppercase();
      final output = transformParser(input, <T>(parser) {
        return source.isEqualTo(parser) ? target as Parser<T> : parser;
      });
      expect(input, isNot(output));
      expect(input.isEqualTo(output), isFalse);
      expect(input.children.single, source);
      expect(output.children.single, target);
    });
    test('double', () {
      final source = lowercase();
      final input = source & source;
      final target = uppercase();
      final output = transformParser(input, <T>(parser) {
        return source.isEqualTo(parser) ? target as Parser<T> : parser;
      });
      expect(input, isNot(output));
      expect(input.isEqualTo(output), isFalse);
      expect(input.isEqualTo(source & source), isTrue);
      expect(input.children.first, input.children.last);
      expect(output.isEqualTo(target & target), isTrue);
      expect(output.children.first, output.children.last);
    });
    test('loop (existing)', () {
      final inner = failure().settable();
      final outer = inner.settable().settable();
      inner.set(outer);
      final output = transformParser(outer, <T>(parser) {
        return parser;
      });
      expect(outer, isNot(output));
      expect(outer.isEqualTo(output), isTrue);
      final inputs = allParser(outer).toSet();
      final outputs = allParser(output).toSet();
      for (final input in inputs) {
        expect(outputs.contains(input), isFalse);
      }
      for (final output in outputs) {
        expect(inputs.contains(output), isFalse);
      }
    });
    test('loop (new)', () {
      final source = lowercase();
      final input = source;
      final inner = failure<String>().settable();
      final outer = inner.settable().settable();
      inner.set(outer);
      final output = transformParser(
          input,
          <T>(parser) =>
              source.isEqualTo(parser) ? outer as Parser<T> : parser);
      expect(input, isNot(output));
      expect(input.isEqualTo(output), isFalse);
      expect(output.isEqualTo(outer), isTrue);
    });
  });
  group('optimize', () {
    group('remove settables', () {
      test('basic settables', () {
        final input = lowercase().settable();
        final output = removeSettables(input);
        expect(output.isEqualTo(lowercase()), isTrue);
      });
      test('nested settables', () {
        final input = lowercase().settable().star();
        final output = removeSettables(input);
        expect(output.isEqualTo(lowercase().star()), isTrue);
      });
      test('double settables', () {
        final input = lowercase().settable().settable();
        final output = removeSettables(input);
        expect(output.isEqualTo(lowercase()), isTrue);
      });
    });
    test('remove duplicate', () {
      final input = lowercase() & lowercase();
      final output = removeDuplicates(input);
      expect(input.isEqualTo(output), isTrue);
      expect(input.children.first, isNot(input.children.last));
      expect(output.children.first, output.children.last);
    });
  });
}
