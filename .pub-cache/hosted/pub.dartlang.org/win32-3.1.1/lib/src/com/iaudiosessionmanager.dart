// iaudiosessionmanager.dart

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
const IID_IAudioSessionManager = '{BFA971F1-4D5E-40BB-935E-967039BFBEE4}';

/// {@category Interface}
/// {@category com}
class IAudioSessionManager extends IUnknown {
  // vtable begins at 3, is 2 entries long.
  IAudioSessionManager(super.ptr);

  factory IAudioSessionManager.from(IUnknown interface) =>
      IAudioSessionManager(interface.toInterface(IID_IAudioSessionManager));

  int getAudioSessionControl(Pointer<GUID> AudioSessionGuid, int StreamFlags,
          Pointer<Pointer<COMObject>> SessionControl) =>
      ptr.ref.vtable
              .elementAt(3)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<GUID> AudioSessionGuid,
                              Uint32 StreamFlags,
                              Pointer<Pointer<COMObject>> SessionControl)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<GUID> AudioSessionGuid,
                      int StreamFlags,
                      Pointer<Pointer<COMObject>> SessionControl)>()(
          ptr.ref.lpVtbl, AudioSessionGuid, StreamFlags, SessionControl);

  int getSimpleAudioVolume(Pointer<GUID> AudioSessionGuid, int StreamFlags,
          Pointer<Pointer<COMObject>> AudioVolume) =>
      ptr.ref.vtable
              .elementAt(4)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Pointer<GUID> AudioSessionGuid,
                              Uint32 StreamFlags,
                              Pointer<Pointer<COMObject>> AudioVolume)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      Pointer<GUID> AudioSessionGuid,
                      int StreamFlags,
                      Pointer<Pointer<COMObject>> AudioVolume)>()(
          ptr.ref.lpVtbl, AudioSessionGuid, StreamFlags, AudioVolume);
}
