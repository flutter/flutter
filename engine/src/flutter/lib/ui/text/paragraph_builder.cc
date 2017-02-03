// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/text/paragraph_builder.h"

#include "flutter/common/threads.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/sky/engine/core/rendering/RenderInline.h"
#include "flutter/sky/engine/core/rendering/RenderParagraph.h"
#include "flutter/sky/engine/core/rendering/RenderText.h"
#include "flutter/sky/engine/core/rendering/style/RenderStyle.h"
#include "flutter/sky/engine/platform/text/LocaleToScriptMapping.h"
#include "lib/ftl/tasks/task_runner.h"
#include "lib/tonic/converter/dart_converter.h"
#include "lib/tonic/dart_args.h"
#include "lib/tonic/dart_binding_macros.h"
#include "lib/tonic/dart_library_natives.h"

namespace blink {
namespace {

// TextStyle

const int tsColorIndex = 1;
const int tsTextDecorationIndex = 2;
const int tsTextDecorationColorIndex = 3;
const int tsTextDecorationStyleIndex = 4;
const int tsFontWeightIndex = 5;
const int tsFontStyleIndex = 6;
const int tsTextBaselineIndex = 7;
const int tsFontFamilyIndex = 8;
const int tsFontSizeIndex = 9;
const int tsLetterSpacingIndex = 10;
const int tsWordSpacingIndex = 11;
const int tsHeightIndex = 12;

const int tsColorMask = 1 << tsColorIndex;
const int tsTextDecorationMask = 1 << tsTextDecorationIndex;
const int tsTextDecorationColorMask = 1 << tsTextDecorationColorIndex;
const int tsTextDecorationStyleMask = 1 << tsTextDecorationStyleIndex;
const int tsFontWeightMask = 1 << tsFontWeightIndex;
const int tsFontStyleMask = 1 << tsFontStyleIndex;
const int tsTextBaselineMask = 1 << tsTextBaselineIndex;
const int tsFontFamilyMask = 1 << tsFontFamilyIndex;
const int tsFontSizeMask = 1 << tsFontSizeIndex;
const int tsLetterSpacingMask = 1 << tsLetterSpacingIndex;
const int tsWordSpacingMask = 1 << tsWordSpacingIndex;
const int tsHeightMask = 1 << tsHeightIndex;

// ParagraphStyle

const int psTextAlignIndex = 1;
const int psFontWeightIndex = 2;
const int psFontStyleIndex = 3;
const int psMaxLinesIndex = 4;
const int psFontFamilyIndex = 5;
const int psFontSizeIndex = 6;
const int psLineHeightIndex = 7;
const int psEllipsisIndex = 8;

const int psTextAlignMask = 1 << psTextAlignIndex;
const int psFontWeightMask = 1 << psFontWeightIndex;
const int psFontStyleMask = 1 << psFontStyleIndex;
const int psMaxLinesMask = 1 << psMaxLinesIndex;
const int psFontFamilyMask = 1 << psFontFamilyIndex;
const int psFontSizeMask = 1 << psFontSizeIndex;
const int psLineHeightMask = 1 << psLineHeightIndex;
const int psEllipsisMask = 1 << psEllipsisIndex;

float getComputedSizeFromSpecifiedSize(float specifiedSize) {
  if (specifiedSize < std::numeric_limits<float>::epsilon())
    return 0.0f;
  return specifiedSize;
}

void createFontForDocument(RenderStyle* style) {
  FontDescription fontDescription = FontDescription();
  fontDescription.setScript(
      localeToScriptCodeForFontSelection(style->locale()));

  // Using 14px default to match Material Design English Body1:
  // http://www.google.com/design/spec/style/typography.html#typography-typeface
  const float defaultFontSize = 14.0;

  fontDescription.setSpecifiedSize(defaultFontSize);
  fontDescription.setComputedSize(defaultFontSize);

  FontOrientation fontOrientation = Horizontal;
  NonCJKGlyphOrientation glyphOrientation = NonCJKGlyphOrientationVerticalRight;

  fontDescription.setOrientation(fontOrientation);
  fontDescription.setNonCJKGlyphOrientation(glyphOrientation);
  style->setFontDescription(fontDescription);
  style->font().update(UIDartState::Current()->font_selector());
}

PassRefPtr<RenderStyle> decodeParagraphStyle(
    RenderStyle* parentStyle,
    tonic::Int32List& encoded,
    const std::string& fontFamily,
    double fontSize,
    double lineHeight,
    const std::string& ellipsis) {
  FTL_DCHECK(encoded.num_elements() == 5);

  RefPtr<RenderStyle> style = RenderStyle::create();
  style->inheritFrom(parentStyle);
  style->setDisplay(PARAGRAPH);

  int32_t mask = encoded[0];

  if (mask & psTextAlignMask)
    style->setTextAlign(static_cast<ETextAlign>(encoded[psTextAlignIndex]));

  if (mask & (psFontWeightMask | psFontStyleMask | psFontFamilyMask |
              psFontSizeMask)) {
    FontDescription fontDescription = style->fontDescription();

    if (mask & psFontWeightMask)
      fontDescription.setWeight(
          static_cast<FontWeight>(encoded[psFontWeightIndex]));

    if (mask & psFontStyleMask)
      fontDescription.setStyle(
          static_cast<FontStyle>(encoded[psFontStyleIndex]));

    if (mask & psFontFamilyMask) {
      FontFamily family;
      family.setFamily(String::fromUTF8(fontFamily));
      fontDescription.setFamily(family);
    }

    if (mask & psFontSizeMask) {
      fontDescription.setSpecifiedSize(fontSize);
      fontDescription.setIsAbsoluteSize(true);
      fontDescription.setComputedSize(
          getComputedSizeFromSpecifiedSize(fontSize));
    }

    style->setFontDescription(fontDescription);
    style->font().update(UIDartState::Current()->font_selector());
  }

  if (mask & psLineHeightMask)
    style->setLineHeight(Length(lineHeight * 100.0, Percent));

  if (mask & psMaxLinesMask)
    style->setMaxLines(encoded[psMaxLinesIndex]);

  if (mask & psEllipsisMask)
    style->setEllipsis(AtomicString::fromUTF8(ellipsis.c_str()));

  return style.release();
}

Color getColorFromARGB(int argb) {
  return Color((argb & 0x00FF0000) >> 16, (argb & 0x0000FF00) >> 8,
               (argb & 0x000000FF) >> 0, (argb & 0xFF000000) >> 24);
}

}  // namespace

static void ParagraphBuilder_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&ParagraphBuilder::create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, ParagraphBuilder);

#define FOR_EACH_BINDING(V)      \
  V(ParagraphBuilder, pushStyle) \
  V(ParagraphBuilder, pop)       \
  V(ParagraphBuilder, addText)   \
  V(ParagraphBuilder, build)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void ParagraphBuilder::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register(
      {{"ParagraphBuilder_constructor", ParagraphBuilder_constructor, 6, true},
       FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

ftl::RefPtr<ParagraphBuilder> ParagraphBuilder::create(
    tonic::Int32List& encoded,
    const std::string& fontFamily,
    double fontSize,
    double lineHeight,
    const std::string& ellipsis) {
  return ftl::MakeRefCounted<ParagraphBuilder>(
      encoded, fontFamily, fontSize, lineHeight, ellipsis);
}

ParagraphBuilder::ParagraphBuilder(tonic::Int32List& encoded,
                                   const std::string& fontFamily,
                                   double fontSize,
                                   double lineHeight,
                                   const std::string& ellipsis) {
  createRenderView();

  RefPtr<RenderStyle> paragraphStyle = decodeParagraphStyle(
      m_renderView->style(), encoded, fontFamily, fontSize, lineHeight, ellipsis);
  encoded.Release();

  m_renderParagraph = new RenderParagraph();
  m_renderParagraph->setStyle(paragraphStyle.release());

  m_currentRenderObject = m_renderParagraph;
  m_renderView->addChild(m_currentRenderObject);
}

ParagraphBuilder::~ParagraphBuilder() {
  if (m_renderView) {
    RenderView* renderView = m_renderView.leakPtr();
    Threads::UI()->PostTask(
        [renderView]() { renderView->destroy(); });
  }
}

void ParagraphBuilder::pushStyle(tonic::Int32List& encoded,
                                 const std::string& fontFamily,
                                 double fontSize,
                                 double letterSpacing,
                                 double wordSpacing,
                                 double height) {
  FTL_DCHECK(encoded.num_elements() == 8);
  RefPtr<RenderStyle> style = RenderStyle::create();
  style->inheritFrom(m_currentRenderObject->style());

  int32_t mask = encoded[0];

  if (mask & tsColorMask)
    style->setColor(getColorFromARGB(encoded[tsColorIndex]));

  if (mask & tsTextDecorationMask) {
    style->setTextDecoration(
        static_cast<TextDecoration>(encoded[tsTextDecorationIndex]));
    style->applyTextDecorations();
  }

  if (mask & tsTextDecorationColorMask)
    style->setTextDecorationColor(
        StyleColor(getColorFromARGB(encoded[tsTextDecorationColorIndex])));

  if (mask & tsTextDecorationStyleMask)
    style->setTextDecorationStyle(
        static_cast<TextDecorationStyle>(encoded[tsTextDecorationStyleIndex]));

  if (mask & tsTextBaselineMask) {
    // TODO(abarth): Implement TextBaseline. The CSS version of this
    // property wasn't wired up either.
  }

  if (mask & (tsFontWeightMask | tsFontStyleMask | tsFontFamilyMask |
              tsFontSizeMask | tsLetterSpacingMask | tsWordSpacingMask)) {
    FontDescription fontDescription = style->fontDescription();

    if (mask & tsFontWeightMask)
      fontDescription.setWeight(
          static_cast<FontWeight>(encoded[tsFontWeightIndex]));

    if (mask & tsFontStyleMask)
      fontDescription.setStyle(
          static_cast<FontStyle>(encoded[tsFontStyleIndex]));

    if (mask & tsFontFamilyMask) {
      FontFamily family;
      family.setFamily(String::fromUTF8(fontFamily));
      fontDescription.setFamily(family);
    }

    if (mask & tsFontSizeMask) {
      fontDescription.setSpecifiedSize(fontSize);
      fontDescription.setIsAbsoluteSize(true);
      fontDescription.setComputedSize(
          getComputedSizeFromSpecifiedSize(fontSize));
    }

    if (mask & tsLetterSpacingMask)
      fontDescription.setLetterSpacing(letterSpacing);

    if (mask & tsWordSpacingMask)
      fontDescription.setWordSpacing(wordSpacing);

    style->setFontDescription(fontDescription);
    style->font().update(UIDartState::Current()->font_selector());
  }

  if (mask & tsHeightMask) {
    style->setLineHeight(Length(height * 100.0, Percent));
  }

  encoded.Release();

  RenderObject* span = new RenderInline();
  span->setStyle(style.release());
  m_currentRenderObject->addChild(span);
  m_currentRenderObject = span;
}

void ParagraphBuilder::pop() {
  if (m_currentRenderObject)
    m_currentRenderObject = m_currentRenderObject->parent();
}

void ParagraphBuilder::addText(const std::string& text) {
  if (!m_currentRenderObject)
    return;
  RenderText* renderText = new RenderText(String::fromUTF8(text).impl());
  RefPtr<RenderStyle> style = RenderStyle::create();
  style->inheritFrom(m_currentRenderObject->style());
  renderText->setStyle(style.release());
  m_currentRenderObject->addChild(renderText);
}

ftl::RefPtr<Paragraph> ParagraphBuilder::build() {
  m_currentRenderObject = nullptr;
  return Paragraph::create(m_renderView.release());
}

void ParagraphBuilder::createRenderView() {
  RefPtr<RenderStyle> style = RenderStyle::create();
  style->setRTLOrdering(LogicalOrder);
  style->setZIndex(0);
  style->setUserModify(READ_ONLY);
  createFontForDocument(style.get());

  m_renderView = adoptPtr(new RenderView());
  m_renderView->setStyle(style.release());
}

}  // namespace blink
