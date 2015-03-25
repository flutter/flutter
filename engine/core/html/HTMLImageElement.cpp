/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/core/html/HTMLImageElement.h"

#include "gen/sky/core/CSSPropertyNames.h"
#include "gen/sky/core/HTMLNames.h"
#include "gen/sky/core/MediaTypeNames.h"
#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "sky/engine/core/css/MediaQueryListListener.h"
#include "sky/engine/core/css/MediaQueryMatcher.h"
#include "sky/engine/core/css/MediaValuesDynamic.h"
#include "sky/engine/core/dom/Attribute.h"
#include "sky/engine/core/dom/NodeTraversal.h"
#include "sky/engine/core/fetch/ImageResource.h"
#include "sky/engine/core/html/HTMLAnchorElement.h"
#include "sky/engine/core/html/parser/HTMLParserIdioms.h"
#include "sky/engine/core/html/parser/HTMLSrcsetParser.h"
#include "sky/engine/core/inspector/ConsoleMessage.h"
#include "sky/engine/core/rendering/RenderImage.h"
#include "sky/engine/platform/MIMETypeRegistry.h"

namespace blink {

class HTMLImageElement::ViewportChangeListener final : public MediaQueryListListener {
public:
    static RefPtr<ViewportChangeListener> create(HTMLImageElement* element)
    {
        return adoptRef(new ViewportChangeListener(element));
    }

    virtual void notifyMediaQueryChanged() override
    {
        if (m_element)
            m_element->notifyViewportChanged();
    }

    void clearElement() { m_element = nullptr; }

private:
    explicit ViewportChangeListener(HTMLImageElement* element) : m_element(element) { }
    RawPtr<HTMLImageElement> m_element;
};

HTMLImageElement::HTMLImageElement(Document& document, bool createdByParser)
    : HTMLElement(HTMLNames::imgTag, document)
    , m_imageLoader(HTMLImageLoader::create(this))
    , m_imageDevicePixelRatio(1.0f)
    , m_elementCreatedByParser(createdByParser)
    , m_intrinsicSizingViewportDependant(false)
    , m_effectiveSizeViewportDependant(false)
{
}

PassRefPtr<HTMLImageElement> HTMLImageElement::create(Document& document)
{
    return adoptRef(new HTMLImageElement(document));
}

PassRefPtr<HTMLImageElement> HTMLImageElement::create(Document& document, bool createdByParser)
{
    return adoptRef(new HTMLImageElement(document, createdByParser));
}

HTMLImageElement::~HTMLImageElement()
{
#if !ENABLE(OILPAN)
    if (m_listener) {
        document().mediaQueryMatcher().removeViewportListener(m_listener.get());
        m_listener->clearElement();
    }
#endif
}

void HTMLImageElement::notifyViewportChanged()
{
    // Re-selecting the source URL in order to pick a more fitting resource
    // And update the image's intrinsic dimensions when the viewport changes.
    // Picking of a better fitting resource is UA dependant, not spec required.
    selectSourceURL(ImageLoader::UpdateSizeChanged);
}

PassRefPtr<HTMLImageElement> HTMLImageElement::createForJSConstructor(Document& document, int width, int height)
{
    RefPtr<HTMLImageElement> image = adoptRef(new HTMLImageElement(document));
    if (width)
        image->setWidth(width);
    if (height)
        image->setHeight(height);
    image->m_elementCreatedByParser = false;
    return image.release();
}

const AtomicString HTMLImageElement::imageSourceURL() const
{
    return m_bestFitImageURL.isNull() ? getAttribute(HTMLNames::srcAttr) : m_bestFitImageURL;
}

void HTMLImageElement::setBestFitURLAndDPRFromImageCandidate(const ImageCandidate& candidate)
{
    m_bestFitImageURL = candidate.url();
    float candidateDensity = candidate.density();
    if (candidateDensity >= 0)
        m_imageDevicePixelRatio = 1.0 / candidateDensity;
    if (candidate.resourceWidth() > 0)
        m_intrinsicSizingViewportDependant = true;
    if (renderer() && renderer()->isImage())
        toRenderImage(renderer())->setImageDevicePixelRatio(m_imageDevicePixelRatio);
}

void HTMLImageElement::parseAttribute(const QualifiedName& name, const AtomicString& value)
{
    if (name == HTMLNames::srcAttr) {
        selectSourceURL(ImageLoader::UpdateIgnorePreviousError);
    } else {
        HTMLElement::parseAttribute(name, value);
    }
}

RenderObject* HTMLImageElement::createRenderer(RenderStyle* style)
{
    RenderImage* image = new RenderImage(this);
    image->setImageResource(RenderImageResource::create());
    image->setImageDevicePixelRatio(m_imageDevicePixelRatio);

    RenderImageResource* imageResource = image->imageResource();
    if (cachedImage() || imageResource->cachedImage())
        imageResource->setImageResource(cachedImage());

    return image;
}

bool HTMLImageElement::canStartSelection() const
{
    if (shadow())
        return HTMLElement::canStartSelection();

    return false;
}

void HTMLImageElement::insertedInto(ContainerNode* insertionPoint)
{
    HTMLElement::insertedInto(insertionPoint);

    if (m_listener)
        document().mediaQueryMatcher().addViewportListener(m_listener.get());

    // If we have been inserted from a renderer-less document,
    // our loader may have not fetched the image, so do it now.
    if ((insertionPoint->inDocument() && !imageLoader().image()))
        imageLoader().updateFromElement(ImageLoader::UpdateNormal, m_elementCreatedByParser ? ImageLoader::ForceLoadImmediately : ImageLoader::LoadNormally);
}

void HTMLImageElement::removedFrom(ContainerNode* insertionPoint)
{
    if (m_listener)
        document().mediaQueryMatcher().removeViewportListener(m_listener.get());
    HTMLElement::removedFrom(insertionPoint);
}

int HTMLImageElement::width()
{
    if (!renderer()) {
        // check the attribute first for an explicit pixel value
        bool ok;
        int width = getAttribute(HTMLNames::widthAttr).toInt(&ok);
        if (ok)
            return width;

        // if the image is available, use its width
        if (imageLoader().image())
            return imageLoader().image()->imageSizeForRenderer(renderer()).width();
    }

    document().updateLayout();

    RenderBox* box = renderBox();
    return box ? box->contentBoxRect().pixelSnappedWidth() : 0;
}

int HTMLImageElement::height()
{
    if (!renderer()) {
        // check the attribute first for an explicit pixel value
        bool ok;
        int height = getAttribute(HTMLNames::heightAttr).toInt(&ok);
        if (ok)
            return height;

        // if the image is available, use its height
        if (imageLoader().image())
            return imageLoader().image()->imageSizeForRenderer(renderer()).height();
    }

    document().updateLayout();

    RenderBox* box = renderBox();
    return box ? box->contentBoxRect().pixelSnappedHeight() : 0;
}

int HTMLImageElement::naturalWidth() const
{
    if (!imageLoader().image())
        return 0;

    return imageLoader().image()->imageSizeForRenderer(renderer(), ImageResource::IntrinsicSize).width();
}

int HTMLImageElement::naturalHeight() const
{
    if (!imageLoader().image())
        return 0;

    return imageLoader().image()->imageSizeForRenderer(renderer(), ImageResource::IntrinsicSize).height();
}

const String& HTMLImageElement::currentSrc() const
{
    // http://www.whatwg.org/specs/web-apps/current-work/multipage/edits.html#dom-img-currentsrc
    // The currentSrc IDL attribute must return the img element's current request's current URL.
    // Initially, the pending request turns into current request when it is either available or broken.
    // We use the image's dimensions as a proxy to it being in any of these states.
    if (!imageLoader().image() || !imageLoader().image()->image() || !imageLoader().image()->image()->width())
        return emptyAtom;

    return imageLoader().image()->url().string();
}

bool HTMLImageElement::isURLAttribute(const Attribute& attribute) const
{
    return attribute.name() == HTMLNames::srcAttr
        || HTMLElement::isURLAttribute(attribute);
}

void HTMLImageElement::setHeight(int value)
{
    setIntegralAttribute(HTMLNames::heightAttr, value);
}

KURL HTMLImageElement::src() const
{
    return document().completeURL(getAttribute(HTMLNames::srcAttr));
}

void HTMLImageElement::setSrc(const String& value)
{
    setAttribute(HTMLNames::srcAttr, AtomicString(value));
}

void HTMLImageElement::setWidth(int value)
{
    setIntegralAttribute(HTMLNames::widthAttr, value);
}

int HTMLImageElement::x() const
{
    document().updateLayout();
    RenderObject* r = renderer();
    if (!r)
        return 0;

    // FIXME: This doesn't work correctly with transforms.
    FloatPoint absPos = r->localToAbsolute();
    return absPos.x();
}

int HTMLImageElement::y() const
{
    document().updateLayout();
    RenderObject* r = renderer();
    if (!r)
        return 0;

    // FIXME: This doesn't work correctly with transforms.
    FloatPoint absPos = r->localToAbsolute();
    return absPos.y();
}

bool HTMLImageElement::complete() const
{
    return imageLoader().imageComplete();
}

void HTMLImageElement::didMoveToNewDocument(Document& oldDocument)
{
    imageLoader().elementDidMoveToNewDocument();
    HTMLElement::didMoveToNewDocument(oldDocument);
}

void HTMLImageElement::selectSourceURL(ImageLoader::UpdateFromElementBehavior behavior)
{
    unsigned effectiveSize = 0;
    ImageCandidate candidate = bestFitSourceForImageAttributes(
        document().devicePixelRatio(), effectiveSize,
        getAttribute(HTMLNames::srcAttr), AtomicString());
    setBestFitURLAndDPRFromImageCandidate(candidate);
    if (m_intrinsicSizingViewportDependant && m_effectiveSizeViewportDependant && !m_listener.get()) {
        m_listener = ViewportChangeListener::create(this);
        document().mediaQueryMatcher().addViewportListener(m_listener.get());
    }
    imageLoader().updateFromElement(behavior);
}

}
