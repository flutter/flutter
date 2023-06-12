// ipersistmemory.dart

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
import 'ipersist.dart';
import 'iunknown.dart';

/// @nodoc
const IID_IPersistMemory = '{BD1AE5E0-A6AE-11CE-BD37-504200C10000}';

/// {@category Interface}
/// {@category com}
class IPersistMemory extends IPersist {
  // vtable begins at 4, is 5 entries long.
  IPersistMemory(super.ptr);

  factory IPersistMemory.from(IUnknown interface) =>
      IPersistMemory(interface.toInterface(IID_IPersistMemory));

  int isDirty() => ptr.ref.vtable
      .elementAt(4)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer)>>>()
      .value
      .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);

  int load(Pointer pMem, int cbSize) => ptr.ref.vtable
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer pMem, Uint32 cbSize)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer pMem, int cbSize)>()(
      ptr.ref.lpVtbl, pMem, cbSize);

  int save(Pointer pMem, int fClearDirty, int cbSize) => ptr.ref.vtable
      .elementAt(6)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer pMem, Int32 fClearDirty,
                      Uint32 cbSize)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer pMem, int fClearDirty,
              int cbSize)>()(ptr.ref.lpVtbl, pMem, fClearDirty, cbSize);

  int getSizeMax(Pointer<Uint32> pCbSize) => ptr.ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Uint32> pCbSize)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Uint32> pCbSize)>()(
      ptr.ref.lpVtbl, pCbSize);

  int initNew() => ptr.ref.vtable
      .elementAt(8)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer)>>>()
      .value
      .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);
}
