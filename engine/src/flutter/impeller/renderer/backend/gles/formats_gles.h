// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_FORMATS_GLES_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_FORMATS_GLES_H_

#include <optional>

#include "flutter/fml/logging.h"
#include "impeller/core/formats.h"
#include "impeller/core/shader_types.h"
#include "impeller/renderer/backend/gles/gles.h"

namespace impeller {

constexpr GLenum ToMode(PrimitiveType primitive_type) {
  switch (primitive_type) {
    case PrimitiveType::kTriangle:
      return GL_TRIANGLES;
    case PrimitiveType::kTriangleStrip:
      return GL_TRIANGLE_STRIP;
    case PrimitiveType::kLine:
      return GL_LINES;
    case PrimitiveType::kLineStrip:
      return GL_LINE_STRIP;
    case PrimitiveType::kPoint:
      return GL_POINTS;
    case PrimitiveType::kTriangleFan:
      return GL_TRIANGLE_FAN;
  }
  FML_UNREACHABLE();
}

constexpr GLenum ToIndexType(IndexType type) {
  switch (type) {
    case IndexType::kUnknown:
    case IndexType::kNone:
      FML_UNREACHABLE();
    case IndexType::k16bit:
      return GL_UNSIGNED_SHORT;
    case IndexType::k32bit:
      return GL_UNSIGNED_INT;
  }
  FML_UNREACHABLE();
}

constexpr GLenum ToStencilOp(StencilOperation op) {
  switch (op) {
    case StencilOperation::kKeep:
      return GL_KEEP;
    case StencilOperation::kZero:
      return GL_ZERO;
    case StencilOperation::kSetToReferenceValue:
      return GL_REPLACE;
    case StencilOperation::kIncrementClamp:
      return GL_INCR;
    case StencilOperation::kDecrementClamp:
      return GL_DECR;
    case StencilOperation::kInvert:
      return GL_INVERT;
    case StencilOperation::kIncrementWrap:
      return GL_INCR_WRAP;
    case StencilOperation::kDecrementWrap:
      return GL_DECR_WRAP;
  }
  FML_UNREACHABLE();
}

constexpr GLenum ToCompareFunction(CompareFunction func) {
  switch (func) {
    case CompareFunction::kNever:
      return GL_NEVER;
    case CompareFunction::kAlways:
      return GL_ALWAYS;
    case CompareFunction::kLess:
      return GL_LESS;
    case CompareFunction::kEqual:
      return GL_EQUAL;
    case CompareFunction::kLessEqual:
      return GL_LEQUAL;
    case CompareFunction::kGreater:
      return GL_GREATER;
    case CompareFunction::kNotEqual:
      return GL_NOTEQUAL;
    case CompareFunction::kGreaterEqual:
      return GL_GEQUAL;
  }
  FML_UNREACHABLE();
}

constexpr GLenum ToBlendFactor(BlendFactor factor) {
  switch (factor) {
    case BlendFactor::kZero:
      return GL_ZERO;
    case BlendFactor::kOne:
      return GL_ONE;
    case BlendFactor::kSourceColor:
      return GL_SRC_COLOR;
    case BlendFactor::kOneMinusSourceColor:
      return GL_ONE_MINUS_SRC_COLOR;
    case BlendFactor::kSourceAlpha:
      return GL_SRC_ALPHA;
    case BlendFactor::kOneMinusSourceAlpha:
      return GL_ONE_MINUS_SRC_ALPHA;
    case BlendFactor::kDestinationColor:
      return GL_DST_COLOR;
    case BlendFactor::kOneMinusDestinationColor:
      return GL_ONE_MINUS_DST_COLOR;
    case BlendFactor::kDestinationAlpha:
      return GL_DST_ALPHA;
    case BlendFactor::kOneMinusDestinationAlpha:
      return GL_ONE_MINUS_DST_ALPHA;
    case BlendFactor::kSourceAlphaSaturated:
      return GL_SRC_ALPHA_SATURATE;
    case BlendFactor::kBlendColor:
      return GL_CONSTANT_COLOR;
    case BlendFactor::kOneMinusBlendColor:
      return GL_ONE_MINUS_CONSTANT_COLOR;
    case BlendFactor::kBlendAlpha:
      return GL_CONSTANT_ALPHA;
    case BlendFactor::kOneMinusBlendAlpha:
      return GL_ONE_MINUS_CONSTANT_ALPHA;
  }
  FML_UNREACHABLE();
}

constexpr GLenum ToBlendOperation(BlendOperation op) {
  switch (op) {
    case BlendOperation::kAdd:
      return GL_FUNC_ADD;
    case BlendOperation::kSubtract:
      return GL_FUNC_SUBTRACT;
    case BlendOperation::kReverseSubtract:
      return GL_FUNC_REVERSE_SUBTRACT;
  }
  FML_UNREACHABLE();
}

/// Returns the GL scalar type for a vertex attribute, or `std::nullopt` when
/// the format cannot be consumed as a vertex attribute on this backend. The
/// component count is supplied separately to `glVertexAttribPointer`, so only
/// the scalar kind matters here. Half-float and 32-bit integer attributes are
/// not available on the GLES 2.0 floor.
constexpr std::optional<GLenum> ToVertexAttribType(VertexAttributeFormat type) {
  switch (type) {
    case VertexAttributeFormat::kSInt8:
    case VertexAttributeFormat::kSInt8x2:
    case VertexAttributeFormat::kSInt8x3:
    case VertexAttributeFormat::kSInt8x4:
      return GL_BYTE;
    case VertexAttributeFormat::kUInt8:
    case VertexAttributeFormat::kUInt8x2:
    case VertexAttributeFormat::kUInt8x3:
    case VertexAttributeFormat::kUInt8x4:
      return GL_UNSIGNED_BYTE;
    case VertexAttributeFormat::kSInt16:
    case VertexAttributeFormat::kSInt16x2:
    case VertexAttributeFormat::kSInt16x3:
    case VertexAttributeFormat::kSInt16x4:
      return GL_SHORT;
    case VertexAttributeFormat::kUInt16:
    case VertexAttributeFormat::kUInt16x2:
    case VertexAttributeFormat::kUInt16x3:
    case VertexAttributeFormat::kUInt16x4:
      return GL_UNSIGNED_SHORT;
    case VertexAttributeFormat::kFloat32:
    case VertexAttributeFormat::kFloat32x2:
    case VertexAttributeFormat::kFloat32x3:
    case VertexAttributeFormat::kFloat32x4:
      return GL_FLOAT;
    case VertexAttributeFormat::kInvalid:
    case VertexAttributeFormat::kFloat16:
    case VertexAttributeFormat::kFloat16x2:
    case VertexAttributeFormat::kFloat16x3:
    case VertexAttributeFormat::kFloat16x4:
    case VertexAttributeFormat::kSInt32:
    case VertexAttributeFormat::kSInt32x2:
    case VertexAttributeFormat::kSInt32x3:
    case VertexAttributeFormat::kSInt32x4:
    case VertexAttributeFormat::kUInt32:
    case VertexAttributeFormat::kUInt32x2:
    case VertexAttributeFormat::kUInt32x3:
    case VertexAttributeFormat::kUInt32x4:
      return std::nullopt;
  }
  FML_UNREACHABLE();
}

constexpr GLenum ToTextureType(TextureType type) {
  switch (type) {
    case TextureType::kTexture2D:
      return GL_TEXTURE_2D;
    case TextureType::kTexture2DMultisample:
      return GL_TEXTURE_2D_MULTISAMPLE;
    case TextureType::kTextureCube:
      return GL_TEXTURE_CUBE_MAP;
    case TextureType::kTextureExternalOES:
      return GL_TEXTURE_EXTERNAL_OES;
  }
  FML_UNREACHABLE();
}

constexpr std::optional<GLenum> ToTextureTarget(TextureType type) {
  switch (type) {
    case TextureType::kTexture2D:
      return GL_TEXTURE_2D;
    case TextureType::kTexture2DMultisample:
      return GL_TEXTURE_2D;
    case TextureType::kTextureCube:
      return GL_TEXTURE_CUBE_MAP;
    case TextureType::kTextureExternalOES:
      return GL_TEXTURE_EXTERNAL_OES;
  }
  FML_UNREACHABLE();
}

struct PixelFormatGLES {
  GLint internal_format = 0;
  GLenum external_format = GL_NONE;
  GLenum type = GL_NONE;
  // When true, the data must be uploaded with glCompressedTexImage2D and only
  // `internal_format` is meaningful.
  bool is_compressed = false;
};

std::optional<PixelFormatGLES> ToPixelFormatGLES(PixelFormat format,
                                                 bool supports_bgra);

std::string DebugToFramebufferError(int status);

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_FORMATS_GLES_H_
