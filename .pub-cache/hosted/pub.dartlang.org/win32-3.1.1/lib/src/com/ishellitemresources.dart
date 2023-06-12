// ishellitemresources.dart

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
const IID_IShellItemResources = '{FF5693BE-2CE0-4D48-B5C5-40817D1ACDB9}';

/// {@category Interface}
/// {@category com}
class IShellItemResources extends IUnknown {
  // vtable begins at 3, is 10 entries long.
  IShellItemResources(super.ptr);

  factory IShellItemResources.from(IUnknown interface) =>
      IShellItemResources(interface.toInterface(IID_IShellItemResources));

  int getAttributes(Pointer<Uint32> pdwAttributes) => ptr.ref.vtable
      .elementAt(3)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<Uint32> pdwAttributes)>>>()
      .value
      .asFunction<
          int Function(Pointer,
              Pointer<Uint32> pdwAttributes)>()(ptr.ref.lpVtbl, pdwAttributes);

  int getSize(Pointer<Uint64> pullSize) => ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Uint64> pullSize)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Uint64> pullSize)>()(
      ptr.ref.lpVtbl, pullSize);

  int getTimes(Pointer<FILETIME> pftCreation, Pointer<FILETIME> pftWrite,
          Pointer<FILETIME> pftAccess) =>
      ptr.ref.vtable
              .elementAt(5)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<FILETIME> pftCreation,
                              Pointer<FILETIME> pftWrite,
                              Pointer<FILETIME> pftAccess)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<FILETIME> pftCreation,
                      Pointer<FILETIME> pftWrite,
                      Pointer<FILETIME> pftAccess)>()(
          ptr.ref.lpVtbl, pftCreation, pftWrite, pftAccess);

  int setTimes(Pointer<FILETIME> pftCreation, Pointer<FILETIME> pftWrite,
          Pointer<FILETIME> pftAccess) =>
      ptr.ref.vtable
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<FILETIME> pftCreation,
                              Pointer<FILETIME> pftWrite,
                              Pointer<FILETIME> pftAccess)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<FILETIME> pftCreation,
                      Pointer<FILETIME> pftWrite,
                      Pointer<FILETIME> pftAccess)>()(
          ptr.ref.lpVtbl, pftCreation, pftWrite, pftAccess);

  int getResourceDescription(Pointer<SHELL_ITEM_RESOURCE> pcsir,
          Pointer<Pointer<Utf16>> ppszDescription) =>
      ptr.ref.vtable
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<SHELL_ITEM_RESOURCE> pcsir,
                              Pointer<Pointer<Utf16>> ppszDescription)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<SHELL_ITEM_RESOURCE> pcsir,
                      Pointer<Pointer<Utf16>> ppszDescription)>()(
          ptr.ref.lpVtbl, pcsir, ppszDescription);

  int enumResources(Pointer<Pointer<COMObject>> ppenumr) => ptr.ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<COMObject>> ppenumr)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<COMObject>> ppenumr)>()(
      ptr.ref.lpVtbl, ppenumr);

  int supportsResource(Pointer<SHELL_ITEM_RESOURCE> pcsir) => ptr.ref.vtable
          .elementAt(9)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<SHELL_ITEM_RESOURCE> pcsir)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<SHELL_ITEM_RESOURCE> pcsir)>()(
      ptr.ref.lpVtbl, pcsir);

  int openResource(Pointer<SHELL_ITEM_RESOURCE> pcsir, Pointer<GUID> riid,
          Pointer<Pointer> ppv) =>
      ptr.ref.vtable
          .elementAt(10)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer,
                          Pointer<SHELL_ITEM_RESOURCE> pcsir,
                          Pointer<GUID> riid,
                          Pointer<Pointer> ppv)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer,
                  Pointer<SHELL_ITEM_RESOURCE> pcsir,
                  Pointer<GUID> riid,
                  Pointer<Pointer> ppv)>()(ptr.ref.lpVtbl, pcsir, riid, ppv);

  int createResource(Pointer<SHELL_ITEM_RESOURCE> pcsir, Pointer<GUID> riid,
          Pointer<Pointer> ppv) =>
      ptr.ref.vtable
          .elementAt(11)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer,
                          Pointer<SHELL_ITEM_RESOURCE> pcsir,
                          Pointer<GUID> riid,
                          Pointer<Pointer> ppv)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer,
                  Pointer<SHELL_ITEM_RESOURCE> pcsir,
                  Pointer<GUID> riid,
                  Pointer<Pointer> ppv)>()(ptr.ref.lpVtbl, pcsir, riid, ppv);

  int markForDelete() => ptr.ref.vtable
      .elementAt(12)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer)>>>()
      .value
      .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);
}
