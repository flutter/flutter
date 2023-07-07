// ifiledialog.dart

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

import 'imodalwindow.dart';

/// @nodoc
const IID_IFileDialog = '{42F85136-DB7E-439C-85F1-E4075D135FC8}';

/// {@category Interface}
/// {@category com}
class IFileDialog extends IModalWindow {
  // vtable begins at 4, is 23 entries long.
  IFileDialog(super.ptr);

  int SetFileTypes(int cFileTypes, Pointer<COMDLG_FILTERSPEC> rgFilterSpec) =>
      ptr.ref.vtable
              .elementAt(4)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Uint32 cFileTypes,
                              Pointer<COMDLG_FILTERSPEC> rgFilterSpec)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int cFileTypes,
                      Pointer<COMDLG_FILTERSPEC> rgFilterSpec)>()(
          ptr.ref.lpVtbl, cFileTypes, rgFilterSpec);

  int SetFileTypeIndex(int iFileType) => ptr.ref.vtable
      .elementAt(5)
      .cast<
          Pointer<NativeFunction<Int32 Function(Pointer, Uint32 iFileType)>>>()
      .value
      .asFunction<
          int Function(Pointer, int iFileType)>()(ptr.ref.lpVtbl, iFileType);

  int GetFileTypeIndex(Pointer<Uint32> piFileType) => ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Uint32> piFileType)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Uint32> piFileType)>()(
      ptr.ref.lpVtbl, piFileType);

  int Advise(Pointer<COMObject> pfde, Pointer<Uint32> pdwCookie) => ptr
      .ref.vtable
      .elementAt(7)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<COMObject> pfde,
                      Pointer<Uint32> pdwCookie)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<COMObject> pfde,
              Pointer<Uint32> pdwCookie)>()(ptr.ref.lpVtbl, pfde, pdwCookie);

  int Unadvise(int dwCookie) => ptr.ref.vtable
      .elementAt(8)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Uint32 dwCookie)>>>()
      .value
      .asFunction<
          int Function(Pointer, int dwCookie)>()(ptr.ref.lpVtbl, dwCookie);

  int SetOptions(int fos) => ptr.ref.vtable
      .elementAt(9)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Uint32 fos)>>>()
      .value
      .asFunction<int Function(Pointer, int fos)>()(ptr.ref.lpVtbl, fos);

  int GetOptions(Pointer<Uint32> pfos) => ptr.ref.vtable
      .elementAt(10)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<Uint32> pfos)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<Uint32> pfos)>()(ptr.ref.lpVtbl, pfos);

  int SetDefaultFolder(Pointer<COMObject> psi) => ptr.ref.vtable
          .elementAt(11)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<COMObject> psi)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<COMObject> psi)>()(
      ptr.ref.lpVtbl, psi);

  int SetFolder(Pointer<COMObject> psi) => ptr.ref.vtable
          .elementAt(12)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<COMObject> psi)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<COMObject> psi)>()(
      ptr.ref.lpVtbl, psi);

  int GetFolder(Pointer<Pointer<COMObject>> ppsi) => ptr.ref.vtable
      .elementAt(13)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<Pointer<COMObject>> ppsi)>>>()
      .value
      .asFunction<
          int Function(Pointer,
              Pointer<Pointer<COMObject>> ppsi)>()(ptr.ref.lpVtbl, ppsi);

  int GetCurrentSelection(Pointer<Pointer<COMObject>> ppsi) => ptr.ref.vtable
      .elementAt(14)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<Pointer<COMObject>> ppsi)>>>()
      .value
      .asFunction<
          int Function(Pointer,
              Pointer<Pointer<COMObject>> ppsi)>()(ptr.ref.lpVtbl, ppsi);

  int SetFileName(Pointer<Utf16> pszName) => ptr.ref.vtable
          .elementAt(15)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Utf16> pszName)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Utf16> pszName)>()(
      ptr.ref.lpVtbl, pszName);

  int GetFileName(Pointer<Pointer<Utf16>> pszName) => ptr.ref.vtable
      .elementAt(16)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<Pointer<Utf16>> pszName)>>>()
      .value
      .asFunction<
          int Function(Pointer,
              Pointer<Pointer<Utf16>> pszName)>()(ptr.ref.lpVtbl, pszName);

  int SetTitle(Pointer<Utf16> pszTitle) => ptr.ref.vtable
          .elementAt(17)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Utf16> pszTitle)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Utf16> pszTitle)>()(
      ptr.ref.lpVtbl, pszTitle);

  int SetOkButtonLabel(Pointer<Utf16> pszText) => ptr.ref.vtable
          .elementAt(18)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Utf16> pszText)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Utf16> pszText)>()(
      ptr.ref.lpVtbl, pszText);

  int SetFileNameLabel(Pointer<Utf16> pszLabel) => ptr.ref.vtable
          .elementAt(19)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Utf16> pszLabel)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Utf16> pszLabel)>()(
      ptr.ref.lpVtbl, pszLabel);

  int GetResult(Pointer<Pointer<COMObject>> ppsi) => ptr.ref.vtable
      .elementAt(20)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<Pointer<COMObject>> ppsi)>>>()
      .value
      .asFunction<
          int Function(Pointer,
              Pointer<Pointer<COMObject>> ppsi)>()(ptr.ref.lpVtbl, ppsi);

  int AddPlace(Pointer<COMObject> psi, int fdap) => ptr.ref.vtable
          .elementAt(21)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<COMObject> psi, Int32 fdap)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<COMObject> psi, int fdap)>()(
      ptr.ref.lpVtbl, psi, fdap);

  int SetDefaultExtension(Pointer<Utf16> pszDefaultExtension) => ptr.ref.vtable
          .elementAt(22)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Utf16> pszDefaultExtension)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Utf16> pszDefaultExtension)>()(
      ptr.ref.lpVtbl, pszDefaultExtension);

  int Close(int hr) => ptr.ref.vtable
      .elementAt(23)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Int32 hr)>>>()
      .value
      .asFunction<int Function(Pointer, int hr)>()(ptr.ref.lpVtbl, hr);

  int SetClientGuid(Pointer<GUID> guid) => ptr.ref.vtable
      .elementAt(24)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<GUID> guid)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<GUID> guid)>()(ptr.ref.lpVtbl, guid);

  int ClearClientData() => ptr.ref.vtable
      .elementAt(25)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer)>>>()
      .value
      .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);

  int SetFilter(Pointer<COMObject> pFilter) => ptr.ref.vtable
          .elementAt(26)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<COMObject> pFilter)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<COMObject> pFilter)>()(
      ptr.ref.lpVtbl, pFilter);
}
