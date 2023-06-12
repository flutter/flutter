// ipersist.dart

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
const IID_IPersist = '{0000010C-0000-0000-C000-000000000046}';

/// {@category Interface}
/// {@category com}
class IPersist extends IUnknown {
  // vtable begins at 3, is 1 entries long.
  IPersist(super.ptr);

  factory IPersist.from(IUnknown interface) =>
      IPersist(interface.toInterface(IID_IPersist));

  int getClassID(Pointer<GUID> pClassID) => ptr.ref.vtable
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<GUID> pClassID)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<GUID> pClassID)>()(
      ptr.ref.lpVtbl, pClassID);
}
