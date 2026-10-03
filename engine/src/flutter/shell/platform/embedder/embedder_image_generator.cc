// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_image_generator.h"

#include <utility>

namespace flutter {

EmbedderImageGenerator::EmbedderImageGenerator(FlutterImageGenerator generator,
                                               const SkImageInfo& image_info)
    : generator_(generator), image_info_(image_info) {}

EmbedderImageGenerator::~EmbedderImageGenerator() {
  if (generator_.destruction_callback) {
    generator_.destruction_callback(generator_.user_data);
  }
}

const SkImageInfo& EmbedderImageGenerator::GetInfo() {
  return image_info_;
}

unsigned int EmbedderImageGenerator::GetFrameCount() const {
  if (generator_.get_frame_count) {
    return generator_.get_frame_count(generator_.user_data);
  }
  return 1;
}

unsigned int EmbedderImageGenerator::GetPlayCount() const {
  if (generator_.get_play_count) {
    uint32_t play_count = generator_.get_play_count(generator_.user_data);
    if (play_count == 0) {
      return kInfinitePlayCount;
    }
    return play_count;
  }
  return 1;
}

const ImageGenerator::FrameInfo EmbedderImageGenerator::GetFrameInfo(
    unsigned int frame_index) {
  if (generator_.get_frame_info) {
    FlutterImageGeneratorFrameInfo frame_info = {};
    frame_info.struct_size = sizeof(FlutterImageGeneratorFrameInfo);
    if (generator_.get_frame_info(generator_.user_data, frame_index,
                                  &frame_info)) {
      FrameInfo result;
      if (frame_info.required_frame >= 0) {
        result.required_frame =
            static_cast<unsigned int>(frame_info.required_frame);
      } else {
        result.required_frame = std::nullopt;
      }
      result.duration = frame_info.duration_ms;
      switch (frame_info.disposal_method) {
        case kFlutterImageGeneratorDisposalMethodRestoreBackground:
          result.disposal_method =
              SkCodecAnimation::DisposalMethod::kRestoreBGColor;
          break;
        case kFlutterImageGeneratorDisposalMethodRestorePrevious:
          result.disposal_method =
              SkCodecAnimation::DisposalMethod::kRestorePrevious;
          break;
        case kFlutterImageGeneratorDisposalMethodKeep:
        default:
          result.disposal_method = SkCodecAnimation::DisposalMethod::kKeep;
          break;
      }
      if (frame_info.has_disposal_rect) {
        result.disposal_rect = SkIRect::MakeLTRB(
            static_cast<int32_t>(frame_info.disposal_rect.left),
            static_cast<int32_t>(frame_info.disposal_rect.top),
            static_cast<int32_t>(frame_info.disposal_rect.right),
            static_cast<int32_t>(frame_info.disposal_rect.bottom));
      } else {
        result.disposal_rect = std::nullopt;
      }
      switch (frame_info.blend_mode) {
        case kFlutterImageGeneratorBlendModeSrc:
          result.blend_mode = SkCodecAnimation::Blend::kSrc;
          break;
        case kFlutterImageGeneratorBlendModeSrcOver:
        default:
          result.blend_mode = SkCodecAnimation::Blend::kSrcOver;
          break;
      }
      return result;
    }
  }
  return {
      .required_frame = std::nullopt,
      .duration = 0,
      .disposal_method = SkCodecAnimation::DisposalMethod::kKeep,
      .disposal_rect = std::nullopt,
      .blend_mode = SkCodecAnimation::Blend::kSrcOver,
  };
}

SkISize EmbedderImageGenerator::GetScaledDimensions(float desired_scale) {
  if (generator_.get_scaled_dimensions) {
    uint32_t scaled_width = 0;
    uint32_t scaled_height = 0;
    constexpr uint32_t kMaxDimension =
        static_cast<uint32_t>(std::numeric_limits<int32_t>::max());
    if (generator_.get_scaled_dimensions(generator_.user_data, desired_scale,
                                         &scaled_width, &scaled_height) &&
        scaled_width > 0 && scaled_width <= kMaxDimension &&
        scaled_height > 0 && scaled_height <= kMaxDimension) {
      return SkISize::Make(static_cast<int32_t>(scaled_width),
                           static_cast<int32_t>(scaled_height));
    }
  }
  return image_info_.dimensions();
}

bool EmbedderImageGenerator::GetPixels(
    const SkImageInfo& info,
    void* pixels,
    size_t row_bytes,
    unsigned int frame_index,
    std::optional<unsigned int> prior_frame) {
  if (!generator_.get_pixels || !pixels || info.isEmpty() ||
      info.width() <= 0 || info.height() <= 0 ||
      frame_index >= GetFrameCount()) {
    return false;
  }
  FlutterImageGeneratorInfo flutter_info = {};
  flutter_info.struct_size = sizeof(FlutterImageGeneratorInfo);
  flutter_info.width = static_cast<uint32_t>(info.width());
  flutter_info.height = static_cast<uint32_t>(info.height());
  switch (info.colorType()) {
    case kRGBA_8888_SkColorType:
      flutter_info.color_type = kFlutterImageGeneratorColorTypeRGBA8888;
      break;
    case kBGRA_8888_SkColorType:
      flutter_info.color_type = kFlutterImageGeneratorColorTypeBGRA8888;
      break;
    default:
      flutter_info.color_type = kFlutterImageGeneratorColorTypeUnknown;
      break;
  }
  switch (info.alphaType()) {
    case kOpaque_SkAlphaType:
      flutter_info.alpha_type = kFlutterImageGeneratorAlphaTypeOpaque;
      break;
    case kPremul_SkAlphaType:
      flutter_info.alpha_type = kFlutterImageGeneratorAlphaTypePremul;
      break;
    case kUnpremul_SkAlphaType:
      flutter_info.alpha_type = kFlutterImageGeneratorAlphaTypeUnpremul;
      break;
    default:
      flutter_info.alpha_type = kFlutterImageGeneratorAlphaTypeUnknown;
      break;
  }
  int64_t prior =
      prior_frame.has_value() ? static_cast<int64_t>(prior_frame.value()) : -1;
  return generator_.get_pixels(generator_.user_data, &flutter_info, pixels,
                               row_bytes, frame_index, prior);
}

std::shared_ptr<ImageGenerator> MakeEmbedderImageGenerator(
    const FlutterImageGenerator& generator) {
  if (generator.struct_size < sizeof(FlutterImageGenerator) ||
      !generator.get_info || !generator.get_pixels) {
    if (generator.destruction_callback) {
      generator.destruction_callback(generator.user_data);
    }
    return nullptr;
  }

  FlutterImageGeneratorInfo info = {};
  info.struct_size = sizeof(FlutterImageGeneratorInfo);
  if (!generator.get_info(generator.user_data, &info)) {
    if (generator.destruction_callback) {
      generator.destruction_callback(generator.user_data);
    }
    return nullptr;
  }

  constexpr uint32_t kMaxDimension =
      static_cast<uint32_t>(std::numeric_limits<int32_t>::max());
  if (info.width == 0 || info.height == 0 || info.width > kMaxDimension ||
      info.height > kMaxDimension) {
    if (generator.destruction_callback) {
      generator.destruction_callback(generator.user_data);
    }
    return nullptr;
  }

  SkColorType color_type = kRGBA_8888_SkColorType;
  if (info.color_type == kFlutterImageGeneratorColorTypeBGRA8888) {
    color_type = kBGRA_8888_SkColorType;
  }

  SkAlphaType alpha_type = kPremul_SkAlphaType;
  if (info.alpha_type == kFlutterImageGeneratorAlphaTypeOpaque) {
    alpha_type = kOpaque_SkAlphaType;
  } else if (info.alpha_type == kFlutterImageGeneratorAlphaTypeUnpremul) {
    alpha_type = kUnpremul_SkAlphaType;
  }

  SkImageInfo sk_info = SkImageInfo::Make(static_cast<int32_t>(info.width),
                                          static_cast<int32_t>(info.height),
                                          color_type, alpha_type);
  return std::make_shared<EmbedderImageGenerator>(generator, sk_info);
}

ImageGeneratorFactory CreateEmbedderImageGeneratorFactory(
    const FlutterImageGeneratorRegistrationInfo& registration_info) {
  struct SharedFactoryState {
    FlutterImageGeneratorFactoryCallback create_generator = nullptr;
    void* user_data = nullptr;
    VoidCallback destruction_callback = nullptr;

    ~SharedFactoryState() {
      if (destruction_callback) {
        destruction_callback(user_data);
      }
    }
  };

  auto state = std::make_shared<SharedFactoryState>();
  state->create_generator = registration_info.create_generator;
  state->user_data = registration_info.user_data;
  state->destruction_callback = registration_info.destruction_callback;

  return
      [state](const sk_sp<SkData>& buffer) -> std::shared_ptr<ImageGenerator> {
        if (!state->create_generator || !buffer) {
          return nullptr;
        }
        FlutterImageGenerator generator = {};
        generator.struct_size = sizeof(FlutterImageGenerator);
        bool created = state->create_generator(
            static_cast<const uint8_t*>(buffer->data()), buffer->size(),
            state->user_data, &generator);
        if (!created) {
          return nullptr;
        }
        return MakeEmbedderImageGenerator(generator);
      };
}

}  // namespace flutter
