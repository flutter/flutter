// ishellfolder.dart

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
const IID_IShellFolder = '{000214E6-0000-0000-C000-000000000046}';

/// {@category Interface}
/// {@category com}
class IShellFolder extends IUnknown {
  // vtable begins at 3, is 10 entries long.
  IShellFolder(super.ptr);

  factory IShellFolder.from(IUnknown interface) =>
      IShellFolder(interface.toInterface(IID_IShellFolder));

  int parseDisplayName(
          int hwnd,
          Pointer<COMObject> pbc,
          Pointer<Utf16> pszDisplayName,
          Pointer<Uint32> pchEaten,
          Pointer<Pointer<ITEMIDLIST>> ppidl,
          Pointer<Uint32> pdwAttributes) =>
      ptr.ref.vtable
              .elementAt(3)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              IntPtr hwnd,
                              Pointer<COMObject> pbc,
                              Pointer<Utf16> pszDisplayName,
                              Pointer<Uint32> pchEaten,
                              Pointer<Pointer<ITEMIDLIST>> ppidl,
                              Pointer<Uint32> pdwAttributes)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      int hwnd,
                      Pointer<COMObject> pbc,
                      Pointer<Utf16> pszDisplayName,
                      Pointer<Uint32> pchEaten,
                      Pointer<Pointer<ITEMIDLIST>> ppidl,
                      Pointer<Uint32> pdwAttributes)>()(ptr.ref.lpVtbl, hwnd,
          pbc, pszDisplayName, pchEaten, ppidl, pdwAttributes);

  int enumObjects(
          int hwnd, int grfFlags, Pointer<Pointer<COMObject>> ppenumIDList) =>
      ptr.ref.vtable
              .elementAt(4)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, IntPtr hwnd, Uint32 grfFlags,
                              Pointer<Pointer<COMObject>> ppenumIDList)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int hwnd, int grfFlags,
                      Pointer<Pointer<COMObject>> ppenumIDList)>()(
          ptr.ref.lpVtbl, hwnd, grfFlags, ppenumIDList);

  int bindToObject(Pointer<ITEMIDLIST> pidl, Pointer<COMObject> pbc,
          Pointer<GUID> riid, Pointer<Pointer> ppv) =>
      ptr.ref.vtable
              .elementAt(5)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<ITEMIDLIST> pidl,
                              Pointer<COMObject> pbc,
                              Pointer<GUID> riid,
                              Pointer<Pointer> ppv)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<ITEMIDLIST> pidl,
                      Pointer<COMObject> pbc,
                      Pointer<GUID> riid,
                      Pointer<Pointer> ppv)>()(
          ptr.ref.lpVtbl, pidl, pbc, riid, ppv);

  int bindToStorage(Pointer<ITEMIDLIST> pidl, Pointer<COMObject> pbc,
          Pointer<GUID> riid, Pointer<Pointer> ppv) =>
      ptr.ref.vtable
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<ITEMIDLIST> pidl,
                              Pointer<COMObject> pbc,
                              Pointer<GUID> riid,
                              Pointer<Pointer> ppv)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<ITEMIDLIST> pidl,
                      Pointer<COMObject> pbc,
                      Pointer<GUID> riid,
                      Pointer<Pointer> ppv)>()(
          ptr.ref.lpVtbl, pidl, pbc, riid, ppv);

  int compareIDs(
          int lParam, Pointer<ITEMIDLIST> pidl1, Pointer<ITEMIDLIST> pidl2) =>
      ptr.ref.vtable
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              IntPtr lParam,
                              Pointer<ITEMIDLIST> pidl1,
                              Pointer<ITEMIDLIST> pidl2)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int lParam, Pointer<ITEMIDLIST> pidl1,
                      Pointer<ITEMIDLIST> pidl2)>()(
          ptr.ref.lpVtbl, lParam, pidl1, pidl2);

  int createViewObject(
          int hwndOwner, Pointer<GUID> riid, Pointer<Pointer> ppv) =>
      ptr.ref.vtable
              .elementAt(8)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, IntPtr hwndOwner,
                              Pointer<GUID> riid, Pointer<Pointer> ppv)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int hwndOwner, Pointer<GUID> riid,
                      Pointer<Pointer> ppv)>()(
          ptr.ref.lpVtbl, hwndOwner, riid, ppv);

  int getAttributesOf(int cidl, Pointer<Pointer<ITEMIDLIST>> apidl,
          Pointer<Uint32> rgfInOut) =>
      ptr.ref.vtable
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Uint32 cidl,
                              Pointer<Pointer<ITEMIDLIST>> apidl,
                              Pointer<Uint32> rgfInOut)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      int cidl,
                      Pointer<Pointer<ITEMIDLIST>> apidl,
                      Pointer<Uint32> rgfInOut)>()(
          ptr.ref.lpVtbl, cidl, apidl, rgfInOut);

  int getUIObjectOf(
          int hwndOwner,
          int cidl,
          Pointer<Pointer<ITEMIDLIST>> apidl,
          Pointer<GUID> riid,
          Pointer<Uint32> rgfReserved,
          Pointer<Pointer> ppv) =>
      ptr.ref.vtable
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              IntPtr hwndOwner,
                              Uint32 cidl,
                              Pointer<Pointer<ITEMIDLIST>> apidl,
                              Pointer<GUID> riid,
                              Pointer<Uint32> rgfReserved,
                              Pointer<Pointer> ppv)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      int hwndOwner,
                      int cidl,
                      Pointer<Pointer<ITEMIDLIST>> apidl,
                      Pointer<GUID> riid,
                      Pointer<Uint32> rgfReserved,
                      Pointer<Pointer> ppv)>()(
          ptr.ref.lpVtbl, hwndOwner, cidl, apidl, riid, rgfReserved, ppv);

  int getDisplayNameOf(
          Pointer<ITEMIDLIST> pidl, int uFlags, Pointer<STRRET> pName) =>
      ptr.ref.vtable
              .elementAt(11)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<ITEMIDLIST> pidl,
                              Uint32 uFlags, Pointer<STRRET> pName)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<ITEMIDLIST> pidl, int uFlags,
                      Pointer<STRRET> pName)>()(
          ptr.ref.lpVtbl, pidl, uFlags, pName);

  int setNameOf(int hwnd, Pointer<ITEMIDLIST> pidl, Pointer<Utf16> pszName,
          int uFlags, Pointer<Pointer<ITEMIDLIST>> ppidlOut) =>
      ptr.ref.vtable
              .elementAt(12)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              IntPtr hwnd,
                              Pointer<ITEMIDLIST> pidl,
                              Pointer<Utf16> pszName,
                              Uint32 uFlags,
                              Pointer<Pointer<ITEMIDLIST>> ppidlOut)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      int hwnd,
                      Pointer<ITEMIDLIST> pidl,
                      Pointer<Utf16> pszName,
                      int uFlags,
                      Pointer<Pointer<ITEMIDLIST>> ppidlOut)>()(
          ptr.ref.lpVtbl, hwnd, pidl, pszName, uFlags, ppidlOut);
}
