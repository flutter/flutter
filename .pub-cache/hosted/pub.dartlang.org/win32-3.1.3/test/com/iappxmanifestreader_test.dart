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

  final appxmanifestreader = IAppxManifestReader(ptr);
  test('Can instantiate IAppxManifestReader.getPackageId', () {
    expect(appxmanifestreader.getPackageId, isA<Function>());
  });
  test('Can instantiate IAppxManifestReader.getProperties', () {
    expect(appxmanifestreader.getProperties, isA<Function>());
  });
  test('Can instantiate IAppxManifestReader.getPackageDependencies', () {
    expect(appxmanifestreader.getPackageDependencies, isA<Function>());
  });
  test('Can instantiate IAppxManifestReader.getCapabilities', () {
    expect(appxmanifestreader.getCapabilities, isA<Function>());
  });
  test('Can instantiate IAppxManifestReader.getResources', () {
    expect(appxmanifestreader.getResources, isA<Function>());
  });
  test('Can instantiate IAppxManifestReader.getDeviceCapabilities', () {
    expect(appxmanifestreader.getDeviceCapabilities, isA<Function>());
  });
  test('Can instantiate IAppxManifestReader.getPrerequisite', () {
    expect(appxmanifestreader.getPrerequisite, isA<Function>());
  });
  test('Can instantiate IAppxManifestReader.getApplications', () {
    expect(appxmanifestreader.getApplications, isA<Function>());
  });
  test('Can instantiate IAppxManifestReader.getStream', () {
    expect(appxmanifestreader.getStream, isA<Function>());
  });
  free(ptr);
}
