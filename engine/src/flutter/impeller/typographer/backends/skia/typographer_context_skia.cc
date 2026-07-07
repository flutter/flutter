// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/backends/skia/typographer_context_skia.h"

#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <memory>
#include <numeric>
#include <utility>
#include <vector>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "fml/closure.h"

#include "impeller/base/validation.h"
#include "impeller/core/allocator.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/formats.h"
#include "impeller/core/host_buffer.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/size.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/render_target.h"
#include "impeller/typographer/backends/skia/typeface_skia.h"
#include "impeller/typographer/font_glyph_pair.h"
#include "impeller/typographer/glyph.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/rectangle_packer.h"
#include "impeller/typographer/typographer_context.h"

#include "third_party/abseil-cpp/absl/status/statusor.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkBlendMode.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkFont.h"
#include "third_party/skia/include/core/SkPaint.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace impeller {

constexpr auto kPadding = 2;

namespace {
SkPaint::Cap ToSkiaCap(Cap cap) {
  switch (cap) {
    case Cap::kButt:
      return SkPaint::Cap::kButt_Cap;
    case Cap::kRound:
      return SkPaint::Cap::kRound_Cap;
    case Cap::kSquare:
      return SkPaint::Cap::kSquare_Cap;
  }
  FML_UNREACHABLE();
}

SkPaint::Join ToSkiaJoin(Join join) {
  switch (join) {
    case Join::kMiter:
      return SkPaint::Join::kMiter_Join;
    case Join::kRound:
      return SkPaint::Join::kRound_Join;
    case Join::kBevel:
      return SkPaint::Join::kBevel_Join;
  }
  FML_UNREACHABLE();
}

// Create an A8 bitmap from an color bitmap.
absl::StatusOr<SkBitmap> ToA8Bitmap(const SkBitmap& src) {
  FML_DCHECK(src.colorType() == kRGBA_8888_SkColorType);

  SkBitmap a8_bitmap;
  a8_bitmap.setInfo(SkImageInfo::MakeA8(src.width(), src.height()));
  if (!a8_bitmap.tryAllocPixels()) {
    return absl::Status(absl::StatusCode::kInternal,
                        "Failed to allocate pixels for A8 bitmap");
  }
  if (!src.readPixels(a8_bitmap.pixmap())) {
    return absl::Status(absl::StatusCode::kInternal,
                        "Failed to read pixels into A8 bitmap");
  }
  return a8_bitmap;
}

}  // namespace

std::shared_ptr<TypographerContext> TypographerContextSkia::Make() {
  return std::make_shared<TypographerContextSkia>();
}

TypographerContextSkia::TypographerContextSkia() = default;

TypographerContextSkia::~TypographerContextSkia() = default;

std::shared_ptr<GlyphAtlasContext>
TypographerContextSkia::CreateGlyphAtlasContext(GlyphAtlas::Type type) const {
  return std::make_shared<GlyphAtlasContext>(type);
}

SkImageInfo TypographerContextSkia::GetImageInfo(const GlyphAtlas& atlas,
                                                 Size size,
                                                 bool support_light_glyphs) {
  SkISize skia_size = {static_cast<int32_t>(size.width),
                       static_cast<int32_t>(size.height)};

  switch (atlas.GetType()) {
    case GlyphAtlas::Type::kAlphaBitmap:
      return support_light_glyphs
                 ? SkImageInfo::Make(skia_size, kRGBA_8888_SkColorType,
                                     kPremul_SkAlphaType)
                 : SkImageInfo::MakeA8(skia_size);
    case GlyphAtlas::Type::kColorBitmap:
      return SkImageInfo::Make(skia_size, kRGBA_8888_SkColorType,
                               kPremul_SkAlphaType);
  }
  FML_UNREACHABLE();
}

static size_t AppendToExistingAtlas(
    const std::shared_ptr<GlyphAtlas>& atlas,
    const std::vector<FontGlyphPair>& extra_pairs,
    std::vector<Rect>& glyph_positions,
    const std::vector<Rect>& glyph_sizes,
    ISize atlas_size,
    int64_t height_adjustment,
    const std::shared_ptr<RectanglePacker>& rect_packer) {
  TRACE_EVENT0("impeller", __FUNCTION__);
  if (!rect_packer || atlas_size.IsEmpty()) {
    return 0;
  }

  for (size_t i = 0; i < extra_pairs.size(); i++) {
    ISize glyph_size = ISize::Ceil(glyph_sizes[i].GetSize());
    IPoint16 location_in_atlas;
    if (!rect_packer->AddRect(glyph_size.width + kPadding,
                              glyph_size.height + kPadding,
                              &location_in_atlas)) {
      return i;
    }
    glyph_positions.push_back(
        Rect::MakeXYWH(location_in_atlas.x() + 1,
                       location_in_atlas.y() + height_adjustment + 1,
                       glyph_size.width, glyph_size.height));
  }

  return extra_pairs.size();
}

static size_t PairsFitInAtlasOfSize(
    const std::vector<FontGlyphPair>& pairs,
    const ISize& atlas_size,
    std::vector<Rect>& glyph_positions,
    const std::vector<Rect>& glyph_sizes,
    int64_t height_adjustment,
    const std::shared_ptr<RectanglePacker>& rect_packer,
    size_t start_index) {
  FML_DCHECK(!atlas_size.IsEmpty());

  for (size_t i = start_index; i < pairs.size(); i++) {
    ISize glyph_size = ISize::Ceil(glyph_sizes[i].GetSize());
    IPoint16 location_in_atlas;
    if (!rect_packer->AddRect(glyph_size.width + kPadding,
                              glyph_size.height + kPadding,
                              &location_in_atlas)) {
      return i;
    }
    glyph_positions.push_back(
        Rect::MakeXYWH(location_in_atlas.x() + 1,
                       location_in_atlas.y() + height_adjustment + 1,
                       glyph_size.width, glyph_size.height));
  }

  return pairs.size();
}

static ISize ComputeNextAtlasSize(
    const std::shared_ptr<GlyphAtlasContext>& atlas_context,
    const std::vector<FontGlyphPair>& extra_pairs,
    std::vector<Rect>& glyph_positions,
    const std::vector<Rect>& glyph_sizes,
    size_t glyph_index_start,
    int64_t max_texture_height) {
  static constexpr int64_t kAtlasWidth = 4096;
  static constexpr int64_t kMinAtlasHeight = 1024;

  ISize current_size = ISize(kAtlasWidth, kMinAtlasHeight);
  if (atlas_context->GetAtlasSize().height > current_size.height) {
    current_size.height = atlas_context->GetAtlasSize().height * 2;
  }

  auto height_adjustment = atlas_context->GetAtlasSize().height;
  while (current_size.height <= max_texture_height) {
    std::shared_ptr<RectanglePacker> rect_packer;
    if (atlas_context->GetRectPacker() || glyph_index_start) {
      rect_packer = RectanglePacker::Factory(
          kAtlasWidth,
          current_size.height - atlas_context->GetAtlasSize().height);
    } else {
      rect_packer = RectanglePacker::Factory(kAtlasWidth, current_size.height);
    }
    glyph_positions.erase(glyph_positions.begin() + glyph_index_start,
                          glyph_positions.end());
    atlas_context->UpdateRectPacker(rect_packer);
    auto next_index = PairsFitInAtlasOfSize(
        extra_pairs, current_size, glyph_positions, glyph_sizes,
        height_adjustment, rect_packer, glyph_index_start);
    if (next_index == extra_pairs.size()) {
      return current_size;
    }
    current_size = ISize(current_size.width, current_size.height * 2);
  }
  return {};
}

static Point SubpixelPositionToPoint(SubpixelPosition pos) {
  return Point((pos & 0xff) / 4.f, (pos >> 2 & 0xff) / 4.f);
}

static void DrawGlyph(SkCanvas* canvas,
                      const SkPoint position,
                      const ScaledFont& scaled_font,
                      const SubpixelGlyph& glyph,
                      const Rect& scaled_bounds,
                      const GlyphProperties& prop) {
  const auto& metrics = scaled_font.font.GetMetrics();
  SkGlyphID glyph_id = glyph.glyph.index;

  SkFont sk_font(
      TypefaceSkia::Cast(*scaled_font.font.GetTypeface()).GetSkiaTypeface(),
      metrics.point_size, metrics.scaleX, metrics.skewX);
  sk_font.setEdging(SkFont::Edging::kAntiAlias);
  sk_font.setHinting(SkFontHinting::kSlight);
  sk_font.setEmbolden(metrics.embolden);
  sk_font.setSubpixel(true);
  sk_font.setSize(sk_font.getSize() * static_cast<Scalar>(scaled_font.scale));

  SkColor glyph_color;
  if (prop.tone_or_color == GlyphProperties::kDarkTone) {
    glyph_color = SK_ColorBLACK;
  } else if (prop.tone_or_color == GlyphProperties::kLightTone) {
    glyph_color = SK_ColorWHITE;
  } else {
    FML_DCHECK(std::holds_alternative<Color>(prop.tone_or_color));
    glyph_color = std::get<Color>(prop.tone_or_color).ToARGB();
  }

  SkPaint glyph_paint;
  glyph_paint.setColor(glyph_color);
  glyph_paint.setBlendMode(SkBlendMode::kSrc);
  if (prop.stroke.has_value()) {
    auto stroke = prop.stroke;
    glyph_paint.setStroke(true);
    glyph_paint.setStrokeWidth(stroke->width *
                               static_cast<Scalar>(scaled_font.scale));
    glyph_paint.setStrokeCap(ToSkiaCap(stroke->cap));
    glyph_paint.setStrokeJoin(ToSkiaJoin(stroke->join));
    glyph_paint.setStrokeMiter(stroke->miter_limit);
  }
  canvas->save();
  Point subpixel_offset = SubpixelPositionToPoint(glyph.subpixel_offset);
  canvas->translate(subpixel_offset.x, subpixel_offset.y);
  canvas->drawGlyphs(
      {&glyph_id, 1u}, {&position, 1u},
      SkPoint::Make(-scaled_bounds.GetLeft(), -scaled_bounds.GetTop()), sk_font,
      glyph_paint);
  canvas->restore();
}

static bool UpdateAtlasBitmap(const GlyphAtlas& atlas,
                              std::shared_ptr<BlitPass>& blit_pass,
                              HostBuffer& data_host_buffer,
                              const std::shared_ptr<Texture>& texture,
                              const std::vector<FontGlyphPair>& new_pairs,
                              size_t start_index,
                              size_t end_index) {
  TRACE_EVENT0("impeller", __FUNCTION__);

  for (size_t i = start_index; i < end_index; i++) {
    const FontGlyphPair& pair = new_pairs[i];
    auto data = atlas.FindFontGlyphBounds(pair);
    if (!data.has_value()) {
      continue;
    }
    auto [pos, bounds, placeholder] = data.value();
    FML_DCHECK(!placeholder);

    Size size = pos.GetSize();
    if (size.IsEmpty()) {
      continue;
    }
    size.width += 2;
    size.height += 2;

    SkBitmap bitmap;
    bool is_light_glyph =
        pair.glyph.properties.tone_or_color == GlyphProperties::kLightTone;

    bitmap.setInfo(
        TypographerContextSkia::GetImageInfo(atlas, size, is_light_glyph));
    if (!bitmap.tryAllocPixels()) {
      return false;
    }
    bitmap.eraseColor(SK_ColorTRANSPARENT);

    auto surface = SkSurfaces::WrapPixels(bitmap.pixmap());
    if (!surface) {
      return false;
    }
    auto canvas = surface->getCanvas();
    if (!canvas) {
      return false;
    }

    DrawGlyph(canvas, SkPoint::Make(1, 1), pair.scaled_font, pair.glyph, bounds,
              pair.glyph.properties);

    if (is_light_glyph) {
      auto a8_bitmap_status = ToA8Bitmap(bitmap);
      if (!a8_bitmap_status.ok()) {
        VALIDATION_LOG << a8_bitmap_status.status().message();
        return false;
      }
      bitmap = a8_bitmap_status.value();
    }

    // BUGFIX: Skia adds padding bytes to the end of rows for memory alignment.
    // Impeller expects a tightly packed buffer. We must manually pack the
    // memory row-by-row to avoid texture memory shearing/scrambling.
    size_t bpp = BytesPerPixelForPixelFormat(
        atlas.GetTexture()->GetTextureDescriptor().format);

    BufferView buffer_view = data_host_buffer.Emplace(
        size.Area() * bpp, data_host_buffer.GetMinimumUniformAlignment(),
        [&](uint8_t* dest) {
          const uint8_t* src = static_cast<const uint8_t*>(bitmap.getPixels());
          const int width = static_cast<int>(size.width);
          const int height = static_cast<int>(size.height);
          const size_t dest_row_bytes = width * bpp;
          const size_t src_row_bytes = bitmap.rowBytes();

          for (int y = 0; y < height; y++) {
            std::memcpy(dest + (y * dest_row_bytes), src + (y * src_row_bytes),
                        dest_row_bytes);
          }
        });

    if (!blit_pass->AddCopy(std::move(buffer_view), texture,
                            IRect::MakeXYWH(pos.GetLeft() - 1, pos.GetTop() - 1,
                                            size.width, size.height),
                            /*label=*/"",
                            /*mip_level=*/0,
                            /*slice=*/0,
                            /*convert_to_read=*/false)) {
      return false;
    }
  }

  return blit_pass->ConvertTextureToShaderRead(texture);
}

static Rect ComputeGlyphSize(const SkFont& font,
                             const SubpixelGlyph& glyph,
                             Scalar scale) {
  SkRect scaled_bounds;
  SkPaint glyph_paint;
  if (glyph.properties.stroke.has_value()) {
    glyph_paint.setStroke(true);
    glyph_paint.setStrokeWidth(glyph.properties.stroke->width * scale);
    glyph_paint.setStrokeCap(ToSkiaCap(glyph.properties.stroke->cap));
    glyph_paint.setStrokeJoin(ToSkiaJoin(glyph.properties.stroke->join));
    glyph_paint.setStrokeMiter(glyph.properties.stroke->miter_limit);
  }
  font.getBounds({&glyph.glyph.index, 1}, {&scaled_bounds, 1}, &glyph_paint);

  // BUGFIX: We MUST calculate the absolute integer floor and ceil of the
  // coordinates first. Then we add 1 pixel of padding to accommodate CoreText
  // subpixel bleeding. Without floor/ceil, the bounds remain fractional, which
  // clips the text when blitted to the integer-aligned texture atlas.
  return Rect::MakeLTRB(std::floor(scaled_bounds.fLeft) - 1.0f,
                        std::floor(scaled_bounds.fTop) - 1.0f,
                        std::ceil(scaled_bounds.fRight) + 1.0f,
                        std::ceil(scaled_bounds.fBottom) + 1.0f);
};

std::pair<std::vector<FontGlyphPair>, std::vector<Rect>>
TypographerContextSkia::CollectNewGlyphs(
    const std::shared_ptr<GlyphAtlas>& atlas,
    const std::vector<RenderableText>& renderable_texts) {
  std::vector<FontGlyphPair> new_glyphs;
  std::vector<Rect> glyph_sizes;
  for (const auto& frame : renderable_texts) {
    Rational rounded_scale = TextFrame::RoundScaledFontSize(
        frame.origin_transform.GetMaxBasisLengthXY());
    for (const auto& run : frame.text_frame->GetRuns()) {
      auto metrics = run.GetFont().GetMetrics();

      ScaledFont scaled_font{.font = run.GetFont(), .scale = rounded_scale};

      FontGlyphAtlas* font_glyph_atlas =
          atlas->GetOrCreateFontGlyphAtlas(scaled_font);
      FML_DCHECK(!!font_glyph_atlas);

      SkFont sk_font(
          TypefaceSkia::Cast(*scaled_font.font.GetTypeface()).GetSkiaTypeface(),
          metrics.point_size, metrics.scaleX, metrics.skewX);
      sk_font.setEdging(SkFont::Edging::kAntiAlias);
      sk_font.setHinting(SkFontHinting::kSlight);
      sk_font.setEmbolden(metrics.embolden);
      sk_font.setSize(sk_font.getSize() *
                      static_cast<Scalar>(scaled_font.scale));
      sk_font.setSubpixel(true);

      for (const auto& glyph_position : run.GetGlyphPositions()) {
        SubpixelPosition subpixel = TextFrame::ComputeSubpixelPosition(
            glyph_position, scaled_font.font.GetAxisAlignment(),
            frame.origin_transform);
        SubpixelGlyph subpixel_glyph(glyph_position.glyph, subpixel,
                                     frame.properties);

        // ATLAS CACHE FIX: Check if the glyph already exists in the atlas
        if (font_glyph_atlas->FindGlyphBounds(subpixel_glyph).has_value()) {
          continue;
        }

        FontGlyphPair font_glyph_pair{scaled_font, subpixel_glyph};

        auto it = std::find_if(
            new_glyphs.begin(), new_glyphs.end(),
            [&font_glyph_pair](const FontGlyphPair& existing) {
              return ScaledFont::Equal{}(font_glyph_pair.scaled_font,
                                         existing.scaled_font) &&
                     SubpixelGlyph::Equal{}(font_glyph_pair.glyph,
                                            existing.glyph);
            });

        Rect glyph_bounds;
        if (it == new_glyphs.end()) {
          new_glyphs.push_back(font_glyph_pair);
          glyph_bounds = ComputeGlyphSize(
              sk_font, subpixel_glyph, static_cast<Scalar>(scaled_font.scale));
          glyph_sizes.push_back(glyph_bounds);
        } else {
          size_t index = std::distance(new_glyphs.begin(), it);
          glyph_bounds = glyph_sizes[index];
        }

        auto frame_bounds =
            FrameBounds{Rect::MakeLTRB(0, 0, 0, 0), glyph_bounds,
                        /*placeholder=*/true};

        font_glyph_atlas->AppendGlyph(subpixel_glyph, frame_bounds);
      }
    }
  }
  return {std::move(new_glyphs), std::move(glyph_sizes)};
}

std::shared_ptr<GlyphAtlas> TypographerContextSkia::CreateGlyphAtlas(
    Context& context,
    GlyphAtlas::Type type,
    HostBuffer& data_host_buffer,
    const std::shared_ptr<GlyphAtlasContext>& atlas_context,
    const std::vector<RenderableText>& renderable_texts) const {
  TRACE_EVENT0("impeller", __FUNCTION__);
  if (!IsValid()) {
    return nullptr;
  }
  std::shared_ptr<GlyphAtlas> last_atlas = atlas_context->GetGlyphAtlas();
  FML_DCHECK(last_atlas->GetType() == type);

  if (renderable_texts.empty()) {
    return last_atlas;
  }

  auto [new_glyphs, glyph_sizes] =
      CollectNewGlyphs(last_atlas, renderable_texts);
  if (new_glyphs.size() == 0) {
    return last_atlas;
  }

  std::vector<Rect> glyph_positions;
  glyph_positions.reserve(new_glyphs.size());
  size_t first_missing_index = 0;

  if (last_atlas->GetTexture()) {
    first_missing_index = AppendToExistingAtlas(
        last_atlas, new_glyphs, glyph_positions, glyph_sizes,
        atlas_context->GetAtlasSize(), atlas_context->GetHeightAdjustment(),
        atlas_context->GetRectPacker());

    for (size_t i = 0; i < first_missing_index; i++) {
      last_atlas->AddTypefaceGlyphPositionAndBounds(
          new_glyphs[i], glyph_positions[i], glyph_sizes[i]);
    }

    std::shared_ptr<CommandBuffer> cmd_buffer = context.CreateCommandBuffer();
    std::shared_ptr<BlitPass> blit_pass = cmd_buffer->CreateBlitPass();

    fml::ScopedCleanupClosure closure([&]() {
      blit_pass->EncodeCommands();
      if (!context.EnqueueCommandBuffer(std::move(cmd_buffer))) {
        VALIDATION_LOG << "Failed to submit glyph atlas command buffer";
      }
    });

    if (!UpdateAtlasBitmap(*last_atlas, blit_pass, data_host_buffer,
                           last_atlas->GetTexture(), new_glyphs, 0,
                           first_missing_index)) {
      return nullptr;
    }

    if (first_missing_index == new_glyphs.size()) {
      return last_atlas;
    }
  }

  int64_t height_adjustment = atlas_context->GetAtlasSize().height;
  const int64_t max_texture_height =
      context.GetResourceAllocator()->GetMaxTextureSizeSupported().height;

  bool blit_old_atlas = true;
  std::shared_ptr<GlyphAtlas> new_atlas = last_atlas;
  if (atlas_context->GetAtlasSize().height >= max_texture_height ||
      context.GetBackendType() == Context::BackendType::kOpenGLES) {
    blit_old_atlas = false;
    new_atlas = std::make_shared<GlyphAtlas>(
        type, /*initial_generation=*/last_atlas->GetAtlasGeneration() + 1);

    auto [update_glyphs, update_sizes] =
        CollectNewGlyphs(new_atlas, renderable_texts);
    new_glyphs = std::move(update_glyphs);
    glyph_sizes = std::move(update_sizes);

    glyph_positions.clear();
    glyph_positions.reserve(new_glyphs.size());
    first_missing_index = 0;

    height_adjustment = 0;
    atlas_context->UpdateRectPacker(nullptr);
    atlas_context->UpdateGlyphAtlas(new_atlas, {0, 0}, 0);
  }

  ISize atlas_size = ComputeNextAtlasSize(
      atlas_context, new_glyphs, glyph_positions, glyph_sizes,
      first_missing_index, max_texture_height);

  atlas_context->UpdateGlyphAtlas(new_atlas, atlas_size, height_adjustment);
  if (atlas_size.IsEmpty()) {
    return nullptr;
  }
  FML_DCHECK(new_glyphs.size() == glyph_positions.size());

  TextureDescriptor descriptor;
  switch (type) {
    case GlyphAtlas::Type::kAlphaBitmap:
      descriptor.format =
          context.GetCapabilities()->GetDefaultGlyphAtlasFormat();
      break;
    case GlyphAtlas::Type::kColorBitmap:
      descriptor.format = PixelFormat::kR8G8B8A8UNormInt;
      break;
  }
  descriptor.size = atlas_size;
  descriptor.storage_mode = StorageMode::kDevicePrivate;
  descriptor.usage = TextureUsage::kShaderRead;
  std::shared_ptr<Texture> new_texture =
      context.GetResourceAllocator()->CreateTexture(descriptor);
  if (!new_texture) {
    return nullptr;
  }

  new_texture->SetLabel("GlyphAtlas");

  std::shared_ptr<CommandBuffer> cmd_buffer = context.CreateCommandBuffer();
  std::shared_ptr<BlitPass> blit_pass = cmd_buffer->CreateBlitPass();

  fml::ScopedCleanupClosure closure([&]() {
    blit_pass->EncodeCommands();
    if (!context.EnqueueCommandBuffer(std::move(cmd_buffer))) {
      VALIDATION_LOG << "Failed to submit glyph atlas command buffer";
    }
  });

  auto old_texture = new_atlas->GetTexture();
  new_atlas->SetTexture(std::move(new_texture));

  for (size_t i = first_missing_index; i < glyph_positions.size(); i++) {
    new_atlas->AddTypefaceGlyphPositionAndBounds(
        new_glyphs[i], glyph_positions[i], glyph_sizes[i]);
  }

  if (blit_old_atlas && old_texture) {
    blit_pass->AddCopy(
        old_texture,                              // source
        new_atlas->GetTexture(),                  // destination
        IRect::MakeSize(old_texture->GetSize()),  // source_region
        IPoint(0, 0),                             // destination_origin
        /*label=*/"");
  }

  if (!UpdateAtlasBitmap(*new_atlas, blit_pass, data_host_buffer,
                         new_atlas->GetTexture(), new_glyphs,
                         first_missing_index, new_glyphs.size())) {
    return nullptr;
  }

  return new_atlas;
}

}  // namespace impeller