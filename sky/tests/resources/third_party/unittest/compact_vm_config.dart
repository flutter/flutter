// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A test configuration that generates a compact 1-line progress bar. The bar
/// is updated in-place before and after each test is executed. If all tests
/// pass, only a couple of lines are printed in the terminal. If a test fails,
/// the failure is shown and the progress bar continues to be updated below it.
library unittest.compact_vm_config;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'unittest.dart';
import 'src/utils.dart';
import 'vm_config.dart';

const String _GREEN = '\u001b[32m';
const String _RED = '\u001b[31m';
const String _NONE = '\u001b[0m';

const int MAX_LINE = 80;

class CompactVMConfiguration extends VMConfiguration {
  // The VM won't shut down if a receive port is open. Use this to make sure
  // we correctly wait for asynchronous tests.
  ReceivePort _receivePort;

  DateTime _start;
  Set<int> _passing = new Set();
  Set<int> _failing = new Set();
  int get _pass => _passing.length;
  int get _fail => _failing.length;

  void onInit() {
    _receivePort = new ReceivePort();
    // Override and don't call the superclass onInit() to avoid printing the
    // "unittest-suite-..." boilerplate.
  }

  void onStart() {
    _start = new DateTime.now();
  }

  void onTestStart(TestCase test) {
    super.onTestStart(test);
    _progressLine(test.description);
  }

  void onTestResult(TestCase test) {
    super.onTestResult(test);
    if (test.result == PASS) {
      _passing.add(test.id);
      _progressLine(test.description);
    } else {
      _failing.add(test.id);
      _progressLine(test.description);
      _print();
      if (test.message != '') {
        _print(indent(test.message));
      }

      if (test.stackTrace != null) {
        _print(indent(test.stackTrace.toString()));
      }
    }
  }

  void onTestResultChanged(TestCase test) {
    _passing.remove(test.id);
    _failing.add(test.id);
    _progressLine(test.description);
    _print();
    if (test.message != '') {
      _print(indent(test.message));
    }

    if (test.stackTrace != null) {
      _print(indent(test.stackTrace.toString()));
    }
  }

  void onDone(bool success) {
    // Override and don't call the superclass onDone() to avoid printing the
    // "unittest-suite-..." boilerplate.
    Future.wait([stdout.close(), stderr.close()]).then((_) {
      _receivePort.close();
      exit(success ? 0 : 1);
    });
  }

  void onSummary(int passed, int failed, int errors, List<TestCase> results,
      String uncaughtError) {
    if (passed == 0 && failed == 0 && errors == 0 && uncaughtError == null) {
      _print('\nNo tests ran.');
    } else if (failed == 0 && errors == 0 && uncaughtError == null) {
      _progressLine('All tests passed!', _NONE);
      _print();
    } else {
      _progressLine('Some tests failed.', _RED);
      _print();
      if (uncaughtError != null) {
        _print('Top-level uncaught error: $uncaughtError');
      }
      _print('$passed PASSED, $failed FAILED, $errors ERRORS');
    }
  }

  int _lastLength = 0;

  final int _nonVisiblePrefix = 1 + _GREEN.length + _NONE.length;

  void _progressLine(String message, [String color = _NONE]) {
    var duration = (new DateTime.now()).difference(_start);
    var buffer = new StringBuffer();
    // \r moves back to the beginning of the current line.
    buffer.write('\r${_timeString(duration)} ');
    buffer.write(_GREEN);
    buffer.write('+');
    buffer.write(_pass);
    buffer.write(_NONE);
    if (_fail != 0) {
      buffer.write(_RED);
      buffer.write(' -');
      buffer.write(_fail);
      buffer.write(_NONE);
    }
    buffer.write(': ');
    buffer.write(color);

    // Ensure the line fits under MAX_LINE. [buffer] includes the color escape
    // sequences too. Because these sequences are not visible characters, we
    // make sure they are not counted towards the limit.
    int nonVisible = _nonVisiblePrefix +
        color.length +
        (_fail != 0 ? (_RED.length + _NONE.length) : 0);
    int len = buffer.length - nonVisible;
    buffer.write(_snippet(message, MAX_LINE - len));
    buffer.write(_NONE);

    // Pad the rest of the line so that it looks erased.
    len = buffer.length - nonVisible - _NONE.length;
    if (len > _lastLength) {
      _lastLength = len;
    } else {
      while (len < _lastLength) {
        buffer.write(' ');
        _lastLength--;
      }
    }
    stdout.write(buffer.toString());
  }

  String _padTime(int time) =>
      (time == 0) ? '00' : ((time < 10) ? '0$time' : '$time');

  String _timeString(Duration duration) {
    var min = duration.inMinutes;
    var sec = duration.inSeconds % 60;
    return '${_padTime(min)}:${_padTime(sec)}';
  }

  String _snippet(String text, int maxLength) {
    // Return the full message if it fits
    if (text.length <= maxLength) return text;

    // If we can fit the first and last three words, do so.
    var words = text.split(' ');
    if (words.length > 1) {
      int i = words.length;
      var len = words.first.length + 4;
      do {
        len += 1 + words[--i].length;
      } while (len <= maxLength && i > 0);
      if (len > maxLength || i == 0) i++;
      if (i < words.length - 4) {
        // Require at least 3 words at the end.
        var buffer = new StringBuffer();
        buffer.write(words.first);
        buffer.write(' ...');
        for ( ; i < words.length; i++) {
          buffer.write(' ');
          buffer.write(words[i]);
        }
        return buffer.toString();
      }
    }

    // Otherwise truncate to return the trailing text, but attempt to start at
    // the beginning of a word.
    var res = text.substring(text.length - maxLength + 4);
    var firstSpace = res.indexOf(' ');
    if (firstSpace > 0) {
      res = res.substring(firstSpace);
    }
    return '...$res';
  }
}

// TODO(sigmund): delete when dartbug.com/17269 is fixed (use `print` instead).
_print([value = '']) => stdout.write('$value\n');

void useCompactVMConfiguration() {
  // If the test is running on the Dart buildbots, we don't want to use this
  // config since it's output may not be what the bots expect.
  if (Platform.environment['LOGNAME'] == 'chrome-bot') {
    return;
  }

  unittestConfiguration = _singleton;
}

final _singleton = new CompactVMConfiguration();
