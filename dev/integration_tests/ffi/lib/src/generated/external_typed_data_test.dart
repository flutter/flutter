// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'expect.dart';
import "package:ffi/ffi.dart";

main() {
  testInt8Load();
  testInt8Store();
  testUint8Load();
  testUint8Store();
  testInt16Load();
  testInt16Store();
  testUint16Load();
  testUint16Store();
  testInt32Load();
  testInt32Store();
  testUint32Load();
  testUint32Store();
  testInt64Load();
  testInt64Store();
  testUint64Load();
  testUint64Store();
  testFloatLoad();
  testFloatStore();
  testDoubleLoad();
  testDoubleStore();
  testArrayLoad();
  testArrayStore();
  testNegativeArray();
  testAlignment();
}

// For signed int tests, we store 0xf* and load -1 to check sign-extension.
// For unsigned int tests, we store 0xf* and load the same to check truncation.

void testInt8Load() {
  // Load
  Pointer<Int8> ptr = allocate();
  ptr.value = 0xff;
  Int8List list = ptr.asTypedList(1);
  Expect.equals(list[0], -1);
  Expect.equals(list.length, 1);
  free(ptr);
}

void testInt8Store() {
  // Store
  Pointer<Int8> ptr = allocate();
  Int8List list = ptr.asTypedList(1);
  list[0] = 0xff;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, -1);
  free(ptr);
}

void testUint8Load() {
  // Load
  Pointer<Uint8> ptr = allocate();
  ptr.value = 0xff;
  Uint8List list = ptr.asTypedList(1);
  Expect.equals(list[0], 0xff);
  Expect.equals(list.length, 1);
  free(ptr);
}

void testUint8Store() {
  // Store
  Pointer<Uint8> ptr = allocate();
  Uint8List list = ptr.asTypedList(1);
  list[0] = 0xff;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, 0xff);
  free(ptr);
}

void testInt16Load() {
  // Load
  Pointer<Int16> ptr = allocate();
  ptr.value = 0xffff;
  Int16List list = ptr.asTypedList(1);
  Expect.equals(list[0], -1);
  Expect.equals(list.length, 1);
  free(ptr);
}

void testInt16Store() {
  // Store
  Pointer<Int16> ptr = allocate();
  Int16List list = ptr.asTypedList(1);
  list[0] = 0xffff;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, -1);
  free(ptr);
}

void testUint16Load() {
  // Load
  Pointer<Uint16> ptr = allocate();
  ptr.value = 0xffff;
  Uint16List list = ptr.asTypedList(1);
  Expect.equals(list[0], 0xffff);
  Expect.equals(list.length, 1);
  free(ptr);
}

void testUint16Store() {
  // Store
  Pointer<Uint16> ptr = allocate();
  Uint16List list = ptr.asTypedList(1);
  list[0] = 0xffff;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, 0xffff);
  free(ptr);
}

void testInt32Load() {
  // Load
  Pointer<Int32> ptr = allocate();
  ptr.value = 0xffffffff;
  Int32List list = ptr.asTypedList(1);
  Expect.equals(list[0], -1);
  Expect.equals(list.length, 1);
  free(ptr);
}

void testInt32Store() {
  // Store
  Pointer<Int32> ptr = allocate();
  Int32List list = ptr.asTypedList(1);
  list[0] = 0xffffffff;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, -1);
  free(ptr);
}

void testUint32Load() {
  // Load
  Pointer<Uint32> ptr = allocate();
  ptr.value = 0xffffffff;
  Uint32List list = ptr.asTypedList(1);
  Expect.equals(list[0], 0xffffffff);
  Expect.equals(list.length, 1);
  free(ptr);
}

void testUint32Store() {
  // Store
  Pointer<Uint32> ptr = allocate();
  Uint32List list = ptr.asTypedList(1);
  list[0] = 0xffffffff;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, 0xffffffff);
  free(ptr);
}

void testInt64Load() {
  // Load
  Pointer<Int64> ptr = allocate();
  ptr.value = 0xffffffffffffffff;
  Int64List list = ptr.asTypedList(1);
  Expect.equals(list[0], -1);
  Expect.equals(list.length, 1);
  free(ptr);
}

void testInt64Store() {
  // Store
  Pointer<Int64> ptr = allocate();
  Int64List list = ptr.asTypedList(1);
  list[0] = 0xffffffffffffffff;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, -1);
  free(ptr);
}

void testUint64Load() {
  // Load
  Pointer<Uint64> ptr = allocate();
  ptr.value = 0xffffffffffffffff;
  Uint64List list = ptr.asTypedList(1);
  Expect.equals(list[0], 0xffffffffffffffff);
  Expect.equals(list.length, 1);
  free(ptr);
}

void testUint64Store() {
  // Store
  Pointer<Uint64> ptr = allocate();
  Uint64List list = ptr.asTypedList(1);
  list[0] = 0xffffffffffffffff;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, 0xffffffffffffffff);
  free(ptr);
}

double maxFloat = (2 - pow(2, -23)) * pow(2, 127);
double maxDouble = (2 - pow(2, -52)) * pow(2, pow(2, 10) - 1);

void testFloatLoad() {
  // Load
  Pointer<Float> ptr = allocate();
  ptr.value = maxFloat;
  Float32List list = ptr.asTypedList(1);
  Expect.equals(list[0], maxFloat);
  Expect.equals(list.length, 1);
  free(ptr);
}

void testFloatStore() {
  // Store
  Pointer<Float> ptr = allocate();
  Float32List list = ptr.asTypedList(1);
  list[0] = maxFloat;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, maxFloat);
  free(ptr);
}

void testDoubleLoad() {
  // Load
  Pointer<Double> ptr = allocate();
  ptr.value = maxDouble;
  Float64List list = ptr.asTypedList(1);
  Expect.equals(list[0], maxDouble);
  Expect.equals(list.length, 1);
  free(ptr);
}

void testDoubleStore() {
  // Store
  Pointer<Double> ptr = allocate();
  Float64List list = ptr.asTypedList(1);
  list[0] = maxDouble;
  Expect.equals(list.length, 1);
  Expect.equals(ptr.value, maxDouble);
  free(ptr);
}

void testArrayLoad() {
  const int count = 0x100;
  Pointer<Int32> ptr = allocate(count: count);
  for (int i = 0; i < count; ++i) {
    ptr[i] = i;
  }
  Int32List array = ptr.asTypedList(count);
  for (int i = 0; i < count; ++i) {
    Expect.equals(array[i], i);
  }
  free(ptr);
}

void testArrayStore() {
  const int count = 0x100;
  Pointer<Int32> ptr = allocate(count: count);
  Int32List array = ptr.asTypedList(count);
  for (int i = 0; i < count; ++i) {
    array[i] = i;
  }
  for (int i = 0; i < count; ++i) {
    Expect.equals(ptr[i], i);
  }
  free(ptr);
}

void testNegativeArray() {
  Pointer<Int32> ptr = nullptr;
  Expect.throws<ArgumentError>(() => ptr.asTypedList(-1));
}

// Tests that the address we're creating an ExternalTypedData from is aligned to
// the element size.
void testAlignment() {
  Expect.throws<ArgumentError>(
      () => Pointer<Int16>.fromAddress(1).asTypedList(1));
  Expect.throws<ArgumentError>(
      () => Pointer<Int32>.fromAddress(2).asTypedList(1));
  Expect.throws<ArgumentError>(
      () => Pointer<Int64>.fromAddress(4).asTypedList(1));
  Expect.throws<ArgumentError>(
      () => Pointer<Uint16>.fromAddress(1).asTypedList(1));
  Expect.throws<ArgumentError>(
      () => Pointer<Uint32>.fromAddress(2).asTypedList(1));
  Expect.throws<ArgumentError>(
      () => Pointer<Uint64>.fromAddress(4).asTypedList(1));
  Expect.throws<ArgumentError>(
      () => Pointer<Float>.fromAddress(2).asTypedList(1));
  Expect.throws<ArgumentError>(
      () => Pointer<Double>.fromAddress(4).asTypedList(1));
}
