// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/backends/skia/text_frame_skia.h"

#include <vector>

#include "flutter/display_list/geometry/dl_path.h"
#include "flutter/fml/logging.h"
#include "fml/status.h"
#include "impeller/typographer/backends/skia/typeface_skia.h"
#include "impeller/typographer/font.h"
#include "impeller/typographer/glyph.h"
#include "third_party/skia/include/core/SkData.h"
#include "third_party/skia/include/core/SkFont.h"
#include "third_party/skia/include/core/SkFontMetrics.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/core/SkPaint.h"
#include "third_party/skia/include/core/SkPath.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkTypeface.h"
#include "third_party/skia/modules/skparagraph/include/Paragraph.h"  // nogncheck
#include "third_party/skia/src/core/SkStrikeSpec.h"    // nogncheck
#include "third_party/skia/src/core/SkTextBlobPriv.h"  // nogncheck

namespace impeller {

static Font ToFont(const SkTextBlobRunIterator& run, AxisAlignment alignment) {
  auto& font = run.font();
  auto typeface = std::make_shared<TypefaceSkia>(font.refTypeface());

  SkFontMetrics sk_metrics;
  font.getMetrics(&sk_metrics);

  Font::Metrics metrics;
  metrics.point_size = font.getSize();
  metrics.embolden = font.isEmbolden();
  metrics.skewX = font.getSkewX();
  metrics.scaleX = font.getScaleX();

  return Font{std::move(typeface), metrics, alignment};
}

static Rect ToRect(const SkRect& rect) {
  return Rect::MakeLTRB(rect.fLeft, rect.fTop, rect.fRight, rect.fBottom);
}

namespace {

// Minimal big-endian OpenType readers for the COLR (v0) and CPAL tables.
// iOS uses the CoreText backend, which rasterizes the *composite* color glyph
// to a bitmap and never exposes COLR layers as vector data. But COLRv0 layers
// are just references to ordinary glyphs whose outlines CoreText *does*
// provide, so we parse the tables ourselves and render each layer as a colored
// path.
uint16_t ReadU16(const uint8_t* p) {
  return static_cast<uint16_t>((static_cast<uint16_t>(p[0]) << 8) | p[1]);
}
uint32_t ReadU32(const uint8_t* p) {
  return (static_cast<uint32_t>(p[0]) << 24) |
         (static_cast<uint32_t>(p[1]) << 16) |
         (static_cast<uint32_t>(p[2]) << 8) | static_cast<uint32_t>(p[3]);
}

// The first (index 0) CPAL palette, as impeller Colors. Empty if unavailable.
std::vector<Color> ParseCpalPalette0(const sk_sp<SkData>& data) {
  if (!data || data->size() < 14) {
    return {};
  }
  const uint8_t* b = data->bytes();
  const size_t size = data->size();
  uint16_t num_palette_entries = ReadU16(b + 2);
  uint16_t num_palettes = ReadU16(b + 4);
  uint16_t num_color_records = ReadU16(b + 6);
  uint32_t color_records_offset = ReadU32(b + 8);
  if (num_palettes == 0) {
    return {};
  }
  // colorRecordIndices[] starts at offset 12 (u16 each); palette 0 is the
  // first.
  uint16_t first_record = ReadU16(b + 12);
  std::vector<Color> colors;
  colors.reserve(num_palette_entries);
  for (uint16_t i = 0; i < num_palette_entries; i++) {
    uint32_t rec = first_record + i;
    if (rec >= num_color_records) {
      break;
    }
    size_t off = color_records_offset + static_cast<size_t>(rec) * 4;
    if (off + 4 > size) {
      break;
    }
    // CPAL color records are stored BGRA, 8 bits each.
    Scalar blue = b[off + 0] / 255.0f;
    Scalar green = b[off + 1] / 255.0f;
    Scalar red = b[off + 2] / 255.0f;
    Scalar alpha = b[off + 3] / 255.0f;
    colors.push_back(Color(red, green, blue, alpha));
  }
  return colors;
}

// A parsed COLR (v0) table header; layer records are read on demand.
struct ColrV0 {
  const uint8_t* data = nullptr;
  size_t size = 0;
  uint16_t num_base_glyph_records = 0;
  uint32_t base_glyph_records_offset = 0;
  uint32_t layer_records_offset = 0;
  uint16_t num_layer_records = 0;
  bool ok = false;
};

ColrV0 ParseColrV0(const sk_sp<SkData>& data) {
  ColrV0 c;
  if (!data || data->size() < 14) {
    return c;
  }
  const uint8_t* b = data->bytes();
  // Only the v0 base/layer records are handled (v1 keeps them at the same
  // offsets, so v1 fonts still get their v0 layers rendered).
  c.data = b;
  c.size = data->size();
  c.num_base_glyph_records = ReadU16(b + 2);
  c.base_glyph_records_offset = ReadU32(b + 4);
  c.layer_records_offset = ReadU32(b + 8);
  c.num_layer_records = ReadU16(b + 12);
  c.ok = true;
  return c;
}

// Binary-search the (glyphID-sorted) base glyph records for `glyph_id`.
bool FindColrLayers(const ColrV0& c,
                    uint16_t glyph_id,
                    uint16_t* first_layer,
                    uint16_t* num_layers) {
  if (!c.ok || c.num_base_glyph_records == 0) {
    return false;
  }
  int lo = 0;
  int hi = static_cast<int>(c.num_base_glyph_records) - 1;
  while (lo <= hi) {
    int mid = (lo + hi) / 2;
    size_t off = c.base_glyph_records_offset + static_cast<size_t>(mid) * 6;
    if (off + 6 > c.size) {
      return false;
    }
    uint16_t gid = ReadU16(c.data + off);
    if (gid == glyph_id) {
      *first_layer = ReadU16(c.data + off + 2);
      *num_layers = ReadU16(c.data + off + 4);
      return true;
    }
    if (gid < glyph_id) {
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return false;
}

bool GetColrLayerRecord(const ColrV0& c,
                        uint16_t layer_index,
                        uint16_t* glyph_id,
                        uint16_t* palette_index) {
  if (layer_index >= c.num_layer_records) {
    return false;
  }
  size_t off = c.layer_records_offset + static_cast<size_t>(layer_index) * 4;
  if (off + 4 > c.size) {
    return false;
  }
  *glyph_id = ReadU16(c.data + off);
  *palette_index = ReadU16(c.data + off + 2);
  return true;
}

// Appends `glyph_id`'s outline (translated to `pos`) as a layer filled with
// `color` (or the foreground color when `use_foreground`).
void AppendGlyphPath(SkBulkGlyphMetricsAndPaths& paths,
                     SkGlyphID glyph_id,
                     SkPoint pos,
                     Color color,
                     bool use_foreground,
                     std::vector<ColorGlyphLayer>* out) {
  SkSpan<const SkGlyph*> span = paths.glyphs(SkSpan(&glyph_id, 1));
  if (span.empty() || span[0] == nullptr) {
    return;
  }
  const SkPath* path = span[0]->path();
  if (path == nullptr || path->isEmpty()) {
    return;
  }
  SkPath moved = path->makeTransform(SkMatrix::Translate(pos.x(), pos.y()));
  ColorGlyphLayer layer;
  layer.path = flutter::DlPath(moved);
  layer.color = color;
  layer.use_foreground_color = use_foreground;
  out->push_back(std::move(layer));
}

}  // namespace

std::shared_ptr<TextFrame> MakeTextFrameFromTextBlobSkia(
    const sk_sp<SkTextBlob>& blob) {
  bool has_color = false;
  std::vector<TextRun> runs;
  for (SkTextBlobRunIterator run(blob.get()); !run.done(); run.next()) {
    SkStrikeSpec strikeSpec = SkStrikeSpec::MakeWithNoDevice(run.font());
    SkBulkGlyphMetricsAndPaths paths{strikeSpec};
    SkSpan<const SkGlyph*> glyphs =
        paths.glyphs(SkSpan(run.glyphs(), run.glyphCount()));

    for (const auto& glyph : glyphs) {
      has_color |= glyph->isColor();
    }

    AxisAlignment alignment = AxisAlignment::kNone;
    if (run.font().isSubpixel() && run.font().isBaselineSnap() && !has_color) {
      alignment = AxisAlignment::kX;
    }

    switch (run.positioning()) {
      case SkTextBlobRunIterator::kFull_Positioning: {
        std::vector<TextRun::GlyphPosition> positions;
        positions.reserve(run.glyphCount());
        for (auto i = 0u; i < run.glyphCount(); i++) {
          // kFull_Positioning has two scalars per glyph.
          const SkPoint* glyph_points = run.points();
          const SkPoint* point = glyph_points + i;
          Glyph::Type type =
              glyphs[i]->isColor() ? Glyph::Type::kBitmap : Glyph::Type::kPath;
          positions.emplace_back(TextRun::GlyphPosition{
              Glyph{glyphs[i]->getGlyphID(), type}, Point{
                                                        point->x(),
                                                        point->y(),
                                                    }});
        }
        TextRun text_run(ToFont(run, alignment), positions);
        runs.emplace_back(text_run);
        break;
      }
      default:
        FML_DLOG(ERROR) << "Unimplemented.";
        continue;
    }
  }
  return std::make_shared<TextFrame>(
      runs, ToRect(blob->bounds()), has_color,
      [blob]() -> fml::StatusOr<flutter::DlPath> {
        SkPath path = skia::textlayout::Paragraph::GetPath(blob.get());
        if (path.isEmpty()) {
          return fml::Status(fml::StatusCode::kCancelled, "No path available");
        }
        SkPath transformed = path.makeTransform(
            SkMatrix::Translate(blob->bounds().left(), blob->bounds().top()));
        return flutter::DlPath(transformed);
      },
      [blob]() -> std::vector<ColorGlyphLayer> {
        // Build per-layer colored vector paths for every glyph in the frame so
        // COLR text can be drawn as paths (crisp at any scale) instead of the
        // color glyph atlas. See ColorGlyphLayer / TextFrame::GetColorPaths.
        std::vector<ColorGlyphLayer> layers;
        for (SkTextBlobRunIterator run(blob.get()); !run.done(); run.next()) {
          if (run.positioning() != SkTextBlobRunIterator::kFull_Positioning) {
            continue;
          }
          SkTypeface* typeface = run.font().getTypeface();
          if (typeface == nullptr) {
            continue;
          }
          sk_sp<SkData> colr_data =
              typeface->copyTableData(SkSetFourByteTag('C', 'O', 'L', 'R'));
          sk_sp<SkData> cpal_data =
              typeface->copyTableData(SkSetFourByteTag('C', 'P', 'A', 'L'));
          ColrV0 colr = ParseColrV0(colr_data);
          std::vector<Color> palette = ParseCpalPalette0(cpal_data);

          // Fetch outlines unhinted with linear metrics: these paths are
          // rendered as scalable vectors, and grid-fitting (e.g. FreeType on
          // Android) displaces the base glyph and its color layers by
          // different amounts, which reads as a visible misalignment once
          // zoomed. (CoreText never hints, so this is a no-op on iOS/macOS.)
          SkFont path_font = run.font();
          path_font.setHinting(SkFontHinting::kNone);
          path_font.setLinearMetrics(true);
          SkStrikeSpec strike_spec = SkStrikeSpec::MakeWithNoDevice(path_font);
          SkBulkGlyphMetricsAndPaths paths{strike_spec};

          const SkGlyphID* glyph_ids = run.glyphs();
          const SkPoint* points = run.points();
          for (uint32_t i = 0; i < run.glyphCount(); i++) {
            SkGlyphID gid = glyph_ids[i];
            SkPoint pos = points[i];
            uint16_t first_layer = 0;
            uint16_t num_layers = 0;
            bool found =
                colr.ok && FindColrLayers(colr, gid, &first_layer, &num_layers);
            if (found && num_layers > 0) {
              for (uint16_t l = 0; l < num_layers; l++) {
                uint16_t layer_gid = 0;
                uint16_t palette_index = 0;
                if (!GetColrLayerRecord(colr, first_layer + l, &layer_gid,
                                        &palette_index)) {
                  continue;
                }
                bool use_foreground =
                    palette_index == 0xFFFF || palette_index >= palette.size();
                Color color =
                    use_foreground ? Color::Black() : palette[palette_index];
                AppendGlyphPath(paths, layer_gid, pos, color, use_foreground,
                                &layers);
              }
            } else {
              // Non-color glyph inside a color frame: draw its own outline in
              // the foreground (paint) color.
              AppendGlyphPath(paths, gid, pos, Color::Black(),
                              /*use_foreground=*/true, &layers);
            }
          }
        }
        return layers;
      });
}

}  // namespace impeller
