import 'package:args/args.dart';
import 'package:completion/src/get_args_completions.dart';
import 'package:test/test.dart';

import 'completion_tests_args.dart';

void main() {
  group('hello world sample', () {
    final parser = getHelloSampleParser();

    final allOptions = _getAllOptions(parser);

    final pairs = [
      _CompletionSet('empty input, just give all the commands', [],
          parser.commands.keys.toList()),
      _CompletionSet('just a dash: should be empty. Vague', ['-'], []),
      _CompletionSet('double-dash, give all the options', ['--'], allOptions),
      _CompletionSet(
          '+flag complete --frie to --friendly', ['--frie'], ['--friendly']),
      _CompletionSet('+flag complete full, final option to itself',
          ['--friendly'], ['--friendly']),
      _CompletionSet("+command starting to complete 'help' - finish with help",
          ['he'], ['help']),
      _CompletionSet(
          "+command all of 'help' - finish with help", ['help'], ['help']),
      _CompletionSet('too much', ['helpp'], []),
      _CompletionSet('wrong case', ['Help'], []),
      _CompletionSet(
          "+command complete 'assistance'", ['help', 'assist'], ['assistance']),
      _CompletionSet('show the yell flag for help', ['help', '--'],
          ['--yell', '--no-yell']),
      _CompletionSet("+command help - complete '--n' to '--no-yell'",
          ['help', '--n'], ['--no-yell']),
      _CompletionSet('+command help has sub-command - assistance', ['help', ''],
          ['assistance']),
      _CompletionSet("+flag don't offer --friendly twice", ['--friendly', '--'],
          ['--loud', '--no-loud', '--salutation', '--middle-name']),
      _CompletionSet(
          "+abbr+flag+no-multiple don't offer --friendly twice, even if the "
          'first one is the abbreviation',
          ['-f', '--'],
          ['--loud', '--no-loud', '--salutation', '--middle-name']),
      _CompletionSet("+flag+no-multiple don't complete a second --friendly",
          ['--friendly', '--friend'], []),
      _CompletionSet(
          "+abbr+flag+no-multiple don't complete a second --friendly, even if "
          'the first one is the abbreviation',
          ['-f', '--friend'],
          []),
      _CompletionSet(
          "+flag+negatable+no-multiple don't complete the opposite of a "
          'negatable - 1',
          ['--no-loud', '--'],
          ['--friendly', '--salutation', '--middle-name']),
      _CompletionSet(
          "+flag+negatable+no-multiple don't complete the opposite of a "
          'negatable - 2',
          ['--loud', '--'],
          ['--friendly', '--salutation', '--middle-name']),
      _CompletionSet(
        "+option+no-allowed+multiple okay to have multiple 'multiple' options",
        ['--middle-name', 'Robert', '--'],
        allOptions,
      ),
      _CompletionSet(
          "+option+no-allowed+multiple okay to have multiple 'multiple' "
          'options, even abbreviations',
          ['-m', '"John Davis"', '--'],
          allOptions),
      _CompletionSet(
        "+option+no-allowed don't suggest if an option is waiting for a value",
        ['--middle-name', ''],
        [],
      ),
      _CompletionSet(
          "+abbr+option+no-allowed don't suggest if an option is waiting for a "
          'value',
          ['-m', ''],
          []),
      _CompletionSet(
          '+option+allowed suggest completions for an option with allowed '
          'defined',
          ['--salutation', ''],
          ['Mr', 'Mrs', 'Dr', 'Ms']),
      _CompletionSet(
          '+option+allowed finish a completion for an option (added via abbr) '
          'with allowed defined',
          ['-s', 'M'],
          ['Mr', 'Mrs', 'Ms']),
      _CompletionSet("+abbr+option+allowed don't finish a bad completion",
          ['-s', 'W'], []),
      _CompletionSet(
          '+abbr+option+allowed confirm a completion', ['-s', 'Dr'], ['Dr']),
      _CompletionSet(
          '+abbr+option+allowed back to command completion after a completed '
          'option',
          ['-s', 'Dr', ''],
          ['help']),
      _CompletionSet(
          '+abbr+option+allowed back to option completion after a completed '
          'option',
          ['-s', 'Dr', '--'],
          ['--friendly', '--loud', '--no-loud', '--middle-name']),
    ];

    test('compPoint not at the end', () {
      const compLine = 'help';
      final args = ['help'];

      _testCompletionPair(parser, args, ['help'], compLine, compLine.length);
      _testCompletionPair(parser, args, [], compLine, compLine.length - 1);
    });

    for (var p in pairs) {
      final compLine = p.args.join(' ');
      final compPoint = compLine.length;
      final args = p.args.toList();

      test(p.description, () {
        _testCompletionPair(parser, args, p.suggestions, compLine, compPoint);
      });
    }
  });
}

List<String> _getAllOptions(ArgParser parser) {
  final list = <String>[];

  parser.options.forEach((k, v) {
    if (k != v.name) {
      throw StateError('Boo!');
    }

    list.add(_optionIze(k));

    if (v.negatable!) {
      list.add(_optionIze('no-$k'));
    }
  });

  return list;
}

String _optionIze(String input) => '--$input';

void _testCompletionPair(ArgParser parser, List<String> args,
    List<String> suggestions, String compLine, int compPoint) {
  final completions = getArgsCompletions(parser, args, compLine, compPoint);

  expect(completions, unorderedEquals(suggestions),
      reason: 'for args: $args expected: $suggestions but got: $completions');
}

class _CompletionSet {
  final String description;
  final List<String> args;
  final List<String> suggestions;

  _CompletionSet(this.description, this.args, this.suggestions);
}
