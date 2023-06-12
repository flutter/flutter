// ishellitem.dart

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
const IID_IShellItem = '{43826D1E-E718-42EE-BC55-A1E261C37BFE}';

/// {@category Interface}
/// {@category com}
class IShellItem extends IUnknown {
  // vtable begins at 3, is 5 entries long.
  IShellItem(super.ptr);

  factory IShellItem.from(IUnknown interface) =>
      IShellItem(interface.toInterface(IID_IShellItem));

  int bindToHandler(Pointer<COMObject> pbc, Pointer<GUID> bhid,
          Pointer<GUID> riid, Pointer<Pointer> ppv) =>
      ptr.ref.vtable
              .elementAt(3)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<COMObject> pbc,
                              Pointer<GUID> bhid,
                              Pointer<GUID> riid,
                              Pointer<Pointer> ppv)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<COMObject> pbc,
                      Pointer<GUID> bhid,
                      Pointer<GUID> riid,
                      Pointer<Pointer> ppv)>()(
          ptr.ref.lpVtbl, pbc, bhid, riid, ppv);

  int getParent(Pointer<Pointer<COMObject>> ppsi) => ptr.ref.vtable
      .elementAt(4)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<Pointer<COMObject>> ppsi)>>>()
      .value
      .asFunction<
          int Function(Pointer,
              Pointer<Pointer<COMObject>> ppsi)>()(ptr.ref.lpVtbl, ppsi);

  int getDisplayName(int sigdnName, Pointer<Pointer<Utf16>> ppszName) => ptr
          .ref.vtable
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Int32 sigdnName,
                          Pointer<Pointer<Utf16>> ppszName)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, int sigdnName, Pointer<Pointer<Utf16>> ppszName)>()(
      ptr.ref.lpVtbl, sigdnName, ppszName);

  int getAttributes(int sfgaoMask, Pointer<Uint32> psfgaoAttribs) =>
      ptr.ref.vtable
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Uint32 sfgaoMask,
                              Pointer<Uint32> psfgaoAttribs)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, int sfgaoMask, Pointer<Uint32> psfgaoAttribs)>()(
          ptr.ref.lpVtbl, sfgaoMask, psfgaoAttribs);

  int compare(Pointer<COMObject> psi, int hint, Pointer<Int32> piOrder) => ptr
      .ref.vtable
      .elementAt(7)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<COMObject> psi, Uint32 hint,
                      Pointer<Int32> piOrder)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<COMObject> psi, int hint,
              Pointer<Int32> piOrder)>()(ptr.ref.lpVtbl, psi, hint, piOrder);
}

/// @nodoc
const CLSID_ShellItem = '{9AC9FBE1-E0A2-4AD6-B4EE-E212013EA917}';

/// {@category com}
class ShellItem extends IShellItem {
  ShellItem(super.ptr);

  factory ShellItem.createInstance() =>
      ShellItem(COMObject.createFromID(CLSID_ShellItem, IID_IShellItem));
}
