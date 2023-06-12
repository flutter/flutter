// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:async/async.dart';

import '../util/io.dart';

/// An interactive console for taking user commands.
class Console {
  /// The registered commands.
  final _commands = <String, _Command>{};

  /// The pending next line of standard input, if we're waiting on one.
  CancelableOperation? _nextLine;

  /// Whether the console is currently running.
  bool _running = false;

  /// The terminal escape for red text, or the empty string if this is Windows
  /// or not outputting to a terminal.
  final String _red;

  /// The terminal escape for bold text, or the empty string if this is
  /// Windows or not outputting to a terminal.
  final String _bold;

  /// The terminal escape for removing test coloring, or the empty string if
  /// this is Windows or not outputting to a terminal.
  final String _noColor;

  /// Creates a new [Console].
  ///
  /// If [color] is true, this uses Unix terminal colors.
  Console({bool color = true})
      : _red = color ? '\u001b[31m' : '',
        _bold = color ? '\u001b[1m' : '',
        _noColor = color ? '\u001b[0m' : '' {
    registerCommand('help', 'Displays this help information.', _displayHelp);
  }

  /// Registers a command to be run whenever the user types [name].
  ///
  /// The [description] should be a one-line description of the command to print
  /// in the help output. The [body] callback will be called when the user types
  /// the command, and may return a [Future].
  void registerCommand(
      String name, String description, dynamic Function() body) {
    if (_commands.containsKey(name)) {
      throw ArgumentError('The console already has a command named "$name".');
    }

    _commands[name] = _Command(name, description, body);
  }

  /// Starts running the console.
  ///
  /// This prints the initial prompt and loops while waiting for user input.
  void start() {
    _running = true;
    unawaited(() async {
      while (_running) {
        stdout.write('> ');
        _nextLine = stdinLines.cancelable((queue) => queue.next);
        var commandName = await _nextLine!.value;
        _nextLine = null;

        var command = _commands[commandName];
        if (command == null) {
          stderr.writeln(
              '${_red}Unknown command $_bold$commandName$_noColor$_red.'
              '$_noColor');
        } else {
          await command.body();
        }
      }
    }());
  }

  /// Stops the console running.
  void stop() {
    _running = false;
    if (_nextLine != null) {
      stdout.writeln();
      _nextLine!.cancel();
    }
  }

  /// Displays the help info for the console commands.
  void _displayHelp() {
    var maxCommandLength =
        _commands.values.map((command) => command.name.length).reduce(math.max);

    for (var command in _commands.values) {
      var name = command.name.padRight(maxCommandLength + 4);
      print('$_bold$name$_noColor${command.description}');
    }
  }
}

/// An individual console command.
class _Command {
  /// The name of the command.
  final String name;

  /// The single-line description of the command.
  final String description;

  /// The callback to run when the command is invoked.
  final Function body;

  _Command(this.name, this.description, this.body);
}
