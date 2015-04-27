// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library network_error.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;


class NetworkError extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int code = 0;
  String description = null;

  NetworkError() : super(kVersions.last.size);

  static NetworkError deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static NetworkError decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    NetworkError result = new NetworkError();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.code = decoder0.decodeInt32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.description = decoder0.decodeString(16, true);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInt32(code, 8);
    
    encoder0.encodeString(description, 16, true);
  }

  String toString() {
    return "NetworkError("
           "code: $code" ", "
           "description: $description" ")";
  }
}

