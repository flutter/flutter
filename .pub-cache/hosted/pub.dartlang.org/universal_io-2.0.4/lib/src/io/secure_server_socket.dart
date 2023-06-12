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

import 'dart:async';

import '../io_impl_js.dart';

/// The RawSecureServerSocket is a server socket, providing a stream of low-level
/// [RawSecureSocket]s.
///
/// See [RawSecureSocket] for more info.
abstract class RawSecureServerSocket extends Stream<RawSecureSocket> {
  bool get requestClientCertificate;
  bool get requireClientCertificate;
  List<String>? get supportedProtocols;

  /// Returns the address used by this socket.
  InternetAddress get address;

  /// Returns the port used by this socket.
  int get port;

  /// Closes the socket. The returned future completes when the socket
  /// is fully closed and is no longer bound.
  Future<RawSecureServerSocket> close();

  @override
  StreamSubscription<RawSecureSocket> listen(
      void Function(RawSecureSocket s)? onData,
      {Function? onError,
      void Function()? onDone,
      bool? cancelOnError});

  /// Returns a future for a [RawSecureServerSocket]. When the future
  /// completes the server socket is bound to the given [address] and
  /// [port] and has started listening on it.
  ///
  /// The [address] can either be a [String] or an
  /// [InternetAddress]. If [address] is a [String], [bind] will
  /// perform a [InternetAddress.lookup] and use the first value in the
  /// list. To listen on the loopback adapter, which will allow only
  /// incoming connections from the local host, use the value
  /// [InternetAddress.loopbackIPv4] or
  /// [InternetAddress.loopbackIPv6]. To allow for incoming
  /// connection from the network use either one of the values
  /// [InternetAddress.anyIPv4] or [InternetAddress.anyIPv6] to
  /// bind to all interfaces or the IP address of a specific interface.
  ///
  /// If [port] has the value [:0:] an ephemeral port will be chosen by
  /// the system. The actual port used can be retrieved using the
  /// [port] getter.
  ///
  /// The optional argument [backlog] can be used to specify the listen
  /// backlog for the underlying OS listen setup. If [backlog] has the
  /// value of [:0:] (the default) a reasonable value will be chosen by
  /// the system.
  ///
  /// Incoming client connections are promoted to secure connections,
  /// using the server certificate and key set in [context].
  ///
  /// [address] must be given as a numeric address, not a host name.
  ///
  /// To request or require that clients authenticate by providing an SSL (TLS)
  /// client certificate, set the optional parameters requestClientCertificate or
  /// requireClientCertificate to true.  Require implies request, so one doesn't
  /// need to specify both.  To check whether a client certificate was received,
  /// check SecureSocket.peerCertificate after connecting.  If no certificate
  /// was received, the result will be null.
  ///
  /// [supportedProtocols] is an optional list of protocols (in decreasing
  /// order of preference) to use during the ALPN protocol negotiation with
  /// clients.  Example values are "http/1.1" or "h2".  The selected protocol
  /// can be obtained via [RawSecureSocket.selectedProtocol].
  ///
  /// The optional argument [shared] specifies whether additional
  /// RawSecureServerSocket objects can bind to the same combination of
  /// `address`, `port` and `v6Only`.  If `shared` is `true` and more
  /// `RawSecureServerSocket`s from this isolate or other isolates are bound to
  /// the port, then the incoming connections will be distributed among all the
  /// bound `RawSecureServerSocket`s. Connections can be distributed over
  /// multiple isolates this way.
  static Future<RawSecureServerSocket> bind(
      address, int port, SecurityContext? context,
      {int backlog = 0,
      bool v6Only = false,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false,
      List<String>? supportedProtocols,
      bool shared = false}) {
    throw UnimplementedError();
  }
}

/// The [SecureServerSocket] is a server socket, providing a stream of high-level
/// [Socket]s.
///
/// See [SecureSocket] for more info.
class SecureServerSocket extends Stream<SecureSocket> {
  final RawSecureServerSocket _socket;

  SecureServerSocket._(this._socket);

  /// Returns the address used by this socket.
  InternetAddress get address => _socket.address;

  /// Returns the port used by this socket.
  int get port => _socket.port;

  /// Closes the socket. The returned future completes when the socket
  /// is fully closed and is no longer bound.
  Future<SecureServerSocket> close() => _socket.close().then((_) => this);

  @override
  StreamSubscription<SecureSocket> listen(
      void Function(SecureSocket event)? onData,
      {Function? onError,
      void Function()? onDone,
      bool? cancelOnError}) {
    throw UnimplementedError();
  }

  /// Returns a future for a [SecureServerSocket]. When the future
  /// completes the server socket is bound to the given [address] and
  /// [port] and has started listening on it.
  ///
  /// The [address] can either be a [String] or an
  /// [InternetAddress]. If [address] is a [String], [bind] will
  /// perform a [InternetAddress.lookup] and use the first value in the
  /// list. To listen on the loopback adapter, which will allow only
  /// incoming connections from the local host, use the value
  /// [InternetAddress.loopbackIPv4] or
  /// [InternetAddress.loopbackIPv6]. To allow for incoming
  /// connection from the network use either one of the values
  /// [InternetAddress.anyIPv4] or [InternetAddress.anyIPv6] to
  /// bind to all interfaces or the IP address of a specific interface.
  ///
  /// If [port] has the value [:0:] an ephemeral port will be chosen by
  /// the system. The actual port used can be retrieved using the
  /// [port] getter.
  ///
  /// The optional argument [backlog] can be used to specify the listen
  /// backlog for the underlying OS listen setup. If [backlog] has the
  /// value of [:0:] (the default) a reasonable value will be chosen by
  /// the system.
  ///
  /// Incoming client connections are promoted to secure connections, using
  /// the server certificate and key set in [context].
  ///
  /// [address] must be given as a numeric address, not a host name.
  ///
  /// To request or require that clients authenticate by providing an SSL (TLS)
  /// client certificate, set the optional parameter [requestClientCertificate]
  /// or [requireClientCertificate] to true.  Requiring a certificate implies
  /// requesting a certificate, so setting both is redundant.
  /// To check whether a client certificate was received, check
  /// SecureSocket.peerCertificate after connecting.  If no certificate
  /// was received, the result will be null.
  ///
  /// [supportedProtocols] is an optional list of protocols (in decreasing
  /// order of preference) to use during the ALPN protocol negogiation with
  /// clients.  Example values are "http/1.1" or "h2".  The selected protocol
  /// can be obtained via [SecureSocket.selectedProtocol].
  ///
  /// The optional argument [shared] specifies whether additional
  /// SecureServerSocket objects can bind to the same combination of `address`,
  /// `port` and `v6Only`.  If `shared` is `true` and more `SecureServerSocket`s
  /// from this isolate or other isolates are bound to the port, then the
  /// incoming connections will be distributed among all the bound
  /// `SecureServerSocket`s. Connections can be distributed over multiple
  /// isolates this way.
  static Future<SecureServerSocket> bind(
      address, int port, SecurityContext? context,
      {int backlog = 0,
      bool v6Only = false,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false,
      List<String>? supportedProtocols,
      bool shared = false}) {
    return RawSecureServerSocket.bind(address, port, context,
            backlog: backlog,
            v6Only: v6Only,
            requestClientCertificate: requestClientCertificate,
            requireClientCertificate: requireClientCertificate,
            supportedProtocols: supportedProtocols,
            shared: shared)
        .then((serverSocket) => SecureServerSocket._(serverSocket));
  }
}
