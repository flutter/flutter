// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file contains test functions for the dart:ffi test cases.
// This file is not allowed to depend on any symbols from the embedder and is
// therefore not allowed to use `dart_api.h`. (The flutter/flutter integration
// tests will run dart tests using this library only.)

#include <stddef.h>
#include <stdlib.h>
#include <sys/types.h>

#include <cmath>
#include <iostream>
#include <limits>

#if defined(_WIN32)
#define DART_EXPORT extern "C" __declspec(dllexport)
#else
#define DART_EXPORT                                                            \
  extern "C" __attribute__((visibility("default"))) __attribute((used))
#endif

namespace dart {

#define CHECK(X)                                                               \
  if (!(X)) {                                                                  \
    fprintf(stderr, "%s\n", "Check failed: " #X);                              \
    return 1;                                                                  \
  }

#define CHECK_EQ(X, Y) CHECK((X) == (Y))

////////////////////////////////////////////////////////////////////////////////
// Tests for Dart -> native calls.
//
// Note: If this interface is changed please also update
// sdk/runtime/tools/dartfuzz/ffiapi.dart

// Sums two ints and adds 42.
// Simple function to test trampolines.
// Also used for testing argument exception on passing null instead of a Dart
// int.
DART_EXPORT int32_t SumPlus42(int32_t a, int32_t b) {
  std::cout << "SumPlus42(" << a << ", " << b << ")\n";
  const int32_t retval = 42 + a + b;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Tests for sign and zero extension return values when passed to Dart.
DART_EXPORT uint8_t ReturnMaxUint8() {
  return 0xff;
}

DART_EXPORT uint16_t ReturnMaxUint16() {
  return 0xffff;
}

DART_EXPORT uint32_t ReturnMaxUint32() {
  return 0xffffffff;
}

DART_EXPORT int8_t ReturnMinInt8() {
  return 0x80;
}

DART_EXPORT int16_t ReturnMinInt16() {
  return 0x8000;
}

DART_EXPORT int32_t ReturnMinInt32() {
  return 0x80000000;
}

// Test that return values are truncated by callee before passed to Dart.
DART_EXPORT uint8_t ReturnMaxUint8v2() {
  uint64_t v = 0xabcff;
  // Truncated to 8 bits and zero extended, or truncated to 32 bits, depending
  // on ABI.
  return v;
}

DART_EXPORT uint16_t ReturnMaxUint16v2() {
  uint64_t v = 0xabcffff;
  return v;
}

DART_EXPORT uint32_t ReturnMaxUint32v2() {
  uint64_t v = 0xabcffffffff;
  return v;
}

DART_EXPORT int8_t ReturnMinInt8v2() {
  int64_t v = 0x8abc80;
  return v;
}

DART_EXPORT int16_t ReturnMinInt16v2() {
  int64_t v = 0x8abc8000;
  return v;
}

DART_EXPORT int32_t ReturnMinInt32v2() {
  int64_t v = 0x8abc80000000;
  return v;
}

// Test that arguments are truncated correctly.
DART_EXPORT intptr_t TakeMaxUint8(uint8_t x) {
  std::cout << "TakeMaxUint8(" << static_cast<int>(x) << ")\n";
  return x == 0xff ? 1 : 0;
}

DART_EXPORT intptr_t TakeMaxUint16(uint16_t x) {
  std::cout << "TakeMaxUint16(" << x << ")\n";
  return x == 0xffff ? 1 : 0;
}

DART_EXPORT intptr_t TakeMaxUint32(uint32_t x) {
  std::cout << "TakeMaxUint32(" << x << ")\n";
  return x == 0xffffffff ? 1 : 0;
}

DART_EXPORT intptr_t TakeMinInt8(int8_t x) {
  std::cout << "TakeMinInt8(" << static_cast<int>(x) << ")\n";
  const int64_t expected = -0x80;
  const int64_t received = x;
  return expected == received ? 1 : 0;
}

DART_EXPORT intptr_t TakeMinInt16(int16_t x) {
  std::cout << "TakeMinInt16(" << x << ")\n";
  const int64_t expected = -0x8000;
  const int64_t received = x;
  return expected == received ? 1 : 0;
}

DART_EXPORT intptr_t TakeMinInt32(int32_t x) {
  std::cout << "TakeMinInt32(" << x << ")\n";
  const int64_t expected = INT32_MIN;
  const int64_t received = x;
  return expected == received ? 1 : 0;
}

// Test that arguments are truncated correctly, including stack arguments
DART_EXPORT intptr_t TakeMaxUint8x10(uint8_t a,
                                     uint8_t b,
                                     uint8_t c,
                                     uint8_t d,
                                     uint8_t e,
                                     uint8_t f,
                                     uint8_t g,
                                     uint8_t h,
                                     uint8_t i,
                                     uint8_t j) {
  std::cout << "TakeMaxUint8x10(" << static_cast<int>(a) << ", "
            << static_cast<int>(b) << ", " << static_cast<int>(c) << ", "
            << static_cast<int>(d) << ", " << static_cast<int>(e) << ", "
            << static_cast<int>(f) << ", " << static_cast<int>(g) << ", "
            << static_cast<int>(h) << ", " << static_cast<int>(i) << ", "
            << static_cast<int>(j) << ", "
            << ")\n";
  return (a == 0xff && b == 0xff && c == 0xff && d == 0xff && e == 0xff &&
          f == 0xff && g == 0xff && h == 0xff && i == 0xff && j == 0xff)
             ? 1
             : 0;
}

// Performs some computation on various sized signed ints.
// Used for testing value ranges for signed ints.
DART_EXPORT int64_t IntComputation(int8_t a, int16_t b, int32_t c, int64_t d) {
  std::cout << "IntComputation(" << static_cast<int>(a) << ", " << b << ", "
            << c << ", " << d << ")\n";
  const int64_t retval = d - c + b - a;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Used in regress_39044_test.dart.
DART_EXPORT int64_t Regress39044(int64_t a, int8_t b) {
  std::cout << "Regress39044(" << a << ", " << static_cast<int>(b) << ")\n";
  const int64_t retval = a - b;
  std::cout << "returning " << retval << "\n";
  return retval;
}

DART_EXPORT intptr_t Regress40537(uint8_t x) {
  std::cout << "Regress40537(" << static_cast<int>(x) << ")\n";
  return x == 249 ? 1 : 0;
}

DART_EXPORT intptr_t Regress40537Variant2(uint8_t x) {
  std::cout << "Regress40537Variant2(" << static_cast<int>(x) << ")\n";
  return x;
}

DART_EXPORT uint8_t Regress40537Variant3(intptr_t x) {
  std::cout << "Regress40537Variant3(" << static_cast<int>(x) << ")\n";
  return x;
}

// Performs some computation on various sized unsigned ints.
// Used for testing value ranges for unsigned ints.
DART_EXPORT int64_t UintComputation(uint8_t a,
                                    uint16_t b,
                                    uint32_t c,
                                    uint64_t d) {
  std::cout << "UintComputation(" << static_cast<int>(a) << ", " << b << ", "
            << c << ", " << d << ")\n";
  const uint64_t retval = d - c + b - a;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Multiplies pointer sized intptr_t by three.
// Used for testing pointer sized parameter and return value.
DART_EXPORT intptr_t Times3(intptr_t a) {
  std::cout << "Times3(" << a << ")\n";
  const intptr_t retval = a * 3;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Multiples a double by 1.337.
// Used for testing double parameter and return value.
// Also used for testing argument exception on passing null instead of a Dart
// double.
DART_EXPORT double Times1_337Double(double a) {
  std::cout << "Times1_337Double(" << a << ")\n";
  const double retval = a * 1.337;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Multiples a float by 1.337.
// Used for testing float parameter and return value.
DART_EXPORT float Times1_337Float(float a) {
  std::cout << "Times1_337Float(" << a << ")\n";
  const float retval = a * 1.337f;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Sums many ints.
// Used for testing calling conventions. With so many integers we are using all
// normal parameter registers and some stack slots.
DART_EXPORT intptr_t SumManyInts(intptr_t a,
                                 intptr_t b,
                                 intptr_t c,
                                 intptr_t d,
                                 intptr_t e,
                                 intptr_t f,
                                 intptr_t g,
                                 intptr_t h,
                                 intptr_t i,
                                 intptr_t j) {
  std::cout << "SumManyInts(" << a << ", " << b << ", " << c << ", " << d
            << ", " << e << ", " << f << ", " << g << ", " << h << ", " << i
            << ", " << j << ")\n";
  const intptr_t retval = a + b + c + d + e + f + g + h + i + j;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Sums many ints.
// Used for testing calling conventions. With small integers on stack slots we
// test stack alignment.
DART_EXPORT int16_t SumManySmallInts(int8_t a,
                                     int16_t b,
                                     int8_t c,
                                     int16_t d,
                                     int8_t e,
                                     int16_t f,
                                     int8_t g,
                                     int16_t h,
                                     int8_t i,
                                     int16_t j) {
  std::cout << "SumManySmallInts(" << static_cast<int>(a) << ", " << b << ", "
            << static_cast<int>(c) << ", " << d << ", " << static_cast<int>(e)
            << ", " << f << ", " << static_cast<int>(g) << ", " << h << ", "
            << static_cast<int>(i) << ", " << j << ")\n";
  const int16_t retval = a + b + c + d + e + f + g + h + i + j;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Used for testing floating point argument backfilling on Arm32 in hardfp.
DART_EXPORT double SumFloatsAndDoubles(float a, double b, float c) {
  std::cout << "SumFloatsAndDoubles(" << a << ", " << b << ", " << c << ")\n";
  const double retval = a + b + c;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Very many small integers, tests alignment on stack.
DART_EXPORT int16_t SumVeryManySmallInts(int8_t a01,
                                         int16_t a02,
                                         int8_t a03,
                                         int16_t a04,
                                         int8_t a05,
                                         int16_t a06,
                                         int8_t a07,
                                         int16_t a08,
                                         int8_t a09,
                                         int16_t a10,
                                         int8_t a11,
                                         int16_t a12,
                                         int8_t a13,
                                         int16_t a14,
                                         int8_t a15,
                                         int16_t a16,
                                         int8_t a17,
                                         int16_t a18,
                                         int8_t a19,
                                         int16_t a20,
                                         int8_t a21,
                                         int16_t a22,
                                         int8_t a23,
                                         int16_t a24,
                                         int8_t a25,
                                         int16_t a26,
                                         int8_t a27,
                                         int16_t a28,
                                         int8_t a29,
                                         int16_t a30,
                                         int8_t a31,
                                         int16_t a32,
                                         int8_t a33,
                                         int16_t a34,
                                         int8_t a35,
                                         int16_t a36,
                                         int8_t a37,
                                         int16_t a38,
                                         int8_t a39,
                                         int16_t a40) {
  std::cout << "SumVeryManySmallInts(" << static_cast<int>(a01) << ", " << a02
            << ", " << static_cast<int>(a03) << ", " << a04 << ", "
            << static_cast<int>(a05) << ", " << a06 << ", "
            << static_cast<int>(a07) << ", " << a08 << ", "
            << static_cast<int>(a09) << ", " << a10 << ", "
            << static_cast<int>(a11) << ", " << a12 << ", "
            << static_cast<int>(a13) << ", " << a14 << ", "
            << static_cast<int>(a15) << ", " << a16 << ", "
            << static_cast<int>(a17) << ", " << a18 << ", "
            << static_cast<int>(a19) << ", " << a20 << ", "
            << static_cast<int>(a21) << ", " << a22 << ", "
            << static_cast<int>(a23) << ", " << a24 << ", "
            << static_cast<int>(a25) << ", " << a26 << ", "
            << static_cast<int>(a27) << ", " << a28 << ", "
            << static_cast<int>(a29) << ", " << a30 << ", "
            << static_cast<int>(a31) << ", " << a32 << ", "
            << static_cast<int>(a33) << ", " << a34 << ", "
            << static_cast<int>(a35) << ", " << a36 << ", "
            << static_cast<int>(a37) << ", " << a38 << ", "
            << static_cast<int>(a39) << ", " << a40 << ")\n";
  const int16_t retval = a01 + a02 + a03 + a04 + a05 + a06 + a07 + a08 + a09 +
                         a10 + a11 + a12 + a13 + a14 + a15 + a16 + a17 + a18 +
                         a19 + a20 + a21 + a22 + a23 + a24 + a25 + a26 + a27 +
                         a28 + a29 + a30 + a31 + a32 + a33 + a34 + a35 + a36 +
                         a37 + a38 + a39 + a40;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Very many floating points, tests alignment on stack, and packing in
// floating point registers in hardfp.
DART_EXPORT double SumVeryManyFloatsDoubles(float a01,
                                            double a02,
                                            float a03,
                                            double a04,
                                            float a05,
                                            double a06,
                                            float a07,
                                            double a08,
                                            float a09,
                                            double a10,
                                            float a11,
                                            double a12,
                                            float a13,
                                            double a14,
                                            float a15,
                                            double a16,
                                            float a17,
                                            double a18,
                                            float a19,
                                            double a20,
                                            float a21,
                                            double a22,
                                            float a23,
                                            double a24,
                                            float a25,
                                            double a26,
                                            float a27,
                                            double a28,
                                            float a29,
                                            double a30,
                                            float a31,
                                            double a32,
                                            float a33,
                                            double a34,
                                            float a35,
                                            double a36,
                                            float a37,
                                            double a38,
                                            float a39,
                                            double a40) {
  std::cout << "SumVeryManyFloatsDoubles(" << a01 << ", " << a02 << ", " << a03
            << ", " << a04 << ", " << a05 << ", " << a06 << ", " << a07 << ", "
            << a08 << ", " << a09 << ", " << a10 << ", " << a11 << ", " << a12
            << ", " << a13 << ", " << a14 << ", " << a15 << ", " << a16 << ", "
            << a17 << ", " << a18 << ", " << a19 << ", " << a20 << ", " << a21
            << ", " << a22 << ", " << a23 << ", " << a24 << ", " << a25 << ", "
            << a26 << ", " << a27 << ", " << a28 << ", " << a29 << ", " << a30
            << ", " << a31 << ", " << a32 << ", " << a33 << ", " << a34 << ", "
            << a35 << ", " << a36 << ", " << a37 << ", " << a38 << ", " << a39
            << ", " << a40 << ")\n";
  const double retval = a01 + a02 + a03 + a04 + a05 + a06 + a07 + a08 + a09 +
                        a10 + a11 + a12 + a13 + a14 + a15 + a16 + a17 + a18 +
                        a19 + a20 + a21 + a22 + a23 + a24 + a25 + a26 + a27 +
                        a28 + a29 + a30 + a31 + a32 + a33 + a34 + a35 + a36 +
                        a37 + a38 + a39 + a40;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Sums an odd number of ints.
// Used for testing calling conventions. With so many arguments, and an odd
// number of arguments, we are testing stack alignment on various architectures.
DART_EXPORT intptr_t SumManyIntsOdd(intptr_t a,
                                    intptr_t b,
                                    intptr_t c,
                                    intptr_t d,
                                    intptr_t e,
                                    intptr_t f,
                                    intptr_t g,
                                    intptr_t h,
                                    intptr_t i,
                                    intptr_t j,
                                    intptr_t k) {
  std::cout << "SumManyInts(" << a << ", " << b << ", " << c << ", " << d
            << ", " << e << ", " << f << ", " << g << ", " << h << ", " << i
            << ", " << j << ", " << k << ")\n";
  const intptr_t retval = a + b + c + d + e + f + g + h + i + j + k;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Sums many doubles.
// Used for testing calling conventions. With so many doubles we are using all
// xmm parameter registers and some stack slots.
DART_EXPORT double SumManyDoubles(double a,
                                  double b,
                                  double c,
                                  double d,
                                  double e,
                                  double f,
                                  double g,
                                  double h,
                                  double i,
                                  double j) {
  std::cout << "SumManyDoubles(" << a << ", " << b << ", " << c << ", " << d
            << ", " << e << ", " << f << ", " << g << ", " << h << ", " << i
            << ", " << j << ")\n";
  const double retval = a + b + c + d + e + f + g + h + i + j;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Sums many numbers.
// Used for testing calling conventions. With so many parameters we are using
// both registers and stack slots.
DART_EXPORT double SumManyNumbers(intptr_t a,
                                  float b,
                                  intptr_t c,
                                  double d,
                                  intptr_t e,
                                  float f,
                                  intptr_t g,
                                  double h,
                                  intptr_t i,
                                  float j,
                                  intptr_t k,
                                  double l,
                                  intptr_t m,
                                  float n,
                                  intptr_t o,
                                  double p,
                                  intptr_t q,
                                  float r,
                                  intptr_t s,
                                  double t) {
  std::cout << "SumManyNumbers(" << a << ", " << b << ", " << c << ", " << d
            << ", " << e << ", " << f << ", " << g << ", " << h << ", " << i
            << ", " << j << ", " << k << ", " << l << ", " << m << ", " << n
            << ", " << o << ", " << p << ", " << q << ", " << r << ", " << s
            << ", " << t << ")\n";
  const double retval = a + b + c + d + e + f + g + h + i + j + k + l + m + n +
                        o + p + q + r + s + t;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Assigns 1337 to the second element and returns the address of that element.
// Used for testing Pointer parameters and return values.
DART_EXPORT int64_t* Assign1337Index1(int64_t* a) {
  std::cout << "Assign1337Index1(" << a << ")\n";
  std::cout << "val[0] = " << a[0] << "\n";
  std::cout << "val[1] = " << a[1] << "\n";
  a[1] = 1337;
  std::cout << "val[1] = " << a[1] << "\n";
  int64_t* retval = a + 1;
  std::cout << "returning " << retval << "\n";
  return retval;
}

struct Coord {
  double x;
  double y;
  Coord* next;
};

// Transposes Coordinate by (10, 10) and returns next Coordinate.
// Used for testing struct pointer parameter, struct pointer return value,
// struct field access, and struct pointer field dereference.
DART_EXPORT Coord* TransposeCoordinate(Coord* coord) {
  std::cout << "TransposeCoordinate(" << coord << " {" << coord->x << ", "
            << coord->y << ", " << coord->next << "})\n";
  coord->x = coord->x + 10.0;
  coord->y = coord->y + 10.0;
  std::cout << "returning " << coord->next << "\n";
  return coord->next;
}

// Takes a Coordinate array and returns a Coordinate pointer to the next
// element.
// Used for testing struct arrays.
DART_EXPORT Coord* CoordinateElemAt1(Coord* coord) {
  std::cout << "CoordinateElemAt1(" << coord << ")\n";
  std::cout << "sizeof(Coord): " << sizeof(Coord) << "\n";
  std::cout << "coord[0] = {" << coord[0].x << ", " << coord[0].y << ", "
            << coord[0].next << "}\n";
  std::cout << "coord[1] = {" << coord[1].x << ", " << coord[1].y << ", "
            << coord[1].next << "}\n";
  Coord* retval = coord + 1;
  std::cout << "returning " << retval << "\n";
  return retval;
}

typedef Coord* (*CoordUnOp)(Coord* coord);

// Takes a Coordinate Function(Coordinate) and applies it three times to a
// Coordinate.
// Used for testing function pointers with structs.
DART_EXPORT Coord* CoordinateUnOpTrice(CoordUnOp unop, Coord* coord) {
  std::cout << "CoordinateUnOpTrice(" << &unop << ", " << coord << ")\n";
  Coord* retval = unop(unop(unop(coord)));
  std::cout << "returning " << retval << "\n";
  return retval;
}

typedef intptr_t (*IntptrBinOp)(intptr_t a, intptr_t b);

// Returns a closure.
// Note this closure is not properly marked as DART_EXPORT or extern "C".
// Used for testing passing a pointer to a closure to Dart.
// TODO(dacoharkes): is this a supported use case?
DART_EXPORT IntptrBinOp IntptrAdditionClosure() {
  std::cout << "IntptrAdditionClosure()\n";
  IntptrBinOp retval = [](intptr_t a, intptr_t b) { return a + b; };
  std::cout << "returning " << &retval << "\n";
  return retval;
}

// Applies an intptr binop function to 42 and 74.
// Used for testing passing a function pointer to C.
DART_EXPORT intptr_t ApplyTo42And74(IntptrBinOp binop) {
  std::cout << "ApplyTo42And74()\n";
  intptr_t retval = binop(42, 74);
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Returns next element in the array, unless a null pointer is passed.
// When a null pointer is passed, a null pointer is returned.
// Used for testing null pointers.
DART_EXPORT int64_t* NullableInt64ElemAt1(int64_t* a) {
  std::cout << "NullableInt64ElemAt1(" << a << ")\n";
  int64_t* retval;
  if (a != nullptr) {
    std::cout << "not null pointer, address: " << a << "\n";
    retval = a + 1;
  } else {
    std::cout << "null pointer, address: " << a << "\n";
    retval = nullptr;
  }
  std::cout << "returning " << retval << "\n";
  return retval;
}

// A struct designed to exercise all kinds of alignment rules.
// Note that offset32A (System V ia32) aligns doubles on 4 bytes while offset32B
// (Arm 32 bit and MSVC ia32) aligns on 8 bytes.
// TODO(37271): Support nested structs.
// TODO(37470): Add uncommon primitive data types when we want to support them.
struct VeryLargeStruct {
  //                             size32 size64 offset32A offset32B offset64
  int8_t a;                   // 1              0         0         0
  int16_t b;                  // 2              2         2         2
  int32_t c;                  // 4              4         4         4
  int64_t d;                  // 8              8         8         8
  uint8_t e;                  // 1             16        16        16
  uint16_t f;                 // 2             18        18        18
  uint32_t g;                 // 4             20        20        20
  uint64_t h;                 // 8             24        24        24
  intptr_t i;                 // 4      8      32        32        32
  double j;                   // 8             36        40        40
  float k;                    // 4             44        48        48
  VeryLargeStruct* parent;    // 4      8      48        52        56
  intptr_t numChildren;       // 4      8      52        56        64
  VeryLargeStruct* children;  // 4      8      56        60        72
  int8_t smallLastField;      // 1             60        64        80
                              // sizeof        64        72        88
};

// Sums the fields of a very large struct, including the first field (a) from
// the parent and children.
// Used for testing alignment and padding in structs.
DART_EXPORT int64_t SumVeryLargeStruct(VeryLargeStruct* vls) {
  std::cout << "SumVeryLargeStruct(" << vls << ")\n";
  std::cout << "offsetof(a): " << offsetof(VeryLargeStruct, a) << "\n";
  std::cout << "offsetof(b): " << offsetof(VeryLargeStruct, b) << "\n";
  std::cout << "offsetof(c): " << offsetof(VeryLargeStruct, c) << "\n";
  std::cout << "offsetof(d): " << offsetof(VeryLargeStruct, d) << "\n";
  std::cout << "offsetof(e): " << offsetof(VeryLargeStruct, e) << "\n";
  std::cout << "offsetof(f): " << offsetof(VeryLargeStruct, f) << "\n";
  std::cout << "offsetof(g): " << offsetof(VeryLargeStruct, g) << "\n";
  std::cout << "offsetof(h): " << offsetof(VeryLargeStruct, h) << "\n";
  std::cout << "offsetof(i): " << offsetof(VeryLargeStruct, i) << "\n";
  std::cout << "offsetof(j): " << offsetof(VeryLargeStruct, j) << "\n";
  std::cout << "offsetof(k): " << offsetof(VeryLargeStruct, k) << "\n";
  std::cout << "offsetof(parent): " << offsetof(VeryLargeStruct, parent)
            << "\n";
  std::cout << "offsetof(numChildren): "
            << offsetof(VeryLargeStruct, numChildren) << "\n";
  std::cout << "offsetof(children): " << offsetof(VeryLargeStruct, children)
            << "\n";
  std::cout << "offsetof(smallLastField): "
            << offsetof(VeryLargeStruct, smallLastField) << "\n";
  std::cout << "sizeof(VeryLargeStruct): " << sizeof(VeryLargeStruct) << "\n";

  std::cout << "vls->a: " << static_cast<int>(vls->a) << "\n";
  std::cout << "vls->b: " << vls->b << "\n";
  std::cout << "vls->c: " << vls->c << "\n";
  std::cout << "vls->d: " << vls->d << "\n";
  std::cout << "vls->e: " << static_cast<int>(vls->e) << "\n";
  std::cout << "vls->f: " << vls->f << "\n";
  std::cout << "vls->g: " << vls->g << "\n";
  std::cout << "vls->h: " << vls->h << "\n";
  std::cout << "vls->i: " << vls->i << "\n";
  std::cout << "vls->j: " << vls->j << "\n";
  std::cout << "vls->k: " << vls->k << "\n";
  std::cout << "vls->parent: " << vls->parent << "\n";
  std::cout << "vls->numChildren: " << vls->numChildren << "\n";
  std::cout << "vls->children: " << vls->children << "\n";
  std::cout << "vls->smallLastField: " << static_cast<int>(vls->smallLastField)
            << "\n";

  int64_t retval = 0;
  retval += 0x0L + vls->a;
  retval += vls->b;
  retval += vls->c;
  retval += vls->d;
  retval += vls->e;
  retval += vls->f;
  retval += vls->g;
  retval += vls->h;
  retval += vls->i;
  retval += vls->j;
  retval += vls->k;
  retval += vls->smallLastField;
  std::cout << retval << "\n";
  if (vls->parent != nullptr) {
    std::cout << "has parent\n";
    retval += vls->parent->a;
  }
  std::cout << "has " << vls->numChildren << " children\n";
  for (intptr_t i = 0; i < vls->numChildren; i++) {
    retval += vls->children[i].a;
  }
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Sums numbers of various sizes.
// Used for testing truncation and sign extension of non 64 bit parameters.
DART_EXPORT int64_t SumSmallNumbers(int8_t a,
                                    int16_t b,
                                    int32_t c,
                                    uint8_t d,
                                    uint16_t e,
                                    uint32_t f) {
  std::cout << "SumSmallNumbers(" << static_cast<int>(a) << ", " << b << ", "
            << c << ", " << static_cast<int>(d) << ", " << e << ", " << f
            << ")\n";
  int64_t retval = 0;
  retval += a;
  retval += b;
  retval += c;
  retval += d;
  retval += e;
  retval += f;
  std::cout << "returning " << retval << "\n";
  return retval;
}

// Checks whether the float is between 1336.0f and 1338.0f.
// Used for testing rounding of Dart Doubles to floats in Pointer.store().
DART_EXPORT uint8_t IsRoughly1337(float* a) {
  std::cout << "IsRoughly1337(" << a[0] << ")\n";
  uint8_t retval = (1336.0f < a[0] && a[0] < 1338.0f) ? 1 : 0;
  std::cout << "returning " << static_cast<int>(retval) << "\n";
  return retval;
}

// Does nothing with input.
// Used for testing functions that return void
DART_EXPORT void DevNullFloat(float a) {
  std::cout << "DevNullFloat(" << a << ")\n";
  std::cout << "returning nothing\n";
}

// Invents an elite floating pointptr_t number.
// Used for testing functions that do not take any arguments.
DART_EXPORT float InventFloatValue() {
  std::cout << "InventFloatValue()\n";
  const float retval = 1337.0f;
  std::cout << "returning " << retval << "\n";
  return retval;
}

////////////////////////////////////////////////////////////////////////////////
// Tests for callbacks.

// Sanity test.
DART_EXPORT intptr_t TestSimpleAddition(intptr_t (*add)(int, int)) {
  CHECK_EQ(add(10, 20), 30);
  return 0;
}

//// Following tests are copied from above, with the role of Dart and C++ code
//// reversed.

DART_EXPORT intptr_t
TestIntComputation(int64_t (*fn)(int8_t, int16_t, int32_t, int64_t)) {
  CHECK_EQ(fn(125, 250, 500, 1000), 625);
  CHECK_EQ(0x7FFFFFFFFFFFFFFFLL, fn(0, 0, 0, 0x7FFFFFFFFFFFFFFFLL));
  CHECK_EQ(((int64_t)-0x8000000000000000LL),
           fn(0, 0, 0, -0x8000000000000000LL));
  return 0;
}

DART_EXPORT intptr_t
TestUintComputation(uint64_t (*fn)(uint8_t, uint16_t, uint32_t, uint64_t)) {
  CHECK_EQ(0x7FFFFFFFFFFFFFFFLL, fn(0, 0, 0, 0x7FFFFFFFFFFFFFFFLL));
  CHECK_EQ(-0x8000000000000000LL, fn(0, 0, 0, -0x8000000000000000LL));
  CHECK_EQ(-1, (int64_t)fn(0, 0, 0, -1));
  return 0;
}

DART_EXPORT intptr_t TestSimpleMultiply(double (*fn)(double)) {
  CHECK_EQ(fn(2.0), 2.0 * 1.337);
  return 0;
}

DART_EXPORT intptr_t TestSimpleMultiplyFloat(float (*fn)(float)) {
  CHECK(::std::abs(fn(2.0) - 2.0 * 1.337) < 0.001);
  return 0;
}

DART_EXPORT intptr_t TestManyInts(intptr_t (*fn)(intptr_t,
                                                 intptr_t,
                                                 intptr_t,
                                                 intptr_t,
                                                 intptr_t,
                                                 intptr_t,
                                                 intptr_t,
                                                 intptr_t,
                                                 intptr_t,
                                                 intptr_t)) {
  CHECK_EQ(55, fn(1, 2, 3, 4, 5, 6, 7, 8, 9, 10));
  return 0;
}

DART_EXPORT intptr_t TestManyDoubles(double (*fn)(double,
                                                  double,
                                                  double,
                                                  double,
                                                  double,
                                                  double,
                                                  double,
                                                  double,
                                                  double,
                                                  double)) {
  CHECK_EQ(55, fn(1, 2, 3, 4, 5, 6, 7, 8, 9, 10));
  return 0;
}

DART_EXPORT intptr_t TestManyArgs(double (*fn)(intptr_t a,
                                               float b,
                                               intptr_t c,
                                               double d,
                                               intptr_t e,
                                               float f,
                                               intptr_t g,
                                               double h,
                                               intptr_t i,
                                               float j,
                                               intptr_t k,
                                               double l,
                                               intptr_t m,
                                               float n,
                                               intptr_t o,
                                               double p,
                                               intptr_t q,
                                               float r,
                                               intptr_t s,
                                               double t)) {
  CHECK(210.0 == fn(1, 2.0, 3, 4.0, 5, 6.0, 7, 8.0, 9, 10.0, 11, 12.0, 13, 14.0,
                    15, 16.0, 17, 18.0, 19, 20.0));
  return 0;
}

// Used for testing floating point argument backfilling on Arm32 in hardfp.
DART_EXPORT intptr_t TestSumFloatsAndDoubles(double (*fn)(float,
                                                          double,
                                                          float)) {
  CHECK_EQ(6.0, fn(1.0, 2.0, 3.0));
  return 0;
}

// Very many small integers, tests alignment on stack.
DART_EXPORT intptr_t TestSumVeryManySmallInts(int16_t (*fn)(int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t,
                                                            int8_t,
                                                            int16_t)) {
  CHECK_EQ(40 * 41 / 2, fn(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
                           16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28,
                           29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40));
  return 0;
}

// Very many floating points, tests alignment on stack, and packing in
// floating point registers in hardfp.
DART_EXPORT intptr_t TestSumVeryManyFloatsDoubles(double (*fn)(float,
                                                               double,
                                                               float,
                                                               double,
                                                               float,
                                                               double,
                                                               float,
                                                               double,
                                                               float,
                                                               double,
                                                               float,
                                                               double,
                                                               float,
                                                               double,
                                                               float,
                                                               double,
                                                               float,
                                                               double,
                                                               float,
                                                               double,
                                                               float,
                                                               double,
                                                               float,
                                                               double,
                                                               float,
                                                               double,
                                                               float,
                                                               double,
                                                               float,
                                                               double,
                                                               float,
                                                               double,
                                                               float,
                                                               double,
                                                               float,
                                                               double,
                                                               float,
                                                               double,
                                                               float,
                                                               double)) {
  CHECK_EQ(40 * 41 / 2,
           fn(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0,
              13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0,
              24.0, 25.0, 26.0, 27.0, 28.0, 29.0, 30.0, 31.0, 32.0, 33.0, 34.0,
              35.0, 36.0, 37.0, 38.0, 39.0, 40.0));
  return 0;
}

DART_EXPORT intptr_t TestStore(int64_t* (*fn)(int64_t* a)) {
  int64_t p[2] = {42, 1000};
  int64_t* result = fn(p);
  CHECK_EQ(*result, 1337);
  CHECK_EQ(p[1], 1337);
  CHECK_EQ(result, p + 1);
  return 0;
}

DART_EXPORT intptr_t TestReturnNull(int32_t (*fn)()) {
  CHECK_EQ(fn(), 42);
  return 0;
}

DART_EXPORT intptr_t TestNullPointers(int64_t* (*fn)(int64_t* ptr)) {
  CHECK_EQ(fn(nullptr), reinterpret_cast<void*>(sizeof(int64_t)));
  int64_t p[2] = {0};
  CHECK_EQ(fn(p), p + 1);
  return 0;
}

DART_EXPORT intptr_t TestReturnVoid(intptr_t (*return_void)()) {
  CHECK_EQ(return_void(), 0);
  return 0;
}

DART_EXPORT intptr_t TestThrowExceptionDouble(double (*fn)()) {
  CHECK_EQ(fn(), 42.0);
  return 0;
}

DART_EXPORT intptr_t TestThrowExceptionPointer(void* (*fn)()) {
  CHECK_EQ(fn(), nullptr);
  return 0;
}

DART_EXPORT intptr_t TestThrowException(intptr_t (*fn)()) {
  CHECK_EQ(fn(), 42);
  return 0;
}

DART_EXPORT intptr_t TestTakeMaxUint8x10(intptr_t (*fn)(uint8_t,
                                                        uint8_t,
                                                        uint8_t,
                                                        uint8_t,
                                                        uint8_t,
                                                        uint8_t,
                                                        uint8_t,
                                                        uint8_t,
                                                        uint8_t,
                                                        uint8_t)) {
  CHECK_EQ(1, fn(0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF));
  // Check the argument values are properly truncated.
  uint64_t v = 0xabcFF;
  CHECK_EQ(1, fn(v, v, v, v, v, v, v, v, v, v));
  return 0;
}

DART_EXPORT intptr_t TestReturnMaxUint8(uint8_t (*fn)()) {
  std::cout << "TestReturnMaxUint8(fn): " << static_cast<int>(fn()) << "\n";
  CHECK_EQ(0xFF, fn());
  return 0;
}

// Receives some pointer (Pointer<NativeType> in Dart) and writes some bits.
DART_EXPORT void NativeTypePointerParam(void* p) {
  uint8_t* p2 = reinterpret_cast<uint8_t*>(p);
  p2[0] = 42;
}

// Manufactures some pointer (Pointer<NativeType> in Dart) with a bogus address.
DART_EXPORT void* NativeTypePointerReturn() {
  uint64_t bogus_address = 0x13370000;
  return reinterpret_cast<void*>(bogus_address);
}

// Passes some pointer (Pointer<NativeType> in Dart) to Dart as argument.
DART_EXPORT void CallbackNativeTypePointerParam(void (*f)(void*)) {
  void* pointer = malloc(sizeof(int64_t));
  f(pointer);
  free(pointer);
}

// Receives some pointer (Pointer<NativeType> in Dart) from Dart as return
// value.
DART_EXPORT void CallbackNativeTypePointerReturn(void* (*f)()) {
  void* p = f();
  uint8_t* p2 = reinterpret_cast<uint8_t*>(p);
  p2[0] = 42;
}

}  // namespace dart
