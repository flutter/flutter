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
import 'dart:typed_data';

import '../annotations.dart';
import '../io_impl_js.dart';
import 'exceptions.dart';
import 'security_context.dart';
import 'socket.dart';

/// An exception that happens in the handshake phase of establishing
/// a secure network connection, when looking up or verifying a
/// certificate.
class CertificateException extends TlsException {
  @pragma('vm:entry-point')
  const CertificateException([String message = '', OSError? osError])
      : super._('CertificateException', message, osError);
}

/// An exception that happens in the handshake phase of establishing
/// a secure network connection.
@pragma('vm:entry-point')
class HandshakeException extends TlsException {
  @pragma('vm:entry-point')
  const HandshakeException([String message = '', OSError? osError])
      : super._('HandshakeException', message, osError);
}

/// RawSecureSocket provides a secure (SSL or TLS) network connection.
/// Client connections to a server are provided by calling
/// RawSecureSocket.connect.  A secure server, created with
/// [RawSecureServerSocket], also returns RawSecureSocket objects representing
/// the server end of a secure connection.
/// The certificate provided by the server is checked
/// using the trusted certificates set in the SecurityContext object.
/// The default [SecurityContext] object contains a built-in set of trusted
/// root certificates for well-known certificate authorities.
abstract class RawSecureSocket implements RawSocket {
  /// Get the peer certificate for a connected RawSecureSocket.  If this
  /// RawSecureSocket is the server end of a secure socket connection,
  /// [peerCertificate] will return the client certificate, or null, if no
  /// client certificate was received.  If it is the client end,
  /// [peerCertificate] will return the server's certificate.
  X509Certificate? get peerCertificate;

  /// The protocol which was selected during protocol negotiation.
  ///
  /// Returns null if one of the peers does not have support for ALPN, did not
  /// specify a list of supported ALPN protocols or there was no common
  /// protocol between client and server.
  String? get selectedProtocol;

  /// Renegotiate an existing secure connection, renewing the session keys
  /// and possibly changing the connection properties.
  ///
  /// This repeats the SSL or TLS handshake, with options that allow clearing
  /// the session cache and requesting a client certificate.
  void renegotiate(
      {bool useSessionCache = true,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false});

  /// Constructs a new secure client socket and connect it to the given
  /// host on the given port. The returned [Future] is completed with the
  /// RawSecureSocket when it is connected and ready for subscription.
  ///
  /// The certificate provided by the server is checked using the trusted
  /// certificates set in the SecurityContext object If a certificate and key are
  /// set on the client, using [SecurityContext.useCertificateChain] and
  /// [SecurityContext.usePrivateKey], and the server asks for a client
  /// certificate, then that client certificate is sent to the server.
  ///
  /// [onBadCertificate] is an optional handler for unverifiable certificates.
  /// The handler receives the [X509Certificate], and can inspect it and
  /// decide (or let the user decide) whether to accept
  /// the connection or not.  The handler should return true
  /// to continue the [RawSecureSocket] connection.
  ///
  /// [supportedProtocols] is an optional list of protocols (in decreasing
  /// order of preference) to use during the ALPN protocol negotiation with the
  /// server.  Example values are "http/1.1" or "h2".  The selected protocol
  /// can be obtained via [RawSecureSocket.selectedProtocol].
  static Future<RawSecureSocket> connect(host, int port,
      {SecurityContext? context,
      bool Function(X509Certificate certificate)? onBadCertificate,
      List<String>? supportedProtocols,
      Duration? timeout}) {
    throw UnimplementedError();
  }

  /// Takes an already connected [socket] and starts client side TLS
  /// handshake to make the communication secure. When the returned
  /// future completes the [RawSecureSocket] has completed the TLS
  /// handshake. Using this function requires that the other end of the
  /// connection is prepared for TLS handshake.
  ///
  /// If the [socket] already has a subscription, pass the existing
  /// subscription in the [subscription] parameter. The [secure]
  /// operation will take over the subscription by replacing the
  /// handlers with it own secure processing. The caller must not touch
  /// this subscription anymore. Passing a paused subscription is an
  /// error.
  ///
  /// If the [host] argument is passed it will be used as the host name
  /// for the TLS handshake. If [host] is not passed the host name from
  /// the [socket] will be used. The [host] can be either a [String] or
  /// an [InternetAddress].
  ///
  /// [supportedProtocols] is an optional list of protocols (in decreasing
  /// order of preference) to use during the ALPN protocol negotiation with the
  /// server.  Example values are "http/1.1" or "h2".  The selected protocol
  /// can be obtained via [SecureSocket.selectedProtocol].
  ///
  /// Calling this function will _not_ cause a DNS host lookup. If the
  /// [host] passed is a [String] the [InternetAddress] for the
  /// resulting [SecureSocket] will have this passed in [host] as its
  /// host value and the internet address of the already connected
  /// socket as its address value.
  ///
  /// See [connect] for more information on the arguments.
  ///
  static Future<RawSecureSocket> secure(RawSocket socket,
      {StreamSubscription<RawSocketEvent>? subscription,
      host,
      SecurityContext? context,
      bool Function(X509Certificate certificate)? onBadCertificate,
      List<String>? supportedProtocols}) {
    throw UnimplementedError();
  }

  /// Takes an already connected [socket] and starts server side TLS
  /// handshake to make the communication secure. When the returned
  /// future completes the [RawSecureSocket] has completed the TLS
  /// handshake. Using this function requires that the other end of the
  /// connection is going to start the TLS handshake.
  ///
  /// If the [socket] already has a subscription, pass the existing
  /// subscription in the [subscription] parameter. The [secureServer]
  /// operation will take over the subscription by replacing the
  /// handlers with it own secure processing. The caller must not touch
  /// this subscription anymore. Passing a paused subscription is an
  /// error.
  ///
  /// If some of the data of the TLS handshake has already been read
  /// from the socket this data can be passed in the [bufferedData]
  /// parameter. This data will be processed before any other data
  /// available on the socket.
  ///
  /// See [RawSecureServerSocket.bind] for more information on the
  /// arguments.
  ///
  static Future<RawSecureSocket> secureServer(
          RawSocket socket, SecurityContext? context,
          {StreamSubscription<RawSocketEvent>? subscription,
          List<int>? bufferedData,
          bool requestClientCertificate = false,
          bool requireClientCertificate = false,
          List<String>? supportedProtocols}) =>
      throw UnimplementedError();

  /// Like [connect], but returns a [Future] that completes with a
  /// [ConnectionTask] that can be cancelled if the [RawSecureSocket] is no
  /// longer needed.
  static Future<ConnectionTask<RawSecureSocket>> startConnect(host, int port,
      {SecurityContext? context,
      bool Function(X509Certificate certificate)? onBadCertificate,
      List<String>? supportedProtocols}) {
    throw UnimplementedError();
  }
}

/// A high-level class for communicating securely over a TCP socket, using
/// TLS and SSL. The [SecureSocket] exposes both a [Stream] and an
/// [IOSink] interface, making it ideal for using together with
/// other [Stream]s.
abstract class SecureSocket implements Socket {
  factory SecureSocket._(RawSecureSocket rawSocket) =>
      throw UnimplementedError();

  /// Get the peer certificate for a connected SecureSocket.  If this
  /// SecureSocket is the server end of a secure socket connection,
  /// [peerCertificate] will return the client certificate, or null, if no
  /// client certificate was received.  If it is the client end,
  /// [peerCertificate] will return the server's certificate.
  X509Certificate? get peerCertificate;

  /// The protocol which was selected during ALPN protocol negotiation.
  ///
  /// Returns null if one of the peers does not have support for ALPN, did not
  /// specify a list of supported ALPN protocols or there was no common
  /// protocol between client and server.
  String? get selectedProtocol;

  /// Renegotiate an existing secure connection, renewing the session keys
  /// and possibly changing the connection properties.
  ///
  /// This repeats the SSL or TLS handshake, with options that allow clearing
  /// the session cache and requesting a client certificate.
  void renegotiate(
      {bool useSessionCache = true,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false});

  /// Constructs a new secure client socket and connects it to the given
  /// [host] on port [port]. The returned Future will complete with a
  /// [SecureSocket] that is connected and ready for subscription.
  ///
  /// The certificate provided by the server is checked
  /// using the trusted certificates set in the SecurityContext object.
  /// The default SecurityContext object contains a built-in set of trusted
  /// root certificates for well-known certificate authorities.
  ///
  /// [onBadCertificate] is an optional handler for unverifiable certificates.
  /// The handler receives the [X509Certificate], and can inspect it and
  /// decide (or let the user decide) whether to accept
  /// the connection or not.  The handler should return true
  /// to continue the [SecureSocket] connection.
  ///
  /// [supportedProtocols] is an optional list of protocols (in decreasing
  /// order of preference) to use during the ALPN protocol negotiation with the
  /// server.  Example values are "http/1.1" or "h2".  The selected protocol
  /// can be obtained via [SecureSocket.selectedProtocol].
  ///
  /// The argument [timeout] is used to specify the maximum allowed time to wait
  /// for a connection to be established. If [timeout] is longer than the system
  /// level timeout duration, a timeout may occur sooner than specified in
  /// [timeout]. On timeout, a [SocketException] is thrown and all ongoing
  /// connection attempts to [host] are cancelled.
  static Future<SecureSocket> connect(host, int port,
      {SecurityContext? context,
      bool Function(X509Certificate certificate)? onBadCertificate,
      List<String>? supportedProtocols,
      Duration? timeout}) {
    throw UnimplementedError();
  }

  /// Takes an already connected [socket] and starts client side TLS
  /// handshake to make the communication secure. When the returned
  /// future completes the [SecureSocket] has completed the TLS
  /// handshake. Using this function requires that the other end of the
  /// connection is prepared for TLS handshake.
  ///
  /// If the [socket] already has a subscription, this subscription
  /// will no longer receive and events. In most cases calling
  /// `pause` on this subscription before starting TLS handshake is
  /// the right thing to do.
  ///
  /// The given [socket] is closed and may not be used anymore.
  ///
  /// If the [host] argument is passed it will be used as the host name
  /// for the TLS handshake. If [host] is not passed the host name from
  /// the [socket] will be used. The [host] can be either a [String] or
  /// an [InternetAddress].
  ///
  /// [supportedProtocols] is an optional list of protocols (in decreasing
  /// order of preference) to use during the ALPN protocol negotiation with the
  /// server.  Example values are "http/1.1" or "h2".  The selected protocol
  /// can be obtained via [SecureSocket.selectedProtocol].
  ///
  /// Calling this function will _not_ cause a DNS host lookup. If the
  /// [host] passed is a [String] the [InternetAddress] for the
  /// resulting [SecureSocket] will have the passed in [host] as its
  /// host value and the internet address of the already connected
  /// socket as its address value.
  ///
  /// See [connect] for more information on the arguments.
  ///
  static Future<SecureSocket> secure(Socket socket,
      {host,
      SecurityContext? context,
      bool Function(X509Certificate certificate)? onBadCertificate,
      @Since('2.6') List<String>? supportedProtocols}) {
    throw UnimplementedError();
  }

  /// Takes an already connected [socket] and starts server side TLS
  /// handshake to make the communication secure. When the returned
  /// future completes the [SecureSocket] has completed the TLS
  /// handshake. Using this function requires that the other end of the
  /// connection is going to start the TLS handshake.
  ///
  /// If the [socket] already has a subscription, this subscription
  /// will no longer receive and events. In most cases calling
  /// [:pause:] on this subscription before starting TLS handshake is
  /// the right thing to do.
  ///
  /// If some of the data of the TLS handshake has already been read
  /// from the socket this data can be passed in the [bufferedData]
  /// parameter. This data will be processed before any other data
  /// available on the socket.
  ///
  /// See [SecureServerSocket.bind] for more information on the
  /// arguments.
  ///
  static Future<SecureSocket> secureServer(
      Socket socket, SecurityContext? context,
      {List<int>? bufferedData,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false,
      List<String>? supportedProtocols}) {
    return ((socket as dynamic /*_Socket*/)._detachRaw() as Future)
        .then<RawSecureSocket>((detachedRaw) {
      return RawSecureSocket.secureServer(detachedRaw[0] as RawSocket, context,
          subscription: detachedRaw[1] as StreamSubscription<RawSocketEvent>?,
          bufferedData: bufferedData,
          requestClientCertificate: requestClientCertificate,
          requireClientCertificate: requireClientCertificate,
          supportedProtocols: supportedProtocols);
    }).then<SecureSocket>((raw) => SecureSocket._(raw));
  }

  /// Like [connect], but returns a [Future] that completes with a
  /// [ConnectionTask] that can be cancelled if the [SecureSocket] is no
  /// longer needed.
  static Future<ConnectionTask<SecureSocket>> startConnect(host, int port,
      {SecurityContext? context,
      bool Function(X509Certificate certificate)? onBadCertificate,
      List<String>? supportedProtocols}) {
    throw UnimplementedError();
  }
}

/// A secure networking exception caused by a failure in the
///  TLS/SSL protocol.
class TlsException implements IOException {
  final String type;
  final String message;
  final OSError? osError;

  @pragma('vm:entry-point')
  const TlsException([String message = '', OSError? osError])
      : this._('TlsException', message, osError);

  const TlsException._(this.type, this.message, this.osError);

  @override
  String toString() {
    var sb = StringBuffer();
    sb.write(type);
    if (message.isNotEmpty) {
      sb.write(': $message');
      if (osError != null) {
        sb.write(' ($osError)');
      }
    } else if (osError != null) {
      sb.write(': $osError');
    }
    return sb.toString();
  }
}

/// X509Certificate represents an SSL certificate, with accessors to
/// get the fields of the certificate.
@pragma('vm:entry-point')
abstract class X509Certificate {
  @pragma('vm:entry-point')
  factory X509Certificate._() => throw UnimplementedError();

  /// The DER encoded bytes of the certificate.
  Uint8List get der;

  DateTime get endValidity;

  String get issuer;

  /// The PEM encoded String of the certificate.
  String get pem;

  /// The SHA1 hash of the certificate.
  Uint8List get sha1;

  DateTime get startValidity;

  String get subject;
}
