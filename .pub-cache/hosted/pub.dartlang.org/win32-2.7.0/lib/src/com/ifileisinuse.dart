// ifileisinuse.dart

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
const IID_IFileIsInUse = '{64A1CBF0-3A1A-4461-9158-376969693950}';

/// {@category Interface}
/// {@category com}
class IFileIsInUse extends IUnknown {
  // vtable begins at 3, is 5 entries long.
  IFileIsInUse(super.ptr);

  int GetAppName(Pointer<Pointer<Utf16>> ppszName) => ptr.ref.vtable
      .elementAt(3)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<Pointer<Utf16>> ppszName)>>>()
      .value
      .asFunction<
          int Function(Pointer,
              Pointer<Pointer<Utf16>> ppszName)>()(ptr.ref.lpVtbl, ppszName);

  int GetUsage(Pointer<Int32> pfut) => ptr.ref.vtable
      .elementAt(4)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<Int32> pfut)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<Int32> pfut)>()(ptr.ref.lpVtbl, pfut);

  int GetCapabilities(Pointer<Uint32> pdwCapFlags) => ptr.ref.vtable
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Uint32> pdwCapFlags)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Uint32> pdwCapFlags)>()(
      ptr.ref.lpVtbl, pdwCapFlags);

  int GetSwitchToHWND(Pointer<IntPtr> phwnd) => ptr.ref.vtable
      .elementAt(6)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<IntPtr> phwnd)>>>()
      .value
      .asFunction<
          int Function(
              Pointer, Pointer<IntPtr> phwnd)>()(ptr.ref.lpVtbl, phwnd);

  int CloseFile() => ptr.ref.vtable
      .elementAt(7)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer)>>>()
      .value
      .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);
}
