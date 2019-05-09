// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

html.Element _logElement;
html.Element _logContainer;
List<_LogMessage> _logBuffer = <_LogMessage>[];

class _LogMessage {
  _LogMessage(this.message);

  int duplicateCount = 1;
  final String message;

  @override
  String toString() {
    if (duplicateCount == 1) {
      return message;
    }
    return '${duplicateCount}x $message';
  }
}

/// A drop-in replacement for [print] that prints on the screen into a
/// fixed-positioned element.
///
/// This is useful, for example, for print-debugging on iOS when debugging over
/// USB is not available.
void printOnScreen(Object object) {
  if (_logElement == null) {
    _initialize();
  }

  final String message = '$object';
  if (_logBuffer.isNotEmpty && _logBuffer.last.message == message) {
    _logBuffer.last.duplicateCount += 1;
  } else {
    _logBuffer.add(_LogMessage(message));
  }

  if (_logBuffer.length > 80) {
    _logBuffer = _logBuffer.sublist(_logBuffer.length - 50);
  }

  _logContainer.text = _logBuffer.join('\n');

  // Also log to console for browsers that give you access to it.
  print(message);
}

void _initialize() {
  _logElement = html.Element.tag('flt-onscreen-log');
  _logElement.setAttribute('aria-hidden', 'true');
  _logElement.style
    ..position = 'fixed'
    ..left = '0'
    ..right = '0'
    ..bottom = '0'
    ..height = '25%'
    ..backgroundColor = 'rgba(0, 0, 0, 0.85)'
    ..color = 'white'
    ..fontSize = '8px'
    ..whiteSpace = 'pre-wrap'
    ..overflow = 'hidden'
    ..zIndex = '1000';

  _logContainer = html.Element.tag('flt-log-container');
  _logContainer.setAttribute('aria-hidden', 'true');
  _logContainer.style
    ..position = 'absolute'
    ..bottom = '0';
  _logElement.append(_logContainer);

  html.document.body.append(_logElement);
}
