// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';
import 'webidl.dart';

typedef GLenum = int;
typedef GLboolean = bool;
typedef GLbitfield = int;
typedef GLbyte = int;
typedef GLshort = int;
typedef GLint = int;
typedef GLsizei = int;
typedef GLintptr = int;
typedef GLsizeiptr = int;
typedef GLubyte = int;
typedef GLushort = int;
typedef GLuint = int;
typedef GLfloat = num;
typedef GLclampf = num;
typedef TexImageSource = JSObject;
typedef Float32List = JSObject;
typedef Int32List = JSObject;
typedef WebGLPowerPreference = String;

@JS()
@staticInterop
@anonymous
class WebGLContextAttributes {
  external factory WebGLContextAttributes({
    bool alpha,
    bool depth,
    bool stencil,
    bool antialias,
    bool premultipliedAlpha,
    bool preserveDrawingBuffer,
    WebGLPowerPreference powerPreference,
    bool failIfMajorPerformanceCaveat,
    bool desynchronized,
    bool xrCompatible,
  });
}

extension WebGLContextAttributesExtension on WebGLContextAttributes {
  external set alpha(bool value);
  external bool get alpha;
  external set depth(bool value);
  external bool get depth;
  external set stencil(bool value);
  external bool get stencil;
  external set antialias(bool value);
  external bool get antialias;
  external set premultipliedAlpha(bool value);
  external bool get premultipliedAlpha;
  external set preserveDrawingBuffer(bool value);
  external bool get preserveDrawingBuffer;
  external set powerPreference(WebGLPowerPreference value);
  external WebGLPowerPreference get powerPreference;
  external set failIfMajorPerformanceCaveat(bool value);
  external bool get failIfMajorPerformanceCaveat;
  external set desynchronized(bool value);
  external bool get desynchronized;
  external set xrCompatible(bool value);
  external bool get xrCompatible;
}

@JS('WebGLObject')
@staticInterop
class WebGLObject {}

@JS('WebGLBuffer')
@staticInterop
class WebGLBuffer implements WebGLObject {}

@JS('WebGLFramebuffer')
@staticInterop
class WebGLFramebuffer implements WebGLObject {}

@JS('WebGLProgram')
@staticInterop
class WebGLProgram implements WebGLObject {}

@JS('WebGLRenderbuffer')
@staticInterop
class WebGLRenderbuffer implements WebGLObject {}

@JS('WebGLShader')
@staticInterop
class WebGLShader implements WebGLObject {}

@JS('WebGLTexture')
@staticInterop
class WebGLTexture implements WebGLObject {}

@JS('WebGLUniformLocation')
@staticInterop
class WebGLUniformLocation {}

@JS('WebGLActiveInfo')
@staticInterop
class WebGLActiveInfo {}

extension WebGLActiveInfoExtension on WebGLActiveInfo {
  external GLint get size;
  external GLenum get type;
  external String get name;
}

@JS('WebGLShaderPrecisionFormat')
@staticInterop
class WebGLShaderPrecisionFormat {}

extension WebGLShaderPrecisionFormatExtension on WebGLShaderPrecisionFormat {
  external GLint get rangeMin;
  external GLint get rangeMax;
  external GLint get precision;
}

@JS('WebGLRenderingContext')
@staticInterop
class WebGLRenderingContext {
  external static GLenum get DEPTH_BUFFER_BIT;
  external static GLenum get STENCIL_BUFFER_BIT;
  external static GLenum get COLOR_BUFFER_BIT;
  external static GLenum get POINTS;
  external static GLenum get LINES;
  external static GLenum get LINE_LOOP;
  external static GLenum get LINE_STRIP;
  external static GLenum get TRIANGLES;
  external static GLenum get TRIANGLE_STRIP;
  external static GLenum get TRIANGLE_FAN;
  external static GLenum get ZERO;
  external static GLenum get ONE;
  external static GLenum get SRC_COLOR;
  external static GLenum get ONE_MINUS_SRC_COLOR;
  external static GLenum get SRC_ALPHA;
  external static GLenum get ONE_MINUS_SRC_ALPHA;
  external static GLenum get DST_ALPHA;
  external static GLenum get ONE_MINUS_DST_ALPHA;
  external static GLenum get DST_COLOR;
  external static GLenum get ONE_MINUS_DST_COLOR;
  external static GLenum get SRC_ALPHA_SATURATE;
  external static GLenum get FUNC_ADD;
  external static GLenum get BLEND_EQUATION;
  external static GLenum get BLEND_EQUATION_RGB;
  external static GLenum get BLEND_EQUATION_ALPHA;
  external static GLenum get FUNC_SUBTRACT;
  external static GLenum get FUNC_REVERSE_SUBTRACT;
  external static GLenum get BLEND_DST_RGB;
  external static GLenum get BLEND_SRC_RGB;
  external static GLenum get BLEND_DST_ALPHA;
  external static GLenum get BLEND_SRC_ALPHA;
  external static GLenum get CONSTANT_COLOR;
  external static GLenum get ONE_MINUS_CONSTANT_COLOR;
  external static GLenum get CONSTANT_ALPHA;
  external static GLenum get ONE_MINUS_CONSTANT_ALPHA;
  external static GLenum get BLEND_COLOR;
  external static GLenum get ARRAY_BUFFER;
  external static GLenum get ELEMENT_ARRAY_BUFFER;
  external static GLenum get ARRAY_BUFFER_BINDING;
  external static GLenum get ELEMENT_ARRAY_BUFFER_BINDING;
  external static GLenum get STREAM_DRAW;
  external static GLenum get STATIC_DRAW;
  external static GLenum get DYNAMIC_DRAW;
  external static GLenum get BUFFER_SIZE;
  external static GLenum get BUFFER_USAGE;
  external static GLenum get CURRENT_VERTEX_ATTRIB;
  external static GLenum get FRONT;
  external static GLenum get BACK;
  external static GLenum get FRONT_AND_BACK;
  external static GLenum get CULL_FACE;
  external static GLenum get BLEND;
  external static GLenum get DITHER;
  external static GLenum get STENCIL_TEST;
  external static GLenum get DEPTH_TEST;
  external static GLenum get SCISSOR_TEST;
  external static GLenum get POLYGON_OFFSET_FILL;
  external static GLenum get SAMPLE_ALPHA_TO_COVERAGE;
  external static GLenum get SAMPLE_COVERAGE;
  external static GLenum get NO_ERROR;
  external static GLenum get INVALID_ENUM;
  external static GLenum get INVALID_VALUE;
  external static GLenum get INVALID_OPERATION;
  external static GLenum get OUT_OF_MEMORY;
  external static GLenum get CW;
  external static GLenum get CCW;
  external static GLenum get LINE_WIDTH;
  external static GLenum get ALIASED_POINT_SIZE_RANGE;
  external static GLenum get ALIASED_LINE_WIDTH_RANGE;
  external static GLenum get CULL_FACE_MODE;
  external static GLenum get FRONT_FACE;
  external static GLenum get DEPTH_RANGE;
  external static GLenum get DEPTH_WRITEMASK;
  external static GLenum get DEPTH_CLEAR_VALUE;
  external static GLenum get DEPTH_FUNC;
  external static GLenum get STENCIL_CLEAR_VALUE;
  external static GLenum get STENCIL_FUNC;
  external static GLenum get STENCIL_FAIL;
  external static GLenum get STENCIL_PASS_DEPTH_FAIL;
  external static GLenum get STENCIL_PASS_DEPTH_PASS;
  external static GLenum get STENCIL_REF;
  external static GLenum get STENCIL_VALUE_MASK;
  external static GLenum get STENCIL_WRITEMASK;
  external static GLenum get STENCIL_BACK_FUNC;
  external static GLenum get STENCIL_BACK_FAIL;
  external static GLenum get STENCIL_BACK_PASS_DEPTH_FAIL;
  external static GLenum get STENCIL_BACK_PASS_DEPTH_PASS;
  external static GLenum get STENCIL_BACK_REF;
  external static GLenum get STENCIL_BACK_VALUE_MASK;
  external static GLenum get STENCIL_BACK_WRITEMASK;
  external static GLenum get VIEWPORT;
  external static GLenum get SCISSOR_BOX;
  external static GLenum get COLOR_CLEAR_VALUE;
  external static GLenum get COLOR_WRITEMASK;
  external static GLenum get UNPACK_ALIGNMENT;
  external static GLenum get PACK_ALIGNMENT;
  external static GLenum get MAX_TEXTURE_SIZE;
  external static GLenum get MAX_VIEWPORT_DIMS;
  external static GLenum get SUBPIXEL_BITS;
  external static GLenum get RED_BITS;
  external static GLenum get GREEN_BITS;
  external static GLenum get BLUE_BITS;
  external static GLenum get ALPHA_BITS;
  external static GLenum get DEPTH_BITS;
  external static GLenum get STENCIL_BITS;
  external static GLenum get POLYGON_OFFSET_UNITS;
  external static GLenum get POLYGON_OFFSET_FACTOR;
  external static GLenum get TEXTURE_BINDING_2D;
  external static GLenum get SAMPLE_BUFFERS;
  external static GLenum get SAMPLES;
  external static GLenum get SAMPLE_COVERAGE_VALUE;
  external static GLenum get SAMPLE_COVERAGE_INVERT;
  external static GLenum get COMPRESSED_TEXTURE_FORMATS;
  external static GLenum get DONT_CARE;
  external static GLenum get FASTEST;
  external static GLenum get NICEST;
  external static GLenum get GENERATE_MIPMAP_HINT;
  external static GLenum get BYTE;
  external static GLenum get UNSIGNED_BYTE;
  external static GLenum get SHORT;
  external static GLenum get UNSIGNED_SHORT;
  external static GLenum get INT;
  external static GLenum get UNSIGNED_INT;
  external static GLenum get FLOAT;
  external static GLenum get DEPTH_COMPONENT;
  external static GLenum get ALPHA;
  external static GLenum get RGB;
  external static GLenum get RGBA;
  external static GLenum get LUMINANCE;
  external static GLenum get LUMINANCE_ALPHA;
  external static GLenum get UNSIGNED_SHORT_4_4_4_4;
  external static GLenum get UNSIGNED_SHORT_5_5_5_1;
  external static GLenum get UNSIGNED_SHORT_5_6_5;
  external static GLenum get FRAGMENT_SHADER;
  external static GLenum get VERTEX_SHADER;
  external static GLenum get MAX_VERTEX_ATTRIBS;
  external static GLenum get MAX_VERTEX_UNIFORM_VECTORS;
  external static GLenum get MAX_VARYING_VECTORS;
  external static GLenum get MAX_COMBINED_TEXTURE_IMAGE_UNITS;
  external static GLenum get MAX_VERTEX_TEXTURE_IMAGE_UNITS;
  external static GLenum get MAX_TEXTURE_IMAGE_UNITS;
  external static GLenum get MAX_FRAGMENT_UNIFORM_VECTORS;
  external static GLenum get SHADER_TYPE;
  external static GLenum get DELETE_STATUS;
  external static GLenum get LINK_STATUS;
  external static GLenum get VALIDATE_STATUS;
  external static GLenum get ATTACHED_SHADERS;
  external static GLenum get ACTIVE_UNIFORMS;
  external static GLenum get ACTIVE_ATTRIBUTES;
  external static GLenum get SHADING_LANGUAGE_VERSION;
  external static GLenum get CURRENT_PROGRAM;
  external static GLenum get NEVER;
  external static GLenum get LESS;
  external static GLenum get EQUAL;
  external static GLenum get LEQUAL;
  external static GLenum get GREATER;
  external static GLenum get NOTEQUAL;
  external static GLenum get GEQUAL;
  external static GLenum get ALWAYS;
  external static GLenum get KEEP;
  external static GLenum get REPLACE;
  external static GLenum get INCR;
  external static GLenum get DECR;
  external static GLenum get INVERT;
  external static GLenum get INCR_WRAP;
  external static GLenum get DECR_WRAP;
  external static GLenum get VENDOR;
  external static GLenum get RENDERER;
  external static GLenum get VERSION;
  external static GLenum get NEAREST;
  external static GLenum get LINEAR;
  external static GLenum get NEAREST_MIPMAP_NEAREST;
  external static GLenum get LINEAR_MIPMAP_NEAREST;
  external static GLenum get NEAREST_MIPMAP_LINEAR;
  external static GLenum get LINEAR_MIPMAP_LINEAR;
  external static GLenum get TEXTURE_MAG_FILTER;
  external static GLenum get TEXTURE_MIN_FILTER;
  external static GLenum get TEXTURE_WRAP_S;
  external static GLenum get TEXTURE_WRAP_T;
  external static GLenum get TEXTURE_2D;
  external static GLenum get TEXTURE;
  external static GLenum get TEXTURE_CUBE_MAP;
  external static GLenum get TEXTURE_BINDING_CUBE_MAP;
  external static GLenum get TEXTURE_CUBE_MAP_POSITIVE_X;
  external static GLenum get TEXTURE_CUBE_MAP_NEGATIVE_X;
  external static GLenum get TEXTURE_CUBE_MAP_POSITIVE_Y;
  external static GLenum get TEXTURE_CUBE_MAP_NEGATIVE_Y;
  external static GLenum get TEXTURE_CUBE_MAP_POSITIVE_Z;
  external static GLenum get TEXTURE_CUBE_MAP_NEGATIVE_Z;
  external static GLenum get MAX_CUBE_MAP_TEXTURE_SIZE;
  external static GLenum get TEXTURE0;
  external static GLenum get TEXTURE1;
  external static GLenum get TEXTURE2;
  external static GLenum get TEXTURE3;
  external static GLenum get TEXTURE4;
  external static GLenum get TEXTURE5;
  external static GLenum get TEXTURE6;
  external static GLenum get TEXTURE7;
  external static GLenum get TEXTURE8;
  external static GLenum get TEXTURE9;
  external static GLenum get TEXTURE10;
  external static GLenum get TEXTURE11;
  external static GLenum get TEXTURE12;
  external static GLenum get TEXTURE13;
  external static GLenum get TEXTURE14;
  external static GLenum get TEXTURE15;
  external static GLenum get TEXTURE16;
  external static GLenum get TEXTURE17;
  external static GLenum get TEXTURE18;
  external static GLenum get TEXTURE19;
  external static GLenum get TEXTURE20;
  external static GLenum get TEXTURE21;
  external static GLenum get TEXTURE22;
  external static GLenum get TEXTURE23;
  external static GLenum get TEXTURE24;
  external static GLenum get TEXTURE25;
  external static GLenum get TEXTURE26;
  external static GLenum get TEXTURE27;
  external static GLenum get TEXTURE28;
  external static GLenum get TEXTURE29;
  external static GLenum get TEXTURE30;
  external static GLenum get TEXTURE31;
  external static GLenum get ACTIVE_TEXTURE;
  external static GLenum get REPEAT;
  external static GLenum get CLAMP_TO_EDGE;
  external static GLenum get MIRRORED_REPEAT;
  external static GLenum get FLOAT_VEC2;
  external static GLenum get FLOAT_VEC3;
  external static GLenum get FLOAT_VEC4;
  external static GLenum get INT_VEC2;
  external static GLenum get INT_VEC3;
  external static GLenum get INT_VEC4;
  external static GLenum get BOOL;
  external static GLenum get BOOL_VEC2;
  external static GLenum get BOOL_VEC3;
  external static GLenum get BOOL_VEC4;
  external static GLenum get FLOAT_MAT2;
  external static GLenum get FLOAT_MAT3;
  external static GLenum get FLOAT_MAT4;
  external static GLenum get SAMPLER_2D;
  external static GLenum get SAMPLER_CUBE;
  external static GLenum get VERTEX_ATTRIB_ARRAY_ENABLED;
  external static GLenum get VERTEX_ATTRIB_ARRAY_SIZE;
  external static GLenum get VERTEX_ATTRIB_ARRAY_STRIDE;
  external static GLenum get VERTEX_ATTRIB_ARRAY_TYPE;
  external static GLenum get VERTEX_ATTRIB_ARRAY_NORMALIZED;
  external static GLenum get VERTEX_ATTRIB_ARRAY_POINTER;
  external static GLenum get VERTEX_ATTRIB_ARRAY_BUFFER_BINDING;
  external static GLenum get IMPLEMENTATION_COLOR_READ_TYPE;
  external static GLenum get IMPLEMENTATION_COLOR_READ_FORMAT;
  external static GLenum get COMPILE_STATUS;
  external static GLenum get LOW_FLOAT;
  external static GLenum get MEDIUM_FLOAT;
  external static GLenum get HIGH_FLOAT;
  external static GLenum get LOW_INT;
  external static GLenum get MEDIUM_INT;
  external static GLenum get HIGH_INT;
  external static GLenum get FRAMEBUFFER;
  external static GLenum get RENDERBUFFER;
  external static GLenum get RGBA4;
  external static GLenum get RGB5_A1;
  external static GLenum get RGB565;
  external static GLenum get DEPTH_COMPONENT16;
  external static GLenum get STENCIL_INDEX8;
  external static GLenum get DEPTH_STENCIL;
  external static GLenum get RENDERBUFFER_WIDTH;
  external static GLenum get RENDERBUFFER_HEIGHT;
  external static GLenum get RENDERBUFFER_INTERNAL_FORMAT;
  external static GLenum get RENDERBUFFER_RED_SIZE;
  external static GLenum get RENDERBUFFER_GREEN_SIZE;
  external static GLenum get RENDERBUFFER_BLUE_SIZE;
  external static GLenum get RENDERBUFFER_ALPHA_SIZE;
  external static GLenum get RENDERBUFFER_DEPTH_SIZE;
  external static GLenum get RENDERBUFFER_STENCIL_SIZE;
  external static GLenum get FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE;
  external static GLenum get FRAMEBUFFER_ATTACHMENT_OBJECT_NAME;
  external static GLenum get FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL;
  external static GLenum get FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE;
  external static GLenum get COLOR_ATTACHMENT0;
  external static GLenum get DEPTH_ATTACHMENT;
  external static GLenum get STENCIL_ATTACHMENT;
  external static GLenum get DEPTH_STENCIL_ATTACHMENT;
  external static GLenum get NONE;
  external static GLenum get FRAMEBUFFER_COMPLETE;
  external static GLenum get FRAMEBUFFER_INCOMPLETE_ATTACHMENT;
  external static GLenum get FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT;
  external static GLenum get FRAMEBUFFER_INCOMPLETE_DIMENSIONS;
  external static GLenum get FRAMEBUFFER_UNSUPPORTED;
  external static GLenum get FRAMEBUFFER_BINDING;
  external static GLenum get RENDERBUFFER_BINDING;
  external static GLenum get MAX_RENDERBUFFER_SIZE;
  external static GLenum get INVALID_FRAMEBUFFER_OPERATION;
  external static GLenum get UNPACK_FLIP_Y_WEBGL;
  external static GLenum get UNPACK_PREMULTIPLY_ALPHA_WEBGL;
  external static GLenum get CONTEXT_LOST_WEBGL;
  external static GLenum get UNPACK_COLORSPACE_CONVERSION_WEBGL;
  external static GLenum get BROWSER_DEFAULT_WEBGL;
}

extension WebGLRenderingContextExtension on WebGLRenderingContext {
  external WebGLContextAttributes? getContextAttributes();
  external bool isContextLost();
  external JSArray? getSupportedExtensions();
  external JSObject? getExtension(String name);
  external void activeTexture(GLenum texture);
  external void attachShader(
    WebGLProgram program,
    WebGLShader shader,
  );
  external void bindAttribLocation(
    WebGLProgram program,
    GLuint index,
    String name,
  );
  external void bindBuffer(
    GLenum target,
    WebGLBuffer? buffer,
  );
  external void bindFramebuffer(
    GLenum target,
    WebGLFramebuffer? framebuffer,
  );
  external void bindRenderbuffer(
    GLenum target,
    WebGLRenderbuffer? renderbuffer,
  );
  external void bindTexture(
    GLenum target,
    WebGLTexture? texture,
  );
  external void blendColor(
    GLclampf red,
    GLclampf green,
    GLclampf blue,
    GLclampf alpha,
  );
  external void blendEquation(GLenum mode);
  external void blendEquationSeparate(
    GLenum modeRGB,
    GLenum modeAlpha,
  );
  external void blendFunc(
    GLenum sfactor,
    GLenum dfactor,
  );
  external void blendFuncSeparate(
    GLenum srcRGB,
    GLenum dstRGB,
    GLenum srcAlpha,
    GLenum dstAlpha,
  );
  external GLenum checkFramebufferStatus(GLenum target);
  external void clear(GLbitfield mask);
  external void clearColor(
    GLclampf red,
    GLclampf green,
    GLclampf blue,
    GLclampf alpha,
  );
  external void clearDepth(GLclampf depth);
  external void clearStencil(GLint s);
  external void colorMask(
    GLboolean red,
    GLboolean green,
    GLboolean blue,
    GLboolean alpha,
  );
  external void compileShader(WebGLShader shader);
  external void copyTexImage2D(
    GLenum target,
    GLint level,
    GLenum internalformat,
    GLint x,
    GLint y,
    GLsizei width,
    GLsizei height,
    GLint border,
  );
  external void copyTexSubImage2D(
    GLenum target,
    GLint level,
    GLint xoffset,
    GLint yoffset,
    GLint x,
    GLint y,
    GLsizei width,
    GLsizei height,
  );
  external WebGLBuffer? createBuffer();
  external WebGLFramebuffer? createFramebuffer();
  external WebGLProgram? createProgram();
  external WebGLRenderbuffer? createRenderbuffer();
  external WebGLShader? createShader(GLenum type);
  external WebGLTexture? createTexture();
  external void cullFace(GLenum mode);
  external void deleteBuffer(WebGLBuffer? buffer);
  external void deleteFramebuffer(WebGLFramebuffer? framebuffer);
  external void deleteProgram(WebGLProgram? program);
  external void deleteRenderbuffer(WebGLRenderbuffer? renderbuffer);
  external void deleteShader(WebGLShader? shader);
  external void deleteTexture(WebGLTexture? texture);
  external void depthFunc(GLenum func);
  external void depthMask(GLboolean flag);
  external void depthRange(
    GLclampf zNear,
    GLclampf zFar,
  );
  external void detachShader(
    WebGLProgram program,
    WebGLShader shader,
  );
  external void disable(GLenum cap);
  external void disableVertexAttribArray(GLuint index);
  external void drawArrays(
    GLenum mode,
    GLint first,
    GLsizei count,
  );
  external void drawElements(
    GLenum mode,
    GLsizei count,
    GLenum type,
    GLintptr offset,
  );
  external void enable(GLenum cap);
  external void enableVertexAttribArray(GLuint index);
  external void finish();
  external void flush();
  external void framebufferRenderbuffer(
    GLenum target,
    GLenum attachment,
    GLenum renderbuffertarget,
    WebGLRenderbuffer? renderbuffer,
  );
  external void framebufferTexture2D(
    GLenum target,
    GLenum attachment,
    GLenum textarget,
    WebGLTexture? texture,
    GLint level,
  );
  external void frontFace(GLenum mode);
  external void generateMipmap(GLenum target);
  external WebGLActiveInfo? getActiveAttrib(
    WebGLProgram program,
    GLuint index,
  );
  external WebGLActiveInfo? getActiveUniform(
    WebGLProgram program,
    GLuint index,
  );
  external JSArray? getAttachedShaders(WebGLProgram program);
  external GLint getAttribLocation(
    WebGLProgram program,
    String name,
  );
  external JSAny? getBufferParameter(
    GLenum target,
    GLenum pname,
  );
  external JSAny? getParameter(GLenum pname);
  external GLenum getError();
  external JSAny? getFramebufferAttachmentParameter(
    GLenum target,
    GLenum attachment,
    GLenum pname,
  );
  external JSAny? getProgramParameter(
    WebGLProgram program,
    GLenum pname,
  );
  external String? getProgramInfoLog(WebGLProgram program);
  external JSAny? getRenderbufferParameter(
    GLenum target,
    GLenum pname,
  );
  external JSAny? getShaderParameter(
    WebGLShader shader,
    GLenum pname,
  );
  external WebGLShaderPrecisionFormat? getShaderPrecisionFormat(
    GLenum shadertype,
    GLenum precisiontype,
  );
  external String? getShaderInfoLog(WebGLShader shader);
  external String? getShaderSource(WebGLShader shader);
  external JSAny? getTexParameter(
    GLenum target,
    GLenum pname,
  );
  external JSAny? getUniform(
    WebGLProgram program,
    WebGLUniformLocation location,
  );
  external WebGLUniformLocation? getUniformLocation(
    WebGLProgram program,
    String name,
  );
  external JSAny? getVertexAttrib(
    GLuint index,
    GLenum pname,
  );
  external GLintptr getVertexAttribOffset(
    GLuint index,
    GLenum pname,
  );
  external void hint(
    GLenum target,
    GLenum mode,
  );
  external GLboolean isBuffer(WebGLBuffer? buffer);
  external GLboolean isEnabled(GLenum cap);
  external GLboolean isFramebuffer(WebGLFramebuffer? framebuffer);
  external GLboolean isProgram(WebGLProgram? program);
  external GLboolean isRenderbuffer(WebGLRenderbuffer? renderbuffer);
  external GLboolean isShader(WebGLShader? shader);
  external GLboolean isTexture(WebGLTexture? texture);
  external void lineWidth(GLfloat width);
  external void linkProgram(WebGLProgram program);
  external void pixelStorei(
    GLenum pname,
    GLint param,
  );
  external void polygonOffset(
    GLfloat factor,
    GLfloat units,
  );
  external void renderbufferStorage(
    GLenum target,
    GLenum internalformat,
    GLsizei width,
    GLsizei height,
  );
  external void sampleCoverage(
    GLclampf value,
    GLboolean invert,
  );
  external void scissor(
    GLint x,
    GLint y,
    GLsizei width,
    GLsizei height,
  );
  external void shaderSource(
    WebGLShader shader,
    String source,
  );
  external void stencilFunc(
    GLenum func,
    GLint ref,
    GLuint mask,
  );
  external void stencilFuncSeparate(
    GLenum face,
    GLenum func,
    GLint ref,
    GLuint mask,
  );
  external void stencilMask(GLuint mask);
  external void stencilMaskSeparate(
    GLenum face,
    GLuint mask,
  );
  external void stencilOp(
    GLenum fail,
    GLenum zfail,
    GLenum zpass,
  );
  external void stencilOpSeparate(
    GLenum face,
    GLenum fail,
    GLenum zfail,
    GLenum zpass,
  );
  external void texParameterf(
    GLenum target,
    GLenum pname,
    GLfloat param,
  );
  external void texParameteri(
    GLenum target,
    GLenum pname,
    GLint param,
  );
  external void uniform1f(
    WebGLUniformLocation? location,
    GLfloat x,
  );
  external void uniform2f(
    WebGLUniformLocation? location,
    GLfloat x,
    GLfloat y,
  );
  external void uniform3f(
    WebGLUniformLocation? location,
    GLfloat x,
    GLfloat y,
    GLfloat z,
  );
  external void uniform4f(
    WebGLUniformLocation? location,
    GLfloat x,
    GLfloat y,
    GLfloat z,
    GLfloat w,
  );
  external void uniform1i(
    WebGLUniformLocation? location,
    GLint x,
  );
  external void uniform2i(
    WebGLUniformLocation? location,
    GLint x,
    GLint y,
  );
  external void uniform3i(
    WebGLUniformLocation? location,
    GLint x,
    GLint y,
    GLint z,
  );
  external void uniform4i(
    WebGLUniformLocation? location,
    GLint x,
    GLint y,
    GLint z,
    GLint w,
  );
  external void useProgram(WebGLProgram? program);
  external void validateProgram(WebGLProgram program);
  external void vertexAttrib1f(
    GLuint index,
    GLfloat x,
  );
  external void vertexAttrib2f(
    GLuint index,
    GLfloat x,
    GLfloat y,
  );
  external void vertexAttrib3f(
    GLuint index,
    GLfloat x,
    GLfloat y,
    GLfloat z,
  );
  external void vertexAttrib4f(
    GLuint index,
    GLfloat x,
    GLfloat y,
    GLfloat z,
    GLfloat w,
  );
  external void vertexAttrib1fv(
    GLuint index,
    Float32List values,
  );
  external void vertexAttrib2fv(
    GLuint index,
    Float32List values,
  );
  external void vertexAttrib3fv(
    GLuint index,
    Float32List values,
  );
  external void vertexAttrib4fv(
    GLuint index,
    Float32List values,
  );
  external void vertexAttribPointer(
    GLuint index,
    GLint size,
    GLenum type,
    GLboolean normalized,
    GLsizei stride,
    GLintptr offset,
  );
  external void viewport(
    GLint x,
    GLint y,
    GLsizei width,
    GLsizei height,
  );
  external JSPromise makeXRCompatible();
  external void bufferData(
    GLenum target,
    JSAny dataOrSize,
    GLenum usage,
  );
  external void bufferSubData(
    GLenum target,
    GLintptr offset,
    AllowSharedBufferSource data,
  );
  external void compressedTexImage2D(
    GLenum target,
    GLint level,
    GLenum internalformat,
    GLsizei width,
    GLsizei height,
    GLint border,
    ArrayBufferView data,
  );
  external void compressedTexSubImage2D(
    GLenum target,
    GLint level,
    GLint xoffset,
    GLint yoffset,
    GLsizei width,
    GLsizei height,
    GLenum format,
    ArrayBufferView data,
  );
  external void readPixels(
    GLint x,
    GLint y,
    GLsizei width,
    GLsizei height,
    GLenum format,
    GLenum type,
    ArrayBufferView? pixels,
  );
  external void texImage2D(
    GLenum target,
    GLint level,
    GLint internalformat,
    JSAny formatOrWidth,
    JSAny heightOrType,
    JSAny borderOrSource, [
    GLenum format,
    GLenum type,
    ArrayBufferView? pixels,
  ]);
  external void texSubImage2D(
    GLenum target,
    GLint level,
    GLint xoffset,
    GLint yoffset,
    JSAny formatOrWidth,
    JSAny heightOrType,
    JSAny formatOrSource, [
    GLenum type,
    ArrayBufferView? pixels,
  ]);
  external void uniform1fv(
    WebGLUniformLocation? location,
    Float32List v,
  );
  external void uniform2fv(
    WebGLUniformLocation? location,
    Float32List v,
  );
  external void uniform3fv(
    WebGLUniformLocation? location,
    Float32List v,
  );
  external void uniform4fv(
    WebGLUniformLocation? location,
    Float32List v,
  );
  external void uniform1iv(
    WebGLUniformLocation? location,
    Int32List v,
  );
  external void uniform2iv(
    WebGLUniformLocation? location,
    Int32List v,
  );
  external void uniform3iv(
    WebGLUniformLocation? location,
    Int32List v,
  );
  external void uniform4iv(
    WebGLUniformLocation? location,
    Int32List v,
  );
  external void uniformMatrix2fv(
    WebGLUniformLocation? location,
    GLboolean transpose,
    Float32List value,
  );
  external void uniformMatrix3fv(
    WebGLUniformLocation? location,
    GLboolean transpose,
    Float32List value,
  );
  external void uniformMatrix4fv(
    WebGLUniformLocation? location,
    GLboolean transpose,
    Float32List value,
  );
  external JSObject get canvas;
  external GLsizei get drawingBufferWidth;
  external GLsizei get drawingBufferHeight;
  external set drawingBufferColorSpace(PredefinedColorSpace value);
  external PredefinedColorSpace get drawingBufferColorSpace;
  external set unpackColorSpace(PredefinedColorSpace value);
  external PredefinedColorSpace get unpackColorSpace;
}

@JS('WebGLContextEvent')
@staticInterop
class WebGLContextEvent implements Event {
  external factory WebGLContextEvent(
    String type, [
    WebGLContextEventInit eventInit,
  ]);
}

extension WebGLContextEventExtension on WebGLContextEvent {
  external String get statusMessage;
}

@JS()
@staticInterop
@anonymous
class WebGLContextEventInit implements EventInit {
  external factory WebGLContextEventInit({String statusMessage});
}

extension WebGLContextEventInitExtension on WebGLContextEventInit {
  external set statusMessage(String value);
  external String get statusMessage;
}
