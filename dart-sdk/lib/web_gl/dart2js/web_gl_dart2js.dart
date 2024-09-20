/// 3D programming in the browser.
///
/// > [!Note]
/// > New projects should prefer to use
/// > [package:web](https://pub.dev/packages/web). For existing projects, see
/// > our [migration guide](https://dart.dev/go/package-web).
///
/// {@category Web (Legacy)}
library dart.dom.web_gl;

import 'dart:async';
import 'dart:collection' hide LinkedList, LinkedListEntry;
import 'dart:_internal' show FixedLengthListMixin;
import 'dart:html';
import 'dart:html_common';
import 'dart:_native_typed_data';
import 'dart:typed_data';
import 'dart:_js_helper'
    show Creates, JSName, Native, Returns, convertDartClosureToJS;
import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show JavaScriptObject, JSExtendableArray;
// DO NOT EDIT - unless you are editing documentation as per:
// https://code.google.com/p/dart/wiki/ContributingHTMLDocumentation
// Auto-generated dart:web_gl library.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Unstable()
@Native("WebGLActiveInfo")
class ActiveInfo extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory ActiveInfo._() {
    throw new UnsupportedError("Not supported");
  }

  String get name native;

  int get size native;

  int get type native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("ANGLEInstancedArrays,ANGLE_instanced_arrays")
class AngleInstancedArrays extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory AngleInstancedArrays._() {
    throw new UnsupportedError("Not supported");
  }

  static const int VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE = 0x88FE;

  @JSName('drawArraysInstancedANGLE')
  void drawArraysInstancedAngle(int mode, int first, int count, int primcount)
      native;

  @JSName('drawElementsInstancedANGLE')
  void drawElementsInstancedAngle(
      int mode, int count, int type, int offset, int primcount) native;

  @JSName('vertexAttribDivisorANGLE')
  void vertexAttribDivisorAngle(int index, int divisor) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Unstable()
@Native("WebGLBuffer")
class Buffer extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory Buffer._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLCanvas")
class Canvas extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory Canvas._() {
    throw new UnsupportedError("Not supported");
  }

  @JSName('canvas')
  CanvasElement get canvas native;

  @JSName('canvas')
  OffscreenCanvas? get offscreenCanvas native;
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLColorBufferFloat")
class ColorBufferFloat extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory ColorBufferFloat._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLCompressedTextureASTC")
class CompressedTextureAstc extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory CompressedTextureAstc._() {
    throw new UnsupportedError("Not supported");
  }

  static const int COMPRESSED_RGBA_ASTC_10x10_KHR = 0x93BB;

  static const int COMPRESSED_RGBA_ASTC_10x5_KHR = 0x93B8;

  static const int COMPRESSED_RGBA_ASTC_10x6_KHR = 0x93B9;

  static const int COMPRESSED_RGBA_ASTC_10x8_KHR = 0x93BA;

  static const int COMPRESSED_RGBA_ASTC_12x10_KHR = 0x93BC;

  static const int COMPRESSED_RGBA_ASTC_12x12_KHR = 0x93BD;

  static const int COMPRESSED_RGBA_ASTC_4x4_KHR = 0x93B0;

  static const int COMPRESSED_RGBA_ASTC_5x4_KHR = 0x93B1;

  static const int COMPRESSED_RGBA_ASTC_5x5_KHR = 0x93B2;

  static const int COMPRESSED_RGBA_ASTC_6x5_KHR = 0x93B3;

  static const int COMPRESSED_RGBA_ASTC_6x6_KHR = 0x93B4;

  static const int COMPRESSED_RGBA_ASTC_8x5_KHR = 0x93B5;

  static const int COMPRESSED_RGBA_ASTC_8x6_KHR = 0x93B6;

  static const int COMPRESSED_RGBA_ASTC_8x8_KHR = 0x93B7;

  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR = 0x93DB;

  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR = 0x93D8;

  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR = 0x93D9;

  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR = 0x93DA;

  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR = 0x93DC;

  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR = 0x93DD;

  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR = 0x93D0;

  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR = 0x93D1;

  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR = 0x93D2;

  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR = 0x93D3;

  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR = 0x93D4;

  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR = 0x93D5;

  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR = 0x93D6;

  static const int COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR = 0x93D7;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLCompressedTextureATC,WEBGL_compressed_texture_atc")
class CompressedTextureAtc extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory CompressedTextureAtc._() {
    throw new UnsupportedError("Not supported");
  }

  static const int COMPRESSED_RGBA_ATC_EXPLICIT_ALPHA_WEBGL = 0x8C93;

  static const int COMPRESSED_RGBA_ATC_INTERPOLATED_ALPHA_WEBGL = 0x87EE;

  static const int COMPRESSED_RGB_ATC_WEBGL = 0x8C92;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLCompressedTextureETC1,WEBGL_compressed_texture_etc1")
class CompressedTextureETC1 extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory CompressedTextureETC1._() {
    throw new UnsupportedError("Not supported");
  }

  static const int COMPRESSED_RGB_ETC1_WEBGL = 0x8D64;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLCompressedTextureETC")
class CompressedTextureEtc extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory CompressedTextureEtc._() {
    throw new UnsupportedError("Not supported");
  }

  static const int COMPRESSED_R11_EAC = 0x9270;

  static const int COMPRESSED_RG11_EAC = 0x9272;

  static const int COMPRESSED_RGB8_ETC2 = 0x9274;

  static const int COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 0x9276;

  static const int COMPRESSED_RGBA8_ETC2_EAC = 0x9278;

  static const int COMPRESSED_SIGNED_R11_EAC = 0x9271;

  static const int COMPRESSED_SIGNED_RG11_EAC = 0x9273;

  static const int COMPRESSED_SRGB8_ALPHA8_ETC2_EAC = 0x9279;

  static const int COMPRESSED_SRGB8_ETC2 = 0x9275;

  static const int COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 0x9277;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLCompressedTexturePVRTC,WEBGL_compressed_texture_pvrtc")
class CompressedTexturePvrtc extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory CompressedTexturePvrtc._() {
    throw new UnsupportedError("Not supported");
  }

  static const int COMPRESSED_RGBA_PVRTC_2BPPV1_IMG = 0x8C03;

  static const int COMPRESSED_RGBA_PVRTC_4BPPV1_IMG = 0x8C02;

  static const int COMPRESSED_RGB_PVRTC_2BPPV1_IMG = 0x8C01;

  static const int COMPRESSED_RGB_PVRTC_4BPPV1_IMG = 0x8C00;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLCompressedTextureS3TC,WEBGL_compressed_texture_s3tc")
class CompressedTextureS3TC extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory CompressedTextureS3TC._() {
    throw new UnsupportedError("Not supported");
  }

  static const int COMPRESSED_RGBA_S3TC_DXT1_EXT = 0x83F1;

  static const int COMPRESSED_RGBA_S3TC_DXT3_EXT = 0x83F2;

  static const int COMPRESSED_RGBA_S3TC_DXT5_EXT = 0x83F3;

  static const int COMPRESSED_RGB_S3TC_DXT1_EXT = 0x83F0;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLCompressedTextureS3TCsRGB")
class CompressedTextureS3TCsRgb extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory CompressedTextureS3TCsRgb._() {
    throw new UnsupportedError("Not supported");
  }

  static const int COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT = 0x8C4D;

  static const int COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT = 0x8C4E;

  static const int COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT = 0x8C4F;

  static const int COMPRESSED_SRGB_S3TC_DXT1_EXT = 0x8C4C;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Unstable()
@Native("WebGLContextEvent")
class ContextEvent extends Event {
  // To suppress missing implicit constructor warnings.
  factory ContextEvent._() {
    throw new UnsupportedError("Not supported");
  }

  factory ContextEvent(String type, [Map? eventInit]) {
    if (eventInit != null) {
      var eventInit_1 = convertDartToNative_Dictionary(eventInit);
      return ContextEvent._create_1(type, eventInit_1);
    }
    return ContextEvent._create_2(type);
  }
  static ContextEvent _create_1(type, eventInit) =>
      JS('ContextEvent', 'new WebGLContextEvent(#,#)', type, eventInit);
  static ContextEvent _create_2(type) =>
      JS('ContextEvent', 'new WebGLContextEvent(#)', type);

  String get statusMessage native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLDebugRendererInfo,WEBGL_debug_renderer_info")
class DebugRendererInfo extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory DebugRendererInfo._() {
    throw new UnsupportedError("Not supported");
  }

  static const int UNMASKED_RENDERER_WEBGL = 0x9246;

  static const int UNMASKED_VENDOR_WEBGL = 0x9245;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLDebugShaders,WEBGL_debug_shaders")
class DebugShaders extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory DebugShaders._() {
    throw new UnsupportedError("Not supported");
  }

  String? getTranslatedShaderSource(Shader shader) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLDepthTexture,WEBGL_depth_texture")
class DepthTexture extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory DepthTexture._() {
    throw new UnsupportedError("Not supported");
  }

  static const int UNSIGNED_INT_24_8_WEBGL = 0x84FA;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLDrawBuffers,WEBGL_draw_buffers")
class DrawBuffers extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory DrawBuffers._() {
    throw new UnsupportedError("Not supported");
  }

  @JSName('drawBuffersWEBGL')
  void drawBuffersWebgl(List<int> buffers) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("EXTsRGB,EXT_sRGB")
class EXTsRgb extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory EXTsRgb._() {
    throw new UnsupportedError("Not supported");
  }

  static const int FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING_EXT = 0x8210;

  static const int SRGB8_ALPHA8_EXT = 0x8C43;

  static const int SRGB_ALPHA_EXT = 0x8C42;

  static const int SRGB_EXT = 0x8C40;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("EXTBlendMinMax,EXT_blend_minmax")
class ExtBlendMinMax extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory ExtBlendMinMax._() {
    throw new UnsupportedError("Not supported");
  }

  static const int MAX_EXT = 0x8008;

  static const int MIN_EXT = 0x8007;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("EXTColorBufferFloat")
class ExtColorBufferFloat extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory ExtColorBufferFloat._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("EXTColorBufferHalfFloat")
class ExtColorBufferHalfFloat extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory ExtColorBufferHalfFloat._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("EXTDisjointTimerQuery")
class ExtDisjointTimerQuery extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory ExtDisjointTimerQuery._() {
    throw new UnsupportedError("Not supported");
  }

  static const int CURRENT_QUERY_EXT = 0x8865;

  static const int GPU_DISJOINT_EXT = 0x8FBB;

  static const int QUERY_COUNTER_BITS_EXT = 0x8864;

  static const int QUERY_RESULT_AVAILABLE_EXT = 0x8867;

  static const int QUERY_RESULT_EXT = 0x8866;

  static const int TIMESTAMP_EXT = 0x8E28;

  static const int TIME_ELAPSED_EXT = 0x88BF;

  @JSName('beginQueryEXT')
  void beginQueryExt(int target, TimerQueryExt query) native;

  @JSName('createQueryEXT')
  TimerQueryExt createQueryExt() native;

  @JSName('deleteQueryEXT')
  void deleteQueryExt(TimerQueryExt? query) native;

  @JSName('endQueryEXT')
  void endQueryExt(int target) native;

  @JSName('getQueryEXT')
  Object? getQueryExt(int target, int pname) native;

  @JSName('getQueryObjectEXT')
  Object? getQueryObjectExt(TimerQueryExt query, int pname) native;

  @JSName('isQueryEXT')
  bool isQueryExt(TimerQueryExt? query) native;

  @JSName('queryCounterEXT')
  void queryCounterExt(TimerQueryExt query, int target) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("EXTDisjointTimerQueryWebGL2")
class ExtDisjointTimerQueryWebGL2 extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory ExtDisjointTimerQueryWebGL2._() {
    throw new UnsupportedError("Not supported");
  }

  static const int GPU_DISJOINT_EXT = 0x8FBB;

  static const int QUERY_COUNTER_BITS_EXT = 0x8864;

  static const int TIMESTAMP_EXT = 0x8E28;

  static const int TIME_ELAPSED_EXT = 0x88BF;

  @JSName('queryCounterEXT')
  void queryCounterExt(Query query, int target) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("EXTFragDepth,EXT_frag_depth")
class ExtFragDepth extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory ExtFragDepth._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("EXTShaderTextureLOD,EXT_shader_texture_lod")
class ExtShaderTextureLod extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory ExtShaderTextureLod._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("EXTTextureFilterAnisotropic,EXT_texture_filter_anisotropic")
class ExtTextureFilterAnisotropic extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory ExtTextureFilterAnisotropic._() {
    throw new UnsupportedError("Not supported");
  }

  static const int MAX_TEXTURE_MAX_ANISOTROPY_EXT = 0x84FF;

  static const int TEXTURE_MAX_ANISOTROPY_EXT = 0x84FE;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Unstable()
@Native("WebGLFramebuffer")
class Framebuffer extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory Framebuffer._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLGetBufferSubDataAsync")
class GetBufferSubDataAsync extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory GetBufferSubDataAsync._() {
    throw new UnsupportedError("Not supported");
  }

  Future getBufferSubDataAsync(int target, int srcByteOffset, TypedData dstData,
          [int? dstOffset, int? length]) =>
      promiseToFuture(JS("", "#.getBufferSubDataAsync(#, #, #, #, #)", this,
          target, srcByteOffset, dstData, dstOffset, length));
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLLoseContext,WebGLExtensionLoseContext,WEBGL_lose_context")
class LoseContext extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory LoseContext._() {
    throw new UnsupportedError("Not supported");
  }

  void loseContext() native;

  void restoreContext() native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("OESElementIndexUint,OES_element_index_uint")
class OesElementIndexUint extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory OesElementIndexUint._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("OESStandardDerivatives,OES_standard_derivatives")
class OesStandardDerivatives extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory OesStandardDerivatives._() {
    throw new UnsupportedError("Not supported");
  }

  static const int FRAGMENT_SHADER_DERIVATIVE_HINT_OES = 0x8B8B;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("OESTextureFloat,OES_texture_float")
class OesTextureFloat extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory OesTextureFloat._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("OESTextureFloatLinear,OES_texture_float_linear")
class OesTextureFloatLinear extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory OesTextureFloatLinear._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("OESTextureHalfFloat,OES_texture_half_float")
class OesTextureHalfFloat extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory OesTextureHalfFloat._() {
    throw new UnsupportedError("Not supported");
  }

  static const int HALF_FLOAT_OES = 0x8D61;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("OESTextureHalfFloatLinear,OES_texture_half_float_linear")
class OesTextureHalfFloatLinear extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory OesTextureHalfFloatLinear._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("OESVertexArrayObject,OES_vertex_array_object")
class OesVertexArrayObject extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory OesVertexArrayObject._() {
    throw new UnsupportedError("Not supported");
  }

  static const int VERTEX_ARRAY_BINDING_OES = 0x85B5;

  @JSName('bindVertexArrayOES')
  void bindVertexArray(VertexArrayObjectOes? arrayObject) native;

  @JSName('createVertexArrayOES')
  VertexArrayObjectOes createVertexArray() native;

  @JSName('deleteVertexArrayOES')
  void deleteVertexArray(VertexArrayObjectOes? arrayObject) native;

  @JSName('isVertexArrayOES')
  bool isVertexArray(VertexArrayObjectOes? arrayObject) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Unstable()
@Native("WebGLProgram")
class Program extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory Program._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLQuery")
class Query extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory Query._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Unstable()
@Native("WebGLRenderbuffer")
class Renderbuffer extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory Renderbuffer._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX)
@Unstable()
@Native("WebGLRenderingContext")
class RenderingContext extends JavaScriptObject
    implements CanvasRenderingContext {
  // To suppress missing implicit constructor warnings.
  factory RenderingContext._() {
    throw new UnsupportedError("Not supported");
  }

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.WebGLRenderingContext)');

  CanvasElement get canvas native;

  // From WebGLRenderingContextBase

  int? get drawingBufferHeight native;

  int? get drawingBufferWidth native;

  void activeTexture(int texture) native;

  void attachShader(Program program, Shader shader) native;

  void bindAttribLocation(Program program, int index, String name) native;

  void bindBuffer(int target, Buffer? buffer) native;

  void bindFramebuffer(int target, Framebuffer? framebuffer) native;

  void bindRenderbuffer(int target, Renderbuffer? renderbuffer) native;

  void bindTexture(int target, Texture? texture) native;

  void blendColor(num red, num green, num blue, num alpha) native;

  void blendEquation(int mode) native;

  void blendEquationSeparate(int modeRGB, int modeAlpha) native;

  void blendFunc(int sfactor, int dfactor) native;

  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha)
      native;

  void bufferData(int target, data_OR_size, int usage) native;

  void bufferSubData(int target, int offset, data) native;

  int checkFramebufferStatus(int target) native;

  void clear(int mask) native;

  void clearColor(num red, num green, num blue, num alpha) native;

  void clearDepth(num depth) native;

  void clearStencil(int s) native;

  void colorMask(bool red, bool green, bool blue, bool alpha) native;

  Future commit() => promiseToFuture(JS("", "#.commit()", this));

  void compileShader(Shader shader) native;

  void compressedTexImage2D(int target, int level, int internalformat,
      int width, int height, int border, TypedData data) native;

  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset,
      int width, int height, int format, TypedData data) native;

  void copyTexImage2D(int target, int level, int internalformat, int x, int y,
      int width, int height, int border) native;

  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x,
      int y, int width, int height) native;

  Buffer createBuffer() native;

  Framebuffer createFramebuffer() native;

  Program createProgram() native;

  Renderbuffer createRenderbuffer() native;

  Shader createShader(int type) native;

  Texture createTexture() native;

  void cullFace(int mode) native;

  void deleteBuffer(Buffer? buffer) native;

  void deleteFramebuffer(Framebuffer? framebuffer) native;

  void deleteProgram(Program? program) native;

  void deleteRenderbuffer(Renderbuffer? renderbuffer) native;

  void deleteShader(Shader? shader) native;

  void deleteTexture(Texture? texture) native;

  void depthFunc(int func) native;

  void depthMask(bool flag) native;

  void depthRange(num zNear, num zFar) native;

  void detachShader(Program program, Shader shader) native;

  void disable(int cap) native;

  void disableVertexAttribArray(int index) native;

  void drawArrays(int mode, int first, int count) native;

  void drawElements(int mode, int count, int type, int offset) native;

  void enable(int cap) native;

  void enableVertexAttribArray(int index) native;

  void finish() native;

  void flush() native;

  void framebufferRenderbuffer(int target, int attachment,
      int renderbuffertarget, Renderbuffer? renderbuffer) native;

  void framebufferTexture2D(int target, int attachment, int textarget,
      Texture? texture, int level) native;

  void frontFace(int mode) native;

  void generateMipmap(int target) native;

  ActiveInfo getActiveAttrib(Program program, int index) native;

  ActiveInfo getActiveUniform(Program program, int index) native;

  List<Shader>? getAttachedShaders(Program program) native;

  int getAttribLocation(Program program, String name) native;

  @Creates('int|Null')
  @Returns('int|Null')
  Object? getBufferParameter(int target, int pname) native;

  @Creates('ContextAttributes|Null')
  Map? getContextAttributes() {
    return convertNativeToDart_Dictionary(_getContextAttributes_1());
  }

  @JSName('getContextAttributes')
  @Creates('ContextAttributes|Null')
  _getContextAttributes_1() native;

  int getError() native;

  Object? getExtension(String name) native;

  @Creates('int|Renderbuffer|Texture|Null')
  @Returns('int|Renderbuffer|Texture|Null')
  Object? getFramebufferAttachmentParameter(
      int target, int attachment, int pname) native;

  @Creates(
      'Null|num|String|bool|JSExtendableArray|NativeFloat32List|NativeInt32List|NativeUint32List|Framebuffer|Renderbuffer|Texture')
  @Returns(
      'Null|num|String|bool|JSExtendableArray|NativeFloat32List|NativeInt32List|NativeUint32List|Framebuffer|Renderbuffer|Texture')
  Object? getParameter(int pname) native;

  String? getProgramInfoLog(Program program) native;

  @Creates('int|bool|Null')
  @Returns('int|bool|Null')
  Object? getProgramParameter(Program program, int pname) native;

  @Creates('int|Null')
  @Returns('int|Null')
  Object? getRenderbufferParameter(int target, int pname) native;

  String? getShaderInfoLog(Shader shader) native;

  @Creates('int|bool|Null')
  @Returns('int|bool|Null')
  Object? getShaderParameter(Shader shader, int pname) native;

  ShaderPrecisionFormat getShaderPrecisionFormat(
      int shadertype, int precisiontype) native;

  String? getShaderSource(Shader shader) native;

  List<String>? getSupportedExtensions() native;

  @Creates('int|Null')
  @Returns('int|Null')
  Object? getTexParameter(int target, int pname) native;

  @Creates(
      'Null|num|String|bool|JSExtendableArray|NativeFloat32List|NativeInt32List|NativeUint32List')
  @Returns(
      'Null|num|String|bool|JSExtendableArray|NativeFloat32List|NativeInt32List|NativeUint32List')
  Object? getUniform(Program program, UniformLocation location) native;

  UniformLocation getUniformLocation(Program program, String name) native;

  @Creates('Null|num|bool|NativeFloat32List|Buffer')
  @Returns('Null|num|bool|NativeFloat32List|Buffer')
  Object? getVertexAttrib(int index, int pname) native;

  int getVertexAttribOffset(int index, int pname) native;

  void hint(int target, int mode) native;

  bool isBuffer(Buffer? buffer) native;

  bool isContextLost() native;

  bool isEnabled(int cap) native;

  bool isFramebuffer(Framebuffer? framebuffer) native;

  bool isProgram(Program? program) native;

  bool isRenderbuffer(Renderbuffer? renderbuffer) native;

  bool isShader(Shader? shader) native;

  bool isTexture(Texture? texture) native;

  void lineWidth(num width) native;

  void linkProgram(Program program) native;

  void pixelStorei(int pname, int param) native;

  void polygonOffset(num factor, num units) native;

  @JSName('readPixels')
  void _readPixels(int x, int y, int width, int height, int format, int type,
      TypedData? pixels) native;

  void renderbufferStorage(
      int target, int internalformat, int width, int height) native;

  void sampleCoverage(num value, bool invert) native;

  void scissor(int x, int y, int width, int height) native;

  void shaderSource(Shader shader, String string) native;

  void stencilFunc(int func, int ref, int mask) native;

  void stencilFuncSeparate(int face, int func, int ref, int mask) native;

  void stencilMask(int mask) native;

  void stencilMaskSeparate(int face, int mask) native;

  void stencilOp(int fail, int zfail, int zpass) native;

  void stencilOpSeparate(int face, int fail, int zfail, int zpass) native;

  void texImage2D(
      int target,
      int level,
      int internalformat,
      int format_OR_width,
      int height_OR_type,
      bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video,
      [int? format,
      int? type,
      TypedData? pixels]) {
    if (type != null &&
        format != null &&
        (bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video is int)) {
      _texImage2D_1(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video,
          format,
          type,
          pixels);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video is ImageData) &&
        format == null &&
        type == null &&
        pixels == null) {
      var pixels_1 = convertDartToNative_ImageData(
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      _texImage2D_2(target, level, internalformat, format_OR_width,
          height_OR_type, pixels_1);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video
            is ImageElement) &&
        format == null &&
        type == null &&
        pixels == null) {
      _texImage2D_3(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video
            is CanvasElement) &&
        format == null &&
        type == null &&
        pixels == null) {
      _texImage2D_4(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video
            is VideoElement) &&
        format == null &&
        type == null &&
        pixels == null) {
      _texImage2D_5(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video
            is ImageBitmap) &&
        format == null &&
        type == null &&
        pixels == null) {
      _texImage2D_6(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @JSName('texImage2D')
  void _texImage2D_1(target, level, internalformat, width, height, int border,
      format, type, TypedData? pixels) native;
  @JSName('texImage2D')
  void _texImage2D_2(target, level, internalformat, format, type, pixels)
      native;
  @JSName('texImage2D')
  void _texImage2D_3(
      target, level, internalformat, format, type, ImageElement image) native;
  @JSName('texImage2D')
  void _texImage2D_4(
      target, level, internalformat, format, type, CanvasElement canvas) native;
  @JSName('texImage2D')
  void _texImage2D_5(
      target, level, internalformat, format, type, VideoElement video) native;
  @JSName('texImage2D')
  void _texImage2D_6(
      target, level, internalformat, format, type, ImageBitmap bitmap) native;

  void texParameterf(int target, int pname, num param) native;

  void texParameteri(int target, int pname, int param) native;

  void texSubImage2D(
      int target,
      int level,
      int xoffset,
      int yoffset,
      int format_OR_width,
      int height_OR_type,
      bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video,
      [int? type,
      TypedData? pixels]) {
    if (type != null &&
        (bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video is int)) {
      _texSubImage2D_1(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video,
          type,
          pixels);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video is ImageData) &&
        type == null &&
        pixels == null) {
      var pixels_1 = convertDartToNative_ImageData(
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      _texSubImage2D_2(target, level, xoffset, yoffset, format_OR_width,
          height_OR_type, pixels_1);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video
            is ImageElement) &&
        type == null &&
        pixels == null) {
      _texSubImage2D_3(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video
            is CanvasElement) &&
        type == null &&
        pixels == null) {
      _texSubImage2D_4(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video
            is VideoElement) &&
        type == null &&
        pixels == null) {
      _texSubImage2D_5(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video
            is ImageBitmap) &&
        type == null &&
        pixels == null) {
      _texSubImage2D_6(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @JSName('texSubImage2D')
  void _texSubImage2D_1(target, level, xoffset, yoffset, width, height,
      int format, type, TypedData? pixels) native;
  @JSName('texSubImage2D')
  void _texSubImage2D_2(target, level, xoffset, yoffset, format, type, pixels)
      native;
  @JSName('texSubImage2D')
  void _texSubImage2D_3(
      target, level, xoffset, yoffset, format, type, ImageElement image) native;
  @JSName('texSubImage2D')
  void _texSubImage2D_4(target, level, xoffset, yoffset, format, type,
      CanvasElement canvas) native;
  @JSName('texSubImage2D')
  void _texSubImage2D_5(
      target, level, xoffset, yoffset, format, type, VideoElement video) native;
  @JSName('texSubImage2D')
  void _texSubImage2D_6(
      target, level, xoffset, yoffset, format, type, ImageBitmap bitmap) native;

  void uniform1f(UniformLocation? location, num x) native;

  void uniform1fv(UniformLocation? location, v) native;

  void uniform1i(UniformLocation? location, int x) native;

  void uniform1iv(UniformLocation? location, v) native;

  void uniform2f(UniformLocation? location, num x, num y) native;

  void uniform2fv(UniformLocation? location, v) native;

  void uniform2i(UniformLocation? location, int x, int y) native;

  void uniform2iv(UniformLocation? location, v) native;

  void uniform3f(UniformLocation? location, num x, num y, num z) native;

  void uniform3fv(UniformLocation? location, v) native;

  void uniform3i(UniformLocation? location, int x, int y, int z) native;

  void uniform3iv(UniformLocation? location, v) native;

  void uniform4f(UniformLocation? location, num x, num y, num z, num w) native;

  void uniform4fv(UniformLocation? location, v) native;

  void uniform4i(UniformLocation? location, int x, int y, int z, int w) native;

  void uniform4iv(UniformLocation? location, v) native;

  void uniformMatrix2fv(UniformLocation? location, bool transpose, array)
      native;

  void uniformMatrix3fv(UniformLocation? location, bool transpose, array)
      native;

  void uniformMatrix4fv(UniformLocation? location, bool transpose, array)
      native;

  void useProgram(Program? program) native;

  void validateProgram(Program program) native;

  void vertexAttrib1f(int indx, num x) native;

  void vertexAttrib1fv(int indx, values) native;

  void vertexAttrib2f(int indx, num x, num y) native;

  void vertexAttrib2fv(int indx, values) native;

  void vertexAttrib3f(int indx, num x, num y, num z) native;

  void vertexAttrib3fv(int indx, values) native;

  void vertexAttrib4f(int indx, num x, num y, num z, num w) native;

  void vertexAttrib4fv(int indx, values) native;

  void vertexAttribPointer(int indx, int size, int type, bool normalized,
      int stride, int offset) native;

  void viewport(int x, int y, int width, int height) native;

  void readPixels(int x, int y, int width, int height, int format, int type,
      TypedData? pixels) {
    _readPixels(x, y, width, height, format, type, pixels);
  }

  /**
   * Sets the currently bound texture to [data].
   *
   * [data] can be either an [ImageElement], a
   * [CanvasElement], a [VideoElement], [TypedData] or an [ImageData] object.
   *
   * This is deprecated in favor of [texImage2D].
   */
  @Deprecated("Use texImage2D")
  void texImage2DUntyped(int targetTexture, int levelOfDetail,
      int internalFormat, int format, int type, data) {
    texImage2D(
        targetTexture, levelOfDetail, internalFormat, format, type, data);
  }

  /**
   * Sets the currently bound texture to [data].
   *
   * This is deprecated in favour of [texImage2D].
   */
  @Deprecated("Use texImage2D")
  void texImage2DTyped(int targetTexture, int levelOfDetail, int internalFormat,
      int width, int height, int border, int format, int type, TypedData data) {
    texImage2D(targetTexture, levelOfDetail, internalFormat, width, height,
        border, format, type, data);
  }

  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   *
   * [data] can be either an [ImageElement], a
   * [CanvasElement], a [VideoElement], [TypedData] or an [ImageData] object.
   *
   */
  @Deprecated("Use texSubImage2D")
  void texSubImage2DUntyped(int targetTexture, int levelOfDetail, int xOffset,
      int yOffset, int format, int type, data) {
    texSubImage2D(
        targetTexture, levelOfDetail, xOffset, yOffset, format, type, data);
  }

  /**
   * Updates a sub-rectangle of the currently bound texture to [data].
   */
  @Deprecated("Use texSubImage2D")
  void texSubImage2DTyped(
      int targetTexture,
      int levelOfDetail,
      int xOffset,
      int yOffset,
      int width,
      int height,
      int border,
      int format,
      int type,
      TypedData data) {
    texSubImage2D(targetTexture, levelOfDetail, xOffset, yOffset, width, height,
        format, type, data);
  }

  /**
   * Set the bufferData to [data].
   */
  @Deprecated("Use bufferData")
  void bufferDataTyped(int target, TypedData data, int usage) {
    bufferData(target, data, usage);
  }

  /**
   * Set the bufferSubData to [data].
   */
  @Deprecated("Use bufferSubData")
  void bufferSubDataTyped(int target, int offset, TypedData data) {
    bufferSubData(target, offset, data);
  }
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGL2RenderingContext")
class RenderingContext2 extends JavaScriptObject
    implements _WebGL2RenderingContextBase, _WebGLRenderingContextBase {
  // To suppress missing implicit constructor warnings.
  factory RenderingContext2._() {
    throw new UnsupportedError("Not supported");
  }

  Canvas? get canvas native;

  // From WebGL2RenderingContextBase

  void beginQuery(int target, Query query) native;

  void beginTransformFeedback(int primitiveMode) native;

  void bindBufferBase(int target, int index, Buffer? buffer) native;

  void bindBufferRange(
      int target, int index, Buffer? buffer, int offset, int size) native;

  void bindSampler(int unit, Sampler? sampler) native;

  void bindTransformFeedback(int target, TransformFeedback? feedback) native;

  void bindVertexArray(VertexArrayObject? vertexArray) native;

  void blitFramebuffer(int srcX0, int srcY0, int srcX1, int srcY1, int dstX0,
      int dstY0, int dstX1, int dstY1, int mask, int filter) native;

  @JSName('bufferData')
  void bufferData2(int target, TypedData srcData, int usage, int srcOffset,
      [int? length]) native;

  @JSName('bufferSubData')
  void bufferSubData2(
      int target, int dstByteOffset, TypedData srcData, int srcOffset,
      [int? length]) native;

  void clearBufferfi(int buffer, int drawbuffer, num depth, int stencil) native;

  void clearBufferfv(int buffer, int drawbuffer, value, [int? srcOffset])
      native;

  void clearBufferiv(int buffer, int drawbuffer, value, [int? srcOffset])
      native;

  void clearBufferuiv(int buffer, int drawbuffer, value, [int? srcOffset])
      native;

  int clientWaitSync(Sync sync, int flags, int timeout) native;

  @JSName('compressedTexImage2D')
  void compressedTexImage2D2(int target, int level, int internalformat,
      int width, int height, int border, TypedData data, int srcOffset,
      [int? srcLengthOverride]) native;

  @JSName('compressedTexImage2D')
  void compressedTexImage2D3(int target, int level, int internalformat,
      int width, int height, int border, int imageSize, int offset) native;

  void compressedTexImage3D(int target, int level, int internalformat,
      int width, int height, int depth, int border, TypedData data,
      [int? srcOffset, int? srcLengthOverride]) native;

  @JSName('compressedTexImage3D')
  void compressedTexImage3D2(
      int target,
      int level,
      int internalformat,
      int width,
      int height,
      int depth,
      int border,
      int imageSize,
      int offset) native;

  @JSName('compressedTexSubImage2D')
  void compressedTexSubImage2D2(int target, int level, int xoffset, int yoffset,
      int width, int height, int format, TypedData data, int srcOffset,
      [int? srcLengthOverride]) native;

  @JSName('compressedTexSubImage2D')
  void compressedTexSubImage2D3(int target, int level, int xoffset, int yoffset,
      int width, int height, int format, int imageSize, int offset) native;

  void compressedTexSubImage3D(int target, int level, int xoffset, int yoffset,
      int zoffset, int width, int height, int depth, int format, TypedData data,
      [int? srcOffset, int? srcLengthOverride]) native;

  @JSName('compressedTexSubImage3D')
  void compressedTexSubImage3D2(
      int target,
      int level,
      int xoffset,
      int yoffset,
      int zoffset,
      int width,
      int height,
      int depth,
      int format,
      int imageSize,
      int offset) native;

  void copyBufferSubData(int readTarget, int writeTarget, int readOffset,
      int writeOffset, int size) native;

  void copyTexSubImage3D(int target, int level, int xoffset, int yoffset,
      int zoffset, int x, int y, int width, int height) native;

  Query? createQuery() native;

  Sampler? createSampler() native;

  TransformFeedback? createTransformFeedback() native;

  VertexArrayObject? createVertexArray() native;

  void deleteQuery(Query? query) native;

  void deleteSampler(Sampler? sampler) native;

  void deleteSync(Sync? sync) native;

  void deleteTransformFeedback(TransformFeedback? feedback) native;

  void deleteVertexArray(VertexArrayObject? vertexArray) native;

  void drawArraysInstanced(int mode, int first, int count, int instanceCount)
      native;

  void drawBuffers(List<int> buffers) native;

  void drawElementsInstanced(
      int mode, int count, int type, int offset, int instanceCount) native;

  void drawRangeElements(
      int mode, int start, int end, int count, int type, int offset) native;

  void endQuery(int target) native;

  void endTransformFeedback() native;

  Sync? fenceSync(int condition, int flags) native;

  void framebufferTextureLayer(int target, int attachment, Texture? texture,
      int level, int layer) native;

  String? getActiveUniformBlockName(Program program, int uniformBlockIndex)
      native;

  Object? getActiveUniformBlockParameter(
      Program program, int uniformBlockIndex, int pname) native;

  Object? getActiveUniforms(
      Program program, List<int> uniformIndices, int pname) native;

  void getBufferSubData(int target, int srcByteOffset, TypedData dstData,
      [int? dstOffset, int? length]) native;

  int getFragDataLocation(Program program, String name) native;

  Object? getIndexedParameter(int target, int index) native;

  Object? getInternalformatParameter(int target, int internalformat, int pname)
      native;

  Object? getQuery(int target, int pname) native;

  Object? getQueryParameter(Query query, int pname) native;

  Object? getSamplerParameter(Sampler sampler, int pname) native;

  Object? getSyncParameter(Sync sync, int pname) native;

  ActiveInfo? getTransformFeedbackVarying(Program program, int index) native;

  int getUniformBlockIndex(Program program, String uniformBlockName) native;

  List<int>? getUniformIndices(Program program, List<String> uniformNames) {
    List uniformNames_1 = convertDartToNative_StringArray(uniformNames);
    return _getUniformIndices_1(program, uniformNames_1);
  }

  @JSName('getUniformIndices')
  List<int>? _getUniformIndices_1(Program program, List uniformNames) native;

  void invalidateFramebuffer(int target, List<int> attachments) native;

  void invalidateSubFramebuffer(int target, List<int> attachments, int x, int y,
      int width, int height) native;

  bool isQuery(Query? query) native;

  bool isSampler(Sampler? sampler) native;

  bool isSync(Sync? sync) native;

  bool isTransformFeedback(TransformFeedback? feedback) native;

  bool isVertexArray(VertexArrayObject? vertexArray) native;

  void pauseTransformFeedback() native;

  void readBuffer(int mode) native;

  @JSName('readPixels')
  void readPixels2(int x, int y, int width, int height, int format, int type,
      dstData_OR_offset,
      [int? offset]) native;

  void renderbufferStorageMultisample(int target, int samples,
      int internalformat, int width, int height) native;

  void resumeTransformFeedback() native;

  void samplerParameterf(Sampler sampler, int pname, num param) native;

  void samplerParameteri(Sampler sampler, int pname, int param) native;

  void texImage2D2(
      int target,
      int level,
      int internalformat,
      int width,
      int height,
      int border,
      int format,
      int type,
      bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video,
      [int? srcOffset]) {
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is int) &&
        srcOffset == null) {
      _texImage2D2_1(
          target,
          level,
          internalformat,
          width,
          height,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is ImageData) &&
        srcOffset == null) {
      var data_1 = convertDartToNative_ImageData(
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      _texImage2D2_2(target, level, internalformat, width, height, border,
          format, type, data_1);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is ImageElement) &&
        srcOffset == null) {
      _texImage2D2_3(
          target,
          level,
          internalformat,
          width,
          height,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is CanvasElement) &&
        srcOffset == null) {
      _texImage2D2_4(
          target,
          level,
          internalformat,
          width,
          height,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is VideoElement) &&
        srcOffset == null) {
      _texImage2D2_5(
          target,
          level,
          internalformat,
          width,
          height,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is ImageBitmap) &&
        srcOffset == null) {
      _texImage2D2_6(
          target,
          level,
          internalformat,
          width,
          height,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if (srcOffset != null &&
        (bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is TypedData)) {
      _texImage2D2_7(
          target,
          level,
          internalformat,
          width,
          height,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video,
          srcOffset);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @JSName('texImage2D')
  void _texImage2D2_1(target, level, internalformat, width, height, border,
      format, type, int offset) native;
  @JSName('texImage2D')
  void _texImage2D2_2(target, level, internalformat, width, height, border,
      format, type, data) native;
  @JSName('texImage2D')
  void _texImage2D2_3(target, level, internalformat, width, height, border,
      format, type, ImageElement image) native;
  @JSName('texImage2D')
  void _texImage2D2_4(target, level, internalformat, width, height, border,
      format, type, CanvasElement canvas) native;
  @JSName('texImage2D')
  void _texImage2D2_5(target, level, internalformat, width, height, border,
      format, type, VideoElement video) native;
  @JSName('texImage2D')
  void _texImage2D2_6(target, level, internalformat, width, height, border,
      format, type, ImageBitmap bitmap) native;
  @JSName('texImage2D')
  void _texImage2D2_7(target, level, internalformat, width, height, border,
      format, type, TypedData srcData, srcOffset) native;

  void texImage3D(
      int target,
      int level,
      int internalformat,
      int width,
      int height,
      int depth,
      int border,
      int format,
      int type,
      bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video,
      [int? srcOffset]) {
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is int) &&
        srcOffset == null) {
      _texImage3D_1(
          target,
          level,
          internalformat,
          width,
          height,
          depth,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is ImageData) &&
        srcOffset == null) {
      var data_1 = convertDartToNative_ImageData(
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      _texImage3D_2(target, level, internalformat, width, height, depth, border,
          format, type, data_1);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is ImageElement) &&
        srcOffset == null) {
      _texImage3D_3(
          target,
          level,
          internalformat,
          width,
          height,
          depth,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is CanvasElement) &&
        srcOffset == null) {
      _texImage3D_4(
          target,
          level,
          internalformat,
          width,
          height,
          depth,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is VideoElement) &&
        srcOffset == null) {
      _texImage3D_5(
          target,
          level,
          internalformat,
          width,
          height,
          depth,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is ImageBitmap) &&
        srcOffset == null) {
      _texImage3D_6(
          target,
          level,
          internalformat,
          width,
          height,
          depth,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
                is TypedData ||
            bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video ==
                null) &&
        srcOffset == null) {
      _texImage3D_7(
          target,
          level,
          internalformat,
          width,
          height,
          depth,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if (srcOffset != null &&
        (bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is TypedData)) {
      _texImage3D_8(
          target,
          level,
          internalformat,
          width,
          height,
          depth,
          border,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video,
          srcOffset);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @JSName('texImage3D')
  void _texImage3D_1(target, level, internalformat, width, height, depth,
      border, format, type, int offset) native;
  @JSName('texImage3D')
  void _texImage3D_2(target, level, internalformat, width, height, depth,
      border, format, type, data) native;
  @JSName('texImage3D')
  void _texImage3D_3(target, level, internalformat, width, height, depth,
      border, format, type, ImageElement image) native;
  @JSName('texImage3D')
  void _texImage3D_4(target, level, internalformat, width, height, depth,
      border, format, type, CanvasElement canvas) native;
  @JSName('texImage3D')
  void _texImage3D_5(target, level, internalformat, width, height, depth,
      border, format, type, VideoElement video) native;
  @JSName('texImage3D')
  void _texImage3D_6(target, level, internalformat, width, height, depth,
      border, format, type, ImageBitmap bitmap) native;
  @JSName('texImage3D')
  void _texImage3D_7(target, level, internalformat, width, height, depth,
      border, format, type, TypedData? pixels) native;
  @JSName('texImage3D')
  void _texImage3D_8(target, level, internalformat, width, height, depth,
      border, format, type, TypedData pixels, srcOffset) native;

  void texStorage2D(
      int target, int levels, int internalformat, int width, int height) native;

  void texStorage3D(int target, int levels, int internalformat, int width,
      int height, int depth) native;

  void texSubImage2D2(
      int target,
      int level,
      int xoffset,
      int yoffset,
      int width,
      int height,
      int format,
      int type,
      bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video,
      [int? srcOffset]) {
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is int) &&
        srcOffset == null) {
      _texSubImage2D2_1(
          target,
          level,
          xoffset,
          yoffset,
          width,
          height,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is ImageData) &&
        srcOffset == null) {
      var data_1 = convertDartToNative_ImageData(
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      _texSubImage2D2_2(
          target, level, xoffset, yoffset, width, height, format, type, data_1);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is ImageElement) &&
        srcOffset == null) {
      _texSubImage2D2_3(
          target,
          level,
          xoffset,
          yoffset,
          width,
          height,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is CanvasElement) &&
        srcOffset == null) {
      _texSubImage2D2_4(
          target,
          level,
          xoffset,
          yoffset,
          width,
          height,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is VideoElement) &&
        srcOffset == null) {
      _texSubImage2D2_5(
          target,
          level,
          xoffset,
          yoffset,
          width,
          height,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is ImageBitmap) &&
        srcOffset == null) {
      _texSubImage2D2_6(
          target,
          level,
          xoffset,
          yoffset,
          width,
          height,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video);
      return;
    }
    if (srcOffset != null &&
        (bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video
            is TypedData)) {
      _texSubImage2D2_7(
          target,
          level,
          xoffset,
          yoffset,
          width,
          height,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_srcData_OR_video,
          srcOffset);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @JSName('texSubImage2D')
  void _texSubImage2D2_1(target, level, xoffset, yoffset, width, height, format,
      type, int offset) native;
  @JSName('texSubImage2D')
  void _texSubImage2D2_2(target, level, xoffset, yoffset, width, height, format,
      type, data) native;
  @JSName('texSubImage2D')
  void _texSubImage2D2_3(target, level, xoffset, yoffset, width, height, format,
      type, ImageElement image) native;
  @JSName('texSubImage2D')
  void _texSubImage2D2_4(target, level, xoffset, yoffset, width, height, format,
      type, CanvasElement canvas) native;
  @JSName('texSubImage2D')
  void _texSubImage2D2_5(target, level, xoffset, yoffset, width, height, format,
      type, VideoElement video) native;
  @JSName('texSubImage2D')
  void _texSubImage2D2_6(target, level, xoffset, yoffset, width, height, format,
      type, ImageBitmap bitmap) native;
  @JSName('texSubImage2D')
  void _texSubImage2D2_7(target, level, xoffset, yoffset, width, height, format,
      type, TypedData srcData, srcOffset) native;

  void texSubImage3D(
      int target,
      int level,
      int xoffset,
      int yoffset,
      int zoffset,
      int width,
      int height,
      int depth,
      int format,
      int type,
      bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video,
      [int? srcOffset]) {
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is int) &&
        srcOffset == null) {
      _texSubImage3D_1(
          target,
          level,
          xoffset,
          yoffset,
          zoffset,
          width,
          height,
          depth,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is ImageData) &&
        srcOffset == null) {
      var data_1 = convertDartToNative_ImageData(
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      _texSubImage3D_2(target, level, xoffset, yoffset, zoffset, width, height,
          depth, format, type, data_1);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is ImageElement) &&
        srcOffset == null) {
      _texSubImage3D_3(
          target,
          level,
          xoffset,
          yoffset,
          zoffset,
          width,
          height,
          depth,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is CanvasElement) &&
        srcOffset == null) {
      _texSubImage3D_4(
          target,
          level,
          xoffset,
          yoffset,
          zoffset,
          width,
          height,
          depth,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is VideoElement) &&
        srcOffset == null) {
      _texSubImage3D_5(
          target,
          level,
          xoffset,
          yoffset,
          zoffset,
          width,
          height,
          depth,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is ImageBitmap) &&
        srcOffset == null) {
      _texSubImage3D_6(
          target,
          level,
          xoffset,
          yoffset,
          zoffset,
          width,
          height,
          depth,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is TypedData) &&
        srcOffset == null) {
      _texSubImage3D_7(
          target,
          level,
          xoffset,
          yoffset,
          zoffset,
          width,
          height,
          depth,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video);
      return;
    }
    if (srcOffset != null &&
        (bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video
            is TypedData)) {
      _texSubImage3D_8(
          target,
          level,
          xoffset,
          yoffset,
          zoffset,
          width,
          height,
          depth,
          format,
          type,
          bitmap_OR_canvas_OR_data_OR_image_OR_offset_OR_pixels_OR_video,
          srcOffset);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @JSName('texSubImage3D')
  void _texSubImage3D_1(target, level, xoffset, yoffset, zoffset, width, height,
      depth, format, type, int offset) native;
  @JSName('texSubImage3D')
  void _texSubImage3D_2(target, level, xoffset, yoffset, zoffset, width, height,
      depth, format, type, data) native;
  @JSName('texSubImage3D')
  void _texSubImage3D_3(target, level, xoffset, yoffset, zoffset, width, height,
      depth, format, type, ImageElement image) native;
  @JSName('texSubImage3D')
  void _texSubImage3D_4(target, level, xoffset, yoffset, zoffset, width, height,
      depth, format, type, CanvasElement canvas) native;
  @JSName('texSubImage3D')
  void _texSubImage3D_5(target, level, xoffset, yoffset, zoffset, width, height,
      depth, format, type, VideoElement video) native;
  @JSName('texSubImage3D')
  void _texSubImage3D_6(target, level, xoffset, yoffset, zoffset, width, height,
      depth, format, type, ImageBitmap bitmap) native;
  @JSName('texSubImage3D')
  void _texSubImage3D_7(target, level, xoffset, yoffset, zoffset, width, height,
      depth, format, type, TypedData pixels) native;
  @JSName('texSubImage3D')
  void _texSubImage3D_8(target, level, xoffset, yoffset, zoffset, width, height,
      depth, format, type, TypedData pixels, srcOffset) native;

  void transformFeedbackVaryings(
      Program program, List<String> varyings, int bufferMode) {
    List varyings_1 = convertDartToNative_StringArray(varyings);
    _transformFeedbackVaryings_1(program, varyings_1, bufferMode);
    return;
  }

  @JSName('transformFeedbackVaryings')
  void _transformFeedbackVaryings_1(Program program, List varyings, bufferMode)
      native;

  @JSName('uniform1fv')
  void uniform1fv2(UniformLocation? location, v, int srcOffset,
      [int? srcLength]) native;

  @JSName('uniform1iv')
  void uniform1iv2(UniformLocation? location, v, int srcOffset,
      [int? srcLength]) native;

  void uniform1ui(UniformLocation? location, int v0) native;

  void uniform1uiv(UniformLocation? location, v,
      [int? srcOffset, int? srcLength]) native;

  @JSName('uniform2fv')
  void uniform2fv2(UniformLocation? location, v, int srcOffset,
      [int? srcLength]) native;

  @JSName('uniform2iv')
  void uniform2iv2(UniformLocation? location, v, int srcOffset,
      [int? srcLength]) native;

  void uniform2ui(UniformLocation? location, int v0, int v1) native;

  void uniform2uiv(UniformLocation? location, v,
      [int? srcOffset, int? srcLength]) native;

  @JSName('uniform3fv')
  void uniform3fv2(UniformLocation? location, v, int srcOffset,
      [int? srcLength]) native;

  @JSName('uniform3iv')
  void uniform3iv2(UniformLocation? location, v, int srcOffset,
      [int? srcLength]) native;

  void uniform3ui(UniformLocation? location, int v0, int v1, int v2) native;

  void uniform3uiv(UniformLocation? location, v,
      [int? srcOffset, int? srcLength]) native;

  @JSName('uniform4fv')
  void uniform4fv2(UniformLocation? location, v, int srcOffset,
      [int? srcLength]) native;

  @JSName('uniform4iv')
  void uniform4iv2(UniformLocation? location, v, int srcOffset,
      [int? srcLength]) native;

  void uniform4ui(UniformLocation? location, int v0, int v1, int v2, int v3)
      native;

  void uniform4uiv(UniformLocation? location, v,
      [int? srcOffset, int? srcLength]) native;

  void uniformBlockBinding(
      Program program, int uniformBlockIndex, int uniformBlockBinding) native;

  @JSName('uniformMatrix2fv')
  void uniformMatrix2fv2(
      UniformLocation? location, bool transpose, array, int srcOffset,
      [int? srcLength]) native;

  void uniformMatrix2x3fv(UniformLocation? location, bool transpose, value,
      [int? srcOffset, int? srcLength]) native;

  void uniformMatrix2x4fv(UniformLocation? location, bool transpose, value,
      [int? srcOffset, int? srcLength]) native;

  @JSName('uniformMatrix3fv')
  void uniformMatrix3fv2(
      UniformLocation? location, bool transpose, array, int srcOffset,
      [int? srcLength]) native;

  void uniformMatrix3x2fv(UniformLocation? location, bool transpose, value,
      [int? srcOffset, int? srcLength]) native;

  void uniformMatrix3x4fv(UniformLocation? location, bool transpose, value,
      [int? srcOffset, int? srcLength]) native;

  @JSName('uniformMatrix4fv')
  void uniformMatrix4fv2(
      UniformLocation? location, bool transpose, array, int srcOffset,
      [int? srcLength]) native;

  void uniformMatrix4x2fv(UniformLocation? location, bool transpose, value,
      [int? srcOffset, int? srcLength]) native;

  void uniformMatrix4x3fv(UniformLocation? location, bool transpose, value,
      [int? srcOffset, int? srcLength]) native;

  void vertexAttribDivisor(int index, int divisor) native;

  void vertexAttribI4i(int index, int x, int y, int z, int w) native;

  void vertexAttribI4iv(int index, v) native;

  void vertexAttribI4ui(int index, int x, int y, int z, int w) native;

  void vertexAttribI4uiv(int index, v) native;

  void vertexAttribIPointer(
      int index, int size, int type, int stride, int offset) native;

  void waitSync(Sync sync, int flags, int timeout) native;

  // From WebGLRenderingContextBase

  int? get drawingBufferHeight native;

  int? get drawingBufferWidth native;

  void activeTexture(int texture) native;

  void attachShader(Program program, Shader shader) native;

  void bindAttribLocation(Program program, int index, String name) native;

  void bindBuffer(int target, Buffer? buffer) native;

  void bindFramebuffer(int target, Framebuffer? framebuffer) native;

  void bindRenderbuffer(int target, Renderbuffer? renderbuffer) native;

  void bindTexture(int target, Texture? texture) native;

  void blendColor(num red, num green, num blue, num alpha) native;

  void blendEquation(int mode) native;

  void blendEquationSeparate(int modeRGB, int modeAlpha) native;

  void blendFunc(int sfactor, int dfactor) native;

  void blendFuncSeparate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha)
      native;

  void bufferData(int target, data_OR_size, int usage) native;

  void bufferSubData(int target, int offset, data) native;

  int checkFramebufferStatus(int target) native;

  void clear(int mask) native;

  void clearColor(num red, num green, num blue, num alpha) native;

  void clearDepth(num depth) native;

  void clearStencil(int s) native;

  void colorMask(bool red, bool green, bool blue, bool alpha) native;

  Future commit() => promiseToFuture(JS("", "#.commit()", this));

  void compileShader(Shader shader) native;

  void compressedTexImage2D(int target, int level, int internalformat,
      int width, int height, int border, TypedData data) native;

  void compressedTexSubImage2D(int target, int level, int xoffset, int yoffset,
      int width, int height, int format, TypedData data) native;

  void copyTexImage2D(int target, int level, int internalformat, int x, int y,
      int width, int height, int border) native;

  void copyTexSubImage2D(int target, int level, int xoffset, int yoffset, int x,
      int y, int width, int height) native;

  Buffer createBuffer() native;

  Framebuffer createFramebuffer() native;

  Program createProgram() native;

  Renderbuffer createRenderbuffer() native;

  Shader createShader(int type) native;

  Texture createTexture() native;

  void cullFace(int mode) native;

  void deleteBuffer(Buffer? buffer) native;

  void deleteFramebuffer(Framebuffer? framebuffer) native;

  void deleteProgram(Program? program) native;

  void deleteRenderbuffer(Renderbuffer? renderbuffer) native;

  void deleteShader(Shader? shader) native;

  void deleteTexture(Texture? texture) native;

  void depthFunc(int func) native;

  void depthMask(bool flag) native;

  void depthRange(num zNear, num zFar) native;

  void detachShader(Program program, Shader shader) native;

  void disable(int cap) native;

  void disableVertexAttribArray(int index) native;

  void drawArrays(int mode, int first, int count) native;

  void drawElements(int mode, int count, int type, int offset) native;

  void enable(int cap) native;

  void enableVertexAttribArray(int index) native;

  void finish() native;

  void flush() native;

  void framebufferRenderbuffer(int target, int attachment,
      int renderbuffertarget, Renderbuffer? renderbuffer) native;

  void framebufferTexture2D(int target, int attachment, int textarget,
      Texture? texture, int level) native;

  void frontFace(int mode) native;

  void generateMipmap(int target) native;

  ActiveInfo getActiveAttrib(Program program, int index) native;

  ActiveInfo getActiveUniform(Program program, int index) native;

  List<Shader>? getAttachedShaders(Program program) native;

  int getAttribLocation(Program program, String name) native;

  Object? getBufferParameter(int target, int pname) native;

  Map? getContextAttributes() {
    return convertNativeToDart_Dictionary(_getContextAttributes_1());
  }

  @JSName('getContextAttributes')
  _getContextAttributes_1() native;

  int getError() native;

  Object? getExtension(String name) native;

  Object? getFramebufferAttachmentParameter(
      int target, int attachment, int pname) native;

  Object? getParameter(int pname) native;

  String? getProgramInfoLog(Program program) native;

  Object? getProgramParameter(Program program, int pname) native;

  Object? getRenderbufferParameter(int target, int pname) native;

  String? getShaderInfoLog(Shader shader) native;

  Object? getShaderParameter(Shader shader, int pname) native;

  ShaderPrecisionFormat getShaderPrecisionFormat(
      int shadertype, int precisiontype) native;

  String? getShaderSource(Shader shader) native;

  List<String>? getSupportedExtensions() native;

  Object? getTexParameter(int target, int pname) native;

  Object? getUniform(Program program, UniformLocation location) native;

  UniformLocation getUniformLocation(Program program, String name) native;

  Object? getVertexAttrib(int index, int pname) native;

  int getVertexAttribOffset(int index, int pname) native;

  void hint(int target, int mode) native;

  bool isBuffer(Buffer? buffer) native;

  bool isContextLost() native;

  bool isEnabled(int cap) native;

  bool isFramebuffer(Framebuffer? framebuffer) native;

  bool isProgram(Program? program) native;

  bool isRenderbuffer(Renderbuffer? renderbuffer) native;

  bool isShader(Shader? shader) native;

  bool isTexture(Texture? texture) native;

  void lineWidth(num width) native;

  void linkProgram(Program program) native;

  void pixelStorei(int pname, int param) native;

  void polygonOffset(num factor, num units) native;

  @JSName('readPixels')
  void _readPixels(int x, int y, int width, int height, int format, int type,
      TypedData? pixels) native;

  void renderbufferStorage(
      int target, int internalformat, int width, int height) native;

  void sampleCoverage(num value, bool invert) native;

  void scissor(int x, int y, int width, int height) native;

  void shaderSource(Shader shader, String string) native;

  void stencilFunc(int func, int ref, int mask) native;

  void stencilFuncSeparate(int face, int func, int ref, int mask) native;

  void stencilMask(int mask) native;

  void stencilMaskSeparate(int face, int mask) native;

  void stencilOp(int fail, int zfail, int zpass) native;

  void stencilOpSeparate(int face, int fail, int zfail, int zpass) native;

  void texImage2D(
      int target,
      int level,
      int internalformat,
      int format_OR_width,
      int height_OR_type,
      bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video,
      [int? format,
      int? type,
      TypedData? pixels]) {
    if (type != null &&
        format != null &&
        (bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video is int)) {
      _texImage2D_1(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video,
          format,
          type,
          pixels);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video is ImageData) &&
        format == null &&
        type == null &&
        pixels == null) {
      var pixels_1 = convertDartToNative_ImageData(
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      _texImage2D_2(target, level, internalformat, format_OR_width,
          height_OR_type, pixels_1);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video
            is ImageElement) &&
        format == null &&
        type == null &&
        pixels == null) {
      _texImage2D_3(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video
            is CanvasElement) &&
        format == null &&
        type == null &&
        pixels == null) {
      _texImage2D_4(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video
            is VideoElement) &&
        format == null &&
        type == null &&
        pixels == null) {
      _texImage2D_5(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video
            is ImageBitmap) &&
        format == null &&
        type == null &&
        pixels == null) {
      _texImage2D_6(
          target,
          level,
          internalformat,
          format_OR_width,
          height_OR_type,
          bitmap_OR_border_OR_canvas_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @JSName('texImage2D')
  void _texImage2D_1(target, level, internalformat, width, height, int border,
      format, type, TypedData? pixels) native;
  @JSName('texImage2D')
  void _texImage2D_2(target, level, internalformat, format, type, pixels)
      native;
  @JSName('texImage2D')
  void _texImage2D_3(
      target, level, internalformat, format, type, ImageElement image) native;
  @JSName('texImage2D')
  void _texImage2D_4(
      target, level, internalformat, format, type, CanvasElement canvas) native;
  @JSName('texImage2D')
  void _texImage2D_5(
      target, level, internalformat, format, type, VideoElement video) native;
  @JSName('texImage2D')
  void _texImage2D_6(
      target, level, internalformat, format, type, ImageBitmap bitmap) native;

  void texParameterf(int target, int pname, num param) native;

  void texParameteri(int target, int pname, int param) native;

  void texSubImage2D(
      int target,
      int level,
      int xoffset,
      int yoffset,
      int format_OR_width,
      int height_OR_type,
      bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video,
      [int? type,
      TypedData? pixels]) {
    if (type != null &&
        (bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video is int)) {
      _texSubImage2D_1(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video,
          type,
          pixels);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video is ImageData) &&
        type == null &&
        pixels == null) {
      var pixels_1 = convertDartToNative_ImageData(
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      _texSubImage2D_2(target, level, xoffset, yoffset, format_OR_width,
          height_OR_type, pixels_1);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video
            is ImageElement) &&
        type == null &&
        pixels == null) {
      _texSubImage2D_3(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video
            is CanvasElement) &&
        type == null &&
        pixels == null) {
      _texSubImage2D_4(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video
            is VideoElement) &&
        type == null &&
        pixels == null) {
      _texSubImage2D_5(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    if ((bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video
            is ImageBitmap) &&
        type == null &&
        pixels == null) {
      _texSubImage2D_6(
          target,
          level,
          xoffset,
          yoffset,
          format_OR_width,
          height_OR_type,
          bitmap_OR_canvas_OR_format_OR_image_OR_pixels_OR_video);
      return;
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @JSName('texSubImage2D')
  void _texSubImage2D_1(target, level, xoffset, yoffset, width, height,
      int format, type, TypedData? pixels) native;
  @JSName('texSubImage2D')
  void _texSubImage2D_2(target, level, xoffset, yoffset, format, type, pixels)
      native;
  @JSName('texSubImage2D')
  void _texSubImage2D_3(
      target, level, xoffset, yoffset, format, type, ImageElement image) native;
  @JSName('texSubImage2D')
  void _texSubImage2D_4(target, level, xoffset, yoffset, format, type,
      CanvasElement canvas) native;
  @JSName('texSubImage2D')
  void _texSubImage2D_5(
      target, level, xoffset, yoffset, format, type, VideoElement video) native;
  @JSName('texSubImage2D')
  void _texSubImage2D_6(
      target, level, xoffset, yoffset, format, type, ImageBitmap bitmap) native;

  void uniform1f(UniformLocation? location, num x) native;

  void uniform1fv(UniformLocation? location, v) native;

  void uniform1i(UniformLocation? location, int x) native;

  void uniform1iv(UniformLocation? location, v) native;

  void uniform2f(UniformLocation? location, num x, num y) native;

  void uniform2fv(UniformLocation? location, v) native;

  void uniform2i(UniformLocation? location, int x, int y) native;

  void uniform2iv(UniformLocation? location, v) native;

  void uniform3f(UniformLocation? location, num x, num y, num z) native;

  void uniform3fv(UniformLocation? location, v) native;

  void uniform3i(UniformLocation? location, int x, int y, int z) native;

  void uniform3iv(UniformLocation? location, v) native;

  void uniform4f(UniformLocation? location, num x, num y, num z, num w) native;

  void uniform4fv(UniformLocation? location, v) native;

  void uniform4i(UniformLocation? location, int x, int y, int z, int w) native;

  void uniform4iv(UniformLocation? location, v) native;

  void uniformMatrix2fv(UniformLocation? location, bool transpose, array)
      native;

  void uniformMatrix3fv(UniformLocation? location, bool transpose, array)
      native;

  void uniformMatrix4fv(UniformLocation? location, bool transpose, array)
      native;

  void useProgram(Program? program) native;

  void validateProgram(Program program) native;

  void vertexAttrib1f(int indx, num x) native;

  void vertexAttrib1fv(int indx, values) native;

  void vertexAttrib2f(int indx, num x, num y) native;

  void vertexAttrib2fv(int indx, values) native;

  void vertexAttrib3f(int indx, num x, num y, num z) native;

  void vertexAttrib3fv(int indx, values) native;

  void vertexAttrib4f(int indx, num x, num y, num z, num w) native;

  void vertexAttrib4fv(int indx, values) native;

  void vertexAttribPointer(int indx, int size, int type, bool normalized,
      int stride, int offset) native;

  void viewport(int x, int y, int width, int height) native;

  void readPixels(int x, int y, int width, int height, int format, int type,
      TypedData pixels) {
    _readPixels(x, y, width, height, format, type, pixels);
  }
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLSampler")
class Sampler extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory Sampler._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLShader")
class Shader extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory Shader._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLShaderPrecisionFormat")
class ShaderPrecisionFormat extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory ShaderPrecisionFormat._() {
    throw new UnsupportedError("Not supported");
  }

  int get precision native;

  int get rangeMax native;

  int get rangeMin native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLSync")
class Sync extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory Sync._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLTexture")
class Texture extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory Texture._() {
    throw new UnsupportedError("Not supported");
  }

  bool? get lastUploadedVideoFrameWasSkipped native;

  int? get lastUploadedVideoHeight native;

  num? get lastUploadedVideoTimestamp native;

  int? get lastUploadedVideoWidth native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLTimerQueryEXT")
class TimerQueryExt extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory TimerQueryExt._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLTransformFeedback")
class TransformFeedback extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory TransformFeedback._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLUniformLocation")
class UniformLocation extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory UniformLocation._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLVertexArrayObject")
class VertexArrayObject extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory VertexArrayObject._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGLVertexArrayObjectOES")
class VertexArrayObjectOes extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory VertexArrayObjectOes._() {
    throw new UnsupportedError("Not supported");
  }
}
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Amalgamation of the WebGL constants from the IDL interfaces in
/// WebGLRenderingContextBase, WebGL2RenderingContextBase, & WebGLDrawBuffers.
/// Because the RenderingContextBase interfaces are hidden they would be
/// replicated in more than one class (e.g., RenderingContext and
/// RenderingContext2) to prevent that duplication these 600+ constants are
/// defined in one abstract class (WebGL).
@Native("WebGL")
abstract class WebGL {
  // To suppress missing implicit constructor warnings.
  factory WebGL._() {
    throw new UnsupportedError("Not supported");
  }

  static const int ACTIVE_ATTRIBUTES = 0x8B89;

  static const int ACTIVE_TEXTURE = 0x84E0;

  static const int ACTIVE_UNIFORMS = 0x8B86;

  static const int ACTIVE_UNIFORM_BLOCKS = 0x8A36;

  static const int ALIASED_LINE_WIDTH_RANGE = 0x846E;

  static const int ALIASED_POINT_SIZE_RANGE = 0x846D;

  static const int ALPHA = 0x1906;

  static const int ALPHA_BITS = 0x0D55;

  static const int ALREADY_SIGNALED = 0x911A;

  static const int ALWAYS = 0x0207;

  static const int ANY_SAMPLES_PASSED = 0x8C2F;

  static const int ANY_SAMPLES_PASSED_CONSERVATIVE = 0x8D6A;

  static const int ARRAY_BUFFER = 0x8892;

  static const int ARRAY_BUFFER_BINDING = 0x8894;

  static const int ATTACHED_SHADERS = 0x8B85;

  static const int BACK = 0x0405;

  static const int BLEND = 0x0BE2;

  static const int BLEND_COLOR = 0x8005;

  static const int BLEND_DST_ALPHA = 0x80CA;

  static const int BLEND_DST_RGB = 0x80C8;

  static const int BLEND_EQUATION = 0x8009;

  static const int BLEND_EQUATION_ALPHA = 0x883D;

  static const int BLEND_EQUATION_RGB = 0x8009;

  static const int BLEND_SRC_ALPHA = 0x80CB;

  static const int BLEND_SRC_RGB = 0x80C9;

  static const int BLUE_BITS = 0x0D54;

  static const int BOOL = 0x8B56;

  static const int BOOL_VEC2 = 0x8B57;

  static const int BOOL_VEC3 = 0x8B58;

  static const int BOOL_VEC4 = 0x8B59;

  static const int BROWSER_DEFAULT_WEBGL = 0x9244;

  static const int BUFFER_SIZE = 0x8764;

  static const int BUFFER_USAGE = 0x8765;

  static const int BYTE = 0x1400;

  static const int CCW = 0x0901;

  static const int CLAMP_TO_EDGE = 0x812F;

  static const int COLOR = 0x1800;

  static const int COLOR_ATTACHMENT0 = 0x8CE0;

  static const int COLOR_ATTACHMENT0_WEBGL = 0x8CE0;

  static const int COLOR_ATTACHMENT1 = 0x8CE1;

  static const int COLOR_ATTACHMENT10 = 0x8CEA;

  static const int COLOR_ATTACHMENT10_WEBGL = 0x8CEA;

  static const int COLOR_ATTACHMENT11 = 0x8CEB;

  static const int COLOR_ATTACHMENT11_WEBGL = 0x8CEB;

  static const int COLOR_ATTACHMENT12 = 0x8CEC;

  static const int COLOR_ATTACHMENT12_WEBGL = 0x8CEC;

  static const int COLOR_ATTACHMENT13 = 0x8CED;

  static const int COLOR_ATTACHMENT13_WEBGL = 0x8CED;

  static const int COLOR_ATTACHMENT14 = 0x8CEE;

  static const int COLOR_ATTACHMENT14_WEBGL = 0x8CEE;

  static const int COLOR_ATTACHMENT15 = 0x8CEF;

  static const int COLOR_ATTACHMENT15_WEBGL = 0x8CEF;

  static const int COLOR_ATTACHMENT1_WEBGL = 0x8CE1;

  static const int COLOR_ATTACHMENT2 = 0x8CE2;

  static const int COLOR_ATTACHMENT2_WEBGL = 0x8CE2;

  static const int COLOR_ATTACHMENT3 = 0x8CE3;

  static const int COLOR_ATTACHMENT3_WEBGL = 0x8CE3;

  static const int COLOR_ATTACHMENT4 = 0x8CE4;

  static const int COLOR_ATTACHMENT4_WEBGL = 0x8CE4;

  static const int COLOR_ATTACHMENT5 = 0x8CE5;

  static const int COLOR_ATTACHMENT5_WEBGL = 0x8CE5;

  static const int COLOR_ATTACHMENT6 = 0x8CE6;

  static const int COLOR_ATTACHMENT6_WEBGL = 0x8CE6;

  static const int COLOR_ATTACHMENT7 = 0x8CE7;

  static const int COLOR_ATTACHMENT7_WEBGL = 0x8CE7;

  static const int COLOR_ATTACHMENT8 = 0x8CE8;

  static const int COLOR_ATTACHMENT8_WEBGL = 0x8CE8;

  static const int COLOR_ATTACHMENT9 = 0x8CE9;

  static const int COLOR_ATTACHMENT9_WEBGL = 0x8CE9;

  static const int COLOR_BUFFER_BIT = 0x00004000;

  static const int COLOR_CLEAR_VALUE = 0x0C22;

  static const int COLOR_WRITEMASK = 0x0C23;

  static const int COMPARE_REF_TO_TEXTURE = 0x884E;

  static const int COMPILE_STATUS = 0x8B81;

  static const int COMPRESSED_TEXTURE_FORMATS = 0x86A3;

  static const int CONDITION_SATISFIED = 0x911C;

  static const int CONSTANT_ALPHA = 0x8003;

  static const int CONSTANT_COLOR = 0x8001;

  static const int CONTEXT_LOST_WEBGL = 0x9242;

  static const int COPY_READ_BUFFER = 0x8F36;

  static const int COPY_READ_BUFFER_BINDING = 0x8F36;

  static const int COPY_WRITE_BUFFER = 0x8F37;

  static const int COPY_WRITE_BUFFER_BINDING = 0x8F37;

  static const int CULL_FACE = 0x0B44;

  static const int CULL_FACE_MODE = 0x0B45;

  static const int CURRENT_PROGRAM = 0x8B8D;

  static const int CURRENT_QUERY = 0x8865;

  static const int CURRENT_VERTEX_ATTRIB = 0x8626;

  static const int CW = 0x0900;

  static const int DECR = 0x1E03;

  static const int DECR_WRAP = 0x8508;

  static const int DELETE_STATUS = 0x8B80;

  static const int DEPTH = 0x1801;

  static const int DEPTH24_STENCIL8 = 0x88F0;

  static const int DEPTH32F_STENCIL8 = 0x8CAD;

  static const int DEPTH_ATTACHMENT = 0x8D00;

  static const int DEPTH_BITS = 0x0D56;

  static const int DEPTH_BUFFER_BIT = 0x00000100;

  static const int DEPTH_CLEAR_VALUE = 0x0B73;

  static const int DEPTH_COMPONENT = 0x1902;

  static const int DEPTH_COMPONENT16 = 0x81A5;

  static const int DEPTH_COMPONENT24 = 0x81A6;

  static const int DEPTH_COMPONENT32F = 0x8CAC;

  static const int DEPTH_FUNC = 0x0B74;

  static const int DEPTH_RANGE = 0x0B70;

  static const int DEPTH_STENCIL = 0x84F9;

  static const int DEPTH_STENCIL_ATTACHMENT = 0x821A;

  static const int DEPTH_TEST = 0x0B71;

  static const int DEPTH_WRITEMASK = 0x0B72;

  static const int DITHER = 0x0BD0;

  static const int DONT_CARE = 0x1100;

  static const int DRAW_BUFFER0 = 0x8825;

  static const int DRAW_BUFFER0_WEBGL = 0x8825;

  static const int DRAW_BUFFER1 = 0x8826;

  static const int DRAW_BUFFER10 = 0x882F;

  static const int DRAW_BUFFER10_WEBGL = 0x882F;

  static const int DRAW_BUFFER11 = 0x8830;

  static const int DRAW_BUFFER11_WEBGL = 0x8830;

  static const int DRAW_BUFFER12 = 0x8831;

  static const int DRAW_BUFFER12_WEBGL = 0x8831;

  static const int DRAW_BUFFER13 = 0x8832;

  static const int DRAW_BUFFER13_WEBGL = 0x8832;

  static const int DRAW_BUFFER14 = 0x8833;

  static const int DRAW_BUFFER14_WEBGL = 0x8833;

  static const int DRAW_BUFFER15 = 0x8834;

  static const int DRAW_BUFFER15_WEBGL = 0x8834;

  static const int DRAW_BUFFER1_WEBGL = 0x8826;

  static const int DRAW_BUFFER2 = 0x8827;

  static const int DRAW_BUFFER2_WEBGL = 0x8827;

  static const int DRAW_BUFFER3 = 0x8828;

  static const int DRAW_BUFFER3_WEBGL = 0x8828;

  static const int DRAW_BUFFER4 = 0x8829;

  static const int DRAW_BUFFER4_WEBGL = 0x8829;

  static const int DRAW_BUFFER5 = 0x882A;

  static const int DRAW_BUFFER5_WEBGL = 0x882A;

  static const int DRAW_BUFFER6 = 0x882B;

  static const int DRAW_BUFFER6_WEBGL = 0x882B;

  static const int DRAW_BUFFER7 = 0x882C;

  static const int DRAW_BUFFER7_WEBGL = 0x882C;

  static const int DRAW_BUFFER8 = 0x882D;

  static const int DRAW_BUFFER8_WEBGL = 0x882D;

  static const int DRAW_BUFFER9 = 0x882E;

  static const int DRAW_BUFFER9_WEBGL = 0x882E;

  static const int DRAW_FRAMEBUFFER = 0x8CA9;

  static const int DRAW_FRAMEBUFFER_BINDING = 0x8CA6;

  static const int DST_ALPHA = 0x0304;

  static const int DST_COLOR = 0x0306;

  static const int DYNAMIC_COPY = 0x88EA;

  static const int DYNAMIC_DRAW = 0x88E8;

  static const int DYNAMIC_READ = 0x88E9;

  static const int ELEMENT_ARRAY_BUFFER = 0x8893;

  static const int ELEMENT_ARRAY_BUFFER_BINDING = 0x8895;

  static const int EQUAL = 0x0202;

  static const int FASTEST = 0x1101;

  static const int FLOAT = 0x1406;

  static const int FLOAT_32_UNSIGNED_INT_24_8_REV = 0x8DAD;

  static const int FLOAT_MAT2 = 0x8B5A;

  static const int FLOAT_MAT2x3 = 0x8B65;

  static const int FLOAT_MAT2x4 = 0x8B66;

  static const int FLOAT_MAT3 = 0x8B5B;

  static const int FLOAT_MAT3x2 = 0x8B67;

  static const int FLOAT_MAT3x4 = 0x8B68;

  static const int FLOAT_MAT4 = 0x8B5C;

  static const int FLOAT_MAT4x2 = 0x8B69;

  static const int FLOAT_MAT4x3 = 0x8B6A;

  static const int FLOAT_VEC2 = 0x8B50;

  static const int FLOAT_VEC3 = 0x8B51;

  static const int FLOAT_VEC4 = 0x8B52;

  static const int FRAGMENT_SHADER = 0x8B30;

  static const int FRAGMENT_SHADER_DERIVATIVE_HINT = 0x8B8B;

  static const int FRAMEBUFFER = 0x8D40;

  static const int FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE = 0x8215;

  static const int FRAMEBUFFER_ATTACHMENT_BLUE_SIZE = 0x8214;

  static const int FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING = 0x8210;

  static const int FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE = 0x8211;

  static const int FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE = 0x8216;

  static const int FRAMEBUFFER_ATTACHMENT_GREEN_SIZE = 0x8213;

  static const int FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1;

  static const int FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 0x8CD0;

  static const int FRAMEBUFFER_ATTACHMENT_RED_SIZE = 0x8212;

  static const int FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE = 0x8217;

  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;

  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER = 0x8CD4;

  static const int FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 0x8CD2;

  static const int FRAMEBUFFER_BINDING = 0x8CA6;

  static const int FRAMEBUFFER_COMPLETE = 0x8CD5;

  static const int FRAMEBUFFER_DEFAULT = 0x8218;

  static const int FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6;

  static const int FRAMEBUFFER_INCOMPLETE_DIMENSIONS = 0x8CD9;

  static const int FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;

  static const int FRAMEBUFFER_INCOMPLETE_MULTISAMPLE = 0x8D56;

  static const int FRAMEBUFFER_UNSUPPORTED = 0x8CDD;

  static const int FRONT = 0x0404;

  static const int FRONT_AND_BACK = 0x0408;

  static const int FRONT_FACE = 0x0B46;

  static const int FUNC_ADD = 0x8006;

  static const int FUNC_REVERSE_SUBTRACT = 0x800B;

  static const int FUNC_SUBTRACT = 0x800A;

  static const int GENERATE_MIPMAP_HINT = 0x8192;

  static const int GEQUAL = 0x0206;

  static const int GREATER = 0x0204;

  static const int GREEN_BITS = 0x0D53;

  static const int HALF_FLOAT = 0x140B;

  static const int HIGH_FLOAT = 0x8DF2;

  static const int HIGH_INT = 0x8DF5;

  static const int IMPLEMENTATION_COLOR_READ_FORMAT = 0x8B9B;

  static const int IMPLEMENTATION_COLOR_READ_TYPE = 0x8B9A;

  static const int INCR = 0x1E02;

  static const int INCR_WRAP = 0x8507;

  static const int INT = 0x1404;

  static const int INTERLEAVED_ATTRIBS = 0x8C8C;

  static const int INT_2_10_10_10_REV = 0x8D9F;

  static const int INT_SAMPLER_2D = 0x8DCA;

  static const int INT_SAMPLER_2D_ARRAY = 0x8DCF;

  static const int INT_SAMPLER_3D = 0x8DCB;

  static const int INT_SAMPLER_CUBE = 0x8DCC;

  static const int INT_VEC2 = 0x8B53;

  static const int INT_VEC3 = 0x8B54;

  static const int INT_VEC4 = 0x8B55;

  static const int INVALID_ENUM = 0x0500;

  static const int INVALID_FRAMEBUFFER_OPERATION = 0x0506;

  static const int INVALID_INDEX = 0xFFFFFFFF;

  static const int INVALID_OPERATION = 0x0502;

  static const int INVALID_VALUE = 0x0501;

  static const int INVERT = 0x150A;

  static const int KEEP = 0x1E00;

  static const int LEQUAL = 0x0203;

  static const int LESS = 0x0201;

  static const int LINEAR = 0x2601;

  static const int LINEAR_MIPMAP_LINEAR = 0x2703;

  static const int LINEAR_MIPMAP_NEAREST = 0x2701;

  static const int LINES = 0x0001;

  static const int LINE_LOOP = 0x0002;

  static const int LINE_STRIP = 0x0003;

  static const int LINE_WIDTH = 0x0B21;

  static const int LINK_STATUS = 0x8B82;

  static const int LOW_FLOAT = 0x8DF0;

  static const int LOW_INT = 0x8DF3;

  static const int LUMINANCE = 0x1909;

  static const int LUMINANCE_ALPHA = 0x190A;

  static const int MAX = 0x8008;

  static const int MAX_3D_TEXTURE_SIZE = 0x8073;

  static const int MAX_ARRAY_TEXTURE_LAYERS = 0x88FF;

  static const int MAX_CLIENT_WAIT_TIMEOUT_WEBGL = 0x9247;

  static const int MAX_COLOR_ATTACHMENTS = 0x8CDF;

  static const int MAX_COLOR_ATTACHMENTS_WEBGL = 0x8CDF;

  static const int MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS = 0x8A33;

  static const int MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;

  static const int MAX_COMBINED_UNIFORM_BLOCKS = 0x8A2E;

  static const int MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS = 0x8A31;

  static const int MAX_CUBE_MAP_TEXTURE_SIZE = 0x851C;

  static const int MAX_DRAW_BUFFERS = 0x8824;

  static const int MAX_DRAW_BUFFERS_WEBGL = 0x8824;

  static const int MAX_ELEMENTS_INDICES = 0x80E9;

  static const int MAX_ELEMENTS_VERTICES = 0x80E8;

  static const int MAX_ELEMENT_INDEX = 0x8D6B;

  static const int MAX_FRAGMENT_INPUT_COMPONENTS = 0x9125;

  static const int MAX_FRAGMENT_UNIFORM_BLOCKS = 0x8A2D;

  static const int MAX_FRAGMENT_UNIFORM_COMPONENTS = 0x8B49;

  static const int MAX_FRAGMENT_UNIFORM_VECTORS = 0x8DFD;

  static const int MAX_PROGRAM_TEXEL_OFFSET = 0x8905;

  static const int MAX_RENDERBUFFER_SIZE = 0x84E8;

  static const int MAX_SAMPLES = 0x8D57;

  static const int MAX_SERVER_WAIT_TIMEOUT = 0x9111;

  static const int MAX_TEXTURE_IMAGE_UNITS = 0x8872;

  static const int MAX_TEXTURE_LOD_BIAS = 0x84FD;

  static const int MAX_TEXTURE_SIZE = 0x0D33;

  static const int MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS = 0x8C8A;

  static const int MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS = 0x8C8B;

  static const int MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS = 0x8C80;

  static const int MAX_UNIFORM_BLOCK_SIZE = 0x8A30;

  static const int MAX_UNIFORM_BUFFER_BINDINGS = 0x8A2F;

  static const int MAX_VARYING_COMPONENTS = 0x8B4B;

  static const int MAX_VARYING_VECTORS = 0x8DFC;

  static const int MAX_VERTEX_ATTRIBS = 0x8869;

  static const int MAX_VERTEX_OUTPUT_COMPONENTS = 0x9122;

  static const int MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C;

  static const int MAX_VERTEX_UNIFORM_BLOCKS = 0x8A2B;

  static const int MAX_VERTEX_UNIFORM_COMPONENTS = 0x8B4A;

  static const int MAX_VERTEX_UNIFORM_VECTORS = 0x8DFB;

  static const int MAX_VIEWPORT_DIMS = 0x0D3A;

  static const int MEDIUM_FLOAT = 0x8DF1;

  static const int MEDIUM_INT = 0x8DF4;

  static const int MIN = 0x8007;

  static const int MIN_PROGRAM_TEXEL_OFFSET = 0x8904;

  static const int MIRRORED_REPEAT = 0x8370;

  static const int NEAREST = 0x2600;

  static const int NEAREST_MIPMAP_LINEAR = 0x2702;

  static const int NEAREST_MIPMAP_NEAREST = 0x2700;

  static const int NEVER = 0x0200;

  static const int NICEST = 0x1102;

  static const int NONE = 0;

  static const int NOTEQUAL = 0x0205;

  static const int NO_ERROR = 0;

  static const int OBJECT_TYPE = 0x9112;

  static const int ONE = 1;

  static const int ONE_MINUS_CONSTANT_ALPHA = 0x8004;

  static const int ONE_MINUS_CONSTANT_COLOR = 0x8002;

  static const int ONE_MINUS_DST_ALPHA = 0x0305;

  static const int ONE_MINUS_DST_COLOR = 0x0307;

  static const int ONE_MINUS_SRC_ALPHA = 0x0303;

  static const int ONE_MINUS_SRC_COLOR = 0x0301;

  static const int OUT_OF_MEMORY = 0x0505;

  static const int PACK_ALIGNMENT = 0x0D05;

  static const int PACK_ROW_LENGTH = 0x0D02;

  static const int PACK_SKIP_PIXELS = 0x0D04;

  static const int PACK_SKIP_ROWS = 0x0D03;

  static const int PIXEL_PACK_BUFFER = 0x88EB;

  static const int PIXEL_PACK_BUFFER_BINDING = 0x88ED;

  static const int PIXEL_UNPACK_BUFFER = 0x88EC;

  static const int PIXEL_UNPACK_BUFFER_BINDING = 0x88EF;

  static const int POINTS = 0x0000;

  static const int POLYGON_OFFSET_FACTOR = 0x8038;

  static const int POLYGON_OFFSET_FILL = 0x8037;

  static const int POLYGON_OFFSET_UNITS = 0x2A00;

  static const int QUERY_RESULT = 0x8866;

  static const int QUERY_RESULT_AVAILABLE = 0x8867;

  static const int R11F_G11F_B10F = 0x8C3A;

  static const int R16F = 0x822D;

  static const int R16I = 0x8233;

  static const int R16UI = 0x8234;

  static const int R32F = 0x822E;

  static const int R32I = 0x8235;

  static const int R32UI = 0x8236;

  static const int R8 = 0x8229;

  static const int R8I = 0x8231;

  static const int R8UI = 0x8232;

  static const int R8_SNORM = 0x8F94;

  static const int RASTERIZER_DISCARD = 0x8C89;

  static const int READ_BUFFER = 0x0C02;

  static const int READ_FRAMEBUFFER = 0x8CA8;

  static const int READ_FRAMEBUFFER_BINDING = 0x8CAA;

  static const int RED = 0x1903;

  static const int RED_BITS = 0x0D52;

  static const int RED_INTEGER = 0x8D94;

  static const int RENDERBUFFER = 0x8D41;

  static const int RENDERBUFFER_ALPHA_SIZE = 0x8D53;

  static const int RENDERBUFFER_BINDING = 0x8CA7;

  static const int RENDERBUFFER_BLUE_SIZE = 0x8D52;

  static const int RENDERBUFFER_DEPTH_SIZE = 0x8D54;

  static const int RENDERBUFFER_GREEN_SIZE = 0x8D51;

  static const int RENDERBUFFER_HEIGHT = 0x8D43;

  static const int RENDERBUFFER_INTERNAL_FORMAT = 0x8D44;

  static const int RENDERBUFFER_RED_SIZE = 0x8D50;

  static const int RENDERBUFFER_SAMPLES = 0x8CAB;

  static const int RENDERBUFFER_STENCIL_SIZE = 0x8D55;

  static const int RENDERBUFFER_WIDTH = 0x8D42;

  static const int RENDERER = 0x1F01;

  static const int REPEAT = 0x2901;

  static const int REPLACE = 0x1E01;

  static const int RG = 0x8227;

  static const int RG16F = 0x822F;

  static const int RG16I = 0x8239;

  static const int RG16UI = 0x823A;

  static const int RG32F = 0x8230;

  static const int RG32I = 0x823B;

  static const int RG32UI = 0x823C;

  static const int RG8 = 0x822B;

  static const int RG8I = 0x8237;

  static const int RG8UI = 0x8238;

  static const int RG8_SNORM = 0x8F95;

  static const int RGB = 0x1907;

  static const int RGB10_A2 = 0x8059;

  static const int RGB10_A2UI = 0x906F;

  static const int RGB16F = 0x881B;

  static const int RGB16I = 0x8D89;

  static const int RGB16UI = 0x8D77;

  static const int RGB32F = 0x8815;

  static const int RGB32I = 0x8D83;

  static const int RGB32UI = 0x8D71;

  static const int RGB565 = 0x8D62;

  static const int RGB5_A1 = 0x8057;

  static const int RGB8 = 0x8051;

  static const int RGB8I = 0x8D8F;

  static const int RGB8UI = 0x8D7D;

  static const int RGB8_SNORM = 0x8F96;

  static const int RGB9_E5 = 0x8C3D;

  static const int RGBA = 0x1908;

  static const int RGBA16F = 0x881A;

  static const int RGBA16I = 0x8D88;

  static const int RGBA16UI = 0x8D76;

  static const int RGBA32F = 0x8814;

  static const int RGBA32I = 0x8D82;

  static const int RGBA32UI = 0x8D70;

  static const int RGBA4 = 0x8056;

  static const int RGBA8 = 0x8058;

  static const int RGBA8I = 0x8D8E;

  static const int RGBA8UI = 0x8D7C;

  static const int RGBA8_SNORM = 0x8F97;

  static const int RGBA_INTEGER = 0x8D99;

  static const int RGB_INTEGER = 0x8D98;

  static const int RG_INTEGER = 0x8228;

  static const int SAMPLER_2D = 0x8B5E;

  static const int SAMPLER_2D_ARRAY = 0x8DC1;

  static const int SAMPLER_2D_ARRAY_SHADOW = 0x8DC4;

  static const int SAMPLER_2D_SHADOW = 0x8B62;

  static const int SAMPLER_3D = 0x8B5F;

  static const int SAMPLER_BINDING = 0x8919;

  static const int SAMPLER_CUBE = 0x8B60;

  static const int SAMPLER_CUBE_SHADOW = 0x8DC5;

  static const int SAMPLES = 0x80A9;

  static const int SAMPLE_ALPHA_TO_COVERAGE = 0x809E;

  static const int SAMPLE_BUFFERS = 0x80A8;

  static const int SAMPLE_COVERAGE = 0x80A0;

  static const int SAMPLE_COVERAGE_INVERT = 0x80AB;

  static const int SAMPLE_COVERAGE_VALUE = 0x80AA;

  static const int SCISSOR_BOX = 0x0C10;

  static const int SCISSOR_TEST = 0x0C11;

  static const int SEPARATE_ATTRIBS = 0x8C8D;

  static const int SHADER_TYPE = 0x8B4F;

  static const int SHADING_LANGUAGE_VERSION = 0x8B8C;

  static const int SHORT = 0x1402;

  static const int SIGNALED = 0x9119;

  static const int SIGNED_NORMALIZED = 0x8F9C;

  static const int SRC_ALPHA = 0x0302;

  static const int SRC_ALPHA_SATURATE = 0x0308;

  static const int SRC_COLOR = 0x0300;

  static const int SRGB = 0x8C40;

  static const int SRGB8 = 0x8C41;

  static const int SRGB8_ALPHA8 = 0x8C43;

  static const int STATIC_COPY = 0x88E6;

  static const int STATIC_DRAW = 0x88E4;

  static const int STATIC_READ = 0x88E5;

  static const int STENCIL = 0x1802;

  static const int STENCIL_ATTACHMENT = 0x8D20;

  static const int STENCIL_BACK_FAIL = 0x8801;

  static const int STENCIL_BACK_FUNC = 0x8800;

  static const int STENCIL_BACK_PASS_DEPTH_FAIL = 0x8802;

  static const int STENCIL_BACK_PASS_DEPTH_PASS = 0x8803;

  static const int STENCIL_BACK_REF = 0x8CA3;

  static const int STENCIL_BACK_VALUE_MASK = 0x8CA4;

  static const int STENCIL_BACK_WRITEMASK = 0x8CA5;

  static const int STENCIL_BITS = 0x0D57;

  static const int STENCIL_BUFFER_BIT = 0x00000400;

  static const int STENCIL_CLEAR_VALUE = 0x0B91;

  static const int STENCIL_FAIL = 0x0B94;

  static const int STENCIL_FUNC = 0x0B92;

  static const int STENCIL_INDEX8 = 0x8D48;

  static const int STENCIL_PASS_DEPTH_FAIL = 0x0B95;

  static const int STENCIL_PASS_DEPTH_PASS = 0x0B96;

  static const int STENCIL_REF = 0x0B97;

  static const int STENCIL_TEST = 0x0B90;

  static const int STENCIL_VALUE_MASK = 0x0B93;

  static const int STENCIL_WRITEMASK = 0x0B98;

  static const int STREAM_COPY = 0x88E2;

  static const int STREAM_DRAW = 0x88E0;

  static const int STREAM_READ = 0x88E1;

  static const int SUBPIXEL_BITS = 0x0D50;

  static const int SYNC_CONDITION = 0x9113;

  static const int SYNC_FENCE = 0x9116;

  static const int SYNC_FLAGS = 0x9115;

  static const int SYNC_FLUSH_COMMANDS_BIT = 0x00000001;

  static const int SYNC_GPU_COMMANDS_COMPLETE = 0x9117;

  static const int SYNC_STATUS = 0x9114;

  static const int TEXTURE = 0x1702;

  static const int TEXTURE0 = 0x84C0;

  static const int TEXTURE1 = 0x84C1;

  static const int TEXTURE10 = 0x84CA;

  static const int TEXTURE11 = 0x84CB;

  static const int TEXTURE12 = 0x84CC;

  static const int TEXTURE13 = 0x84CD;

  static const int TEXTURE14 = 0x84CE;

  static const int TEXTURE15 = 0x84CF;

  static const int TEXTURE16 = 0x84D0;

  static const int TEXTURE17 = 0x84D1;

  static const int TEXTURE18 = 0x84D2;

  static const int TEXTURE19 = 0x84D3;

  static const int TEXTURE2 = 0x84C2;

  static const int TEXTURE20 = 0x84D4;

  static const int TEXTURE21 = 0x84D5;

  static const int TEXTURE22 = 0x84D6;

  static const int TEXTURE23 = 0x84D7;

  static const int TEXTURE24 = 0x84D8;

  static const int TEXTURE25 = 0x84D9;

  static const int TEXTURE26 = 0x84DA;

  static const int TEXTURE27 = 0x84DB;

  static const int TEXTURE28 = 0x84DC;

  static const int TEXTURE29 = 0x84DD;

  static const int TEXTURE3 = 0x84C3;

  static const int TEXTURE30 = 0x84DE;

  static const int TEXTURE31 = 0x84DF;

  static const int TEXTURE4 = 0x84C4;

  static const int TEXTURE5 = 0x84C5;

  static const int TEXTURE6 = 0x84C6;

  static const int TEXTURE7 = 0x84C7;

  static const int TEXTURE8 = 0x84C8;

  static const int TEXTURE9 = 0x84C9;

  static const int TEXTURE_2D = 0x0DE1;

  static const int TEXTURE_2D_ARRAY = 0x8C1A;

  static const int TEXTURE_3D = 0x806F;

  static const int TEXTURE_BASE_LEVEL = 0x813C;

  static const int TEXTURE_BINDING_2D = 0x8069;

  static const int TEXTURE_BINDING_2D_ARRAY = 0x8C1D;

  static const int TEXTURE_BINDING_3D = 0x806A;

  static const int TEXTURE_BINDING_CUBE_MAP = 0x8514;

  static const int TEXTURE_COMPARE_FUNC = 0x884D;

  static const int TEXTURE_COMPARE_MODE = 0x884C;

  static const int TEXTURE_CUBE_MAP = 0x8513;

  static const int TEXTURE_CUBE_MAP_NEGATIVE_X = 0x8516;

  static const int TEXTURE_CUBE_MAP_NEGATIVE_Y = 0x8518;

  static const int TEXTURE_CUBE_MAP_NEGATIVE_Z = 0x851A;

  static const int TEXTURE_CUBE_MAP_POSITIVE_X = 0x8515;

  static const int TEXTURE_CUBE_MAP_POSITIVE_Y = 0x8517;

  static const int TEXTURE_CUBE_MAP_POSITIVE_Z = 0x8519;

  static const int TEXTURE_IMMUTABLE_FORMAT = 0x912F;

  static const int TEXTURE_IMMUTABLE_LEVELS = 0x82DF;

  static const int TEXTURE_MAG_FILTER = 0x2800;

  static const int TEXTURE_MAX_LEVEL = 0x813D;

  static const int TEXTURE_MAX_LOD = 0x813B;

  static const int TEXTURE_MIN_FILTER = 0x2801;

  static const int TEXTURE_MIN_LOD = 0x813A;

  static const int TEXTURE_WRAP_R = 0x8072;

  static const int TEXTURE_WRAP_S = 0x2802;

  static const int TEXTURE_WRAP_T = 0x2803;

  static const int TIMEOUT_EXPIRED = 0x911B;

  static const int TIMEOUT_IGNORED = -1;

  static const int TRANSFORM_FEEDBACK = 0x8E22;

  static const int TRANSFORM_FEEDBACK_ACTIVE = 0x8E24;

  static const int TRANSFORM_FEEDBACK_BINDING = 0x8E25;

  static const int TRANSFORM_FEEDBACK_BUFFER = 0x8C8E;

  static const int TRANSFORM_FEEDBACK_BUFFER_BINDING = 0x8C8F;

  static const int TRANSFORM_FEEDBACK_BUFFER_MODE = 0x8C7F;

  static const int TRANSFORM_FEEDBACK_BUFFER_SIZE = 0x8C85;

  static const int TRANSFORM_FEEDBACK_BUFFER_START = 0x8C84;

  static const int TRANSFORM_FEEDBACK_PAUSED = 0x8E23;

  static const int TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN = 0x8C88;

  static const int TRANSFORM_FEEDBACK_VARYINGS = 0x8C83;

  static const int TRIANGLES = 0x0004;

  static const int TRIANGLE_FAN = 0x0006;

  static const int TRIANGLE_STRIP = 0x0005;

  static const int UNIFORM_ARRAY_STRIDE = 0x8A3C;

  static const int UNIFORM_BLOCK_ACTIVE_UNIFORMS = 0x8A42;

  static const int UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES = 0x8A43;

  static const int UNIFORM_BLOCK_BINDING = 0x8A3F;

  static const int UNIFORM_BLOCK_DATA_SIZE = 0x8A40;

  static const int UNIFORM_BLOCK_INDEX = 0x8A3A;

  static const int UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER = 0x8A46;

  static const int UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER = 0x8A44;

  static const int UNIFORM_BUFFER = 0x8A11;

  static const int UNIFORM_BUFFER_BINDING = 0x8A28;

  static const int UNIFORM_BUFFER_OFFSET_ALIGNMENT = 0x8A34;

  static const int UNIFORM_BUFFER_SIZE = 0x8A2A;

  static const int UNIFORM_BUFFER_START = 0x8A29;

  static const int UNIFORM_IS_ROW_MAJOR = 0x8A3E;

  static const int UNIFORM_MATRIX_STRIDE = 0x8A3D;

  static const int UNIFORM_OFFSET = 0x8A3B;

  static const int UNIFORM_SIZE = 0x8A38;

  static const int UNIFORM_TYPE = 0x8A37;

  static const int UNPACK_ALIGNMENT = 0x0CF5;

  static const int UNPACK_COLORSPACE_CONVERSION_WEBGL = 0x9243;

  static const int UNPACK_FLIP_Y_WEBGL = 0x9240;

  static const int UNPACK_IMAGE_HEIGHT = 0x806E;

  static const int UNPACK_PREMULTIPLY_ALPHA_WEBGL = 0x9241;

  static const int UNPACK_ROW_LENGTH = 0x0CF2;

  static const int UNPACK_SKIP_IMAGES = 0x806D;

  static const int UNPACK_SKIP_PIXELS = 0x0CF4;

  static const int UNPACK_SKIP_ROWS = 0x0CF3;

  static const int UNSIGNALED = 0x9118;

  static const int UNSIGNED_BYTE = 0x1401;

  static const int UNSIGNED_INT = 0x1405;

  static const int UNSIGNED_INT_10F_11F_11F_REV = 0x8C3B;

  static const int UNSIGNED_INT_24_8 = 0x84FA;

  static const int UNSIGNED_INT_2_10_10_10_REV = 0x8368;

  static const int UNSIGNED_INT_5_9_9_9_REV = 0x8C3E;

  static const int UNSIGNED_INT_SAMPLER_2D = 0x8DD2;

  static const int UNSIGNED_INT_SAMPLER_2D_ARRAY = 0x8DD7;

  static const int UNSIGNED_INT_SAMPLER_3D = 0x8DD3;

  static const int UNSIGNED_INT_SAMPLER_CUBE = 0x8DD4;

  static const int UNSIGNED_INT_VEC2 = 0x8DC6;

  static const int UNSIGNED_INT_VEC3 = 0x8DC7;

  static const int UNSIGNED_INT_VEC4 = 0x8DC8;

  static const int UNSIGNED_NORMALIZED = 0x8C17;

  static const int UNSIGNED_SHORT = 0x1403;

  static const int UNSIGNED_SHORT_4_4_4_4 = 0x8033;

  static const int UNSIGNED_SHORT_5_5_5_1 = 0x8034;

  static const int UNSIGNED_SHORT_5_6_5 = 0x8363;

  static const int VALIDATE_STATUS = 0x8B83;

  static const int VENDOR = 0x1F00;

  static const int VERSION = 0x1F02;

  static const int VERTEX_ARRAY_BINDING = 0x85B5;

  static const int VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;

  static const int VERTEX_ATTRIB_ARRAY_DIVISOR = 0x88FE;

  static const int VERTEX_ATTRIB_ARRAY_ENABLED = 0x8622;

  static const int VERTEX_ATTRIB_ARRAY_INTEGER = 0x88FD;

  static const int VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A;

  static const int VERTEX_ATTRIB_ARRAY_POINTER = 0x8645;

  static const int VERTEX_ATTRIB_ARRAY_SIZE = 0x8623;

  static const int VERTEX_ATTRIB_ARRAY_STRIDE = 0x8624;

  static const int VERTEX_ATTRIB_ARRAY_TYPE = 0x8625;

  static const int VERTEX_SHADER = 0x8B31;

  static const int VIEWPORT = 0x0BA2;

  static const int WAIT_FAILED = 0x911D;

  static const int ZERO = 0;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Native("WebGL2RenderingContextBase")
abstract class _WebGL2RenderingContextBase extends JavaScriptObject
    implements _WebGLRenderingContextBase {
  // To suppress missing implicit constructor warnings.
  factory _WebGL2RenderingContextBase._() {
    throw new UnsupportedError("Not supported");
  }

  // From WebGLRenderingContextBase
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class _WebGLRenderingContextBase extends JavaScriptObject {
  // To suppress missing implicit constructor warnings.
  factory _WebGLRenderingContextBase._() {
    throw new UnsupportedError("Not supported");
  }
}
