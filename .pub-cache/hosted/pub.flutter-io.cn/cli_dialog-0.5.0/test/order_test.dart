import 'package:cli_dialog/src/xterm.dart';
import 'package:test/test.dart';
import 'package:cli_dialog/src/services.dart';
import 'package:cli_dialog/src/dialog.dart';
import 'test_utils.dart';

void main() {
  late StdoutService std_output;
  late StdinService std_input;

  setUp(() {
    std_output = StdoutService(mock: true);
    std_input =
        StdinService(mock: true, informStdout: std_output, isTest: true);
  });

  test('Order is respected', () {
    const questions = [
      ['Whats´up?', 'B']
    ];

    const booleanQuestions = [
      ['Are you serious right now?', 'C'],
      ['Really?', 'A'],
    ];

    const order = ['C', 'A', 'B'];

    std_input.addToBuffer(['Not really\n', 'Yes\n', 'Nothing\n']);

    final dialog = CLI_Dialog.std(std_input, std_output,
        questions: questions, booleanQuestions: booleanQuestions, order: order);
    final answer = dialog.ask();

    const expectedAnswer = {
      'C': false,
      'A': true,
      'B': 'Nothing',
    };

    final expectedOutput = '''
${booleanQnA('Are you serious right now?', 'No')}
${booleanQnA('Really?', 'Yes')}
${QnA('Whats´up?', 'Nothing')}''';

    expect(answer, equals(expectedAnswer));
    expect(std_output.getStringOutput(), equals(expectedOutput));
  });

  test('Order is respected with lists too', () {
    const listQuestions = [
      [
        {
          'question': 'What is your favourite number?',
          'options': ['1', '2', '3']
        },
        'question1'
      ],
      [
        {
          'question': 'What is your favourite letter?',
          'options': ['A', 'B', 'C', 'D', 'E']
        },
        'question2'
      ]
    ];

    final expectedOutput = questionNList(
            'What is your favourite letter?', ['A', 'B', 'C', 'D', 'E'], 3) +
        '\n' +
        questionNList('What is your favourite number?', ['1', '2', '3'], 2);

    const order = ['question2', 'question1'];

    std_input.addToBuffer([
      ...Keys.arrowDown,
      ...Keys.arrowDown,
      ...Keys.arrowDown,
      Keys.enter,
      ...Keys.arrowDown,
      ...Keys.arrowDown,
      Keys.enter
    ]);

    final dialog = CLI_Dialog.std(std_input, std_output,
        listQuestions: listQuestions, order: order);
    dialog.ask();

    expect(std_output.getStringOutput(), equals(expectedOutput));
  });
}
