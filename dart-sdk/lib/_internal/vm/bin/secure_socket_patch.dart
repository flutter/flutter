// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "common_patch.dart";

@patch
class SecureSocket {
  @patch
  factory SecureSocket._(RawSecureSocket rawSocket) =>
      new _SecureSocket(rawSocket);
}

@patch
class _SecureFilter {
  @patch
  factory _SecureFilter._() => new _SecureFilterImpl._();
}

@patch
@pragma("vm:entry-point")
class X509Certificate {
  @patch
  @pragma("vm:entry-point")
  factory X509Certificate._() => new _X509CertificateImpl._();
}

class _SecureSocket extends _Socket implements SecureSocket {
  _RawSecureSocket? get _raw => super._raw as _RawSecureSocket?;

  _SecureSocket(RawSecureSocket raw) : super(raw);

  void renegotiate(
      {bool useSessionCache = true,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false}) {}

  X509Certificate? get peerCertificate {
    if (_raw == null) {
      throw new StateError("peerCertificate called on destroyed SecureSocket");
    }
    return _raw!.peerCertificate;
  }

  String? get selectedProtocol {
    if (_raw == null) {
      throw new StateError("selectedProtocol called on destroyed SecureSocket");
    }
    return _raw!.selectedProtocol;
  }
}

/**
 * _SecureFilterImpl wraps a filter that encrypts and decrypts data travelling
 * over an encrypted socket.  The filter also handles the handshaking
 * and certificate verification.
 *
 * The filter exposes its input and output buffers as Dart objects that
 * are backed by an external C array of bytes, so that both Dart code and
 * native code can access the same data.
 */
@pragma("vm:entry-point")
base class _SecureFilterImpl extends NativeFieldWrapperClass1
    implements _SecureFilter {
  // Performance is improved if a full buffer of plaintext fits
  // in the encrypted buffer, when encrypted.
  // SIZE and ENCRYPTED_SIZE are referenced from C++.
  @pragma("vm:entry-point")
  static final int SIZE = 8 * 1024;
  @pragma("vm:entry-point")
  static final int ENCRYPTED_SIZE = 10 * 1024;

  _SecureFilterImpl._() {
    buffers = <_ExternalBuffer>[
      for (int i = 0; i < _RawSecureSocket.bufferCount; ++i)
        new _ExternalBuffer(
            _RawSecureSocket._isBufferEncrypted(i) ? ENCRYPTED_SIZE : SIZE),
    ];
  }

  @pragma("vm:external-name", "SecureSocket_Connect")
  external void connect(
      String hostName,
      SecurityContext context,
      bool isServer,
      bool requestClientCertificate,
      bool requireClientCertificate,
      Uint8List protocols);

  void destroy() {
    buffers = null;
    _destroy();
  }

  @pragma("vm:external-name", "SecureSocket_Destroy")
  external void _destroy();

  @pragma("vm:external-name", "SecureSocket_Handshake")
  external int _handshake(SendPort replyPort);

  @pragma("vm:external-name", "SecureSocket_MarkAsTrusted")
  external void _markAsTrusted(int certificatePtr, bool isTrusted);

  @pragma("vm:external-name", "SecureSocket_NewX509CertificateWrapper")
  external static X509Certificate _newX509CertificateWrapper(
      int certificatePtr);

  Future<bool> handshake() {
    Completer<bool> evaluatorCompleter = Completer<bool>();

    ReceivePort rpEvaluateResponse = ReceivePort();
    rpEvaluateResponse.listen((data) {
      List list = data as List;
      // incoming messages (bool isTrusted, int certificatePtr) is
      // sent by TrustEvaluator native port after system evaluates
      // the certificate chain
      if (list.length != 2) {
        throw Exception("Invalid number of arguments in evaluate response");
      }
      bool isTrusted = list[0] as bool;
      int certificatePtr = list[1] as int;
      // Make sure certificatePtr gets released.
      X509Certificate certificate = _newX509CertificateWrapper(certificatePtr);
      if (!isTrusted) {
        if (badCertificateCallback != null) {
          try {
            isTrusted = badCertificateCallback!(certificate);
          } catch (e, st) {
            evaluatorCompleter.completeError(e, st);
            rpEvaluateResponse.close();
            return;
          }
        }
      }
      _markAsTrusted(certificatePtr, isTrusted);
      evaluatorCompleter.complete(true);
      rpEvaluateResponse.close();
    });

    const int kSslErrorWantCertificateVerify = 16; // ssl.h:558
    int handshakeResult;
    try {
      handshakeResult = _handshake(rpEvaluateResponse.sendPort);
    } catch (e, st) {
      rpEvaluateResponse.close();
      rethrow;
    }
    if (handshakeResult == kSslErrorWantCertificateVerify) {
      return evaluatorCompleter.future;
    } else {
      // Response is ready, no need for evaluate response receive port
      rpEvaluateResponse.close();
      return Future<bool>.value(false);
    }
  }

  void rehandshake() => throw new UnimplementedError();

  int processBuffer(int bufferIndex) => throw new UnimplementedError();

  @pragma("vm:external-name", "SecureSocket_GetSelectedProtocol")
  external String? selectedProtocol();

  @pragma("vm:external-name", "SecureSocket_Init")
  external void init();

  @pragma("vm:external-name", "SecureSocket_PeerCertificate")
  external X509Certificate? get peerCertificate;

  @pragma("vm:external-name", "SecureSocket_RegisterBadCertificateCallback")
  external void _registerBadCertificateCallback(
      bool Function(X509Certificate) callback);

  bool Function(X509Certificate)? badCertificateCallback;

  void registerBadCertificateCallback(bool Function(X509Certificate) callback) {
    badCertificateCallback = callback;
    _registerBadCertificateCallback(callback);
  }

  @pragma("vm:external-name", "SecureSocket_RegisterHandshakeCompleteCallback")
  external void registerHandshakeCompleteCallback(
      Function handshakeCompleteHandler);

  @pragma("vm:external-name", "SecureSocket_RegisterKeyLogPort")
  external void registerKeyLogPort(SendPort port);

  // This is a security issue, as it exposes a raw pointer to Dart code.
  @pragma("vm:external-name", "SecureSocket_FilterPointer")
  external int _pointer();

  @pragma("vm:entry-point", "get")
  List<_ExternalBuffer>? buffers;
}

@patch
class SecurityContext {
  @patch
  factory SecurityContext({bool withTrustedRoots = false}) {
    return new _SecurityContext(withTrustedRoots);
  }

  @patch
  static SecurityContext get defaultContext {
    return _SecurityContext.defaultContext;
  }

  @patch
  static bool get alpnSupported => true;
}

base class _SecurityContext extends NativeFieldWrapperClass1
    implements SecurityContext {
  bool _allowLegacyUnsafeRenegotiation = false;

  _SecurityContext(bool withTrustedRoots) {
    _createNativeContext();
    if (withTrustedRoots) {
      _trustBuiltinRoots();
    }
  }

  set allowLegacyUnsafeRenegotiation(bool allow) {
    _allowLegacyUnsafeRenegotiation = allow;
    _setAllowTlsRenegotiation(allow);
  }

  bool get allowLegacyUnsafeRenegotiation => _allowLegacyUnsafeRenegotiation;

  set minimumTlsProtocolVersion(TlsProtocolVersion version) {
    _setMinimumProtocolVersion(version._version);
  }

  TlsProtocolVersion get minimumTlsProtocolVersion =>
      TlsProtocolVersion._fromProtocolVersionConstant(
          _getMinimumProtocolVersion());

  @pragma("vm:external-name", "SecurityContext_Allocate")
  external void _createNativeContext();

  static final SecurityContext defaultContext = new _SecurityContext(true);

  void usePrivateKey(String file, {String? password}) {
    List<int> bytes = (new File(file)).readAsBytesSync();
    usePrivateKeyBytes(bytes, password: password);
  }

  @pragma("vm:external-name", "SecurityContext_UsePrivateKeyBytes")
  external void usePrivateKeyBytes(List<int> keyBytes, {String? password});

  void setTrustedCertificates(String file, {String? password}) {
    List<int> bytes = (new File(file)).readAsBytesSync();
    setTrustedCertificatesBytes(bytes, password: password);
  }

  @pragma("vm:external-name", "SecurityContext_SetTrustedCertificatesBytes")
  external void setTrustedCertificatesBytes(List<int> certBytes,
      {String? password});

  void useCertificateChain(String file, {String? password}) {
    List<int> bytes = (new File(file)).readAsBytesSync();
    useCertificateChainBytes(bytes, password: password);
  }

  @pragma("vm:external-name", "SecurityContext_UseCertificateChainBytes")
  external void useCertificateChainBytes(List<int> chainBytes,
      {String? password});

  void setClientAuthorities(String file, {String? password}) {
    List<int> bytes = (new File(file)).readAsBytesSync();
    setClientAuthoritiesBytes(bytes, password: password);
  }

  @pragma("vm:external-name", "SecurityContext_SetClientAuthoritiesBytes")
  external void setClientAuthoritiesBytes(List<int> authCertBytes,
      {String? password});

  void setAlpnProtocols(List<String> protocols, bool isServer) {
    Uint8List encodedProtocols =
        SecurityContext._protocolsToLengthEncoding(protocols);
    _setAlpnProtocols(encodedProtocols, isServer);
  }

  @pragma("vm:external-name", "SecurityContext_SetAlpnProtocols")
  external void _setAlpnProtocols(Uint8List protocols, bool isServer);
  @pragma("vm:external-name", "SecurityContext_TrustBuiltinRoots")
  external void _trustBuiltinRoots();
  @pragma("vm:external-name", "SecurityContext_SetAllowTlsRenegotiation")
  external void _setAllowTlsRenegotiation(bool allow);
  @pragma("vm:external-name", "SecurityContext_SetMinimumProtocolVersion")
  external void _setMinimumProtocolVersion(int version);
  @pragma("vm:external-name", "SecurityContext_GetMinimumProtocolVersion")
  external int _getMinimumProtocolVersion();
}

/**
 * _X509CertificateImpl wraps an X509 certificate object held by the BoringSSL
 * library. It exposes the fields of the certificate object.
 */
base class _X509CertificateImpl extends NativeFieldWrapperClass1
    implements X509Certificate {
  // The native field must be set manually on a new object, in native code.
  // This is done by WrappedX509Certificate in security_context.cc.
  _X509CertificateImpl._();

  @pragma("vm:external-name", "X509_Der")
  external Uint8List get _der;
  late final Uint8List der = _der;

  @pragma("vm:external-name", "X509_Pem")
  external String get _pem;
  late final String pem = _pem;

  @pragma("vm:external-name", "X509_Sha1")
  external Uint8List get _sha1;
  late final Uint8List sha1 = _sha1;

  @pragma("vm:external-name", "X509_Subject")
  external String get subject;
  @pragma("vm:external-name", "X509_Issuer")
  external String get issuer;
  DateTime get startValidity {
    return new DateTime.fromMillisecondsSinceEpoch(_startValidity(),
        isUtc: true);
  }

  DateTime get endValidity {
    return new DateTime.fromMillisecondsSinceEpoch(_endValidity(), isUtc: true);
  }

  @pragma("vm:external-name", "X509_StartValidity")
  external int _startValidity();
  @pragma("vm:external-name", "X509_EndValidity")
  external int _endValidity();
}
