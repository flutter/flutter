// idesktopwallpaper.dart

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
const IID_IDesktopWallpaper = '{B92B56A9-8B55-4E14-9A89-0199BBB6F93B}';

/// {@category Interface}
/// {@category com}
class IDesktopWallpaper extends IUnknown {
  // vtable begins at 3, is 16 entries long.
  IDesktopWallpaper(super.ptr);

  int SetWallpaper(Pointer<Utf16> monitorID, Pointer<Utf16> wallpaper) => ptr
          .ref.vtable
          .elementAt(3)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Utf16> monitorID,
                          Pointer<Utf16> wallpaper)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Utf16> monitorID,
                  Pointer<Utf16> wallpaper)>()(
      ptr.ref.lpVtbl, monitorID, wallpaper);

  int GetWallpaper(
          Pointer<Utf16> monitorID, Pointer<Pointer<Utf16>> wallpaper) =>
      ptr.ref.vtable
              .elementAt(4)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<Utf16> monitorID,
                              Pointer<Pointer<Utf16>> wallpaper)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Utf16> monitorID,
                      Pointer<Pointer<Utf16>> wallpaper)>()(
          ptr.ref.lpVtbl, monitorID, wallpaper);

  int GetMonitorDevicePathAt(
          int monitorIndex, Pointer<Pointer<Utf16>> monitorID) =>
      ptr
              .ref.vtable
              .elementAt(5)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Uint32 monitorIndex,
                              Pointer<Pointer<Utf16>> monitorID)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int monitorIndex,
                      Pointer<Pointer<Utf16>> monitorID)>()(
          ptr.ref.lpVtbl, monitorIndex, monitorID);

  int GetMonitorDevicePathCount(Pointer<Uint32> count) => ptr.ref.vtable
      .elementAt(6)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<Uint32> count)>>>()
      .value
      .asFunction<
          int Function(
              Pointer, Pointer<Uint32> count)>()(ptr.ref.lpVtbl, count);

  int GetMonitorRECT(Pointer<Utf16> monitorID, Pointer<RECT> displayRect) =>
      ptr.ref.vtable
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<Utf16> monitorID,
                              Pointer<RECT> displayRect)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Utf16> monitorID,
                      Pointer<RECT> displayRect)>()(
          ptr.ref.lpVtbl, monitorID, displayRect);

  int SetBackgroundColor(int color) => ptr.ref.vtable
      .elementAt(8)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Uint32 color)>>>()
      .value
      .asFunction<int Function(Pointer, int color)>()(ptr.ref.lpVtbl, color);

  int GetBackgroundColor(Pointer<Uint32> color) => ptr.ref.vtable
      .elementAt(9)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<Uint32> color)>>>()
      .value
      .asFunction<
          int Function(
              Pointer, Pointer<Uint32> color)>()(ptr.ref.lpVtbl, color);

  int SetPosition(int position) => ptr.ref.vtable
      .elementAt(10)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Int32 position)>>>()
      .value
      .asFunction<
          int Function(Pointer, int position)>()(ptr.ref.lpVtbl, position);

  int GetPosition(Pointer<Int32> position) => ptr.ref.vtable
          .elementAt(11)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<Int32> position)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<Int32> position)>()(
      ptr.ref.lpVtbl, position);

  int SetSlideshow(Pointer<COMObject> items) => ptr.ref.vtable
          .elementAt(12)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(Pointer, Pointer<COMObject> items)>>>()
          .value
          .asFunction<int Function(Pointer, Pointer<COMObject> items)>()(
      ptr.ref.lpVtbl, items);

  int GetSlideshow(Pointer<Pointer<COMObject>> items) => ptr.ref.vtable
          .elementAt(13)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Pointer<Pointer<COMObject>> items)>>>()
          .value
          .asFunction<
              int Function(Pointer, Pointer<Pointer<COMObject>> items)>()(
      ptr.ref.lpVtbl, items);

  int SetSlideshowOptions(int options, int slideshowTick) => ptr.ref.vtable
          .elementAt(14)
          .cast<
              Pointer<
                  NativeFunction<
                      Int32 Function(
                          Pointer, Int32 options, Uint32 slideshowTick)>>>()
          .value
          .asFunction<int Function(Pointer, int options, int slideshowTick)>()(
      ptr.ref.lpVtbl, options, slideshowTick);

  int GetSlideshowOptions(
          Pointer<Int32> options, Pointer<Uint32> slideshowTick) =>
      ptr.ref.vtable
              .elementAt(15)
              .cast<
                  Pointer<
                      NativeFunction<
                          Int32 Function(Pointer, Pointer<Int32> options,
                              Pointer<Uint32> slideshowTick)>>>()
              .value
              .asFunction<
                  int Function(Pointer, Pointer<Int32> options,
                      Pointer<Uint32> slideshowTick)>()(
          ptr.ref.lpVtbl, options, slideshowTick);

  int AdvanceSlideshow(Pointer<Utf16> monitorID, int direction) => ptr
      .ref.vtable
      .elementAt(16)
      .cast<
          Pointer<
              NativeFunction<
                  Int32 Function(
                      Pointer, Pointer<Utf16> monitorID, Int32 direction)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<Utf16> monitorID,
              int direction)>()(ptr.ref.lpVtbl, monitorID, direction);

  int GetStatus(Pointer<Int32> state) => ptr.ref.vtable
      .elementAt(17)
      .cast<
          Pointer<
              NativeFunction<Int32 Function(Pointer, Pointer<Int32> state)>>>()
      .value
      .asFunction<
          int Function(Pointer, Pointer<Int32> state)>()(ptr.ref.lpVtbl, state);

  int Enable(int enable) => ptr.ref.vtable
      .elementAt(18)
      .cast<Pointer<NativeFunction<Int32 Function(Pointer, Int32 enable)>>>()
      .value
      .asFunction<int Function(Pointer, int enable)>()(ptr.ref.lpVtbl, enable);
}

/// @nodoc
const CLSID_DesktopWallpaper = '{C2CF3110-460E-4FC1-B9D0-8A1C0C9CC4BD}';

/// {@category com}
class DesktopWallpaper extends IDesktopWallpaper {
  DesktopWallpaper(super.ptr);

  factory DesktopWallpaper.createInstance() => DesktopWallpaper(
      COMObject.createFromID(CLSID_DesktopWallpaper, IID_IDesktopWallpaper));
}
