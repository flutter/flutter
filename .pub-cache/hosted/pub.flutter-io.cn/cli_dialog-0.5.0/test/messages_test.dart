import 'package:cli_dialog/cli_dialog.dart';
import 'package:test/test.dart';
import 'test_utils.dart';

void main() {
  late StdoutService std_output;
  late StdinService std_input;

  setUp(() {
    std_output = StdoutService(mock: true);
    std_input =
        StdinService(mock: true, informStdout: std_output, isTest: true);
  });

  test('Messages are displayed', () {
    final dialog = CLI_Dialog.std(std_input, std_output);
    const messages = ['This is my first message', 'This is my second message'];
    dialog.addQuestions(messages, is_message: true);
    dialog.ask();
    expect(std_output.getStringOutput(),
        message(messages[0]) + '\n' + message(messages[1]));
  });

  test('Order is respected', () {
    final dialog =
        CLI_Dialog.std(std_input, std_output, order: ['first', 'second']);
    const messages = [
      ['This is my second message', 'second'],
      ['This is my first message', 'first']
    ];
    dialog.addQuestions(messages, is_message: true);
    dialog.ask();
    expect(std_output.getStringOutput(),
        message(messages[1]) + '\n' + message(messages[0]));
  });
}
