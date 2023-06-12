// Copyright 2017 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../webkit_inspection_protocol.dart';

class WipLog extends WipDomain {
  WipLog(WipConnection connection) : super(connection);

  Future<WipResponse> enable() => sendCommand('Log.enable');

  Future<WipResponse> disable() => sendCommand('Log.disable');

  Stream<LogEntry> get onEntryAdded =>
      eventStream('Log.entryAdded', (WipEvent event) => LogEntry(event.json));
}

class LogEntry extends WipEvent {
  LogEntry(Map<String, dynamic> json) : super(json);

  Map<String, dynamic> get _entry => params!['entry'] as Map<String, dynamic>;

  /// Log entry source. Allowed values: xml, javascript, network, storage,
  /// appcache, rendering, security, deprecation, worker, violation,
  /// intervention, other.
  String get source => _entry['source'] as String;

  /// Log entry severity. Allowed values: verbose, info, warning, error.
  String get level => _entry['level'] as String;

  /// Logged text.
  String get text => _entry['text'] as String;

  /// URL of the resource if known.
  @optional
  String? get url => _entry['url'] as String?;

  /// Timestamp when this entry was added.
  num get timestamp => _entry['timestamp'] as num;

  @override
  String toString() => text;
}
