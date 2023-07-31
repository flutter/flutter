// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A message emitted by a test.
///
/// A message encompasses any textual information that should be presented to
/// the user. Reporters are encouraged to visually distinguish different message
/// types.
class Message {
  final MessageType type;

  final String text;

  Message(this.type, this.text);

  Message.print(this.text) : type = MessageType.print;
  Message.skip(this.text) : type = MessageType.skip;
}

class MessageType {
  /// A message explicitly printed by the user's test.
  static const print = MessageType._('print');

  /// A message indicating that a test, or some portion of one, was skipped.
  static const skip = MessageType._('skip');

  /// The name of the message type.
  final String name;

  factory MessageType.parse(String name) {
    switch (name) {
      case 'print':
        return MessageType.print;
      case 'skip':
        return MessageType.skip;
      default:
        throw ArgumentError('Invalid message type "$name".');
    }
  }

  const MessageType._(this.name);

  @override
  String toString() => name;
}
