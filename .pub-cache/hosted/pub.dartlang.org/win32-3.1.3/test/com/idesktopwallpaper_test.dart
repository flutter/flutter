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
  test('Can instantiate IDesktopWallpaper.setWallpaper', () {
    expect(desktopwallpaper.setWallpaper, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.getWallpaper', () {
    expect(desktopwallpaper.getWallpaper, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.getMonitorDevicePathAt', () {
    expect(desktopwallpaper.getMonitorDevicePathAt, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.getMonitorDevicePathCount', () {
    expect(desktopwallpaper.getMonitorDevicePathCount, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.getMonitorRECT', () {
    expect(desktopwallpaper.getMonitorRECT, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.setBackgroundColor', () {
    expect(desktopwallpaper.setBackgroundColor, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.getBackgroundColor', () {
    expect(desktopwallpaper.getBackgroundColor, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.setPosition', () {
    expect(desktopwallpaper.setPosition, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.getPosition', () {
    expect(desktopwallpaper.getPosition, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.setSlideshow', () {
    expect(desktopwallpaper.setSlideshow, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.getSlideshow', () {
    expect(desktopwallpaper.getSlideshow, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.setSlideshowOptions', () {
    expect(desktopwallpaper.setSlideshowOptions, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.getSlideshowOptions', () {
    expect(desktopwallpaper.getSlideshowOptions, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.advanceSlideshow', () {
    expect(desktopwallpaper.advanceSlideshow, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.getStatus', () {
    expect(desktopwallpaper.getStatus, isA<Function>());
  });
  test('Can instantiate IDesktopWallpaper.enable', () {
    expect(desktopwallpaper.enable, isA<Function>());
  });
  free(ptr);
}
