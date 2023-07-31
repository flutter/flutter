import 'package:cli_dialog/cli_dialog.dart';

class Menu {
  final List<String> choices;
  final String title;

  Menu(this.choices, {this.title = ''});

  Answer choose() {
    final dialog = CLI_Dialog(listQuestions: [
      [
        {'question': title, 'options': choices},
        'result'
      ]
    ]);

    final answer = dialog.ask();
    final result = answer['result'] as String;
    final index = choices.indexOf(result);

    return Answer(result: result, index: index);
  }
}

class Answer {
  final String result;
  final int index;

  const Answer({required this.result, required this.index});
}
