// isensormanager.dart

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
const IID_ISensorManager = '{BD77DB67-45A8-42DC-8D00-6DCF15F8377A}';

/// {@category Interface}
/// {@category com}
class ISensorManager extends IUnknown {
  // vtable begins at 3, is 5 entries long.
  ISensorManager(super.ptr);

  factory ISensorManager.from(IUnknown interface) =>
      ISensorManager(interface.toInterface(IID_ISensorManager));

  int getSensorsByCategory(Pointer<GUID> sensorCategory,
          Pointer<Pointer<COMObject>> ppSensorsFound) =>
      ptr.ref.vtable
              .elementAt(3)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<GUID> sensorCategory,
                              Pointer<Pointer<COMObject>> ppSensorsFound)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<GUID> sensorCategory,
                      Pointer<Pointer<COMObject>> ppSensorsFound)>()(
          ptr.ref.lpVtbl, sensorCategory, ppSensorsFound);

  int getSensorsByType(Pointer<GUID> sensorType,
          Pointer<Pointer<COMObject>> ppSensorsFound) =>
      ptr.ref.vtable
              .elementAt(4)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<GUID> sensorType,
                              Pointer<Pointer<COMObject>> ppSensorsFound)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<GUID> sensorType,
                      Pointer<Pointer<COMObject>> ppSensorsFound)>()(
          ptr.ref.lpVtbl, sensorType, ppSensorsFound);

  int getSensorByID(
          Pointer<GUID> sensorID, Pointer<Pointer<COMObject>> ppSensor) =>
      ptr
              .ref.vtable
              .elementAt(5)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<GUID> sensorID,
                              Pointer<Pointer<COMObject>> ppSensor)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<GUID> sensorID,
                      Pointer<Pointer<COMObject>> ppSensor)>()(
          ptr.ref.lpVtbl, sensorID, ppSensor);

  int setEventSink(Pointer<COMObject> pEvents) => ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<COMObject> pEvents)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<COMObject> pEvents)>()(
      ptr.ref.lpVtbl, pEvents);

  int requestPermissions(
          int hParent, Pointer<COMObject> pSensors, int fModal) =>
      ptr.ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, IntPtr hParent,
                          Pointer<COMObject> pSensors, Int32 fModal)>>>()
          .value
          .asFunction<
              int Function(Pointer, int hParent, Pointer<COMObject> pSensors,
                  int fModal)>()(ptr.ref.lpVtbl, hParent, pSensors, fModal);
}

/// @nodoc
const CLSID_SensorManager = '{77A1C827-FCD2-4689-8915-9D613CC5FA3E}';

/// {@category com}
class SensorManager extends ISensorManager {
  SensorManager(super.ptr);

  factory SensorManager.createInstance() => SensorManager(
      COMObject.createFromID(CLSID_SensorManager, IID_ISensorManager));
}
