// iappxmanifestpackagedependency.dart

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
const IID_IAppxManifestPackageDependency =
    '{E4946B59-733E-43F0-A724-3BDE4C1285A0}';

/// {@category Interface}
/// {@category com}
class IAppxManifestPackageDependency extends IUnknown {
  // vtable begins at 3, is 3 entries long.
  IAppxManifestPackageDependency(super.ptr);

  int GetName(Pointer<Pointer<Utf16>> name) => ptr.ref.vtable
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Pointer<Utf16>> name)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Pointer<Utf16>> name)>()(
      ptr.ref.lpVtbl, name);

  int GetPublisher(Pointer<Pointer<Utf16>> publisher) => ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<Utf16>> publisher)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<Utf16>> publisher)>()(
      ptr.ref.lpVtbl, publisher);

  int GetMinVersion(Pointer<Uint64> minVersion) => ptr.ref.vtable
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Uint64> minVersion)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Uint64> minVersion)>()(
      ptr.ref.lpVtbl, minVersion);
}
