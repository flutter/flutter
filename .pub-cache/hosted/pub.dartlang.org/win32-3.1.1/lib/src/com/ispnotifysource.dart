// ispnotifysource.dart

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
const IID_ISpNotifySource = '{5EFF4AEF-8487-11D2-961C-00C04F8EE628}';

/// {@category Interface}
/// {@category com}
class ISpNotifySource extends IUnknown {
  // vtable begins at 3, is 7 entries long.
  ISpNotifySource(super.ptr);

  factory ISpNotifySource.from(IUnknown interface) =>
      ISpNotifySource(interface.toInterface(IID_ISpNotifySource));

  int setNotifySink(Pointer<COMObject> pNotifySink) => ptr.ref.vtable
      .elementAt(3)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(Pointer, Pointer<COMObject> pNotifySink)>>>()
      .value
      .asFunction<
          int Function(Pointer,
              Pointer<COMObject> pNotifySink)>()(ptr.ref.lpVtbl, pNotifySink);

  int setNotifyWindowMessage(int hWnd, int Msg, int wParam, int lParam) =>
      ptr.ref.vtable
          .elementAt(4)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, IntPtr hWnd, Uint32 Msg,
                          IntPtr wParam, IntPtr lParam)>>>()
          .value
          .asFunction<
              int Function(Pointer, int hWnd, int Msg, int wParam,
                  int lParam)>()(ptr.ref.lpVtbl, hWnd, Msg, wParam, lParam);

  int setNotifyCallbackFunction(
          Pointer<Pointer<NativeFunction<SpNotifyCallback>>> pfnCallback,
          int wParam,
          int lParam) =>
      ptr.ref.vtable
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer,
                          Pointer<Pointer<NativeFunction<SpNotifyCallback>>>
                              pfnCallback,
                          IntPtr wParam,
                          IntPtr lParam)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer,
                  Pointer<Pointer<NativeFunction<SpNotifyCallback>>>
                      pfnCallback,
                  int wParam,
                  int lParam)>()(ptr.ref.lpVtbl, pfnCallback, wParam, lParam);

  int setNotifyCallbackInterface(
          Pointer<COMObject> pSpCallback, int wParam, int lParam) =>
      ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<COMObject> pSpCallback,
                          IntPtr wParam, IntPtr lParam)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<COMObject> pSpCallback, int wParam,
                  int lParam)>()(ptr.ref.lpVtbl, pSpCallback, wParam, lParam);

  int setNotifyWin32Event() => ptr.ref.vtable
      .elementAt(7)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer)>>>()
      .value
      .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);

  int waitForNotifyEvent(int dwMilliseconds) => ptr.ref.vtable
      .elementAt(8)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Uint32 dwMilliseconds)>>>()
      .value
      .asFunction<
          int Function(
              Pointer, int dwMilliseconds)>()(ptr.ref.lpVtbl, dwMilliseconds);

  int getNotifyEventHandle() => ptr.ref.vtable
      .elementAt(9)
      .cast<Pointer<NativeFunction<IntPtr Function(Pointer)>>>()
      .value
      .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);
}
