// ienumnetworkconnections.dart

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
const IID_IEnumNetworkConnections = '{DCB00006-570F-4A9B-8D69-199FDBA5723B}';

/// {@category Interface}
/// {@category com}
class IEnumNetworkConnections extends IDispatch {
  // vtable begins at 7, is 5 entries long.
  IEnumNetworkConnections(super.ptr);

  Pointer<COMObject> get NewEnum {
    final retValuePtr = calloc<Pointer<COMObject>>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer,
                              Pointer<Pointer<COMObject>> ppEnumVar)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, Pointer<Pointer<COMObject>> ppEnumVar)>()(
          ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int Next(int celt, Pointer<Pointer<COMObject>> rgelt,
          Pointer<Uint32> pceltFetched) =>
      ptr.ref.vtable
              .elementAt(8)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Uint32 celt,
                              Pointer<Pointer<COMObject>> rgelt,
                              Pointer<Uint32> pceltFetched)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      int celt,
                      Pointer<Pointer<COMObject>> rgelt,
                      Pointer<Uint32> pceltFetched)>()(
          ptr.ref.lpVtbl, celt, rgelt, pceltFetched);

  int Skip(int celt) => ptr.ref.vtable
      .elementAt(9)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Uint32 celt)>>>()
      .value
      .asFunction<int Function(Pointer, int celt)>()(ptr.ref.lpVtbl, celt);

  int Reset() => ptr.ref.vtable
      .elementAt(10)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer)>>>()
      .value
      .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);

  int Clone(Pointer<Pointer<COMObject>> ppEnumNetwork) => ptr.ref.vtable
          .elementAt(11)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer,
                          Pointer<Pointer<COMObject>> ppEnumNetwork)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Pointer<COMObject>> ppEnumNetwork)>()(
      ptr.ref.lpVtbl, ppEnumNetwork);
}
