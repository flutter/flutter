// iaudiosessioncontrol.dart

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
const IID_IAudioSessionControl = '{F4B1A599-7266-4319-A8CA-E70ACB11E8CD}';

/// {@category Interface}
/// {@category com}
class IAudioSessionControl extends IUnknown {
  // vtable begins at 3, is 9 entries long.
  IAudioSessionControl(super.ptr);

  factory IAudioSessionControl.from(IUnknown interface) =>
      IAudioSessionControl(interface.toInterface(IID_IAudioSessionControl));

  int getState(Pointer<Int32> pRetVal) => ptr.ref.vtable
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Int32> pRetVal)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Int32> pRetVal)>()(
      ptr.ref.lpVtbl, pRetVal);

  int getDisplayName(Pointer<Pointer<Utf16>> pRetVal) => ptr.ref.vtable
      .elementAt(4)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<Pointer<Utf16>> pRetVal)>>>()
      .value
      .asFunction<
          int Function(Pointer,
              Pointer<Pointer<Utf16>> pRetVal)>()(ptr.ref.lpVtbl, pRetVal);

  int setDisplayName(Pointer<Utf16> Value, Pointer<GUID> EventContext) => ptr
          .ref.vtable
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Utf16> Value,
                          Pointer<GUID> EventContext)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Utf16> Value, Pointer<GUID> EventContext)>()(
      ptr.ref.lpVtbl, Value, EventContext);

  int getIconPath(Pointer<Pointer<Utf16>> pRetVal) => ptr.ref.vtable
      .elementAt(6)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<Pointer<Utf16>> pRetVal)>>>()
      .value
      .asFunction<
          int Function(Pointer,
              Pointer<Pointer<Utf16>> pRetVal)>()(ptr.ref.lpVtbl, pRetVal);

  int setIconPath(Pointer<Utf16> Value, Pointer<GUID> EventContext) => ptr
          .ref.vtable
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Utf16> Value,
                          Pointer<GUID> EventContext)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Utf16> Value, Pointer<GUID> EventContext)>()(
      ptr.ref.lpVtbl, Value, EventContext);

  int getGroupingParam(Pointer<GUID> pRetVal) => ptr.ref.vtable
      .elementAt(8)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<GUID> pRetVal)>>>()
      .value
      .asFunction<
          int Function(
              Pointer, Pointer<GUID> pRetVal)>()(ptr.ref.lpVtbl, pRetVal);

  int setGroupingParam(Pointer<GUID> Override, Pointer<GUID> EventContext) =>
      ptr.ref.vtable
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<GUID> Override,
                              Pointer<GUID> EventContext)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<GUID> Override,
                      Pointer<GUID> EventContext)>()(
          ptr.ref.lpVtbl, Override, EventContext);

  int registerAudioSessionNotification(Pointer<COMObject> NewNotifications) =>
      ptr.ref.vtable
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Pointer<COMObject> NewNotifications)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<COMObject> NewNotifications)>()(
          ptr.ref.lpVtbl, NewNotifications);

  int unregisterAudioSessionNotification(Pointer<COMObject> NewNotifications) =>
      ptr.ref.vtable
              .elementAt(11)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer, Pointer<COMObject> NewNotifications)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<COMObject> NewNotifications)>()(
          ptr.ref.lpVtbl, NewNotifications);
}
