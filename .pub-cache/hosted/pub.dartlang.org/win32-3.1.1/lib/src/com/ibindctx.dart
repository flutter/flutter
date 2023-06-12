// ibindctx.dart

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
const IID_IBindCtx = '{0000000E-0000-0000-C000-000000000046}';

/// {@category Interface}
/// {@category com}
class IBindCtx extends IUnknown {
  // vtable begins at 3, is 10 entries long.
  IBindCtx(super.ptr);

  factory IBindCtx.from(IUnknown interface) =>
      IBindCtx(interface.toInterface(IID_IBindCtx));

  int registerObjectBound(Pointer<COMObject> punk) => ptr.ref.vtable
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<COMObject> punk)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<COMObject> punk)>()(
      ptr.ref.lpVtbl, punk);

  int revokeObjectBound(Pointer<COMObject> punk) => ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<COMObject> punk)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<COMObject> punk)>()(
      ptr.ref.lpVtbl, punk);

  int releaseBoundObjects() => ptr.ref.vtable
      .elementAt(5)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer)>>>()
      .value
      .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);

  int setBindOptions(Pointer<BIND_OPTS> pbindopts) => ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<BIND_OPTS> pbindopts)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<BIND_OPTS> pbindopts)>()(
      ptr.ref.lpVtbl, pbindopts);

  int getBindOptions(Pointer<BIND_OPTS> pbindopts) => ptr.ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<BIND_OPTS> pbindopts)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<BIND_OPTS> pbindopts)>()(
      ptr.ref.lpVtbl, pbindopts);

  int getRunningObjectTable(Pointer<Pointer<COMObject>> pprot) => ptr.ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<COMObject>> pprot)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<COMObject>> pprot)>()(
      ptr.ref.lpVtbl, pprot);

  int registerObjectParam(Pointer<Utf16> pszKey, Pointer<COMObject> punk) =>
      ptr.ref.vtable
          .elementAt(9)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Utf16> pszKey,
                          Pointer<COMObject> punk)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Utf16> pszKey,
                  Pointer<COMObject> punk)>()(ptr.ref.lpVtbl, pszKey, punk);

  int getObjectParam(
          Pointer<Utf16> pszKey, Pointer<Pointer<COMObject>> ppunk) =>
      ptr.ref.vtable
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<Utf16> pszKey,
                              Pointer<Pointer<COMObject>> ppunk)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Utf16> pszKey,
                      Pointer<Pointer<COMObject>> ppunk)>()(
          ptr.ref.lpVtbl, pszKey, ppunk);

  int enumObjectParam(Pointer<Pointer<COMObject>> ppenum) => ptr.ref.vtable
          .elementAt(11)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<COMObject>> ppenum)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<COMObject>> ppenum)>()(
      ptr.ref.lpVtbl, ppenum);

  int revokeObjectParam(Pointer<Utf16> pszKey) => ptr.ref.vtable
      .elementAt(12)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<Utf16> pszKey)>>>()
      .value
      .asFunction<
          int Function(
              Pointer, Pointer<Utf16> pszKey)>()(ptr.ref.lpVtbl, pszKey);
}
