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
  test('Can instantiate IAppxManifestPackageId.GetName', () {
    expect(appxmanifestpackageid.GetName, isA<Function>());
  });
  test('Can instantiate IAppxManifestPackageId.GetArchitecture', () {
    expect(appxmanifestpackageid.GetArchitecture, isA<Function>());
  });
  test('Can instantiate IAppxManifestPackageId.GetPublisher', () {
    expect(appxmanifestpackageid.GetPublisher, isA<Function>());
  });
  test('Can instantiate IAppxManifestPackageId.GetVersion', () {
    expect(appxmanifestpackageid.GetVersion, isA<Function>());
  });
  test('Can instantiate IAppxManifestPackageId.GetResourceId', () {
    expect(appxmanifestpackageid.GetResourceId, isA<Function>());
  });
  test('Can instantiate IAppxManifestPackageId.ComparePublisher', () {
    expect(appxmanifestpackageid.ComparePublisher, isA<Function>());
  });
  test('Can instantiate IAppxManifestPackageId.GetPackageFullName', () {
    expect(appxmanifestpackageid.GetPackageFullName, isA<Function>());
  });
  test('Can instantiate IAppxManifestPackageId.GetPackageFamilyName', () {
    expect(appxmanifestpackageid.GetPackageFamilyName, isA<Function>());
  });
  free(ptr);
}
