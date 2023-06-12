// iinspectable.dart

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
const IID_IInspectable = '{AF86E2E0-B12D-4C6A-9C5A-D7AA65101E90}';

/// {@category Interface}
/// {@category com}
class IInspectable extends IUnknown {
  // vtable begins at 3, is 3 entries long.
  IInspectable(super.ptr);

  factory IInspectable.from(IUnknown interface) =>
      IInspectable(interface.toInterface(IID_IInspectable));

  int getIids(Pointer<Uint32> iidCount, Pointer<Pointer<GUID>> iids) => ptr
      .ref.vtable
      .elementAt(3)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<Uint32> iidCount,
                      Pointer<Pointer<GUID>> iids)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<Uint32> iidCount,
              Pointer<Pointer<GUID>> iids)>()(ptr.ref.lpVtbl, iidCount, iids);

  int getRuntimeClassName(Pointer<IntPtr> className) => ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<IntPtr> className)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<IntPtr> className)>()(
      ptr.ref.lpVtbl, className);

  int getTrustLevel(Pointer<Int32> trustLevel) => ptr.ref.vtable
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Int32> trustLevel)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Int32> trustLevel)>()(
      ptr.ref.lpVtbl, trustLevel);
}
