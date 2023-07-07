// iappxmanifestpackagedependenciesenumerator.dart

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
const IID_IAppxManifestPackageDependenciesEnumerator =
    '{B43BBCF9-65A6-42DD-BAC0-8C6741E7F5A4}';

/// {@category Interface}
/// {@category com}
class IAppxManifestPackageDependenciesEnumerator extends IUnknown {
  // vtable begins at 3, is 3 entries long.
  IAppxManifestPackageDependenciesEnumerator(super.ptr);

  int GetCurrent(Pointer<Pointer<COMObject>> dependency) => ptr.ref.vtable
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<COMObject>> dependency)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<COMObject>> dependency)>()(
      ptr.ref.lpVtbl, dependency);

  int GetHasCurrent(Pointer<Int32> hasCurrent) => ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Int32> hasCurrent)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Int32> hasCurrent)>()(
      ptr.ref.lpVtbl, hasCurrent);

  int MoveNext(Pointer<Int32> hasNext) => ptr.ref.vtable
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Int32> hasNext)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Int32> hasNext)>()(
      ptr.ref.lpVtbl, hasNext);
}
