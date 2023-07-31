import 'package:cli_dialog/cli_dialog.dart';

void main() {
  final dialog = CLI_Dialog(questions: [
    ['What is your name?', 'name']
  ]);
  final name = dialog.ask()['name'];
  print('Hello $name!');
}
