// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'logger.dart';
import 'platform.dart';
import 'terminal.dart';

// ignore_for_file: non_constant_identifier_names

const String fire = '🔥';
const String image = '🖼️';
const int maxLineWidth = 84;

/// Encapsulates the help text construction and printing.
class CommandHelp {
  CommandHelp({
    @required Logger logger,
    @required AnsiTerminal terminal,
    @required Platform platform,
    @required OutputPreferences outputPreferences,
  }) : _logger = logger,
       _terminal = terminal,
       _platform = platform,
       _outputPreferences = outputPreferences;

  final Logger _logger;

  final AnsiTerminal _terminal;

  final Platform _platform;

  final OutputPreferences _outputPreferences;

  CommandHelpOption _I;
  CommandHelpOption get I => _I ??= _makeOption(
    'I',
    'Toggle oversized image inversion $image.',
    'debugInvertOversizedImages',
  );

  CommandHelpOption _L;
  CommandHelpOption get L => _L ??= _makeOption(
    'L',
    'Dump layer tree to the console.',
    'debugDumpLayerTree',
  );

  CommandHelpOption _P;
  CommandHelpOption get P => _P ??= _makeOption(
    'P',
    'Toggle performance overlay.',
    'WidgetsApp.showPerformanceOverlay',
  );

  CommandHelpOption _R;
  CommandHelpOption get R => _R ??= _makeOption(
    'R',
    'Hot restart.',
  );

  CommandHelpOption _S;
  CommandHelpOption get S => _S ??= _makeOption(
    'S',
    'Dump accessibility tree in traversal order.',
    'debugDumpSemantics',
  );

  CommandHelpOption _U;
  CommandHelpOption get U => _U ??= _makeOption(
    'U',
    'Dump accessibility tree in inverse hit test order.',
    'debugDumpSemantics',
  );

  CommandHelpOption _a;
  CommandHelpOption get a => _a ??= _makeOption(
    'a',
    'Toggle timeline events for all widget build methods.',
    'debugProfileWidgetBuilds',
  );

  CommandHelpOption _b;
  CommandHelpOption get b => _b ??= _makeOption(
    'b',
    'Toggle the platform brightness setting (dark and light mode).',
    'debugBrightnessOverride',
  );

  CommandHelpOption _c;
  CommandHelpOption get c => _c ??= _makeOption(
    'c',
    'Clear the screen',
  );

  CommandHelpOption _d;
  CommandHelpOption get d => _d ??= _makeOption(
    'd',
    'Detach (terminate "flutter run" but leave application running).',
  );

  CommandHelpOption _g;
  CommandHelpOption get g => _g ??= _makeOption(
    'g',
    'Run source code generators.'
  );

  CommandHelpOption _h;
  CommandHelpOption get h => _h ??= _makeOption(
    'h',
    'Repeat this help message.',
  );

  CommandHelpOption _i;
  CommandHelpOption get i => _i ??= _makeOption(
    'i',
    'Toggle widget inspector.',
    'WidgetsApp.showWidgetInspectorOverride',
  );

  CommandHelpOption _o;
  CommandHelpOption get o => _o ??= _makeOption(
    'o',
    'Simulate different operating systems.',
    'defaultTargetPlatform',
  );

  CommandHelpOption _p;
  CommandHelpOption get p => _p ??= _makeOption(
    'p',
    'Toggle the display of construction lines.',
    'debugPaintSizeEnabled',
  );

  CommandHelpOption _q;
  CommandHelpOption get q => _q ??= _makeOption(
    'q',
    'Quit (terminate the application on the device).',
  );

  CommandHelpOption _r;
  CommandHelpOption get r => _r ??= _makeOption(
    'r',
    'Hot reload. $fire$fire$fire',
  );

  CommandHelpOption _s;
  CommandHelpOption get s => _s ??= _makeOption(
    's',
    'Save a screenshot to flutter.png.',
  );

  CommandHelpOption _t;
  CommandHelpOption get t => _t ??= _makeOption(
    't',
    'Dump rendering tree to the console.',
    'debugDumpRenderTree',
  );

  CommandHelpOption _v;
  CommandHelpOption get v => _v ??= _makeOption(
    'v',
    'Launch DevTools.',
  );

  CommandHelpOption _w;
  CommandHelpOption get w => _w ??= _makeOption(
    'w',
    'Dump widget hierarchy to the console.',
    'debugDumpApp',
  );

  CommandHelpOption _z;
  CommandHelpOption get z => _z ??= _makeOption(
    'z',
    'Toggle elevation checker.',
  );

  CommandHelpOption _k;
  CommandHelpOption get k => _k ??= _makeOption(
    'k',
    'Toggle CanvasKit rendering.',
  );

  CommandHelpOption _M;
  CommandHelpOption get M => _M ??= _makeOption(
    'M',
    'Write SkSL shaders to a unique file in the project directory.',
  );

  CommandHelpOption _makeOption(String key, String description, [
    String inParenthesis = '',
  ]) {
    return CommandHelpOption(
      key,
      description,
      inParenthesis: inParenthesis,
      logger: _logger,
      terminal: _terminal,
      platform: _platform,
      outputPreferences: _outputPreferences,
    );
  }
}

/// Encapsulates printing help text for a single option.
class CommandHelpOption {
  CommandHelpOption(
    this.key,
    this.description, {
    this.inParenthesis = '',
    @required Logger logger,
    @required Terminal terminal,
    @required Platform platform,
    @required OutputPreferences outputPreferences,
  }) : _logger = logger,
       _terminal = terminal,
       _platform = platform,
       _outputPreferences = outputPreferences;

  final Logger _logger;

  final Terminal _terminal;

  final Platform _platform;

  final OutputPreferences _outputPreferences;

  /// The key associated with this command.
  final String key;
  /// A description of what this command does.
  final String description;
  /// Text shown in parenthesis to give the context.
  final String inParenthesis;

  bool get _hasTextInParenthesis => inParenthesis != null && inParenthesis.isNotEmpty;

  int get _rawMessageLength => key.length + description.length;

  @override
  String toString() {
    final StringBuffer message = StringBuffer();
    message.writeAll(<String>[_terminal.bolden(key), description], ' ');
    if (!_hasTextInParenthesis) {
      return message.toString();
    }

    bool wrap = false;
    final int maxWidth = math.max(
      _outputPreferences.wrapColumn ?? 0,
      maxLineWidth,
    );
    final int adjustedMessageLength = _platform.stdoutSupportsAnsi
      ? _rawMessageLength + 1
      : message.length;
    int width = maxWidth - adjustedMessageLength;
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
    message.write(_terminal.color(parentheticalText, TerminalColor.grey));

    // Terminals seem to require this because we have both boldened and colored
    // a line. Otherwise the next line comes out bold until a reset bold.
    if (_terminal.supportsColor) {
      message.write(AnsiTerminal.resetBold);
    }

    return message.toString();
  }

  void print() {
    _logger.printStatus(toString());
  }
}
