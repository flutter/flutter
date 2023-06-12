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

// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../io_impl_js.dart';

/// The object containing the certificates to trust when making
/// a secure client connection, and the certificate chain and
/// private key to serve from a secure server.
///
/// The [SecureSocket]  and [SecureServerSocket] classes take a SecurityContext
/// as an argument to their connect and bind methods.
///
/// Certificates and keys can be added to a SecurityContext from either PEM
/// or PKCS12 containers.
///
/// iOS note: Some methods to add, remove, and inspect certificates are not yet
/// implemented. However, the platform's built-in trusted certificates can
/// be used, by way of [SecurityContext.defaultContext].
abstract class SecurityContext {
  /// Whether the platform supports ALPN. This always returns true and will be
  /// removed in a future release.
  @deprecated
  static bool get alpnSupported => throw UnimplementedError();

  /// Secure networking classes with an optional `context` parameter
  /// use the [defaultContext] object if the parameter is omitted.
  /// This object can also be accessed, and modified, directly.
  /// Each isolate has a different [defaultContext] object.
  /// The [defaultContext] object uses a list of well-known trusted
  /// certificate authorities as its trusted roots. On Linux and Windows, this
  /// list is taken from Mozilla, who maintains it as part of Firefox. On,
  /// MacOS, iOS, and Android, this list comes from the trusted certificates
  /// stores built in to the platforms.
  static SecurityContext get defaultContext => throw UnimplementedError();

  /// Creates a new [SecurityContext].
  ///
  /// By default, the created [SecurityContext] contains no keys or certificates.
  /// These can be added by calling the methods of this class.
  ///
  /// If `withTrustedRoots` is passed as `true`, the [SecurityContext] will be
  /// seeded by the trusted root certificates provided as explained below. To
  /// obtain a [SecurityContext] containing trusted root certificates,
  /// [SecurityContext.defaultContext] is usually sufficient, and should
  /// be used instead. However, if the [SecurityContext] containing the trusted
  /// root certificates must be modified per-connection, then `withTrustedRoots`
  /// should be used.
  factory SecurityContext({bool withTrustedRoots = false}) {
    throw UnimplementedError();
  }

  /// Sets the list of application-level protocols supported by a client
  /// connection or server connection. The ALPN (application level protocol
  /// negotiation) extension to TLS allows a client to send a list of
  /// protocols in the TLS client hello message, and the server to pick
  /// one and send the selected one back in its server hello message.
  ///
  /// Separate lists of protocols can be sent for client connections and
  /// for server connections, using the same SecurityContext.  The [isServer]
  /// boolean argument specifies whether to set the list for server connections
  /// or client connections.
  void setAlpnProtocols(List<String> protocols, bool isServer);

  /// Sets the list of authority names that a [SecureServerSocket] will advertise
  /// as accepted when requesting a client certificate from a connecting
  /// client.
  ///
  /// [file] is a PEM or PKCS12 file containing the accepted signing
  /// authority certificates - the authority names are extracted from the
  /// certificates. For PKCS12 files, [password] is the password for the file.
  /// For PEM files, [password] is ignored. Assuming it is well-formatted, all
  /// other contents of [file] are ignored.
  ///
  /// NB: This function calls [File.readAsBytesSync], and will block on file IO.
  /// Prefer using [setClientAuthoritiesBytes].
  ///
  /// iOS note: This call is not supported.
  void setClientAuthorities(String file, {String? password});

  /// Sets the list of authority names that a [SecureServerSocket] will advertise
  /// as accepted, when requesting a client certificate from a connecting
  /// client.
  ///
  /// Like [setClientAuthorities] but takes the contents of the file.
  void setClientAuthoritiesBytes(List<int> authCertBytes, {String? password});

  /// Sets the set of trusted X509 certificates used by [SecureSocket]
  /// client connections, when connecting to a secure server.
  ///
  /// [file] is the path to a PEM or PKCS12 file containing X509 certificates,
  /// usually root certificates from certificate authorities. For PKCS12 files,
  /// [password] is the password for the file. For PEM files, [password] is
  /// ignored. Assuming it is well-formatted, all other contents of [file] are
  /// ignored.
  ///
  /// NB: This function calls [File.readAsBytesSync], and will block on file IO.
  /// Prefer using [setTrustedCertificatesBytes].
  ///
  /// iOS note: On iOS, this call takes only the bytes for a single DER
  /// encoded X509 certificate. It may be called multiple times to add
  /// multiple trusted certificates to the context. A DER encoded certificate
  /// can be obtained from a PEM encoded certificate by using the openssl tool:
  ///
  ///   $ openssl x509 -outform der -in cert.pem -out cert.der
  void setTrustedCertificates(String file, {String? password});

  /// Sets the set of trusted X509 certificates used by [SecureSocket]
  /// client connections, when connecting to a secure server.
  ///
  /// Like [setTrustedCertificates] but takes the contents of the file.
  void setTrustedCertificatesBytes(List<int> certBytes, {String? password});

  /// Sets the chain of X509 certificates served by [SecureServerSocket]
  /// when making secure connections, including the server certificate.
  ///
  /// [file] is a PEM or PKCS12 file containing X509 certificates, starting with
  /// the root authority and intermediate authorities forming the signed
  /// chain to the server certificate, and ending with the server certificate.
  /// The private key for the server certificate is set by [usePrivateKey]. For
  /// PKCS12 files, [password] is the password for the file. For PEM files,
  /// [password] is ignored. Assuming it is well-formatted, all
  /// other contents of [file] are ignored.
  ///
  /// NB: This function calls [File.readAsBytesSync], and will block on file IO.
  /// Prefer using [useCertificateChainBytes].
  ///
  /// iOS note: As noted above, [usePrivateKey] does the job of both
  /// that call and this one. On iOS, this call is a no-op.
  void useCertificateChain(String file, {String? password});

  /// Sets the chain of X509 certificates served by [SecureServerSocket]
  /// when making secure connections, including the server certificate.
  ///
  /// Like [useCertificateChain] but takes the contents of the file.
  void useCertificateChainBytes(List<int> chainBytes, {String? password});

  /// Sets the private key for a server certificate or client certificate.
  ///
  /// A secure connection using this SecurityContext will use this key with
  /// the server or client certificate to sign and decrypt messages.
  /// [file] is the path to a PEM or PKCS12 file containing an encrypted
  /// private key, encrypted with [password]. Assuming it is well-formatted, all
  /// other contents of [file] are ignored. An unencrypted file can be used,
  /// but this is not usual.
  ///
  /// NB: This function calls [File.readAsBytesSync], and will block on file IO.
  /// Prefer using [usePrivateKeyBytes].
  ///
  /// iOS note: Only PKCS12 data is supported. It should contain both the private
  /// key and the certificate chain. On iOS one call to [usePrivateKey] with this
  /// data is used instead of two calls to [useCertificateChain] and
  /// [usePrivateKey].
  void usePrivateKey(String file, {String? password});

  /// Sets the private key for a server certificate or client certificate.
  ///
  /// Like [usePrivateKey], but takes the contents of the file as a list
  /// of bytes.
  void usePrivateKeyBytes(List<int> keyBytes, {String? password});
}
