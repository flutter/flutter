// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../webkit_inspection_protocol.dart';

@Deprecated('This domain is deprecated - use Runtime or Log instead')
class WipConsole extends WipDomain {
  WipConsole(WipConnection connection) : super(connection);

  Future<WipResponse> enable() => sendCommand('Console.enable');

  Future<WipResponse> disable() => sendCommand('Console.disable');

  Future<WipResponse> clearMessages() => sendCommand('Console.clearMessages');

  Stream<ConsoleMessageEvent> get onMessage => eventStream(
      'Console.messageAdded',
      (WipEvent event) => ConsoleMessageEvent(event.json));

  Stream<ConsoleClearedEvent> get onCleared => eventStream(
      'Console.messagesCleared',
      (WipEvent event) => ConsoleClearedEvent(event.json));
}

class ConsoleMessageEvent extends WipEvent {
  ConsoleMessageEvent(Map<String, dynamic> json) : super(json);

  Map get _message => params!['message'] as Map;

  String get text => _message['text'] as String;

  String get level => _message['level'] as String;

  String? get url => _message['url'] as String?;

  Iterable<WipConsoleCallFrame> getStackTrace() {
    if (_message.containsKey('stackTrace')) {
      return (params!['stackTrace'] as List).map((frame) =>
          WipConsoleCallFrame.fromMap(frame as Map<String, dynamic>));
    } else {
      return [];
    }
  }

  @override
  String toString() => text;
}

class ConsoleClearedEvent extends WipEvent {
  ConsoleClearedEvent(Map<String, dynamic> json) : super(json);
}

class WipConsoleCallFrame {
  final Map<String, dynamic> json;

  WipConsoleCallFrame.fromMap(this.json);

  int get columnNumber => json['columnNumber'] as int;

  String get functionName => json['functionName'] as String;

  int get lineNumber => json['lineNumber'] as int;

  String get scriptId => json['scriptId'] as String;

  String get url => json['url'] as String;
}
