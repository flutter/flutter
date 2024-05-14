// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/backends/skia/typographer_context_skia.h"

#include <cstddef>
#include <numeric>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "fml/closure.h"

#include "impeller/base/allocation.h"
#include "impeller/core/allocator.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/formats.h"
#include "impeller/core/host_buffer.h"
#include "impeller/core/platform.h"
#include "impeller/core/texture_descriptor.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/renderer/render_target.h"
#include "impeller/typographer/backends/skia/typeface_skia.h"
#include "impeller/typographer/glyph_atlas.h"
#include "impeller/typographer/rectangle_packer.h"
#include "impeller/typographer/typographer_context.h"
#include "include/core/SkColor.h"
#include "include/core/SkImageInfo.h"
#include "include/core/SkPixelRef.h"
#include "include/core/SkSize.h"

#include "third_party/skia/include/core/SkBitmap.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkFont.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace impeller {

// TODO(bdero): We might be able to remove this per-glyph padding if we fix
//              the underlying causes of the overlap.
//              https://github.com/flutter/flutter/issues/114563
constexpr auto kPadding = 2;

namespace {

class HostBufferAllocator : public SkBitmap::Allocator {
 public:
  explicit HostBufferAllocator(HostBuffer& host_buffer)
      : host_buffer_(host_buffer) {}

  [[nodiscard]] BufferView TakeBufferView() {
    buffer_view_.buffer->Flush();
    return std::move(buffer_view_);
  }

  // |SkBitmap::Allocator|
  bool allocPixelRef(SkBitmap* bitmap) override {
    if (!bitmap) {
      return false;
    }
    const SkImageInfo& info = bitmap->info();
    if (kUnknown_SkColorType == info.colorType() || info.width() < 0 ||
        info.height() < 0 || !info.validRowBytes(bitmap->rowBytes())) {
      return false;
    }

    size_t required_bytes = bitmap->rowBytes() * bitmap->height();
    BufferView buffer_view = host_buffer_.Emplace(nullptr, required_bytes,
                                                  DefaultUniformAlignment());

    // The impeller host buffer is not cleared between frames and may contain
    // stale data. The Skia software canvas does not write to pixels without
    // any contents, which causes this data to leak through.
    ::memset(buffer_view.buffer->OnGetContents() + buffer_view.range.offset, 0,
             required_bytes);

    auto pixel_ref = sk_sp<SkPixelRef>(new SkPixelRef(
        info.width(), info.height(),
        buffer_view.buffer->OnGetContents() + buffer_view.range.offset,
        bitmap->rowBytes()));

    bitmap->setPixelRef(std::move(pixel_ref), 0, 0);
    buffer_view_ = std::move(buffer_view);
    return true;
  }

 private:
  BufferView buffer_view_;
  HostBuffer& host_buffer_;
};

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

static size_t PairsFitInAtlasOfSize(
    const std::vector<FontGlyphPair>& pairs,
    const ISize& atlas_size,
    std::vector<Rect>& glyph_positions,
    const std::shared_ptr<RectanglePacker>& rect_packer) {
  if (atlas_size.IsEmpty()) {
    return false;
  }

  glyph_positions.clear();
  glyph_positions.reserve(pairs.size());

  size_t i = 0;
  for (auto it = pairs.begin(); it != pairs.end(); ++i, ++it) {
    const auto& pair = *it;

    const auto glyph_size =
        ISize::Ceil(pair.glyph.bounds.GetSize() * pair.scaled_font.scale);
    IPoint16 location_in_atlas;
    if (!rect_packer->AddRect(glyph_size.width + kPadding,   //
                              glyph_size.height + kPadding,  //
                              &location_in_atlas             //
                              )) {
      return pairs.size() - i;
    }
    glyph_positions.emplace_back(Rect::MakeXYWH(location_in_atlas.x(),  //
                                                location_in_atlas.y(),  //
                                                glyph_size.width,       //
                                                glyph_size.height       //
                                                ));
  }

  return 0;
}

static bool CanAppendToExistingAtlas(
    const std::shared_ptr<GlyphAtlas>& atlas,
    const std::vector<FontGlyphPair>& extra_pairs,
    std::vector<Rect>& glyph_positions,
    ISize atlas_size,
    const std::shared_ptr<RectanglePacker>& rect_packer) {
  TRACE_EVENT0("impeller", __FUNCTION__);
  if (!rect_packer || atlas_size.IsEmpty()) {
    return false;
  }

  // We assume that all existing glyphs will fit. After all, they fit before.
  // The glyph_positions only contains the values for the additional glyphs
  // from extra_pairs.
  FML_DCHECK(glyph_positions.size() == 0);
  glyph_positions.reserve(extra_pairs.size());
  for (size_t i = 0; i < extra_pairs.size(); i++) {
    const FontGlyphPair& pair = extra_pairs[i];

    const auto glyph_size =
        ISize::Ceil(pair.glyph.bounds.GetSize() * pair.scaled_font.scale);
    IPoint16 location_in_atlas;
    if (!rect_packer->AddRect(glyph_size.width + kPadding,   //
                              glyph_size.height + kPadding,  //
                              &location_in_atlas             //
                              )) {
      return false;
    }
    glyph_positions.emplace_back(Rect::MakeXYWH(location_in_atlas.x(),  //
                                                location_in_atlas.y(),  //
                                                glyph_size.width,       //
                                                glyph_size.height       //
                                                ));
  }

  return true;
}

static ISize OptimumAtlasSizeForFontGlyphPairs(
    const std::vector<FontGlyphPair>& pairs,
    std::vector<Rect>& glyph_positions,
    const std::shared_ptr<GlyphAtlasContext>& atlas_context,
    GlyphAtlas::Type type,
    const ISize& max_texture_size) {
  static constexpr auto kMinAtlasSize = 8u;
  static constexpr auto kMinAlphaBitmapSize = 1024u;

  TRACE_EVENT0("impeller", __FUNCTION__);

  ISize current_size = type == GlyphAtlas::Type::kAlphaBitmap
                           ? ISize(kMinAlphaBitmapSize, kMinAlphaBitmapSize)
                           : ISize(kMinAtlasSize, kMinAtlasSize);
  size_t total_pairs = pairs.size() + 1;
  do {
    auto rect_packer = std::shared_ptr<RectanglePacker>(
        RectanglePacker::Factory(current_size.width, current_size.height));

    auto remaining_pairs = PairsFitInAtlasOfSize(pairs, current_size,
                                                 glyph_positions, rect_packer);
    if (remaining_pairs == 0) {
      atlas_context->UpdateRectPacker(rect_packer);
      return current_size;
    } else if (remaining_pairs < std::ceil(total_pairs / 2)) {
      current_size = ISize::MakeWH(
          std::max(current_size.width, current_size.height),
          Allocation::NextPowerOfTwoSize(
              std::min(current_size.width, current_size.height) + 1));
    } else {
      current_size = ISize::MakeWH(
          Allocation::NextPowerOfTwoSize(current_size.width + 1),
          Allocation::NextPowerOfTwoSize(current_size.height + 1));
    }
  } while (current_size.width <= max_texture_size.width &&
           current_size.height <= max_texture_size.height);
  return ISize{0, 0};
}

static void DrawGlyph(SkCanvas* canvas,
                      const ScaledFont& scaled_font,
                      const Glyph& glyph,
                      bool has_color) {
  const auto& metrics = scaled_font.font.GetMetrics();
  const auto position = SkPoint::Make(0, 0);
  SkGlyphID glyph_id = glyph.index;

  SkFont sk_font(
      TypefaceSkia::Cast(*scaled_font.font.GetTypeface()).GetSkiaTypeface(),
      metrics.point_size, metrics.scaleX, metrics.skewX);
  sk_font.setEdging(SkFont::Edging::kAntiAlias);
  sk_font.setHinting(SkFontHinting::kSlight);
  sk_font.setEmbolden(metrics.embolden);

  auto glyph_color = has_color ? SK_ColorWHITE : SK_ColorBLACK;

  SkPaint glyph_paint;
  glyph_paint.setColor(glyph_color);
  canvas->resetMatrix();
  canvas->scale(scaled_font.scale, scaled_font.scale);

  canvas->drawGlyphs(
      1u,         // count
      &glyph_id,  // glyphs
      &position,  // positions
      SkPoint::Make(-glyph.bounds.GetLeft(), -glyph.bounds.GetTop()),  // origin
      sk_font,                                                         // font
      glyph_paint                                                      // paint
  );
}

static bool UpdateAtlasBitmap(const GlyphAtlas& atlas,
                              std::shared_ptr<BlitPass>& blit_pass,
                              HostBuffer& host_buffer,
                              const std::shared_ptr<Texture>& texture,
                              const std::vector<FontGlyphPair>& new_pairs) {
  TRACE_EVENT0("impeller", __FUNCTION__);

  bool has_color = atlas.GetType() == GlyphAtlas::Type::kColorBitmap;

  for (const FontGlyphPair& pair : new_pairs) {
    auto pos = atlas.FindFontGlyphBounds(pair);
    if (!pos.has_value()) {
      continue;
    }
    Size size = pos->GetSize();
    if (size.IsEmpty()) {
      continue;
    }

    SkBitmap bitmap;
    HostBufferAllocator allocator(host_buffer);
    bitmap.setInfo(GetImageInfo(atlas, size));
    if (!bitmap.tryAllocPixels(&allocator)) {
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

    DrawGlyph(canvas, pair.scaled_font, pair.glyph, has_color);

    if (!blit_pass->AddCopy(allocator.TakeBufferView(), texture,
                            IRect::MakeXYWH(pos->GetLeft(), pos->GetTop(),
                                            size.width, size.height))) {
      return false;
    }
  }
  return true;
}

// The texture needs to be cleared to transparent black so that linearly
// samplex rotated/skewed glyphs do not grab uninitialized data.
bool ClearTextureToTransparentBlack(Context& context,
                                    HostBuffer& host_buffer,
                                    std::shared_ptr<CommandBuffer>& cmd_buffer,
                                    std::shared_ptr<BlitPass>& blit_pass,
                                    std::shared_ptr<Texture>& texture) {
  // The R8/A8 textures used for certain glyphs is not supported as color
  // attachments in most graphics drivers. To be safe, just do a CPU clear
  // for these.
  if (texture->GetTextureDescriptor().format ==
      context.GetCapabilities()->GetDefaultGlyphAtlasFormat()) {
    size_t byte_size =
        texture->GetTextureDescriptor().GetByteSizeOfBaseMipLevel();
    BufferView buffer_view =
        host_buffer.Emplace(nullptr, byte_size, DefaultUniformAlignment());

    ::memset(buffer_view.buffer->OnGetContents() + buffer_view.range.offset, 0,
             byte_size);
    buffer_view.buffer->Flush();
    return blit_pass->AddCopy(buffer_view, texture);
  }
  // In all other cases, we can use a render pass to clear to a transparent
  // color.
  ColorAttachment attachment;
  attachment.clear_color = Color::BlackTransparent();
  attachment.load_action = LoadAction::kClear;
  attachment.store_action = StoreAction::kStore;
  attachment.texture = texture;

  RenderTarget render_target;
  render_target.SetColorAttachment(attachment, 0u);

  auto render_pass = cmd_buffer->CreateRenderPass(render_target);
  return render_pass->EncodeCommands();
}

std::shared_ptr<GlyphAtlas> TypographerContextSkia::CreateGlyphAtlas(
    Context& context,
    GlyphAtlas::Type type,
    HostBuffer& host_buffer,
    const std::shared_ptr<GlyphAtlasContext>& atlas_context,
    const FontGlyphMap& font_glyph_map) const {
  TRACE_EVENT0("impeller", __FUNCTION__);
  if (!IsValid()) {
    return nullptr;
  }
  std::shared_ptr<GlyphAtlas> last_atlas = atlas_context->GetGlyphAtlas();
  FML_DCHECK(last_atlas->GetType() == type);

  if (font_glyph_map.empty()) {
    return last_atlas;
  }
  std::shared_ptr<CommandBuffer> cmd_buffer = context.CreateCommandBuffer();
  std::shared_ptr<BlitPass> blit_pass = cmd_buffer->CreateBlitPass();

  fml::ScopedCleanupClosure closure([&]() {
    blit_pass->EncodeCommands(context.GetResourceAllocator());
    context.GetCommandQueue()->Submit({std::move(cmd_buffer)});
  });

  // ---------------------------------------------------------------------------
  // Step 1: Determine if the atlas type and font glyph pairs are compatible
  //         with the current atlas and reuse if possible.
  // ---------------------------------------------------------------------------
  std::vector<FontGlyphPair> new_glyphs;
  for (const auto& font_value : font_glyph_map) {
    const ScaledFont& scaled_font = font_value.first;
    const FontGlyphAtlas* font_glyph_atlas =
        last_atlas->GetFontGlyphAtlas(scaled_font.font, scaled_font.scale);
    if (font_glyph_atlas) {
      for (const Glyph& glyph : font_value.second) {
        if (!font_glyph_atlas->FindGlyphBounds(glyph)) {
          new_glyphs.emplace_back(scaled_font, glyph);
        }
      }
    } else {
      for (const Glyph& glyph : font_value.second) {
        new_glyphs.emplace_back(scaled_font, glyph);
      }
    }
  }
  if (new_glyphs.size() == 0) {
    return last_atlas;
  }

  // ---------------------------------------------------------------------------
  // Step 2: Determine if the additional missing glyphs can be appended to the
  //         existing bitmap without recreating the atlas. This requires that
  //         the type is identical.
  // ---------------------------------------------------------------------------
  std::vector<Rect> glyph_positions;
  if (CanAppendToExistingAtlas(last_atlas, new_glyphs, glyph_positions,
                               atlas_context->GetAtlasSize(),
                               atlas_context->GetRectPacker())) {
    // The old bitmap will be reused and only the additional glyphs will be
    // added.

    // ---------------------------------------------------------------------------
    // Step 3a: Record the positions in the glyph atlas of the newly added
    //          glyphs.
    // ---------------------------------------------------------------------------
    for (size_t i = 0, count = glyph_positions.size(); i < count; i++) {
      last_atlas->AddTypefaceGlyphPosition(new_glyphs[i], glyph_positions[i]);
    }

    // ---------------------------------------------------------------------------
    // Step 4a: Draw new font-glyph pairs into the a host buffer and encode
    // the uploads into the blit pass.
    // ---------------------------------------------------------------------------
    if (!UpdateAtlasBitmap(*last_atlas, blit_pass, host_buffer,
                           last_atlas->GetTexture(), new_glyphs)) {
      return nullptr;
    }

    return last_atlas;
  }
  // A new glyph atlas must be created.

  // ---------------------------------------------------------------------------
  // Step 3b: Get the optimum size of the texture atlas.
  // ---------------------------------------------------------------------------
  std::vector<FontGlyphPair> font_glyph_pairs;
  font_glyph_pairs.reserve(std::accumulate(
      font_glyph_map.begin(), font_glyph_map.end(), 0,
      [](const int a, const auto& b) { return a + b.second.size(); }));
  for (const auto& font_value : font_glyph_map) {
    const ScaledFont& scaled_font = font_value.first;
    for (const Glyph& glyph : font_value.second) {
      font_glyph_pairs.push_back({scaled_font, glyph});
    }
  }
  std::shared_ptr<GlyphAtlas> glyph_atlas = std::make_shared<GlyphAtlas>(type);
  ISize atlas_size = OptimumAtlasSizeForFontGlyphPairs(
      font_glyph_pairs,                                             //
      glyph_positions,                                              //
      atlas_context,                                                //
      type,                                                         //
      context.GetResourceAllocator()->GetMaxTextureSizeSupported()  //
  );

  atlas_context->UpdateGlyphAtlas(glyph_atlas, atlas_size);
  if (atlas_size.IsEmpty()) {
    return nullptr;
  }
  // ---------------------------------------------------------------------------
  // Step 4b: Find location of font-glyph pairs in the atlas. We have this from
  // the last step. So no need to do create another rect packer. But just do a
  // sanity check of counts. This could also be just an assertion as only a
  // construction issue would cause such a failure.
  // ---------------------------------------------------------------------------
  if (glyph_positions.size() != font_glyph_pairs.size()) {
    return nullptr;
  }

  // ---------------------------------------------------------------------------
  // Step 5b: Record the positions in the glyph atlas.
  // ---------------------------------------------------------------------------
  {
    size_t i = 0;
    for (auto it = font_glyph_pairs.begin(); it != font_glyph_pairs.end();
         ++i, ++it) {
      glyph_atlas->AddTypefaceGlyphPosition(*it, glyph_positions[i]);
    }
  }

  // If the new atlas size is the same size as the previous texture, reuse the
  // texture and treat this as an updated that replaces all glyphs.
  std::shared_ptr<Texture> new_texture;
  if (last_atlas && last_atlas->GetTexture() &&
      last_atlas->GetTexture()->GetSize() == atlas_size) {
    new_texture = last_atlas->GetTexture();
  } else {
    // Otherwise, create a new texture.
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
    descriptor.usage = TextureUsage::kShaderRead | TextureUsage::kRenderTarget;
    new_texture = context.GetResourceAllocator()->CreateTexture(descriptor);
  }

  if (!new_texture) {
    return nullptr;
  }

  new_texture->SetLabel("GlyphAtlas");

  ClearTextureToTransparentBlack(context, host_buffer, cmd_buffer, blit_pass,
                                 new_texture);
  if (!UpdateAtlasBitmap(*glyph_atlas, blit_pass, host_buffer, new_texture,
                         font_glyph_pairs)) {
    return nullptr;
  }

  // ---------------------------------------------------------------------------
  // Step 8b: Record the texture in the glyph atlas.
  // ---------------------------------------------------------------------------
  glyph_atlas->SetTexture(std::move(new_texture));

  return glyph_atlas;
}

}  // namespace impeller
