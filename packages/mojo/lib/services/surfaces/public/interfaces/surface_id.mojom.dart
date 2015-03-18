// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library surface_id.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;


class SurfaceId extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int local = 0;
  int idNamespace = 0;

  SurfaceId() : super(kStructSize);

  static SurfaceId deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static SurfaceId decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    SurfaceId result = new SurfaceId();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.local = decoder0.decodeUint32(8);
    }
    {
      
      result.idNamespace = decoder0.decodeUint32(12);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint32(local, 8);
    
    encoder0.encodeUint32(idNamespace, 12);
  }

  String toString() {
    return "SurfaceId("
           "local: $local" ", "
           "idNamespace: $idNamespace" ")";
  }
}

