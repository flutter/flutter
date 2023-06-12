// ispeventsource.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import
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
import 'ispnotifysource.dart';
import 'iunknown.dart';

/// @nodoc
const IID_ISpEventSource = '{be7a9cce-5f9e-11d2-960f-00c04f8ee628}';

/// Using the methods on ISpNotifySource an application can specify the
/// mechanism by which it receives notifications.  Applications can
/// configure which events should trigger notifications and which events
/// retrieve queued events. ISpEventSource inherits from the
/// [ISpNotifySource] interface.
///
/// {@category Interface}
/// {@category com}
class ISpEventSource extends ISpNotifySource {
  // vtable begins at 10, is 3 entries long.
  ISpEventSource(super.ptr);

  factory ISpEventSource.from(IUnknown interface) =>
      ISpEventSource(interface.toInterface(IID_ISpEventSource));

  int setInterest(int ullEventInterest, int ullQueuedInterest) => ptr.ref.vtable
          .elementAt(10)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Uint64 ullEventInterest,
                          Uint64 ullQueuedInterest)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, int ullEventInterest, int ullQueuedInterest)>()(
      ptr.ref.lpVtbl, ullEventInterest, ullQueuedInterest);

  int getEvents(int ulCount, Pointer<SPEVENT> pEventArray,
          Pointer<Uint32> pulFetched) =>
      ptr.ref.vtable
              .elementAt(11)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(
                              Pointer,
                              Uint32 ulCount,
                              Pointer<SPEVENT> pEventArray,
                              Pointer<Uint32> pulFetched)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer,
                      int ulCount,
                      Pointer<SPEVENT> pEventArray,
                      Pointer<Uint32> pulFetched)>()(
          ptr.ref.lpVtbl, ulCount, pEventArray, pulFetched);

  int getInfo(Pointer<SPEVENTSOURCEINFO> pInfo) => ptr.ref.vtable
      .elementAt(12)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<SPEVENTSOURCEINFO> pInfo)>>>()
      .value
      .asFunction<
          int Function(Pointer,
              Pointer<SPEVENTSOURCEINFO> pInfo)>()(ptr.ref.lpVtbl, pInfo);
}
