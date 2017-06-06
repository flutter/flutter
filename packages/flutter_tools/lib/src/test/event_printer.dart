import 'dart:convert' show JSON;

import '../base/io.dart' show stdout;
import 'watcher.dart';

/// Prints JSON events when running a test in --machine mode.
class EventPrinter extends TestWatcher {
  EventPrinter({StringSink out}) : this._out = out == null ? stdout: out;

  final StringSink _out;

  @override
  void onStartedProcess(ProcessEvent event) {
    _sendEvent("test.startedProcess",
        <String, dynamic>{"observatoryUri": event.observatoryUri.toString()});
  }

  void _sendEvent(String name, [dynamic args]) {
    final Map<String, dynamic> map = <String, dynamic>{ 'event': name};
    if (args != null) {
      map['params'] = args;
    }
    _send(map);
  }

  void _send(Map<String, dynamic> command) {
    final String encoded = JSON.encode(command, toEncodable: _jsonEncodeObject);
    _out.writeln('\n[$encoded]');
  }

  dynamic _jsonEncodeObject(dynamic object) {
    if (object is Uri) {
      return object.toString();
    }
    return object;
  }
}
