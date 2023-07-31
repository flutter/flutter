import 'dart:io';
import 'package:test/test.dart';
import 'package:cli_dialog/src/xterm.dart';
import 'test_utils.dart';

void main() {
  StdinService std_in;

  test('Basic functionality', () {
    std_in = StdinService(mock: true);
    final entries = ['Entry1\n', 'Entry2\r', Keys.enter];
    std_in.addToBuffer(entries);
    final line1 = std_in.readLineSync();
    final line2 = std_in.readLineSync();
    final byte1 = std_in.readByteSync();
    expect([line1, line2, byte1], equals(entries));
  });

  test('Informs stdout', () {
    final std_out = StdoutService(mock: true);
    final std_in =
        StdinService(mock: true, informStdout: std_out, isTest: true);
    std_in.addToBuffer(['1337\n', ...Keys.arrowDown]);
    std_in.readLineSync();
    if (Platform.isWindows) {
      std_in.readByteSync(); // arrowDown is just a single byte ('s') on Windows
    } else {
      for (var i = 0; i < 3; i++) {
        std_in.readByteSync();
      }
    }
    expect(std_out.getOutput(), equals(['1337']));
  });
}
