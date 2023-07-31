import 'package:cli_dialog/cli_dialog.dart';

void main() {
  const listQuestions = [
    [
      {
        'question': 'Where are you from?',
        'options': ['Africa', 'Asia', 'Europe', 'North America', 'South Africa']
      },
      'origin'
    ]
  ];

  const booleanQuestions = [
    ['Do you want to continue?', 'continue']
  ];

  final dialog = CLI_Dialog(
      booleanQuestions: booleanQuestions,
      listQuestions: listQuestions,
      order: ['origin', 'continue']);

  dialog.ask();
}
