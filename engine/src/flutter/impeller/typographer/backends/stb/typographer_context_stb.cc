// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/backends/stb/typographer_context_stb.h"

#include <numeric>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "fml/closure.h"
#include "fml/mapping.h"
#include "impeller/base/allocation.h"
#include "impeller/core/allocator.h"
#include "impeller/core/device_buffer.h"
#include "impeller/typographer/backends/stb/glyph_atlas_context_stb.h"
#include "impeller/typographer/font_glyph_pair.h"
#include "typeface_stb.h"

#define DISABLE_COLOR_FONT_SUPPORT 1
#ifdef DISABLE_COLOR_FONT_SUPPORT
constexpr auto kColorFontBitsPerPixel = 1;
#else
constexpr auto kColorFontBitsPerPixel = 4;
#endif

namespace impeller {

constexpr size_t kPadding = 1;

std::unique_ptr<TypographerContext> TypographerContextSTB::Make() {
  return std::make_unique<TypographerContextSTB>();
}

TypographerContextSTB::TypographerContextSTB() : TypographerContext() {}

TypographerContextSTB::~TypographerContextSTB() = default;

std::shared_ptr<GlyphAtlasContext>
TypographerContextSTB::CreateGlyphAtlasContext(GlyphAtlas::Type type) const {
  return std::make_shared<GlyphAtlasContextSTB>(type);
}

// Function returns the count of "remaining pairs" not packed into rect of given
// size.
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
    const Font& font = pair.scaled_font.font;

    // We downcast to the correct typeface type to access `stb` specific
    // methods.
    std::shared_ptr<TypefaceSTB> typeface_stb =
        std::reinterpret_pointer_cast<TypefaceSTB>(font.GetTypeface());
    // Conversion factor to scale font size in Points to pixels.
    // Note this assumes typical DPI.
    float text_size_pixels =
        font.GetMetrics().point_size * TypefaceSTB::kPointsToPixels;

    ISize glyph_size;
    {
      int x0 = 0, y0 = 0, x1 = 0, y1 = 0;
      float scale = stbtt_ScaleForMappingEmToPixels(typeface_stb->GetFontInfo(),
                                                    text_size_pixels);
      stbtt_GetGlyphBitmapBox(typeface_stb->GetFontInfo(),
                              pair.glyph.glyph.index, scale, scale, &x0, &y0,
                              &x1, &y1);

      glyph_size = ISize(x1 - x0, y1 - y0);
    }

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
    const Font& font = pair.scaled_font.font;

    // We downcast to the correct typeface type to access `stb` specific methods
    std::shared_ptr<TypefaceSTB> typeface_stb =
        std::reinterpret_pointer_cast<TypefaceSTB>(font.GetTypeface());
    // Conversion factor to scale font size in Points to pixels.
    // Note this assumes typical DPI.
    float text_size_pixels =
        font.GetMetrics().point_size * TypefaceSTB::kPointsToPixels;

    ISize glyph_size;
    {
      int x0 = 0, y0 = 0, x1 = 0, y1 = 0;
      float scale_y = stbtt_ScaleForMappingEmToPixels(
          typeface_stb->GetFontInfo(), text_size_pixels);
      float scale_x = scale_y;
      stbtt_GetGlyphBitmapBox(typeface_stb->GetFontInfo(),
                              pair.glyph.glyph.index, scale_x, scale_y, &x0,
                              &y0, &x1, &y1);

      glyph_size = ISize(x1 - x0, y1 - y0);
    }

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

static void DrawGlyph(BitmapSTB* bitmap,
                      const ScaledFont& scaled_font,
                      const Glyph& glyph,
                      const Rect& location,
                      bool has_color) {
  const auto& metrics = scaled_font.font.GetMetrics();

  const impeller::Font& font = scaled_font.font;
  auto typeface = font.GetTypeface();
  // We downcast to the correct typeface type to access `stb` specific methods
  std::shared_ptr<TypefaceSTB> typeface_stb =
      std::reinterpret_pointer_cast<TypefaceSTB>(typeface);
  // Conversion factor to scale font size in Points to pixels.
  // Note this assumes typical DPI.
  float text_size_pixels = metrics.point_size * TypefaceSTB::kPointsToPixels;
  float scale_y = stbtt_ScaleForMappingEmToPixels(typeface_stb->GetFontInfo(),
                                                  text_size_pixels);
  float scale_x = scale_y;

  auto output = bitmap->GetPixelAddress({static_cast<size_t>(location.GetX()),
                                         static_cast<size_t>(location.GetY())});
  // For Alpha and Signed Distance field bitmaps we can use STB to draw the
  // Glyph in place
  if (!has_color || DISABLE_COLOR_FONT_SUPPORT) {
    stbtt_MakeGlyphBitmap(typeface_stb->GetFontInfo(), output,
                          location.GetWidth(), location.GetHeight(),
                          bitmap->GetRowBytes(), scale_x, scale_y, glyph.index);
  } else {
    // But for color bitmaps we need to get the glyph pixels and then carry all
    // channels into the atlas bitmap. This may not be performant but I'm unsure
    // of any other approach currently.
    int glyph_bitmap_width = 0;
    int glyph_bitmap_height = 0;
    int glyph_bitmap_xoff = 0;
    int glyph_bitmap_yoff = 0;
    auto glyph_pixels = stbtt_GetGlyphBitmap(
        typeface_stb->GetFontInfo(), scale_x, scale_y, glyph.index,
        &glyph_bitmap_width, &glyph_bitmap_height, &glyph_bitmap_xoff,
        &glyph_bitmap_yoff);

    uint8_t* write_pos = output;
    for (auto y = 0; y < glyph_bitmap_height; ++y) {
      for (auto x = 0; x < glyph_bitmap_width; ++x) {
        // Color bitmaps write as White (i.e. what is 0 in an alpha bitmap is
        // 255 in a color bitmap) But not alpha. Alpha still carries
        // transparency info in the normal way.
        // There's some issue with color fonts, in that if the pixel color is
        // nonzero, the alpha is ignored during rendering. That is, partially
        // (or fully) transparent pixels with nonzero color are rendered as
        // fully opaque.
        uint8_t a = glyph_pixels[x + y * glyph_bitmap_width];
        uint8_t c = 255 - a;

        // Red channel
        *write_pos = c;
        write_pos++;
        // Green channel
        *write_pos = c;
        write_pos++;
        // Blue channel
        *write_pos = c;
        write_pos++;
        // Alpha channel
        *write_pos = a;
        write_pos++;
      }
      // next row
      write_pos = output + (y * bitmap->GetRowBytes());
    }
    stbtt_FreeBitmap(glyph_pixels, nullptr);
  }
}

static bool UpdateAtlasBitmap(const GlyphAtlas& atlas,
                              const std::shared_ptr<BitmapSTB>& bitmap,
                              const std::vector<FontGlyphPair>& new_pairs) {
  TRACE_EVENT0("impeller", __FUNCTION__);
  FML_DCHECK(bitmap != nullptr);

  bool has_color = atlas.GetType() == GlyphAtlas::Type::kColorBitmap;

  for (const FontGlyphPair& pair : new_pairs) {
    auto pos = atlas.FindFontGlyphBounds(pair);
    if (!pos.has_value()) {
      continue;
    }
    DrawGlyph(bitmap.get(), pair.scaled_font, pair.glyph.glyph,
              pos.value().first, has_color);
  }
  return true;
}

static std::shared_ptr<BitmapSTB> CreateAtlasBitmap(const GlyphAtlas& atlas,
                                                    const ISize& atlas_size) {
  TRACE_EVENT0("impeller", __FUNCTION__);

  size_t bytes_per_pixel = 1;
  if (atlas.GetType() == GlyphAtlas::Type::kColorBitmap &&
      !DISABLE_COLOR_FONT_SUPPORT) {
    bytes_per_pixel = kColorFontBitsPerPixel;
  }
  auto bitmap = std::make_shared<BitmapSTB>(atlas_size.width, atlas_size.height,
                                            bytes_per_pixel);

  bool has_color = atlas.GetType() == GlyphAtlas::Type::kColorBitmap;

  atlas.IterateGlyphs([&bitmap, has_color](const ScaledFont& scaled_font,
                                           const SubpixelGlyph& glyph,
                                           const Rect& location) -> bool {
    DrawGlyph(bitmap.get(), scaled_font, glyph.glyph, location, has_color);
    return true;
  });

  return bitmap;
}

// static bool UpdateGlyphTextureAtlas(std::shared_ptr<SkBitmap> bitmap,
static bool UpdateGlyphTextureAtlas(std::shared_ptr<BitmapSTB>& bitmap,
                                    const std::shared_ptr<Allocator>& allocator,
                                    std::shared_ptr<BlitPass>& blit_pass,
                                    const std::shared_ptr<Texture>& texture) {
  TRACE_EVENT0("impeller", __FUNCTION__);

  FML_DCHECK(bitmap != nullptr);

  auto texture_descriptor = texture->GetTextureDescriptor();

  auto mapping = std::make_shared<fml::NonOwnedMapping>(
      reinterpret_cast<const uint8_t*>(bitmap->GetPixels()),  // data
      texture_descriptor.GetByteSizeOfBaseMipLevel()          // size
      // As the bitmap is static in this module I believe we don't need to
      // specify a release proc.
  );

  std::shared_ptr<DeviceBuffer> device_buffer =
      allocator->CreateBufferWithCopy(*mapping);
  blit_pass->AddCopy(DeviceBuffer::AsBufferView(device_buffer), texture);

  return blit_pass->EncodeCommands(allocator);
}

static std::shared_ptr<Texture> UploadGlyphTextureAtlas(
    const std::shared_ptr<Allocator>& allocator,
    std::shared_ptr<BlitPass>& blit_pass,
    std::shared_ptr<BitmapSTB>& bitmap,
    const ISize& atlas_size,
    PixelFormat format) {
  TRACE_EVENT0("impeller", __FUNCTION__);
  if (!allocator) {
    return nullptr;
  }

  FML_DCHECK(bitmap != nullptr);

  TextureDescriptor texture_descriptor;
  texture_descriptor.storage_mode = StorageMode::kDevicePrivate;
  texture_descriptor.format = format;
  texture_descriptor.size = atlas_size;

  if (bitmap->GetRowBytes() * bitmap->GetHeight() !=
      texture_descriptor.GetByteSizeOfBaseMipLevel()) {
    return nullptr;
  }

  auto texture = allocator->CreateTexture(texture_descriptor);
  if (!texture || !texture->IsValid()) {
    return nullptr;
  }
  texture->SetLabel("GlyphAtlas");

  std::shared_ptr<fml::NonOwnedMapping> mapping =
      std::make_shared<fml::NonOwnedMapping>(
          reinterpret_cast<const uint8_t*>(bitmap->GetPixels()),  // data
          texture_descriptor.GetByteSizeOfBaseMipLevel()          // size
          // As the bitmap is static in this module I believe we don't need to
          // specify a release proc.
      );
  std::shared_ptr<DeviceBuffer> device_buffer =
      allocator->CreateBufferWithCopy(*mapping);
  blit_pass->AddCopy(DeviceBuffer::AsBufferView(device_buffer), texture);
  if (!blit_pass->EncodeCommands(allocator)) {
    return nullptr;
  }

  return texture;
}

static Rect ComputeGlyphSize(const ScaledFont& font,
                             const SubpixelGlyph& glyph) {
  std::shared_ptr<TypefaceSTB> typeface_stb =
      std::reinterpret_pointer_cast<TypefaceSTB>(font.font.GetTypeface());
  float scale = stbtt_ScaleForMappingEmToPixels(
      typeface_stb->GetFontInfo(),
      font.font.GetMetrics().point_size * TypefaceSTB::kPointsToPixels);
  int x0 = 0, y0 = 0, x1 = 0, y1 = 0;
  stbtt_GetGlyphBitmapBox(typeface_stb->GetFontInfo(), glyph.glyph.index, scale,
                          scale, &x0, &y0, &x1, &y1);
  return Rect::MakeLTRB(0, 0, x1 - x0, y1 - y0);
}

std::shared_ptr<GlyphAtlas> TypographerContextSTB::CreateGlyphAtlas(
    Context& context,
    GlyphAtlas::Type type,
    HostBuffer& host_buffer,
    const std::shared_ptr<GlyphAtlasContext>& atlas_context,
    const FontGlyphMap& font_glyph_map) const {
  TRACE_EVENT0("impeller", __FUNCTION__);
  if (!IsValid()) {
    return nullptr;
  }
  auto& atlas_context_stb = GlyphAtlasContextSTB::Cast(*atlas_context);
  std::shared_ptr<GlyphAtlas> last_atlas = atlas_context->GetGlyphAtlas();

  if (font_glyph_map.empty()) {
    return last_atlas;
  }

  // ---------------------------------------------------------------------------
  // Step 1: Determine if the atlas type and font glyph pairs are compatible
  //         with the current atlas and reuse if possible.
  // ---------------------------------------------------------------------------
  std::vector<FontGlyphPair> new_glyphs;
  std::vector<Rect> new_sizes;
  for (const auto& font_value : font_glyph_map) {
    const ScaledFont& scaled_font = font_value.first;
    const FontGlyphAtlas* font_glyph_atlas =
        last_atlas->GetFontGlyphAtlas(scaled_font.font, scaled_font.scale);
    if (font_glyph_atlas) {
      for (const SubpixelGlyph& glyph : font_value.second) {
        if (!font_glyph_atlas->FindGlyphBounds(glyph)) {
          new_glyphs.emplace_back(scaled_font, glyph);
          new_sizes.push_back(ComputeGlyphSize(scaled_font, glyph));
        }
      }
    } else {
      for (const SubpixelGlyph& glyph : font_value.second) {
        new_glyphs.emplace_back(scaled_font, glyph);
        new_sizes.push_back(ComputeGlyphSize(scaled_font, glyph));
      }
    }
  }

  if (last_atlas->GetType() == type && new_glyphs.size() == 0) {
    return last_atlas;
  }

  std::shared_ptr<CommandBuffer> cmd_buffer = context.CreateCommandBuffer();
  std::shared_ptr<BlitPass> blit_pass = cmd_buffer->CreateBlitPass();

  fml::ScopedCleanupClosure closure([&cmd_buffer, &context]() {
    context.GetCommandQueue()->Submit({std::move(cmd_buffer)});
  });

  // ---------------------------------------------------------------------------
  // Step 2: Determine if the additional missing glyphs can be appended to the
  //         existing bitmap without recreating the atlas. This requires that
  //         the type is identical.
  // ---------------------------------------------------------------------------
  std::vector<Rect> glyph_positions;
  if (last_atlas->GetType() == type &&
      CanAppendToExistingAtlas(last_atlas, new_glyphs, glyph_positions,
                               atlas_context->GetAtlasSize(),
                               atlas_context->GetRectPacker())) {
    // The old bitmap will be reused and only the additional glyphs will be
    // added.

    // ---------------------------------------------------------------------------
    // Step 3a: Record the positions in the glyph atlas of the newly added
    // glyphs.
    // ---------------------------------------------------------------------------
    for (size_t i = 0, count = glyph_positions.size(); i < count; i++) {
      last_atlas->AddTypefaceGlyphPositionAndBounds(
          new_glyphs[i], glyph_positions[i], new_sizes[i]);
    }

    // ---------------------------------------------------------------------------
    // Step 4a: Draw new font-glyph pairs into the existing bitmap.
    // ---------------------------------------------------------------------------
    // auto bitmap = atlas_context->GetBitmap();
    auto bitmap = atlas_context_stb.GetBitmap();
    if (!UpdateAtlasBitmap(*last_atlas, bitmap, new_glyphs)) {
      return nullptr;
    }

    // ---------------------------------------------------------------------------
    // Step 5a: Update the existing texture with the updated bitmap.
    // ---------------------------------------------------------------------------
    if (!UpdateGlyphTextureAtlas(bitmap, context.GetResourceAllocator(),
                                 blit_pass, last_atlas->GetTexture())) {
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
    for (const SubpixelGlyph& glyph : font_value.second) {
      font_glyph_pairs.push_back({scaled_font, glyph});
    }
  }
  auto glyph_atlas = std::make_shared<GlyphAtlas>(type);
  auto atlas_size = OptimumAtlasSizeForFontGlyphPairs(
      font_glyph_pairs,                                             //
      glyph_positions,                                              //
      atlas_context,                                                //
      type,                                                         //
      context.GetResourceAllocator()->GetMaxTextureSizeSupported()  //
  );

  atlas_context->UpdateGlyphAtlas(glyph_atlas, atlas_size, 0);
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
      glyph_atlas->AddTypefaceGlyphPositionAndBounds(*it, glyph_positions[i],
                                                     new_sizes[i]);
    }
  }

  // ---------------------------------------------------------------------------
  // Step 6b: Draw font-glyph pairs in the correct spot in the atlas.
  // ---------------------------------------------------------------------------
  auto bitmap = CreateAtlasBitmap(*glyph_atlas, atlas_size);
  if (!bitmap) {
    return nullptr;
  }
  atlas_context_stb.UpdateBitmap(bitmap);

  // ---------------------------------------------------------------------------
  // Step 7b: Upload the atlas as a texture.
  // ---------------------------------------------------------------------------
  PixelFormat format;
  switch (type) {
    case GlyphAtlas::Type::kAlphaBitmap:
      format = context.GetCapabilities()->GetDefaultGlyphAtlasFormat();
      break;
    case GlyphAtlas::Type::kColorBitmap:
      format = DISABLE_COLOR_FONT_SUPPORT
                   ? context.GetCapabilities()->GetDefaultGlyphAtlasFormat()
                   : PixelFormat::kR8G8B8A8UNormInt;
      break;
  }
  auto texture = UploadGlyphTextureAtlas(context.GetResourceAllocator(),
                                         blit_pass, bitmap, atlas_size, format);
  if (!texture) {
    return nullptr;
  }

  // ---------------------------------------------------------------------------
  // Step 8b: Record the texture in the glyph atlas.
  // ---------------------------------------------------------------------------
  glyph_atlas->SetTexture(std::move(texture));

  return glyph_atlas;
}

}  // namespace impeller
