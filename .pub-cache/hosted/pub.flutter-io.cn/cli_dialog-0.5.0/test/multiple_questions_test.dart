import 'package:cli_dialog/src/xterm.dart';
import 'package:test/test.dart';
import 'package:cli_dialog/src/dialog.dart';
import 'test_utils.dart';

void main() {
  test('Multiple questions in each category', () {
    final std_output = StdoutService(mock: true);
    final std_input =
        StdinService(mock: true, informStdout: std_output, isTest: true);

    const questions = [
      ['Question 1', 'question1'],
      ['Question 2', 'question2']
    ];

    const booleanQuestions = [
      ['Are you serious right now?', 'C'],
      ['Really?', 'A'],
    ];

    const listQuestions = [
      [
        {
          'question': 'What is your favourite number?',
          'options': ['1', '2', '3']
        },
        'lquestion1'
      ],
      [
        {
          'question': 'What is your favourite letter?',
          'options': ['A', 'B', 'C', 'D', 'E']
        },
        'lquestion2'
      ]
    ];

    std_input.addToBuffer([
      'Answer1\n',
      'Answer2\n',
      'Yes\n',
      'Yes\n',
      Keys.enter,
      ...Keys.arrowDown,
      Keys.enter
    ]);

    final dialog = CLI_Dialog.std(std_input, std_output,
        questions: questions,
        booleanQuestions: booleanQuestions,
        listQuestions: listQuestions);

    const expectedAnswer = {
      'question1': 'Answer1',
      'question2': 'Answer2',
      'C': true,
      'A': true,
      'lquestion1': '1',
      'lquestion2': 'B'
    };

    var outputBuffer = StringBuffer();

    outputBuffer.writeln(QnA('Question 1', 'Answer1'));
    outputBuffer.writeln(QnA('Question 2', 'Answer2'));
    outputBuffer.writeln(booleanQnA('Are you serious right now?', 'Yes'));
    outputBuffer.writeln(booleanQnA('Really?', 'Yes'));
    outputBuffer.writeln(
        questionNList('What is your favourite number?', ['1', '2', '3'], 0));
    outputBuffer.write(questionNList(
        'What is your favourite letter?', ['A', 'B', 'C', 'D', 'E'], 1));

    final expectedOutput = outputBuffer.toString();

    final answer = dialog.ask();

    expect(answer, equals(expectedAnswer));
    expect(std_output.getStringOutput(), equals(expectedOutput));
  });
}
