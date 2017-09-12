/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2006, 2010, 2011 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

#include "flutter/sky/engine/platform/fonts/Font.h"

#include "flutter/sky/engine/platform/LayoutUnit.h"
#include "flutter/sky/engine/platform/fonts/Character.h"
#include "flutter/sky/engine/platform/fonts/FontCache.h"
#include "flutter/sky/engine/platform/fonts/FontFallbackList.h"
#include "flutter/sky/engine/platform/fonts/FontPlatformFeatures.h"
#include "flutter/sky/engine/platform/fonts/GlyphBuffer.h"
#include "flutter/sky/engine/platform/fonts/GlyphPageTreeNode.h"
#include "flutter/sky/engine/platform/fonts/SimpleFontData.h"
#include "flutter/sky/engine/platform/fonts/WidthIterator.h"
#include "flutter/sky/engine/platform/fonts/harfbuzz/HarfBuzzShaper.h"
#include "flutter/sky/engine/platform/geometry/FloatRect.h"
#include "flutter/sky/engine/platform/graphics/GraphicsContext.h"
#include "flutter/sky/engine/platform/text/TextRun.h"
#include "flutter/sky/engine/wtf/MainThread.h"
#include "flutter/sky/engine/wtf/StdLibExtras.h"
#include "flutter/sky/engine/wtf/unicode/CharacterNames.h"
#include "flutter/sky/engine/wtf/unicode/Unicode.h"

using namespace WTF;
using namespace Unicode;

namespace blink {

CodePath Font::s_codePath = AutoPath;

// ============================================================================================
// Font Implementation (Cross-Platform Portion)
// ============================================================================================

Font::Font() {}

Font::Font(const FontDescription& fd) : m_fontDescription(fd) {}

Font::Font(const Font& other)
    : m_fontDescription(other.m_fontDescription),
      m_fontFallbackList(other.m_fontFallbackList) {}

Font& Font::operator=(const Font& other) {
  m_fontDescription = other.m_fontDescription;
  m_fontFallbackList = other.m_fontFallbackList;
  return *this;
}

bool Font::operator==(const Font& other) const {
  // Our FontData don't have to be checked, since checking the font description
  // will be fine.
  // FIXME: This does not work if the font was made with the FontPlatformData
  // constructor.
  if (loadingCustomFonts() || other.loadingCustomFonts())
    return false;

  FontSelector* first =
      m_fontFallbackList ? m_fontFallbackList->fontSelector() : 0;
  FontSelector* second =
      other.m_fontFallbackList ? other.m_fontFallbackList->fontSelector() : 0;

  return first == second && m_fontDescription == other.m_fontDescription &&
         (m_fontFallbackList ? m_fontFallbackList->fontSelectorVersion() : 0) ==
             (other.m_fontFallbackList
                  ? other.m_fontFallbackList->fontSelectorVersion()
                  : 0) &&
         (m_fontFallbackList ? m_fontFallbackList->generation() : 0) ==
             (other.m_fontFallbackList ? other.m_fontFallbackList->generation()
                                       : 0);
}

void Font::update(PassRefPtr<FontSelector> fontSelector) const {
  // FIXME: It is pretty crazy that we are willing to just poke into a RefPtr,
  // but it ends up being reasonably safe (because inherited fonts in the render
  // tree pick up the new style anyway. Other copies are transient, e.g., the
  // state in the GraphicsContext, and won't stick around long enough to get you
  // in trouble). Still, this is pretty disgusting, and could eventually be
  // rectified by using RefPtrs for Fonts themselves.
  if (!m_fontFallbackList)
    m_fontFallbackList = FontFallbackList::create();
  m_fontFallbackList->invalidate(fontSelector);
}

float Font::buildGlyphBuffer(const TextRunPaintInfo& runInfo,
                             GlyphBuffer& glyphBuffer,
                             ForTextEmphasisOrNot forTextEmphasis) const {
  if (codePath(runInfo.run) == ComplexPath) {
    HarfBuzzShaper shaper(this, runInfo.run,
                          (forTextEmphasis == ForTextEmphasis)
                              ? HarfBuzzShaper::ForTextEmphasis
                              : HarfBuzzShaper::NotForTextEmphasis);
    shaper.setDrawRange(runInfo.from, runInfo.to);
    shaper.shape(&glyphBuffer);

    return 0;
  }

  WidthIterator it(this, runInfo.run, nullptr, false, forTextEmphasis);
  it.advance(runInfo.from);
  float beforeWidth = it.runWidthSoFar();
  it.advance(runInfo.to, &glyphBuffer);

  if (runInfo.run.ltr())
    return beforeWidth;

  // RTL
  float afterWidth = it.runWidthSoFar();
  it.advance(runInfo.run.length());
  glyphBuffer.reverse();

  return it.runWidthSoFar() - afterWidth;
}

void Font::drawText(GraphicsContext* context,
                    const TextRunPaintInfo& runInfo,
                    const FloatPoint& point) const {
  // Don't draw anything while we are using custom fonts that are in the process
  // of loading.
  if (shouldSkipDrawing())
    return;

  TextDrawingModeFlags textMode = context->textDrawingMode();
  if (!(textMode & TextModeFill) &&
      !((textMode & TextModeStroke) && context->hasStroke()))
    return;

  if (runInfo.cachedTextBlob && runInfo.cachedTextBlob->get()) {
    // we have a pre-cached blob -- happy joy!
    drawTextBlob(context, runInfo.cachedTextBlob->get(), point.data());
    return;
  }

  {
    FontCachePurgePreventer preventer;
    GlyphBuffer glyphBuffer;
    float initialAdvance = buildGlyphBuffer(runInfo, glyphBuffer);

    if (glyphBuffer.isEmpty())
      return;

    // Enabling text-blobs forces the blob rendering path even for uncacheable
    // blobs.
    TextBlobPtr uncacheableTextBlob;
    TextBlobPtr& textBlob =
        runInfo.cachedTextBlob ? *runInfo.cachedTextBlob : uncacheableTextBlob;
    FloatRect blobBounds = runInfo.bounds;
    blobBounds.moveBy(-point);

    textBlob = buildTextBlob(glyphBuffer, initialAdvance, blobBounds);
    if (textBlob) {
      drawTextBlob(context, textBlob.get(), point.data());
      return;
    }

    drawGlyphBuffer(context, runInfo, glyphBuffer,
                    FloatPoint(point.x() + initialAdvance, point.y()));
  }
}

float Font::drawUncachedText(
    GraphicsContext* context,
    const TextRunPaintInfo& runInfo,
    const FloatPoint& point,
    CustomFontNotReadyAction customFontNotReadyAction) const {
  // Don't draw anything while we are using custom fonts that are in the process
  // of loading, except if the 'force' argument is set to true (in which case it
  // will use a fallback font).
  if (shouldSkipDrawing() &&
      customFontNotReadyAction == DoNotPaintIfFontNotReady)
    return 0;

  TextDrawingModeFlags textMode = context->textDrawingMode();
  if (!(textMode & TextModeFill) &&
      !((textMode & TextModeStroke) && context->hasStroke()))
    return 0;

  GlyphBuffer glyphBuffer;
  float initialAdvance = buildGlyphBuffer(runInfo, glyphBuffer);

  if (glyphBuffer.isEmpty())
    return 0;

  return drawGlyphBuffer(context, runInfo, glyphBuffer,
                         FloatPoint(point.x() + initialAdvance, point.y()));
}

void Font::drawEmphasisMarks(GraphicsContext* context,
                             const TextRunPaintInfo& runInfo,
                             const AtomicString& mark,
                             const FloatPoint& point) const {
  if (shouldSkipDrawing())
    return;

  GlyphBuffer glyphBuffer;
  float initialAdvance =
      buildGlyphBuffer(runInfo, glyphBuffer, ForTextEmphasis);

  if (glyphBuffer.isEmpty())
    return;

  drawEmphasisMarks(context, runInfo, glyphBuffer, mark,
                    FloatPoint(point.x() + initialAdvance, point.y()));
}

static inline void updateGlyphOverflowFromBounds(
    const IntRectExtent& glyphBounds,
    const FontMetrics& fontMetrics,
    GlyphOverflow* glyphOverflow) {
  glyphOverflow->top = std::max<int>(
      glyphOverflow->top,
      glyphBounds.top() -
          (glyphOverflow->computeBounds ? 0 : fontMetrics.ascent()));
  glyphOverflow->bottom = std::max<int>(
      glyphOverflow->bottom,
      glyphBounds.bottom() -
          (glyphOverflow->computeBounds ? 0 : fontMetrics.descent()));
  glyphOverflow->left = glyphBounds.left();
  glyphOverflow->right = glyphBounds.right();
}

float Font::width(const TextRun& run,
                  HashSet<const SimpleFontData*>* fallbackFonts,
                  GlyphOverflow* glyphOverflow) const {
  CodePath codePathToUse = codePath(run);
  if (codePathToUse != ComplexPath) {
    // The simple path can optimize the case where glyph overflow is not
    // observable.
    if (codePathToUse != SimpleWithGlyphOverflowPath &&
        (glyphOverflow && !glyphOverflow->computeBounds))
      glyphOverflow = 0;
  }

  bool hasWordSpacingOrLetterSpacing =
      fontDescription().wordSpacing() || fontDescription().letterSpacing();
  bool isCacheable =
      codePathToUse == ComplexPath &&
      !hasWordSpacingOrLetterSpacing  // Word spacing and letter spacing can
                                      // change the width of a word.
      && !run.allowTabs();  // If we allow tabs and a tab occurs inside a word,
                            // the width of the word varies based on its
                            // position on the line.

  WidthCacheEntry* cacheEntry =
      isCacheable ? m_fontFallbackList->widthCache().add(run, WidthCacheEntry())
                  : 0;
  if (cacheEntry && cacheEntry->isValid()) {
    if (glyphOverflow)
      updateGlyphOverflowFromBounds(cacheEntry->glyphBounds, fontMetrics(),
                                    glyphOverflow);
    return cacheEntry->width;
  }

  float result;
  IntRectExtent glyphBounds;
  if (codePathToUse == ComplexPath) {
    result = floatWidthForComplexText(run, fallbackFonts, &glyphBounds);
  } else {
    ASSERT(!isCacheable);
    result = floatWidthForSimpleText(run, fallbackFonts,
                                     glyphOverflow ? &glyphBounds : 0);
  }

  if (cacheEntry && (!fallbackFonts || fallbackFonts->isEmpty())) {
    cacheEntry->glyphBounds = glyphBounds;
    cacheEntry->width = result;
  }

  if (glyphOverflow)
    updateGlyphOverflowFromBounds(glyphBounds, fontMetrics(), glyphOverflow);
  return result;
}

float Font::width(const TextRun& run,
                  int& charsConsumed,
                  Glyph& glyphId) const {
  charsConsumed = run.length();
  glyphId = 0;
  return width(run);
}

FloatRect Font::selectionRectForText(const TextRun& run,
                                     const FloatPoint& point,
                                     int h,
                                     int from,
                                     int to,
                                     bool accountForGlyphBounds) const {
  to = (to == -1 ? run.length() : to);

  CodePath codePathToUse = codePath(run);
  // FIXME: Use the fast code path once it handles partial runs with kerning and
  // ligatures. See http://webkit.org/b/100050
  if (codePathToUse != ComplexPath && fontDescription().typesettingFeatures() &&
      (from || to != run.length()))
    codePathToUse = ComplexPath;

  if (codePathToUse != ComplexPath)
    return selectionRectForSimpleText(run, point, h, from, to,
                                      accountForGlyphBounds);

  return selectionRectForComplexText(run, point, h, from, to);
}

int Font::offsetForPosition(const TextRun& run,
                            float x,
                            bool includePartialGlyphs) const {
  // FIXME: Use the fast code path once it handles partial runs with kerning and
  // ligatures. See http://webkit.org/b/100050
  if (codePath(run) != ComplexPath && !fontDescription().typesettingFeatures())
    return offsetForPositionForSimpleText(run, x, includePartialGlyphs);

  return offsetForPositionForComplexText(run, x, includePartialGlyphs);
}

void Font::setCodePath(CodePath p) {
  s_codePath = p;
}

CodePath Font::codePath() {
  return s_codePath;
}

CodePath Font::codePath(const TextRun& run) const {
  if (s_codePath != AutoPath)
    return s_codePath;

  if (m_fontDescription.featureSettings() &&
      m_fontDescription.featureSettings()->size() > 0 &&
      m_fontDescription.letterSpacing() == 0)
    return ComplexPath;

  if (m_fontDescription.widthVariant() != RegularWidth)
    return ComplexPath;

  if (run.length() > 1 && fontDescription().typesettingFeatures())
    return ComplexPath;

  if (!run.characterScanForCodePath())
    return SimplePath;

  if (run.is8Bit())
    return SimplePath;

  // Start from 0 since drawing and highlighting also measure the characters
  // before run->from.
  return Character::characterRangeCodePath(run.characters16(), run.length());
}

void Font::willUseFontData(UChar32 character) const {
  const FontFamily& family = fontDescription().family();
  if (m_fontFallbackList && m_fontFallbackList->fontSelector() &&
      !family.familyIsEmpty())
    m_fontFallbackList->fontSelector()->willUseFontData(
        fontDescription(), family.family(), character);
}

static inline bool isInRange(UChar32 character,
                             UChar32 lowerBound,
                             UChar32 upperBound) {
  return character >= lowerBound && character <= upperBound;
}

static bool shouldIgnoreRotation(UChar32 character) {
  if (character == 0x000A7 || character == 0x000A9 || character == 0x000AE)
    return true;

  if (character == 0x000B6 || character == 0x000BC || character == 0x000BD ||
      character == 0x000BE)
    return true;

  if (isInRange(character, 0x002E5, 0x002EB))
    return true;

  if (isInRange(character, 0x01100, 0x011FF) ||
      isInRange(character, 0x01401, 0x0167F) ||
      isInRange(character, 0x01800, 0x018FF))
    return true;

  if (character == 0x02016 || character == 0x02018 || character == 0x02019 ||
      character == 0x02020 || character == 0x02021 || character == 0x2030 ||
      character == 0x02031)
    return true;

  if (isInRange(character, 0x0203B, 0x0203D) || character == 0x02042 ||
      character == 0x02044 || character == 0x02047 || character == 0x02048 ||
      character == 0x02049 || character == 0x2051)
    return true;

  if (isInRange(character, 0x02065, 0x02069) ||
      isInRange(character, 0x020DD, 0x020E0) ||
      isInRange(character, 0x020E2, 0x020E4) ||
      isInRange(character, 0x02100, 0x02117) ||
      isInRange(character, 0x02119, 0x02131) ||
      isInRange(character, 0x02133, 0x0213F))
    return true;

  if (isInRange(character, 0x02145, 0x0214A) || character == 0x0214C ||
      character == 0x0214D || isInRange(character, 0x0214F, 0x0218F))
    return true;

  if (isInRange(character, 0x02300, 0x02307) ||
      isInRange(character, 0x0230C, 0x0231F) ||
      isInRange(character, 0x02322, 0x0232B) ||
      isInRange(character, 0x0237D, 0x0239A) ||
      isInRange(character, 0x023B4, 0x023B6) ||
      isInRange(character, 0x023BA, 0x023CF) ||
      isInRange(character, 0x023D1, 0x023DB) ||
      isInRange(character, 0x023E2, 0x024FF))
    return true;

  if (isInRange(character, 0x025A0, 0x02619) ||
      isInRange(character, 0x02620, 0x02767) ||
      isInRange(character, 0x02776, 0x02793) ||
      isInRange(character, 0x02B12, 0x02B2F) ||
      isInRange(character, 0x02B4D, 0x02BFF) ||
      isInRange(character, 0x02E80, 0x03007))
    return true;

  if (character == 0x03012 || character == 0x03013 ||
      isInRange(character, 0x03020, 0x0302F) ||
      isInRange(character, 0x03031, 0x0309F) ||
      isInRange(character, 0x030A1, 0x030FB) ||
      isInRange(character, 0x030FD, 0x0A4CF))
    return true;

  if (isInRange(character, 0x0A840, 0x0A87F) ||
      isInRange(character, 0x0A960, 0x0A97F) ||
      isInRange(character, 0x0AC00, 0x0D7FF) ||
      isInRange(character, 0x0E000, 0x0FAFF))
    return true;

  if (isInRange(character, 0x0FE10, 0x0FE1F) ||
      isInRange(character, 0x0FE30, 0x0FE48) ||
      isInRange(character, 0x0FE50, 0x0FE57) ||
      isInRange(character, 0x0FE5F, 0x0FE62) ||
      isInRange(character, 0x0FE67, 0x0FE6F))
    return true;

  if (isInRange(character, 0x0FF01, 0x0FF07) ||
      isInRange(character, 0x0FF0A, 0x0FF0C) ||
      isInRange(character, 0x0FF0E, 0x0FF19) ||
      isInRange(character, 0x0FF1F, 0x0FF3A))
    return true;

  if (character == 0x0FF3C || character == 0x0FF3E)
    return true;

  if (isInRange(character, 0x0FF40, 0x0FF5A) ||
      isInRange(character, 0x0FFE0, 0x0FFE2) ||
      isInRange(character, 0x0FFE4, 0x0FFE7) ||
      isInRange(character, 0x0FFF0, 0x0FFF8) || character == 0x0FFFD)
    return true;

  if (isInRange(character, 0x13000, 0x1342F) ||
      isInRange(character, 0x1B000, 0x1B0FF) ||
      isInRange(character, 0x1D000, 0x1D1FF) ||
      isInRange(character, 0x1D300, 0x1D37F) ||
      isInRange(character, 0x1F000, 0x1F64F) ||
      isInRange(character, 0x1F680, 0x1F77F))
    return true;

  if (isInRange(character, 0x20000, 0x2FFFD) ||
      isInRange(character, 0x30000, 0x3FFFD))
    return true;

  return false;
}

static inline std::pair<GlyphData, GlyphPage*>
glyphDataAndPageForNonCJKCharacterWithGlyphOrientation(
    UChar32 character,
    NonCJKGlyphOrientation orientation,
    GlyphData& data,
    GlyphPage* page,
    unsigned pageNumber) {
  if (orientation == NonCJKGlyphOrientationUpright ||
      shouldIgnoreRotation(character)) {
    RefPtr<SimpleFontData> uprightFontData =
        data.fontData->uprightOrientationFontData();
    GlyphPageTreeNode* uprightNode =
        GlyphPageTreeNode::getRootChild(uprightFontData.get(), pageNumber);
    GlyphPage* uprightPage = uprightNode->page();
    if (uprightPage) {
      GlyphData uprightData = uprightPage->glyphDataForCharacter(character);
      // If the glyphs are the same, then we know we can just use the horizontal
      // glyph rotated vertically to be upright.
      if (data.glyph == uprightData.glyph)
        return std::make_pair(data, page);
      // The glyphs are distinct, meaning that the font has a vertical-right
      // glyph baked into it. We can't use that glyph, so we fall back to the
      // upright data and use the horizontal glyph.
      if (uprightData.fontData)
        return std::make_pair(uprightData, uprightPage);
    }
  } else if (orientation == NonCJKGlyphOrientationVerticalRight) {
    RefPtr<SimpleFontData> verticalRightFontData =
        data.fontData->verticalRightOrientationFontData();
    GlyphPageTreeNode* verticalRightNode = GlyphPageTreeNode::getRootChild(
        verticalRightFontData.get(), pageNumber);
    GlyphPage* verticalRightPage = verticalRightNode->page();
    if (verticalRightPage) {
      GlyphData verticalRightData =
          verticalRightPage->glyphDataForCharacter(character);
      // If the glyphs are distinct, we will make the assumption that the font
      // has a vertical-right glyph baked into it.
      if (data.glyph != verticalRightData.glyph)
        return std::make_pair(data, page);
      // The glyphs are identical, meaning that we should just use the
      // horizontal glyph.
      if (verticalRightData.fontData)
        return std::make_pair(verticalRightData, verticalRightPage);
    }
  }
  return std::make_pair(data, page);
}

std::pair<GlyphData, GlyphPage*> Font::glyphDataAndPageForCharacter(
    UChar32 c,
    bool mirror,
    FontDataVariant variant) const {
  ASSERT(isMainThread());

  if (variant == AutoVariant) {
    if (m_fontDescription.variant() == FontVariantSmallCaps &&
        !primaryFont()->isSVGFont()) {
      UChar32 upperC = toUpper(c);
      if (upperC != c) {
        c = upperC;
        variant = SmallCapsVariant;
      } else {
        variant = NormalVariant;
      }
    } else {
      variant = NormalVariant;
    }
  }

  if (mirror)
    c = mirroredChar(c);

  unsigned pageNumber = (c / GlyphPage::size);

  GlyphPageTreeNode* node = m_fontFallbackList->getPageNode(pageNumber);
  if (!node) {
    node = GlyphPageTreeNode::getRootChild(fontDataAt(0), pageNumber);
    m_fontFallbackList->setPageNode(pageNumber, node);
  }

  GlyphPage* page = 0;
  if (variant == NormalVariant) {
    // Fastest loop, for the common case (normal variant).
    while (true) {
      page = node->page();
      if (page) {
        GlyphData data = page->glyphDataForCharacter(c);
        if (data.fontData &&
            (data.fontData->platformData().orientation() == Horizontal ||
             data.fontData->isTextOrientationFallback()))
          return std::make_pair(data, page);

        if (data.fontData) {
          if (Character::isCJKIdeographOrSymbol(c)) {
            if (!data.fontData->hasVerticalGlyphs()) {
              // Use the broken ideograph font data. The broken ideograph font
              // will use the horizontal width of glyphs to make sure you get a
              // square (even for broken glyphs like symbols used for
              // punctuation).
              variant = BrokenIdeographVariant;
              break;
            }
          } else {
            return glyphDataAndPageForNonCJKCharacterWithGlyphOrientation(
                c, m_fontDescription.nonCJKGlyphOrientation(), data, page,
                pageNumber);
          }

          return std::make_pair(data, page);
        }

        if (node->isSystemFallback())
          break;
      }

      // Proceed with the fallback list.
      node = node->getChild(fontDataAt(node->level()), pageNumber);
      m_fontFallbackList->setPageNode(pageNumber, node);
    }
  }
  if (variant != NormalVariant) {
    while (true) {
      page = node->page();
      if (page) {
        GlyphData data = page->glyphDataForCharacter(c);
        if (data.fontData) {
          // The variantFontData function should not normally return 0.
          // But if it does, we will just render the capital letter big.
          RefPtr<SimpleFontData> variantFontData =
              data.fontData->variantFontData(m_fontDescription, variant);
          if (!variantFontData)
            return std::make_pair(data, page);

          GlyphPageTreeNode* variantNode = GlyphPageTreeNode::getRootChild(
              variantFontData.get(), pageNumber);
          GlyphPage* variantPage = variantNode->page();
          if (variantPage) {
            GlyphData data = variantPage->glyphDataForCharacter(c);
            if (data.fontData)
              return std::make_pair(data, variantPage);
          }

          // Do not attempt system fallback off the variantFontData. This is the
          // very unlikely case that a font has the lowercase character but the
          // small caps font does not have its uppercase version.
          return std::make_pair(variantFontData->missingGlyphData(), page);
        }

        if (node->isSystemFallback())
          break;
      }

      // Proceed with the fallback list.
      node = node->getChild(fontDataAt(node->level()), pageNumber);
      m_fontFallbackList->setPageNode(pageNumber, node);
    }
  }

  ASSERT(page);
  ASSERT(node->isSystemFallback());

  // System fallback is character-dependent. When we get here, we
  // know that the character in question isn't in the system fallback
  // font's glyph page. Try to lazily create it here.

  // FIXME: Unclear if this should normalizeSpaces above 0xFFFF.
  // Doing so changes fast/text/international/plane2-diffs.html
  UChar32 characterToRender = c;
  if (characterToRender <= 0xFFFF)
    characterToRender = Character::normalizeSpaces(characterToRender);
  const SimpleFontData* fontDataToSubstitute =
      fontDataAt(0)->fontDataForCharacter(characterToRender);
  RefPtr<SimpleFontData> characterFontData =
      FontCache::fontCache()->fallbackFontForCharacter(
          m_fontDescription, characterToRender, fontDataToSubstitute);
  if (characterFontData) {
    if (characterFontData->platformData().orientation() == Vertical &&
        !characterFontData->hasVerticalGlyphs() &&
        Character::isCJKIdeographOrSymbol(c))
      variant = BrokenIdeographVariant;
    if (variant != NormalVariant)
      characterFontData =
          characterFontData->variantFontData(m_fontDescription, variant);
  }
  if (characterFontData) {
    // Got the fallback glyph and font.
    GlyphPage* fallbackPage =
        GlyphPageTreeNode::getRootChild(characterFontData.get(), pageNumber)
            ->page();
    GlyphData data = fallbackPage && fallbackPage->glyphForCharacter(c)
                         ? fallbackPage->glyphDataForCharacter(c)
                         : characterFontData->missingGlyphData();
    // Cache it so we don't have to do system fallback again next time.
    if (variant == NormalVariant) {
      page->setGlyphDataForCharacter(c, data.glyph, data.fontData);
      data.fontData->setMaxGlyphPageTreeLevel(
          std::max(data.fontData->maxGlyphPageTreeLevel(), node->level()));
      if (!Character::isCJKIdeographOrSymbol(c) &&
          data.fontData->platformData().orientation() != Horizontal &&
          !data.fontData->isTextOrientationFallback())
        return glyphDataAndPageForNonCJKCharacterWithGlyphOrientation(
            c, m_fontDescription.nonCJKGlyphOrientation(), data, page,
            pageNumber);
    }
    return std::make_pair(data, page);
  }

  // Even system fallback can fail; use the missing glyph in that case.
  // FIXME: It would be nicer to use the missing glyph from the last resort font
  // instead.
  GlyphData data = primaryFont()->missingGlyphData();
  if (variant == NormalVariant) {
    page->setGlyphDataForCharacter(c, data.glyph, data.fontData);
    data.fontData->setMaxGlyphPageTreeLevel(
        std::max(data.fontData->maxGlyphPageTreeLevel(), node->level()));
  }
  return std::make_pair(data, page);
}

bool Font::primaryFontHasGlyphForCharacter(UChar32 character) const {
  unsigned pageNumber = (character / GlyphPage::size);

  GlyphPageTreeNode* node =
      GlyphPageTreeNode::getRootChild(primaryFont(), pageNumber);
  GlyphPage* page = node->page();

  return page && page->glyphForCharacter(character);
}

// FIXME: This function may not work if the emphasis mark uses a complex script,
// but none of the standard emphasis marks do so.
bool Font::getEmphasisMarkGlyphData(const AtomicString& mark,
                                    GlyphData& glyphData) const {
  if (mark.isEmpty())
    return false;

  UChar32 character = mark[0];

  if (U16_IS_SURROGATE(character)) {
    if (!U16_IS_SURROGATE_LEAD(character))
      return false;

    if (mark.length() < 2)
      return false;

    UChar low = mark[1];
    if (!U16_IS_TRAIL(low))
      return false;

    character = U16_GET_SUPPLEMENTARY(character, low);
  }

  glyphData = glyphDataForCharacter(character, false, EmphasisMarkVariant);
  return true;
}

int Font::emphasisMarkAscent(const AtomicString& mark) const {
  FontCachePurgePreventer purgePreventer;

  GlyphData markGlyphData;
  if (!getEmphasisMarkGlyphData(mark, markGlyphData))
    return 0;

  const SimpleFontData* markFontData = markGlyphData.fontData;
  ASSERT(markFontData);
  if (!markFontData)
    return 0;

  return markFontData->fontMetrics().ascent();
}

int Font::emphasisMarkDescent(const AtomicString& mark) const {
  FontCachePurgePreventer purgePreventer;

  GlyphData markGlyphData;
  if (!getEmphasisMarkGlyphData(mark, markGlyphData))
    return 0;

  const SimpleFontData* markFontData = markGlyphData.fontData;
  ASSERT(markFontData);
  if (!markFontData)
    return 0;

  return markFontData->fontMetrics().descent();
}

int Font::emphasisMarkHeight(const AtomicString& mark) const {
  FontCachePurgePreventer purgePreventer;

  GlyphData markGlyphData;
  if (!getEmphasisMarkGlyphData(mark, markGlyphData))
    return 0;

  const SimpleFontData* markFontData = markGlyphData.fontData;
  ASSERT(markFontData);
  if (!markFontData)
    return 0;

  return markFontData->fontMetrics().height();
}

float Font::drawGlyphBuffer(GraphicsContext* context,
                            const TextRunPaintInfo& runInfo,
                            const GlyphBuffer& glyphBuffer,
                            const FloatPoint& point) const {
  // Draw each contiguous run of glyphs that use the same font data.
  const SimpleFontData* fontData = glyphBuffer.fontDataAt(0);
  FloatPoint startPoint(point);
  float advanceSoFar = 0;
  unsigned lastFrom = 0;
  unsigned nextGlyph = 0;
  while (nextGlyph < glyphBuffer.size()) {
    const SimpleFontData* nextFontData = glyphBuffer.fontDataAt(nextGlyph);
    if (nextFontData != fontData) {
      drawGlyphs(context, fontData, glyphBuffer, lastFrom, nextGlyph - lastFrom,
                 startPoint, runInfo.bounds);
      lastFrom = nextGlyph;
      fontData = nextFontData;
      startPoint += FloatSize(advanceSoFar, 0);
      advanceSoFar = 0;
    }
    advanceSoFar += glyphBuffer.advanceAt(nextGlyph);
    nextGlyph++;
  }
  drawGlyphs(context, fontData, glyphBuffer, lastFrom, nextGlyph - lastFrom,
             startPoint, runInfo.bounds);
  startPoint += FloatSize(advanceSoFar, 0);
  return startPoint.x() - point.x();
}

inline static float offsetToMiddleOfGlyph(const SimpleFontData* fontData,
                                          Glyph glyph) {
  if (fontData->platformData().orientation() == Horizontal) {
    FloatRect bounds = fontData->boundsForGlyph(glyph);
    return bounds.x() + bounds.width() / 2;
  }
  // FIXME: Use glyph bounds once they make sense for vertical fonts.
  return fontData->widthForGlyph(glyph) / 2;
}

inline static float offsetToMiddleOfAdvanceAtIndex(
    const GlyphBuffer& glyphBuffer,
    size_t i) {
  return glyphBuffer.advanceAt(i) / 2;
}

void Font::drawEmphasisMarks(GraphicsContext* context,
                             const TextRunPaintInfo& runInfo,
                             const GlyphBuffer& glyphBuffer,
                             const AtomicString& mark,
                             const FloatPoint& point) const {
  FontCachePurgePreventer purgePreventer;

  GlyphData markGlyphData;
  if (!getEmphasisMarkGlyphData(mark, markGlyphData))
    return;

  const SimpleFontData* markFontData = markGlyphData.fontData;
  ASSERT(markFontData);
  if (!markFontData)
    return;

  Glyph markGlyph = markGlyphData.glyph;
  Glyph spaceGlyph = markFontData->spaceGlyph();

  float middleOfLastGlyph = offsetToMiddleOfAdvanceAtIndex(glyphBuffer, 0);
  FloatPoint startPoint(point.x() + middleOfLastGlyph -
                            offsetToMiddleOfGlyph(markFontData, markGlyph),
                        point.y());

  GlyphBuffer markBuffer;
  for (unsigned i = 0; i + 1 < glyphBuffer.size(); ++i) {
    float middleOfNextGlyph =
        offsetToMiddleOfAdvanceAtIndex(glyphBuffer, i + 1);
    float advance =
        glyphBuffer.advanceAt(i) - middleOfLastGlyph + middleOfNextGlyph;
    markBuffer.add(glyphBuffer.glyphAt(i) ? markGlyph : spaceGlyph,
                   markFontData, advance);
    middleOfLastGlyph = middleOfNextGlyph;
  }
  markBuffer.add(
      glyphBuffer.glyphAt(glyphBuffer.size() - 1) ? markGlyph : spaceGlyph,
      markFontData, 0);

  drawGlyphBuffer(context, runInfo, markBuffer, startPoint);
}

float Font::floatWidthForSimpleText(
    const TextRun& run,
    HashSet<const SimpleFontData*>* fallbackFonts,
    IntRectExtent* glyphBounds) const {
  WidthIterator it(this, run, fallbackFonts, glyphBounds);
  it.advance(run.length());

  if (glyphBounds) {
    glyphBounds->setTop(floorf(-it.minGlyphBoundingBoxY()));
    glyphBounds->setBottom(ceilf(it.maxGlyphBoundingBoxY()));
    glyphBounds->setLeft(floorf(it.firstGlyphOverflow()));
    glyphBounds->setRight(ceilf(it.lastGlyphOverflow()));
  }

  return it.m_runWidthSoFar;
}

FloatRect Font::pixelSnappedSelectionRect(float fromX,
                                          float toX,
                                          float y,
                                          float height) {
  // Using roundf() rather than ceilf() for the right edge as a compromise to
  // ensure correct caret positioning.
  float roundedX = roundf(fromX);
  return FloatRect(roundedX, y, roundf(toX - roundedX), height);
}

FloatRect Font::selectionRectForSimpleText(const TextRun& run,
                                           const FloatPoint& point,
                                           int h,
                                           int from,
                                           int to,
                                           bool accountForGlyphBounds) const {
  WidthIterator it(this, run, 0, accountForGlyphBounds);
  it.advance(from);
  float fromX = it.m_runWidthSoFar;
  it.advance(to);
  float toX = it.m_runWidthSoFar;

  if (run.rtl()) {
    it.advance(run.length());
    float totalWidth = it.m_runWidthSoFar;
    float beforeWidth = fromX;
    float afterWidth = toX;
    fromX = totalWidth - afterWidth;
    toX = totalWidth - beforeWidth;
  }

  return pixelSnappedSelectionRect(
      point.x() + fromX, point.x() + toX,
      accountForGlyphBounds ? it.minGlyphBoundingBoxY() : point.y(),
      accountForGlyphBounds
          ? it.maxGlyphBoundingBoxY() - it.minGlyphBoundingBoxY()
          : h);
}

int Font::offsetForPositionForSimpleText(const TextRun& run,
                                         float x,
                                         bool includePartialGlyphs) const {
  float delta = x;

  WidthIterator it(this, run);
  unsigned offset;
  if (run.rtl()) {
    delta -= floatWidthForSimpleText(run);
    while (1) {
      offset = it.m_currentCharacter;
      float w;
      if (!it.advanceOneCharacter(w))
        break;
      delta += w;
      if (includePartialGlyphs) {
        if (delta - w / 2 >= 0)
          break;
      } else {
        if (delta >= 0)
          break;
      }
    }
  } else {
    while (1) {
      offset = it.m_currentCharacter;
      float w;
      if (!it.advanceOneCharacter(w))
        break;
      delta -= w;
      if (includePartialGlyphs) {
        if (delta + w / 2 <= 0)
          break;
      } else {
        if (delta <= 0)
          break;
      }
    }
  }

  return offset;
}

}  // namespace blink
