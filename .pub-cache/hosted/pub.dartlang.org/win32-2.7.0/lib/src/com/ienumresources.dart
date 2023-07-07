// ienumresources.dart

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
const IID_IEnumResources = '{2DD81FE3-A83C-4DA9-A330-47249D345BA1}';

/// {@category Interface}
/// {@category com}
class IEnumResources extends IUnknown {
  // vtable begins at 3, is 4 entries long.
  IEnumResources(super.ptr);

  int Next(int celt, Pointer<SHELL_ITEM_RESOURCE> psir,
          Pointer<Uint32> pceltFetched) =>
      ptr.ref.vtable
              .elementAt(3)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Uint32 celt,
                              Pointer<SHELL_ITEM_RESOURCE> psir,
                              Pointer<Uint32> pceltFetched)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      int celt,
                      Pointer<SHELL_ITEM_RESOURCE> psir,
                      Pointer<Uint32> pceltFetched)>()(
          ptr.ref.lpVtbl, celt, psir, pceltFetched);

  int Skip(int celt) => ptr.ref.vtable
      .elementAt(4)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Uint32 celt)>>>()
      .value
      .asFunction<int Function(Pointer, int celt)>()(ptr.ref.lpVtbl, celt);

  int Reset() => ptr.ref.vtable
      .elementAt(5)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer)>>>()
      .value
      .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);

  int Clone(Pointer<Pointer<COMObject>> ppenumr) => ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<COMObject>> ppenumr)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<COMObject>> ppenumr)>()(
      ptr.ref.lpVtbl, ppenumr);
}
