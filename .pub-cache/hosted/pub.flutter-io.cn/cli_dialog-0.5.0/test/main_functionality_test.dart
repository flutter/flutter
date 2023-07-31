import 'package:test/test.dart';
import 'package:cli_dialog/cli_dialog.dart';
import 'package:cli_dialog/src/xterm.dart';
import 'test_utils.dart';

void main() {
  test('Main functionality', () {
    var std_output = StdoutService(mock: true);
    var std_input =
        StdinService(mock: true, informStdout: std_output, isTest: true);

    std_input.addToBuffer([
      'My project\n',
      'No\n',
      ...Keys.arrowDown,
      ...Keys.arrowDown,
      ...Keys.arrowDown,
      ...Keys.arrowDown,
      ...Keys.arrowUp,
      Keys.enter
    ]);

    const questions = [
      ['What name would you like to use for the project?', 'project_name']
    ];
    const booleanQuestions = [
      ['Would you like to add AngularDart routing?', 'routing']
    ];

    const listQuestion = 'Which stylesheet format would you like to use?';

    const options = [
      'CSS',
      'SCSS   [ https://sass-lang.com/documentation/syntax#scss                ]',
      'Sass   [ https://sass-lang.com/documentation/syntax#the-indented-syntax ]',
      'Less   [ http://lesscss.org                                             ]',
      'Stylus [ http://stylus-lang.com                                         ]'
    ];

    const listQuestions = [
      [
        {'question': listQuestion, 'options': options},
        'stylesheet'
      ]
    ];

    const expectedAnswer = {
      'project_name': 'My project',
      'routing': false,
      'stylesheet':
          'Less   [ http://lesscss.org                                             ]'
    };

    var outputBuffer = StringBuffer();
    outputBuffer.writeln(QnA(questions[0][0], expectedAnswer['project_name']));
    outputBuffer.writeln(booleanQnA(booleanQuestions[0][0], 'No'));
    outputBuffer.write(questionNList(listQuestion, options, 3));

    expect(
        CLI_Dialog.std(std_input, std_output,
                questions: questions,
                booleanQuestions: booleanQuestions,
                listQuestions: listQuestions)
            .ask(),
        equals(expectedAnswer));

    expect(std_output.getStringOutput(), equals(outputBuffer.toString()));
  });
}
