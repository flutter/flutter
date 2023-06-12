// isimpleaudiovolume.dart

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
const IID_ISimpleAudioVolume = '{87CE5498-68D6-44E5-9215-6DA47EF883D8}';

/// {@category Interface}
/// {@category com}
class ISimpleAudioVolume extends IUnknown {
  // vtable begins at 3, is 4 entries long.
  ISimpleAudioVolume(super.ptr);

  int SetMasterVolume(double fLevel, Pointer<GUID> EventContext) =>
      ptr.ref.vtable
              .elementAt(3)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Float fLevel,
                              Pointer<GUID> EventContext)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, double fLevel, Pointer<GUID> EventContext)>()(
          ptr.ref.lpVtbl, fLevel, EventContext);

  int GetMasterVolume(Pointer<Float> pfLevel) => ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Float> pfLevel)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Float> pfLevel)>()(
      ptr.ref.lpVtbl, pfLevel);

  int SetMute(int bMute, Pointer<GUID> EventContext) => ptr.ref.vtable
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Int32 bMute, Pointer<GUID> EventContext)>>>()
          .value
          .asFunction<
              int Function(Pointer, int bMute, Pointer<GUID> EventContext)>()(
      ptr.ref.lpVtbl, bMute, EventContext);

  int GetMute(Pointer<Int32> pbMute) => ptr.ref.vtable
      .elementAt(6)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<Int32> pbMute)>>>()
      .value
      .asFunction<
          int Function(
              Pointer, Pointer<Int32> pbMute)>()(ptr.ref.lpVtbl, pbMute);
}
