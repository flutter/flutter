import 'package:cli_dialog/cli_dialog.dart';

void main() {
  const listQuestions = [
    [
      {
        'question': 'What is your favourite colour?',
        'options': ['Red', 'Blue', 'Green']
      },
      'colour'
    ]
  ];

  final dialog = CLI_Dialog(listQuestions: listQuestions);
  final answer = dialog.ask();
  final colour = answer['colour'];
  print('Your favourite colour is $colour.');
}
