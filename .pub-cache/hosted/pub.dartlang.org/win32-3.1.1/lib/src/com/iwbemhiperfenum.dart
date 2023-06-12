// iwbemhiperfenum.dart

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
const IID_IWbemHiPerfEnum = '{2705C288-79AE-11D2-B348-00105A1F8177}';

/// {@category Interface}
/// {@category com}
class IWbemHiPerfEnum extends IUnknown {
  // vtable begins at 3, is 4 entries long.
  IWbemHiPerfEnum(super.ptr);

  factory IWbemHiPerfEnum.from(IUnknown interface) =>
      IWbemHiPerfEnum(interface.toInterface(IID_IWbemHiPerfEnum));

  int addObjects(int lFlags, int uNumObjects, Pointer<Int32> apIds,
          Pointer<Pointer<COMObject>> apObj) =>
      ptr.ref.vtable
              .elementAt(3)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Int32 lFlags,
                              Uint32 uNumObjects,
                              Pointer<Int32> apIds,
                              Pointer<Pointer<COMObject>> apObj)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      int lFlags,
                      int uNumObjects,
                      Pointer<Int32> apIds,
                      Pointer<Pointer<COMObject>> apObj)>()(
          ptr.ref.lpVtbl, lFlags, uNumObjects, apIds, apObj);

  int removeObjects(int lFlags, int uNumObjects, Pointer<Int32> apIds) => ptr
          .ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Int32 lFlags, Uint32 uNumObjects,
                          Pointer<Int32> apIds)>>>()
          .value
          .asFunction<
              int Function(Pointer, int lFlags, int uNumObjects,
                  Pointer<Int32> apIds)>()(
      ptr.ref.lpVtbl, lFlags, uNumObjects, apIds);

  int getObjects(int lFlags, int uNumObjects, Pointer<Pointer<COMObject>> apObj,
          Pointer<Uint32> puReturned) =>
      ptr.ref.vtable
              .elementAt(5)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Int32 lFlags,
                              Uint32 uNumObjects,
                              Pointer<Pointer<COMObject>> apObj,
                              Pointer<Uint32> puReturned)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      int lFlags,
                      int uNumObjects,
                      Pointer<Pointer<COMObject>> apObj,
                      Pointer<Uint32> puReturned)>()(
          ptr.ref.lpVtbl, lFlags, uNumObjects, apObj, puReturned);

  int removeAll(int lFlags) => ptr.ref.vtable
      .elementAt(6)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Int32 lFlags)>>>()
      .value
      .asFunction<int Function(Pointer, int lFlags)>()(ptr.ref.lpVtbl, lFlags);
}
