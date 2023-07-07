// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that Win32 API prototypes can be successfully loaded (i.e. that
// lookupFunction works for all the APIs generated)

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_local_variable

@TestOn('windows')

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

import 'package:win32/win32.dart';

void main() {
  final ptr = calloc<COMObject>();

  final desktopwallpaper = IDesktopWallpaper(ptr);
  test('Can instantiate IDesktopWallpaper.SetWallpaper', () {
    expect(desktopwallpaper.SetWallpaper, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.GetWallpaper', () {
    expect(desktopwallpaper.GetWallpaper, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.GetMonitorDevicePathAt', () {
    expect(desktopwallpaper.GetMonitorDevicePathAt, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.GetMonitorDevicePathCount', () {
    expect(desktopwallpaper.GetMonitorDevicePathCount, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.GetMonitorRECT', () {
    expect(desktopwallpaper.GetMonitorRECT, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.SetBackgroundColor', () {
    expect(desktopwallpaper.SetBackgroundColor, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.GetBackgroundColor', () {
    expect(desktopwallpaper.GetBackgroundColor, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.SetPosition', () {
    expect(desktopwallpaper.SetPosition, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.GetPosition', () {
    expect(desktopwallpaper.GetPosition, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.SetSlideshow', () {
    expect(desktopwallpaper.SetSlideshow, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.GetSlideshow', () {
    expect(desktopwallpaper.GetSlideshow, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.SetSlideshowOptions', () {
    expect(desktopwallpaper.SetSlideshowOptions, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.GetSlideshowOptions', () {
    expect(desktopwallpaper.GetSlideshowOptions, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.AdvanceSlideshow', () {
    expect(desktopwallpaper.AdvanceSlideshow, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.GetStatus', () {
    expect(desktopwallpaper.GetStatus, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.Enable', () {
    expect(desktopwallpaper.Enable, isA<Function>());
  });
  free(ptr);
}
