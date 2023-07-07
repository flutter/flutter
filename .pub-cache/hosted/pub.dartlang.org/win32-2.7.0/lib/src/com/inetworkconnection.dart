// inetworkconnection.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../callbacks.dart';
import '../combase.dart';
import '../constants.dart';
import '../exceptions.dart';
import '../guid.dart';
import '../macros.dart';
import '../ole32.dart';
import '../structs.dart';
import '../structs.g.dart';
import '../utils.dart';

import 'idispatch.dart';

/// @nodoc
const IID_INetworkConnection = '{DCB00005-570F-4A9B-8D69-199FDBA5723B}';

/// {@category Interface}
/// {@category com}
class INetworkConnection extends IDispatch {
  // vtable begins at 7, is 7 entries long.
  INetworkConnection(super.ptr);

  int GetNetwork(Pointer<Pointer<COMObject>> ppNetwork) => ptr.ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<COMObject>> ppNetwork)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<COMObject>> ppNetwork)>()(
      ptr.ref.lpVtbl, ppNetwork);

  int get IsConnectedToInternet {
    final retValuePtr = calloc<Int16>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Int16> pbIsConnected)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<Int16> pbIsConnected)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int get IsConnected {
    final retValuePtr = calloc<Int16>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(9)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Int16> pbIsConnected)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<Int16> pbIsConnected)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int GetConnectivity(Pointer<Int32> pConnectivity) => ptr.ref.vtable
          .elementAt(10)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Int32> pConnectivity)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Int32> pConnectivity)>()(
      ptr.ref.lpVtbl, pConnectivity);

  int GetConnectionId(Pointer<GUID> pgdConnectionId) =>
      ptr.ref.vtable
              .elementAt(11)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Pointer<GUID> pgdConnectionId)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<GUID> pgdConnectionId)>()(
          ptr.ref.lpVtbl, pgdConnectionId);

  int GetAdapterId(Pointer<GUID> pgdAdapterId) => ptr.ref.vtable
          .elementAt(12)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<GUID> pgdAdapterId)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<GUID> pgdAdapterId)>()(
      ptr.ref.lpVtbl, pgdAdapterId);

  int GetDomainType(Pointer<Int32> pDomainType) => ptr.ref.vtable
          .elementAt(13)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Int32> pDomainType)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Int32> pDomainType)>()(
      ptr.ref.lpVtbl, pDomainType);
}
