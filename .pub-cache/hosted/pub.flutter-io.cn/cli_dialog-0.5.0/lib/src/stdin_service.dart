import 'dart:io';
import 'package:cli_dialog/src/stdout_service.dart';
import 'package:dart_console/dart_console.dart';
import 'keys.dart';

final console = Console();

/// Service to simulate stdin. Use it in unit tests.
class StdinService {
  /// Indicates whether this is a mock service.
  /// Being a mock service means here that it does not really read stdin
  /// but gets it´s input from an internal buffer which is filled with [addToBuffer]
  bool mock;

  /// The stdout which should be informed if stdin is received in echoMode.
  /// echoMode means that you see that the user sees what he/her is typing. See [here](https://api.dart.dev/stable/2.7.2/dart-io/Stdin/echoMode.html).
  StdoutService? informStdout;

  /// The default and only constructor where you can optionally indicate
  /// whether you want [mock] stdin and [informStdout]
  StdinService({this.mock = false, this.informStdout, isTest}) {
    if (isTest != null && isTest) {
      _isTest = true;
    }
  }

  /// Use this to simulate stdin.
  ///
  /// ```
  /// std_output = StdoutService(mock: true);
  /// std_input = StdinService(mock: true, informStdout: std_output);
  /// std_input.addToBuffer('Some input\n', ...Keys.arrowDown, Keys.enter);
  /// ```
  void addToBuffer(elements) {
    if (elements is Iterable) {
      _mockBuffer.addAll(elements);
    } else {
      _mockBuffer.add(elements); // that is, if it is only one element
    }
  }

  /// Use this to read a byte, whether in  [mock] mode or with real stdin.
  int? readByteSync() {
    if (mock) {
      var ret = _mockBuffer[0];
      _mockBuffer.removeAt(0);
      return (ret is int ? ret : int.parse(ret));
    }
    int? key;
    if (Platform.isWindows) {
      var key_input = console.readKey().toString();
      if (key_input.startsWith('ControlCharacter')) {
        key_input = key_input.split('.')[1];
        if (key_input == 'arrowUp') {
          return WIN_UP;
        } else if (key_input == 'arrowDown') {
          return WIN_DOWN;
        } else if (key_input == 'enter') {
          return WIN_ENTER;
        }
      } else {
        return key_input.codeUnitAt(0);
      }
    } else {
      key = stdin.readByteSync();
    }
    return key;
  }

  /// Use this to read a whole line, whether in [mock] mode or with real stdin.
  String? readLineSync({encoding}) {
    if (mock) {
      var ret = _mockBuffer[0];
      _mockBuffer.removeAt(0);
      if (informStdout != null && (_isTest || _getEchomode())) {
        informStdout!.write(ret);
      }
      return ret;
    }
    return stdin.readLineSync(encoding: encoding);
  }

  // END OF PUBLIC API

  bool _isTest = false;

  final _mockBuffer = [];
  bool _getEchomode() {
    if (!stdin.hasTerminal) {
      return false;
    } else {
      return stdin.echoMode;
    }
  }
}
