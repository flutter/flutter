// Copyright 2015 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library webdriver.support.stdio_stepper;

import 'dart:async' show StreamController;
import 'dart:convert' show Encoding, json;
import 'dart:io' show exit, Stdin, stdin, systemEncoding;

import '../src/async/stepper.dart';

LineReader? _stdinLineReader;

/// A [LineReader] instance connected to 'dart:io' [stdin].
LineReader get stdinLineReader => _stdinLineReader ??= LineReader(stdin);

/// Provides a command line interface for stepping through or skipping
/// WebDriver commands.
class StdioStepper implements Stepper {
  bool enabled = true;

  final LineReader _reader;

  StdioStepper({LineReader? reader}) : _reader = reader ?? stdinLineReader;

  @override
  Future<bool> step(String method, String command, params) async {
    if (!enabled) return true;
    print('$method $command(${json.encode(params)}):');
    await for (String command in _reader.onLine) {
      switch (command) {
        case 'continue':
        case 'c':
          return true;
        case 'skip':
        case 's':
          return false;
        case 'break':
        case 'b':
          throw Exception('process ended by user.');
        case 'help':
        case 'h':
          _printUsage();
          break;
        case 'disable':
        case 'd':
          enabled = false;
          return true;
        case 'quit':
        case 'q':
          return exit(-1);
        default:
          print('invalid command: `$command` enter `h` or `help` for help.');
      }
    }
    throw Exception('stdin has been closed');
  }

  void _printUsage() {
    print('`c` or `continue`: execute command');
    print('`s` or `skip`: skip command');
    print('`d` or `disable`: disable stepper');
    print('`b` or `break`: throw exception');
    print('`q` or `quit`: terminate vm');
    print('`h` or `help`: display this message');
  }
}

/// Converts a Stream<List<int> | int> to Stream<String> that fires an event
/// for every line of data in the original Stream.
class LineReader {
  static const cr = 13;
  static const lf = 10;

  bool _crPrevious = false;
  final _bytes = <int>[];
  final _controller = StreamController<String>.broadcast();

  final Encoding encoding;

  /// Only encodings that are a superset of ASCII are supported
  /// TODO(DrMarcII): Support arbitrary encodings
  LineReader(Stream /* <List<int> | int> */ stream,
      {this.encoding = systemEncoding}) {
    if (stream is Stdin) {
      stdin.lineMode = false;
    }
    stream.listen(_listen,
        onDone: _controller.close, onError: _controller.addError);
  }

  void _listen(/* List<int> | int */ data) {
    if (data is List<int>) {
      data.forEach(_addByte);
    } else {
      _addByte(data as int);
    }
  }

  void _addByte(int byte) {
    if (_crPrevious && byte == lf) {
      _crPrevious = false;
      return;
    }
    _crPrevious = byte == cr;
    if (byte == cr || byte == lf) {
      _controller.add(encoding.decode(_bytes));
      _bytes.clear();
    } else {
      _bytes.add(byte);
    }
  }

  /// A Stream that fires for each line of data.
  Stream<String> get onLine => _controller.stream;
}
