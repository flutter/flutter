// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

/// Signature for [debugPrint] implementations.
typedef void DebugPrintCallback(String message, { int wrapWidth });

const bool _kThrottlePrint = false;

/// Prints a message to the console, which you can access using the "flutter"
/// tool's "logs" command ("flutter logs").
///
/// If a wrapWidth is provided, each line of the message is word-wrapped to that
/// width. (Lines may be separated by newline characters, as in '\n'.)
///
/// This function very crudely attempts to throttle the rate at which messages
/// are sent to avoid data loss on Android. This means that interleaving calls
/// to this function (directly or indirectly via [debugDumpRenderTree] or
/// [debugDumpApp]) and to the Dart [print] method can result in out-of-order
/// messages in the logs.
///
/// The implementation of this function can be replaced by setting the
/// variable to a new implementation that matches the
/// [DebugPrintCallback] signature. For example, flutter_test does this.
DebugPrintCallback debugPrint = _defaultDebugPrint;

void _defaultDebugPrint(String message, { int wrapWidth }) {
  if (wrapWidth != null) {
    _debugPrintBuffer.addAll(message.split('\n').expand((String line) => debugWordWrap(line, wrapWidth)));
  } else {
    _debugPrintBuffer.addAll(message.split('\n'));
  }
  if (!_debugPrintScheduled)
    _debugPrintTask();
}
int _debugPrintedCharacters = 0;
const int _kDebugPrintCapacity = 16 * 1024;
Duration _kDebugPrintPauseTime = const Duration(seconds: 1);
Queue<String> _debugPrintBuffer = new Queue<String>();
Stopwatch _debugPrintStopwatch = new Stopwatch();
bool _debugPrintScheduled = false;
void _debugPrintTask() {
  _debugPrintScheduled = false;
  if (_debugPrintStopwatch.elapsed > _kDebugPrintPauseTime) {
    _debugPrintStopwatch.stop();
    _debugPrintStopwatch.reset();
    _debugPrintedCharacters = 0;
  }
  while ((!_kThrottlePrint || _debugPrintedCharacters < _kDebugPrintCapacity) && _debugPrintBuffer.length > 0) {
    String line = _debugPrintBuffer.removeFirst();
    _debugPrintedCharacters += line.length; // TODO(ianh): Use the UTF-8 byte length instead
    print(line);
  }
  if (_debugPrintBuffer.length > 0) {
    _debugPrintScheduled = true;
    _debugPrintedCharacters = 0;
    new Timer(_kDebugPrintPauseTime, _debugPrintTask);
  } else {
    _debugPrintStopwatch.start();
  }
}

final RegExp _indentPattern = new RegExp('^ *(?:[-+*] |[0-9]+[.):] )?');
enum _WordWrapParseMode { inSpace, inWord, atBreak }
/// Wraps the given string at the given width.
///
/// Wrapping occurs at space characters (U+0020). Lines that start
/// with an octothorpe ("#", U+0023) are not wrapped (so for example,
/// Dart stack traces won't be wrapped).
///
/// This is not suitable for use with arbitrary Unicode text. For
/// example, it doesn't implement UAX #14, can't handle ideographic
/// text, doesn't hyphenate, and so forth. It is only intended for
/// formatting error messages.
///
/// The default [debugPrint] implementation uses this for its line
/// wrapping.
Iterable<String> debugWordWrap(String message, int width) sync* {
  if (message.length < width || message[0] == '#') {
    yield message;
    return;
  }
  Match prefixMatch = _indentPattern.matchAsPrefix(message);
  String prefix = ' ' * prefixMatch.group(0).length;
  int start = 0;
  int startForLengthCalculations = 0;
  bool addPrefix = false;
  int index = prefix.length;
  _WordWrapParseMode mode = _WordWrapParseMode.inSpace;
  int lastWordStart;
  int lastWordEnd;
  while (true) {
    switch (mode) {
      case _WordWrapParseMode.inSpace: // at start of break point (or start of line); can't break until next break
        while ((index < message.length) && (message[index] == ' '))
          index += 1;
        lastWordStart = index;
        mode = _WordWrapParseMode.inWord;
        break;
      case _WordWrapParseMode.inWord: // looking for a good break point
        while ((index < message.length) && (message[index] != ' '))
          index += 1;
        mode = _WordWrapParseMode.atBreak;
        break;
      case _WordWrapParseMode.atBreak: // at start of break point
        if ((index - startForLengthCalculations > width) || (index == message.length)) {
          // we are over the width line, so break
          if ((index - startForLengthCalculations <= width) || (lastWordEnd == null)) {
            // we should use this point, before either it doesn't actually go over the end (last line), or it does, but there was no earlier break point
            lastWordEnd = index;
          }
          if (addPrefix) {
            yield prefix + message.substring(start, lastWordEnd);
          } else {
            yield message.substring(start, lastWordEnd);
            addPrefix = true;
          }
          if (lastWordEnd >= message.length)
            return;
          // just yielded a line
          if (lastWordEnd == index) {
            // we broke at current position
            // eat all the spaces, then set our start point
            while ((index < message.length) && (message[index] == ' '))
              index += 1;
            start = index;
            mode = _WordWrapParseMode.inWord;
          } else {
            // we broke at the previous break point, and we're at the start of a new one
            assert(lastWordStart > lastWordEnd);
            start = lastWordStart;
            mode = _WordWrapParseMode.atBreak;
          }
          startForLengthCalculations = start - prefix.length;
          assert(addPrefix);
          lastWordEnd = null;
        } else {
          // save this break point, we're not yet over the line width
          lastWordEnd = index;
          // skip to the end of this break point
          mode = _WordWrapParseMode.inSpace;
        }
        break;
    }
  }
}

/// Dump the current stack to the console using [debugPrint].
///
/// The current stack is obtained using [StackTrace.current].
void debugPrintStack() {
  debugPrint(StackTrace.current.toString());
}
