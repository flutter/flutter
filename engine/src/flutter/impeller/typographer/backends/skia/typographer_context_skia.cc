// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/backends/skia/typographer_context_skia.h"

#include <cstddef>
#include <cstdint>
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

#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkBlendMode.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkFont.h"
#include "third_party/skia/include/core/SkImageInfo.h"
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

static SkImageInfo GetImageInfo(const GlyphAtlas& atlas, Size size) {
  switch (atlas.GetType()) {
    case GlyphAtlas::Type::kAlphaBitmap:
      return SkImageInfo::MakeA8(SkISize{static_cast<int32_t>(size.width),
                                         static_cast<int32_t>(size.height)});
    case GlyphAtlas::Type::kColorBitmap:
      return SkImageInfo::MakeN32Premul(size.width, size.height);
  }
  FML_UNREACHABLE();
}

bool TypographerContextSkia::AppendSizesAndGrowPacker(
    const std::shared_ptr<RectanglePacker>& rect_packer,
    std::vector<NewGlyphData>& glyphs,
    int max_packer_height) {
  if (!rect_packer) {
    // Caller should try again in the "brand new atlas" mode where they
    // create a brand new packer and expect to create a new texture.
    return false;
  }

  FML_DCHECK(rect_packer->width() > 0 && rect_packer->height() > 0);
  FML_DCHECK(rect_packer->height() <= max_packer_height);

  size_t glyph_index = 0u;
  while (glyph_index < glyphs.size()) {
    ISize glyph_size = ISize::Ceil(glyphs[glyph_index].bounds.GetSize());
    IPoint16 location_in_atlas;
    if (rect_packer->AddRect(glyph_size.width + kPadding,
                             glyph_size.height + kPadding,
                             &location_in_atlas)) {
      // Position the glyph in the center of the 1px padding.
      glyphs[glyph_index].position =
          Rect::MakeXYWH(location_in_atlas.x() + 1,  //
                         location_in_atlas.y() + 1,  //
                         glyph_size.width,           //
                         glyph_size.height           //
          );
      glyph_index++;
      continue;
    }

    int new_height = std::min(rect_packer->height() * 2, max_packer_height);
    if (new_height > rect_packer->height()) {
      rect_packer->GrowTo(rect_packer->width(), new_height);
      continue;
    }

    // We failed to add all of the glyphs to the current rectangle packer
    // even after growing it to the maximum allowed height.
    return false;
  }

  FML_DCHECK(glyph_index == glyphs.size());
  return true;
}

static Point SubpixelPositionToPoint(SubpixelPosition pos) {
  return Point((pos & 0xff) / 4.f, (pos >> 2 & 0xff) / 4.f);
}

static void DrawGlyph(SkCanvas* canvas,
                      const SkPoint position,
                      const ScaledFont& scaled_font,
                      const SubpixelGlyph& glyph,
                      const Rect& scaled_bounds,
                      const std::optional<GlyphProperties>& prop,
                      bool has_color) {
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

  auto glyph_color = prop.has_value() ? prop->color.ToARGB() : SK_ColorBLACK;

  SkPaint glyph_paint;
  glyph_paint.setColor(glyph_color);
  glyph_paint.setBlendMode(SkBlendMode::kSrc);
  if (prop.has_value()) {
    auto stroke = prop->stroke;
    if (stroke.has_value()) {
      glyph_paint.setStroke(true);
      glyph_paint.setStrokeWidth(stroke->width *
                                 static_cast<Scalar>(scaled_font.scale));
      glyph_paint.setStrokeCap(ToSkiaCap(stroke->cap));
      glyph_paint.setStrokeJoin(ToSkiaJoin(stroke->join));
      glyph_paint.setStrokeMiter(stroke->miter_limit);
    } else {
      glyph_paint.setStroke(false);
    }
  }
  canvas->save();
  Point subpixel_offset = SubpixelPositionToPoint(glyph.subpixel_offset);
  canvas->translate(subpixel_offset.x, subpixel_offset.y);
  // Draw a single glyph in the bounds
  canvas->drawGlyphs({&glyph_id, 1u},  // glyphs
                     {&position, 1u},  // positions
                     SkPoint::Make(-scaled_bounds.GetLeft(),
                                   -scaled_bounds.GetTop()),  // origin
                     sk_font,                                 // font
                     glyph_paint                              // paint
  );
  canvas->restore();
}

/// @brief Batch render to a single surface.
///
/// This is only safe for use when updating a fresh texture.
bool TypographerContextSkia::BulkUpdateAtlasBitmap(
    const GlyphAtlas& atlas,
    std::shared_ptr<BlitPass>& blit_pass,
    HostBuffer& data_host_buffer,
    const std::shared_ptr<Texture>& texture,
    const std::vector<NewGlyphData>& new_glyphs) {
  TRACE_EVENT0("impeller", __FUNCTION__);

  bool has_color = atlas.GetType() == GlyphAtlas::Type::kColorBitmap;

  SkBitmap bitmap;
  bitmap.setInfo(GetImageInfo(atlas, Size(texture->GetSize())));
  if (!bitmap.tryAllocPixels()) {
    return false;
  }

  auto surface = SkSurfaces::WrapPixels(bitmap.pixmap());
  if (!surface) {
    return false;
  }
  auto canvas = surface->getCanvas();
  if (!canvas) {
    return false;
  }

  for (const NewGlyphData& new_glyph : new_glyphs) {
    const FontGlyphPair& pair = new_glyph.pair;
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

    DrawGlyph(canvas, SkPoint::Make(pos.GetLeft(), pos.GetTop()),
              pair.scaled_font, pair.glyph, bounds, pair.glyph.properties,
              has_color);
  }

  // Writing to a malloc'd buffer and then copying to the staging buffers
  // benchmarks as substantially faster on a number of Android devices.
  BufferView buffer_view = data_host_buffer.Emplace(
      bitmap.getAddr(0, 0),
      texture->GetSize().Area() *
          BytesPerPixelForPixelFormat(
              atlas.GetTexture()->GetTextureDescriptor().format),
      data_host_buffer.GetMinimumUniformAlignment());

  return blit_pass->AddCopy(std::move(buffer_view),  //
                            texture,                 //
                            IRect::MakeXYWH(0, 0, texture->GetSize().width,
                                            texture->GetSize().height));
}

bool TypographerContextSkia::UpdateAtlasBitmap(
    const GlyphAtlas& atlas,
    std::shared_ptr<BlitPass>& blit_pass,
    HostBuffer& data_host_buffer,
    const std::shared_ptr<Texture>& texture,
    const std::vector<NewGlyphData>& new_glyphs) {
  TRACE_EVENT0("impeller", __FUNCTION__);

  bool has_color = atlas.GetType() == GlyphAtlas::Type::kColorBitmap;

  for (const NewGlyphData& new_glyph : new_glyphs) {
    const FontGlyphPair& pair = new_glyph.pair;
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
    // The uploaded bitmap is expanded by 1px of padding
    // on each side.
    size.width += 2;
    size.height += 2;

    SkBitmap bitmap;
    bitmap.setInfo(GetImageInfo(atlas, size));
    if (!bitmap.tryAllocPixels()) {
      return false;
    }

    auto surface = SkSurfaces::WrapPixels(bitmap.pixmap());
    if (!surface) {
      return false;
    }
    auto canvas = surface->getCanvas();
    if (!canvas) {
      return false;
    }

    DrawGlyph(canvas, SkPoint::Make(1, 1), pair.scaled_font, pair.glyph, bounds,
              pair.glyph.properties, has_color);

    // Writing to a malloc'd buffer and then copying to the staging buffers
    // benchmarks as substantially faster on a number of Android devices.
    BufferView buffer_view = data_host_buffer.Emplace(
        bitmap.getAddr(0, 0),
        size.Area() * BytesPerPixelForPixelFormat(
                          atlas.GetTexture()->GetTextureDescriptor().format),
        data_host_buffer.GetMinimumUniformAlignment());

    // convert_to_read is set to false so that the texture remains in a transfer
    // dst layout until we finish writing to it below. This only has an impact
    // on Vulkan where we are responsible for managing image layouts.
    if (!blit_pass->AddCopy(std::move(buffer_view),  //
                            texture,                 //
                            IRect::MakeXYWH(pos.GetLeft() - 1, pos.GetTop() - 1,
                                            size.width, size.height),  //
                            /*label=*/"",                              //
                            /*mip_level=*/0,                           //
                            /*slice=*/0,                               //
                            /*convert_to_read=*/false                  //
                            )) {
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
  if (glyph.properties.has_value() && glyph.properties->stroke) {
    glyph_paint.setStroke(true);
    glyph_paint.setStrokeWidth(glyph.properties->stroke->width * scale);
    glyph_paint.setStrokeCap(ToSkiaCap(glyph.properties->stroke->cap));
    glyph_paint.setStrokeJoin(ToSkiaJoin(glyph.properties->stroke->join));
    glyph_paint.setStrokeMiter(glyph.properties->stroke->miter_limit);
  }
  // Get bounds for a single glyph
  font.getBounds({&glyph.glyph.index, 1}, {&scaled_bounds, 1}, &glyph_paint);

  // Expand the bounds of glyphs at subpixel offsets by 2 in the x direction.
  Scalar adjustment = 0.0;
  if (glyph.subpixel_offset != SubpixelPosition::kSubpixel00) {
    adjustment = 1.0;
  }
  return Rect::MakeLTRB(scaled_bounds.fLeft - adjustment, scaled_bounds.fTop,
                        scaled_bounds.fRight + adjustment,
                        scaled_bounds.fBottom);
};

std::vector<TypographerContextSkia::NewGlyphData>
TypographerContextSkia::CollectNewGlyphs(
    const std::shared_ptr<GlyphAtlas>& atlas,
    const std::vector<RenderableText>& renderable_texts) {
  std::vector<NewGlyphData> new_glyphs;
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
      // Rather than computing the bounds at the requested point size and
      // scaling up the bounds, we scale up the font size and request the
      // bounds. This seems to give more accurate bounds information.
      sk_font.setSize(sk_font.getSize() *
                      static_cast<Scalar>(scaled_font.scale));
      sk_font.setSubpixel(true);

      for (const auto& glyph_position : run.GetGlyphPositions()) {
        SubpixelPosition subpixel = TextFrame::ComputeSubpixelPosition(
            glyph_position, scaled_font.font.GetAxisAlignment(),
            frame.origin_transform);
        SubpixelGlyph subpixel_glyph(glyph_position.glyph, subpixel,
                                     frame.properties);
        const auto& font_glyph_bounds =
            font_glyph_atlas->FindGlyphBounds(subpixel_glyph);

        if (!font_glyph_bounds.has_value()) {
          auto glyph_bounds = ComputeGlyphSize(
              sk_font, subpixel_glyph, static_cast<Scalar>(scaled_font.scale));

          new_glyphs.emplace_back(NewGlyphData{
              .pair = FontGlyphPair{scaled_font, subpixel_glyph},
              .bounds = glyph_bounds,
          });

          auto frame_bounds = FrameBounds{
              Rect::MakeLTRB(0, 0, 0, 0),  //
              glyph_bounds,                //
              /*placeholder=*/true         //
          };

          font_glyph_atlas->AppendGlyph(subpixel_glyph, frame_bounds);
        }
      }
    }
  }
  return new_glyphs;
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

  // ---------------------------------------------------------------------------
  // Step 1: Determine if the atlas type and font glyph pairs are compatible
  //         with the current atlas and reuse if possible. For each new font and
  //         glyph pair, compute the glyph size at scale.
  // ---------------------------------------------------------------------------
  std::vector<NewGlyphData> new_glyphs =
      CollectNewGlyphs(last_atlas, renderable_texts);
  if (new_glyphs.size() == 0) {
    // All of the glyphs needed in this frame were already found in the
    // existing atlas, no further work is needed.
    return last_atlas;
  }

  // ---------------------------------------------------------------------------
  // Step 2: Determine if the additional missing glyphs can be appended to the
  //         existing bitmap without recreating the atlas.
  // ---------------------------------------------------------------------------
  std::vector<Rect> glyph_positions;
  glyph_positions.reserve(new_glyphs.size());
  std::shared_ptr<RectanglePacker> packer = atlas_context->GetRectPacker();

  std::shared_ptr<GlyphAtlas> new_atlas = last_atlas;
  std::shared_ptr<Texture> last_texture = last_atlas->GetTexture();
  ISize last_atlas_size = last_texture ? last_texture->GetSize() : ISize();
  ISize new_atlas_size = last_atlas_size;

  const int64_t max_texture_height =
      context.GetResourceAllocator()->GetMaxTextureSizeSupported().height;

  // IF we cannot grow the current atlas size to fit all of the new glyphs,
  // then we will need to "GC" and create an atlas with only the required
  // glyphs. OpenGLES will always opt out of growing the atlas as it
  // cannot reliably perform the blit required to keep the glyphs in the
  // old atlas, as 1) it requires attaching textures as read and write
  // framebuffers which has substantially smaller size limits that max
  // textures and 2) is missing a GLES 2.0 implementation and cap check.
  const bool can_grow_atlas =
      (context.GetBackendType() != Context::BackendType::kOpenGLES) ||
      last_texture == nullptr;

  bool atlas_grows = false;
  bool atlas_refreshes = false;

  // If we cannot grow the atlas, then the first attempt to stuff the
  // existing atlas with the new glyphs has to indicate that the rectangle
  // packer is already at its maximum height. Otherwise, we allow the
  // algorithm to grow the packer to accomodate the new glyphs up to the
  // maximum texture height.
  const int64_t max_growth_height =
      can_grow_atlas ? max_texture_height : last_atlas_size.height;

  if (AppendSizesAndGrowPacker(packer, new_glyphs, max_growth_height)) {
    // We can fit the new glyphs into the existing atlas, but do we need
    // to grow the atlas texture to do so?
    FML_DCHECK(packer);
    atlas_grows = (packer->height() > last_atlas_size.height);
    if (atlas_grows) {
      new_atlas_size = ISize(packer->width(), packer->height());
      atlas_context->UpdateGlyphAtlas(new_atlas, new_atlas_size);
    }
  } else {
    // We could not append all of the glyphs to the existing atlas,
    // even after (potentially) growing it. So, we start over with
    // an empty atlas and try one last time.
    new_atlas = std::make_shared<GlyphAtlas>(
        type, /*initial_generation=*/last_atlas->GetAtlasGeneration() + 1);
    std::vector<NewGlyphData> update_glyphs =
        CollectNewGlyphs(new_atlas, renderable_texts);
    new_glyphs = std::move(update_glyphs);

    packer = RectanglePacker::Factory(kAtlasWidth, kMinAtlasHeight);

    glyph_positions.clear();
    glyph_positions.reserve(new_glyphs.size());

    // Since we are recreating an atlas in this instance, we can use the
    // max_texture_height as the growth limit - the newly created atlas
    // can be any allocatable height.
    if (!AppendSizesAndGrowPacker(packer, new_glyphs, max_texture_height)) {
      // We could not append all of the glyphs even to a brand new empty
      // atlas of maximum possible height, this frame cannot be updated
      // for the glyphs in it.
      return nullptr;
    }

    new_atlas_size = ISize(packer->width(), packer->height());
    atlas_context->UpdateRectPacker(packer);
    atlas_context->UpdateGlyphAtlas(new_atlas, new_atlas_size);
    atlas_refreshes = true;
  }

  std::shared_ptr<CommandBuffer> cmd_buffer = context.CreateCommandBuffer();
  std::shared_ptr<BlitPass> blit_pass = cmd_buffer->CreateBlitPass();

  fml::ScopedCleanupClosure closure([&]() {
    blit_pass->EncodeCommands();
    if (!context.EnqueueCommandBuffer(std::move(cmd_buffer))) {
      VALIDATION_LOG << "Failed to submit glyph atlas command buffer";
    }
  });

  // By one of multiple means the new glyphs have been added to a
  // rectangle packer for an atlas. That atlas may be the existing
  // atlas with no growth, or to a grown version of the existing atlas,
  // or to a brand new atlas.
  if (atlas_grows || atlas_refreshes) {
    // Either the existing atlas can contain the new glyphs, but needs
    // to grow in size, or we had to start over with an empty atlas.
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
    descriptor.size = new_atlas_size;
    descriptor.storage_mode = StorageMode::kDevicePrivate;
    descriptor.usage = TextureUsage::kShaderRead;
    std::shared_ptr<Texture> new_texture =
        context.GetResourceAllocator()->CreateTexture(descriptor);
    if (!new_texture) {
      return nullptr;
    }

    new_texture->SetLabel("GlyphAtlas");

    if (last_texture && !atlas_refreshes) {
      blit_pass->AddCopy(last_texture, new_texture,
                         IRect::MakeSize(last_atlas_size), {0, 0});
    }
    new_atlas->SetTexture(std::move(new_texture));
  }

  // ---------------------------------------------------------------------------
  // Step 3a: Record the positions in the glyph atlas of the newly added
  //          glyphs.
  // ---------------------------------------------------------------------------
  for (const auto& new_glyph : new_glyphs) {
    new_atlas->AddTypefaceGlyphPositionAndBounds(
        new_glyph.pair, new_glyph.position, new_glyph.bounds);
  }

  // ---------------------------------------------------------------------------
  // Step 4a: Draw new font-glyph pairs into the a host buffer and encode
  // the uploads into the blit pass.
  // ---------------------------------------------------------------------------
  if (atlas_refreshes) {
    if (!BulkUpdateAtlasBitmap(*new_atlas, blit_pass, data_host_buffer,
                               new_atlas->GetTexture(), new_glyphs)) {
      return nullptr;
    }
  } else {
    if (!UpdateAtlasBitmap(*new_atlas, blit_pass, data_host_buffer,
                           new_atlas->GetTexture(), new_glyphs)) {
      return nullptr;
    }
  }

  return new_atlas;
}

}  // namespace impeller
