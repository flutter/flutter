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

/// Which of the vertex attribute formats beyond the GLES 2.0 floor the current
/// context can consume. Computed once by `CapabilitiesGLES` and consulted when
/// translating a `VertexAttributeFormat`.
struct VertexFormatSupportGLES {
  /// The GL type to bind half-float attributes with, or `GL_NONE` when they
  /// are unavailable. Core GLES 3.0 spells this `GL_HALF_FLOAT`; the GLES 2.0
  /// extension spells the same layout `GL_HALF_FLOAT_OES`.
  GLenum half_float_type = GL_NONE;

  /// Whether `glVertexAttribIPointer` is available, which every integer-typed
  /// vertex input needs. GLES 3.0 only, since GLSL ES 1.00 has no integer
  /// vertex inputs.
  bool integer = false;

  /// Whether `GL_UNSIGNED_INT_2_10_10_10_REV` is accepted as a vertex type.
  bool packed_2_10_10_10 = false;

  /// Whether `GL_BGRA_EXT` is accepted as a vertex attribute size, which is
  /// how blue/green/red/alpha byte ordering is expressed.
  bool bgra = false;
};

/// How a vertex attribute is described to `glVertexAttribPointer` or, when
/// `integer` is set, to `glVertexAttribIPointer`.
struct VertexAttribGLES {
  /// The component count, or `GL_BGRA_EXT` for the swizzled byte format.
  GLint size = 0;
  GLenum type = GL_NONE;
  GLboolean normalized = GL_FALSE;
  bool integer = false;
};

/// Returns how to bind a vertex attribute of the given format, or
/// `std::nullopt` when the current context cannot consume it.
constexpr std::optional<VertexAttribGLES> ToVertexAttribGLES(
    VertexAttributeFormat format,
    const VertexFormatSupportGLES& support) {
  auto floating = [](GLint size, GLenum type) {
    return VertexAttribGLES{.size = size, .type = type};
  };
  auto normalized = [](GLint size, GLenum type) {
    return VertexAttribGLES{.size = size, .type = type, .normalized = GL_TRUE};
  };
  auto integer = [&support](GLint size,
                            GLenum type) -> std::optional<VertexAttribGLES> {
    if (!support.integer) {
      return std::nullopt;
    }
    return VertexAttribGLES{.size = size, .type = type, .integer = true};
  };
  auto half = [&support](GLint size) -> std::optional<VertexAttribGLES> {
    if (support.half_float_type == GL_NONE) {
      return std::nullopt;
    }
    return VertexAttribGLES{.size = size, .type = support.half_float_type};
  };

  switch (format) {
    case VertexAttributeFormat::kFloat32:
      return floating(1, GL_FLOAT);
    case VertexAttributeFormat::kFloat32x2:
      return floating(2, GL_FLOAT);
    case VertexAttributeFormat::kFloat32x3:
      return floating(3, GL_FLOAT);
    case VertexAttributeFormat::kFloat32x4:
      return floating(4, GL_FLOAT);

    case VertexAttributeFormat::kFloat16:
      return half(1);
    case VertexAttributeFormat::kFloat16x2:
      return half(2);
    case VertexAttributeFormat::kFloat16x3:
      return half(3);
    case VertexAttributeFormat::kFloat16x4:
      return half(4);

    case VertexAttributeFormat::kSInt8:
      return integer(1, GL_BYTE);
    case VertexAttributeFormat::kSInt8x2:
      return integer(2, GL_BYTE);
    case VertexAttributeFormat::kSInt8x3:
      return integer(3, GL_BYTE);
    case VertexAttributeFormat::kSInt8x4:
      return integer(4, GL_BYTE);

    case VertexAttributeFormat::kUInt8:
      return integer(1, GL_UNSIGNED_BYTE);
    case VertexAttributeFormat::kUInt8x2:
      return integer(2, GL_UNSIGNED_BYTE);
    case VertexAttributeFormat::kUInt8x3:
      return integer(3, GL_UNSIGNED_BYTE);
    case VertexAttributeFormat::kUInt8x4:
      return integer(4, GL_UNSIGNED_BYTE);

    case VertexAttributeFormat::kSNorm8:
      return normalized(1, GL_BYTE);
    case VertexAttributeFormat::kSNorm8x2:
      return normalized(2, GL_BYTE);
    case VertexAttributeFormat::kSNorm8x4:
      return normalized(4, GL_BYTE);

    case VertexAttributeFormat::kUNorm8:
      return normalized(1, GL_UNSIGNED_BYTE);
    case VertexAttributeFormat::kUNorm8x2:
      return normalized(2, GL_UNSIGNED_BYTE);
    case VertexAttributeFormat::kUNorm8x4:
      return normalized(4, GL_UNSIGNED_BYTE);

    case VertexAttributeFormat::kUNorm8x4BGRA:
      if (!support.bgra) {
        return std::nullopt;
      }
      return normalized(GL_BGRA_EXT, GL_UNSIGNED_BYTE);

    case VertexAttributeFormat::kSInt16:
      return integer(1, GL_SHORT);
    case VertexAttributeFormat::kSInt16x2:
      return integer(2, GL_SHORT);
    case VertexAttributeFormat::kSInt16x3:
      return integer(3, GL_SHORT);
    case VertexAttributeFormat::kSInt16x4:
      return integer(4, GL_SHORT);

    case VertexAttributeFormat::kUInt16:
      return integer(1, GL_UNSIGNED_SHORT);
    case VertexAttributeFormat::kUInt16x2:
      return integer(2, GL_UNSIGNED_SHORT);
    case VertexAttributeFormat::kUInt16x3:
      return integer(3, GL_UNSIGNED_SHORT);
    case VertexAttributeFormat::kUInt16x4:
      return integer(4, GL_UNSIGNED_SHORT);

    case VertexAttributeFormat::kSNorm16:
      return normalized(1, GL_SHORT);
    case VertexAttributeFormat::kSNorm16x2:
      return normalized(2, GL_SHORT);
    case VertexAttributeFormat::kSNorm16x4:
      return normalized(4, GL_SHORT);

    case VertexAttributeFormat::kUNorm16:
      return normalized(1, GL_UNSIGNED_SHORT);
    case VertexAttributeFormat::kUNorm16x2:
      return normalized(2, GL_UNSIGNED_SHORT);
    case VertexAttributeFormat::kUNorm16x4:
      return normalized(4, GL_UNSIGNED_SHORT);

    case VertexAttributeFormat::kSInt32:
      return integer(1, GL_INT);
    case VertexAttributeFormat::kSInt32x2:
      return integer(2, GL_INT);
    case VertexAttributeFormat::kSInt32x3:
      return integer(3, GL_INT);
    case VertexAttributeFormat::kSInt32x4:
      return integer(4, GL_INT);

    case VertexAttributeFormat::kUInt32:
      return integer(1, GL_UNSIGNED_INT);
    case VertexAttributeFormat::kUInt32x2:
      return integer(2, GL_UNSIGNED_INT);
    case VertexAttributeFormat::kUInt32x3:
      return integer(3, GL_UNSIGNED_INT);
    case VertexAttributeFormat::kUInt32x4:
      return integer(4, GL_UNSIGNED_INT);

    case VertexAttributeFormat::kUNorm10_10_10_2:
      if (!support.packed_2_10_10_10) {
        return std::nullopt;
      }
      return normalized(4, GL_UNSIGNED_INT_2_10_10_10_REV);

    case VertexAttributeFormat::kInvalid:
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
    case TextureType::kTexture2DArray:
      return GL_TEXTURE_2D_ARRAY;
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
    case TextureType::kTexture2DArray:
      return GL_TEXTURE_2D_ARRAY;
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
