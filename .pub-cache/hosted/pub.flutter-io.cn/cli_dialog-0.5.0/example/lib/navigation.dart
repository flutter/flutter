import 'package:cli_dialog/cli_dialog.dart';

void main() {
  final dialog = CLI_Dialog(navigationMode: true);
  dialog.addQuestion('Question 1', 'answer1');
  dialog.addQuestion('Question 2', 'answer2', is_boolean: true);
  dialog.addQuestion({
    'question': 'Question 3',
    'options': ['option 1', 'option2', 'option3']
  }, 'answer3', is_list: true);
  dialog.ask();
}
