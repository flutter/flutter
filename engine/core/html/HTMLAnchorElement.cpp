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

#include "config.h"
#include "core/html/HTMLAnchorElement.h"

#include "core/dom/Attribute.h"
#include "core/editing/FrameSelection.h"
#include "core/events/KeyboardEvent.h"
#include "core/events/MouseEvent.h"
#include "core/frame/FrameHost.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/frame/UseCounter.h"
#include "core/html/HTMLImageElement.h"
#include "core/html/parser/HTMLParserIdioms.h"
#include "core/loader/FrameLoaderClient.h"
#include "core/loader/FrameLoaderTypes.h"
#include "core/page/Chrome.h"
#include "core/page/ChromeClient.h"
#include "core/rendering/RenderImage.h"
#include "mojo/services/public/interfaces/navigation/navigation.mojom.h"
#include "platform/PlatformMouseEvent.h"
#include "platform/network/ResourceRequest.h"
#include "platform/weborigin/KnownPorts.h"
#include "platform/weborigin/SecurityPolicy.h"
#include "public/platform/Platform.h"
#include "public/platform/ServiceProvider.h"
#include "public/platform/WebURL.h"
#include "public/platform/WebURLRequest.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

static bool isEnterKeyKeydownEvent(Event* event)
{
    return event->type() == EventTypeNames::keydown && event->isKeyboardEvent() && toKeyboardEvent(event)->keyIdentifier() == "Enter";
}

static bool isLinkClick(Event* event)
{
    return event->type() == EventTypeNames::click && (!event->isMouseEvent() || toMouseEvent(event)->button() != RightButton);
}

PassRefPtr<HTMLAnchorElement> HTMLAnchorElement::create(Document& document)
{
    return adoptRef(new HTMLAnchorElement(document));
}

HTMLAnchorElement::HTMLAnchorElement(Document& document)
    : HTMLElement(HTMLNames::aTag, document)
{
    ScriptWrappable::init(this);
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
    if (focused() && isEnterKeyKeydownEvent(event) && isLiveLink()) {
        event->setDefaultHandled();
        dispatchSimulatedClick(event);
        return;
    }

    if (isLinkClick(event) && isLiveLink()) {
        handleClick(event);
        return;
    }
}

bool HTMLAnchorElement::isURLAttribute(const Attribute& attribute) const
{
    return attribute.name() == HTMLNames::hrefAttr || HTMLElement::isURLAttribute(attribute);
}

bool HTMLAnchorElement::hasLegalLinkAttribute(const QualifiedName& name) const
{
    return name == HTMLNames::hrefAttr || HTMLElement::hasLegalLinkAttribute(name);
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
    host->services().NavigatorHost()->RequestNavigate(
        mojo::TARGET_SOURCE_NODE, request.Pass());
    event->setDefaultHandled();
}

bool HTMLAnchorElement::willRespondToMouseClickEvents()
{
    return isLiveLink();
}

bool HTMLAnchorElement::isInteractiveContent() const
{
    return isLiveLink();
}

}
