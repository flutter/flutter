// IUnknown.dart

// This class is generated manually, since it includes additional helper
// functions that are only for the base COM object.

// ignore_for_file: camel_case_types
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../combase.dart';
import '../exceptions.dart';
import '../guid.dart';
import '../macros.dart';
import '../utils.dart';

/// @nodoc
const IID_IUnknown = '{00000000-0000-0000-C000-000000000046}';

typedef _QueryInterface_Native = Int32 Function(
    Pointer obj, Pointer<GUID> riid, Pointer<Pointer> ppvObject);
typedef _QueryInterface_Dart = int Function(
    Pointer obj, Pointer<GUID> riid, Pointer<Pointer> ppvObject);

typedef _AddRef_Native = Uint32 Function(Pointer obj);
typedef _AddRef_Dart = int Function(Pointer obj);

typedef _Release_Native = Uint32 Function(Pointer obj);
typedef _Release_Dart = int Function(Pointer obj);

/// {@category Interface}
/// {@category com}
class IUnknown {
  // vtable begins at 0, ends at 2
  Pointer<COMObject> ptr;

  IUnknown(this.ptr);

  int QueryInterface(Pointer<GUID> riid, Pointer<Pointer> ppvObject) =>
      Pointer<NativeFunction<_QueryInterface_Native>>.fromAddress(
              ptr.ref.vtable.elementAt(0).value)
          .asFunction<_QueryInterface_Dart>()(ptr.ref.lpVtbl, riid, ppvObject);

  int AddRef() => Pointer<NativeFunction<_AddRef_Native>>.fromAddress(
          ptr.ref.vtable.elementAt(1).value)
      .asFunction<_AddRef_Dart>()(ptr.ref.lpVtbl);

  int Release() => Pointer<NativeFunction<_Release_Native>>.fromAddress(
          ptr.ref.vtable.elementAt(2).value)
      .asFunction<_Release_Dart>()(ptr.ref.lpVtbl);

  /// Cast an existing COM object to a specified interface.
  ///
  /// Takes a string (typically a constant such as `IID_IModalWindow`) and does
  /// a COM QueryInterface to return a reference to that interface. This method
  /// reduces the boilerplate associated with calling QueryInterface manually.
  Pointer<COMObject> toInterface(String iid) {
    final pIID = convertToIID(iid);
    final pObject = calloc<COMObject>();
    try {
      final hr = QueryInterface(pIID, pObject.cast());
      if (FAILED(hr)) throw WindowsException(hr);
      return pObject;
    } finally {
      free(pIID);
    }
  }
}
