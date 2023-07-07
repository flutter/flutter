// ishelllinkdual.dart

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

import 'idispatch.dart';

/// @nodoc
const IID_IShellLinkDual = '{88A05C00-F000-11CE-8350-444553540000}';

/// {@category Interface}
/// {@category com}
class IShellLinkDual extends IDispatch {
  // vtable begins at 7, is 16 entries long.
  IShellLinkDual(super.ptr);

  Pointer<Utf16> get Path {
    final retValuePtr = calloc<Pointer<Utf16>>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Pointer<Utf16>> pbs)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<Pointer<Utf16>> pbs)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set Path(Pointer<Utf16> value) {
    final hr = ptr.ref.vtable
        .elementAt(8)
        .cast<
            Pointer<
                NativeFunction<Int32 Function(Pointer, Pointer<Utf16> bs)>>>()
        .value
        .asFunction<
            int Function(Pointer, Pointer<Utf16> bs)>()(ptr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  Pointer<Utf16> get Description {
    final retValuePtr = calloc<Pointer<Utf16>>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(9)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Pointer<Utf16>> pbs)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<Pointer<Utf16>> pbs)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set Description(Pointer<Utf16> value) {
    final hr = ptr.ref.vtable
        .elementAt(10)
        .cast<
            Pointer<
                NativeFunction<Int32 Function(Pointer, Pointer<Utf16> bs)>>>()
        .value
        .asFunction<
            int Function(Pointer, Pointer<Utf16> bs)>()(ptr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  Pointer<Utf16> get WorkingDirectory {
    final retValuePtr = calloc<Pointer<Utf16>>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(11)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Pointer<Utf16>> pbs)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<Pointer<Utf16>> pbs)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set WorkingDirectory(Pointer<Utf16> value) {
    final hr = ptr.ref.vtable
        .elementAt(12)
        .cast<
            Pointer<
                NativeFunction<Int32 Function(Pointer, Pointer<Utf16> bs)>>>()
        .value
        .asFunction<
            int Function(Pointer, Pointer<Utf16> bs)>()(ptr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  Pointer<Utf16> get Arguments {
    final retValuePtr = calloc<Pointer<Utf16>>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(13)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Pointer<Utf16>> pbs)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<Pointer<Utf16>> pbs)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set Arguments(Pointer<Utf16> value) {
    final hr = ptr.ref.vtable
        .elementAt(14)
        .cast<
            Pointer<
                NativeFunction<Int32 Function(Pointer, Pointer<Utf16> bs)>>>()
        .value
        .asFunction<
            int Function(Pointer, Pointer<Utf16> bs)>()(ptr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  int get Hotkey {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = ptr.ref.vtable
              .elementAt(15)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<Int32> piHK)>>>()
              .value
              .asFunction<int Function(Pointer, Pointer<Int32> piHK)>()(
          ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set Hotkey(int value) {
    final hr = ptr.ref.vtable
        .elementAt(16)
        .cast<Pointer<NativeFunction<Int32 Function(Pointer, Int32 iHK)>>>()
        .value
        .asFunction<int Function(Pointer, int iHK)>()(ptr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  int get ShowCommand {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(17)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Int32> piShowCommand)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<Int32> piShowCommand)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  set ShowCommand(int value) {
    final hr = ptr.ref.vtable
        .elementAt(18)
        .cast<
            Pointer<
                NativeFunction<Int32 Function(Pointer, Int32 iShowCommand)>>>()
        .value
        .asFunction<
            int Function(Pointer, int iShowCommand)>()(ptr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  int Resolve(int fFlags) => ptr.ref.vtable
      .elementAt(19)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Int32 fFlags)>>>()
      .value
      .asFunction<int Function(Pointer, int fFlags)>()(ptr.ref.lpVtbl, fFlags);

  int GetIconLocation(Pointer<Pointer<Utf16>> pbs, Pointer<Int32> piIcon) =>
      ptr.ref.vtable
          .elementAt(20)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Pointer<Utf16>> pbs,
                          Pointer<Int32> piIcon)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<Utf16>> pbs,
                  Pointer<Int32> piIcon)>()(ptr.ref.lpVtbl, pbs, piIcon);

  int SetIconLocation(Pointer<Utf16> bs, int iIcon) => ptr.ref.vtable
      .elementAt(21)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<Utf16> bs, Int32 iIcon)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<Utf16> bs,
              int iIcon)>()(ptr.ref.lpVtbl, bs, iIcon);

  int Save(VARIANT vWhere) => ptr.ref.vtable
      .elementAt(22)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, VARIANT vWhere)>>>()
      .value
      .asFunction<
          int Function(Pointer, VARIANT vWhere)>()(ptr.ref.lpVtbl, vWhere);
}
