// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library url_response_mojom;
import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;

import 'package:mojo/mojo/http_header.mojom.dart' as http_header_mojom;
import 'package:mojo/mojo/network_error.mojom.dart' as network_error_mojom;



class UrlResponse extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(88, 0)
  ];
  network_error_mojom.NetworkError error = null;
  core.MojoDataPipeConsumer body = null;
  int statusCode = 0;
  String url = null;
  String statusLine = null;
  List<http_header_mojom.HttpHeader> headers = null;
  String mimeType = null;
  String charset = null;
  String redirectMethod = null;
  String redirectUrl = null;
  String redirectReferrer = null;

  UrlResponse() : super(kVersions.last.size);

  static UrlResponse deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static UrlResponse decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UrlResponse result = new UrlResponse();

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
      
      var decoder1 = decoder0.decodePointer(8, true);
      result.error = network_error_mojom.NetworkError.decode(decoder1);
    }
    if (mainDataHeader.version >= 0) {
      
      result.body = decoder0.decodeConsumerHandle(16, true);
    }
    if (mainDataHeader.version >= 0) {
      
      result.statusCode = decoder0.decodeUint32(20);
    }
    if (mainDataHeader.version >= 0) {
      
      result.url = decoder0.decodeString(24, true);
    }
    if (mainDataHeader.version >= 0) {
      
      result.statusLine = decoder0.decodeString(32, true);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(40, true);
      if (decoder1 == null) {
        result.headers = null;
      } else {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.headers = new List<http_header_mojom.HttpHeader>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.headers[i1] = http_header_mojom.HttpHeader.decode(decoder2);
        }
      }
    }
    if (mainDataHeader.version >= 0) {
      
      result.mimeType = decoder0.decodeString(48, true);
    }
    if (mainDataHeader.version >= 0) {
      
      result.charset = decoder0.decodeString(56, true);
    }
    if (mainDataHeader.version >= 0) {
      
      result.redirectMethod = decoder0.decodeString(64, true);
    }
    if (mainDataHeader.version >= 0) {
      
      result.redirectUrl = decoder0.decodeString(72, true);
    }
    if (mainDataHeader.version >= 0) {
      
      result.redirectReferrer = decoder0.decodeString(80, true);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    try {
      encoder0.encodeStruct(error, 8, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "error of struct UrlResponse: $e";
      rethrow;
    }
    try {
      encoder0.encodeConsumerHandle(body, 16, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "body of struct UrlResponse: $e";
      rethrow;
    }
    try {
      encoder0.encodeUint32(statusCode, 20);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "statusCode of struct UrlResponse: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(url, 24, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "url of struct UrlResponse: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(statusLine, 32, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "statusLine of struct UrlResponse: $e";
      rethrow;
    }
    try {
      if (headers == null) {
        encoder0.encodeNullPointer(40, true);
      } else {
        var encoder1 = encoder0.encodePointerArray(headers.length, 40, bindings.kUnspecifiedArrayLength);
        for (int i0 = 0; i0 < headers.length; ++i0) {
          encoder1.encodeStruct(headers[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
        }
      }
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "headers of struct UrlResponse: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(mimeType, 48, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "mimeType of struct UrlResponse: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(charset, 56, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "charset of struct UrlResponse: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(redirectMethod, 64, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "redirectMethod of struct UrlResponse: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(redirectUrl, 72, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "redirectUrl of struct UrlResponse: $e";
      rethrow;
    }
    try {
      encoder0.encodeString(redirectReferrer, 80, true);
    } on bindings.MojoCodecError catch(e) {
      e.message = "Error encountered while encoding field "
          "redirectReferrer of struct UrlResponse: $e";
      rethrow;
    }
  }

  String toString() {
    return "UrlResponse("
           "error: $error" ", "
           "body: $body" ", "
           "statusCode: $statusCode" ", "
           "url: $url" ", "
           "statusLine: $statusLine" ", "
           "headers: $headers" ", "
           "mimeType: $mimeType" ", "
           "charset: $charset" ", "
           "redirectMethod: $redirectMethod" ", "
           "redirectUrl: $redirectUrl" ", "
           "redirectReferrer: $redirectReferrer" ")";
  }

  Map toJson() {
    throw new bindings.MojoCodecError(
        'Object containing handles cannot be encoded to JSON.');
  }
}






