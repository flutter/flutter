import 'package:cli_dialog/cli_dialog.dart';

void main() {
  final dialog = CLI_Dialog(booleanQuestions: [
    ['Are you happy with this package?', 'isHappy']
  ]);
  final answer = dialog.ask()['isHappy'];
  if (answer) {
    print('I am glad to hear that you like this library.');
  } else {
    print('I am sorry to hear that. What can I improve?');
  }
}
