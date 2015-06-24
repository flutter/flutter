/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Simon Hausmann <hausmann@kde.org>
 * Copyright (C) 2003, 2006, 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
 *           (C) 2006 Graham Dennis (graham.dennis@gmail.com)
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
 */

#include "sky/engine/core/html/HTMLAnchorElement.h"

#include "mojo/services/navigation/public/interfaces/navigation.mojom.h"
#include "sky/engine/core/dom/Attribute.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/events/KeyboardEvent.h"
#include "sky/engine/core/frame/FrameHost.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/html/HTMLImageElement.h"
#include "sky/engine/core/html/parser/HTMLParserIdioms.h"
#include "sky/engine/core/loader/FrameLoaderClient.h"
#include "sky/engine/core/loader/FrameLoaderTypes.h"
#include "sky/engine/core/page/ChromeClient.h"
#include "sky/engine/core/rendering/RenderImage.h"
#include "sky/engine/platform/network/ResourceRequest.h"
#include "sky/engine/platform/weborigin/KnownPorts.h"
#include "sky/engine/platform/weborigin/SecurityPolicy.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/public/platform/ServiceProvider.h"
#include "sky/engine/public/platform/WebURL.h"
#include "sky/engine/public/platform/WebURLRequest.h"
#include "sky/engine/wtf/text/StringBuilder.h"

namespace blink {

static bool isLinkClick(Event* event)
{
    return event->type() == EventTypeNames::click;
}

PassRefPtr<HTMLAnchorElement> HTMLAnchorElement::create(Document& document)
{
    return adoptRef(new HTMLAnchorElement(document));
}

HTMLAnchorElement::HTMLAnchorElement(Document& document)
    : HTMLElement(HTMLNames::aTag, document)
{
}

HTMLAnchorElement::~HTMLAnchorElement()
{
}

bool HTMLAnchorElement::supportsFocus() const
{
    if (hasEditableStyle())
        return HTMLElement::supportsFocus();
    return true;
}

void HTMLAnchorElement::defaultEventHandler(Event* event)
{
    if (isLinkClick(event) && isLiveLink()) {
        handleClick(event);
        return;
    }
}

bool HTMLAnchorElement::isURLAttribute(const Attribute& attribute) const
{
    return attribute.name() == HTMLNames::hrefAttr || HTMLElement::isURLAttribute(attribute);
}

bool HTMLAnchorElement::canStartSelection() const
{
    return hasEditableStyle();
}

KURL HTMLAnchorElement::href() const
{
    return document().completeURL(stripLeadingAndTrailingHTMLSpaces(getAttribute(HTMLNames::hrefAttr)));
}

void HTMLAnchorElement::setHref(const AtomicString& value)
{
    setAttribute(HTMLNames::hrefAttr, value);
}

bool HTMLAnchorElement::isLiveLink() const
{
    return !hasEditableStyle();
}

void HTMLAnchorElement::handleClick(Event* event)
{
    Frame* frame = document().frame();
    if (!frame)
        return;
    FrameHost* host = frame->host();
    if (!host)
        return;
    mojo::URLRequestPtr request = mojo::URLRequest::New();
    request->url = href().string().toUTF8();
    host->services()->NavigatorHost()->RequestNavigate(
        mojo::TARGET_SOURCE_NODE, request.Pass());
    event->setDefaultHandled();
}

}
