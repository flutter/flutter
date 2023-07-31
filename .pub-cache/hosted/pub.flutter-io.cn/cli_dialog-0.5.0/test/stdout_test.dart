import 'package:test/test.dart';
import 'package:cli_dialog/src/stdout_service.dart';
import 'package:cli_dialog/src/xterm.dart';

void main() {
  test('Basic functionality', () {
    final std_output = StdoutService(mock: true);
    std_output.writeln(
        'First line${XTerm.blankRemaining()}\n??${XTerm.moveUp(1)}Go\n');
    std_output.writeln('Second line');
    expect(std_output.getOutput(), equals(['Gorst line', '??', 'Second line']));
  });
}
