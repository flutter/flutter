// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "common_patch.dart";

@patch
class RawServerSocket {
  @patch
  static Future<RawServerSocket> bind(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) {
    return _RawServerSocket.bind(address, port, backlog, v6Only, shared);
  }
}

@patch
class RawSocket {
  @patch
  static Future<RawSocket> connect(dynamic host, int port,
      {dynamic sourceAddress, int sourcePort = 0, Duration? timeout}) {
    return _RawSocket.connect(host, port, sourceAddress, sourcePort, timeout);
  }

  @patch
  static Future<ConnectionTask<RawSocket>> startConnect(dynamic host, int port,
      {dynamic sourceAddress, int sourcePort = 0}) {
    return _RawSocket.startConnect(host, port, sourceAddress, sourcePort);
  }
}

@patch
class RawSocketOption {
  static final List<int?> _optionsCache =
      List<int?>.filled(_RawSocketOptions.values.length, null);

  @patch
  static int _getOptionValue(int key) {
    if (key > _RawSocketOptions.values.length) {
      throw ArgumentError.value(key, 'key');
    }
    return _optionsCache[key] ??= _getNativeOptionValue(key);
  }

  @pragma("vm:external-name", "RawSocketOption_GetOptionValue")
  external static int _getNativeOptionValue(int key);
}

@patch
class InternetAddress {
  @patch
  static InternetAddress get loopbackIPv4 {
    return _InternetAddress.loopbackIPv4;
  }

  @patch
  static InternetAddress get loopbackIPv6 {
    return _InternetAddress.loopbackIPv6;
  }

  @patch
  static InternetAddress get anyIPv4 {
    return _InternetAddress.anyIPv4;
  }

  @patch
  static InternetAddress get anyIPv6 {
    return _InternetAddress.anyIPv6;
  }

  @patch
  factory InternetAddress(String address, {InternetAddressType? type}) {
    return _InternetAddress.fromString(address, type: type);
  }

  @patch
  factory InternetAddress.fromRawAddress(Uint8List rawAddress,
      {InternetAddressType? type}) {
    return _InternetAddress.fromRawAddress(rawAddress, type: type);
  }

  @patch
  static Future<List<InternetAddress>> lookup(String host,
      {InternetAddressType type = InternetAddressType.any}) {
    return _NativeSocket.lookup(host, type: type);
  }

  @patch
  static InternetAddress _cloneWithNewHost(
      InternetAddress address, String host) {
    return (address as _InternetAddress)._cloneWithNewHost(host);
  }

  @patch
  static InternetAddress? tryParse(String address) {
    return _InternetAddress.tryParse(address);
  }
}

@patch
class NetworkInterface {
  @patch
  static bool get listSupported => true;

  @patch
  static Future<List<NetworkInterface>> list(
      {bool includeLoopback = false,
      bool includeLinkLocal = false,
      InternetAddressType type = InternetAddressType.any}) {
    return _NativeSocket.listInterfaces(
        includeLoopback: includeLoopback,
        includeLinkLocal: includeLinkLocal,
        type: type);
  }
}

void _throwOnBadPort(int port) {
  // TODO(40614): Remove once non-nullability is sound.
  ArgumentError.checkNotNull(port, "port");
  if ((port < 0) || (port > 0xFFFF)) {
    throw new ArgumentError("Invalid port $port");
  }
}

void _throwOnBadTtl(int ttl) {
  // TODO(40614): Remove once non-nullability is sound.
  ArgumentError.checkNotNull(ttl, "ttl");
  if (ttl < 1 || ttl > 255) {
    throw new ArgumentError('Invalid ttl $ttl');
  }
}

class _InternetAddress implements InternetAddress {
  static const int _addressLoopbackIPv4 = 0;
  static const int _addressLoopbackIPv6 = 1;
  static const int _addressAnyIPv4 = 2;
  static const int _addressAnyIPv6 = 3;
  static const int _IPv4AddrLength = 4;
  static const int _IPv6AddrLength = 16;

  static _InternetAddress loopbackIPv4 =
      _InternetAddress.fixed(_addressLoopbackIPv4);
  static _InternetAddress loopbackIPv6 =
      _InternetAddress.fixed(_addressLoopbackIPv6);
  static _InternetAddress anyIPv4 = _InternetAddress.fixed(_addressAnyIPv4);
  static _InternetAddress anyIPv6 = _InternetAddress.fixed(_addressAnyIPv6);

  final String address;
  final String? _host;
  final Uint8List _in_addr;
  final int _scope_id;
  final InternetAddressType type;

  String get host => _host ?? address;

  Uint8List get rawAddress => new Uint8List.fromList(_in_addr);

  bool get isLoopback {
    switch (type) {
      case InternetAddressType.IPv4:
        return _in_addr[0] == 127;

      case InternetAddressType.IPv6:
        for (int i = 0; i < _IPv6AddrLength - 1; i++) {
          if (_in_addr[i] != 0) return false;
        }
        return _in_addr[_IPv6AddrLength - 1] == 1;

      case InternetAddressType.unix:
        return false;
    }
    throw new UnsupportedError("Unexpected address type $type");
  }

  bool get isLinkLocal {
    switch (type) {
      case InternetAddressType.IPv4:
        // Checking for 169.254.0.0/16.
        return _in_addr[0] == 169 && _in_addr[1] == 254;

      case InternetAddressType.IPv6:
        // Checking for fe80::/10.
        return _in_addr[0] == 0xFE && (_in_addr[1] & 0xB0) == 0x80;

      case InternetAddressType.unix:
        return false;
    }
    throw new UnsupportedError("Unexpected address type $type");
  }

  bool get isMulticast {
    switch (type) {
      case InternetAddressType.IPv4:
        // Checking for 224.0.0.0 through 239.255.255.255.
        return _in_addr[0] >= 224 && _in_addr[0] < 240;

      case InternetAddressType.IPv6:
        // Checking for ff00::/8.
        return _in_addr[0] == 0xFF;

      case InternetAddressType.unix:
        return false;
    }
    throw new UnsupportedError("Unexpected address type $type");
  }

  Future<InternetAddress> reverse() {
    if (type == InternetAddressType.unix) {
      return Future.value(this);
    }
    return _NativeSocket.reverseLookup(this);
  }

  _InternetAddress(this.type, this.address, this._host, this._in_addr,
      [this._scope_id = 0]);

  static Object _parseAddressString(String address,
      {InternetAddressType? type}) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(address, 'address');
    if (type == InternetAddressType.unix) {
      var rawAddress = FileSystemEntity._toUtf8Array(address);
      return _InternetAddress(
          InternetAddressType.unix, address, null, rawAddress);
    } else {
      int index = address.indexOf('%');
      String originalAddress = address;
      String? scopeID;
      if (index > 0) {
        scopeID = address.substring(index, address.length);
        address = address.substring(0, index);
      }
      var inAddr = _parse(address);
      if (inAddr == null) {
        return ArgumentError('Invalid internet address $address');
      }
      InternetAddressType type = inAddr.length == _IPv4AddrLength
          ? InternetAddressType.IPv4
          : InternetAddressType.IPv6;
      if (scopeID != null && scopeID.length > 0) {
        if (type != InternetAddressType.IPv6) {
          return ArgumentError.value(
              address, 'address', 'IPv4 addresses cannot have a scope ID');
        }

        final scopeID = _parseScopedLinkLocalAddress(originalAddress);

        if (scopeID is int) {
          return _InternetAddress(
              InternetAddressType.IPv6, originalAddress, null, inAddr, scopeID);
        } else {
          return ArgumentError.value(
              address, 'address', 'Invalid IPv6 address with scope ID');
        }
      }
      return _InternetAddress(type, originalAddress, null, inAddr, 0);
    }
  }

  factory _InternetAddress.fromString(String address,
      {InternetAddressType? type}) {
    final parsedAddress = _parseAddressString(address, type: type);
    if (parsedAddress is _InternetAddress) {
      return parsedAddress;
    } else {
      assert(parsedAddress is ArgumentError);
      throw parsedAddress;
    }
  }

  static _InternetAddress? tryParse(String address) {
    checkNotNullable(address, "address");
    final parsedAddress = _parseAddressString(address);
    if (parsedAddress is _InternetAddress) {
      return parsedAddress;
    } else {
      assert(parsedAddress is ArgumentError);
      return null;
    }
  }

  factory _InternetAddress.fromRawAddress(Uint8List rawAddress,
      {InternetAddressType? type}) {
    if (type == InternetAddressType.unix) {
      ArgumentError.checkNotNull(rawAddress, 'rawAddress');
      var rawPath = FileSystemEntity._toNullTerminatedUtf8Array(rawAddress);
      var address = FileSystemEntity._toStringFromUtf8Array(rawAddress);
      return _InternetAddress(InternetAddressType.unix, address, null, rawPath);
    } else {
      int type = -1;
      if (rawAddress.length == _IPv4AddrLength) {
        type = 0;
      } else {
        if (rawAddress.length != _IPv6AddrLength) {
          throw ArgumentError("Invalid internet address ${rawAddress}");
        }
        type = 1;
      }
      var address = _rawAddrToString(rawAddress);
      return _InternetAddress(
          InternetAddressType._from(type), address, null, rawAddress);
    }
  }

  factory _InternetAddress.fixed(int id) {
    switch (id) {
      case _addressLoopbackIPv4:
        var in_addr = Uint8List(_IPv4AddrLength);
        in_addr[0] = 127;
        in_addr[_IPv4AddrLength - 1] = 1;
        return _InternetAddress(
            InternetAddressType.IPv4, "127.0.0.1", null, in_addr);
      case _addressLoopbackIPv6:
        var in_addr = Uint8List(_IPv6AddrLength);
        in_addr[_IPv6AddrLength - 1] = 1;
        return _InternetAddress(InternetAddressType.IPv6, "::1", null, in_addr);
      case _addressAnyIPv4:
        var in_addr = Uint8List(_IPv4AddrLength);
        return _InternetAddress(
            InternetAddressType.IPv4, "0.0.0.0", "0.0.0.0", in_addr);
      case _addressAnyIPv6:
        var in_addr = Uint8List(_IPv6AddrLength);
        return _InternetAddress(InternetAddressType.IPv6, "::", "::", in_addr);
      default:
        assert(false);
        throw ArgumentError();
    }
  }

  // Create a clone of this _InternetAddress replacing the host.
  _InternetAddress _cloneWithNewHost(String host) {
    return _InternetAddress(
        type, address, host, Uint8List.fromList(_in_addr), _scope_id);
  }

  bool operator ==(other) {
    if (!(other is _InternetAddress)) return false;
    if (other.type != type) return false;
    if (type == InternetAddressType.unix) {
      return address == other.address;
    }
    bool equals = true;
    for (int i = 0; i < _in_addr.length && equals; i++) {
      equals = other._in_addr[i] == _in_addr[i];
    }
    return equals;
  }

  int get hashCode {
    if (type == InternetAddressType.unix) {
      return address.hashCode;
    }
    int result = 1;
    for (int i = 0; i < _in_addr.length; i++) {
      result = (result * 31 + _in_addr[i]) & 0x3FFFFFFF;
    }
    return result;
  }

  String toString() {
    return "InternetAddress('$address', ${type.name})";
  }

  @pragma("vm:external-name", "InternetAddress_RawAddrToString")
  external static String _rawAddrToString(Uint8List address);
  @pragma("vm:external-name", "InternetAddress_ParseScopedLinkLocalAddress")
  external static dynamic /* int | OSError */ _parseScopedLinkLocalAddress(
      String address);
  @pragma("vm:external-name", "InternetAddress_Parse")
  external static Uint8List? _parse(String address);
}

class _NetworkInterface implements NetworkInterface {
  final String name;
  final int index;
  final List<InternetAddress> addresses = [];

  _NetworkInterface(this.name, this.index);

  String toString() {
    return "NetworkInterface('$name', $addresses)";
  }
}

// The NativeFieldWrapperClass1 cannot be used with a mixin, due to missing
// implicit constructor.
base class _NativeSocketNativeWrapper extends NativeFieldWrapperClass1 {}

/// Returns error code that corresponds to EINPROGRESS OS error.
@pragma("vm:external-name", "OSError_inProgressErrorCode")
external int get _inProgressErrorCode;

// The _NativeSocket class encapsulates an OS socket.
base class _NativeSocket extends _NativeSocketNativeWrapper
    with _ServiceObject {
  // Bit flags used when communicating between the eventhandler and
  // dart code. The EVENT flags are used to indicate events of
  // interest when sending a message from dart code to the
  // eventhandler. When receiving a message from the eventhandler the
  // EVENT flags indicate the events that actually happened. The
  // COMMAND flags are used to send commands from dart to the
  // eventhandler. COMMAND flags are never received from the
  // eventhandler. Additional flags are used to communicate other
  // information.
  static const int readEvent = 0;
  static const int writeEvent = 1;
  static const int errorEvent = 2;
  static const int closedEvent = 3;
  static const int destroyedEvent = 4;
  static const int firstEvent = readEvent;
  static const int lastEvent = destroyedEvent;
  static const int eventCount = lastEvent - firstEvent + 1;

  static const int closeCommand = 8;
  static const int shutdownReadCommand = 9;
  static const int shutdownWriteCommand = 10;
  // The lower bits of returnTokenCommand messages contains the number
  // of tokens returned.
  static const int returnTokenCommand = 11;
  static const int setEventMaskCommand = 12;
  static const int firstCommand = closeCommand;
  static const int lastCommand = setEventMaskCommand;

  // Type flag send to the eventhandler providing additional
  // information on the type of the file descriptor.
  static const int listeningSocket = 16;
  static const int pipeSocket = 17;
  static const int typeNormalSocket = 0;
  static const int typeListeningSocket = 1 << listeningSocket;
  static const int typePipe = 1 << pipeSocket;
  static const int typeTypeMask = typeListeningSocket | pipeSocket;

  // Protocol flags.
  // Keep in sync with SocketType enum in socket.h.
  static const int tcpSocket = 18;
  static const int udpSocket = 19;
  static const int internalSocket = 20;
  static const int internalSignalSocket = 21;
  static const int typeTcpSocket = 1 << tcpSocket;
  static const int typeUdpSocket = 1 << udpSocket;
  static const int typeInternalSocket = 1 << internalSocket;
  static const int typeInternalSignalSocket = 1 << internalSignalSocket;
  static const int typeProtocolMask = typeTcpSocket |
      typeUdpSocket |
      typeInternalSocket |
      typeInternalSignalSocket;

  // Native port messages.
  static const hostNameLookupMessage = 0;
  static const listInterfacesMessage = 1;
  static const reverseLookupMessage = 2;

  // Protocol flags.
  static const int protocolIPv4 = 1 << 0;
  static const int protocolIPv6 = 1 << 1;

  static const int normalTokenBatchSize = 8;
  static const int listeningTokenBatchSize = 2;

  static const Duration _retryDuration = const Duration(milliseconds: 250);
  static const Duration _retryDurationLoopback =
      const Duration(milliseconds: 25);

  // Socket close state
  bool isClosed = false;
  bool isClosing = false;
  bool isClosedRead = false;
  bool closedReadEventSent = false;
  bool isClosedWrite = false;
  Completer closeCompleter = new Completer.sync();

  // Handlers and receive port for socket events from the event handler.
  void Function()? readEventHandler;
  void Function()? writeEventHandler;
  void Function(Object e, StackTrace? st)? errorEventHandler;
  void Function()? closedEventHandler;
  void Function()? destroyedEventHandler;

  RawReceivePort? eventPort;
  bool flagsSent = false;

  // The type flags for this socket.
  final int typeFlags;

  // Holds the port of the socket, 0 if not known.
  int localPort = 0;

  // Holds the address used to connect or bind the socket.
  late InternetAddress localAddress;

  // The size of data that is ready to be read, for TCP sockets.
  // This might be out-of-date when Read is called.
  // The number of pending connections, for Listening sockets.
  int available = 0;

  // Only used for UDP sockets.
  bool _availableDatagram = false;

  // The number of incoming connections for Listening socket.
  int connections = 0;

  // The count of received event from eventhandler.
  int tokens = 0;

  bool sendReadEvents = false;
  bool readEventIssued = false;

  bool sendWriteEvents = false;
  bool writeEventIssued = false;
  bool writeAvailable = false;

  // The owner object is the object that the Socket is being used by, e.g.
  // a HttpServer, a WebSocket connection, a process pipe, etc.
  Object? owner;

  static Future<List<InternetAddress>> lookup(String host,
      {InternetAddressType type = InternetAddressType.any}) {
    return _IOService._dispatch(_IOService.socketLookup, [host, type._value])
        .then((response) {
      if (isErrorResponse(response)) {
        throw createError(response, "Failed host lookup: '$host'");
      }
      return [
        for (List<Object?> result in (response as List).skip(1))
          _InternetAddress(
              InternetAddressType._from(result[0] as int),
              result[1] as String,
              host,
              result[2] as Uint8List,
              result[3] as int)
      ];
    });
  }

  static Future<InternetAddress> reverseLookup(InternetAddress addr) {
    return _IOService._dispatch(_IOService.socketReverseLookup,
        [(addr as _InternetAddress)._in_addr]).then((response) {
      if (isErrorResponse(response)) {
        throw createError(response, "Failed reverse host lookup", addr);
      } else {
        return addr._cloneWithNewHost(response as String);
      }
    });
  }

  static Future<List<NetworkInterface>> listInterfaces(
      {bool includeLoopback = false,
      bool includeLinkLocal = false,
      InternetAddressType type = InternetAddressType.any}) {
    return _IOService._dispatch(_IOService.socketListInterfaces, [type._value])
        .then((response) {
      if (isErrorResponse(response)) {
        throw createError(response, "Failed listing interfaces");
      } else {
        var map = (response as List)
            .skip(1)
            .fold(new Map<String, NetworkInterface>(), (map, result) {
          List<Object?> resultList = result as List<Object?>;
          var type = InternetAddressType._from(resultList[0] as int);
          var name = resultList[3] as String;
          var index = resultList[4] as int;
          var address = _InternetAddress(
              type, resultList[1] as String, "", resultList[2] as Uint8List);
          if (!includeLinkLocal && address.isLinkLocal) return map;
          if (!includeLoopback && address.isLoopback) return map;
          map.putIfAbsent(name, () => new _NetworkInterface(name, index));
          (map[name] as _NetworkInterface).addresses.add(address);
          return map;
        });
        return map.values.toList();
      }
    });
  }

  static String escapeLinkLocalAddress(String host) {
    // if the host contains escape, host is an IPv6 address with scope ID.
    // Remove '25' before feeding into native calls.
    int index = host.indexOf('%');
    if (index >= 0) {
      if (!checkLinkLocalAddress(host)) {
        // The only well defined usage is link-local address. Checks Section 4 of https://tools.ietf.org/html/rfc6874.
        // If it is not a valid link-local address and contains escape character, throw an exception.
        throw new FormatException(
            '${host} is not a valid link-local address but contains %. Scope id should be used as part of link-local address.',
            host,
            index);
      }
      if (host.startsWith("25", index + 1)) {
        // Remove '25' after '%' if present
        host = host.replaceRange(index + 1, index + 3, '');
      }
    }
    return host;
  }

  static bool checkLinkLocalAddress(String host) {
    // The shortest possible link-local address is [fe80::1]
    if (host.length < 7) return false;
    var char = host[2];
    return host.startsWith('fe') &&
        (char == '8' || char == '9' || char == 'a' || char == 'b');
  }

  /// Explicitly makes two separate OS lookup requests: first for IPv4 then,
  /// after a short delay, for IPv6.
  ///
  /// This avoids making a single OS lookup request that internally does both
  /// IPv4 and IPv6 lookups together, which will be as slow as the slowest
  /// lookup. Some broken DNS servers do not support IPv6 AAAA records and
  /// will cause the IPv6 lookup to timeout.
  ///
  /// The IPv4 lookup is done first because, in practice, IPv4 traffic is
  /// routed more reliably.
  ///
  /// See https://dartbug.com/50868.
  static Stream<List<InternetAddress>> staggeredLookup(
      String host, _InternetAddress? source) {
    final controller = StreamController<List<InternetAddress>>(sync: true);

    controller.onListen = () {
      // Completed when there are no further addresses, or when the returned
      // stream is canceled,
      // The latter signals that no further addresses are needed.
      // When both completers are completed, one way or another, the stream is
      // closed.
      final ipv4Completer = Completer<void>();
      final ipv6Completer = Completer<void>();
      // Only report an error if no address lookups were sucessful.
      var anySuccess = false;

      void lookupAddresses(
          InternetAddressType type, Completer<void> done) async {
        try {
          final addresses = await lookup(host, type: type);
          anySuccess = true;
          if (done.isCompleted) {
            // By the time lookup is done, [connectNext] might have
            // been able to connect to one of the resolved addresses.
            return;
          }
          controller.add(addresses);
          done.complete();
        } catch (e, st) {
          if (done.isCompleted) {
            // By the time lookup is done, [connectNext] might have
            // been able to connect to one of the resolved addresses.
            return;
          }
          done.completeError(e, st);
        }
      }

      const concurrentLookupDelay = Duration(milliseconds: 10);
      Timer? ipv6LookupDelay;

      lookupAddresses(InternetAddressType.IPv4, ipv4Completer);
      if (source != null && source.type == InternetAddressType.IPv4) {
        // Binding to an IPv4 address and connecting to an IPv6 address will
        // never work.
        ipv6Completer.complete();
      } else {
        // Introduce a delay before IPv6 lookup in order to favor IPv4.
        ipv6LookupDelay = Timer(concurrentLookupDelay,
            () => lookupAddresses(InternetAddressType.IPv6, ipv6Completer));
      }

      Future.wait([ipv4Completer.future, ipv6Completer.future])
          .then((_) => controller.close(), onError: (e, st) {
        if (!anySuccess) {
          controller.addError(e, st);
        }
        controller.close();
      });

      controller.onCancel = () {
        // This is invoked when [connectNext] managed to connect to one of the
        // looked-up addresses at which point we want to stop looking up
        // the addresses.
        if (!ipv4Completer.isCompleted) ipv4Completer.complete();
        if (!ipv6Completer.isCompleted) ipv6Completer.complete();
        ipv6LookupDelay?.cancel();
      };
    };
    return controller.stream;
  }

  static Future<ConnectionTask<_NativeSocket>> startConnect(
      dynamic host, int port, dynamic sourceAddress, int sourcePort) {
    // Looks up [sourceAddress] to one or more IP addresses,
    // then tries connecting to each one until a connection succeeds.
    // Attempts are staggered by a minimum delay, so a new
    // attempt isn't made until either a previous attempt has *failed*,
    // or the delay has passed.
    // This ensures that at most *n* uncompleted connections can be
    // active after *n* × *delay* time has passed.
    if (host is String) {
      host = escapeLinkLocalAddress(host);
    }
    _throwOnBadPort(port);
    _throwOnBadPort(sourcePort);
    _InternetAddress? source;
    if (sourceAddress != null) {
      if (sourceAddress is _InternetAddress) {
        // A host of type [String] is interpreted to be a an internet host
        // (or numeric IP e.g. '127.0.0.1'), which is never reachable using
        // a Unix Domain Socket.
        if (host is String && sourceAddress.type == InternetAddressType.unix) {
          // ArgumentError would be better but changing it would not be
          // backwards-compatible.
          throw SocketException(
              "Cannot connect to an internet host using a unix domain socket");
        }
        source = sourceAddress;
      } else if (sourceAddress is String) {
        source = new _InternetAddress.fromString(sourceAddress);
      } else {
        throw ArgumentError.value(sourceAddress, "sourceAddress",
            "Must be a string or native InternetAddress");
      }
    }

    final stackTrace = StackTrace.current;

    return new Future.value(host).then<ConnectionTask<_NativeSocket>>((host) {
      if (host is String) {
        // Attempt to interpret the host as a numeric address
        // (e.g. "127.0.0.1"). This will prevent [InternetAddress.lookup] from
        // generating an unnecessary address in a different address family e.g.
        // `InternetAddress.lookup('127.0.0.1', InternetAddressType.IPv6)`
        // may return `InternetAddress('::ffff:127.0.0.1').
        host = _InternetAddress.tryParse(host) ?? host;
      }
      if (host is _InternetAddress) {
        return tryConnectToResolvedAddresses(host, port, source, sourcePort,
            Stream.value(<_InternetAddress>[host]), stackTrace);
      }
      final hostname = host as String;

      final Stream<List<InternetAddress>> addresses =
          staggeredLookup(hostname, source);
      return tryConnectToResolvedAddresses(
          host, port, source, sourcePort, addresses, stackTrace);
    });
  }

  static ConnectionTask<_NativeSocket> tryConnectToResolvedAddresses(
      dynamic host,
      int port,
      _InternetAddress? source,
      int sourcePort,
      Stream<List<InternetAddress>> addresses,
      StackTrace callerStackTrace) {
    // Completer for result.
    final result = new Completer<_NativeSocket>();
    // Error, set if an error occurs.
    // Keeps first error if multiple errors occur.
    var error = null;
    // Contains all sockets which haven't received an initial
    // write or error event.
    final connecting = <_NativeSocket>{};
    // Timer counting down from the last connection attempt.
    // Reset when a new connection is attempted,
    // which happens either when a previous timer runs out,
    // or when a previous connection attempt fails.
    Timer? timer;
    // Addresses arrived from lookup stream, but haven't been tried to connect
    // to yet due to Timer-based throttling.
    final pendingLookedUp = Queue<InternetAddress>();

    // When deciding how to handle errors we need to know whether more
    // addresses potentially are coming from the lookup stream.
    bool isLookedUpStreamClosed = false;
    late StreamSubscription<List<InternetAddress>> addressesSubscription;

    Object? createConnection(InternetAddress address, _InternetAddress? source,
        _NativeSocket socket) {
      Object? connectionResult;
      if (address.type == InternetAddressType.unix) {
        if (source == null) {
          connectionResult = socket.nativeCreateUnixDomainConnect(
              address.address, _Namespace._namespace);
        } else {
          if (source.type != InternetAddressType.unix) {
            return SocketException(
                // Use the same error message as used on Linux for better
                // searchability...
                "Address family not supported by protocol family, "
                // ...and then add some details.
                "sourceAddress.type must be ${InternetAddressType.unix} but was "
                "${source.type}", address: address);
          }
          connectionResult = socket.nativeCreateUnixDomainBindConnect(
              address.address, source.address, _Namespace._namespace);
        }
        assert(connectionResult == true ||
            connectionResult is Error ||
            connectionResult is OSError);
      } else {
        final address_ = address as _InternetAddress;
        if (source == null && sourcePort == 0) {
          connectionResult = socket.nativeCreateConnect(
              address_._in_addr, port, address_._scope_id);
        } else {
          // allow specified port without address
          if (source == null) {
            source = address_.type == InternetAddressType.IPv4
                ? _InternetAddress.anyIPv4
                : _InternetAddress.anyIPv6;
          }
          if (source.type != InternetAddressType.IPv4 &&
              source.type != InternetAddressType.IPv6) {
            return SocketException(
                // Use the same error message as used on Linux for better
                // searchability...
                "Address family not supported by protocol family, "
                // ...and then add some details.
                "sourceAddress.type must be ${InternetAddressType.IPv4} or "
                "${InternetAddressType.IPv6} but was ${source.type}",
                address: address);
          }
          connectionResult = socket.nativeCreateBindConnect(address_._in_addr,
              port, source._in_addr, sourcePort, address_._scope_id);
        }
        assert(connectionResult == true || connectionResult is OSError);
      }
      return connectionResult;
    }

    createConnectionError(Object? connectionResult, InternetAddress address,
        int port, _NativeSocket socket) {
      if (connectionResult is OSError) {
        final errorCode = connectionResult.errorCode;
        if (source != null &&
            errorCode != null &&
            socket.isBindError(errorCode)) {
          return createError(connectionResult, "Bind failed", source);
        } else {
          return createError(
              connectionResult, "Connection failed", address, port);
        }
      } else if (connectionResult is SocketException) {
        return connectionResult;
      } else if (connectionResult is Error) {
        return connectionResult;
      }
      return createError(null, "Connection failed", address);
    }

    // Invoked either directly or via throttling Timer callback when we
    // are ready to verify that we can connect to resolved address.
    connectNext() {
      timer?.cancel();
      if (isLookedUpStreamClosed &&
          connecting.isEmpty &&
          pendingLookedUp.isEmpty) {
        assert(error != null);
        if (!result.isCompleted) {
          // Might be already completed via onCancel
          result.completeError(error, callerStackTrace);
        }
        return;
      }
      if (pendingLookedUp.isEmpty) {
        assert(!isLookedUpStreamClosed || connecting.isNotEmpty);
        return;
      }
      final address = pendingLookedUp.removeFirst();
      final socket = new _NativeSocket.normal(address);
      // Will contain values of various types representing the result
      // of trying to create a connection.
      // A value of `true` means success, everything else means failure.
      final Object? connectionResult =
          createConnection(address, source, socket);
      if (connectionResult != true) {
        // connectionResult was not a success.
        error = createConnectionError(connectionResult, address, port, socket);
        connectNext(); // Try again after failure to connect.
        return;
      }
      // Query the local port for error messages.
      try {
        socket.port;
      } catch (e) {
        if (e is OSError && e.errorCode == _inProgressErrorCode) {
          // Ignore the error, proceed with waiting for a socket to become open.
          // In non-blocking mode connect might not be established away, socket
          // have to be waited for.
          // EINPROGRESS error is ignored during |connect| call in native code,
          // it has be ignored here during |port| query here.
        } else {
          error ??= createError(e, "Connection failed", address, port);
          connectNext(); // Try again after failure to connect.
          return;
        }
      }

      // Try again if no response (failure or success) within a duration.
      // If this occurs, the socket is still trying to connect, and might
      // succeed or fail later.
      final duration =
          address.isLoopback ? _retryDurationLoopback : _retryDuration;
      timer = new Timer(duration, connectNext);
      connecting.add(socket);
      // Setup handlers for receiving the first write event which
      // indicate that the socket is fully connected.
      socket.setHandlers(write: () {
        // First remote response on connection.
        // If error, drop the socket and go to the next address.
        // If success, complete with the socket
        // and stop all other open connection attempts.
        connecting.remove(socket);
        // From 'man 2 connect':
        // After select(2) indicates writability, use getsockopt(2) to read
        // the SO_ERROR option at level SOL_SOCKET to determine whether
        // connect() completed successfully (SO_ERROR is zero) or
        // unsuccessfully.
        final osError = socket.nativeGetError();
        if (osError != null) {
          socket.close();
          error ??= osError;
          connectNext();
          return;
        }
        // Connection success!
        // Stop all other connecting sockets and the timer.
        timer!.cancel();
        socket.setListening(read: false, write: false);
        for (var s in connecting) {
          s.close();
          s.setHandlers();
          s.setListening(read: false, write: false);
        }
        connecting.clear();
        addressesSubscription.cancel();
        if (!result.isCompleted) {
          // Might be already completed via onCancel
          result.complete(socket);
        }
      }, error: (e, st) {
        connecting.remove(socket);
        socket.close();
        socket.setHandlers();
        socket.setListening(read: false, write: false);
        // Keep first error, if present.
        error ??= e;
        connectNext(); // Try again after failure to connect.
      });
      socket.setListening(read: false, write: true);
    }

    void onCancel() {
      timer?.cancel();
      for (var s in connecting) {
        s.close();
        s.setHandlers();
        s.setListening(read: false, write: false);
      }
      addressesSubscription.cancel();
      connecting.clear();
      if (!result.isCompleted) {
        error ??= createError(
            null, "Connection attempt cancelled, host: ${host}, port: ${port}");
        result.completeError(error, callerStackTrace);
      }
    }

    addressesSubscription = addresses.listen((address) {
      pendingLookedUp.addAll(address);
      if (timer == null || !timer!.isActive) {
        connectNext();
      }
    }, onDone: () {
      isLookedUpStreamClosed = true;
      connectNext();
    }, onError: (e, st) {
      error = e;
    });

    connectNext();
    return new ConnectionTask<_NativeSocket>._(result.future, onCancel);
  }

  static Future<_NativeSocket> connect(dynamic host, int port,
      dynamic sourceAddress, int sourcePort, Duration? timeout) {
    return startConnect(host, port, sourceAddress, sourcePort)
        .then((ConnectionTask<_NativeSocket> task) {
      Future<_NativeSocket> socketFuture = task.socket;
      if (timeout != null) {
        socketFuture = socketFuture.timeout(timeout, onTimeout: () {
          task.cancel();
          throw createError(
              null, "Connection timed out, host: ${host}, port: ${port}");
        });
      }
      return socketFuture;
    });
  }

  static Future<_InternetAddress> _resolveHost(dynamic host) async {
    if (host is _InternetAddress) {
      return host;
    } else {
      final list = await lookup(host);
      if (list.isEmpty) {
        throw createError(null, "Failed host lookup: '$host'");
      }
      return list.first as _InternetAddress;
    }
  }

  static Future<_NativeSocket> bind(
      host, int port, int backlog, bool v6Only, bool shared) async {
    _throwOnBadPort(port);
    if (host is String) {
      host = escapeLinkLocalAddress(host);
    }
    final address = await _resolveHost(host);

    var socket = new _NativeSocket.listen(address);
    var result;
    if (address.type == InternetAddressType.unix) {
      var path = address.address;
      if (FileSystemEntity.isLinkSync(path)) {
        path = Link(path).targetSync();
      }
      result = socket.nativeCreateUnixDomainBindListen(
          path, backlog, shared, _Namespace._namespace);
    } else {
      result = socket.nativeCreateBindListen(
          address._in_addr, port, backlog, v6Only, shared, address._scope_id);
    }
    if (result is OSError) {
      throw new SocketException("Failed to create server socket",
          osError: result, address: address, port: port);
    }
    if (port != 0) socket.localPort = port;
    socket.connectToEventHandler();
    return socket;
  }

  static Future<_NativeSocket> bindDatagram(
      host, int port, bool reuseAddress, bool reusePort, int ttl) async {
    _throwOnBadPort(port);
    _throwOnBadTtl(ttl);

    final address = await _resolveHost(host);

    var socket = new _NativeSocket.datagram(address);
    var result = socket.nativeCreateBindDatagram(
        address._in_addr, port, reuseAddress, reusePort, ttl);
    if (result is OSError) {
      throw new SocketException("Failed to create datagram socket",
          osError: result, address: address, port: port);
    }
    if (port != 0) socket.localPort = port;
    return socket;
  }

  _NativeSocket.datagram(this.localAddress)
      : typeFlags = typeNormalSocket | typeUdpSocket;

  _NativeSocket.normal(this.localAddress)
      : typeFlags = typeNormalSocket | typeTcpSocket;

  _NativeSocket.listen(this.localAddress)
      : typeFlags = typeListeningSocket | typeTcpSocket {
    isClosedWrite = true;
  }

  _NativeSocket.pipe() : typeFlags = typePipe;

  _NativeSocket._watchCommon(int id, int type)
      : typeFlags = typeNormalSocket | type {
    isClosedWrite = true;
    nativeSetSocketId(id, typeFlags);
  }

  _NativeSocket.watchSignal(int id)
      : this._watchCommon(id, typeInternalSignalSocket);

  _NativeSocket.watch(int id) : this._watchCommon(id, typeInternalSocket);

  bool get isListening => (typeFlags & typeListeningSocket) != 0;
  bool get isPipe => (typeFlags & typePipe) != 0;
  bool get isInternal => (typeFlags & typeInternalSocket) != 0;
  bool get isInternalSignal => (typeFlags & typeInternalSignalSocket) != 0;
  bool get isTcp => (typeFlags & typeTcpSocket) != 0;
  bool get isUdp => (typeFlags & typeUdpSocket) != 0;

  String get _serviceTypePath => throw new UnimplementedError();
  String get _serviceTypeName => throw new UnimplementedError();

  Uint8List? read(int? count) {
    if (count != null && count <= 0) {
      throw ArgumentError("Illegal length $count");
    }
    if (isClosing || isClosed) return null;
    try {
      Uint8List? list;
      if (count != null) {
        list = nativeRead(count);
        available = nativeAvailable();
      } else {
        // If count is null, read as many bytes as possible.
        // Loop here to ensure bytes that arrived while this read was
        // issued are also read.
        BytesBuilder builder = BytesBuilder(copy: false);
        do {
          assert(available > 0);
          list = nativeRead(available);
          if (list == null) {
            break;
          }
          builder.add(list);
          available = nativeAvailable();
          const MAX_BUFFER_SIZE = 4 * 1024 * 1024;
          if (builder.length > MAX_BUFFER_SIZE) {
            // Don't consume too many bytes, otherwise we risk running
            // out of memory when handling the whole aggregated lot.
            break;
          }
        } while (available > 0);
        if (builder.isEmpty) {
          list = null;
        } else {
          list = builder.toBytes();
        }
      }
      if (!const bool.fromEnvironment("dart.vm.product")) {
        _SocketProfile.collectStatistic(
            nativeGetSocketId(), _SocketProfileType.readBytes, list?.length);
      }
      return list;
    } catch (e) {
      reportError(e, StackTrace.current, "Read failed");
      return null;
    }
  }

  Datagram? receive() {
    if (isClosing || isClosed) return null;
    try {
      Datagram? result = nativeRecvFrom();
      if (!const bool.fromEnvironment("dart.vm.product")) {
        _SocketProfile.collectStatistic(nativeGetSocketId(),
            _SocketProfileType.readBytes, result?.data.length);
      }
      _availableDatagram = nativeAvailableDatagram();
      return result;
    } catch (e) {
      reportError(e, StackTrace.current, "Receive failed");
      return null;
    }
  }

  SocketMessage? readMessage([int? count]) {
    if (count != null && count <= 0) {
      throw ArgumentError("Illegal length $count");
    }
    if (isClosing || isClosed) return null;
    try {
      final bytesCount = count ?? nativeAvailable();
      // Returned messagesData is a list of triples (level, type, uint8list)
      // followed by uint8list with raw data.
      // This is kept at this level to minimize dart api use in native method.
      final List<dynamic> messagesData = nativeReceiveMessage(bytesCount);
      final messages = <SocketControlMessage>[];
      if (messagesData.isNotEmpty) {
        final triplesCount = (messagesData.length - 1) / 3;
        assert((triplesCount * 3) == (messagesData.length - 1));
        for (int i = 0; i < triplesCount; i++) {
          final message = _SocketControlMessageImpl(
              messagesData[i * 3] as int,
              messagesData[i * 3 + 1] as int,
              messagesData[i * 3 + 2] as Uint8List);
          messages.add(message);
        }
      }
      final socketMessage = SocketMessage(
          messagesData[messagesData.length - 1] as Uint8List, messages);
      available = nativeAvailable();
      if (!const bool.fromEnvironment("dart.vm.product")) {
        _SocketProfile.collectStatistic(
            nativeGetSocketId(), _SocketProfileType.readBytes, bytesCount);
      }
      return socketMessage;
    } catch (e, st) {
      reportError(e, st, "Read failed");
      return null;
    }
  }

  static int _fixOffset(int? offset) => offset ?? 0;

  // This code issues a native write operation.
  //
  // On POSIX systems the data will be written using `write` syscall.
  // When `write` returns a positive value this means that this number
  // of bytes have been transferred from [buffer] into the OS buffer.
  // At this point if the underlying descriptor is closed the OS will
  // still attempt to deliver already written bytes to the destination.
  //
  // On Windows we use overlapped IO instead: `write` returning a positive
  // value simply means that we have initiated an asynchronous IO operation
  // for this many bytes. Closing the underlying handle will simply cancel the
  // operation midway. Consequently you can only assume that bytes left userland
  // when asynchronous write operation completes and this socket receives
  // a [writeEvent].
  int write(List<int> buffer, int offset, int? bytes) {
    // TODO(40614): Remove once non-nullability is sound.
    offset = _fixOffset(offset);
    if (bytes == null) {
      if (offset > buffer.length) {
        throw new RangeError.value(offset);
      }
      bytes = buffer.length - offset;
    }
    if (offset < 0) throw new RangeError.value(offset);
    if (bytes < 0) throw new RangeError.value(bytes);
    if ((offset + bytes) > buffer.length) {
      throw new RangeError.value(offset + bytes);
    }
    if (isClosing || isClosed) return 0;
    if (bytes == 0) return 0;
    try {
      _BufferAndStart bufferAndStart =
          _ensureFastAndSerializableByteData(buffer, offset, offset + bytes);
      if (!const bool.fromEnvironment("dart.vm.product")) {
        _SocketProfile.collectStatistic(
            nativeGetSocketId(),
            _SocketProfileType.writeBytes,
            bufferAndStart.buffer.length - bufferAndStart.start);
      }
      int result =
          nativeWrite(bufferAndStart.buffer, bufferAndStart.start, bytes);
      if (result >= 0) {
        // If write succeeded only partially or is pending then we should
        // pause writing and wait for the write event to arrive from the
        // event handler. If the write has fully completed then we should
        // continue writing.
        writeAvailable = (result == bytes) && !hasPendingWrite();
      } else {
        // Negative result indicates that we forced a short write for testing
        // purpose. We are not guaranteed to get a writeEvent in this case
        // unless there is a pending write - which will trigger an event
        // when it completes. So the caller should continue writing into
        // this socket.
        result = -result;
        writeAvailable = !hasPendingWrite();
      }
      return result;
    } catch (e) {
      StackTrace st = StackTrace.current;
      scheduleMicrotask(() => reportError(e, st, "Write failed"));
      return 0;
    }
  }

  int send(List<int> buffer, int offset, int bytes, InternetAddress address,
      int port) {
    _throwOnBadPort(port);
    if (isClosing || isClosed) return 0;
    try {
      _BufferAndStart bufferAndStart =
          _ensureFastAndSerializableByteData(buffer, offset, bytes);
      if (!const bool.fromEnvironment("dart.vm.product")) {
        _SocketProfile.collectStatistic(
            nativeGetSocketId(),
            _SocketProfileType.writeBytes,
            bufferAndStart.buffer.length - bufferAndStart.start);
      }
      int result = nativeSendTo(bufferAndStart.buffer, bufferAndStart.start,
          bytes, (address as _InternetAddress)._in_addr, port);
      return result;
    } catch (e) {
      StackTrace st = StackTrace.current;
      scheduleMicrotask(() => reportError(e, st, "Send failed"));
      return 0;
    }
  }

  int sendMessage(List<int> buffer, int offset, int? bytes,
      List<SocketControlMessage> controlMessages) {
    if (offset < 0) throw new RangeError.value(offset);
    if (bytes != null) {
      if (bytes < 0) throw new RangeError.value(bytes);
    } else {
      bytes = buffer.length - offset;
    }
    if ((offset + bytes) > buffer.length) {
      throw new RangeError.value(offset + bytes);
    }
    if (isClosing || isClosed) return 0;
    try {
      _BufferAndStart bufferAndStart =
          _ensureFastAndSerializableByteData(buffer, offset, bytes);
      if (!const bool.fromEnvironment("dart.vm.product")) {
        _SocketProfile.collectStatistic(
            nativeGetSocketId(),
            _SocketProfileType.writeBytes,
            bufferAndStart.buffer.length - bufferAndStart.start);
      }
      // list of triples <level, type, data> arranged to minimize dart api
      // use in native method.
      List<dynamic> messages = <dynamic>[];
      for (SocketControlMessage controlMessage in controlMessages) {
        messages.add(controlMessage.level);
        messages.add(controlMessage.type);
        messages.add(controlMessage.data);
      }

      return nativeSendMessage(
          bufferAndStart.buffer, bufferAndStart.start, bytes, messages);
    } catch (e, st) {
      scheduleMicrotask(() => reportError(e, st, "SendMessage failed"));
      return 0;
    }
  }

  _NativeSocket? accept() {
    // Don't issue accept if we're closing.
    if (isClosing || isClosed) return null;
    assert(connections > 0);
    connections--;
    tokens++;
    returnTokens(listeningTokenBatchSize);
    var socket = new _NativeSocket.normal(address);
    if (nativeAccept(socket) != true) return null;
    socket.localPort = localPort;
    return socket;
  }

  int get port {
    if (localAddress.type == InternetAddressType.unix) return 0;
    if (localPort != 0) return localPort;
    if (isClosing || isClosed) throw const SocketException.closed();
    var result = nativeGetPort();
    if (result is OSError) {
      throw result;
    }
    return localPort = result;
  }

  int get remotePort {
    if (localAddress.type == InternetAddressType.unix) return 0;
    if (isClosing || isClosed) throw const SocketException.closed();
    return nativeGetRemotePeer()[1];
  }

  InternetAddress get address => localAddress;

  InternetAddress get remoteAddress {
    if (isClosing || isClosed) throw const SocketException.closed();
    var result = nativeGetRemotePeer();
    var addr = result[0] as List<Object?>;
    var type = new InternetAddressType._from(addr[0] as int);
    if (type == InternetAddressType.unix) {
      return _InternetAddress.fromString(addr[1] as String,
          type: InternetAddressType.unix);
    }
    return _InternetAddress(
        type, addr[1] as String, null, addr[2] as Uint8List);
  }

  void issueReadEvent() {
    if (closedReadEventSent) return;
    if (readEventIssued) return;
    readEventIssued = true;
    void issue() {
      readEventIssued = false;
      if (isClosing) return;
      if (!sendReadEvents) return;
      if (stopRead()) {
        if (isClosedRead && !closedReadEventSent) {
          if (isClosedWrite) close();
          var handler = closedEventHandler;
          if (handler == null) return;
          closedReadEventSent = true;
          handler();
        }
        return;
      }
      var handler = readEventHandler;
      if (handler == null) return;
      readEventIssued = true;
      handler();
      scheduleMicrotask(issue);
    }

    scheduleMicrotask(issue);
  }

  bool stopRead() {
    if (isUdp) {
      return !_availableDatagram;
    } else {
      return available == 0;
    }
  }

  void issueWriteEvent({bool delayed = true}) {
    if (writeEventIssued) return;
    if (!writeAvailable) return;
    void issue() {
      writeEventIssued = false;
      if (!writeAvailable) return;
      if (isClosing) return;
      if (!sendWriteEvents) return;
      sendWriteEvents = false;
      var handler = writeEventHandler;
      if (handler == null) return;
      handler();
    }

    if (delayed) {
      writeEventIssued = true;
      scheduleMicrotask(issue);
    } else {
      issue();
    }
  }

  // Multiplexes socket events to the socket handlers.
  void multiplex(Object eventsObj) {
    // TODO(paulberry): when issue #31305 is fixed, we should be able to simply
    // declare `events` as a `covariant int` parameter.
    int events = eventsObj as int;
    for (int i = firstEvent; i <= lastEvent; i++) {
      if (((events & (1 << i)) != 0)) {
        if (isClosing && i != destroyedEvent) continue;
        switch (i) {
          case readEvent:
            if (isClosedRead) continue;
            if (isListening) {
              connections++;
              if (!isClosed) {
                // If the connection is closed right after it's accepted, there's a
                // chance the close-handler is not set.
                var handler = readEventHandler;
                if (handler != null) handler();
              }
            } else {
              if (isUdp) {
                _availableDatagram = nativeAvailableDatagram();
              } else {
                available = nativeAvailable();
              }
              issueReadEvent();
              continue;
            }
            break;
          case writeEvent:
            // On Windows there are two sources of write events: when pending
            // write completes and when we subscribe to write events via
            // setEventMaskCommand. Furthermore we don't always wait for a
            // write event to issue a write. This means when event triggered by
            // setEventMaskCommand arrives we might have already initiated a
            // write. This means we should check [hasPendingWrite] here to
            // be absolutely certain that the pending write operation has
            // completed.
            writeAvailable = !hasPendingWrite();
            issueWriteEvent(delayed: false);
            continue;
          case errorEvent:
            if (!isClosing) {
              final osError = nativeGetError();
              if (osError != null) {
                reportError(osError, null, osError.message);
              } else {
                reportError(
                    Error(),
                    StackTrace.current,
                    "Error event raised in event handler : "
                    "error condition has been reset");
              }
            }
            break;
          case closedEvent:
            if (isClosedRead) continue;
            if (!isListening && !isClosing && !isClosed) {
              isClosedRead = true;
              issueReadEvent();
              continue;
            } else if (!isClosed) {
              // If the connection is closed right after it's accepted, there's a
              // chance the close-handler is not set.
              var handler = closedEventHandler;
              if (handler != null) handler();
            }
            break;
          case destroyedEvent:
            assert(isClosing);
            assert(!isClosed);
            isClosed = true;
            closeCompleter.complete();
            disconnectFromEventHandler();
            var handler = destroyedEventHandler;
            if (handler != null) handler();
            continue;
        }
      }
    }
    if (!isListening) {
      tokens++;
      returnTokens(normalTokenBatchSize);
    }
  }

  void returnTokens(int tokenBatchSize) {
    if (!isClosing && !isClosed) {
      assert(eventPort != null);
      // Return in batches.
      if (tokens == tokenBatchSize) {
        assert(tokens < (1 << firstCommand));
        sendToEventHandler((1 << returnTokenCommand) | tokens);
        tokens = 0;
      }
    }
  }

  void setHandlers(
      {void Function()? read,
      void Function()? write,
      void Function(Object e, StackTrace? st)? error,
      void Function()? closed,
      void Function()? destroyed}) {
    readEventHandler = read;
    writeEventHandler = write;
    errorEventHandler = error;
    closedEventHandler = closed;
    destroyedEventHandler = destroyed;
  }

  void setListening({bool read = true, bool write = true}) {
    sendReadEvents = read;
    sendWriteEvents = write;
    if (read) issueReadEvent();
    if (write) issueWriteEvent();
    if (!flagsSent && !isClosing) {
      flagsSent = true;
      int flags = 1 << setEventMaskCommand;
      if (!isClosedRead) flags |= 1 << readEvent;
      if (!isClosedWrite) flags |= 1 << writeEvent;
      sendToEventHandler(flags);
    }
  }

  Future close() {
    if (!isClosing && !isClosed) {
      sendToEventHandler(1 << closeCommand);
      isClosing = true;
    }
    return closeCompleter.future;
  }

  void shutdown(SocketDirection direction) {
    if (!isClosing && !isClosed) {
      switch (direction) {
        case SocketDirection.receive:
          shutdownRead();
          break;
        case SocketDirection.send:
          shutdownWrite();
          break;
        case SocketDirection.both:
          close();
          break;
        default:
          throw new ArgumentError(direction);
      }
    }
  }

  void shutdownWrite() {
    if (!isClosing && !isClosed) {
      if (closedReadEventSent) {
        close();
      } else {
        sendToEventHandler(1 << shutdownWriteCommand);
      }
      isClosedWrite = true;
    }
  }

  void shutdownRead() {
    if (!isClosing && !isClosed) {
      if (isClosedWrite) {
        close();
      } else {
        sendToEventHandler(1 << shutdownReadCommand);
      }
      isClosedRead = true;
    }
  }

  void sendToEventHandler(int data) {
    int fullData = (typeFlags & typeTypeMask) | data;
    assert(!isClosing);
    connectToEventHandler();
    _EventHandler._sendData(this, eventPort!.sendPort, fullData);
  }

  void connectToEventHandler() {
    assert(!isClosed);
    if (eventPort == null) {
      eventPort = new RawReceivePort(multiplex, 'Socket Event Handler');
    }
  }

  void disconnectFromEventHandler() {
    eventPort!.close();
    eventPort = null;
    // Now that we don't track this Socket anymore, we can clear the owner
    // field.
    owner = null;
  }

  // Check whether this is an error response from a native port call.
  static bool isErrorResponse(response) {
    return response is List && response[0] != _successResponse;
  }

  // Create the appropriate error/exception from different returned
  // error objects.
  static createError(error, String message,
      [InternetAddress? address, int? port]) {
    if (error is OSError) {
      return SocketException(message,
          osError: error, address: address, port: port);
    } else if (error is List) {
      assert(isErrorResponse(error));
      switch (error[0]) {
        case _illegalArgumentResponse:
          return ArgumentError();
        case _osErrorResponse:
          return SocketException(message,
              osError: OSError(error[2], error[1]),
              address: address,
              port: port);
        default:
          return AssertionError("Unknown error");
      }
    } else {
      return SocketException(message, address: address, port: port);
    }
  }

  void reportError(error, StackTrace? st, String message) {
    var e =
        createError(error, message, isUdp || isTcp ? address : null, localPort);
    // Invoke the error handler if any.
    var handler = errorEventHandler;
    if (handler != null) {
      handler(e, st);
    }
    // For all errors we close the socket
    close();
  }

  dynamic getOption(SocketOption option) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(option, "option");
    var result = nativeGetOption(option._value, address.type._value);
    if (result is OSError) throw result;
    return result;
  }

  bool setOption(SocketOption option, value) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(option, "option");
    nativeSetOption(option._value, address.type._value, value);
    return true;
  }

  Uint8List getRawOption(RawSocketOption option) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(option, "option");
    ArgumentError.checkNotNull(option.value, "option.value");
    nativeGetRawOption(option.level, option.option, option.value);
    return option.value;
  }

  void setRawOption(RawSocketOption option) {
    // TODO(40614): Remove once non-nullability is sound.
    ArgumentError.checkNotNull(option, "option");
    ArgumentError.checkNotNull(option.value, "option.value");
    nativeSetRawOption(option.level, option.option, option.value);
  }

  InternetAddress? multicastAddress(
      InternetAddress addr, NetworkInterface? interface) {
    // On Mac OS using the interface index for joining IPv4 multicast groups
    // is not supported. Here the IP address of the interface is needed.
    if ((Platform.isMacOS || Platform.isIOS) &&
        addr.type == InternetAddressType.IPv4) {
      if (interface != null) {
        for (int i = 0; i < interface.addresses.length; i++) {
          if (interface.addresses[i].type == InternetAddressType.IPv4) {
            return interface.addresses[i];
          }
        }
        // No IPv4 address found on the interface.
        throw new SocketException(
            "The network interface does not have an address "
            "of the same family as the multicast address");
      } else {
        // Default to the ANY address if no interface is specified.
        return InternetAddress.anyIPv4;
      }
    } else {
      return null;
    }
  }

  void joinMulticast(InternetAddress addr, NetworkInterface? interface) {
    final interfaceAddr =
        multicastAddress(addr, interface) as _InternetAddress?;
    var interfaceIndex = interface == null ? 0 : interface.index;
    nativeJoinMulticast((addr as _InternetAddress)._in_addr,
        interfaceAddr?._in_addr, interfaceIndex);
  }

  void leaveMulticast(InternetAddress addr, NetworkInterface? interface) {
    final interfaceAddr =
        multicastAddress(addr, interface) as _InternetAddress?;
    var interfaceIndex = interface == null ? 0 : interface.index;
    nativeLeaveMulticast((addr as _InternetAddress)._in_addr,
        interfaceAddr?._in_addr, interfaceIndex);
  }

  bool hasPendingWrite() {
    return Platform.isWindows && nativeHasPendingWrite();
  }

  @pragma("vm:external-name", "Socket_SetSocketId")
  external void nativeSetSocketId(int id, int typeFlags);
  @pragma("vm:external-name", "Socket_Available")
  external int nativeAvailable();
  @pragma("vm:external-name", "Socket_AvailableDatagram")
  external bool nativeAvailableDatagram();
  @pragma("vm:external-name", "Socket_Read")
  external Uint8List? nativeRead(int len);
  @pragma("vm:external-name", "Socket_RecvFrom")
  external Datagram? nativeRecvFrom();
  @pragma("vm:external-name", "Socket_ReceiveMessage")
  external List<dynamic> nativeReceiveMessage(int len);
  @pragma("vm:external-name", "Socket_WriteList")
  external int nativeWrite(List<int> buffer, int offset, int bytes);
  @pragma("vm:external-name", "Socket_HasPendingWrite")
  external bool nativeHasPendingWrite();
  @pragma("vm:external-name", "Socket_SendTo")
  external int nativeSendTo(
      List<int> buffer, int offset, int bytes, Uint8List address, int port);
  @pragma("vm:external-name", "Socket_SendMessage")
  external nativeSendMessage(
      List<int> buffer, int offset, int bytes, List<dynamic> controlMessages);
  @pragma("vm:external-name", "Socket_CreateConnect")
  external nativeCreateConnect(Uint8List addr, int port, int scope_id);
  @pragma("vm:external-name", "Socket_CreateUnixDomainConnect")
  external nativeCreateUnixDomainConnect(String addr, _Namespace namespace);
  @pragma("vm:external-name", "Socket_CreateBindConnect")
  external nativeCreateBindConnect(Uint8List addr, int port,
      Uint8List sourceAddr, int sourcePort, int scope_id);
  @pragma("vm:external-name", "Socket_CreateUnixDomainBindConnect")
  external nativeCreateUnixDomainBindConnect(
      String addr, String sourceAddr, _Namespace namespace);
  @pragma("vm:external-name", "SocketBase_IsBindError")
  external bool isBindError(int errorNumber);
  @pragma("vm:external-name", "ServerSocket_CreateBindListen")
  external nativeCreateBindListen(Uint8List addr, int port, int backlog,
      bool v6Only, bool shared, int scope_id);
  @pragma("vm:external-name", "ServerSocket_CreateUnixDomainBindListen")
  external nativeCreateUnixDomainBindListen(
      String addr, int backlog, bool shared, _Namespace namespace);
  @pragma("vm:external-name", "Socket_CreateBindDatagram")
  external nativeCreateBindDatagram(
      Uint8List addr, int port, bool reuseAddress, bool reusePort, int ttl);
  @pragma("vm:external-name", "ServerSocket_Accept")
  external bool nativeAccept(_NativeSocket socket);
  @pragma("vm:external-name", "Socket_GetPort")
  external dynamic nativeGetPort();
  @pragma("vm:external-name", "Socket_GetRemotePeer")
  external List nativeGetRemotePeer();
  @pragma("vm:external-name", "Socket_GetSocketId")
  external int nativeGetSocketId();
  @pragma("vm:external-name", "Socket_GetFD")
  external int get fd;
  @pragma("vm:external-name", "Socket_GetError")
  external OSError? nativeGetError();
  @pragma("vm:external-name", "Socket_GetOption")
  external nativeGetOption(int option, int protocol);
  @pragma("vm:external-name", "Socket_GetRawOption")
  external void nativeGetRawOption(int level, int option, Uint8List data);
  @pragma("vm:external-name", "Socket_SetOption")
  external void nativeSetOption(int option, int protocol, value);
  @pragma("vm:external-name", "Socket_SetRawOption")
  external void nativeSetRawOption(int level, int option, Uint8List data);
  @pragma("vm:external-name", "Socket_JoinMulticast")
  external void nativeJoinMulticast(
      Uint8List addr, Uint8List? interfaceAddr, int interfaceIndex);
  @pragma("vm:external-name", "Socket_LeaveMulticast")
  external void nativeLeaveMulticast(
      Uint8List addr, Uint8List? interfaceAddr, int interfaceIndex);
  @pragma("vm:external-name", "Socket_Fatal")
  external static void _nativeFatal(msg);
}

class _RawServerSocket extends Stream<RawSocket>
    implements RawServerSocket, _RawSocketBase {
  final _NativeSocket _socket;
  StreamController<RawSocket>? _controller;
  bool _v6Only;

  static Future<_RawServerSocket> bind(
      address, int port, int backlog, bool v6Only, bool shared) {
    _throwOnBadPort(port);
    if (backlog < 0) throw new ArgumentError("Invalid backlog $backlog");
    return _NativeSocket.bind(address, port, backlog, v6Only, shared)
        .then((socket) => new _RawServerSocket(socket, v6Only));
  }

  _RawServerSocket(this._socket, this._v6Only);

  StreamSubscription<RawSocket> listen(void onData(RawSocket event)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    if (_controller != null) {
      throw new StateError("Stream was already listened to");
    }
    var zone = Zone.current;
    final controller = _controller = new StreamController(
        sync: true,
        onListen: _onSubscriptionStateChange,
        onCancel: _onSubscriptionStateChange,
        onPause: _onPauseStateChange,
        onResume: _onPauseStateChange);
    _socket.setHandlers(
        read: zone.bindCallbackGuarded(() {
          while (_socket.connections > 0) {
            var socket = _socket.accept();
            if (socket == null) return;
            if (!const bool.fromEnvironment("dart.vm.product")) {
              _SocketProfile.collectNewSocket(socket.nativeGetSocketId(),
                  _tcpSocket, socket.address, socket.port);
            }
            controller.add(_RawSocket(socket));
            if (controller.isPaused) return;
          }
        }),
        error: zone.bindBinaryCallbackGuarded((Object e, StackTrace? st) {
          controller.addError(e, st);
          controller.close();
        }),
        destroyed: () => controller.close());
    return controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  int get port => _socket.port;

  InternetAddress get address => _socket.address;

  Future<RawServerSocket> close() {
    return _socket.close().then<RawServerSocket>((_) => this);
  }

  void _pause() {
    _socket.setListening(read: false, write: false);
  }

  void _resume() {
    _socket.setListening(read: true, write: false);
  }

  void _onSubscriptionStateChange() {
    if (_controller!.hasListener) {
      _resume();
    } else {
      _socket.close();
    }
  }

  void _onPauseStateChange() {
    if (_controller!.isPaused) {
      _pause();
    } else {
      _resume();
    }
  }

  bool get _closedReadEventSent => _socket.closedReadEventSent;

  void set _owner(owner) {
    _socket.owner = owner;
  }
}

class _RawSocket extends Stream<RawSocketEvent>
    implements RawSocket, _RawSocketBase {
  final _NativeSocket _socket;
  final _controller = new StreamController<RawSocketEvent>(sync: true);
  bool _readEventsEnabled = true;
  bool _writeEventsEnabled = true;

  // Flag to handle Ctrl-D closing of stdio on Mac OS.
  bool _isMacOSTerminalInput = false;

  static Future<RawSocket> connect(dynamic host, int port,
      dynamic sourceAddress, int sourcePort, Duration? timeout) {
    return _NativeSocket.connect(host, port, sourceAddress, sourcePort, timeout)
        .then((socket) {
      if (!const bool.fromEnvironment("dart.vm.product")) {
        _SocketProfile.collectNewSocket(
            socket.nativeGetSocketId(), _tcpSocket, socket.address, port);
      }
      return _RawSocket(socket);
    });
  }

  static Future<ConnectionTask<_RawSocket>> startConnect(
      dynamic host, int port, dynamic sourceAddress, int sourcePort) {
    return _NativeSocket.startConnect(host, port, sourceAddress, sourcePort)
        .then((ConnectionTask<_NativeSocket> nativeTask) {
      final Future<_RawSocket> raw =
          nativeTask.socket.then((_NativeSocket nativeSocket) {
        if (!const bool.fromEnvironment("dart.vm.product")) {
          _SocketProfile.collectNewSocket(nativeSocket.nativeGetSocketId(),
              _tcpSocket, nativeSocket.address, port);
        }
        return _RawSocket(nativeSocket);
      });
      return ConnectionTask<_RawSocket>._(raw, nativeTask._onCancel);
    });
  }

  _RawSocket(this._socket) {
    var zone = Zone.current;
    _controller
      ..onListen = _onSubscriptionStateChange
      ..onCancel = _onSubscriptionStateChange
      ..onPause = _onPauseStateChange
      ..onResume = _onPauseStateChange;
    _socket.setHandlers(
        read: () => _controller.add(RawSocketEvent.read),
        write: () {
          // The write event handler is automatically disabled by the
          // event handler when it fires.
          writeEventsEnabled = false;
          _controller.add(RawSocketEvent.write);
        },
        closed: () => _controller.add(RawSocketEvent.readClosed),
        destroyed: () {
          _controller.add(RawSocketEvent.closed);
          _controller.close();
        },
        error: zone.bindBinaryCallbackGuarded((Object e, StackTrace? st) {
          _controller.addError(e, st);
          _socket.close();
        }));
  }

  factory _RawSocket._writePipe() {
    var native = new _NativeSocket.pipe();
    native.isClosedRead = true;
    native.closedReadEventSent = true;
    return new _RawSocket(native);
  }

  factory _RawSocket._readPipe(int? fd) {
    var native = new _NativeSocket.pipe();
    native.isClosedWrite = true;
    if (fd != null) _getStdioHandle(native, fd);
    var result = new _RawSocket(native);
    if (fd != null) {
      var socketType = _StdIOUtils._nativeSocketType(result._socket);
      result._isMacOSTerminalInput =
          Platform.isMacOS && socketType == _stdioHandleTypeTerminal;
    }
    return result;
  }

  StreamSubscription<RawSocketEvent> listen(void onData(RawSocketEvent event)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  int available() => _socket.available;

  Uint8List? read([int? len]) {
    if (_isMacOSTerminalInput) {
      var available = this.available();
      if (available == 0) return null;
      var data = _socket.read(len);
      if (data == null || data.length < available) {
        // Reading less than available from a Mac OS terminal indicate Ctrl-D.
        // This is interpreted as read closed.
        scheduleMicrotask(() => _controller.add(RawSocketEvent.readClosed));
      }
      return data;
    } else {
      return _socket.read(len);
    }
  }

  SocketMessage? readMessage([int? count]) {
    return _socket.readMessage(count);
  }

  /// See [_NativeSocket.write] for some implementation notes.
  int write(List<int> buffer, [int offset = 0, int? count]) =>
      _socket.write(buffer, offset, count);

  int sendMessage(List<SocketControlMessage> controlMessages, List<int> data,
          [int offset = 0, int? count]) =>
      _socket.sendMessage(data, offset, count, controlMessages);

  Future<RawSocket> close() => _socket.close().then<RawSocket>((_) {
        if (!const bool.fromEnvironment("dart.vm.product")) {
          _SocketProfile.collectStatistic(
              _socket.nativeGetSocketId(), _SocketProfileType.endTime);
        }
        return this;
      });

  void shutdown(SocketDirection direction) => _socket.shutdown(direction);

  int get port => _socket.port;

  int get remotePort => _socket.remotePort;

  InternetAddress get address => _socket.address;

  InternetAddress get remoteAddress => _socket.remoteAddress;

  bool get readEventsEnabled => _readEventsEnabled;
  void set readEventsEnabled(bool value) {
    if (value != _readEventsEnabled) {
      _readEventsEnabled = value;
      if (!_controller.isPaused) _resume();
    }
  }

  bool get writeEventsEnabled => _writeEventsEnabled;
  void set writeEventsEnabled(bool value) {
    if (value != _writeEventsEnabled) {
      _writeEventsEnabled = value;
      if (!_controller.isPaused) _resume();
    }
  }

  bool setOption(SocketOption option, bool enabled) =>
      _socket.setOption(option, enabled);

  Uint8List getRawOption(RawSocketOption option) =>
      _socket.getRawOption(option);
  void setRawOption(RawSocketOption option) => _socket.setRawOption(option);

  _pause() {
    _socket.setListening(read: false, write: false);
  }

  void _resume() {
    _socket.setListening(read: _readEventsEnabled, write: _writeEventsEnabled);
  }

  void _onPauseStateChange() {
    if (_controller.isPaused) {
      _pause();
    } else {
      _resume();
    }
  }

  void _onSubscriptionStateChange() {
    if (_controller.hasListener) {
      _resume();
    } else {
      _socket.close();
    }
  }

  bool get _closedReadEventSent => _socket.closedReadEventSent;

  void set _owner(owner) {
    _socket.owner = owner;
  }
}

@patch
class ServerSocket {
  @patch
  static Future<ServerSocket> _bind(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) {
    return _ServerSocket.bind(address, port, backlog, v6Only, shared);
  }
}

class _ServerSocket extends Stream<Socket> implements ServerSocket {
  final _socket;

  static Future<_ServerSocket> bind(
      address, int port, int backlog, bool v6Only, bool shared) {
    return _RawServerSocket.bind(address, port, backlog, v6Only, shared)
        .then((socket) => new _ServerSocket(socket));
  }

  _ServerSocket(this._socket);

  StreamSubscription<Socket> listen(void onData(Socket event)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    return _socket.map<Socket>((rawSocket) => new _Socket(rawSocket)).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError);
  }

  int get port => _socket.port;

  InternetAddress get address => _socket.address;

  Future<ServerSocket> close() =>
      _socket.close().then<ServerSocket>((_) => this);

  void set _owner(owner) {
    _socket._owner = owner;
  }
}

@patch
class Socket {
  @patch
  static Future<Socket> _connect(dynamic host, int port,
      {dynamic sourceAddress, int sourcePort = 0, Duration? timeout}) {
    return RawSocket.connect(host, port,
            sourceAddress: sourceAddress,
            sourcePort: sourcePort,
            timeout: timeout)
        .then((socket) => new _Socket(socket));
  }

  @patch
  static Future<ConnectionTask<Socket>> _startConnect(dynamic host, int port,
      {dynamic sourceAddress, int sourcePort = 0}) {
    return RawSocket.startConnect(host, port,
            sourceAddress: sourceAddress, sourcePort: sourcePort)
        .then((rawTask) {
      Future<Socket> socket =
          rawTask.socket.then((rawSocket) => new _Socket(rawSocket));
      return new ConnectionTask<Socket>._(socket, rawTask._onCancel);
    });
  }
}

class _SocketStreamConsumer implements StreamConsumer<List<int>> {
  StreamSubscription? subscription;
  final _Socket socket;
  int? offset;
  List<int>? buffer;
  bool paused = false;
  Completer<Socket>? streamCompleter;

  _SocketStreamConsumer(this.socket);

  Future<Socket> addStream(Stream<List<int>> stream) {
    socket._ensureRawSocketSubscription();
    final completer = streamCompleter = new Completer<Socket>();
    if (socket._raw != null) {
      subscription = stream.listen((data) {
        assert(!paused);
        assert(buffer == null);
        buffer = data;
        offset = 0;
        try {
          write();
        } catch (e) {
          buffer = null;
          offset = 0;

          socket.destroy();
          stop();
          done(e);
        }
      }, onError: (error, [stackTrace]) {
        socket.destroy();
        done(error, stackTrace);
      }, onDone: () {
        // Note: stream only delivers done event if subscription is not paused.
        // so it is crucial to keep subscription paused while writes are
        // in flight.
        assert(buffer == null);
        done();
      }, cancelOnError: true);
    } else {
      done();
    }
    return completer.future;
  }

  Future<Socket> close() {
    socket._consumerDone();
    return new Future.value(socket);
  }

  bool get _previousWriteHasCompleted {
    final rawSocket = socket._raw;
    if (rawSocket is _RawSocket) {
      return rawSocket._socket.writeAvailable;
    }
    assert(rawSocket is _RawSecureSocket);
    // _RawSecureSocket has an internal buffering mechanism and it is going
    // to flush its buffer before it shutsdown.
    return true;
  }

  void write() {
    final sub = subscription;
    if (sub == null) return;

    // We have something to write out.
    if (offset! < buffer!.length) {
      offset =
          offset! + socket._write(buffer!, offset!, buffer!.length - offset!);
    }

    if (offset! < buffer!.length || !_previousWriteHasCompleted) {
      // On Windows we might have written the whole buffer out but we are
      // still waiting for the write to complete. We should not resume the
      // subscription until the pending write finishes and we receive a
      // writeEvent signaling that we can write the next chunk or that we
      // can consider all data flushed from our side into kernel buffers.
      if (!paused) {
        paused = true;
        sub.pause();
      }
      socket._enableWriteEvent();
    } else {
      // Write fully completed.
      buffer = null;
      if (paused) {
        paused = false;
        sub.resume();
      }
    }
  }

  void done([error, stackTrace]) {
    final completer = streamCompleter;
    if (completer != null) {
      if (error != null) {
        completer.completeError(error, stackTrace);
      } else {
        completer.complete(socket);
      }
      streamCompleter = null;
    }
  }

  void stop() {
    final sub = subscription;
    if (sub == null) return;
    sub.cancel();
    subscription = null;
    paused = false;
    socket._disableWriteEvent();
  }
}

class _Socket extends Stream<Uint8List> implements Socket {
  RawSocket? _raw; // Set to null when the raw socket is closed.
  bool _closed = false; // Set to true when the raw socket is closed.
  final _controller = new StreamController<Uint8List>(sync: true);
  bool _controllerClosed = false;
  late _SocketStreamConsumer _consumer;
  late IOSink _sink;
  StreamSubscription? _subscription;
  Completer<Object?>? _detachReady;

  _Socket(RawSocket raw) : _raw = raw {
    _controller
      ..onListen = _onSubscriptionStateChange
      ..onCancel = _onSubscriptionStateChange
      ..onPause = _onPauseStateChange
      ..onResume = _onPauseStateChange;
    _consumer = new _SocketStreamConsumer(this);
    _sink = new IOSink(_consumer);

    // Disable read events until there is a subscription.
    raw.readEventsEnabled = false;

    // Disable write events until the consumer needs it for pending writes.
    raw.writeEventsEnabled = false;
  }

  factory _Socket._writePipe() {
    return new _Socket(new _RawSocket._writePipe());
  }

  factory _Socket._readPipe([int? fd]) {
    return new _Socket(new _RawSocket._readPipe(fd));
  }

  // Note: this code seems a bit suspicious because _raw can be _RawSocket and
  // it can be _RawSecureSocket because _SecureSocket extends _Socket
  // and these two types are incompatible because _RawSecureSocket._socket
  // is Socket and not _NativeSocket.
  _NativeSocket get _nativeSocket => (_raw as _RawSocket)._socket;

  StreamSubscription<Uint8List> listen(void onData(Uint8List event)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  Encoding get encoding => _sink.encoding;

  void set encoding(Encoding value) {
    _sink.encoding = value;
  }

  void write(Object? obj) => _sink.write(obj);

  void writeln([Object? obj = ""]) => _sink.writeln(obj);

  void writeCharCode(int charCode) => _sink.writeCharCode(charCode);

  void writeAll(Iterable objects, [String sep = ""]) =>
      _sink.writeAll(objects, sep);

  void add(List<int> bytes) => _sink.add(bytes);

  /// Unsupported operation on sockets.
  ///
  /// Throws an [UnsupportedError] because errors cannot be transmitted over a
  /// [Socket].
  void addError(Object error, [StackTrace? stackTrace]) {
    throw new UnsupportedError("Cannot send errors on sockets");
  }

  Future addStream(Stream<List<int>> stream) {
    return _sink.addStream(stream);
  }

  Future flush() => _sink.flush();

  Future close() => _sink.close();

  Future get done => _sink.done;

  void destroy() {
    // Destroy can always be called to get rid of a socket.
    if (_raw == null) return;
    _consumer.stop();
    _closeRawSocket();
    _controllerClosed = true;
    _controller.close();
  }

  bool setOption(SocketOption option, bool enabled) {
    final raw = _raw;
    if (raw == null) throw const SocketException.closed();
    return raw.setOption(option, enabled);
  }

  Uint8List getRawOption(RawSocketOption option) {
    final raw = _raw;
    if (raw == null) throw const SocketException.closed();
    return raw.getRawOption(option);
  }

  void setRawOption(RawSocketOption option) {
    final raw = _raw;
    if (raw == null) throw const SocketException.closed();
    raw.setRawOption(option);
  }

  int get port {
    final raw = _raw;
    if (raw == null) throw const SocketException.closed();
    return raw.port;
  }

  InternetAddress get address {
    final raw = _raw;
    if (raw == null) throw const SocketException.closed();
    return raw.address;
  }

  int get remotePort {
    final raw = _raw;
    if (raw == null) throw const SocketException.closed();
    return raw.remotePort;
  }

  InternetAddress get remoteAddress {
    final raw = _raw;
    if (raw == null) throw const SocketException.closed();
    return raw.remoteAddress;
  }

  Future<List<Object?>> _detachRaw() {
    var completer = Completer<Object?>();
    _detachReady = completer;
    _sink.close();
    return completer.future.then((_) {
      assert(_consumer.buffer == null);
      var raw = _raw;
      _raw = null;
      return [raw, _subscription];
    });
  }

  // Ensure a subscription on the raw socket. Both the stream and the
  // consumer needs a subscription as they share the error and done
  // events from the raw socket.
  void _ensureRawSocketSubscription() {
    final raw = _raw;
    if (_subscription == null && raw != null) {
      _subscription = raw.listen(_onData,
          onError: _onError, onDone: _onDone, cancelOnError: true);
    }
  }

  _closeRawSocket() {
    var raw = _raw!;
    _raw = null;
    _closed = true;
    raw.close();
  }

  void _onSubscriptionStateChange() {
    final raw = _raw;
    if (_controller.hasListener) {
      _ensureRawSocketSubscription();
      // Enable read events for providing data to subscription.
      if (raw != null) {
        raw.readEventsEnabled = true;
      }
    } else {
      _controllerClosed = true;
      if (raw != null) {
        raw.shutdown(SocketDirection.receive);
      }
    }
  }

  void _onPauseStateChange() {
    _raw?.readEventsEnabled = !_controller.isPaused;
  }

  void _onData(event) {
    switch (event) {
      case RawSocketEvent.read:
        if (_raw == null) break;
        var buffer = _raw!.read();
        if (buffer != null) _controller.add(buffer);
        break;
      case RawSocketEvent.write:
        _consumer.write();
        break;
      case RawSocketEvent.readClosed:
        _controllerClosed = true;
        _controller.close();
        break;
    }
  }

  void _onDone() {
    if (!_controllerClosed) {
      _controllerClosed = true;
      _controller.close();
    }
    _consumer.done();
  }

  void _onError(error, stackTrace) {
    if (!_controllerClosed) {
      _controllerClosed = true;
      _controller.addError(error, stackTrace);
      _controller.close();
    }
    _consumer.done(error, stackTrace);
  }

  int _write(List<int> data, int offset, int length) {
    final raw = _raw;
    if (raw != null) {
      return raw.write(data, offset, length);
    }
    return 0;
  }

  void _enableWriteEvent() {
    _raw?.writeEventsEnabled = true;
  }

  void _disableWriteEvent() {
    _raw?.writeEventsEnabled = false;
  }

  void _consumerDone() {
    if (_detachReady != null) {
      _detachReady!.complete(null);
    } else {
      final raw = _raw;
      if (raw != null) {
        raw.shutdown(SocketDirection.send);
        _disableWriteEvent();
      }
    }
  }

  void set _owner(owner) {
    // Note: _raw can be _RawSocket and _RawSecureSocket.
    (_raw as _RawSocketBase)._owner = owner;
  }
}

@patch
class RawDatagramSocket {
  @patch
  static Future<RawDatagramSocket> bind(host, int port,
      {bool reuseAddress = true, bool reusePort = false, int ttl = 1}) {
    return _RawDatagramSocket.bind(host, port, reuseAddress, reusePort, ttl);
  }
}

class _RawDatagramSocket extends Stream<RawSocketEvent>
    implements RawDatagramSocket {
  _NativeSocket _socket;
  late StreamController<RawSocketEvent> _controller;
  bool _readEventsEnabled = true;
  bool _writeEventsEnabled = true;

  _RawDatagramSocket(this._socket) {
    var zone = Zone.current;
    _controller = new StreamController<RawSocketEvent>(
        sync: true,
        onListen: _onSubscriptionStateChange,
        onCancel: _onSubscriptionStateChange,
        onPause: _onPauseStateChange,
        onResume: _onPauseStateChange);
    _socket.setHandlers(
        read: () => _controller.add(RawSocketEvent.read),
        write: () {
          // The write event handler is automatically disabled by the
          // event handler when it fires.
          writeEventsEnabled = false;
          _controller.add(RawSocketEvent.write);
        },
        closed: () => _controller.add(RawSocketEvent.readClosed),
        destroyed: () {
          _controller.add(RawSocketEvent.closed);
          _controller.close();
        },
        error: zone.bindBinaryCallbackGuarded((Object e, StackTrace? st) {
          _controller.addError(e, st);
          _socket.close();
        }));
  }

  static Future<RawDatagramSocket> bind(
      host, int port, bool reuseAddress, bool reusePort, int ttl) {
    _throwOnBadPort(port);
    _throwOnBadTtl(ttl);
    return _NativeSocket.bindDatagram(host, port, reuseAddress, reusePort, ttl)
        .then((socket) {
      if (!const bool.fromEnvironment("dart.vm.product")) {
        _SocketProfile.collectNewSocket(
            socket.nativeGetSocketId(), _udpSocket, socket.address, port);
      }
      return _RawDatagramSocket(socket);
    });
  }

  StreamSubscription<RawSocketEvent> listen(void onData(RawSocketEvent event)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  Future close() => _socket.close().then<RawDatagramSocket>((_) {
        if (!const bool.fromEnvironment("dart.vm.product")) {
          _SocketProfile.collectStatistic(
              _socket.nativeGetSocketId(), _SocketProfileType.endTime);
        }
        return this;
      });

  int send(List<int> buffer, InternetAddress address, int port) =>
      _socket.send(buffer, 0, buffer.length, address, port);

  Datagram? receive() {
    return _socket.receive();
  }

  void joinMulticast(InternetAddress group, [NetworkInterface? interface]) {
    _socket.joinMulticast(group, interface);
  }

  void leaveMulticast(InternetAddress group, [NetworkInterface? interface]) {
    _socket.leaveMulticast(group, interface);
  }

  bool get readEventsEnabled => _readEventsEnabled;
  void set readEventsEnabled(bool value) {
    if (value != _readEventsEnabled) {
      _readEventsEnabled = value;
      if (!_controller.isPaused) _resume();
    }
  }

  bool get writeEventsEnabled => _writeEventsEnabled;
  void set writeEventsEnabled(bool value) {
    if (value != _writeEventsEnabled) {
      _writeEventsEnabled = value;
      if (!_controller.isPaused) _resume();
    }
  }

  bool get multicastLoopback =>
      _socket.getOption(SocketOption._ipMulticastLoop);
  void set multicastLoopback(bool value) =>
      _socket.setOption(SocketOption._ipMulticastLoop, value);

  int get multicastHops => _socket.getOption(SocketOption._ipMulticastHops);
  void set multicastHops(int value) =>
      _socket.setOption(SocketOption._ipMulticastHops, value);

  NetworkInterface get multicastInterface => throw UnimplementedError();
  void set multicastInterface(NetworkInterface? value) =>
      throw UnimplementedError();

  bool get broadcastEnabled => _socket.getOption(SocketOption._ipBroadcast);
  void set broadcastEnabled(bool value) =>
      _socket.setOption(SocketOption._ipBroadcast, value);

  int get port => _socket.port;

  InternetAddress get address => _socket.address;

  _pause() {
    _socket.setListening(read: false, write: false);
  }

  void _resume() {
    _socket.setListening(read: _readEventsEnabled, write: _writeEventsEnabled);
  }

  void _onPauseStateChange() {
    if (_controller.isPaused) {
      _pause();
    } else {
      _resume();
    }
  }

  void _onSubscriptionStateChange() {
    if (_controller.hasListener) {
      _resume();
    } else {
      _socket.close();
    }
  }

  Uint8List getRawOption(RawSocketOption option) =>
      _socket.getRawOption(option);
  void setRawOption(RawSocketOption option) => _socket.setRawOption(option);
}

@pragma("vm:entry-point", "call")
Datagram _makeDatagram(
    Uint8List data, String address, Uint8List in_addr, int port, int type) {
  return new Datagram(
      data,
      _InternetAddress(InternetAddressType._from(type), address, null, in_addr),
      port);
}

@patch
@pragma("vm:entry-point")
class ResourceHandle {
  @patch
  factory ResourceHandle.fromFile(RandomAccessFile file) {
    int fd = (file as _RandomAccessFile).fd;
    return _ResourceHandleImpl(fd);
  }

  @patch
  factory ResourceHandle.fromSocket(Socket socket) {
    final _socket = socket as _Socket;
    if (_socket._raw == null) {
      throw ArgumentError("Socket is closed");
    }
    final _RawSocket raw = _socket._raw! as _RawSocket;
    final _NativeSocket nativeSocket = raw._socket;
    int fd = nativeSocket.fd;
    return _ResourceHandleImpl(fd);
  }

  @patch
  factory ResourceHandle.fromRawSocket(RawSocket socket) {
    final _RawSocket raw = socket as _RawSocket;
    final _NativeSocket nativeSocket = raw._socket;
    int fd = nativeSocket.fd;
    return _ResourceHandleImpl(fd);
  }

  @patch
  factory ResourceHandle.fromRawDatagramSocket(RawDatagramSocket socket) {
    final _RawDatagramSocket raw = socket as _RawDatagramSocket;
    final _NativeSocket nativeSocket = socket._socket;
    int fd = nativeSocket.fd;
    return _ResourceHandleImpl(fd);
  }

  @patch
  factory ResourceHandle.fromStdin(Stdin stdin) {
    return _ResourceHandleImpl(stdin._fd);
  }

  @patch
  factory ResourceHandle.fromStdout(Stdout stdout) {
    return _ResourceHandleImpl(stdout._fd);
  }

  @patch
  factory ResourceHandle.fromReadPipe(ReadPipe pipe) {
    _ReadPipe rp = pipe as _ReadPipe;
    return ResourceHandle.fromFile(rp._openedFile!);
  }

  @patch
  factory ResourceHandle.fromWritePipe(WritePipe pipe) {
    _WritePipe wp = pipe as _WritePipe;
    return ResourceHandle.fromFile(wp._file);
  }
}

@pragma("vm:entry-point")
class _ResourceHandleImpl implements ResourceHandle {
  bool _toMethodCalled = false;

  @pragma("vm:entry-point")
  int _handle; // file descriptor on linux
  @pragma("vm:entry-point")
  _ResourceHandleImpl(this._handle);

  RandomAccessFile toFile() {
    if (_toMethodCalled) {
      throw StateError('Resource handle has already been used.');
    }
    _toMethodCalled = true;
    return _toFile();
  }

  RawDatagramSocket toRawDatagramSocket() {
    if (_toMethodCalled) {
      throw StateError('Resource handle has already been used.');
    }
    _toMethodCalled = true;
    return _toRawDatagramSocket();
  }

  RawSocket toRawSocket() {
    if (_toMethodCalled) {
      throw StateError('Resource handle has already been used.');
    }
    _toMethodCalled = true;

    List<dynamic> list = _toRawSocket();
    InternetAddressType type = InternetAddressType._from(list[0] as int);
    String hostname = list[1] as String;
    Uint8List rawAddr = list[2] as Uint8List;
    int fd = list[3] as int;
    InternetAddress internetAddress = type == InternetAddressType.unix
        ? _InternetAddress.fromString(hostname, type: InternetAddressType.unix)
        : _InternetAddress(type, hostname, null, rawAddr);
    final nativeSocket = _NativeSocket.normal(internetAddress);
    nativeSocket.nativeSetSocketId(fd, _NativeSocket.typeInternalSocket);
    return _RawSocket(nativeSocket);
  }

  Socket toSocket() {
    if (_toMethodCalled) {
      throw StateError('Resource handle has already been used.');
    }
    _toMethodCalled = true;
    return _toSocket();
  }

  _ReadPipe toReadPipe() {
    return _ReadPipe(toFile());
  }

  _WritePipe toWritePipe() {
    return _WritePipe(toFile());
  }

  @pragma("vm:external-name", "ResourceHandleImpl_toFile")
  external RandomAccessFile _toFile();
  @pragma("vm:external-name", "ResourceHandleImpl_toSocket")
  external Socket _toSocket();
  @pragma("vm:external-name", "ResourceHandleImpl_toRawSocket")
  external List<dynamic> _toRawSocket();
  @pragma("vm:external-name", "ResourceHandleImpl_toRawDatagramSocket")
  external RawDatagramSocket _toRawDatagramSocket();

  @pragma("vm:entry-point")
  static final _ResourceHandleImpl _sentinel = _ResourceHandleImpl(-1);
}

@patch
class SocketControlMessage {
  @pragma("vm:external-name", "SocketControlMessage_fromHandles")
  @patch
  external factory SocketControlMessage.fromHandles(
      List<ResourceHandle> handles);
}

@pragma("vm:entry-point")
class _SocketControlMessageImpl implements SocketControlMessage {
  @pragma("vm:entry-point")
  final int level;
  @pragma("vm:entry-point")
  final int type;
  @pragma("vm:entry-point")
  final Uint8List data;

  @pragma("vm:entry-point")
  _SocketControlMessageImpl(this.level, this.type, this.data);

  @pragma("vm:external-name", "SocketControlMessageImpl_extractHandles")
  external List<ResourceHandle> extractHandles();

  static final _sentinel = _SocketControlMessageImpl(0, 0, Uint8List(0));
}
