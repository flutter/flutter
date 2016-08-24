// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'command.dart';
import '../base/logger.dart';

class CommandLine {
  CommandLine(this._cmd,
              this.term,
              {Stdin consoleIn,
               Stdout consoleOut,
               this.prompt : '> '}) {
    _stdin = (consoleIn != null ? consoleIn : stdin);
    _stdout = (consoleOut != null ? consoleOut : stdout);
    _stdin.echoMode = false;
    _stdin.lineMode = false;
    _writePrompt();
    _stdinSubscription =
      _stdin.transform(UTF8.decoder).listen(_handleText,
                                            onError:_stdinError,
                                            onDone:_stdinDone);
    _dumbMode = term.isDumb;
    _resize();
  }

  // Ctrl keys
  static const int runeCtrlA       = 0x01;
  static const int runeCtrlB       = 0x02;
  static const int runeCtrlD       = 0x04;
  static const int runeCtrlE       = 0x05;
  static const int runeCtrlF       = 0x06;
  static const int runeTAB         = 0x09;
  static const int runeNewline     = 0x0a;
  static const int runeCtrlK       = 0x0b;
  static const int runeCtrlL       = 0x0c;
  static const int runeCtrlN       = 0x0e;
  static const int runeCtrlP       = 0x10;
  static const int runeCtrlU       = 0x15;
  static const int runeCtrlY       = 0x19;
  static const int runeESC         = 0x1b;
  static const int runeSpace       = 0x20;
  static const int runeA           = 0x41;
  static const int runeB           = 0x42;
  static const int runeC           = 0x43;
  static const int runeD           = 0x44;
  static const int runeLeftBracket = 0x5b;
  static const int runeDEL         = 0x7F;

  RootCommand get rootCommand => _cmd;
  RootCommand _cmd;
  bool _dumbMode;

  bool get _promptShown => _hideDepth == 0;

  Future<Null> quit() async {
    await _done();
  }

  void _stdinError(dynamic e, StackTrace st) {
    print('Unexpected error reading input: $e\n$st');
    _done();
  }

  void _stdinDone() {
    _done();
  }

  Future<Null> _done() {
    _stdin.echoMode = true;
    _stdin.lineMode = true;
    Future<Null> future = _stdinSubscription.cancel();
    if (future != null) {
      return future;
    } else {
      return new Future<Null>.value();
    }
  }

  void _resize() {
    _screenWidth = term.cols - 1;
  }

  void _handleText(String text) {
    try {
      if (!_promptShown) {
        _bufferedInput.write(text);
        return;
      }

      List<int> runes = text.runes.toList();
      int pos = 0;
      while (pos < runes.length) {
        if (!_promptShown) {
          // A command was processed which hid the prompt.  Buffer
          // the rest of the input.
          _bufferedInput.write(
              new String.fromCharCodes(runes.skip(pos)));
          return;
        }

        int rune = runes[pos];

        // Count consecutive tabs because double-tab is meaningful.
        if (rune == runeTAB) {
          _tabCount++;
        } else {
          _tabCount = 0;
        }

        if (_isControlRune(rune)) {
          if (_dumbMode) {
            pos += _handleControlSequenceDumb(runes, pos);
          } else {
            pos += _handleControlSequence(runes, pos);
          }
        } else {
          pos += _handleRegularSequence(runes, pos);
        }
      }
    } catch(e, st) {
      print('Unexpected error: $e\n$st');
    }
  }

  bool _matchRunes(List<int> runes, int pos, List<int> match) {
    if (runes.length < pos + match.length)
      return false;

    for (int i = 0; i < match.length; i++) {
      if (runes[pos + i] != match[i])
        return false;
    }
    return true;
  }

  int _handleControlSequence(List<int> runes, int pos) {
    int runesConsumed = 1;  // Most common result.
    int char = runes[pos];
    switch (char) {
      case runeCtrlA:
        _home();
        break;

      case runeCtrlB:
        _leftArrow();
        break;

      case runeCtrlD:
        if (_currentLine.length == 0) {
          // ^D on an empty line means quit.
          _stdout.writeln("^D");
          _done();
        } else {
          _delete();
        }
        break;

      case runeCtrlE:
        _end();
        break;

      case runeCtrlF:
        _rightArrow();
        break;

      case runeTAB:
        _complete(_tabCount > 1);
        break;

      case runeNewline:
        _newline();
        break;

      case runeCtrlK:
        _kill();
        break;

      case runeCtrlL:
        _clearScreen();
        break;

      case runeCtrlN:
        _historyNext();
        break;

      case runeCtrlP:
        _historyPrevious();
        break;

      case runeCtrlU:
        _clearLine();
        break;

      case runeCtrlY:
        _yank();
        break;

      case runeESC:
        if (pos + 1 < runes.length) {
          if (_matchRunes(runes, pos + 1, <int>[runeLeftBracket, runeA])) {
            // ^[[A = up arrow
            _historyPrevious();
            runesConsumed = 3;
            break;
          } else if (_matchRunes(runes, pos + 1,
                                 <int>[runeLeftBracket, runeB])) {
            // ^[[B = down arrow
            _historyNext();
            runesConsumed = 3;
          } else if (_matchRunes(runes, pos + 1,
                                 <int>[runeLeftBracket, runeC])) {
            // ^[[C = right arrow
            _rightArrow();
            runesConsumed = 3;
          } else if (_matchRunes(runes, pos + 1,
                                 <int>[runeLeftBracket, runeD])) {
            // ^[[D = left arrow
            _leftArrow();
            runesConsumed = 3;
          } else {
            HotKey hotKey = _cmd.matchHotKey(runes.skip(pos).toList());
            if (hotKey != null) {
              runesConsumed = hotKey.runes.length;
              List<int> line = hotKey.expansion.runes.toList();
              _update(line, line.length);
              _newline();
            }
          }
        }
        break;

      case runeDEL:
        _backspace();
        break;

      default:
        // Ignore the escape character.
        break;
    }
    return runesConsumed;
  }

  int _handleControlSequenceDumb(List<int> runes, int pos) {
    int runesConsumed = 1;  // Most common result.
    int char = runes[pos];
    switch (char) {
      case runeCtrlD:
        if (_currentLine.length == 0) {
          // ^D on an empty line means quit.
          _stdout.writeln("^D");
          _done();
        }
        break;

      case runeTAB:
        _complete(_tabCount > 1);
        break;

      case runeNewline:
        _newline();
        break;

      case runeCtrlN:
        _historyNext();
        break;

      case runeCtrlP:
        _historyPrevious();
        break;

      case runeCtrlU:
        _clearLine();
        break;

      case runeESC:
        if (pos + 1 < runes.length) {
          if (_matchRunes(runes, pos + 1, <int>[runeLeftBracket, runeA])) {
            // ^[[A = up arrow
            _historyPrevious();
            runesConsumed = 3;
            break;
          } else if (_matchRunes(runes, pos + 1,
                                 <int>[runeLeftBracket, runeB])) {
            // ^[[B = down arrow
            _historyNext();
            runesConsumed = 3;
          } else if (_matchRunes(runes, pos + 1,
                                 <int>[runeLeftBracket, runeC])) {
            // ^[[C = right arrow - Ignore.
            runesConsumed = 3;
          } else if (_matchRunes(runes, pos + 1,
                                 <int>[runeLeftBracket, runeD])) {
            // ^[[D = left arrow - Ignore.
            runesConsumed = 3;
          } else {
            HotKey hotKey = _cmd.matchHotKey(runes.skip(pos).toList());
            if (hotKey != null) {
              runesConsumed = hotKey.runes.length;
              List<int> line = hotKey.expansion.runes.toList();
              _update(line, line.length);
              _newline();
            }
          }
        }
        break;

      case runeDEL:
        _backspace();
        break;

      default:
        // Ignore the escape character.
        break;
    }
    return runesConsumed;
  }

  int _handleRegularSequence(List<int> runes, int pos) {
    int len = pos + 1;
    while (len < runes.length && !_isControlRune(runes[len])) {
      len++;
    }
    _addChars(runes.getRange(pos, len));
    return len;
  }

  bool _isControlRune(int char) {
    return (char >= 0x00 && char < 0x20) || (char == 0x7f);
  }

  void _writePromptAndLine() {
    _writePrompt();
    int pos = _writeRange(_currentLine, 0, _currentLine.length);
    _cursorPos = _move(pos, _cursorPos);
  }

  void _writePrompt() {
    _resize();
    _stdout.write(term.toBold(prompt));
  }

  void _addChars(Iterable<int> chars) {
    List<int> newLine = <int>[];
    newLine..addAll(_currentLine.take(_cursorPos))
           ..addAll(chars)
           ..addAll(_currentLine.skip(_cursorPos));
    _update(newLine, (_cursorPos + chars.length));
  }

  void _backspace() {
    if (_cursorPos == 0)
      return;

    List<int> newLine = <int>[];
    newLine..addAll(_currentLine.take(_cursorPos - 1))
           ..addAll(_currentLine.skip(_cursorPos));
    _update(newLine, (_cursorPos - 1));
  }

  void _delete() {
    if (_cursorPos == _currentLine.length)
      return;

    List<int> newLine = <int>[];
    newLine..addAll(_currentLine.take(_cursorPos))
           ..addAll(_currentLine.skip(_cursorPos + 1));
    _update(newLine, _cursorPos);
  }

  void _home() {
    _updatePos(0);
  }

  void _end() {
    _updatePos(_currentLine.length);
  }

  void _clearScreen() {
    _stdout.write(term.clearScreen);
    _writePromptAndLine();
  }

  void _kill() {
    List<int> newLine = <int>[];
    newLine.addAll(_currentLine.take(_cursorPos));
    _killBuffer = _currentLine.skip(_cursorPos).toList();
    _update(newLine, _cursorPos);
  }

  void _clearLine() {
    _update(<int>[], 0);
  }

  void _yank() {
    List<int> newLine = <int>[];
    newLine..addAll(_currentLine.take(_cursorPos))
           ..addAll(_killBuffer)
           ..addAll(_currentLine.skip(_cursorPos));
    _update(newLine, (_cursorPos + _killBuffer.length));
  }

  static String _commonPrefix(String a, String b) {
    int pos = 0;
    while (pos < a.length && pos < b.length) {
      if (a.codeUnitAt(pos) != b.codeUnitAt(pos))
        break;

      pos++;
    }
    return a.substring(0, pos);
  }

  static String _foldCompletions(List<String> values) {
    if (values.length == 0)
      return '';

    String prefix = values[0];
    for (int i = 1; i < values.length; i++) {
      prefix = _commonPrefix(prefix, values[i]);
    }
    return prefix;
  }

  Future<Null> _complete(bool showCompletions) async {
    List<int> linePrefix = _currentLine.take(_cursorPos).toList();
    String lineAsString = new String.fromCharCodes(linePrefix);
    List<String> completions = await _cmd.completeCommand(lineAsString);
    String completion;
    if (completions.length == 0) {
      // No completions.  Leave the line alone.
      return;
    } else if (completions.length == 1) {
      // Unambiguous completion.
      completion = completions[0];
    } else {
      // Ambiguous completion.
      completions = completions.map((String s) => s.trimRight()).toList();
      completion = _foldCompletions(completions);
    }

    if (showCompletions) {
      // User hit double-TAB.  Show them all possible completions.
      completions.sort((String a, String b) => a.compareTo(b));
      _move(_cursorPos, _currentLine.length);
      _stdout.writeln();
      _stdout.writeln(completions);
      _writePromptAndLine();
      return;

    } else {
      // Apply the current completion.
      List<int> completionRunes = completion.runes.toList();
      List<int> newLine = <int>[];
      newLine..addAll(completionRunes)
             ..addAll(_currentLine.skip(_cursorPos));
      _update(newLine, completionRunes.length);
      return;
    }
  }

  Future<Null> _newline() async {
    _end();
    _stdout.writeln();

    // Prompt is implicitly hidden at this point.
    _hideDepth++;

    String text = new String.fromCharCodes(_currentLine);
    _currentLine = <int>[];
    _cursorPos = 0;
    try {
      await _cmd.runCommand(text);
    } catch (e) {
      print('$e');
    }

    // Reveal the prompt.
    show();
  }

  void _leftArrow() {
    _updatePos(_cursorPos - 1);
  }

  void _rightArrow() {
    _updatePos(_cursorPos + 1);
  }

  void _historyPrevious() {
    String text = new String.fromCharCodes(_currentLine);
    List<int> newLine = _cmd.historyPrev(text).runes.toList();
    _update(newLine, newLine.length);
  }

  void _historyNext() {
    String text = new String.fromCharCodes(_currentLine);
    List<int> newLine = _cmd.historyNext(text).runes.toList();
    _update(newLine, newLine.length);
  }

  void _updatePos(int newCursorPos) {
    if (newCursorPos < 0)
      return;

    if (newCursorPos > _currentLine.length)
      return;

    _cursorPos = _move(_cursorPos, newCursorPos);
  }

  void _update(List<int> newLine, int newCursorPos) {
    int pos = _cursorPos;
    int sharedLen = min(_currentLine.length, newLine.length);

    // Find first difference.
    int diffPos;
    for (diffPos = 0; diffPos < sharedLen; diffPos++) {
      if (_currentLine[diffPos] != newLine[diffPos])
        break;
    }

    if (_dumbMode) {
      assert(_cursorPos == _currentLine.length);
      assert(newCursorPos == newLine.length);
      if (diffPos == _currentLine.length) {
        // Write the new text.
        int pos = _writeRange(newLine, _cursorPos, newLine.length);
        assert(pos == newCursorPos);
        _cursorPos = newCursorPos;
        _currentLine = newLine;
      } else {
        // We can't erase, so just move forward.
        _stdout.writeln();
        _currentLine = newLine;
        _cursorPos = newCursorPos;
        _writePromptAndLine();
      }
      return;
    }

    // Move the cursor to where the difference begins.
    pos = _move(pos, diffPos);

    // Write the new text.
    pos = _writeRange(newLine, pos, newLine.length);

    // Clear any extra characters at the end.
    pos = _clearRange(pos, _currentLine.length);

    // Move the cursor back to the input point.
    _cursorPos = _move(pos, newCursorPos);
    _currentLine = newLine;
  }

  void print(String text) {
    hide();
    _stdout.writeln(text);
    show();
  }

  void hide() {
    if (_hideDepth > 0) {
      _hideDepth++;
      return;
    }
    _hideDepth++;
    if (_dumbMode) {
      _stdout.writeln();
      return;
    }
    // We need to erase everything, including the prompt.
    int curLine = _getLine(_cursorPos);
    int lastLine = _getLine(_currentLine.length);

    // Go to last line.
    if (curLine < lastLine) {
      for (int i = 0; i < (lastLine - curLine); i++) {
        // This moves us to column 0.
        _stdout.write(term.cursorDown);
      }
      curLine = lastLine;
    } else {
      // Move to column 0.
      _stdout.write('\r');
    }

    // Work our way up, clearing lines.
    while (true) {
      _stdout.write(term.clearEOL);
      if (curLine > 0) {
        _stdout.write(term.cursorUp);
      } else {
        break;
      }
    }
  }

  void show() {
    assert(_hideDepth > 0);
    _hideDepth--;
    if (_hideDepth > 0)
      return;

    _writePromptAndLine();

    // If input was buffered while the prompt was hidden, process it
    // now.
    if (_bufferedInput.isNotEmpty) {
      String input = _bufferedInput.toString();
      _bufferedInput.clear();
      _handleText(input);
    }
  }

  int _writeRange(List<int> text, int pos, int writeToPos) {
    if (pos >= writeToPos)
      return pos;

    while (pos < writeToPos) {
      int margin = _nextMargin(pos);
      int limit = min(writeToPos, margin);
      _stdout.write(new String.fromCharCodes(text.getRange(pos, limit)));
      pos = limit;
      if (pos == margin)
        _stdout.write('\n');
    }
    return pos;
  }

  int _clearRange(int pos, int clearToPos) {
    if (pos >= clearToPos)
      return pos;

    while (true) {
      int limit = _nextMargin(pos);
      _stdout.write(term.clearEOL);
      if (limit >= clearToPos)
        return pos;

      _stdout.write('\n');
      pos = limit;
    }
  }

  int _move(int pos, int newPos) {
    if (pos == newPos)
      return pos;

    int curCol = _getCol(pos);
    int curLine = _getLine(pos);
    int newCol = _getCol(newPos);
    int newLine = _getLine(newPos);

    if (curLine > newLine) {
      for (int i = 0; i < (curLine - newLine); i++) {
        _stdout.write(term.cursorUp);
      }
    }
    if (curLine < newLine) {
      for (int i = 0; i < (newLine - curLine); i++) {
        _stdout.write(term.cursorDown);
      }

      // Moving down resets column to zero, oddly.
      curCol = 0;
    }
    if (curCol > newCol) {
      for (int i = 0; i < (curCol - newCol); i++) {
        _stdout.write(term.cursorBack);
      }
    }
    if (curCol < newCol) {
      for (int i = 0; i < (newCol - curCol); i++) {
        _stdout.write(term.cursorForward);
      }
    }

    return newPos;
  }

  int _nextMargin(int pos) {
    int truePos = pos + prompt.length;
    return ((truePos ~/ _screenWidth) + 1) * _screenWidth - prompt.length;
  }

  int _getLine(int pos) {
    int truePos = pos + prompt.length;
    return truePos ~/ _screenWidth;
  }

  int _getCol(int pos) {
    int truePos = pos + prompt.length;
    return truePos % _screenWidth;
  }

  Stdin _stdin;
  StreamSubscription<String> _stdinSubscription;
  IOSink _stdout;
  final String prompt;
  int _hideDepth = 0;
  final AnsiTerminal term;

  int _screenWidth;
  List<int> _currentLine = <int>[];  // A list of runes.
  StringBuffer _bufferedInput = new StringBuffer();
  int _cursorPos = 0;
  int _tabCount = 0;
  List<int> _killBuffer = <int>[];
}
