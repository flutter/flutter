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

/// Represents an x- and y-coordinate pair in two-dimensional space. Can
/// also represent a logical point for certain property usages.
///
/// {@category Struct}
class Point extends Struct {
  @Float()
  external double X;

  @Float()
  external double Y;
}

/// Describes the width, height, and point origin of a rectangle.
///
/// {@category Struct}
class Rect extends Struct {
  @Float()
  external double X;

  @Float()
  external double Y;

  @Float()
  external double Width;

  @Float()
  external double Height;
}

/// Describes the width and height of an object.
///
/// {@category Struct}
class Size extends Struct {
  @Float()
  external double Width;

  @Float()
  external double Height;
}
