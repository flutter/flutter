// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of bindings;

/// Generated StubControl classes implement this interface.
/// StubControl objects are accessible through the [ctrl] field on Stubs.
abstract class StubControl<T> implements StubMessageHandler {
  // TODO(zra): This is only used by ApplicationConnection.requestService(), so
  // try to remove when/after ApplicationConnection is removed/refactored.
  String get serviceName;

  /// [impl] refers to the implementation of the methods of the interface T.
  T impl;
}

/// Generated Stub classes extend this base class.
class Stub<T> implements MojoInterface<T> {
  // In general it's probalby better to avoid adding fields and methods to this
  // class. Names added to this class have to be mangled by Mojo bindings
  // generation to avoid name conflicts.

  /// Proxies control the StubMessageHandler by way of this [StubControl]
  /// object.
  final StubControl<T> ctrl;

  Stub(this.ctrl);

  /// This is a convenience method that simply forwards to ctrl.close().
  /// If a Mojo interface has a method 'close', its name will be mangled to be
  /// 'close_'.
  Future close({bool immediate: false}) => ctrl.close(immediate: immediate);

  /// This getter and setter pair is for convenience and simply forwards to
  /// ctrl.impl. If a Mojo interface has a method 'impl', its name will be
  /// mangled to be 'impl_'.
  T get impl => ctrl.impl;
  set impl(T impl) {
    ctrl.impl = impl;
  }
}

abstract class StubMessageHandler extends core.MojoEventHandler
                                  implements MojoInterfaceControl {
  int _outstandingResponseFutures = 0;
  bool _isClosing = false;
  Completer _closeCompleter;

  StubMessageHandler.fromEndpoint(core.MojoMessagePipeEndpoint endpoint,
                                  {bool autoBegin: true})
      : super.fromEndpoint(endpoint, autoBegin: autoBegin);

  StubMessageHandler.fromHandle(core.MojoHandle handle, {bool autoBegin: true})
      : super.fromHandle(handle, autoBegin: autoBegin);

  StubMessageHandler.unbound() : super.unbound();

  /// Generated StubControl classes implement this method to route messages to
  /// the correct implementation method.
  dynamic handleMessage(ServiceMessage message);

  /// Generated StubControl classes implement this getter to return the version
  /// of the mojom interface for which the bindings are generated.
  int get version;

  @override
  void handleRead() {
    var result = endpoint.queryAndRead();
    if ((result.data == null) || (result.dataLength == 0)) {
      throw new MojoCodecError('Unexpected empty message or error: $result');
    }

    // Prepare the response.
    var message;
    var response;
    try {
      message = new ServiceMessage.fromMessage(new Message(result.data,
          result.handles, result.dataLength, result.handlesLength));
      response = _isClosing ? null : handleMessage(message);
    } catch (e) {
      if (result.handles != null) {
        result.handles.forEach((h) => h.close());
      }
      rethrow;
    }

    // If there's a response, send it.
    if (response != null) {
      if (response is Future) {
        _outstandingResponseFutures++;
        response.then((response) {
          _outstandingResponseFutures--;
          return response;
        }).then(_sendResponse);
      } else {
        _sendResponse(response);
      }
    } else if (_isClosing && (_outstandingResponseFutures == 0)) {
      // We are closing, there is no response to send for this message, and
      // there are no outstanding response futures. Do the close now.
      super.close().then((_) {
        if (_isClosing) {
          _isClosing = false;
          _closeCompleter.complete(null);
          _closeCompleter = null;
        }
      });
    }
  }

  @override
  void handleWrite() {
    throw 'Unexpected write signal in client.';
  }

  // NB: |immediate| should only be true when calling close() while handling an
  // exception thrown from handleRead(), e.g. when we receive a malformed
  // message, or when we have received the PEER_CLOSED event.
  @override
  Future close({bool immediate: false}) {
    if (isOpen &&
        !immediate &&
        !isPeerClosed &&
        (isInHandler || (_outstandingResponseFutures > 0))) {
      // Either close() is being called from within handleRead() or
      // handleWrite(), or close() is being called while there are outstanding
      // response futures. Defer the actual close until all response futures
      // have been resolved.
      _isClosing = true;
      _closeCompleter = new Completer();
      return _closeCompleter.future;
    } else {
      return super.close(immediate: immediate).then((_) {
        if (_isClosing) {
          _isClosing = false;
          _closeCompleter.complete(null);
          _closeCompleter = null;
        }
      });
    }
  }

  Message buildResponse(Struct response, int name) {
    var header = new MessageHeader(name);
    return response.serializeWithHeader(header);
  }

  Message buildResponseWithId(Struct response, int name, int id, int flags) {
    var header = new MessageHeader.withRequestId(name, flags, id);
    return response.serializeWithHeader(header);
  }

  @override
  String toString() {
    var superString = super.toString();
    return "StubMessageHandler(${superString})";
  }

  /// Returns a service description, which exposes the mojom type information
  /// of the service being stubbed.
  /// Note: The description is null or incomplete if type info is unavailable.
  service_describer.ServiceDescription get description => null;

  void _sendResponse(Message response) {
    if (isOpen) {
      endpoint.write(
          response.buffer, response.buffer.lengthInBytes, response.handles);
      // FailedPrecondition is only used to indicate that the other end of
      // the pipe has been closed. We can ignore the close here and wait for
      // the PeerClosed signal on the event stream.
      assert((endpoint.status == core.MojoResult.kOk) ||
          (endpoint.status == core.MojoResult.kFailedPrecondition));
      if (_isClosing && (_outstandingResponseFutures == 0)) {
        // This was the final response future for which we needed to send
        // a response. It is safe to close.
        super.close().then((_) {
          if (_isClosing) {
            _isClosing = false;
            _closeCompleter.complete(null);
            _closeCompleter = null;
          }
        });
      }
    }
  }
}
