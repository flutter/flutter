// ishellitemfilter.dart

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
const IID_IShellItemFilter = '{2659B475-EEB8-48B7-8F07-B378810F48CF}';

/// {@category Interface}
/// {@category com}
class IShellItemFilter extends IUnknown {
  // vtable begins at 3, is 2 entries long.
  IShellItemFilter(super.ptr);

  factory IShellItemFilter.from(IUnknown interface) =>
      IShellItemFilter(interface.toInterface(IID_IShellItemFilter));

  int includeItem(Pointer<COMObject> psi) => ptr.ref.vtable
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<COMObject> psi)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<COMObject> psi)>()(
      ptr.ref.lpVtbl, psi);

  int getEnumFlagsForItem(Pointer<COMObject> psi, Pointer<Uint32> pgrfFlags) =>
      ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<COMObject> psi,
                          Pointer<Uint32> pgrfFlags)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<COMObject> psi,
                  Pointer<Uint32> pgrfFlags)>()(ptr.ref.lpVtbl, psi, pgrfFlags);
}
