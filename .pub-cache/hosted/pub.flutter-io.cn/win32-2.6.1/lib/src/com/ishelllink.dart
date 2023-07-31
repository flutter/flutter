// IShellLink.dart

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
const IID_IShellLink = '{000214F9-0000-0000-C000-000000000046}';

/// {@category Interface}
/// {@category com}
class IShellLink extends IUnknown {
  // vtable begins at 3, is 18 entries long.
  IShellLink(Pointer<COMObject> ptr) : super(ptr);

  int GetPath(
    Pointer<Utf16> pszFile,
    int cch,
    Pointer<WIN32_FIND_DATA> pfd,
    int fFlags,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Utf16> pszFile,
            Int32 cch,
            Pointer<WIN32_FIND_DATA> pfd,
            Uint32 fFlags,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Utf16> pszFile,
            int cch,
            Pointer<WIN32_FIND_DATA> pfd,
            int fFlags,
          )>()(
        ptr.ref.lpVtbl,
        pszFile,
        cch,
        pfd,
        fFlags,
      );

  int GetIDList(
    Pointer<Pointer<ITEMIDLIST>> ppidl,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Pointer<ITEMIDLIST>> ppidl,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Pointer<ITEMIDLIST>> ppidl,
          )>()(
        ptr.ref.lpVtbl,
        ppidl,
      );

  int SetIDList(
    Pointer<ITEMIDLIST> pidl,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<ITEMIDLIST> pidl,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<ITEMIDLIST> pidl,
          )>()(
        ptr.ref.lpVtbl,
        pidl,
      );

  int GetDescription(
    Pointer<Utf16> pszName,
    int cch,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Utf16> pszName,
            Int32 cch,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Utf16> pszName,
            int cch,
          )>()(
        ptr.ref.lpVtbl,
        pszName,
        cch,
      );

  int SetDescription(
    Pointer<Utf16> pszName,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Utf16> pszName,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Utf16> pszName,
          )>()(
        ptr.ref.lpVtbl,
        pszName,
      );

  int GetWorkingDirectory(
    Pointer<Utf16> pszDir,
    int cch,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Utf16> pszDir,
            Int32 cch,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Utf16> pszDir,
            int cch,
          )>()(
        ptr.ref.lpVtbl,
        pszDir,
        cch,
      );

  int SetWorkingDirectory(
    Pointer<Utf16> pszDir,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(9)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Utf16> pszDir,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Utf16> pszDir,
          )>()(
        ptr.ref.lpVtbl,
        pszDir,
      );

  int GetArguments(
    Pointer<Utf16> pszArgs,
    int cch,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(10)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Utf16> pszArgs,
            Int32 cch,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Utf16> pszArgs,
            int cch,
          )>()(
        ptr.ref.lpVtbl,
        pszArgs,
        cch,
      );

  int SetArguments(
    Pointer<Utf16> pszArgs,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(11)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Utf16> pszArgs,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Utf16> pszArgs,
          )>()(
        ptr.ref.lpVtbl,
        pszArgs,
      );

  int GetHotkey(
    Pointer<Uint16> pwHotkey,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(12)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Uint16> pwHotkey,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Uint16> pwHotkey,
          )>()(
        ptr.ref.lpVtbl,
        pwHotkey,
      );

  int SetHotkey(
    int wHotkey,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(13)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Uint16 wHotkey,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            int wHotkey,
          )>()(
        ptr.ref.lpVtbl,
        wHotkey,
      );

  int GetShowCmd(
    Pointer<Int32> piShowCmd,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(14)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Int32> piShowCmd,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Int32> piShowCmd,
          )>()(
        ptr.ref.lpVtbl,
        piShowCmd,
      );

  int SetShowCmd(
    int iShowCmd,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(15)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Int32 iShowCmd,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            int iShowCmd,
          )>()(
        ptr.ref.lpVtbl,
        iShowCmd,
      );

  int GetIconLocation(
    Pointer<Utf16> pszIconPath,
    int cch,
    Pointer<Int32> piIcon,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(16)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Utf16> pszIconPath,
            Int32 cch,
            Pointer<Int32> piIcon,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Utf16> pszIconPath,
            int cch,
            Pointer<Int32> piIcon,
          )>()(
        ptr.ref.lpVtbl,
        pszIconPath,
        cch,
        piIcon,
      );

  int SetIconLocation(
    Pointer<Utf16> pszIconPath,
    int iIcon,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(17)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Utf16> pszIconPath,
            Int32 iIcon,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Utf16> pszIconPath,
            int iIcon,
          )>()(
        ptr.ref.lpVtbl,
        pszIconPath,
        iIcon,
      );

  int SetRelativePath(
    Pointer<Utf16> pszPathRel,
    int dwReserved,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(18)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Utf16> pszPathRel,
            Uint32 dwReserved,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Utf16> pszPathRel,
            int dwReserved,
          )>()(
        ptr.ref.lpVtbl,
        pszPathRel,
        dwReserved,
      );

  int Resolve(
    int hwnd,
    int fFlags,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(19)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            IntPtr hwnd,
            Uint32 fFlags,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            int hwnd,
            int fFlags,
          )>()(
        ptr.ref.lpVtbl,
        hwnd,
        fFlags,
      );

  int SetPath(
    Pointer<Utf16> pszFile,
  ) =>
      ptr.ref.lpVtbl.value
          .elementAt(20)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
            Pointer,
            Pointer<Utf16> pszFile,
          )>>>()
          .value
          .asFunction<
              int Function(
            Pointer,
            Pointer<Utf16> pszFile,
          )>()(
        ptr.ref.lpVtbl,
        pszFile,
      );
}

/// @nodoc
const CLSID_ShellLink = '{00021401-0000-0000-C000-000000000046}';

/// {@category com}
class ShellLink extends IShellLink {
  ShellLink(Pointer<COMObject> ptr) : super(ptr);

  factory ShellLink.createInstance() {
    final ptr = calloc<COMObject>();
    final clsid = calloc<GUID>()..ref.setGUID(CLSID_ShellLink);
    final iid = calloc<GUID>()..ref.setGUID(IID_IShellLink);

    try {
      final hr = CoCreateInstance(clsid, nullptr, CLSCTX_ALL, iid, ptr.cast());

      if (FAILED(hr)) throw WindowsException(hr);

      return ShellLink(ptr);
    } finally {
      free(clsid);
      free(iid);
    }
  }
}
