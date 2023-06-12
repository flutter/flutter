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
import '../structs.g.dart';
import '../utils.dart';
import '../variant.dart';
import '../win32/ole32.g.dart';
import 'iunknown.dart';

/// @nodoc
const IID_IEnumWbemClassObject = '{027947E1-D731-11CE-A357-000000000001}';

/// {@category Interface}
/// {@category com}
class IEnumWbemClassObject extends IUnknown {
  // vtable begins at 3, is 5 entries long.
  IEnumWbemClassObject(super.ptr);

  factory IEnumWbemClassObject.from(IUnknown interface) =>
      IEnumWbemClassObject(interface.toInterface(IID_IEnumWbemClassObject));

  int reset() => ptr.ref.vtable
      .elementAt(3)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer)>>>()
      .value
      .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);

  int next(int lTimeout, int uCount, Pointer<Pointer<COMObject>> apObjects,
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

  int nextAsync(int uCount, Pointer<COMObject> pSink) => ptr.ref.vtable
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

  int clone(Pointer<Pointer<COMObject>> ppEnum) => ptr.ref.vtable
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

  int skip(int lTimeout, int nCount) =>
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
