import 'package:cli_dialog/cli_dialog.dart';

void main() {
  final dialog = CLI_Dialog();
  dialog.addQuestion('What´up?', 'status');
  print(dialog.ask()['status']);
}
