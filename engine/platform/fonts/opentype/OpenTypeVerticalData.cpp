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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#if ENABLE(OPENTYPE_VERTICAL)
#include "platform/fonts/opentype/OpenTypeVerticalData.h"

#include "platform/SharedBuffer.h"
#include "platform/fonts/SimpleFontData.h"
#include "platform/fonts/GlyphPage.h"
#include "platform/fonts/opentype/OpenTypeTypes.h"
#include "platform/geometry/FloatRect.h"
#include "wtf/RefPtr.h"

namespace blink {
namespace OpenType {

const uint32_t GSUBTag = OT_MAKE_TAG('G', 'S', 'U', 'B');
const uint32_t HheaTag = OT_MAKE_TAG('h', 'h', 'e', 'a');
const uint32_t HmtxTag = OT_MAKE_TAG('h', 'm', 't', 'x');
const uint32_t VheaTag = OT_MAKE_TAG('v', 'h', 'e', 'a');
const uint32_t VmtxTag = OT_MAKE_TAG('v', 'm', 't', 'x');
const uint32_t VORGTag = OT_MAKE_TAG('V', 'O', 'R', 'G');

const uint32_t DefaultScriptTag = OT_MAKE_TAG('D', 'F', 'L', 'T');

const uint32_t VertFeatureTag = OT_MAKE_TAG('v', 'e', 'r', 't');

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

    size_t requiredSize() const { return sizeof(*this) + sizeof(VertOriginYMetrics) * (numVertOriginYMetrics - 1); }
};

struct CoverageTable : TableBase {
    OpenType::UInt16 coverageFormat;
};

struct Coverage1Table : CoverageTable {
    OpenType::UInt16 glyphCount;
    OpenType::GlyphID glyphArray[1];
};

struct Coverage2Table : CoverageTable {
    OpenType::UInt16 rangeCount;
    struct RangeRecord {
        OpenType::GlyphID start;
        OpenType::GlyphID end;
        OpenType::UInt16 startCoverageIndex;
    } ranges[1];
};

struct SubstitutionSubTable : TableBase {
    OpenType::UInt16 substFormat;
    OpenType::Offset coverageOffset;

    const CoverageTable* coverage(const SharedBuffer& buffer) const { return validateOffset<CoverageTable>(buffer, coverageOffset); }
};

struct SingleSubstitution2SubTable : SubstitutionSubTable {
    OpenType::UInt16 glyphCount;
    OpenType::GlyphID substitute[1];
};

struct LookupTable : TableBase {
    OpenType::UInt16 lookupType;
    OpenType::UInt16 lookupFlag;
    OpenType::UInt16 subTableCount;
    OpenType::Offset subTableOffsets[1];
    // OpenType::UInt16 markFilteringSet; this field comes after variable length, so offset is determined dynamically.

    bool getSubstitutions(HashMap<Glyph, Glyph>* map, const SharedBuffer& buffer) const
    {
        uint16_t countSubTable = subTableCount;
        if (!isValidEnd(buffer, &subTableOffsets[countSubTable]))
            return false;
        if (lookupType != 1) // "Single Substitution Subtable" is all what we support
            return false;
        for (uint16_t i = 0; i < countSubTable; ++i) {
            const SubstitutionSubTable* substitution = validateOffset<SubstitutionSubTable>(buffer, subTableOffsets[i]);
            if (!substitution)
                return false;
            const CoverageTable* coverage = substitution->coverage(buffer);
            if (!coverage)
                return false;
            if (substitution->substFormat != 2) // "Single Substitution Format 2" is all what we support
                return false;
            const SingleSubstitution2SubTable* singleSubstitution2 = validatePtr<SingleSubstitution2SubTable>(buffer, substitution);
            if (!singleSubstitution2)
                return false;
            uint16_t countTo = singleSubstitution2->glyphCount;
            if (!isValidEnd(buffer, &singleSubstitution2->substitute[countTo]))
                return false;
            switch (coverage->coverageFormat) {
            case 1: { // Coverage Format 1 (e.g., MS Gothic)
                const Coverage1Table* coverage1 = validatePtr<Coverage1Table>(buffer, coverage);
                if (!coverage1)
                    return false;
                uint16_t countFrom = coverage1->glyphCount;
                if (!isValidEnd(buffer, &coverage1->glyphArray[countFrom]) || countTo != countFrom)
                    return false;
                for (uint16_t i = 0; i < countTo; ++i)
                    map->set(coverage1->glyphArray[i], singleSubstitution2->substitute[i]);
                break;
            }
            case 2: { // Coverage Format 2 (e.g., Adobe Kozuka Gothic)
                const Coverage2Table* coverage2 = validatePtr<Coverage2Table>(buffer, coverage);
                if (!coverage2)
                    return false;
                uint16_t countRange = coverage2->rangeCount;
                if (!isValidEnd(buffer, &coverage2->ranges[countRange]))
                    return false;
                for (uint16_t i = 0, indexTo = 0; i < countRange; ++i) {
                    uint16_t from = coverage2->ranges[i].start;
                    uint16_t fromEnd = coverage2->ranges[i].end + 1; // OpenType "end" is inclusive
                    if (indexTo + (fromEnd - from) > countTo)
                        return false;
                    for (; from != fromEnd; ++from, ++indexTo)
                        map->set(from, singleSubstitution2->substitute[indexTo]);
                }
                break;
            }
            default:
                return false;
            }
        }
        return true;
    }
};

struct LookupList : TableBase {
    OpenType::UInt16 lookupCount;
    OpenType::Offset lookupOffsets[1];

    const LookupTable* lookup(uint16_t index, const SharedBuffer& buffer) const
    {
        uint16_t count = lookupCount;
        if (index >= count || !isValidEnd(buffer, &lookupOffsets[count]))
            return 0;
        return validateOffset<LookupTable>(buffer, lookupOffsets[index]);
    }
};

struct FeatureTable : TableBase {
    OpenType::Offset featureParams;
    OpenType::UInt16 lookupCount;
    OpenType::UInt16 lookupListIndex[1];

    bool getGlyphSubstitutions(const LookupList* lookups, HashMap<Glyph, Glyph>* map, const SharedBuffer& buffer) const
    {
        uint16_t count = lookupCount;
        if (!isValidEnd(buffer, &lookupListIndex[count]))
            return false;
        for (uint16_t i = 0; i < count; ++i) {
            const LookupTable* lookup = lookups->lookup(lookupListIndex[i], buffer);
            if (!lookup || !lookup->getSubstitutions(map, buffer))
                return false;
        }
        return true;
    }
};

struct FeatureList : TableBase {
    OpenType::UInt16 featureCount;
    struct FeatureRecord {
        OpenType::Tag featureTag;
        OpenType::Offset featureOffset;
    } features[1];

    const FeatureTable* feature(uint16_t index, OpenType::Tag tag, const SharedBuffer& buffer) const
    {
        uint16_t count = featureCount;
        if (index >= count || !isValidEnd(buffer, &features[count]))
            return 0;
        if (features[index].featureTag == tag)
            return validateOffset<FeatureTable>(buffer, features[index].featureOffset);
        return 0;
    }

    const FeatureTable* findFeature(OpenType::Tag tag, const SharedBuffer& buffer) const
    {
        for (uint16_t i = 0; i < featureCount; ++i) {
            if (isValidEnd(buffer, &features[i]) && features[i].featureTag == tag)
                return validateOffset<FeatureTable>(buffer, features[i].featureOffset);
        }
        return 0;
    }
};

struct LangSysTable : TableBase {
    OpenType::Offset lookupOrder;
    OpenType::UInt16 reqFeatureIndex;
    OpenType::UInt16 featureCount;
    OpenType::UInt16 featureIndex[1];

    const FeatureTable* feature(OpenType::Tag featureTag, const FeatureList* features, const SharedBuffer& buffer) const
    {
        uint16_t count = featureCount;
        if (!isValidEnd(buffer, &featureIndex[count]))
            return 0;
        for (uint16_t i = 0; i < count; ++i) {
            const FeatureTable* featureTable = features->feature(featureIndex[i], featureTag, buffer);
            if (featureTable)
                return featureTable;
        }
        return 0;
    }
};

struct ScriptTable : TableBase {
    OpenType::Offset defaultLangSysOffset;
    OpenType::UInt16 langSysCount;
    struct LangSysRecord {
        OpenType::Tag langSysTag;
        OpenType::Offset langSysOffset;
    } langSysRecords[1];

    const LangSysTable* defaultLangSys(const SharedBuffer& buffer) const
    {
        uint16_t count = langSysCount;
        if (!isValidEnd(buffer, &langSysRecords[count]))
            return 0;
        uint16_t offset = defaultLangSysOffset;
        if (offset)
            return validateOffset<LangSysTable>(buffer, offset);
        if (count)
            return validateOffset<LangSysTable>(buffer, langSysRecords[0].langSysOffset);
        return 0;
    }
};

struct ScriptList : TableBase {
    OpenType::UInt16 scriptCount;
    struct ScriptRecord {
        OpenType::Tag scriptTag;
        OpenType::Offset scriptOffset;
    } scripts[1];

    const ScriptTable* script(OpenType::Tag tag, const SharedBuffer& buffer) const
    {
        uint16_t count = scriptCount;
        if (!isValidEnd(buffer, &scripts[count]))
            return 0;
        for (uint16_t i = 0; i < count; ++i) {
            if (scripts[i].scriptTag == tag)
                return validateOffset<ScriptTable>(buffer, scripts[i].scriptOffset);
        }
        return 0;
    }

    const ScriptTable* defaultScript(const SharedBuffer& buffer) const
    {
        uint16_t count = scriptCount;
        if (!count || !isValidEnd(buffer, &scripts[count]))
            return 0;
        const ScriptTable* scriptOfDefaultTag = script(OpenType::DefaultScriptTag, buffer);
        if (scriptOfDefaultTag)
            return scriptOfDefaultTag;
        return validateOffset<ScriptTable>(buffer, scripts[0].scriptOffset);
    }

    const LangSysTable* defaultLangSys(const SharedBuffer& buffer) const
    {
        const ScriptTable* scriptTable = defaultScript(buffer);
        if (!scriptTable)
            return 0;
        return scriptTable->defaultLangSys(buffer);
    }
};

struct GSUBTable : TableBase {
    OpenType::Fixed version;
    OpenType::Offset scriptListOffset;
    OpenType::Offset featureListOffset;
    OpenType::Offset lookupListOffset;

    const ScriptList* scriptList(const SharedBuffer& buffer) const { return validateOffset<ScriptList>(buffer, scriptListOffset); }
    const FeatureList* featureList(const SharedBuffer& buffer) const { return validateOffset<FeatureList>(buffer, featureListOffset); }
    const LookupList* lookupList(const SharedBuffer& buffer) const { return validateOffset<LookupList>(buffer, lookupListOffset); }

    const LangSysTable* defaultLangSys(const SharedBuffer& buffer) const
    {
        const ScriptList* scripts = scriptList(buffer);
        if (!scripts)
            return 0;
        return scripts->defaultLangSys(buffer);
    }

    const FeatureTable* feature(OpenType::Tag featureTag, const SharedBuffer& buffer) const
    {
        const LangSysTable* langSys = defaultLangSys(buffer);
        const FeatureList* features = featureList(buffer);
        if (!features)
            return 0;
        const FeatureTable* feature = 0;
        if (langSys)
            feature = langSys->feature(featureTag, features, buffer);
        if (!feature) {
            // If the font has no langSys table, or has no default script and the first script doesn't
            // have the requested feature, then use the first matching feature directly.
            feature = features->findFeature(featureTag, buffer);
        }
        return feature;
    }

    bool getVerticalGlyphSubstitutions(HashMap<Glyph, Glyph>* map, const SharedBuffer& buffer) const
    {
        const FeatureTable* verticalFeatureTable = feature(OpenType::VertFeatureTag, buffer);
        if (!verticalFeatureTable)
            return false;
        const LookupList* lookups = lookupList(buffer);
        return lookups && verticalFeatureTable->getGlyphSubstitutions(lookups, map, buffer);
    }
};

#pragma pack()

} // namespace OpenType

OpenTypeVerticalData::OpenTypeVerticalData(const FontPlatformData& platformData)
    : m_defaultVertOriginY(0)
{
    loadMetrics(platformData);
    loadVerticalGlyphSubstitutions(platformData);
}

void OpenTypeVerticalData::loadMetrics(const FontPlatformData& platformData)
{
    // Load hhea and hmtx to get x-component of vertical origins.
    // If these tables are missing, it's not an OpenType font.
    RefPtr<SharedBuffer> buffer = platformData.openTypeTable(OpenType::HheaTag);
    const OpenType::HheaTable* hhea = OpenType::validateTable<OpenType::HheaTable>(buffer);
    if (!hhea)
        return;
    uint16_t countHmtxEntries = hhea->numberOfHMetrics;
    if (!countHmtxEntries) {
        WTF_LOG_ERROR("Invalid numberOfHMetrics");
        return;
    }

    buffer = platformData.openTypeTable(OpenType::HmtxTag);
    const OpenType::HmtxTable* hmtx = OpenType::validateTable<OpenType::HmtxTable>(buffer, countHmtxEntries);
    if (!hmtx) {
        WTF_LOG_ERROR("hhea exists but hmtx does not (or broken)");
        return;
    }
    m_advanceWidths.resize(countHmtxEntries);
    for (uint16_t i = 0; i < countHmtxEntries; ++i)
        m_advanceWidths[i] = hmtx->entries[i].advanceWidth;

    // Load vhea first. This table is required for fonts that support vertical flow.
    buffer = platformData.openTypeTable(OpenType::VheaTag);
    const OpenType::VheaTable* vhea = OpenType::validateTable<OpenType::VheaTable>(buffer);
    if (!vhea)
        return;
    uint16_t countVmtxEntries = vhea->numOfLongVerMetrics;
    if (!countVmtxEntries) {
        WTF_LOG_ERROR("Invalid numOfLongVerMetrics");
        return;
    }

    // Load VORG. This table is optional.
    buffer = platformData.openTypeTable(OpenType::VORGTag);
    const OpenType::VORGTable* vorg = OpenType::validateTable<OpenType::VORGTable>(buffer);
    if (vorg && buffer->size() >= vorg->requiredSize()) {
        m_defaultVertOriginY = vorg->defaultVertOriginY;
        uint16_t countVertOriginYMetrics = vorg->numVertOriginYMetrics;
        if (!countVertOriginYMetrics) {
            // Add one entry so that hasVORG() becomes true
            m_vertOriginY.set(0, m_defaultVertOriginY);
        } else {
            for (uint16_t i = 0; i < countVertOriginYMetrics; ++i) {
                const OpenType::VORGTable::VertOriginYMetrics& metrics = vorg->vertOriginYMetrics[i];
                m_vertOriginY.set(metrics.glyphIndex, metrics.vertOriginY);
            }
        }
    }

    // Load vmtx then. This table is required for fonts that support vertical flow.
    buffer = platformData.openTypeTable(OpenType::VmtxTag);
    const OpenType::VmtxTable* vmtx = OpenType::validateTable<OpenType::VmtxTable>(buffer, countVmtxEntries);
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

    size_t sizeExtra = buffer->size() - sizeof(OpenType::VmtxTable::Entry) * countVmtxEntries;
    if (sizeExtra % sizeof(OpenType::Int16)) {
        WTF_LOG_ERROR("vmtx has incorrect tsb count");
        return;
    }
    size_t countTopSideBearings = countVmtxEntries + sizeExtra / sizeof(OpenType::Int16);
    m_topSideBearings.resize(countTopSideBearings);
    size_t i;
    for (i = 0; i < countVmtxEntries; ++i)
        m_topSideBearings[i] = vmtx->entries[i].topSideBearing;
    if (i < countTopSideBearings) {
        const OpenType::Int16* pTopSideBearingsExtra = reinterpret_cast<const OpenType::Int16*>(&vmtx->entries[countVmtxEntries]);
        for (; i < countTopSideBearings; ++i, ++pTopSideBearingsExtra)
            m_topSideBearings[i] = *pTopSideBearingsExtra;
    }
}

void OpenTypeVerticalData::loadVerticalGlyphSubstitutions(const FontPlatformData& platformData)
{
    RefPtr<SharedBuffer> buffer = platformData.openTypeTable(OpenType::GSUBTag);
    const OpenType::GSUBTable* gsub = OpenType::validateTable<OpenType::GSUBTable>(buffer);
    if (gsub)
        gsub->getVerticalGlyphSubstitutions(&m_verticalGlyphMap, *buffer.get());
}

float OpenTypeVerticalData::advanceHeight(const SimpleFontData* font, Glyph glyph) const
{
    size_t countHeights = m_advanceHeights.size();
    if (countHeights) {
        uint16_t advanceFUnit = m_advanceHeights[glyph < countHeights ? glyph : countHeights - 1];
        float advance = advanceFUnit * font->sizePerUnit();
        return advance;
    }

    // No vertical info in the font file; use height as advance.
    return font->fontMetrics().height();
}

void OpenTypeVerticalData::getVerticalTranslationsForGlyphs(const SimpleFontData* font, const Glyph* glyphs, size_t count, float* outXYArray) const
{
    size_t countWidths = m_advanceWidths.size();
    ASSERT(countWidths > 0);
    const FontMetrics& metrics = font->fontMetrics();
    float sizePerUnit = font->sizePerUnit();
    float ascent = metrics.ascent();
    bool useVORG = hasVORG();
    size_t countTopSideBearings = m_topSideBearings.size();
    float defaultVertOriginY = std::numeric_limits<float>::quiet_NaN();
    for (float* end = &(outXYArray[count * 2]); outXYArray != end; ++glyphs, outXYArray += 2) {
        Glyph glyph = *glyphs;
        uint16_t widthFUnit = m_advanceWidths[glyph < countWidths ? glyph : countWidths - 1];
        float width = widthFUnit * sizePerUnit;
        outXYArray[0] = -width / 2;

        // For Y, try VORG first.
        if (useVORG) {
            int16_t vertOriginYFUnit = m_vertOriginY.get(glyph);
            if (vertOriginYFUnit) {
                outXYArray[1] = -vertOriginYFUnit * sizePerUnit;
                continue;
            }
            if (std::isnan(defaultVertOriginY))
                defaultVertOriginY = -m_defaultVertOriginY * sizePerUnit;
            outXYArray[1] = defaultVertOriginY;
            continue;
        }

        // If no VORG, try vmtx next.
        if (countTopSideBearings) {
            int16_t topSideBearingFUnit = m_topSideBearings[glyph < countTopSideBearings ? glyph : countTopSideBearings - 1];
            float topSideBearing = topSideBearingFUnit * sizePerUnit;
            FloatRect bounds = font->boundsForGlyph(glyph);
            outXYArray[1] = bounds.y() - topSideBearing;
            continue;
        }

        // No vertical info in the font file; use ascent as vertical origin.
        outXYArray[1] = -ascent;
    }
}

void OpenTypeVerticalData::substituteWithVerticalGlyphs(const SimpleFontData* font, GlyphPage* glyphPage, unsigned offset, unsigned length) const
{
    const HashMap<Glyph, Glyph>& map = m_verticalGlyphMap;
    if (map.isEmpty())
        return;

    for (unsigned index = offset, end = offset + length; index < end; ++index) {
        GlyphData glyphData = glyphPage->glyphDataForIndex(index);
        if (glyphData.glyph && glyphData.fontData == font) {
            Glyph to = map.get(glyphData.glyph);
            if (to)
                glyphPage->setGlyphDataForIndex(index, to, font);
        }
    }
}

} // namespace blink
#endif // ENABLE(OPENTYPE_VERTICAL)
