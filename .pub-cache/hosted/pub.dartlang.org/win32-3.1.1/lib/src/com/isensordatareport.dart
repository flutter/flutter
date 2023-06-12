// isensordatareport.dart

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
const IID_ISensorDataReport = '{0AB9DF9B-C4B5-4796-8898-0470706A2E1D}';

/// {@category Interface}
/// {@category com}
class ISensorDataReport extends IUnknown {
  // vtable begins at 3, is 3 entries long.
  ISensorDataReport(super.ptr);

  factory ISensorDataReport.from(IUnknown interface) =>
      ISensorDataReport(interface.toInterface(IID_ISensorDataReport));

  int getTimestamp(Pointer<SYSTEMTIME> pTimeStamp) => ptr.ref.vtable
      .elementAt(3)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<SYSTEMTIME> pTimeStamp)>>>()
      .value
      .asFunction<
          int Function(Pointer,
              Pointer<SYSTEMTIME> pTimeStamp)>()(ptr.ref.lpVtbl, pTimeStamp);

  int getSensorValue(Pointer<PROPERTYKEY> pKey, Pointer<PROPVARIANT> pValue) =>
      ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<PROPERTYKEY> pKey,
                          Pointer<PROPVARIANT> pValue)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<PROPERTYKEY> pKey,
                  Pointer<PROPVARIANT> pValue)>()(ptr.ref.lpVtbl, pKey, pValue);

  int getSensorValues(
          Pointer<COMObject> pKeys, Pointer<Pointer<COMObject>> ppValues) =>
      ptr.ref.vtable
              .elementAt(5)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<COMObject> pKeys,
                              Pointer<Pointer<COMObject>> ppValues)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<COMObject> pKeys,
                      Pointer<Pointer<COMObject>> ppValues)>()(
          ptr.ref.lpVtbl, pKeys, ppValues);
}

/// @nodoc
const CLSID_SensorDataReport = '{4EA9D6EF-694B-4218-8816-CCDA8DA74BBA}';

/// {@category com}
class SensorDataReport extends ISensorDataReport {
  SensorDataReport(super.ptr);

  factory SensorDataReport.createInstance() => SensorDataReport(
      COMObject.createFromID(CLSID_SensorDataReport, IID_ISensorDataReport));
}
