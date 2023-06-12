// iappxmanifestospackagedependency.dart

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
const IID_IAppxManifestOSPackageDependency =
    '{154995EE-54A6-4F14-AC97-D8CF0519644B}';

/// {@category Interface}
/// {@category com}
class IAppxManifestOSPackageDependency extends IUnknown {
  // vtable begins at 3, is 2 entries long.
  IAppxManifestOSPackageDependency(super.ptr);

  factory IAppxManifestOSPackageDependency.from(IUnknown interface) =>
      IAppxManifestOSPackageDependency(
          interface.toInterface(IID_IAppxManifestOSPackageDependency));

  int getName(Pointer<Pointer<Utf16>> name) => ptr.ref.vtable
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Pointer<Utf16>> name)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Pointer<Utf16>> name)>()(
      ptr.ref.lpVtbl, name);

  int getVersion(Pointer<Uint64> version) => ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Uint64> version)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Uint64> version)>()(
      ptr.ref.lpVtbl, version);
}
