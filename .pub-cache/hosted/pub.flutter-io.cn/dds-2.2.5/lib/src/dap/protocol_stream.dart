// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'exceptions.dart';
import 'logging.dart';
import 'protocol_generated.dart';
import 'protocol_stream_transformers.dart';

// TODO(dantup): This class should mostly be shareable with the LSP version,
// but the ProtocolMessage, Request, Response, Event classes are different so
// will need specializations.

/// A wrapper over a Stream/StreamSink that encodes/decores DAP/LSP
/// request/response/event messages.
class ByteStreamServerChannel {
  final Stream<List<int>> _input;

  final StreamSink<List<int>> _output;

  final Logger? _logger;

  /// Completer that will be signalled when the input stream is closed.
  final Completer _closed = Completer();

  /// True if [close] has been called.
  bool _closeRequested = false;

  ByteStreamServerChannel(this._input, this._output, this._logger);

  /// Future that will be completed when the input stream is closed.
  Future get closed {
    return _closed.future;
  }

  void close() {
    if (!_closeRequested) {
      _closeRequested = true;
      assert(!_closed.isCompleted);
      _output.close();
      _closed.complete();
    }
  }

  StreamSubscription<String> listen(
      void Function(ProtocolMessage message) onMessage,
      {Function? onError,
      void Function()? onDone}) {
    return _input.transform(PacketTransformer()).listen(
      (String data) => _readMessage(data, onMessage),
      onError: onError,
      onDone: () {
        close();
        if (onDone != null) {
          onDone();
        }
      },
    );
  }

  void sendEvent(Event event) => _sendLsp(event.toJson());

  void sendRequest(Request request) => _sendLsp(request.toJson());

  void sendResponse(Response response) => _sendLsp(response.toJson());

  /// Read a request from the given [data] and use the given function to handle
  /// the message.
  void _readMessage(String data, void Function(ProtocolMessage) onMessage) {
    // Ignore any further requests after the communication channel is closed.
    if (_closed.isCompleted) {
      return;
    }
    _logger?.call('<== [DAP] $data');
    try {
      final Map<String, Object?> json = jsonDecode(data);
      final type = json['type'] as String;
      if (type == 'request') {
        onMessage(Request.fromJson(json));
      } else if (type == 'event') {
        onMessage(Event.fromJson(json));
      } else if (type == 'response') {
        onMessage(Response.fromJson(json));
      } else {
        _sendParseError(data);
      }
    } catch (e) {
      _sendParseError(data);
    }
  }

  /// Sends a message prefixed with the required LSP headers.
  void _sendLsp(Map<String, Object?> json) {
    // Don't send any further responses after the communication channel is
    // closed.
    if (_closeRequested) {
      return;
    }
    final jsonEncodedBody = jsonEncode(json);
    final utf8EncodedBody = utf8.encode(jsonEncodedBody);
    final header = 'Content-Length: ${utf8EncodedBody.length}\r\n'
        'Content-Type: application/vscode-jsonrpc; charset=utf-8\r\n\r\n';
    final asciiEncodedHeader = ascii.encode(header);

    // Header is always ascii, body is always utf8!
    _write(asciiEncodedHeader);
    _write(utf8EncodedBody);

    _logger?.call('==> [DAP] $jsonEncodedBody');
  }

  void _sendParseError(String data) {
    // TODO(dantup): Review LSP implementation of this when consolidating classes.
    throw DebugAdapterException('Message does not confirm to DAP spec: $data');
  }

  /// Send [bytes] to [_output].
  void _write(List<int> bytes) {
    runZonedGuarded(
      () => _output.add(bytes),
      (e, s) => close(),
    );
  }
}
