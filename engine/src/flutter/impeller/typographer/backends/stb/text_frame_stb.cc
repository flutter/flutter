// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/typographer/backends/stb/text_frame_stb.h"

#include "impeller/typographer/font.h"

namespace impeller {

TextFrame MakeTextFrameSTB(const std::shared_ptr<TypefaceSTB>& typeface_stb,
                           Font::Metrics metrics,
                           const std::string& text) {
  TextRun run(Font(typeface_stb, metrics));

  // Shape the text run using STB. The glyph positions could also be resolved
  // using a more advanced text shaper such as harfbuzz.

  float scale = stbtt_ScaleForPixelHeight(
      typeface_stb->GetFontInfo(),
      metrics.point_size * TypefaceSTB::kPointsToPixels);

  int ascent, descent, line_gap;
  stbtt_GetFontVMetrics(typeface_stb->GetFontInfo(), &ascent, &descent,
                        &line_gap);
  ascent = std::round(ascent * scale);
  descent = std::round(descent * scale);

  float x = 0;
  for (size_t i = 0; i < text.size(); i++) {
    int glyph_index =
        stbtt_FindGlyphIndex(typeface_stb->GetFontInfo(), text[i]);

    int x0, y0, x1, y1;
    stbtt_GetGlyphBitmapBox(typeface_stb->GetFontInfo(), glyph_index, scale,
                            scale, &x0, &y0, &x1, &y1);
    float y = y0;

    int advance_width;
    int left_side_bearing;
    stbtt_GetGlyphHMetrics(typeface_stb->GetFontInfo(), glyph_index,
                           &advance_width, &left_side_bearing);

    Glyph glyph(glyph_index, Glyph::Type::kPath,
                Rect::MakeXYWH(0, 0, x1 - x0, y1 - y0));
    run.AddGlyph(glyph, {x + (left_side_bearing * scale), y});

    if (i + 1 < text.size()) {
      int kerning = stbtt_GetCodepointKernAdvance(typeface_stb->GetFontInfo(),
                                                  text[i], text[i + 1]);
      x += std::round((advance_width + kerning) * scale);
    }
  }

  std::optional<Rect> result;
  for (const auto& glyph_position : run.GetGlyphPositions()) {
    Rect glyph_rect =
        Rect(glyph_position.position + glyph_position.glyph.bounds.origin,
             glyph_position.glyph.bounds.size);
    result = result.has_value() ? result->Union(glyph_rect) : glyph_rect;
  }

  std::vector<TextRun> runs = {run};
  return TextFrame(runs, result.value_or(Rect::MakeLTRB(0, 0, 0, 0)), false);
}

}  // namespace impeller
