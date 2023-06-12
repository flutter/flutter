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
  test('Can instantiate IAppxManifestReader.GetPackageId', () {
    expect(appxmanifestreader.GetPackageId, isA<Function>());
  });
  test('Can instantiate IAppxManifestReader.GetProperties', () {
    expect(appxmanifestreader.GetProperties, isA<Function>());
  });
  test('Can instantiate IAppxManifestReader.GetPackageDependencies', () {
    expect(appxmanifestreader.GetPackageDependencies, isA<Function>());
  });
  test('Can instantiate IAppxManifestReader.GetCapabilities', () {
    expect(appxmanifestreader.GetCapabilities, isA<Function>());
  });
  test('Can instantiate IAppxManifestReader.GetResources', () {
    expect(appxmanifestreader.GetResources, isA<Function>());
  });
  test('Can instantiate IAppxManifestReader.GetDeviceCapabilities', () {
    expect(appxmanifestreader.GetDeviceCapabilities, isA<Function>());
  });
  test('Can instantiate IAppxManifestReader.GetPrerequisite', () {
    expect(appxmanifestreader.GetPrerequisite, isA<Function>());
  });
  test('Can instantiate IAppxManifestReader.GetApplications', () {
    expect(appxmanifestreader.GetApplications, isA<Function>());
  });
  test('Can instantiate IAppxManifestReader.GetStream', () {
    expect(appxmanifestreader.GetStream, isA<Function>());
  });
  free(ptr);
}
