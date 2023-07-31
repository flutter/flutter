import 'dart:convert';
import 'dart:io';
import 'services.dart';
import 'xterm.dart';
import 'keys.dart';

/// Implementation of list questions. Can be used without [CLI_Dialog].
class ListChooser {
  /// The options which are presented to the user
  List<String>? items;

  /// Select the navigation mode. See dialog.dart for details.
  bool navigationMode;

  /// Default constructor for the list chooser.
  /// It is as simple as passing your [items] as a List of strings
  ListChooser(this.items, {this.navigationMode = false}) {
    _checkItems();
    //relevant when running from IntelliJ console pane for example
    if (stdin.hasTerminal) {
      // lineMode must be true to set echoMode in Windows
      // see https://github.com/dart-lang/sdk/issues/28599
      stdin.echoMode = false;
      stdin.lineMode = false;
    }
  }

  /// Named constructor mostly for unit testing.
  /// For context and an example see [CLI_Dialog], `README.md` and the `test/` folder.
  ListChooser.std(this._std_input, this._std_output, this.items,
      {this.navigationMode = false}) {
    _checkItems();
    if (stdin.hasTerminal) {
      stdin.echoMode = false;
      stdin.lineMode = false;
    }
  }

  /// Similar to [ask] this actually triggers the dialog and returns the chosen item = option.
  String choose() {
    int? input;
    var index = 0;

    _renderList(0, initial: true);

    while ((input = _userInput()) != ENTER) {
      if (input! < 0) {
        _resetStdin();
        return ':${-input}';
      }
      if (input == ARROW_UP) {
        if (index > 0) {
          index--;
        }
      } else if (input == ARROW_DOWN) {
        if (index < items!.length - 1) {
          index++;
        }
      }
      _renderList(index);
    }
    _resetStdin();
    return items![index];
  }

  // END OF PUBLIC API

  var _std_input = StdinService();
  var _std_output = StdoutService();

  void _checkItems() {
    if (items == null) {
      throw ArgumentError('No options for list dialog given');
    }
  }

  int? _checkNavigation() {
    final input = _std_input.readByteSync();
    if (navigationMode) {
      if (input == 58) {
        // 58 = :
        _std_output.write(':');
        final inputLine =
            _std_input.readLineSync(encoding: Encoding.getByName('utf-8'))!;
        final lineNumber = int.parse(inputLine.trim());
        _std_output.writeln('$lineNumber');
        return -lineNumber; // make the result negative so it can be told apart from normal key codes
      } else {
        return input;
      }
    } else {
      return input;
    }
  }

  void _deletePreviousList() {
    for (var i = 0; i < items!.length; i++) {
      _std_output.write(XTerm.moveUp(1) + XTerm.blankRemaining());
    }
  }

  void _renderList(index, {initial = false}) {
    if (!initial) {
      _deletePreviousList();
    }
    for (var i = 0; i < items!.length; i++) {
      if (i == index) {
        _std_output
            .writeln(XTerm.rightIndicator() + ' ' + XTerm.teal(items![i]));
        continue;
      }
      _std_output.writeln('  ' + items![i]);
    }
  }

  void _resetStdin() {
    if (stdin.hasTerminal) {
      //see default ctor. Order is important here
      stdin.lineMode = true;
      stdin.echoMode = true;
    }
  }

  int? _userInput() {
    final navigationResult =
        _checkNavigation()!; // just receives the read byte, if not successful,
    if (navigationResult < 0) {
      // < 0 = user has navigated
      return navigationResult;
    }

    if (Platform.isWindows) {
      if (navigationResult == Keys.enter) {
        return ENTER;
      }
      if (navigationResult == Keys.arrowUp[0]) {
        return ARROW_UP;
      }
      if (navigationResult == Keys.arrowDown[0]) {
        return ARROW_DOWN;
      } else {
        return navigationResult;
      }
    } else {
      if (navigationResult == ENTER) {
        return ENTER;
      }
      final anotherByte = _std_input.readByteSync();
      if (anotherByte == ENTER) {
        return ENTER;
      }
      final input = _std_input.readByteSync();
      return input;
    }
  }
}
