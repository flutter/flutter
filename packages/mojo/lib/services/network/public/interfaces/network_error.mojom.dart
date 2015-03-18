// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library network_error.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;


class NetworkError extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int code = 0;
  String description = null;

  NetworkError() : super(kStructSize);

  static NetworkError deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static NetworkError decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    NetworkError result = new NetworkError();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.code = decoder0.decodeInt32(8);
    }
    {
      
      result.description = decoder0.decodeString(16, true);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(code, 8);
    
    encoder0.encodeString(description, 16, true);
  }

  String toString() {
    return "NetworkError("
           "code: $code" ", "
           "description: $description" ")";
  }
}

