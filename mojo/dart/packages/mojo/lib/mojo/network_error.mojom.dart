// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library network_error_mojom;
import 'package:mojo/bindings.dart' as bindings;




class NetworkError extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int code = 0;
  String description = null;

  NetworkError() : super(kVersions.last.size);

  static NetworkError deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
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
          if (mainDataHeader.size == kVersions[i].size) {
            // Found a match.
            break;
          }
          throw new bindings.MojoCodecError(
              'Header size doesn\'t correspond to known version size.');
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
    try {
      encoder0.encodeInt32(code, 8);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "code of struct NetworkError: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(description, 16, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "description of struct NetworkError: $e";
      rethrow;
    }
  }

  String toString() {
    return "NetworkError("
           "code: $code" ", "
           "description: $description" ")";
  }

  Map toJson() {
    Map map = new Map();
    map["code"] = code;
    map["description"] = description;
    return map;
  }
}



