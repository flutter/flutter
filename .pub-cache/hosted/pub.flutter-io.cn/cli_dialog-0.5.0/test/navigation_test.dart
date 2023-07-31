import 'package:test/test.dart';
import 'package:cli_dialog/cli_dialog.dart';
import 'package:cli_dialog/src/xterm.dart';

void main() {
  late StdoutService std_output;
  late StdinService std_input;

  setUp(() {
    std_output = StdoutService(mock: true);
    std_input =
        StdinService(mock: true, informStdout: std_output, isTest: true);
  });

  test('Navigation with standard order', () {
    std_input.addToBuffer([
      ':2\n', // navigate to two
      'no\n', // answer two
      ...Keys.arrowDown,
      58, '1\n', // navigate to one
      'my answer\n', // answer one
      ':3\n', // navigate to 3
      ...Keys.arrowDown,
      ...Keys.arrowDown,
      Keys.enter // answer three
    ]);
    final dialog = CLI_Dialog.std(std_input, std_output, navigationMode: true);
    dialog.addQuestion('Question 1', 'answer1');
    dialog.addQuestion('Question 2', 'answer2', is_boolean: true);
    dialog.addQuestion({
      'question': 'Question 3',
      'options': ['option 1', 'option2', 'option3']
    }, 'answer3', is_list: true);
    final answers = dialog.ask();
    expect(answers,
        {'answer1': 'my answer', 'answer2': false, 'answer3': 'option3'});
  });

  test('Navigation with custom order', () {
    std_input.addToBuffer([':2\n', ':1\n', 'Yes\n', 'Dart\n']);
    final dialog = CLI_Dialog.std(std_input, std_output,
        navigationMode: true, order: ['is-dart-fan', 'fav-lang']);
    dialog.addQuestion(
        'What is your favourite programming language?', 'fav-lang');
    dialog.addQuestion('Are you a Dart fan?', 'is-dart-fan', is_boolean: true);
    final answers = dialog.ask();
    expect(answers, {'is-dart-fan': true, 'fav-lang': 'Dart'});
  });

  test('Messages are excluded from navigation', () {
    std_input.addToBuffer([':2\n', ':1\n', 'Some input\n', 'Never\n']);
    final messages = [
      ['Hello', 'msg1'],
      ['Hi', 'msg2']
    ];
    final dialog = CLI_Dialog.std(std_input, std_output,
        navigationMode: true,
        messages: messages,
        order: ['msg2', 'question2', 'msg1', 'question1']);
    dialog.addQuestion('Can you answer this question?', 'question1',
        is_boolean: true);
    dialog.addQuestion('I expect some input here:', 'question2');
    final answers = dialog.ask();
    expect(answers, {'question1': false, 'question2': 'Some input'});
  });
}
