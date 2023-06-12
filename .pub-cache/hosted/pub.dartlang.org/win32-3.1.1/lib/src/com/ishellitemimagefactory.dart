// ishellitemimagefactory.dart

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
const IID_IShellItemImageFactory = '{BCC18B79-BA16-442F-80C4-8A59C30C463B}';

/// {@category Interface}
/// {@category com}
class IShellItemImageFactory extends IUnknown {
  // vtable begins at 3, is 1 entries long.
  IShellItemImageFactory(super.ptr);

  factory IShellItemImageFactory.from(IUnknown interface) =>
      IShellItemImageFactory(interface.toInterface(IID_IShellItemImageFactory));

  int getImage(SIZE size, int flags, Pointer<IntPtr> phbm) => ptr.ref.vtable
      .elementAt(3)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, SIZE size, Int32 flags,
                      Pointer<IntPtr> phbm)>>>()
      .value
      .asFunction<
          int Function(Pointer, SIZE size, int flags,
              Pointer<IntPtr> phbm)>()(ptr.ref.lpVtbl, size, flags, phbm);
}
