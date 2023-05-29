// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart representations of common structs used in the Windows Runtime APIs.

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: camel_case_extensions, camel_case_types
// ignore_for_file: directives_ordering, unnecessary_getters_setters
// ignore_for_file: unused_field, unused_import
// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// Describes a 3*2 floating point matrix.
///
/// {@category Struct}
class Matrix3x2 extends Struct {
  @Float()
  external double M11;

  @Float()
  external double M12;

  @Float()
  external double M21;

  @Float()
  external double M22;

  @Float()
  external double M31;

  @Float()
  external double M32;
}

/// Describes a 4*4 floating point matrix.
///
/// {@category Struct}
class Matrix4x4 extends Struct {
  @Float()
  external double M11;

  @Float()
  external double M12;

  @Float()
  external double M13;

  @Float()
  external double M14;

  @Float()
  external double M21;

  @Float()
  external double M22;

  @Float()
  external double M23;

  @Float()
  external double M24;

  @Float()
  external double M31;

  @Float()
  external double M32;

  @Float()
  external double M33;

  @Float()
  external double M34;

  @Float()
  external double M41;

  @Float()
  external double M42;

  @Float()
  external double M43;

  @Float()
  external double M44;
}

/// Describes a plane (a flat, two-dimensional surface).
///
/// {@category Struct}
class Plane extends Struct {
  external Vector3 Normal;

  @Float()
  external double D;
}

/// Describes a quaternion, which is an abstract representation of an
/// orientation in space that is based on complex numbers.
///
/// {@category Struct}
class Quaternion extends Struct {
  @Float()
  external double X;

  @Float()
  external double Y;

  @Float()
  external double Z;

  @Float()
  external double W;
}

/// Describes a number that can be created by the division of 2 integers.
///
/// {@category Struct}
class Rational extends Struct {
  @Uint32()
  external int Numerator;

  @Uint32()
  external int Denominator;
}

/// Describes a vector of two floating-point components.
///
/// {@category Struct}
class Vector2 extends Struct {
  @Float()
  external double X;

  @Float()
  external double Y;
}

/// Describes a vector of three floating-point components.
///
/// {@category Struct}
class Vector3 extends Struct {
  @Float()
  external double X;

  @Float()
  external double Y;

  @Float()
  external double Z;
}

/// Describes a vector of four floating-point components.
///
/// {@category Struct}
class Vector4 extends Struct {
  @Float()
  external double X;

  @Float()
  external double Y;

  @Float()
  external double Z;

  @Float()
  external double W;
}
