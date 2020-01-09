// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import '../globals.dart' as globals;
import 'terminal.dart';

const String fire = '🔥';
const int maxLineWidth = 84;

/// Encapsulates the help text construction and printing
class CommandHelp {

  const CommandHelp._(this.key, this.description, [this.inParenthesis = '']);

  static const CommandHelp L = CommandHelp._('L', 'Dump layer tree to the console.', 'debugDumpLayerTree');
  static const CommandHelp P = CommandHelp._('P', 'Toggle performance overlay.', 'WidgetsApp.showPerformanceOverlay');
  static const CommandHelp R = CommandHelp._('R', 'Hot restart.');
  static const CommandHelp S = CommandHelp._('S', 'Dump accessibility tree in traversal order.', 'debugDumpSemantics');
  static const CommandHelp U = CommandHelp._('U', 'Dump accessibility tree in inverse hit test order.', 'debugDumpSemantics');
  static const CommandHelp a = CommandHelp._('a', 'Toggle timeline events for all widget build methods.', 'debugProfileWidgetBuilds');
  static const CommandHelp d = CommandHelp._('d', 'Detach (terminate "flutter run" but leave application running).');
  static const CommandHelp h = CommandHelp._('h', 'Repeat this help message.');
  static const CommandHelp i = CommandHelp._('i', 'Toggle widget inspector.', 'WidgetsApp.showWidgetInspectorOverride');
  static const CommandHelp o = CommandHelp._('o', 'Simulate different operating systems.', 'defaultTargetPlatform');
  static const CommandHelp p = CommandHelp._('p', 'Toggle the display of construction lines.', 'debugPaintSizeEnabled');
  static const CommandHelp q = CommandHelp._('q', 'Quit (terminate the application on the device).');
  static const CommandHelp r = CommandHelp._('r', 'Hot reload. $fire$fire$fire');
  static const CommandHelp s = CommandHelp._('s', 'Save a screenshot to flutter.png.');
  static const CommandHelp t = CommandHelp._('t', 'Dump rendering tree to the console.', 'debugDumpRenderTree');
  static const CommandHelp w = CommandHelp._('w', 'Dump widget hierarchy to the console.', 'debugDumpApp');
  static const CommandHelp z = CommandHelp._('z', 'Toggle elevation checker.');

  /// The key associated with this command
  final String key;
  /// A description of what this command does
  final String description;
  /// Text shown in parenthesis to give the context
  final String inParenthesis;

  bool get _hasTextInParenthesis => inParenthesis != null && inParenthesis.isNotEmpty;

  int get _rawMessageLength => key.length + description.length;

  @override
  String toString() {
    final StringBuffer message = StringBuffer();
    message.writeAll(<String>[globals.terminal.bolden(key), description], ' ');

    if (_hasTextInParenthesis) {
      bool wrap = false;
      final int maxWidth = math.max(outputPreferences.wrapColumn ?? 0,  maxLineWidth);
      int width = maxWidth - (globals.platform.stdoutSupportsAnsi ? _rawMessageLength + 1 : message.length);
      final String parentheticalText = '($inParenthesis)';
      if (width < parentheticalText.length) {
        width = maxWidth;
        wrap = true;
      }

      if (wrap) {
        message.write('\n');
      }
      // pad according to the raw text
      message.write(''.padLeft(width - parentheticalText.length));

      message.write(globals.terminal.color(parentheticalText, TerminalColor.grey));
    }
    return message.toString();
  }

  void print() {
    globals.printStatus(toString());
  }
}
