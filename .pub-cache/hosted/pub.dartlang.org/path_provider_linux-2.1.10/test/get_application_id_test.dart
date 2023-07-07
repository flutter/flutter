// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_linux/src/get_application_id_real.dart';

class _FakeGioUtils implements GioUtils {
  int? application;
  Pointer<Utf8>? applicationId;

  @override
  bool libraryIsPresent = false;

  @override
  int gApplicationGetDefault() => application!;

  @override
  Pointer<Utf8> gApplicationGetApplicationId(int app) => applicationId!;
}

void main() {
  late _FakeGioUtils fakeGio;

  setUp(() {
    fakeGio = _FakeGioUtils();
    gioUtilsOverride = fakeGio;
  });

  tearDown(() {
    gioUtilsOverride = null;
  });

  test('returns null if libgio is not available', () {
    expect(getApplicationId(), null);
  });

  test('returns null if g_paplication_get_default returns 0', () {
    fakeGio.libraryIsPresent = true;
    fakeGio.application = 0;
    expect(getApplicationId(), null);
  });

  test('returns null if g_application_get_application_id returns nullptr', () {
    fakeGio.libraryIsPresent = true;
    fakeGio.application = 1;
    fakeGio.applicationId = nullptr;
    expect(getApplicationId(), null);
  });

  test('returns value if g_application_get_application_id returns a value', () {
    fakeGio.libraryIsPresent = true;
    fakeGio.application = 1;
    const String id = 'foo';
    final Pointer<Utf8> idPtr = id.toNativeUtf8();
    fakeGio.applicationId = idPtr;
    expect(getApplicationId(), id);
    calloc.free(idPtr);
  });
}
