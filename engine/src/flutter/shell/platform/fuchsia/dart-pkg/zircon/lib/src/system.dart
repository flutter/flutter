// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of zircon;

// ignore_for_file: native_function_body_in_non_sdk_code
// ignore_for_file: public_member_api_docs

@pragma('vm:entry-point')
class _Namespace {
  // No public constructor - this only has static methods.
  _Namespace._();

  // Library private variable set by the embedder used to cache the
  // namespace (as an fdio_ns_t*).
  @pragma('vm:entry-point')
  static int? _namespace;
}

/// An exception representing an error returned as an zx_status_t.
class ZxStatusException implements Exception {
  final String? message;
  final int status;

  ZxStatusException(this.status, [this.message]);

  @override
  String toString() {
    if (message == null)
      return 'ZxStatusException: status = $status';
    else
      return 'ZxStatusException: status = $status, "$message"';
  }
}

/// Users of the [_Result] subclasses should check the status before
/// trying to read any data. Attempting to use a value stored in a result
/// when the status in not OK will result in an exception.
class _Result {
  final int status;
  const _Result(this.status);
}

@pragma('vm:entry-point')
class HandleResult extends _Result {
  final Handle? _handle;
  Handle get handle => _handle!;

  @pragma('vm:entry-point')
  const HandleResult(final int status, [this._handle]) : super(status);
  @override
  String toString() => 'HandleResult(status=$status, handle=$_handle)';
}

@pragma('vm:entry-point')
class HandlePairResult extends _Result {
  final Handle? _first;
  final Handle? _second;

  Handle get first => _first!;
  Handle get second => _second!;

  @pragma('vm:entry-point')
  const HandlePairResult(final int status, [this._first, this._second])
      : super(status);
  @override
  String toString() =>
      'HandlePairResult(status=$status, first=$_first, second=$_second)';
}

@pragma('vm:entry-point')
class ReadResult extends _Result {
  final ByteData? _bytes;
  final int? _numBytes;
  final List<Handle>? _handles;

  ByteData get bytes => _bytes!;
  int get numBytes => _numBytes!;
  List<Handle> get handles => _handles!;

  @pragma('vm:entry-point')
  const ReadResult(final int status, [this._bytes, this._numBytes, this._handles])
      : super(status);

  /// Returns the bytes as a Uint8List. If status != OK this will throw
  /// an exception.
  Uint8List bytesAsUint8List() {
    return _bytes!.buffer.asUint8List(_bytes!.offsetInBytes, _numBytes!);
  }

  /// Returns the bytes as a String. If status != OK this will throw
  /// an exception.
  String bytesAsUTF8String() => utf8.decode(bytesAsUint8List());

  @override
  String toString() =>
      'ReadResult(status=$status, bytes=$_bytes, numBytes=$_numBytes, handles=$_handles)';
}

@pragma('vm:entry-point')
class HandleInfo {
  final Handle handle;
  final int type;
  final int rights;

  @pragma('vm:entry-point')
  const HandleInfo(this.handle, this.type, this.rights);

  @override
  String toString() =>
      'HandleInfo(handle=$handle, type=$type, rights=$rights)';
}

@pragma('vm:entry-point')
class ReadEtcResult extends _Result {
  final ByteData? _bytes;
  final int? _numBytes;
  final List<HandleInfo>? _handleInfos;

  ByteData get bytes => _bytes!;
  int get numBytes => _numBytes!;
  List<HandleInfo> get handleInfos => _handleInfos!;

  @pragma('vm:entry-point')
  const ReadEtcResult(final int status, [this._bytes, this._numBytes, this._handleInfos])
      : super(status);

  /// Returns the bytes as a Uint8List. If status != OK this will throw
  /// an exception.
  Uint8List bytesAsUint8List() {
    return _bytes!.buffer.asUint8List(_bytes!.offsetInBytes, _numBytes!);
  }

  /// Returns the bytes as a String. If status != OK this will throw
  /// an exception.
  String bytesAsUTF8String() => utf8.decode(bytesAsUint8List());

  @override
  String toString() =>
      'ReadEtcResult(status=$status, bytes=$_bytes, numBytes=$_numBytes, handleInfos=$_handleInfos)';
}

@pragma('vm:entry-point')
class WriteResult extends _Result {
  final int? _numBytes;
  int get numBytes => _numBytes!;

  @pragma('vm:entry-point')
  const WriteResult(final int status, [this._numBytes]) : super(status);
  @override
  String toString() => 'WriteResult(status=$status, numBytes=$_numBytes)';
}

@pragma('vm:entry-point')
class GetSizeResult extends _Result {
  final int? _size;
  int get size => _size!;

  @pragma('vm:entry-point')
  const GetSizeResult(final int status, [this._size]) : super(status);
  @override
  String toString() => 'GetSizeResult(status=$status, size=$_size)';
}

@pragma('vm:entry-point')
class FromFileResult extends _Result {
  final Handle? _handle;
  final int? _numBytes;

  Handle get handle => _handle!;
  int get numBytes => _numBytes!;

  @pragma('vm:entry-point')
  const FromFileResult(final int status, [this._handle, this._numBytes])
      : super(status);
  @override
  String toString() =>
      'FromFileResult(status=$status, handle=$_handle, numBytes=$_numBytes)';
}

@pragma('vm:entry-point')
class MapResult extends _Result {
  final Uint8List? _data;
  Uint8List get data => _data!;

  @pragma('vm:entry-point')
  const MapResult(final int status, [this._data]) : super(status);
  @override
  String toString() => 'MapResult(status=$status, data=$_data)';
}

@pragma('vm:entry-point')
class System extends NativeFieldWrapperClass1 {
  // No public constructor - this only has static methods.
  System._();

  // Channel operations.
  static HandlePairResult channelCreate([int options = 0])
      native 'System_ChannelCreate';
  static HandleResult channelFromFile(String path)
      native 'System_ChannelFromFile';
  static int connectToService(String path, Handle channel)
    native 'System_ConnectToService';
  static int channelWrite(Handle channel, ByteData data, List<Handle> handles)
      native 'System_ChannelWrite';
  static int channelWriteEtc(Handle channel, ByteData data, List<HandleDisposition> handleDispositions)
      native 'System_ChannelWriteEtc';
  static ReadResult channelQueryAndRead(Handle channel)
      native 'System_ChannelQueryAndRead';
  static ReadEtcResult channelQueryAndReadEtc(Handle channel)
      native 'System_ChannelQueryAndReadEtc';

  // Eventpair operations.
  static HandlePairResult eventpairCreate([int options = 0])
      native 'System_EventpairCreate';

  // Socket operations.
  static HandlePairResult socketCreate([int options = 0])
      native 'System_SocketCreate';
  static WriteResult socketWrite(Handle socket, ByteData data, int options)
      native 'System_SocketWrite';
  static ReadResult socketRead(Handle socket, int size)
      native 'System_SocketRead';

  // Vmo operations.
  static HandleResult vmoCreate(int size, [int options = 0])
      native 'System_VmoCreate';
  static FromFileResult vmoFromFile(String path) native 'System_VmoFromFile';
  static GetSizeResult vmoGetSize(Handle vmo) native 'System_VmoGetSize';
  static int vmoSetSize(Handle vmo, int size) native 'System_VmoSetSize';
  static int vmoWrite(Handle vmo, int offset, ByteData bytes)
      native 'System_VmoWrite';
  static ReadResult vmoRead(Handle vmo, int offset, int size)
      native 'System_VmoRead';
  static MapResult vmoMap(Handle vmo) native 'System_VmoMap';

  // Time operations.
  static int clockGetMonotonic() {
    if (zirconFFIBindings == null) {
      return _nativeClockGetMonotonic();
    } else {
      return zirconFFIBindings!.zircon_dart_clock_get_monotonic();
    }
  }

  static int _nativeClockGetMonotonic() native 'System_ClockGetMonotonic';

  // TODO(edcoyne): Remove this, it is required to safely do an API transition across repos.
  static int reboot() { return -2; /*ZX_ERR_NOT_SUPPORTED*/ }
}
