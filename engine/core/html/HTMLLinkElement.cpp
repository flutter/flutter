/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2006, 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Rob Buis (rwlbuis@gmail.com)
 * Copyright (C) 2011 Google Inc. All rights reserved.
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
#include "core/html/HTMLLinkElement.h"

#include "bindings/core/v8/ScriptEventListener.h"
#include "core/HTMLNames.h"
#include "core/css/MediaList.h"
#include "core/css/MediaQueryEvaluator.h"
#include "core/css/StyleSheetContents.h"
#include "core/css/resolver/StyleResolver.h"
#include "core/dom/Attribute.h"
#include "core/dom/Document.h"
#include "core/dom/StyleEngine.h"
#include "core/events/Event.h"
#include "core/events/EventSender.h"
#include "core/fetch/FetchRequest.h"
#include "core/fetch/ResourceFetcher.h"
#include "core/frame/FrameView.h"
#include "core/frame/LocalFrame.h"
#include "core/html/imports/LinkImport.h"
#include "core/html/parser/HTMLParserIdioms.h"
#include "core/loader/FrameLoaderClient.h"
#include "core/rendering/style/RenderStyle.h"
#include "core/rendering/style/StyleInheritedData.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "wtf/StdLibExtras.h"

namespace blink {

template <typename CharacterType>
static void parseSizes(const CharacterType* value, unsigned length, Vector<IntSize>& iconSizes)
{
    enum State {
        ParseStart,
        ParseWidth,
        ParseHeight
    };
    int width = 0;
    unsigned start = 0;
    unsigned i = 0;
    State state = ParseStart;
    bool invalid = false;
    for (; i < length; ++i) {
        if (state == ParseWidth) {
            if (value[i] == 'x' || value[i] == 'X') {
                if (i == start) {
                    invalid = true;
                    break;
                }
                width = charactersToInt(value + start, i - start);
                start = i + 1;
                state = ParseHeight;
            } else if (value[i] < '0' || value[i] > '9') {
                invalid = true;
                break;
            }
        } else if (state == ParseHeight) {
            if (value[i] == ' ') {
                if (i == start) {
                    invalid = true;
                    break;
                }
                int height = charactersToInt(value + start, i - start);
                iconSizes.append(IntSize(width, height));
                start = i + 1;
                state = ParseStart;
            } else if (value[i] < '0' || value[i] > '9') {
                invalid = true;
                break;
            }
        } else if (state == ParseStart) {
            if (value[i] >= '0' && value[i] <= '9') {
                start = i;
                state = ParseWidth;
            } else if (value[i] != ' ') {
                invalid = true;
                break;
            }
        }
    }
    if (invalid || state == ParseWidth || (state == ParseHeight && start == i)) {
        iconSizes.clear();
        return;
    }
    if (state == ParseHeight && i > start) {
        int height = charactersToInt(value + start, i - start);
        iconSizes.append(IntSize(width, height));
    }
}

static LinkEventSender& linkLoadEventSender()
{
    DEFINE_STATIC_LOCAL(LinkEventSender, sharedLoadEventSender, (EventTypeNames::load));
    return sharedLoadEventSender;
}

void HTMLLinkElement::parseSizesAttribute(const AtomicString& value, Vector<IntSize>& iconSizes)
{
    ASSERT(iconSizes.isEmpty());
    if (value.isEmpty())
        return;
    if (value.is8Bit())
        parseSizes(value.characters8(), value.length(), iconSizes);
    else
        parseSizes(value.characters16(), value.length(), iconSizes);
}

inline HTMLLinkElement::HTMLLinkElement(Document& document, bool createdByParser)
    : HTMLElement(HTMLNames::linkTag, document)
    , m_sizes(DOMSettableTokenList::create())
    , m_createdByParser(createdByParser)
    , m_isInShadowTree(false)
{
    ScriptWrappable::init(this);
}

PassRefPtrWillBeRawPtr<HTMLLinkElement> HTMLLinkElement::create(Document& document, bool createdByParser)
{
    return adoptRefWillBeNoop(new HTMLLinkElement(document, createdByParser));
}

HTMLLinkElement::~HTMLLinkElement()
{
#if !ENABLE(OILPAN)
    m_link.clear();

    if (inDocument())
        document().styleEngine()->removeStyleSheetCandidateNode(this);
#endif

    linkLoadEventSender().cancelEvent(this);
}

void HTMLLinkElement::parseAttribute(const QualifiedName& name, const AtomicString& value)
{
    if (name == HTMLNames::relAttr) {
        m_relAttribute = LinkRelAttribute(value);
        process();
    } else if (name == HTMLNames::hrefAttr) {
        process();
    } else if (name == HTMLNames::typeAttr) {
        m_type = value;
        process();
    } else if (name == HTMLNames::sizesAttr) {
        m_sizes->setValue(value);
        parseSizesAttribute(value, m_iconSizes);
        process();
    } else if (name == HTMLNames::mediaAttr) {
        m_media = value.string().lower();
        process();
    } else {
        HTMLElement::parseAttribute(name, value);
    }
}

LinkResource* HTMLLinkElement::linkResourceToProcess()
{
    bool visible = inDocument() && !m_isInShadowTree;
    if (!visible)
        return 0;

    if (!m_link && m_relAttribute.isImport())
        m_link = LinkImport::create(this);

    return m_link.get();
}

LinkImport* HTMLLinkElement::linkImport() const
{
    if (!m_link || m_link->type() != LinkResource::Import)
        return 0;
    return static_cast<LinkImport*>(m_link.get());
}

Document* HTMLLinkElement::import() const
{
    if (LinkImport* link = linkImport())
        return link->importedDocument();
    return 0;
}

void HTMLLinkElement::process()
{
    if (LinkResource* link = linkResourceToProcess())
        link->process();
}

Node::InsertionNotificationRequest HTMLLinkElement::insertedInto(ContainerNode* insertionPoint)
{
    HTMLElement::insertedInto(insertionPoint);
    if (!insertionPoint->inDocument())
        return InsertionDone;

    m_isInShadowTree = isInShadowTree();
    if (m_isInShadowTree)
        return InsertionDone;

    document().styleEngine()->addStyleSheetCandidateNode(this, m_createdByParser);

    process();

    if (m_link)
        m_link->ownerInserted();

    return InsertionDone;
}

void HTMLLinkElement::removedFrom(ContainerNode* insertionPoint)
{
    HTMLElement::removedFrom(insertionPoint);
    if (!insertionPoint->inDocument())
        return;

    if (m_isInShadowTree)
        return;
    document().styleEngine()->removeStyleSheetCandidateNode(this);

    RefPtrWillBeRawPtr<StyleSheet> removedSheet = sheet();

    if (m_link)
        m_link->ownerRemoved();

    document().removedStyleSheet(removedSheet.get());
}

void HTMLLinkElement::finishParsingChildren()
{
    m_createdByParser = false;
    HTMLElement::finishParsingChildren();
}

void HTMLLinkElement::dispatchPendingLoadEvents()
{
    linkLoadEventSender().dispatchPendingEvents();
}

void HTMLLinkElement::dispatchPendingEvent(LinkEventSender* eventSender)
{
    ASSERT_UNUSED(eventSender, eventSender == &linkLoadEventSender());
    ASSERT(m_link);
    // FIXME(sky): Remove
}

void HTMLLinkElement::scheduleEvent()
{
    linkLoadEventSender().dispatchEventSoon(this);
}

bool HTMLLinkElement::isURLAttribute(const Attribute& attribute) const
{
    return attribute.name().localName() == HTMLNames::hrefAttr || HTMLElement::isURLAttribute(attribute);
}

bool HTMLLinkElement::hasLegalLinkAttribute(const QualifiedName& name) const
{
    return name == HTMLNames::hrefAttr || HTMLElement::hasLegalLinkAttribute(name);
}

const QualifiedName& HTMLLinkElement::subResourceAttributeName() const
{
    // If the link element is not css, ignore it.
    if (equalIgnoringCase(getAttribute(HTMLNames::typeAttr), "text/css")) {
        // FIXME: Add support for extracting links of sub-resources which
        // are inside style-sheet such as @import, @font-face, url(), etc.
        return HTMLNames::hrefAttr;
    }
    return HTMLElement::subResourceAttributeName();
}

KURL HTMLLinkElement::href() const
{
    return document().completeURL(getAttribute(HTMLNames::hrefAttr));
}

const AtomicString& HTMLLinkElement::rel() const
{
    return getAttribute(HTMLNames::relAttr);
}

const AtomicString& HTMLLinkElement::type() const
{
    return getAttribute(HTMLNames::typeAttr);
}

bool HTMLLinkElement::async() const
{
    return hasAttribute(HTMLNames::asyncAttr);
}

String HTMLLinkElement::as() const
{
    return stripLeadingAndTrailingHTMLSpaces(getAttribute(HTMLNames::asAttr));
}

const Vector<IntSize>& HTMLLinkElement::iconSizes() const
{
    return m_iconSizes;
}

DOMSettableTokenList* HTMLLinkElement::sizes() const
{
    return m_sizes.get();
}

void HTMLLinkElement::trace(Visitor* visitor)
{
    visitor->trace(m_link);
    visitor->trace(m_sizes);
    HTMLElement::trace(visitor);
}

} // namespace blink
