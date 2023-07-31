import 'package:test/test.dart';
import 'package:cli_dialog/src/list_chooser.dart';
import 'package:cli_dialog/src/xterm.dart';
import 'test_utils.dart';

void main() {
  late StdinService std_input;
  late StdoutService std_output;
  late List<String> options;

  setUp(() {
    std_input = StdinService(mock: true);
    std_output = StdoutService(mock: true);
    options = ['A', 'B', 'C', 'D'];
  });

  test('Basic functionality', () {
    std_input.addToBuffer(
        [...Keys.arrowDown, ...Keys.arrowDown, ...Keys.arrowDown, Keys.enter]);
    var chooser = ListChooser.std(std_input, std_output, options);
    var expectedStdout = markedList(options, 3);

    expect(chooser.choose(), equals('D'));
    expect(std_output.getStringOutput(), equals(expectedStdout));
  });

  test('Lower bound is respected', () {
    std_input.addToBuffer([
      ...Keys.arrowDown,
      ...Keys.arrowDown,
      ...Keys.arrowDown,
      ...Keys.arrowDown,
      ...Keys.arrowDown,
      Keys.enter
    ]);
    var chooser = ListChooser.std(std_input, std_output, options);
    var expectedStdout = markedList(options, 3);

    expect(chooser.choose(), equals('D'));
    expect(std_output.getStringOutput(), equals(expectedStdout));
  });

  test('Many options', () {
    options = [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z'
    ];
    var elements = [];
    for (var i = 0; i < 11; i++) {
      elements.addAll([
        ...Keys.arrowDown
      ]); // it is a single element but it must be in a list for the spread operator to work
    }
    std_input.addToBuffer([...elements, Keys.enter]);
    var chooser = ListChooser.std(std_input, std_output, options);
    var expectedOutput = markedList(options, 11);

    expect(chooser.choose(), equals('L'));
    expect(std_output.getStringOutput(), equals(expectedOutput));
  });

  test('Only one option', () {
    options = ['A'];
    std_input.addToBuffer(Keys.enter);
    var chooser = ListChooser.std(std_input, std_output, options);
    var expectedOutput = markedList(options, 0);

    expect(chooser.choose(), equals('A'));
    expect(std_output.getStringOutput(), equals(expectedOutput));
  });

  test('Throws exception if no option is given', () {
    expect(
        () => ListChooser.std(std_input, std_output, null),
        throwsA(predicate((dynamic e) =>
            e is ArgumentError &&
            e.message == 'No options for list dialog given')));
  });

  test('Upper bound is respected', () {
    std_input.addToBuffer([
      ...Keys.arrowUp,
      ...Keys.arrowUp,
      ...Keys.arrowUp,
      ...Keys.arrowUp,
      ...Keys.arrowUp,
      Keys.enter
    ]);
    var chooser = ListChooser.std(std_input, std_output, options);
    var expectedStdout = markedList(options, 0);

    expect(chooser.choose(), equals('A'));
    expect(std_output.getStringOutput(), equals(expectedStdout));
  });
}
