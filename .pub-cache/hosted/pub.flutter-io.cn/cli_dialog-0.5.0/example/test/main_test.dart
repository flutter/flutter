import 'package:test/test.dart';
import 'package:example/main.dart';
import 'package:cli_dialog/src/xterm.dart';
import '../../test/test_utils.dart';

void main() {
  test('Result', () {
    var mockStdout = StdoutService(mock: true);
    var mockStdin =
        StdinService(mock: true, informStdout: mockStdout, isTest: true);

    mockStdin.addToBuffer([
      'Some project\n',
      'Yes\n',
      ...Keys.arrowDown,
      ...Keys.arrowDown,
      ...Keys.arrowUp,
      Keys.enter
    ]);
    var expectedAnswer = {
      'project_name': 'Some project',
      'routing': true,
      'stylesheet':
          'SCSS   [ https://sass-lang.com/documentation/syntax#scss                ]'
    };
    var answers = runExample(mockStdin, mockStdout);
    var outputBuffer = StringBuffer();

    outputBuffer.writeln(QnA(
        'What name would you like to use for the project?', 'Some project'));
    outputBuffer.writeln(
        booleanQnA('Would you like to add AngularDart routing?', 'Yes'));

    var items = [
      'CSS',
      'SCSS   [ https://sass-lang.com/documentation/syntax#scss                ]',
      'Sass   [ https://sass-lang.com/documentation/syntax#the-indented-syntax ]',
      'Less   [ http://lesscss.org                                             ]',
      'Stylus [ http://stylus-lang.com                                         ]'
    ];

    outputBuffer.write(questionNList(
        'Which stylesheet format would you like to use?', items, 1));

    var expectedOutput = outputBuffer.toString();

    expect(answers, equals(expectedAnswer));
    expect(mockStdout.getStringOutput(), equals(expectedOutput));
    expect(report(answers, do_print: false), equals('''

Your project name is ${answers['project_name']}.
You ${(answers['routing'] ? '' : 'do not ')}want to use routing.
Your preferred stylesheet format is ${answers["stylesheet"].split(' ')[0]}.
''')); // Reporting
  });
}
