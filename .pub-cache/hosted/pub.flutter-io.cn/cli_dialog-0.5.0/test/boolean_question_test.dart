import 'package:test/test.dart';
import 'package:cli_dialog/cli_dialog.dart';
import 'test_utils.dart';

void main() {
  late StdinService std_input;
  late StdoutService std_output;

  setUp(() {
    std_output = StdoutService(mock: true);
    std_input = StdinService(mock: true, informStdout: std_output);
  });

  test('Boolean question default answer is no', () {
    std_input.addToBuffer('\n');
    const booleanQuestions = [
      ['Does this question deserve an answer?', 'some_question']
    ];
    final dialog = CLI_Dialog.std(std_input, std_output,
        booleanQuestions: booleanQuestions);
    const expectedAnswer = {'some_question': false};
    final expectedOutput =
        booleanQnA('Does this question deserve an answer?', 'No');

    expect(dialog.ask(), equals(expectedAnswer));
    expect(std_output.getStringOutput(), equals(expectedOutput));
  });

  test('Boolean question default answer can be changed to yes', () {
    std_input.addToBuffer('\n');
    const booleanQuestions = [
      ['Does this question deserve an answer?', 'some_question']
    ];
    final dialog = CLI_Dialog.std(std_input, std_output,
        booleanQuestions: booleanQuestions, trueByDefault: true);
    const expectedAnswer = {'some_question': true};
    final expectedOutput = booleanQnA(
        'Does this question deserve an answer?', 'Yes',
        trueByDefault: true);

    expect(dialog.ask(), equals(expectedAnswer));
    expect(std_output.getStringOutput(), equals(expectedOutput));
  });
}
