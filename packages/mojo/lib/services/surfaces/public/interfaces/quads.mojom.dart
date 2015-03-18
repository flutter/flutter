// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library quads.mojom;

import 'dart:async';
import 'dart:mojo.bindings' as bindings;
import 'dart:mojo.core' as core;
import 'package:mojo/services/geometry/public/interfaces/geometry.mojom.dart' as geometry_mojom;
import 'package:mojo/services/surfaces/public/interfaces/surface_id.mojom.dart' as surface_id_mojom;

final int YUVColorSpace_REC_601 = 0;
final int YUVColorSpace_REC_709 = YUVColorSpace_REC_601 + 1;
final int YUVColorSpace_JPEG = YUVColorSpace_REC_709 + 1;

final int Material_CHECKERBOARD = 1;
final int Material_DEBUG_BORDER = Material_CHECKERBOARD + 1;
final int Material_IO_SURFACE_CONTENT = Material_DEBUG_BORDER + 1;
final int Material_PICTURE_CONTENT = Material_IO_SURFACE_CONTENT + 1;
final int Material_RENDER_PASS = Material_PICTURE_CONTENT + 1;
final int Material_SOLID_COLOR = Material_RENDER_PASS + 1;
final int Material_STREAM_VIDEO_CONTENT = Material_SOLID_COLOR + 1;
final int Material_SURFACE_CONTENT = Material_STREAM_VIDEO_CONTENT + 1;
final int Material_TEXTURE_CONTENT = Material_SURFACE_CONTENT + 1;
final int Material_TILED_CONTENT = Material_TEXTURE_CONTENT + 1;
final int Material_YUV_VIDEO_CONTENT = Material_TILED_CONTENT + 1;

final int SkXfermode_kClear_Mode = 0;
final int SkXfermode_kSrc_Mode = SkXfermode_kClear_Mode + 1;
final int SkXfermode_kDst_Mode = SkXfermode_kSrc_Mode + 1;
final int SkXfermode_kSrcOver_Mode = SkXfermode_kDst_Mode + 1;
final int SkXfermode_kDstOver_Mode = SkXfermode_kSrcOver_Mode + 1;
final int SkXfermode_kSrcIn_Mode = SkXfermode_kDstOver_Mode + 1;
final int SkXfermode_kDstIn_Mode = SkXfermode_kSrcIn_Mode + 1;
final int SkXfermode_kSrcOut_Mode = SkXfermode_kDstIn_Mode + 1;
final int SkXfermode_kDstOut_Mode = SkXfermode_kSrcOut_Mode + 1;
final int SkXfermode_kSrcATop_Mode = SkXfermode_kDstOut_Mode + 1;
final int SkXfermode_kDstATop_Mode = SkXfermode_kSrcATop_Mode + 1;
final int SkXfermode_kXor_Mode = SkXfermode_kDstATop_Mode + 1;
final int SkXfermode_kPlus_Mode = SkXfermode_kXor_Mode + 1;
final int SkXfermode_kModulate_Mode = SkXfermode_kPlus_Mode + 1;
final int SkXfermode_kScreen_Mode = SkXfermode_kModulate_Mode + 1;
final int SkXfermode_kLastCoeffMode = SkXfermode_kScreen_Mode;
final int SkXfermode_kOverlay_Mode = SkXfermode_kLastCoeffMode + 1;
final int SkXfermode_kDarken_Mode = SkXfermode_kOverlay_Mode + 1;
final int SkXfermode_kLighten_Mode = SkXfermode_kDarken_Mode + 1;
final int SkXfermode_kColorDodge_Mode = SkXfermode_kLighten_Mode + 1;
final int SkXfermode_kColorBurn_Mode = SkXfermode_kColorDodge_Mode + 1;
final int SkXfermode_kHardLight_Mode = SkXfermode_kColorBurn_Mode + 1;
final int SkXfermode_kSoftLight_Mode = SkXfermode_kHardLight_Mode + 1;
final int SkXfermode_kDifference_Mode = SkXfermode_kSoftLight_Mode + 1;
final int SkXfermode_kExclusion_Mode = SkXfermode_kDifference_Mode + 1;
final int SkXfermode_kMultiply_Mode = SkXfermode_kExclusion_Mode + 1;
final int SkXfermode_kLastSeparableMode = SkXfermode_kMultiply_Mode;
final int SkXfermode_kHue_Mode = SkXfermode_kLastSeparableMode + 1;
final int SkXfermode_kSaturation_Mode = SkXfermode_kHue_Mode + 1;
final int SkXfermode_kColor_Mode = SkXfermode_kSaturation_Mode + 1;
final int SkXfermode_kLuminosity_Mode = SkXfermode_kColor_Mode + 1;
final int SkXfermode_kLastMode = SkXfermode_kLuminosity_Mode;


class Color extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int rgba = 0;

  Color() : super(kStructSize);

  static Color deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Color decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Color result = new Color();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.rgba = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint32(rgba, 8);
  }

  String toString() {
    return "Color("
           "rgba: $rgba" ")";
  }
}

class CheckerboardQuadState extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  CheckerboardQuadState() : super(kStructSize);

  static CheckerboardQuadState deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static CheckerboardQuadState decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    CheckerboardQuadState result = new CheckerboardQuadState();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    encoder.getStructEncoderAtOffset(kDefaultStructInfo);
  }

  String toString() {
    return "CheckerboardQuadState("")";
  }
}

class DebugBorderQuadState extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  DebugBorderQuadState() : super(kStructSize);

  static DebugBorderQuadState deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static DebugBorderQuadState decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    DebugBorderQuadState result = new DebugBorderQuadState();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    encoder.getStructEncoderAtOffset(kDefaultStructInfo);
  }

  String toString() {
    return "DebugBorderQuadState("")";
  }
}

class IoSurfaceContentQuadState extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  IoSurfaceContentQuadState() : super(kStructSize);

  static IoSurfaceContentQuadState deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static IoSurfaceContentQuadState decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    IoSurfaceContentQuadState result = new IoSurfaceContentQuadState();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    encoder.getStructEncoderAtOffset(kDefaultStructInfo);
  }

  String toString() {
    return "IoSurfaceContentQuadState("")";
  }
}

class RenderPassId extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int layerId = 0;
  int index = 0;

  RenderPassId() : super(kStructSize);

  static RenderPassId deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static RenderPassId decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    RenderPassId result = new RenderPassId();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.layerId = decoder0.decodeInt32(8);
    }
    {
      
      result.index = decoder0.decodeInt32(12);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(layerId, 8);
    
    encoder0.encodeInt32(index, 12);
  }

  String toString() {
    return "RenderPassId("
           "layerId: $layerId" ", "
           "index: $index" ")";
  }
}

class RenderPassQuadState extends bindings.Struct {
  static const int kStructSize = 48;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  RenderPassId renderPassId = null;
  int maskResourceId = 0;
  geometry_mojom.PointF maskUvScale = null;
  geometry_mojom.Size maskTextureSize = null;
  geometry_mojom.PointF filtersScale = null;

  RenderPassQuadState() : super(kStructSize);

  static RenderPassQuadState deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static RenderPassQuadState decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    RenderPassQuadState result = new RenderPassQuadState();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.renderPassId = RenderPassId.decode(decoder1);
    }
    {
      
      result.maskResourceId = decoder0.decodeUint32(16);
    }
    {
      
      var decoder1 = decoder0.decodePointer(24, false);
      result.maskUvScale = geometry_mojom.PointF.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(32, false);
      result.maskTextureSize = geometry_mojom.Size.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(40, false);
      result.filtersScale = geometry_mojom.PointF.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(renderPassId, 8, false);
    
    encoder0.encodeUint32(maskResourceId, 16);
    
    encoder0.encodeStruct(maskUvScale, 24, false);
    
    encoder0.encodeStruct(maskTextureSize, 32, false);
    
    encoder0.encodeStruct(filtersScale, 40, false);
  }

  String toString() {
    return "RenderPassQuadState("
           "renderPassId: $renderPassId" ", "
           "maskResourceId: $maskResourceId" ", "
           "maskUvScale: $maskUvScale" ", "
           "maskTextureSize: $maskTextureSize" ", "
           "filtersScale: $filtersScale" ")";
  }
}

class SolidColorQuadState extends bindings.Struct {
  static const int kStructSize = 24;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  Color color = null;
  bool forceAntiAliasingOff = false;

  SolidColorQuadState() : super(kStructSize);

  static SolidColorQuadState deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static SolidColorQuadState decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    SolidColorQuadState result = new SolidColorQuadState();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.color = Color.decode(decoder1);
    }
    {
      
      result.forceAntiAliasingOff = decoder0.decodeBool(16, 0);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(color, 8, false);
    
    encoder0.encodeBool(forceAntiAliasingOff, 16, 0);
  }

  String toString() {
    return "SolidColorQuadState("
           "color: $color" ", "
           "forceAntiAliasingOff: $forceAntiAliasingOff" ")";
  }
}

class SurfaceQuadState extends bindings.Struct {
  static const int kStructSize = 16;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  surface_id_mojom.SurfaceId surface = null;

  SurfaceQuadState() : super(kStructSize);

  static SurfaceQuadState deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static SurfaceQuadState decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    SurfaceQuadState result = new SurfaceQuadState();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.surface = surface_id_mojom.SurfaceId.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(surface, 8, false);
  }

  String toString() {
    return "SurfaceQuadState("
           "surface: $surface" ")";
  }
}

class TextureQuadState extends bindings.Struct {
  static const int kStructSize = 48;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int resourceId = 0;
  bool premultipliedAlpha = false;
  bool flipped = false;
  bool nearestNeighbor = false;
  geometry_mojom.PointF uvTopLeft = null;
  geometry_mojom.PointF uvBottomRight = null;
  Color backgroundColor = null;
  List<double> vertexOpacity = null;

  TextureQuadState() : super(kStructSize);

  static TextureQuadState deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static TextureQuadState decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    TextureQuadState result = new TextureQuadState();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.resourceId = decoder0.decodeUint32(8);
    }
    {
      
      result.premultipliedAlpha = decoder0.decodeBool(12, 0);
    }
    {
      
      result.flipped = decoder0.decodeBool(12, 1);
    }
    {
      
      result.nearestNeighbor = decoder0.decodeBool(12, 2);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.uvTopLeft = geometry_mojom.PointF.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(24, false);
      result.uvBottomRight = geometry_mojom.PointF.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(32, false);
      result.backgroundColor = Color.decode(decoder1);
    }
    {
      
      result.vertexOpacity = decoder0.decodeFloatArray(40, bindings.kNothingNullable, 4);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeUint32(resourceId, 8);
    
    encoder0.encodeBool(premultipliedAlpha, 12, 0);
    
    encoder0.encodeBool(flipped, 12, 1);
    
    encoder0.encodeBool(nearestNeighbor, 12, 2);
    
    encoder0.encodeStruct(uvTopLeft, 16, false);
    
    encoder0.encodeStruct(uvBottomRight, 24, false);
    
    encoder0.encodeStruct(backgroundColor, 32, false);
    
    encoder0.encodeFloatArray(vertexOpacity, 40, bindings.kNothingNullable, 4);
  }

  String toString() {
    return "TextureQuadState("
           "resourceId: $resourceId" ", "
           "premultipliedAlpha: $premultipliedAlpha" ", "
           "flipped: $flipped" ", "
           "nearestNeighbor: $nearestNeighbor" ", "
           "uvTopLeft: $uvTopLeft" ", "
           "uvBottomRight: $uvBottomRight" ", "
           "backgroundColor: $backgroundColor" ", "
           "vertexOpacity: $vertexOpacity" ")";
  }
}

class TileQuadState extends bindings.Struct {
  static const int kStructSize = 32;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  geometry_mojom.RectF texCoordRect = null;
  geometry_mojom.Size textureSize = null;
  bool swizzleContents = false;
  bool nearestNeighbor = false;
  int resourceId = 0;

  TileQuadState() : super(kStructSize);

  static TileQuadState deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static TileQuadState decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    TileQuadState result = new TileQuadState();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.texCoordRect = geometry_mojom.RectF.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.textureSize = geometry_mojom.Size.decode(decoder1);
    }
    {
      
      result.swizzleContents = decoder0.decodeBool(24, 0);
    }
    {
      
      result.nearestNeighbor = decoder0.decodeBool(24, 1);
    }
    {
      
      result.resourceId = decoder0.decodeUint32(28);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(texCoordRect, 8, false);
    
    encoder0.encodeStruct(textureSize, 16, false);
    
    encoder0.encodeBool(swizzleContents, 24, 0);
    
    encoder0.encodeBool(nearestNeighbor, 24, 1);
    
    encoder0.encodeUint32(resourceId, 28);
  }

  String toString() {
    return "TileQuadState("
           "texCoordRect: $texCoordRect" ", "
           "textureSize: $textureSize" ", "
           "swizzleContents: $swizzleContents" ", "
           "nearestNeighbor: $nearestNeighbor" ", "
           "resourceId: $resourceId" ")";
  }
}

class StreamVideoQuadState extends bindings.Struct {
  static const int kStructSize = 8;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);

  StreamVideoQuadState() : super(kStructSize);

  static StreamVideoQuadState deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static StreamVideoQuadState decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    StreamVideoQuadState result = new StreamVideoQuadState();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    encoder.getStructEncoderAtOffset(kDefaultStructInfo);
  }

  String toString() {
    return "StreamVideoQuadState("")";
  }
}

class YuvVideoQuadState extends bindings.Struct {
  static const int kStructSize = 40;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  geometry_mojom.RectF texCoordRect = null;
  int yPlaneResourceId = 0;
  int uPlaneResourceId = 0;
  int vPlaneResourceId = 0;
  int aPlaneResourceId = 0;
  int colorSpace = 0;

  YuvVideoQuadState() : super(kStructSize);

  static YuvVideoQuadState deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static YuvVideoQuadState decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    YuvVideoQuadState result = new YuvVideoQuadState();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.texCoordRect = geometry_mojom.RectF.decode(decoder1);
    }
    {
      
      result.yPlaneResourceId = decoder0.decodeUint32(16);
    }
    {
      
      result.uPlaneResourceId = decoder0.decodeUint32(20);
    }
    {
      
      result.vPlaneResourceId = decoder0.decodeUint32(24);
    }
    {
      
      result.aPlaneResourceId = decoder0.decodeUint32(28);
    }
    {
      
      result.colorSpace = decoder0.decodeInt32(32);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(texCoordRect, 8, false);
    
    encoder0.encodeUint32(yPlaneResourceId, 16);
    
    encoder0.encodeUint32(uPlaneResourceId, 20);
    
    encoder0.encodeUint32(vPlaneResourceId, 24);
    
    encoder0.encodeUint32(aPlaneResourceId, 28);
    
    encoder0.encodeInt32(colorSpace, 32);
  }

  String toString() {
    return "YuvVideoQuadState("
           "texCoordRect: $texCoordRect" ", "
           "yPlaneResourceId: $yPlaneResourceId" ", "
           "uPlaneResourceId: $uPlaneResourceId" ", "
           "vPlaneResourceId: $vPlaneResourceId" ", "
           "aPlaneResourceId: $aPlaneResourceId" ", "
           "colorSpace: $colorSpace" ")";
  }
}

class Quad extends bindings.Struct {
  static const int kStructSize = 128;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int material = 0;
  bool needsBlending = false;
  geometry_mojom.Rect rect = null;
  geometry_mojom.Rect opaqueRect = null;
  geometry_mojom.Rect visibleRect = null;
  int sharedQuadStateIndex = 0;
  CheckerboardQuadState checkerboardQuadState = null;
  DebugBorderQuadState debugBorderQuadState = null;
  IoSurfaceContentQuadState ioSurfaceQuadState = null;
  RenderPassQuadState renderPassQuadState = null;
  SolidColorQuadState solidColorQuadState = null;
  SurfaceQuadState surfaceQuadState = null;
  TextureQuadState textureQuadState = null;
  TileQuadState tileQuadState = null;
  StreamVideoQuadState streamVideoQuadState = null;
  YuvVideoQuadState yuvVideoQuadState = null;

  Quad() : super(kStructSize);

  static Quad deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Quad decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Quad result = new Quad();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.material = decoder0.decodeInt32(8);
    }
    {
      
      result.needsBlending = decoder0.decodeBool(12, 0);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.rect = geometry_mojom.Rect.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(24, false);
      result.opaqueRect = geometry_mojom.Rect.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(32, false);
      result.visibleRect = geometry_mojom.Rect.decode(decoder1);
    }
    {
      
      result.sharedQuadStateIndex = decoder0.decodeUint32(40);
    }
    {
      
      var decoder1 = decoder0.decodePointer(48, true);
      result.checkerboardQuadState = CheckerboardQuadState.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(56, true);
      result.debugBorderQuadState = DebugBorderQuadState.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(64, true);
      result.ioSurfaceQuadState = IoSurfaceContentQuadState.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(72, true);
      result.renderPassQuadState = RenderPassQuadState.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(80, true);
      result.solidColorQuadState = SolidColorQuadState.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(88, true);
      result.surfaceQuadState = SurfaceQuadState.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(96, true);
      result.textureQuadState = TextureQuadState.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(104, true);
      result.tileQuadState = TileQuadState.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(112, true);
      result.streamVideoQuadState = StreamVideoQuadState.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(120, true);
      result.yuvVideoQuadState = YuvVideoQuadState.decode(decoder1);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(material, 8);
    
    encoder0.encodeBool(needsBlending, 12, 0);
    
    encoder0.encodeStruct(rect, 16, false);
    
    encoder0.encodeStruct(opaqueRect, 24, false);
    
    encoder0.encodeStruct(visibleRect, 32, false);
    
    encoder0.encodeUint32(sharedQuadStateIndex, 40);
    
    encoder0.encodeStruct(checkerboardQuadState, 48, true);
    
    encoder0.encodeStruct(debugBorderQuadState, 56, true);
    
    encoder0.encodeStruct(ioSurfaceQuadState, 64, true);
    
    encoder0.encodeStruct(renderPassQuadState, 72, true);
    
    encoder0.encodeStruct(solidColorQuadState, 80, true);
    
    encoder0.encodeStruct(surfaceQuadState, 88, true);
    
    encoder0.encodeStruct(textureQuadState, 96, true);
    
    encoder0.encodeStruct(tileQuadState, 104, true);
    
    encoder0.encodeStruct(streamVideoQuadState, 112, true);
    
    encoder0.encodeStruct(yuvVideoQuadState, 120, true);
  }

  String toString() {
    return "Quad("
           "material: $material" ", "
           "needsBlending: $needsBlending" ", "
           "rect: $rect" ", "
           "opaqueRect: $opaqueRect" ", "
           "visibleRect: $visibleRect" ", "
           "sharedQuadStateIndex: $sharedQuadStateIndex" ", "
           "checkerboardQuadState: $checkerboardQuadState" ", "
           "debugBorderQuadState: $debugBorderQuadState" ", "
           "ioSurfaceQuadState: $ioSurfaceQuadState" ", "
           "renderPassQuadState: $renderPassQuadState" ", "
           "solidColorQuadState: $solidColorQuadState" ", "
           "surfaceQuadState: $surfaceQuadState" ", "
           "textureQuadState: $textureQuadState" ", "
           "tileQuadState: $tileQuadState" ", "
           "streamVideoQuadState: $streamVideoQuadState" ", "
           "yuvVideoQuadState: $yuvVideoQuadState" ")";
  }
}

class SharedQuadState extends bindings.Struct {
  static const int kStructSize = 56;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  geometry_mojom.Transform contentToTargetTransform = null;
  geometry_mojom.Size contentBounds = null;
  geometry_mojom.Rect visibleContentRect = null;
  geometry_mojom.Rect clipRect = null;
  bool isClipped = false;
  double opacity = 0.0;
  int blendMode = 0;
  int sortingContextId = 0;

  SharedQuadState() : super(kStructSize);

  static SharedQuadState deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static SharedQuadState decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    SharedQuadState result = new SharedQuadState();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      var decoder1 = decoder0.decodePointer(8, false);
      result.contentToTargetTransform = geometry_mojom.Transform.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.contentBounds = geometry_mojom.Size.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(24, false);
      result.visibleContentRect = geometry_mojom.Rect.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(32, false);
      result.clipRect = geometry_mojom.Rect.decode(decoder1);
    }
    {
      
      result.isClipped = decoder0.decodeBool(40, 0);
    }
    {
      
      result.opacity = decoder0.decodeFloat(44);
    }
    {
      
      result.blendMode = decoder0.decodeInt32(48);
    }
    {
      
      result.sortingContextId = decoder0.decodeInt32(52);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeStruct(contentToTargetTransform, 8, false);
    
    encoder0.encodeStruct(contentBounds, 16, false);
    
    encoder0.encodeStruct(visibleContentRect, 24, false);
    
    encoder0.encodeStruct(clipRect, 32, false);
    
    encoder0.encodeBool(isClipped, 40, 0);
    
    encoder0.encodeFloat(opacity, 44);
    
    encoder0.encodeInt32(blendMode, 48);
    
    encoder0.encodeInt32(sortingContextId, 52);
  }

  String toString() {
    return "SharedQuadState("
           "contentToTargetTransform: $contentToTargetTransform" ", "
           "contentBounds: $contentBounds" ", "
           "visibleContentRect: $visibleContentRect" ", "
           "clipRect: $clipRect" ", "
           "isClipped: $isClipped" ", "
           "opacity: $opacity" ", "
           "blendMode: $blendMode" ", "
           "sortingContextId: $sortingContextId" ")";
  }
}

class Pass extends bindings.Struct {
  static const int kStructSize = 56;
  static const bindings.StructDataHeader kDefaultStructInfo =
      const bindings.StructDataHeader(kStructSize, 0);
  int id = 0;
  bool hasTransparentBackground = false;
  geometry_mojom.Rect outputRect = null;
  geometry_mojom.Rect damageRect = null;
  geometry_mojom.Transform transformToRootTarget = null;
  List<Quad> quads = null;
  List<SharedQuadState> sharedQuadStates = null;

  Pass() : super(kStructSize);

  static Pass deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static Pass decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    Pass result = new Pass();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if ((mainDataHeader.size < kStructSize) ||
        (mainDataHeader.version < 0)) {
      throw new bindings.MojoCodecError('Malformed header');
    }
    {
      
      result.id = decoder0.decodeInt32(8);
    }
    {
      
      result.hasTransparentBackground = decoder0.decodeBool(12, 0);
    }
    {
      
      var decoder1 = decoder0.decodePointer(16, false);
      result.outputRect = geometry_mojom.Rect.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(24, false);
      result.damageRect = geometry_mojom.Rect.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(32, false);
      result.transformToRootTarget = geometry_mojom.Transform.decode(decoder1);
    }
    {
      
      var decoder1 = decoder0.decodePointer(40, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.quads = new List<Quad>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.quads[i1] = Quad.decode(decoder2);
        }
      }
    }
    {
      
      var decoder1 = decoder0.decodePointer(48, false);
      {
        var si1 = decoder1.decodeDataHeaderForPointerArray(bindings.kUnspecifiedArrayLength);
        result.sharedQuadStates = new List<SharedQuadState>(si1.numElements);
        for (int i1 = 0; i1 < si1.numElements; ++i1) {
          
          var decoder2 = decoder1.decodePointer(bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i1, false);
          result.sharedQuadStates[i1] = SharedQuadState.decode(decoder2);
        }
      }
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kDefaultStructInfo);
    
    encoder0.encodeInt32(id, 8);
    
    encoder0.encodeBool(hasTransparentBackground, 12, 0);
    
    encoder0.encodeStruct(outputRect, 16, false);
    
    encoder0.encodeStruct(damageRect, 24, false);
    
    encoder0.encodeStruct(transformToRootTarget, 32, false);
    
    if (quads == null) {
      encoder0.encodeNullPointer(40, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(quads.length, 40, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < quads.length; ++i0) {
        
        encoder1.encodeStruct(quads[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
    
    if (sharedQuadStates == null) {
      encoder0.encodeNullPointer(48, false);
    } else {
      var encoder1 = encoder0.encodePointerArray(sharedQuadStates.length, 48, bindings.kUnspecifiedArrayLength);
      for (int i0 = 0; i0 < sharedQuadStates.length; ++i0) {
        
        encoder1.encodeStruct(sharedQuadStates[i0], bindings.ArrayDataHeader.kHeaderSize + bindings.kPointerSize * i0, false);
      }
    }
  }

  String toString() {
    return "Pass("
           "id: $id" ", "
           "hasTransparentBackground: $hasTransparentBackground" ", "
           "outputRect: $outputRect" ", "
           "damageRect: $damageRect" ", "
           "transformToRootTarget: $transformToRootTarget" ", "
           "quads: $quads" ", "
           "sharedQuadStates: $sharedQuadStates" ")";
  }
}

