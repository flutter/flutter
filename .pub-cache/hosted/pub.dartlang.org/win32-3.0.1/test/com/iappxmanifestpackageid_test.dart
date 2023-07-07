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

  final appxmanifestpackageid = IAppxManifestPackageId(ptr);
  test('Can instantiate IAppxManifestPackageId.getName', () {
    expect(appxmanifestpackageid.getName, isA<Function>());
  });
  test('Can instantiate IAppxManifestPackageId.getArchitecture', () {
    expect(appxmanifestpackageid.getArchitecture, isA<Function>());
  });
  test('Can instantiate IAppxManifestPackageId.getPublisher', () {
    expect(appxmanifestpackageid.getPublisher, isA<Function>());
  });
  test('Can instantiate IAppxManifestPackageId.getVersion', () {
    expect(appxmanifestpackageid.getVersion, isA<Function>());
  });
  test('Can instantiate IAppxManifestPackageId.getResourceId', () {
    expect(appxmanifestpackageid.getResourceId, isA<Function>());
  });
  test('Can instantiate IAppxManifestPackageId.comparePublisher', () {
    expect(appxmanifestpackageid.comparePublisher, isA<Function>());
  });
  test('Can instantiate IAppxManifestPackageId.getPackageFullName', () {
    expect(appxmanifestpackageid.getPackageFullName, isA<Function>());
  });
  test('Can instantiate IAppxManifestPackageId.getPackageFamilyName', () {
    expect(appxmanifestpackageid.getPackageFamilyName, isA<Function>());
  });
  free(ptr);
}
