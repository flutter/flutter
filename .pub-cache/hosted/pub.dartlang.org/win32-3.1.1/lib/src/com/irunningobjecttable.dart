// irunningobjecttable.dart

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
const IID_IRunningObjectTable = '{00000010-0000-0000-C000-000000000046}';

/// {@category Interface}
/// {@category com}
class IRunningObjectTable extends IUnknown {
  // vtable begins at 3, is 7 entries long.
  IRunningObjectTable(super.ptr);

  factory IRunningObjectTable.from(IUnknown interface) =>
      IRunningObjectTable(interface.toInterface(IID_IRunningObjectTable));

  int register(int grfFlags, Pointer<COMObject> punkObject,
          Pointer<COMObject> pmkObjectName, Pointer<Uint32> pdwRegister) =>
      ptr.ref.vtable
              .elementAt(3)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Uint32 grfFlags,
                              Pointer<COMObject> punkObject,
                              Pointer<COMObject> pmkObjectName,
                              Pointer<Uint32> pdwRegister)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      int grfFlags,
                      Pointer<COMObject> punkObject,
                      Pointer<COMObject> pmkObjectName,
                      Pointer<Uint32> pdwRegister)>()(
          ptr.ref.lpVtbl, grfFlags, punkObject, pmkObjectName, pdwRegister);

  int revoke(int dwRegister) => ptr.ref.vtable
      .elementAt(4)
      .cast<
          Pointer<NativeFunction<Int32 Function(Pointer, Uint32 dwRegister)>>>()
      .value
      .asFunction<
          int Function(Pointer, int dwRegister)>()(ptr.ref.lpVtbl, dwRegister);

  int isRunning(Pointer<COMObject> pmkObjectName) =>
      ptr.ref.vtable
              .elementAt(5)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Pointer<COMObject> pmkObjectName)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<COMObject> pmkObjectName)>()(
          ptr.ref.lpVtbl, pmkObjectName);

  int
      getObject(Pointer<COMObject> pmkObjectName,
              Pointer<Pointer<COMObject>> ppunkObject) =>
          ptr.ref.vtable
                  .elementAt(6)
                  .cast<
                      Pointer<
                          NativeFunction<
                              Int32 Function(
                                  Pointer,
                                  Pointer<COMObject> pmkObjectName,
                                  Pointer<Pointer<COMObject>> ppunkObject)>>>()
                  .value
                  .asFunction<
                      int Function(Pointer, Pointer<COMObject> pmkObjectName,
                          Pointer<Pointer<COMObject>> ppunkObject)>()(
              ptr.ref.lpVtbl, pmkObjectName, ppunkObject);

  int noteChangeTime(int dwRegister, Pointer<FILETIME> pfiletime) =>
      ptr.ref.vtable
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Uint32 dwRegister,
                              Pointer<FILETIME> pfiletime)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, int dwRegister, Pointer<FILETIME> pfiletime)>()(
          ptr.ref.lpVtbl, dwRegister, pfiletime);

  int getTimeOfLastChange(
          Pointer<COMObject> pmkObjectName, Pointer<FILETIME> pfiletime) =>
      ptr.ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<COMObject> pmkObjectName,
                          Pointer<FILETIME> pfiletime)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer,
                  Pointer<COMObject> pmkObjectName,
                  Pointer<FILETIME>
                      pfiletime)>()(ptr.ref.lpVtbl, pmkObjectName, pfiletime);

  int enumRunning(Pointer<Pointer<COMObject>> ppenumMoniker) => ptr.ref.vtable
          .elementAt(9)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer,
                          Pointer<Pointer<COMObject>> ppenumMoniker)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Pointer<COMObject>> ppenumMoniker)>()(
      ptr.ref.lpVtbl, ppenumMoniker);
}
