import 'dart:io';

/// Service to simulate stdout. Use it in unit tests.
class StdoutService {
  /// Indicates if this StdoutService is in mock mode, see also [StdinService].
  bool mock;

  /// The default and only constructor where you can indicate
  // if your stdout should be in [mock] mode.
  StdoutService({this.mock = false});

  /// Use this to write a string, whether in [mock] mode or with real stdout.
  void write(str) {
    if (mock) {
      _buffer += str;
      _flush();
    } else {
      stdout.write(str);
    }
  }

  /// Use this to write a string with a trailing newline ('\n').
  /// Whether in [mock] mode or with real stdout.
  void writeln(str) {
    if (mock) {
      _buffer += str + '\n';
      _flush();
    } else {
      stdout.writeln(str);
    }
  }

  /// This returns the stdout as a list.
  /// Empty strings at the end are removed.
  /// For a string version see [getStringOutput]
  List getOutput() {
    final ret = [];
    _output.forEach((element) {
      if (element.isNotEmpty) {
        ret.add(element);
      }
    });
    return ret;
  }

  /// Calls [getOutput] and joins the returned list using the
  /// newline character ('\n').
  String getStringOutput() => getOutput().join('\n');

  // END OF PUBLIC API

  var _buffer = '';
  final _cursor = {'x': 0, 'y': 0};
  final _output = [''];

  void _addChar() {
    var currLine = _output[_cursor['y']!].split('');
    if (_cursor['x']! < currLine.length) {
      currLine.removeAt(_cursor['x']!);
      currLine.insert(_cursor['x']!, _buffer[0]);
    } else {
      currLine.add(_buffer[0]);
    }
    _output[_cursor['y']!] = currLine.join('');
    _cursor['x'] = _cursor['x']! + 1;
  }

  void _flush() {
    var bufferCpy = _buffer; // copy of buffer

    for (var i = 0; i < bufferCpy.length; i++) {
      var utf16char = bufferCpy[i];

      switch (utf16char) {
        case '\n':
          _handleNewline();
          break;
        case '\r':
          _handleCarriageReturn();
          break;
        case '\u001b':
          var found = _handleEscapeSequence();
          if (found) {
            var toSkip = _removeSequenceFromBuffer();
            i += toSkip;
            continue;
          } else {
            _addChar();
          }
          break;
        default:
          _addChar();
      }
      _removeCharFromBuffer();
    }
  }

  // not all escape sequences have the m delimiter
  int _getDelimiterIndex() {
    var delims = ['A', 'm', 'K'];
    for (var i = 0; i < _buffer.length; i++) {
      if (delims.contains(_buffer[i])) return i;
    }
    return 0;
  }

  void _handleCarriageReturn() {
    _cursor['x'] = 0;
  }

  bool _handleEscapeSequence() {
    final sequence = _buffer.substring(1, _getDelimiterIndex() + 1);

    if (sequence == '[0K') {
      //blank remaning
      _output[_cursor['y']!] =
          _output[_cursor['y']!].substring(0, _cursor['x']);
      return true;
    }
    if (RegExp(r'\[\dA').hasMatch(sequence)) {
      _cursor['x'] = 0;
      var stepsUp =
          int.parse(RegExp(r'\[\dA').firstMatch(sequence)!.group(0)![1]);
      if (_cursor['y']! - stepsUp >= 0) {
        _cursor['y'] = _cursor['y']! - stepsUp;
      }
      return true;
    }
    return false;
  }

  void _handleNewline() {
    _output.add('');
    _cursor['x'] = 0;
    _cursor['y'] = _cursor['y']! + 1;
  }

  void _removeCharFromBuffer() {
    if (_buffer.length > 1) {
      _buffer = _buffer.substring(1);
    } else {
      _buffer = '';
    }
  }

  int _removeSequenceFromBuffer() {
    var delimIndex = _getDelimiterIndex();
    _buffer = _buffer.substring(delimIndex + 1);
    return delimIndex;
  }
}
