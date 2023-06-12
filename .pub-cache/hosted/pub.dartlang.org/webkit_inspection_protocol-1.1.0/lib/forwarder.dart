// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library crmux.forwarder;

import 'dart:async'
    show Future, Stream, StreamController, StreamSink, StreamSubscription;
import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:logging/logging.dart' show Logger;

import 'dom_model.dart' show flattenAttributesMap;
import 'webkit_inspection_protocol.dart'
    show WipConnection, WipDom, WipError, WipEvent, WipResponse;

/// Forwards a [Stream] to a [WipConnection] and events
/// from a [WipConnection] to a [StreamSink].
class WipForwarder {
  static final _log = Logger('ChromeForwarder');

  final Stream<String> _in;
  final StreamSink _out;
  final WipConnection _debugger;
  final WipDom? domModel;

  /// If false, no Debugger.paused events will be forwarded back to the client.
  /// This gets automatically set to true if a breakpoint is set by the client.
  bool forwardPausedEvents = false;

  final List<StreamSubscription> _subscriptions = <StreamSubscription>[];

  final StreamController<void> _closedController = StreamController.broadcast();

  factory WipForwarder(WipConnection debugger, Stream<String> stream,
      {StreamSink? sink, WipDom? domModel}) {
    sink ??= stream as StreamSink;
    return WipForwarder._(debugger, stream, sink, domModel);
  }

  WipForwarder._(this._debugger, this._in, this._out, this.domModel) {
    _subscriptions.add(_in.listen(_onClientDataHandler,
        onError: _onClientErrorHandler, onDone: _onClientDoneHandler));
    _subscriptions.add(_debugger.onNotification.listen(_onDebuggerDataHandler,
        onError: _onDebuggerErrorHandler, onDone: _onDebuggerDoneHandler));
  }

  Future _onClientDataHandler(String data) async {
    var json = jsonDecode(data) as Map<String, dynamic>;
    var response = {'id': json['id']};
    _log.info('Forwarding to debugger: $data');
    try {
      var method = json['method'] as String;
      var params = json['params'] as Map<String, dynamic>;
      bool processed = false;

      if (method.contains('reakpoint')) {
        forwardPausedEvents = true;
      }

      if (domModel != null) {
        switch (method) {
          case 'DOM.getDocument':
            response['result'] = {'root': (await domModel!.getDocument())};
            processed = true;
            break;
          case 'DOM.getAttributes':
            var attributes = flattenAttributesMap(
                await domModel!.getAttributes(params['nodeId'] as int));
            response['result'] = {'attributes': attributes};
            processed = true;
            break;
        }
      }
      if (!processed) {
        WipResponse resp = await _debugger.sendCommand(method, params);
        if (resp.result != null) {
          response['result'] = resp.result;
        }
      }
    } on WipError catch (e) {
      response['error'] = e.error;
    } catch (e, s) {
      _log.severe(json['id'], e.toString(), s);
      response['error'] = e.toString();
    }
    _log.info('forwarding response: $response');
    _out.add(jsonEncode(response));
  }

  void _onClientErrorHandler(Object error, StackTrace stackTrace) {
    _log.severe('error from forwarded client', error, stackTrace);
  }

  void _onClientDoneHandler() {
    _log.info('forwarded client closed.');
    stop();
  }

  void _onDebuggerDataHandler(WipEvent event) {
    if (event.method == 'Debugger.paused' && !forwardPausedEvents) {
      _log.info('not forwarding event: $event');
      return;
    }
    _log.info('forwarding event: $event');

    var json = <String, dynamic>{'method': event.method};
    if (event.params != null) {
      json['params'] = event.params;
    }
    _out.add(jsonEncode(json));
  }

  void _onDebuggerErrorHandler(Object error, StackTrace stackTrace) {
    _log.severe('error from debugger', error, stackTrace);
  }

  void _onDebuggerDoneHandler() {
    _log.info('debugger closed');
    stop();
  }

  void pause() {
    assert(_subscriptions.isNotEmpty);
    _log.info('Pausing forwarding');
    for (var s in _subscriptions) {
      s.pause();
    }
    _subscriptions.clear();
  }

  void resume() {
    assert(_subscriptions.isNotEmpty);
    _log.info('Resuming forwarding');
    for (var s in _subscriptions) {
      s.resume();
    }
    _subscriptions.clear();
  }

  Future stop() {
    assert(_subscriptions.isNotEmpty);
    _log.info('Stopping forwarding');
    for (var s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    _closedController.add(null);
    return Future.wait([_closedController.close(), _out.close()]);
  }

  Stream get onClosed => _closedController.stream;
}
