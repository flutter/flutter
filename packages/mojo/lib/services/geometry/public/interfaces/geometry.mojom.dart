// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library geometry.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;


class Point extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int x = 0;
  int y = 0;

  Point() : super(kStructSize);

  static Point deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Point decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Point result = new Point();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.x = decoder0.decodeInt32(8);
    }
    {
      
      result.y = decoder0.decodeInt32(12);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(x, 8);
    
    encoder0.encodeInt32(y, 12);
  }

  String toString() {
    return "Point("
           "x: $x" ", "
           "y: $y" ")";
  }
}

class PointF extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  double x = 0.0;
  double y = 0.0;

  PointF() : super(kStructSize);

  static PointF deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static PointF decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    PointF result = new PointF();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.x = decoder0.decodeFloat(8);
    }
    {
      
      result.y = decoder0.decodeFloat(12);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeFloat(x, 8);
    
    encoder0.encodeFloat(y, 12);
  }

  String toString() {
    return "PointF("
           "x: $x" ", "
           "y: $y" ")";
  }
}

class Size extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int width = 0;
  int height = 0;

  Size() : super(kStructSize);

  static Size deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Size decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Size result = new Size();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.width = decoder0.decodeInt32(8);
    }
    {
      
      result.height = decoder0.decodeInt32(12);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(width, 8);
    
    encoder0.encodeInt32(height, 12);
  }

  String toString() {
    return "Size("
           "width: $width" ", "
           "height: $height" ")";
  }
}

class Rect extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int x = 0;
  int y = 0;
  int width = 0;
  int height = 0;

  Rect() : super(kStructSize);

  static Rect deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Rect decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Rect result = new Rect();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.x = decoder0.decodeInt32(8);
    }
    {
      
      result.y = decoder0.decodeInt32(12);
    }
    {
      
      result.width = decoder0.decodeInt32(16);
    }
    {
      
      result.height = decoder0.decodeInt32(20);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(x, 8);
    
    encoder0.encodeInt32(y, 12);
    
    encoder0.encodeInt32(width, 16);
    
    encoder0.encodeInt32(height, 20);
  }

  String toString() {
    return "Rect("
           "x: $x" ", "
           "y: $y" ", "
           "width: $width" ", "
           "height: $height" ")";
  }
}

class RectF extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  double x = 0.0;
  double y = 0.0;
  double width = 0.0;
  double height = 0.0;

  RectF() : super(kStructSize);

  static RectF deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static RectF decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    RectF result = new RectF();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.x = decoder0.decodeFloat(8);
    }
    {
      
      result.y = decoder0.decodeFloat(12);
    }
    {
      
      result.width = decoder0.decodeFloat(16);
    }
    {
      
      result.height = decoder0.decodeFloat(20);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeFloat(x, 8);
    
    encoder0.encodeFloat(y, 12);
    
    encoder0.encodeFloat(width, 16);
    
    encoder0.encodeFloat(height, 20);
  }

  String toString() {
    return "RectF("
           "x: $x" ", "
           "y: $y" ", "
           "width: $width" ", "
           "height: $height" ")";
  }
}

class Transform extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  List<double> matrix = null;

  Transform() : super(kStructSize);

  static Transform deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Transform decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Transform result = new Transform();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.matrix = decoder0.decodeFloatArray(8, bindings.kNothingNullable, 16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeFloatArray(matrix, 8, bindings.kNothingNullable, 16);
  }

  String toString() {
    return "Transform("
           "matrix: $matrix" ")";
  }
}

