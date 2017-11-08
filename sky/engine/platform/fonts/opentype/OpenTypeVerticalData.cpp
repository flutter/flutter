/*
 * Copyright (C) 2012 Koji Ishii <kojiishi@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "flutter/sky/engine/platform/fonts/opentype/OpenTypeVerticalData.h"

#include "flutter/sky/engine/platform/SharedBuffer.h"
#include "flutter/sky/engine/platform/fonts/GlyphPage.h"
#include "flutter/sky/engine/platform/fonts/SimpleFontData.h"
#include "flutter/sky/engine/platform/fonts/opentype/OpenTypeTypes.h"
#include "flutter/sky/engine/platform/geometry/FloatRect.h"
#include "flutter/sky/engine/wtf/RefPtr.h"

namespace blink {
namespace OpenType {

const uint32_t HheaTag = OT_MAKE_TAG('h', 'h', 'e', 'a');
const uint32_t HmtxTag = OT_MAKE_TAG('h', 'm', 't', 'x');
const uint32_t VheaTag = OT_MAKE_TAG('v', 'h', 'e', 'a');
const uint32_t VmtxTag = OT_MAKE_TAG('v', 'm', 't', 'x');
const uint32_t VORGTag = OT_MAKE_TAG('V', 'O', 'R', 'G');

#pragma pack(1)

struct HheaTable {
  OpenType::Fixed version;
  OpenType::Int16 ascender;
  OpenType::Int16 descender;
  OpenType::Int16 lineGap;
  OpenType::Int16 advanceWidthMax;
  OpenType::Int16 minLeftSideBearing;
  OpenType::Int16 minRightSideBearing;
  OpenType::Int16 xMaxExtent;
  OpenType::Int16 caretSlopeRise;
  OpenType::Int16 caretSlopeRun;
  OpenType::Int16 caretOffset;
  OpenType::Int16 reserved[4];
  OpenType::Int16 metricDataFormat;
  OpenType::UInt16 numberOfHMetrics;
};

struct VheaTable {
  OpenType::Fixed version;
  OpenType::Int16 ascent;
  OpenType::Int16 descent;
  OpenType::Int16 lineGap;
  OpenType::Int16 advanceHeightMax;
  OpenType::Int16 minTopSideBearing;
  OpenType::Int16 minBottomSideBearing;
  OpenType::Int16 yMaxExtent;
  OpenType::Int16 caretSlopeRise;
  OpenType::Int16 caretSlopeRun;
  OpenType::Int16 caretOffset;
  OpenType::Int16 reserved[4];
  OpenType::Int16 metricDataFormat;
  OpenType::UInt16 numOfLongVerMetrics;
};

struct HmtxTable {
  struct Entry {
    OpenType::UInt16 advanceWidth;
    OpenType::Int16 lsb;
  } entries[1];
};

struct VmtxTable {
  struct Entry {
    OpenType::UInt16 advanceHeight;
    OpenType::Int16 topSideBearing;
  } entries[1];
};

struct VORGTable {
  OpenType::UInt16 majorVersion;
  OpenType::UInt16 minorVersion;
  OpenType::Int16 defaultVertOriginY;
  OpenType::UInt16 numVertOriginYMetrics;
  struct VertOriginYMetrics {
    OpenType::UInt16 glyphIndex;
    OpenType::Int16 vertOriginY;
  } vertOriginYMetrics[1];

  size_t requiredSize() const {
    return sizeof(*this) +
           sizeof(VertOriginYMetrics) * (numVertOriginYMetrics - 1);
  }
};

#pragma pack()

}  // namespace OpenType

OpenTypeVerticalData::OpenTypeVerticalData(const FontPlatformData& platformData)
    : m_defaultVertOriginY(0) {
  loadMetrics(platformData);
}

void OpenTypeVerticalData::loadMetrics(const FontPlatformData& platformData) {
  // Load hhea and hmtx to get x-component of vertical origins.
  // If these tables are missing, it's not an OpenType font.
  RefPtr<SharedBuffer> buffer = platformData.openTypeTable(OpenType::HheaTag);
  const OpenType::HheaTable* hhea =
      OpenType::validateTable<OpenType::HheaTable>(buffer);
  if (!hhea)
    return;
  uint16_t countHmtxEntries = hhea->numberOfHMetrics;
  if (!countHmtxEntries) {
    WTF_LOG_ERROR("Invalid numberOfHMetrics");
    return;
  }

  buffer = platformData.openTypeTable(OpenType::HmtxTag);
  const OpenType::HmtxTable* hmtx =
      OpenType::validateTable<OpenType::HmtxTable>(buffer, countHmtxEntries);
  if (!hmtx) {
    WTF_LOG_ERROR("hhea exists but hmtx does not (or broken)");
    return;
  }
  m_advanceWidths.resize(countHmtxEntries);
  for (uint16_t i = 0; i < countHmtxEntries; ++i)
    m_advanceWidths[i] = hmtx->entries[i].advanceWidth;

  // Load vhea first. This table is required for fonts that support vertical
  // flow.
  buffer = platformData.openTypeTable(OpenType::VheaTag);
  const OpenType::VheaTable* vhea =
      OpenType::validateTable<OpenType::VheaTable>(buffer);
  if (!vhea)
    return;
  uint16_t countVmtxEntries = vhea->numOfLongVerMetrics;
  if (!countVmtxEntries) {
    WTF_LOG_ERROR("Invalid numOfLongVerMetrics");
    return;
  }

  // Load VORG. This table is optional.
  buffer = platformData.openTypeTable(OpenType::VORGTag);
  const OpenType::VORGTable* vorg =
      OpenType::validateTable<OpenType::VORGTable>(buffer);
  if (vorg && buffer->size() >= vorg->requiredSize()) {
    m_defaultVertOriginY = vorg->defaultVertOriginY;
    uint16_t countVertOriginYMetrics = vorg->numVertOriginYMetrics;
    if (!countVertOriginYMetrics) {
      // Add one entry so that hasVORG() becomes true
      m_vertOriginY.set(0, m_defaultVertOriginY);
    } else {
      for (uint16_t i = 0; i < countVertOriginYMetrics; ++i) {
        const OpenType::VORGTable::VertOriginYMetrics& metrics =
            vorg->vertOriginYMetrics[i];
        m_vertOriginY.set(metrics.glyphIndex, metrics.vertOriginY);
      }
    }
  }

  // Load vmtx then. This table is required for fonts that support vertical
  // flow.
  buffer = platformData.openTypeTable(OpenType::VmtxTag);
  const OpenType::VmtxTable* vmtx =
      OpenType::validateTable<OpenType::VmtxTable>(buffer, countVmtxEntries);
  if (!vmtx) {
    WTF_LOG_ERROR("vhea exists but vmtx does not (or broken)");
    return;
  }
  m_advanceHeights.resize(countVmtxEntries);
  for (uint16_t i = 0; i < countVmtxEntries; ++i)
    m_advanceHeights[i] = vmtx->entries[i].advanceHeight;

  // VORG is preferred way to calculate vertical origin than vmtx,
  // so load topSideBearing from vmtx only if VORG is missing.
  if (hasVORG())
    return;

  size_t sizeExtra =
      buffer->size() - sizeof(OpenType::VmtxTable::Entry) * countVmtxEntries;
  if (sizeExtra % sizeof(OpenType::Int16)) {
    WTF_LOG_ERROR("vmtx has incorrect tsb count");
    return;
  }
  size_t countTopSideBearings =
      countVmtxEntries + sizeExtra / sizeof(OpenType::Int16);
  m_topSideBearings.resize(countTopSideBearings);
  size_t i;
  for (i = 0; i < countVmtxEntries; ++i)
    m_topSideBearings[i] = vmtx->entries[i].topSideBearing;
  if (i < countTopSideBearings) {
    const OpenType::Int16* pTopSideBearingsExtra =
        reinterpret_cast<const OpenType::Int16*>(
            &vmtx->entries[countVmtxEntries]);
    for (; i < countTopSideBearings; ++i, ++pTopSideBearingsExtra)
      m_topSideBearings[i] = *pTopSideBearingsExtra;
  }
}

float OpenTypeVerticalData::advanceHeight(const SimpleFontData* font,
                                          Glyph glyph) const {
  size_t countHeights = m_advanceHeights.size();
  if (countHeights) {
    uint16_t advanceFUnit =
        m_advanceHeights[glyph < countHeights ? glyph : countHeights - 1];
    float advance = advanceFUnit * font->sizePerUnit();
    return advance;
  }

  // No vertical info in the font file; use height as advance.
  return font->fontMetrics().height();
}

void OpenTypeVerticalData::getVerticalTranslationsForGlyphs(
    const SimpleFontData* font,
    const Glyph* glyphs,
    size_t count,
    float* outXYArray) const {
  size_t countWidths = m_advanceWidths.size();
  ASSERT(countWidths > 0);
  const FontMetrics& metrics = font->fontMetrics();
  float sizePerUnit = font->sizePerUnit();
  float ascent = metrics.ascent();
  bool useVORG = hasVORG();
  size_t countTopSideBearings = m_topSideBearings.size();
  float defaultVertOriginY = std::numeric_limits<float>::quiet_NaN();
  for (float* end = &(outXYArray[count * 2]); outXYArray != end;
       ++glyphs, outXYArray += 2) {
    Glyph glyph = *glyphs;
    uint16_t widthFUnit =
        m_advanceWidths[glyph < countWidths ? glyph : countWidths - 1];
    float width = widthFUnit * sizePerUnit;
    outXYArray[0] = -width / 2;

    // For Y, try VORG first.
    if (useVORG) {
      if (glyph) {
        int16_t vertOriginYFUnit = m_vertOriginY.get(glyph);
        if (vertOriginYFUnit) {
          outXYArray[1] = -vertOriginYFUnit * sizePerUnit;
          continue;
        }
      }
      if (std::isnan(defaultVertOriginY))
        defaultVertOriginY = -m_defaultVertOriginY * sizePerUnit;
      outXYArray[1] = defaultVertOriginY;
      continue;
    }

    // If no VORG, try vmtx next.
    if (countTopSideBearings) {
      int16_t topSideBearingFUnit =
          m_topSideBearings[glyph < countTopSideBearings
                                ? glyph
                                : countTopSideBearings - 1];
      float topSideBearing = topSideBearingFUnit * sizePerUnit;
      FloatRect bounds = font->boundsForGlyph(glyph);
      outXYArray[1] = bounds.y() - topSideBearing;
      continue;
    }

    // No vertical info in the font file; use ascent as vertical origin.
    outXYArray[1] = -ascent;
  }
}

}  // namespace blink
