// ienumwbemclassobject.dart

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

import 'iunknown.dart';

/// @nodoc
const IID_IEnumWbemClassObject = '{027947E1-D731-11CE-A357-000000000001}';

/// {@category Interface}
/// {@category com}
class IEnumWbemClassObject extends IUnknown {
  // vtable begins at 3, is 5 entries long.
  IEnumWbemClassObject(super.ptr);

  int Reset() => ptr.ref.vtable
      .elementAt(3)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer)>>>()
      .value
      .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);

  int Next(int lTimeout, int uCount, Pointer<Pointer<COMObject>> apObjects,
          Pointer<Uint32> puReturned) =>
      ptr.ref.vtable
              .elementAt(4)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Int32 lTimeout,
                              Uint32 uCount,
                              Pointer<Pointer<COMObject>> apObjects,
                              Pointer<Uint32> puReturned)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      int lTimeout,
                      int uCount,
                      Pointer<Pointer<COMObject>> apObjects,
                      Pointer<Uint32> puReturned)>()(
          ptr.ref.lpVtbl, lTimeout, uCount, apObjects, puReturned);

  int NextAsync(int uCount, Pointer<COMObject> pSink) => ptr.ref.vtable
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Uint32 uCount, Pointer<COMObject> pSink)>>>()
          .value
          .asFunction<
              int Function(Pointer, int uCount, Pointer<COMObject> pSink)>()(
      ptr.ref.lpVtbl, uCount, pSink);

  int Clone(Pointer<Pointer<COMObject>> ppEnum) => ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<COMObject>> ppEnum)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<COMObject>> ppEnum)>()(
      ptr.ref.lpVtbl, ppEnum);

  int Skip(int lTimeout, int nCount) =>
      ptr.ref.vtable
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Int32 lTimeout, Uint32 nCount)>>>()
              .value
              .asFunction<int Function(Pointer, int lTimeout, int nCount)>()(
          ptr.ref.lpVtbl, lTimeout, nCount);
}
