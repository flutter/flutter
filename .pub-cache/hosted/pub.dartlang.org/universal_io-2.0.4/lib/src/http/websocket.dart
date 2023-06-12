// ------------------------------------------------------------------
// THIS FILE WAS DERIVED FROM SOURCE CODE UNDER THE FOLLOWING LICENSE
// ------------------------------------------------------------------
//
// Copyright 2012, the Dart project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---------------------------------------------------------
// THIS, DERIVED FILE IS LICENSE UNDER THE FOLLOWING LICENSE
// ---------------------------------------------------------
// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

part of universal_io.http;

/// Options controlling compression in a [WebSocket].
///
/// A [CompressionOptions] instance can be passed to [WebSocket.connect], or
/// used in other similar places where [WebSocket] compression is configured.
///
/// In most cases the default [compressionDefault] is sufficient, but in some
/// situations, it might be desirable to use different compression parameters,
/// for example to preserve memory on small devices.
class CompressionOptions {
  /// Default [WebSocket] compression configuration.
  ///
  /// Enables compression with default window sizes and no reuse. This is the
  /// default options used by [WebSocket.connect] if no [CompressionOptions] is
  /// supplied.
  ///
  /// * `clientNoContextTakeover`: false
  /// * `serverNoContextTakeover`: false
  /// * `clientMaxWindowBits`: null (default maximal window size of 15 bits)
  /// * `serverMaxWindowBits`: null (default maximal window size of 15 bits)
  static const CompressionOptions compressionDefault = CompressionOptions();
  @Deprecated('Use compressionDefault instead')
  static const CompressionOptions DEFAULT = compressionDefault;

  /// No-compression configuration.
  ///
  /// Disables compression when used as compression configuration for a
  /// [WebSocket].
  static const CompressionOptions compressionOff =
      CompressionOptions(enabled: false);
  @Deprecated('Use compressionOff instead')
  static const CompressionOptions OFF = compressionOff;

  /// Whether the client will reuse its compression instances.
  final bool clientNoContextTakeover;

  /// Whether the server will reuse its compression instances.
  final bool serverNoContextTakeover;

  /// The maximal window size bit count requested by the client.
  ///
  /// The windows size for the compression is always a power of two, so the
  /// number of bits precisely determines the window size.
  ///
  /// If set to `null`, the client has no preference, and the compression can
  /// use up to its default maximum window size of 15 bits depending on the
  /// server's preference.
  final int? clientMaxWindowBits;

  /// The maximal window size bit count requested by the server.
  ///
  /// The windows size for the compression is always a power of two, so the
  /// number of bits precisely determines the window size.
  ///
  /// If set to `null`, the server has no preference, and the compression can
  /// use up to its default maximum window size of 15 bits depending on the
  /// client's preference.
  final int? serverMaxWindowBits;

  /// Whether WebSocket compression is enabled.
  ///
  /// If not enabled, the remaining fields have no effect, and the
  /// [compressionOff] instance can, and should, be reused instead of creating a
  /// new instance with compression disabled.
  final bool enabled;

  const CompressionOptions(
      {this.clientNoContextTakeover = false,
      this.serverNoContextTakeover = false,
      this.clientMaxWindowBits,
      this.serverMaxWindowBits,
      this.enabled = true});
}

/// A two-way HTTP communication object for client or server applications.
///
/// The stream exposes the messages received. A text message will be of type
/// `String` and a binary message will be of type `List<int>`.
abstract class WebSocket
    implements
        Stream<dynamic /*String|List<int>*/ >,
        StreamSink<dynamic /*String|List<int>*/ > {
  /// Possible states of the connection.
  static const int connecting = 0;
  static const int open = 1;
  static const int closing = 2;
  static const int closed = 3;

  @Deprecated('Use connecting instead')
  static const int CONNECTING = connecting;
  @Deprecated('Use open instead')
  static const int OPEN = open;
  @Deprecated('Use closing instead')
  static const int CLOSING = closing;
  @Deprecated('Use closed instead')
  static const int CLOSED = closed;

  /// Gets the user agent used for WebSocket connections.
  static String? userAgent;

  /// The interval between ping signals.
  ///
  /// A ping message is sent every [pingInterval], starting at the first
  /// [pingInterval] after a new value has been assigned or a pong message has
  /// been received. If a ping message is not answered by a pong message from the
  /// peer, the `WebSocket` is assumed disconnected and the connection is closed
  /// with a [WebSocketStatus.goingAway] close code. When a ping signal is sent,
  /// the pong message must be received within [pingInterval].
  ///
  /// There are never two outstanding pings at any given time, and the next ping
  /// timer starts when the pong is received.
  ///
  /// Set the [pingInterval] to `null` to disable sending ping messages.
  ///
  /// The default value is `null`.
  Duration? pingInterval;

  @Deprecated('This constructor will be removed in Dart 2.0. Use `implements`'
      ' instead of `extends` if implementing this abstract class.')
  WebSocket();

  /// Creates a WebSocket from an already-upgraded socket.
  ///
  /// The initial WebSocket handshake must have occurred prior to this call. A
  /// WebSocket client can automatically perform the handshake using
  /// [WebSocket.connect], while a server can do so using
  /// [WebSocketTransformer.upgrade]. To manually upgrade an [HttpRequest],
  /// [HttpResponse.detachSocket] may be called.
  ///
  /// [protocol] should be the protocol negotiated by this handshake, if any.
  ///
  /// [serverSide] must be passed explicitly. If it's `false`, the WebSocket will
  /// act as the client and mask the messages it sends. If it's `true`, it will
  /// act as the server and will not mask its messages.
  ///
  /// If [compression] is provided, the [WebSocket] created will be configured
  /// to negotiate with the specified [CompressionOptions]. If none is specified
  /// then the [WebSocket] will be created with the default [CompressionOptions].
  factory WebSocket.fromUpgradedSocket(Socket socket,
      {String? protocol,
      bool? serverSide,
      CompressionOptions compression = CompressionOptions.compressionDefault}) {
    throw UnimplementedError();
  }

  /// The close code set when the WebSocket connection is closed. If
  /// there is no close code available this property will be [:null:]
  int? get closeCode;

  /// The close reason set when the WebSocket connection is closed. If
  /// there is no close reason available this property will be [:null:]
  String? get closeReason;

  /// The extensions property is initially the empty string. After the
  /// WebSocket connection is established this string reflects the
  /// extensions used by the server.
  String get extensions;

  /// The protocol property is initially the empty string. After the
  /// WebSocket connection is established the value is the subprotocol
  /// selected by the server. If no subprotocol is negotiated the
  /// value will remain [:null:].
  String? get protocol;

  /// Returns the current state of the connection.
  int get readyState;

  /// Sends data on the WebSocket connection. The data in [data] must
  /// be either a `String`, or a `List<int>` holding bytes.
  @override
  void add(/*String|List<int>*/ data);

  /// Sends data from a stream on WebSocket connection. Each data event from
  /// [stream] will be send as a single WebSocket frame. The data from [stream]
  /// must be either `String`s, or `List<int>`s holding bytes.
  @override
  Future addStream(Stream stream);

  /// Sends a text message with the text represented by [bytes].
  ///
  /// The [bytes] should be valid UTF-8 encoded Unicode characters. If they are
  /// not, the receiving end will close the connection.
  void addUtf8Text(List<int> bytes);

  /// Closes the WebSocket connection. Set the optional [code] and [reason]
  /// arguments to send close information to the remote peer. If they are
  /// omitted, the peer will see [WebSocketStatus.noStatusReceived] code
  /// with no reason.
  @override
  Future close([int? code, String? reason]) async {}

  /// Create a new WebSocket connection. The URL supplied in [url]
  /// must use the scheme `ws` or `wss`.
  ///
  /// The [protocols] argument is specifying the subprotocols the
  /// client is willing to speak.
  ///
  /// The [headers] argument is specifying additional HTTP headers for
  /// setting up the connection. This would typically be the `Origin`
  /// header and potentially cookies. The keys of the map are the header
  /// fields and the values are either String or List<String>.
  ///
  /// If [headers] is provided, there are a number of headers
  /// which are controlled by the WebSocket connection process. These
  /// headers are:
  ///
  ///   - `connection`
  ///   - `sec-websocket-key`
  ///   - `sec-websocket-protocol`
  ///   - `sec-websocket-version`
  ///   - `upgrade`
  ///
  /// If any of these are passed in the `headers` map they will be ignored.
  ///
  /// If the `url` contains user information this will be passed as basic
  /// authentication when setting up the connection.
  static Future<WebSocket> connect(String url,
          {Iterable<String>? protocols,
          Map<String, dynamic>? headers,
          CompressionOptions compression =
              CompressionOptions.compressionDefault}) =>
      throw UnimplementedError();
}

class WebSocketException implements IOException {
  final String message;

  const WebSocketException([this.message = '']);

  @override
  String toString() => 'WebSocketException: $message';
}

/// WebSocket status codes used when closing a WebSocket connection.
abstract class WebSocketStatus {
  static const int normalClosure = 1000;
  static const int goingAway = 1001;
  static const int protocolError = 1002;
  static const int unsupportedData = 1003;
  static const int reserved1004 = 1004;
  static const int noStatusReceived = 1005;
  static const int abnormalClosure = 1006;
  static const int invalidFramePayloadData = 1007;
  static const int policyViolation = 1008;
  static const int messageTooBig = 1009;
  static const int missingMandatoryExtension = 1010;
  static const int internalServerError = 1011;
  static const int reserved1015 = 1015;

  @Deprecated('Use normalClosure instead')
  static const int NORMAL_CLOSURE = normalClosure;
  @Deprecated('Use goingAway instead')
  static const int GOING_AWAY = goingAway;
  @Deprecated('Use protocolError instead')
  static const int PROTOCOL_ERROR = protocolError;
  @Deprecated('Use unsupportedData instead')
  static const int UNSUPPORTED_DATA = unsupportedData;
  @Deprecated('Use reserved1004 instead')
  static const int RESERVED_1004 = reserved1004;
  @Deprecated('Use noStatusReceived instead')
  static const int NO_STATUS_RECEIVED = noStatusReceived;
  @Deprecated('Use abnormalClosure instead')
  static const int ABNORMAL_CLOSURE = abnormalClosure;
  @Deprecated('Use invalidFramePayloadData instead')
  static const int INVALID_FRAME_PAYLOAD_DATA = invalidFramePayloadData;
  @Deprecated('Use policyViolation instead')
  static const int POLICY_VIOLATION = policyViolation;
  @Deprecated('Use messageTooBig instead')
  static const int MESSAGE_TOO_BIG = messageTooBig;
  @Deprecated('Use missingMandatoryExtension instead')
  static const int MISSING_MANDATORY_EXTENSION = missingMandatoryExtension;
  @Deprecated('Use internalServerError instead')
  static const int INTERNAL_SERVER_ERROR = internalServerError;
  @Deprecated('Use reserved1015 instead')
  static const int RESERVED_1015 = reserved1015;
}

/// The [WebSocketTransformer] provides the ability to upgrade a
/// [HttpRequest] to a [WebSocket] connection. It supports both
/// upgrading a single [HttpRequest] and upgrading a stream of
/// [HttpRequest]s.
///
/// To upgrade a single [HttpRequest] use the static [upgrade] method.
///
///     HttpServer server;
///     server.listen((request) {
///       if (...) {
///         WebSocketTransformer.upgrade(request).then((websocket) {
///           ...
///         });
///       } else {
///         // Do normal HTTP request processing.
///       }
///     });
///
/// To transform a stream of [HttpRequest] events as it implements a
/// stream transformer that transforms a stream of HttpRequest into a
/// stream of WebSockets by upgrading each HttpRequest from the HTTP or
/// HTTPS server, to the WebSocket protocol.
///
///     server.transform(new WebSocketTransformer()).listen((webSocket) => ...);
///
/// This transformer strives to implement WebSockets as specified by RFC6455.
abstract class WebSocketTransformer
    implements StreamTransformer<HttpRequest, WebSocket> {
  /// Create a new [WebSocketTransformer].
  ///
  /// If [protocolSelector] is provided, [protocolSelector] will be called to
  /// select what protocol to use, if any were provided by the client.
  /// [protocolSelector] is should return either a [String] or a [Future]
  /// completing with a [String]. The [String] must exist in the list of
  /// protocols.
  ///
  /// If [compression] is provided, the [WebSocket] created will be configured
  /// to negotiate with the specified [CompressionOptions]. If none is specified
  /// then the [WebSocket] will be created with the default [CompressionOptions].
  factory WebSocketTransformer(
      {/*String|Future<String>*/ Function(List<String> protocols)?
          protocolSelector,
      CompressionOptions compression = CompressionOptions.compressionDefault}) {
    throw UnimplementedError();
  }

  /// Checks whether the request is a valid WebSocket upgrade request.
  static bool isUpgradeRequest(HttpRequest request) {
    throw UnimplementedError();
  }

  /// Upgrades a [HttpRequest] to a [WebSocket] connection. If the
  /// request is not a valid WebSocket upgrade request an HTTP response
  /// with status code 500 will be returned. Otherwise the returned
  /// future will complete with the [WebSocket] when the upgrade process
  /// is complete.
  ///
  /// If [protocolSelector] is provided, [protocolSelector] will be called to
  /// select what protocol to use, if any were provided by the client.
  /// [protocolSelector] is should return either a [String] or a [Future]
  /// completing with a [String]. The [String] must exist in the list of
  /// protocols.
  ///
  /// If [compression] is provided, the [WebSocket] created will be configured
  /// to negotiate with the specified [CompressionOptions]. If none is specified
  /// then the [WebSocket] will be created with the default [CompressionOptions].
  static Future<WebSocket> upgrade(HttpRequest request,
      {Function(List<String> protocols)? protocolSelector,
      CompressionOptions compression = CompressionOptions.compressionDefault}) {
    throw UnimplementedError();
  }
}
