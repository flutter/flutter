// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library http_response.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;


class HttpResponse extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(40, 0)
  ];
  int statusCode = 200;
  core.MojoDataPipeConsumer body = null;
  int contentLength = 0;
  String contentType = "text/html; charset=utf-8";
  Map<String, String> customHeaders = null;

  HttpResponse() : super(kVersions.last.size);

  static HttpResponse deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static HttpResponse decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    HttpResponse result = new HttpResponse();

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
      
      result.statusCode = decoder0.decodeUint32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.body = decoder0.decodeConsumerHandle(12, true);
    }
    if (mainDataHeader.version >= 0) {
      
      result.contentLength = decoder0.decodeInt64(16);
    }
    if (mainDataHeader.version >= 0) {
      
      result.contentType = decoder0.decodeString(24, false);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(32, true);
      if (decoder1 == null) {
        result.customHeaders = null;
      } else {
        decoder1.decodeDataHeaderForMap();
        List<String> keys0;
        List<String> values0;
        {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize, false);
          {
            var si2 = decoder2.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
            keys0 = new List<String>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
              keys0[i2] = decoder2.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
            }
          }
        }
        {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, false);
          {
            var si2 = decoder2.decodeDataHeaderForPointerArray(keys0.length);
            values0 = new List<String>(si2.numElements);
            for (int i2 = 0; i2 < si2.numElements; ++i2) {
              
              values0[i2] = decoder2.decodeString(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i2, false);
            }
          }
        }
        result.customHeaders = new Map<String, String>.fromIterables(
            keys0, values0);
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint32(statusCode, 8);
    
    encoder0.encodeConsumerHandle(body, 12, true);
    
    encoder0.encodeInt64(contentLength, 16);
    
    encoder0.encodeString(contentType, 24, false);
    
    if (customHeaders == null) {
      encoder0.encodeNullPointer(32, true);
    } else {
      var encoder1 = encoder0.encoderForMap(32);
      int size0 = customHeaders.length;
      var keys0 = customHeaders.keys.toList();
      var values0 = customHeaders.values.toList();
      
      {
        var encoder2 = encoder1.encodePointerArray(keys0.length, bindings.ArrayDataHeader.kHeaderSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < keys0.length; ++i1) {
          
          encoder2.encodeString(keys0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
      
      {
        var encoder2 = encoder1.encodePointerArray(values0.length, bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize, bindings.kUnspecifiedArrayLength);
        for (int i1 = 0; i1 < values0.length; ++i1) {
          
          encoder2.encodeString(values0[i1], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
        }
      }
    }
  }

  String toString() {
    return "HttpResponse("
           "statusCode: $statusCode" ", "
           "body: $body" ", "
           "contentLength: $contentLength" ", "
           "contentType: $contentType" ", "
           "customHeaders: $customHeaders" ")";
  }
}

