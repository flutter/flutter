// ipersiststream.dart

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
const IID_IPersistStream = '{00000109-0000-0000-C000-000000000046}';

/// {@category Interface}
/// {@category com}
class IPersistStream extends IPersist {
  // vtable begins at 4, is 4 entries long.
  IPersistStream(super.ptr);

  factory IPersistStream.from(IUnknown interface) =>
      IPersistStream(interface.toInterface(IID_IPersistStream));

  int isDirty() => ptr.ref.vtable
      .elementAt(4)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer)>>>()
      .value
      .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);

  int load(Pointer<COMObject> pStm) => ptr.ref.vtable
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<COMObject> pStm)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<COMObject> pStm)>()(
      ptr.ref.lpVtbl, pStm);

  int save(Pointer<COMObject> pStm, int fClearDirty) => ptr.ref.vtable
      .elementAt(6)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(
                      Pointer, Pointer<COMObject> pStm, Int32 fClearDirty)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<COMObject> pStm,
              int fClearDirty)>()(ptr.ref.lpVtbl, pStm, fClearDirty);

  int getSizeMax(Pointer<Uint64> pcbSize) => ptr.ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Uint64> pcbSize)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Uint64> pcbSize)>()(
      ptr.ref.lpVtbl, pcbSize);
}
