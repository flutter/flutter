// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/text/ParagraphBuilder.h"

#include "sky/engine/core/css/FontSize.h"
#include "sky/engine/core/rendering/RenderInline.h"
#include "sky/engine/core/rendering/RenderParagraph.h"
#include "sky/engine/core/rendering/RenderText.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"

namespace blink {
namespace {

RenderParagraph* createRenderParagraph(RenderStyle* parentStyle)
{
    RefPtr<RenderStyle> style = RenderStyle::create();
    style->inheritFrom(parentStyle);
    style->setDisplay(PARAGRAPH);

    RenderParagraph* renderParagraph = new RenderParagraph();
    renderParagraph->setStyle(style.release());
    return renderParagraph;
}

Color getColorFromARGB(int argb) {
  return Color(
    (argb & 0x00FF0000) >> 16,
    (argb & 0x0000FF00) >> 8,
    (argb & 0x000000FF) >> 0,
    (argb & 0xFF000000) >> 24
  );
}

// TextStyle

const int kColorIndex = 1;
const int kTextDecorationIndex = 2;
const int kTextDecorationColorIndex = 3;
const int kTextDecorationStyleIndex = 4;
const int kFontWeightIndex = 5;
const int kFontStyleIndex = 6;
const int kFontFamilyIndex = 7;
const int kFontSizeIndex = 8;
const int kLetterSpacingIndex = 9;

const int kColorMask = 1 << kColorIndex;
const int kTextDecorationMask = 1 << kTextDecorationIndex;
const int kTextDecorationColorMask = 1 << kTextDecorationColorIndex;
const int kTextDecorationStyleMask = 1 << kTextDecorationStyleIndex;
const int kFontWeightMask = 1 << kFontWeightIndex;
const int kFontStyleMask = 1 << kFontStyleIndex;
const int kFontFamilyMask = 1 << kFontFamilyIndex;
const int kFontSizeMask = 1 << kFontSizeIndex;
const int kLetterSpacingMask = 1 << kLetterSpacingIndex;

// ParagraphStyle

const int kTextAlignIndex = 1;
const int kTextBaselineIndex = 2;
const int kLineHeightIndex = 3;

const int kTextAlignMask = 1 << kTextAlignIndex;
const int kTextBaselineMask = 1 << kTextBaselineIndex;
const int kLineHeightMask = 1 << kLineHeightIndex;

}  // namespace

ParagraphBuilder::ParagraphBuilder()
{
    m_fontSelector = CSSFontSelector::create();
    createRenderView();
    m_renderParagraph = createRenderParagraph(m_renderView->style());
    m_currentRenderObject = m_renderParagraph;
    m_renderView->addChild(m_currentRenderObject);
}

ParagraphBuilder::~ParagraphBuilder()
{
}

void ParagraphBuilder::pushStyle(Int32List& encoded, const String& fontFamily, double fontSize, double letterSpacing)
{
    DCHECK(encoded.num_elements() == 7);
    RefPtr<RenderStyle> style = RenderStyle::create();
    style->inheritFrom(m_currentRenderObject->style());

    int32_t mask = encoded[0];

    if (mask & kColorMask)
      style->setColor(getColorFromARGB(encoded[kColorIndex]));

    if (mask & kTextDecorationMask) {
      style->setTextDecoration(static_cast<TextDecoration>(encoded[kTextDecorationIndex]));
      style->applyTextDecorations();
    }

    if (mask & kTextDecorationColorMask)
      style->setTextDecorationColor(StyleColor(getColorFromARGB(encoded[kTextDecorationColorIndex])));

    if (mask & kTextDecorationStyleMask)
      style->setTextDecorationStyle(static_cast<TextDecorationStyle>(encoded[kTextDecorationStyleIndex]));

    if (mask & (kFontWeightMask | kFontStyleMask | kFontFamilyMask | kFontSizeMask | kLetterSpacingMask)) {
      FontDescription fontDescription = style->fontDescription();

      if (mask & kFontWeightMask)
        fontDescription.setWeight(static_cast<FontWeight>(encoded[kFontWeightIndex]));

      if (mask & kFontStyleMask)
        fontDescription.setStyle(static_cast<FontStyle>(encoded[kFontStyleIndex]));

      if (mask & kFontFamilyMask) {
        FontFamily family;
        family.setFamily(fontFamily);
        fontDescription.setFamily(family);
      }

      if (mask & kFontSizeMask) {
        fontDescription.setSpecifiedSize(fontSize);
        fontDescription.setIsAbsoluteSize(true);
        fontDescription.setComputedSize(FontSize::getComputedSizeFromSpecifiedSize(true, fontSize));
      }

      if (mask & kLetterSpacingMask)
        fontDescription.setLetterSpacing(letterSpacing);

      style->setFontDescription(fontDescription);
      style->font().update(m_fontSelector);
    }

    encoded.Release();

    RenderObject* span = new RenderInline();
    span->setStyle(style.release());
    m_currentRenderObject->addChild(span);
    m_currentRenderObject = span;
}

void ParagraphBuilder::pop()
{
    if (m_currentRenderObject)
        m_currentRenderObject = m_currentRenderObject->parent();
}

void ParagraphBuilder::addText(const String& text)
{
    if (!m_currentRenderObject)
        return;
    RenderText* renderText = new RenderText(text.impl());
    RefPtr<RenderStyle> style = RenderStyle::create();
    style->inheritFrom(m_currentRenderObject->style());
    renderText->setStyle(style.release());
    m_currentRenderObject->addChild(renderText);
}

PassRefPtr<Paragraph> ParagraphBuilder::build(Int32List& encoded, double lineHeight)
{
    DCHECK(encoded.num_elements() == 3);
    int32_t mask = encoded[0];

    if (mask) {
      RefPtr<RenderStyle> style = RenderStyle::clone(m_renderParagraph->style());

      if (mask & kTextAlignMask)
        style->setTextAlign(static_cast<ETextAlign>(encoded[kTextAlignIndex]));

      if (mask & kTextBaselineMask) {
        // TODO(abarth): Implement TextBaseline. The CSS version of this
        // property wasn't wired up either.
      }

      if (mask & kLineHeightMask)
        style->setLineHeight(Length(lineHeight, Fixed));

      m_renderParagraph->setStyle(style.release());
    }

    encoded.Release();

    m_currentRenderObject = nullptr;
    return Paragraph::create(m_renderView.release());
}

void ParagraphBuilder::createRenderView()
{
    RefPtr<RenderStyle> style = RenderStyle::create();
    style->setRTLOrdering(LogicalOrder);
    style->setZIndex(0);
    style->setUserModify(READ_ONLY);

    FontBuilder fontBuilder;
    fontBuilder.initForStyleResolve(style.get());
    fontBuilder.createFontForDocument(m_fontSelector.get(), style.get());

    m_renderView = adoptPtr(new RenderView());
    m_renderView->setStyle(style.release());
}

} // namespace blink
