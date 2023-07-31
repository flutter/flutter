import 'package:cli_dialog/cli_dialog.dart';

void main() {
  final dialog = CLI_Dialog();
  const messages = ['This is my first message', 'This is my second message'];
  dialog.addQuestions(messages, is_message: true);
  dialog.ask();
  print('lol');
}
