// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library url_request_mojom;

import 'dart:async';

import 'package:mojo/bindings.dart' as bindings;
import 'package:mojo/core.dart' as core;
import 'package:mojo/mojo/http_header.mojom.dart' as http_header_mojom;


class UrlRequestCacheMode extends bindings.MojoEnum {
  static const DEFAULT = const UrlRequestCacheMode._(0);
  static const BYPASS_CACHE = const UrlRequestCacheMode._(1);
  static const ONLY_FROM_CACHE = const UrlRequestCacheMode._(2);

  const UrlRequestCacheMode._(int v) : super(v);

  static const Map<String, UrlRequestCacheMode> valuesMap = const {
    "DEFAULT": DEFAULT,
    "BYPASS_CACHE": BYPASS_CACHE,
    "ONLY_FROM_CACHE": ONLY_FROM_CACHE,
  };
  static const List<UrlRequestCacheMode> values = const [
    DEFAULT,
    BYPASS_CACHE,
    ONLY_FROM_CACHE,
  ];

  static UrlRequestCacheMode valueOf(String name) => valuesMap[name];

  factory UrlRequestCacheMode(int v) {
    switch (v) {
      case 0:
        return DEFAULT;
      case 1:
        return BYPASS_CACHE;
      case 2:
        return ONLY_FROM_CACHE;
      default:
        return null;
    }
  }

  static UrlRequestCacheMode decode(bindings.Decoder decoder0, int offset) {
    int v = decoder0.decodeUint32(offset);
    UrlRequestCacheMode result = new UrlRequestCacheMode(v);
    if (result == null) {
      throw new bindings.MojoCodecError(
          'Bad value $v for enum UrlRequestCacheMode.');
    }
    return result;
  }

  String toString() {
    switch(this) {
      case DEFAULT:
        return 'UrlRequestCacheMode.DEFAULT';
      case BYPASS_CACHE:
        return 'UrlRequestCacheMode.BYPASS_CACHE';
      case ONLY_FROM_CACHE:
        return 'UrlRequestCacheMode.ONLY_FROM_CACHE';
    }
  }

  int toJson() => value;
}

class UrlRequest extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(56, 0)
  ];
  String url = null;
  String method = "GET";
  List<http_header_mojom.HttpHeader> headers = null;
  List<core.MojoDataPipeConsumer> body = null;
  int responseBodyBufferSize = 0;
  bool autoFollowRedirects = false;
  UrlRequestCacheMode cacheMode = new UrlRequestCacheMode(0);

  UrlRequest() : super(kVersions.last.size);

  static UrlRequest deserialize(bindings.Message message) {
    var decoder = new bindings.Decoder(message);
    var result = decode(decoder);
    if (decoder.excessHandles != null) {
      decoder.excessHandles.forEach((h) => h.close());
    }
    return result;
  }

  static UrlRequest decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    UrlRequest result = new UrlRequest();

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
      
      result.url = decoder0.decodeString(8, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.method = decoder0.decodeString(16, false);
    }
    if (mainDataHeader.version >= 0) {
      
      var decoder1 = decoder0.decodePointer(24, true);
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
      
      result.body = decoder0.decodeConsumerHandleArray(32, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    }
    if (mainDataHeader.version >= 0) {
      
      result.responseBodyBufferSize = decoder0.decodeUint32(40);
    }
    if (mainDataHeader.version >= 0) {
      
      result.autoFollowRedirects = decoder0.decodeBool(44, 0);
    }
    if (mainDataHeader.version >= 0) {
      
        result.cacheMode = UrlRequestCacheMode.decode(decoder0, 48);
        if (result.cacheMode == null) {
          throw new bindings.MojoCodecError(
            'Trying to decode null union for non-nullable UrlRequestCacheMode.');
        }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeString(url, 8, false);
    
    encoder0.encodeString(method, 16, false);
    
    if (headers == null) {
      encoder0.encodeNullPointer(24, true);
    } else {
      var encoder1 = encoder0.encodePointerArray(headers.length, 24, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < headers.length; ++i0) {
        
        encoder1.encodeStruct(headers[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
    
    encoder0.encodeConsumerHandleArray(body, 32, bindings.kArrayNullable, bindings.kUnspecifiedArrayLength);
    
    encoder0.encodeUint32(responseBodyBufferSize, 40);
    
    encoder0.encodeBool(autoFollowRedirects, 44, 0);
    
    encoder0.encodeEnum(cacheMode, 48);
  }

  String toString() {
    return "UrlRequest("
           "url: $url" ", "
           "method: $method" ", "
           "headers: $headers" ", "
           "body: $body" ", "
           "responseBodyBufferSize: $responseBodyBufferSize" ", "
           "autoFollowRedirects: $autoFollowRedirects" ", "
           "cacheMode: $cacheMode" ")";
  }

  Map toJson() {
    throw new bindings.MojoCodecError(
        'Object containing handles cannot be encoded to JSON.');
  }
}


