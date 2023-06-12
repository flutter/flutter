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
import '../structs.g.dart';
import '../utils.dart';
import '../variant.dart';
import '../win32/ole32.g.dart';
import 'idispatch.dart';
import 'iunknown.dart';

/// @nodoc
const IID_IShellLinkDual = '{88A05C00-F000-11CE-8350-444553540000}';

/// {@category Interface}
/// {@category com}
class IShellLinkDual extends IDispatch {
  // vtable begins at 7, is 16 entries long.
  IShellLinkDual(super.ptr);

  factory IShellLinkDual.from(IUnknown interface) =>
      IShellLinkDual(interface.toInterface(IID_IShellLinkDual));

  Pointer<Utf16> get path {
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

  set path(Pointer<Utf16> value) {
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

  Pointer<Utf16> get description {
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

  set description(Pointer<Utf16> value) {
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

  Pointer<Utf16> get workingDirectory {
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

  set workingDirectory(Pointer<Utf16> value) {
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

  Pointer<Utf16> get arguments {
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

  set arguments(Pointer<Utf16> value) {
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

  int get hotkey {
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

  set hotkey(int value) {
    final hr = ptr.ref.vtable
        .elementAt(16)
        .cast<Pointer<NativeFunction<Int32 Function(Pointer, Int32 iHK)>>>()
        .value
        .asFunction<int Function(Pointer, int iHK)>()(ptr.ref.lpVtbl, value);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  int get showCommand {
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

  set showCommand(int value) {
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

  int resolve(int fFlags) => ptr.ref.vtable
      .elementAt(19)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Int32 fFlags)>>>()
      .value
      .asFunction<int Function(Pointer, int fFlags)>()(ptr.ref.lpVtbl, fFlags);

  int getIconLocation(Pointer<Pointer<Utf16>> pbs, Pointer<Int32> piIcon) =>
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

  int setIconLocation(Pointer<Utf16> bs, int iIcon) => ptr.ref.vtable
      .elementAt(21)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<Utf16> bs, Int32 iIcon)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<Utf16> bs,
              int iIcon)>()(ptr.ref.lpVtbl, bs, iIcon);

  int save(VARIANT vWhere) => ptr.ref.vtable
      .elementAt(22)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, VARIANT vWhere)>>>()
      .value
      .asFunction<
          int Function(Pointer, VARIANT vWhere)>()(ptr.ref.lpVtbl, vWhere);
}
