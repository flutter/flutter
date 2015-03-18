// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sample_import2.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
import 'package:mojo/public/interfaces/bindings/tests/sample_import.mojom.dart' as sample_import_mojom;

final int Color_RED = 0;
final int Color_BLACK = Color_RED + 1;


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

class Thing extends bindings.Struct {
  static const int kStructSize = 32;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int shape = sample_import_mojom.Shape_RECTANGLE;
  int color = Color_BLACK;
  sample_import_mojom.Point location = null;
  Size size = null;

  Thing() : super(kStructSize);

  static Thing deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Thing decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Thing result = new Thing();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.shape = decoder0.decodeInt32(8);
    }
    {
      
      result.color = decoder0.decodeInt32(12);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.location = sample_import_mojom.Point.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(24, false);
      result.size = Size.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(shape, 8);
    
    encoder0.encodeInt32(color, 12);
    
    encoder0.encodeStruct(location, 16, false);
    
    encoder0.encodeStruct(size, 24, false);
  }

  String toString() {
    return "Thing("
           "shape: $shape" ", "
           "color: $color" ", "
           "location: $location" ", "
           "size: $size" ")";
  }
}

