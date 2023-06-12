// iunknown.dart

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

/// @nodoc
const IID_IUnknown = '{00000000-0000-0000-C000-000000000046}';

/// {@category Interface}
/// {@category com}
class IUnknown {
  // vtable begins at 0, is 3 entries long.
  Pointer<COMObject> ptr;

  IUnknown(this.ptr);

  factory IUnknown.from(IUnknown interface) =>
      IUnknown(interface.toInterface(IID_IUnknown));

  int queryInterface(Pointer<GUID> riid, Pointer<Pointer> ppvObject) => ptr
      .ref.vtable
      .elementAt(0)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<GUID> riid,
                      Pointer<Pointer> ppvObject)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<GUID> riid,
              Pointer<Pointer> ppvObject)>()(ptr.ref.lpVtbl, riid, ppvObject);

  int addRef() => ptr.ref.vtable
      .elementAt(1)
      .cast<Pointer<NativeFunction<Uint32 Function(Pointer)>>>()
      .value
      .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);

  int release() => ptr.ref.vtable
      .elementAt(2)
      .cast<Pointer<NativeFunction<Uint32 Function(Pointer)>>>()
      .value
      .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);

  /// Cast an existing COM object to a specified interface.
  ///
  /// Takes a string (typically a constant such as `IID_IModalWindow`) and does
  /// a COM QueryInterface to return a reference to that interface. This method
  /// reduces the boilerplate associated with calling QueryInterface manually.
  Pointer<COMObject> toInterface(String iid) {
    final pIID = convertToIID(iid);
    final pObject = calloc<COMObject>();
    try {
      final hr = queryInterface(pIID, pObject.cast());
      if (FAILED(hr)) throw WindowsException(hr);
      return pObject;
    } finally {
      free(pIID);
    }
  }
}
