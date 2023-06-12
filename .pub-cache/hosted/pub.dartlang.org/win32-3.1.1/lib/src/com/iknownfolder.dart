// iknownfolder.dart

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
const IID_IKnownFolder = '{3AA7AF7E-9B36-420C-A8E3-F77D4674A488}';

/// {@category Interface}
/// {@category com}
class IKnownFolder extends IUnknown {
  // vtable begins at 3, is 9 entries long.
  IKnownFolder(super.ptr);

  factory IKnownFolder.from(IUnknown interface) =>
      IKnownFolder(interface.toInterface(IID_IKnownFolder));

  int getId(Pointer<GUID> pkfid) => ptr.ref.vtable
      .elementAt(3)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<GUID> pkfid)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<GUID> pkfid)>()(ptr.ref.lpVtbl, pkfid);

  int getCategory(Pointer<Int32> pCategory) => ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Int32> pCategory)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Int32> pCategory)>()(
      ptr.ref.lpVtbl, pCategory);

  int getShellItem(int dwFlags, Pointer<GUID> riid, Pointer<Pointer> ppv) =>
      ptr.ref.vtable
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Uint32 dwFlags,
                          Pointer<GUID> riid, Pointer<Pointer> ppv)>>>()
          .value
          .asFunction<
              int Function(Pointer, int dwFlags, Pointer<GUID> riid,
                  Pointer<Pointer> ppv)>()(ptr.ref.lpVtbl, dwFlags, riid, ppv);

  int getPath(int dwFlags, Pointer<Pointer<Utf16>> ppszPath) => ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Uint32 dwFlags,
                          Pointer<Pointer<Utf16>> ppszPath)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, int dwFlags, Pointer<Pointer<Utf16>> ppszPath)>()(
      ptr.ref.lpVtbl, dwFlags, ppszPath);

  int setPath(int dwFlags, Pointer<Utf16> pszPath) => ptr.ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Uint32 dwFlags, Pointer<Utf16> pszPath)>>>()
          .value
          .asFunction<
              int Function(Pointer, int dwFlags, Pointer<Utf16> pszPath)>()(
      ptr.ref.lpVtbl, dwFlags, pszPath);

  int getIDList(int dwFlags, Pointer<Pointer<ITEMIDLIST>> ppidl) => ptr
          .ref.vtable
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Uint32 dwFlags,
                          Pointer<Pointer<ITEMIDLIST>> ppidl)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, int dwFlags, Pointer<Pointer<ITEMIDLIST>> ppidl)>()(
      ptr.ref.lpVtbl, dwFlags, ppidl);

  int getFolderType(Pointer<GUID> pftid) => ptr.ref.vtable
      .elementAt(9)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<GUID> pftid)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<GUID> pftid)>()(ptr.ref.lpVtbl, pftid);

  int getRedirectionCapabilities(Pointer<Uint32> pCapabilities) => ptr
      .ref.vtable
      .elementAt(10)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<Uint32> pCapabilities)>>>()
      .value
      .asFunction<
          int Function(Pointer,
              Pointer<Uint32> pCapabilities)>()(ptr.ref.lpVtbl, pCapabilities);

  int getFolderDefinition(Pointer<KNOWNFOLDER_DEFINITION> pKFD) => ptr
          .ref.vtable
          .elementAt(11)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<KNOWNFOLDER_DEFINITION> pKFD)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<KNOWNFOLDER_DEFINITION> pKFD)>()(
      ptr.ref.lpVtbl, pKFD);
}
