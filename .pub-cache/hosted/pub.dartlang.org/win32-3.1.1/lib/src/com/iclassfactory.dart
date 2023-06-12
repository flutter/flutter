// iclassfactory.dart

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
const IID_IClassFactory = '{00000001-0000-0000-C000-000000000046}';

/// {@category Interface}
/// {@category com}
class IClassFactory extends IUnknown {
  // vtable begins at 3, is 2 entries long.
  IClassFactory(super.ptr);

  factory IClassFactory.from(IUnknown interface) =>
      IClassFactory(interface.toInterface(IID_IClassFactory));

  int createInstance(Pointer<COMObject> pUnkOuter, Pointer<GUID> riid,
          Pointer<Pointer> ppvObject) =>
      ptr.ref.vtable
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<COMObject> pUnkOuter,
                          Pointer<GUID> riid, Pointer<Pointer> ppvObject)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer,
                  Pointer<COMObject> pUnkOuter,
                  Pointer<GUID> riid,
                  Pointer<Pointer>
                      ppvObject)>()(ptr.ref.lpVtbl, pUnkOuter, riid, ppvObject);

  int lockServer(int fLock) => ptr.ref.vtable
      .elementAt(4)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Int32 fLock)>>>()
      .value
      .asFunction<int Function(Pointer, int fLock)>()(ptr.ref.lpVtbl, fLock);
}
