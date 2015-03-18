// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library gpu_capabilities.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;


class GpuShaderPrecision extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int minRange = 0;
  int maxRange = 0;
  int precision = 0;

  GpuShaderPrecision() : super(kStructSize);

  static GpuShaderPrecision deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static GpuShaderPrecision decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    GpuShaderPrecision result = new GpuShaderPrecision();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.minRange = decoder0.decodeInt32(8);
    }
    {
      
      result.maxRange = decoder0.decodeInt32(12);
    }
    {
      
      result.precision = decoder0.decodeInt32(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(minRange, 8);
    
    encoder0.encodeInt32(maxRange, 12);
    
    encoder0.encodeInt32(precision, 16);
  }

  String toString() {
    return "GpuShaderPrecision("
           "minRange: $minRange" ", "
           "maxRange: $maxRange" ", "
           "precision: $precision" ")";
  }
}

class GpuPerStagePrecisions extends bindings.Struct {
  static const int kStructSize = 56;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  GpuShaderPrecision lowInt = null;
  GpuShaderPrecision mediumInt = null;
  GpuShaderPrecision highInt = null;
  GpuShaderPrecision lowFloat = null;
  GpuShaderPrecision mediumFloat = null;
  GpuShaderPrecision highFloat = null;

  GpuPerStagePrecisions() : super(kStructSize);

  static GpuPerStagePrecisions deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static GpuPerStagePrecisions decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    GpuPerStagePrecisions result = new GpuPerStagePrecisions();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.lowInt = GpuShaderPrecision.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.mediumInt = GpuShaderPrecision.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(24, false);
      result.highInt = GpuShaderPrecision.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(32, false);
      result.lowFloat = GpuShaderPrecision.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(40, false);
      result.mediumFloat = GpuShaderPrecision.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(48, false);
      result.highFloat = GpuShaderPrecision.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(lowInt, 8, false);
    
    encoder0.encodeStruct(mediumInt, 16, false);
    
    encoder0.encodeStruct(highInt, 24, false);
    
    encoder0.encodeStruct(lowFloat, 32, false);
    
    encoder0.encodeStruct(mediumFloat, 40, false);
    
    encoder0.encodeStruct(highFloat, 48, false);
  }

  String toString() {
    return "GpuPerStagePrecisions("
           "lowInt: $lowInt" ", "
           "mediumInt: $mediumInt" ", "
           "highInt: $highInt" ", "
           "lowFloat: $lowFloat" ", "
           "mediumFloat: $mediumFloat" ", "
           "highFloat: $highFloat" ")";
  }
}

class GpuCapabilities extends bindings.Struct {
  static const int kStructSize = 80;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  GpuPerStagePrecisions vertexShaderPrecisions = null;
  GpuPerStagePrecisions fragmentShaderPrecisions = null;
  int maxCombinedTextureImageUnits = 0;
  int maxCubeMapTextureSize = 0;
  int maxFragmentUniformVectors = 0;
  int maxRenderbufferSize = 0;
  int maxTextureImageUnits = 0;
  int maxTextureSize = 0;
  int maxVaryingVectors = 0;
  int maxVertexAttribs = 0;
  int maxVertexTextureImageUnits = 0;
  int maxVertexUniformVectors = 0;
  int numCompressedTextureFormats = 0;
  int numShaderBinaryFormats = 0;
  int bindGeneratesResourceChromium = 0;
  bool postSubBuffer = false;
  bool eglImageExternal = false;
  bool textureFormatBgra8888 = false;
  bool textureFormatEtc1 = false;
  bool textureFormatEtc1Npot = false;
  bool textureRectangle = false;
  bool iosurface = false;
  bool textureUsage = false;
  bool textureStorage = false;
  bool discardFramebuffer = false;
  bool syncQuery = false;
  bool image = false;
  bool futureSyncPoints = false;
  bool blendEquationAdvanced = false;
  bool blendEquationAdvancedCoherent = false;

  GpuCapabilities() : super(kStructSize);

  static GpuCapabilities deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static GpuCapabilities decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    GpuCapabilities result = new GpuCapabilities();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.vertexShaderPrecisions = GpuPerStagePrecisions.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.fragmentShaderPrecisions = GpuPerStagePrecisions.decode(decoder1);
    }
    {
      
      result.maxCombinedTextureImageUnits = decoder0.decodeInt32(24);
    }
    {
      
      result.maxCubeMapTextureSize = decoder0.decodeInt32(28);
    }
    {
      
      result.maxFragmentUniformVectors = decoder0.decodeInt32(32);
    }
    {
      
      result.maxRenderbufferSize = decoder0.decodeInt32(36);
    }
    {
      
      result.maxTextureImageUnits = decoder0.decodeInt32(40);
    }
    {
      
      result.maxTextureSize = decoder0.decodeInt32(44);
    }
    {
      
      result.maxVaryingVectors = decoder0.decodeInt32(48);
    }
    {
      
      result.maxVertexAttribs = decoder0.decodeInt32(52);
    }
    {
      
      result.maxVertexTextureImageUnits = decoder0.decodeInt32(56);
    }
    {
      
      result.maxVertexUniformVectors = decoder0.decodeInt32(60);
    }
    {
      
      result.numCompressedTextureFormats = decoder0.decodeInt32(64);
    }
    {
      
      result.numShaderBinaryFormats = decoder0.decodeInt32(68);
    }
    {
      
      result.bindGeneratesResourceChromium = decoder0.decodeInt32(72);
    }
    {
      
      result.postSubBuffer = decoder0.decodeBool(76, 0);
    }
    {
      
      result.eglImageExternal = decoder0.decodeBool(76, 1);
    }
    {
      
      result.textureFormatBgra8888 = decoder0.decodeBool(76, 2);
    }
    {
      
      result.textureFormatEtc1 = decoder0.decodeBool(76, 3);
    }
    {
      
      result.textureFormatEtc1Npot = decoder0.decodeBool(76, 4);
    }
    {
      
      result.textureRectangle = decoder0.decodeBool(76, 5);
    }
    {
      
      result.iosurface = decoder0.decodeBool(76, 6);
    }
    {
      
      result.textureUsage = decoder0.decodeBool(76, 7);
    }
    {
      
      result.textureStorage = decoder0.decodeBool(77, 0);
    }
    {
      
      result.discardFramebuffer = decoder0.decodeBool(77, 1);
    }
    {
      
      result.syncQuery = decoder0.decodeBool(77, 2);
    }
    {
      
      result.image = decoder0.decodeBool(77, 3);
    }
    {
      
      result.futureSyncPoints = decoder0.decodeBool(77, 4);
    }
    {
      
      result.blendEquationAdvanced = decoder0.decodeBool(77, 5);
    }
    {
      
      result.blendEquationAdvancedCoherent = decoder0.decodeBool(77, 6);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(vertexShaderPrecisions, 8, false);
    
    encoder0.encodeStruct(fragmentShaderPrecisions, 16, false);
    
    encoder0.encodeInt32(maxCombinedTextureImageUnits, 24);
    
    encoder0.encodeInt32(maxCubeMapTextureSize, 28);
    
    encoder0.encodeInt32(maxFragmentUniformVectors, 32);
    
    encoder0.encodeInt32(maxRenderbufferSize, 36);
    
    encoder0.encodeInt32(maxTextureImageUnits, 40);
    
    encoder0.encodeInt32(maxTextureSize, 44);
    
    encoder0.encodeInt32(maxVaryingVectors, 48);
    
    encoder0.encodeInt32(maxVertexAttribs, 52);
    
    encoder0.encodeInt32(maxVertexTextureImageUnits, 56);
    
    encoder0.encodeInt32(maxVertexUniformVectors, 60);
    
    encoder0.encodeInt32(numCompressedTextureFormats, 64);
    
    encoder0.encodeInt32(numShaderBinaryFormats, 68);
    
    encoder0.encodeInt32(bindGeneratesResourceChromium, 72);
    
    encoder0.encodeBool(postSubBuffer, 76, 0);
    
    encoder0.encodeBool(eglImageExternal, 76, 1);
    
    encoder0.encodeBool(textureFormatBgra8888, 76, 2);
    
    encoder0.encodeBool(textureFormatEtc1, 76, 3);
    
    encoder0.encodeBool(textureFormatEtc1Npot, 76, 4);
    
    encoder0.encodeBool(textureRectangle, 76, 5);
    
    encoder0.encodeBool(iosurface, 76, 6);
    
    encoder0.encodeBool(textureUsage, 76, 7);
    
    encoder0.encodeBool(textureStorage, 77, 0);
    
    encoder0.encodeBool(discardFramebuffer, 77, 1);
    
    encoder0.encodeBool(syncQuery, 77, 2);
    
    encoder0.encodeBool(image, 77, 3);
    
    encoder0.encodeBool(futureSyncPoints, 77, 4);
    
    encoder0.encodeBool(blendEquationAdvanced, 77, 5);
    
    encoder0.encodeBool(blendEquationAdvancedCoherent, 77, 6);
  }

  String toString() {
    return "GpuCapabilities("
           "vertexShaderPrecisions: $vertexShaderPrecisions" ", "
           "fragmentShaderPrecisions: $fragmentShaderPrecisions" ", "
           "maxCombinedTextureImageUnits: $maxCombinedTextureImageUnits" ", "
           "maxCubeMapTextureSize: $maxCubeMapTextureSize" ", "
           "maxFragmentUniformVectors: $maxFragmentUniformVectors" ", "
           "maxRenderbufferSize: $maxRenderbufferSize" ", "
           "maxTextureImageUnits: $maxTextureImageUnits" ", "
           "maxTextureSize: $maxTextureSize" ", "
           "maxVaryingVectors: $maxVaryingVectors" ", "
           "maxVertexAttribs: $maxVertexAttribs" ", "
           "maxVertexTextureImageUnits: $maxVertexTextureImageUnits" ", "
           "maxVertexUniformVectors: $maxVertexUniformVectors" ", "
           "numCompressedTextureFormats: $numCompressedTextureFormats" ", "
           "numShaderBinaryFormats: $numShaderBinaryFormats" ", "
           "bindGeneratesResourceChromium: $bindGeneratesResourceChromium" ", "
           "postSubBuffer: $postSubBuffer" ", "
           "eglImageExternal: $eglImageExternal" ", "
           "textureFormatBgra8888: $textureFormatBgra8888" ", "
           "textureFormatEtc1: $textureFormatEtc1" ", "
           "textureFormatEtc1Npot: $textureFormatEtc1Npot" ", "
           "textureRectangle: $textureRectangle" ", "
           "iosurface: $iosurface" ", "
           "textureUsage: $textureUsage" ", "
           "textureStorage: $textureStorage" ", "
           "discardFramebuffer: $discardFramebuffer" ", "
           "syncQuery: $syncQuery" ", "
           "image: $image" ", "
           "futureSyncPoints: $futureSyncPoints" ", "
           "blendEquationAdvanced: $blendEquationAdvanced" ", "
           "blendEquationAdvancedCoherent: $blendEquationAdvancedCoherent" ")";
  }
}

