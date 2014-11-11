// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/html/HTMLIFrameElement.h"

#include "core/HTMLNames.h"
#include "core/frame/LocalFrame.h"
#include "core/html/parser/HTMLParserIdioms.h"
#include "core/loader/FrameLoaderClient.h"
#include "core/rendering/RenderRemote.h"

namespace blink {

PassRefPtr<HTMLIFrameElement> HTMLIFrameElement::create(Document& document)
{
    return adoptRef(new HTMLIFrameElement(document));
}

HTMLIFrameElement::HTMLIFrameElement(Document& document)
    : HTMLElement(HTMLNames::iframeTag, document),
      m_contentView(nullptr)
{
}

HTMLIFrameElement::~HTMLIFrameElement()
{
}

Node::InsertionNotificationRequest HTMLIFrameElement::insertedInto(ContainerNode* insertionPoint)
{
    InsertionNotificationRequest result = HTMLElement::insertedInto(insertionPoint);
    if (insertionPoint->inDocument())
        createView();
    return result;
}

void HTMLIFrameElement::removedFrom(ContainerNode* insertionPoint)
{
    HTMLElement::removedFrom(insertionPoint);
    if (insertionPoint->inDocument()) {
        // TODO(mpcomplete): Tear down the mojo View.
    }
}

RenderObject* HTMLIFrameElement::createRenderer(RenderStyle* style)
{
    return new RenderRemote(this);
}

void HTMLIFrameElement::OnViewDestroyed(mojo::View* view)
{
    DCHECK_EQ(view, m_contentView);
    m_contentView = nullptr;
}

void HTMLIFrameElement::createView()
{
    String urlString = stripLeadingAndTrailingHTMLSpaces(getAttribute(HTMLNames::srcAttr));
    if (urlString.isEmpty())
        urlString = blankURL().string();

    LocalFrame* parentFrame = document().frame();
    if (!parentFrame)
        return;

    KURL url = document().completeURL(urlString);
    m_contentView = parentFrame->loaderClient()->createChildFrame(url);
}

}
