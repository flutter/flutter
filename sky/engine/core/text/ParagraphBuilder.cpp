// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/core/text/ParagraphBuilder.h"

#include "sky/engine/core/css/CSSFontSelector.h"
#include "sky/engine/core/css/resolver/FontBuilder.h"
#include "sky/engine/core/rendering/RenderParagraph.h"
#include "sky/engine/core/rendering/RenderText.h"
#include "sky/engine/core/rendering/style/RenderStyle.h"

namespace blink {
namespace {

PassOwnPtr<RenderView> createRenderView()
{
    RefPtr<RenderStyle> style = RenderStyle::create();
    style->setRTLOrdering(LogicalOrder);
    style->setZIndex(0);
    style->setUserModify(READ_ONLY);

    FontBuilder fontBuilder;
    fontBuilder.initForStyleResolve(nullptr, style.get());
    RefPtr<CSSFontSelector> selector = CSSFontSelector::create(nullptr);
    fontBuilder.createFontForDocument(selector.release(), style.get());

    OwnPtr<RenderView> renderView = adoptPtr(new RenderView(nullptr));
    renderView->setStyle(style.release());
    return renderView.release();
}

RenderParagraph* createRenderParagraph(RenderStyle* parentStyle)
{
    RefPtr<RenderStyle> style = RenderStyle::create();
    style->inheritFrom(parentStyle);
    style->setDisplay(PARAGRAPH);

    RenderParagraph* renderParagraph = new RenderParagraph(nullptr);
    renderParagraph->setStyle(style.release());
    return renderParagraph;
}

}  // namespace

ParagraphBuilder::ParagraphBuilder()
{
    m_renderView = createRenderView();
    m_parentStyle = RenderStyle::clone(m_renderView->style());
    m_renderParagraph = createRenderParagraph(m_parentStyle.get());
    m_parentStyle = RenderStyle::clone(m_renderParagraph->style());
    m_renderView->addChild(m_renderParagraph);
}

ParagraphBuilder::~ParagraphBuilder()
{
}

void ParagraphBuilder::pushStyle(TextStyle* style)
{
}

void ParagraphBuilder::pop()
{
}

void ParagraphBuilder::addText(const String& text)
{
    RenderText* renderText = new RenderText(nullptr, text.impl());
    RefPtr<RenderStyle> style = RenderStyle::create();
    style->inheritFrom(m_parentStyle.get());
    renderText->setStyle(style.release());
    m_renderParagraph->addChild(renderText);
}

PassRefPtr<Paragraph> ParagraphBuilder::build(ParagraphStyle* style)
{
    m_parentStyle = nullptr;
    m_renderParagraph = nullptr;
    return Paragraph::create(m_renderView.release());
}

} // namespace blink
