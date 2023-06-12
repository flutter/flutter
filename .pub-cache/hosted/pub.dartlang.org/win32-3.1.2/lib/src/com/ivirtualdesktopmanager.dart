// ivirtualdesktopmanager.dart

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
const IID_IVirtualDesktopManager = '{a5cd92ff-29be-454c-8d04-d82879fb3f1b}';

/// {@category Interface}
/// {@category com}
class IVirtualDesktopManager extends IUnknown {
  // vtable begins at 3, is 3 entries long.
  IVirtualDesktopManager(super.ptr);

  factory IVirtualDesktopManager.from(IUnknown interface) =>
      IVirtualDesktopManager(interface.toInterface(IID_IVirtualDesktopManager));

  int isWindowOnCurrentVirtualDesktop(
          int topLevelWindow, Pointer<Int32> onCurrentDesktop) =>
      ptr.ref.vtable
              .elementAt(3)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, IntPtr topLevelWindow,
                              Pointer<Int32> onCurrentDesktop)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int topLevelWindow,
                      Pointer<Int32> onCurrentDesktop)>()(
          ptr.ref.lpVtbl, topLevelWindow, onCurrentDesktop);

  int getWindowDesktopId(int topLevelWindow, Pointer<GUID> desktopId) =>
      ptr.ref.vtable
              .elementAt(4)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, IntPtr topLevelWindow,
                              Pointer<GUID> desktopId)>>>()
              .value
              .asFunction<
                  int Function(
                      Pointer, int topLevelWindow, Pointer<GUID> desktopId)>()(
          ptr.ref.lpVtbl, topLevelWindow, desktopId);

  int moveWindowToDesktop(int topLevelWindow, Pointer<GUID> desktopId) => ptr
          .ref.vtable
          .elementAt(5)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, IntPtr topLevelWindow,
                          Pointer<GUID> desktopId)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, int topLevelWindow, Pointer<GUID> desktopId)>()(
      ptr.ref.lpVtbl, topLevelWindow, desktopId);
}

/// @nodoc
const CLSID_VirtualDesktopManager = '{aa509086-5ca9-4c25-8f95-589d3c07b48a}';

/// {@category com}
class VirtualDesktopManager extends IVirtualDesktopManager {
  VirtualDesktopManager(super.ptr);

  factory VirtualDesktopManager.createInstance() =>
      VirtualDesktopManager(COMObject.createFromID(
          CLSID_VirtualDesktopManager, IID_IVirtualDesktopManager));
}
