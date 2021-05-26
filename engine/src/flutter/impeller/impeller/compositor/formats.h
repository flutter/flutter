// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <cstdint>
#include <type_traits>

#include "flutter/fml/hash_combine.h"
#include "flutter/fml/macros.h"

namespace impeller {

enum class PixelFormat {
  kUnknown,
};

enum class BlendFactor {
  kZero,
  kOne,
  kSourceColor,
  kOneMinusSourceColor,
  kSourceAlpha,
  kOneMinusSourceAlpha,
  kDestinationColor,
  kOneMinusDestinationColor,
  kDestinationAlpha,
  kOneMinusDestinationAlpha,
  kSourceAlphaSaturated,
  kBlendColor,
  kOneMinusBlendColor,
  kBlendAlpha,
  kOneMinusBlendAlpha,
};

enum class BlendOperation {
  kAdd,
  kSubtract,
  kReverseSubtract,
  kMin,
  kMax,
};

enum class ColorWriteMask : uint64_t {
  kNone = 0,
  kRed = 1 << 0,
  kGreen = 1 << 1,
  kBlue = 1 << 2,
  kAlpha = 1 << 3,
  kAll = kRed | kGreen | kBlue,
};

struct ColorAttachmentDescriptor {
  PixelFormat format = PixelFormat::kUnknown;
  bool blending_enabled = false;

  //----------------------------------------------------------------------------
  /// Blending at specific color attachments follows the pseudocode:
  /// ```
  /// if (blending_enabled) {
  ///   final_color.rgb = (src_color_blend_factor * new_color.rgb)
  ///                             <color_blend_op>
  ///                     (dst_color_blend_factor * old_color.rgb);
  ///   final_color.a = (src_alpha_blend_factor * new_color.a)
  ///                             <alpha_blend_op>
  ///                     (dst_alpha_blend_factor * old_color.a);
  /// } else {
  ///   final_color = new_color;
  /// }
  /// final_color = final_color & write_mask;
  /// ```

  BlendFactor src_color_blend_factor;
  BlendOperation color_blend_op;
  BlendFactor dst_color_blend_factor;

  BlendFactor src_alpha_blend_factor;
  BlendOperation alpha_blend_op;
  BlendFactor dst_alpha_blend_factor;

  std::underlying_type_t<ColorWriteMask> write_mask;

  constexpr bool operator==(const ColorAttachmentDescriptor& o) const {
    return format == o.format &&                                  //
           blending_enabled == o.blending_enabled &&              //
           src_color_blend_factor == o.src_color_blend_factor &&  //
           color_blend_op == o.color_blend_op &&                  //
           dst_color_blend_factor == o.dst_color_blend_factor &&  //
           src_alpha_blend_factor == o.src_alpha_blend_factor &&  //
           alpha_blend_op == o.alpha_blend_op &&                  //
           dst_alpha_blend_factor == o.dst_alpha_blend_factor &&  //
           write_mask == o.write_mask;
  }

  constexpr size_t Hash() const {
    return fml::HashCombine(format, blending_enabled, src_color_blend_factor,
                            color_blend_op, dst_color_blend_factor,
                            src_alpha_blend_factor, alpha_blend_op,
                            dst_alpha_blend_factor, write_mask);
  }
};

}  // namespace impeller
