// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';

import 'preprocessor_options.dart';

enum MessageLevel { info, warning, severe }

// TODO(terry): Remove the global messages, use some object that tracks
//              compilation state.

/// The global [Messages] for tracking info/warnings/messages.
late Messages messages;

// Color constants used for generating messages.
const _greenColor = '\u001b[32m';
const _redColor = '\u001b[31m';
const _magentaColor = '\u001b[35m';
const _noColor = '\u001b[0m';

/// Map between error levels and their display color.
const Map<MessageLevel, String> _errorColors = {
  MessageLevel.severe: _redColor,
  MessageLevel.warning: _magentaColor,
  MessageLevel.info: _greenColor,
};

/// Map between error levels and their friendly name.
const Map<MessageLevel, String> _errorLabel = {
  MessageLevel.severe: 'error',
  MessageLevel.warning: 'warning',
  MessageLevel.info: 'info',
};

/// A single message from the compiler.
class Message {
  final MessageLevel level;
  final String message;
  final SourceSpan? span;
  final bool useColors;

  Message(this.level, this.message, {this.span, this.useColors = false});

  @override
  String toString() {
    var output = StringBuffer();
    var colors = useColors && _errorColors.containsKey(level);
    var levelColor = colors ? _errorColors[level] : null;
    if (colors) output.write(levelColor);
    output
      ..write(_errorLabel[level])
      ..write(' ');
    if (colors) output.write(_noColor);

    if (span == null) {
      output.write(message);
    } else {
      output.write('on ');
      output.write(span!.message(message, color: levelColor));
    }

    return output.toString();
  }
}

/// This class tracks and prints information, warnings, and errors emitted by
/// the compiler.
class Messages {
  /// Called on every error. Set to blank function to supress printing.
  final void Function(Message obj) printHandler;

  final PreprocessorOptions options;

  final List<Message> messages = <Message>[];

  Messages({PreprocessorOptions? options, this.printHandler = print})
      : options = options ?? PreprocessorOptions();

  /// Report a compile-time CSS error.
  void error(String message, SourceSpan? span) {
    var msg = Message(MessageLevel.severe, message,
        span: span, useColors: options.useColors);

    messages.add(msg);

    printHandler(msg);
  }

  /// Report a compile-time CSS warning.
  void warning(String message, SourceSpan? span) {
    if (options.warningsAsErrors) {
      error(message, span);
    } else {
      var msg = Message(MessageLevel.warning, message,
          span: span, useColors: options.useColors);

      messages.add(msg);
    }
  }

  /// Report and informational message about what the compiler is doing.
  void info(String message, SourceSpan span) {
    var msg = Message(MessageLevel.info, message,
        span: span, useColors: options.useColors);

    messages.add(msg);

    if (options.verbose) printHandler(msg);
  }

  /// Merge [newMessages] to this message lsit.
  void mergeMessages(Messages newMessages) {
    messages.addAll(newMessages.messages);
    newMessages.messages
        .where((message) =>
            message.level == MessageLevel.severe || options.verbose)
        .forEach(printHandler);
  }
}
