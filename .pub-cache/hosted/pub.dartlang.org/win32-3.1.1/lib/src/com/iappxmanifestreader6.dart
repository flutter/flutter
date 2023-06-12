// iappxmanifestreader6.dart

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
const IID_IAppxManifestReader6 = '{34DEACA4-D3C0-4E3E-B312-E42625E3807E}';

/// {@category Interface}
/// {@category com}
class IAppxManifestReader6 extends IUnknown {
  // vtable begins at 3, is 1 entries long.
  IAppxManifestReader6(super.ptr);

  factory IAppxManifestReader6.from(IUnknown interface) =>
      IAppxManifestReader6(interface.toInterface(IID_IAppxManifestReader6));

  int getIsNonQualifiedResourcePackage(
          Pointer<Int32> isNonQualifiedResourcePackage) =>
      ptr.ref.vtable
              .elementAt(3)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer,
                              Pointer<Int32> isNonQualifiedResourcePackage)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, Pointer<Int32> isNonQualifiedResourcePackage)>()(
          ptr.ref.lpVtbl, isNonQualifiedResourcePackage);
}
