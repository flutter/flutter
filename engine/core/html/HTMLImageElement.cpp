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

#include "config.h"
#include "core/html/HTMLImageElement.h"

#include "core/CSSPropertyNames.h"
#include "core/HTMLNames.h"
#include "core/MediaTypeNames.h"
#include "core/css/MediaQueryListListener.h"
#include "core/css/MediaQueryMatcher.h"
#include "core/css/MediaValuesDynamic.h"
#include "core/dom/Attribute.h"
#include "core/dom/NodeTraversal.h"
#include "core/fetch/ImageResource.h"
#include "core/frame/UseCounter.h"
#include "core/html/HTMLAnchorElement.h"
#include "core/html/HTMLCanvasElement.h"
#include "core/html/canvas/CanvasRenderingContext.h"
#include "core/html/parser/HTMLParserIdioms.h"
#include "core/html/parser/HTMLSrcsetParser.h"
#include "core/inspector/ConsoleMessage.h"
#include "core/rendering/RenderImage.h"
#include "platform/MIMETypeRegistry.h"
#include "platform/RuntimeEnabledFeatures.h"

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
    if (candidate.resourceWidth() > 0) {
        m_intrinsicSizingViewportDependant = true;
        UseCounter::count(document(), UseCounter::SrcsetWDescriptor);
    } else if (!candidate.srcOrigin()) {
        UseCounter::count(document(), UseCounter::SrcsetXDescriptor);
    }
    if (renderer() && renderer()->isImage())
        toRenderImage(renderer())->setImageDevicePixelRatio(m_imageDevicePixelRatio);
}

void HTMLImageElement::parseAttribute(const QualifiedName& name, const AtomicString& value)
{
    if (name == HTMLNames::srcAttr || name == HTMLNames::srcsetAttr || name == HTMLNames::sizesAttr) {
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
    return image;
}

bool HTMLImageElement::canStartSelection() const
{
    if (shadow())
        return HTMLElement::canStartSelection();

    return false;
}

void HTMLImageElement::attach(const AttachContext& context)
{
    HTMLElement::attach(context);

    if (renderer() && renderer()->isImage()) {
        RenderImage* renderImage = toRenderImage(renderer());
        RenderImageResource* renderImageResource = renderImage->imageResource();
        if (renderImageResource->hasImage())
            return;

        if (imageLoader().image() || renderImageResource->cachedImage())
            renderImageResource->setImageResource(imageLoader().image());
    }
}

Node::InsertionNotificationRequest HTMLImageElement::insertedInto(ContainerNode* insertionPoint)
{
    if (m_listener)
        document().mediaQueryMatcher().addViewportListener(m_listener.get());

    // If we have been inserted from a renderer-less document,
    // our loader may have not fetched the image, so do it now.
    if ((insertionPoint->inDocument() && !imageLoader().image()))
        imageLoader().updateFromElement(ImageLoader::UpdateNormal, m_elementCreatedByParser ? ImageLoader::ForceLoadImmediately : ImageLoader::LoadNormally);

    return HTMLElement::insertedInto(insertionPoint);
}

void HTMLImageElement::removedFrom(ContainerNode* insertionPoint)
{
    if (m_listener)
        document().mediaQueryMatcher().removeViewportListener(m_listener.get());
    HTMLElement::removedFrom(insertionPoint);
}

int HTMLImageElement::width(bool ignorePendingStylesheets)
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

    if (ignorePendingStylesheets)
        document().updateLayoutIgnorePendingStylesheets();
    else
        document().updateLayout();

    RenderBox* box = renderBox();
    return box ? box->contentBoxRect().pixelSnappedWidth() : 0;
}

int HTMLImageElement::height(bool ignorePendingStylesheets)
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

    if (ignorePendingStylesheets)
        document().updateLayoutIgnorePendingStylesheets();
    else
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
    document().updateLayoutIgnorePendingStylesheets();
    RenderObject* r = renderer();
    if (!r)
        return 0;

    // FIXME: This doesn't work correctly with transforms.
    FloatPoint absPos = r->localToAbsolute();
    return absPos.x();
}

int HTMLImageElement::y() const
{
    document().updateLayoutIgnorePendingStylesheets();
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

Image* HTMLImageElement::imageContents()
{
    if (!imageLoader().imageComplete())
        return 0;

    return imageLoader().image()->image();
}

PassRefPtr<Image> HTMLImageElement::getSourceImageForCanvas(SourceImageMode, SourceImageStatus* status) const
{
    if (!complete() || !cachedImage()) {
        *status = IncompleteSourceImageStatus;
        return nullptr;
    }

    if (cachedImage()->errorOccurred()) {
        *status = UndecodableSourceImageStatus;
        return nullptr;
    }

    RefPtr<Image> sourceImage = cachedImage()->imageForRenderer(renderer());

    // We need to synthesize a container size if a renderer is not available to provide one.
    if (!renderer() && sourceImage->usesContainerSize())
        sourceImage->setContainerSize(sourceImage->size());

    *status = NormalSourceImageStatus;
    return sourceImage->imageForDefaultFrame();
}

FloatSize HTMLImageElement::sourceSize() const
{
    ImageResource* image = cachedImage();
    if (!image)
        return FloatSize();
    return image->imageSizeForRenderer(renderer()); // FIXME: Not sure about this.
}

FloatSize HTMLImageElement::defaultDestinationSize() const
{
    ImageResource* image = cachedImage();
    if (!image)
        return FloatSize();
    LayoutSize size;
    size = image->imageSizeForRenderer(renderer()); // FIXME: Not sure about this.
    if (renderer() && renderer()->isRenderImage() && image->image() && !image->image()->hasRelativeWidth())
        size.scale(toRenderImage(renderer())->imageDevicePixelRatio());
    return size;
}

void HTMLImageElement::selectSourceURL(ImageLoader::UpdateFromElementBehavior behavior)
{
    unsigned effectiveSize = 0;
    ImageCandidate candidate = bestFitSourceForImageAttributes(
        document().devicePixelRatio(), effectiveSize,
        getAttribute(HTMLNames::srcAttr), getAttribute(HTMLNames::srcsetAttr));
    setBestFitURLAndDPRFromImageCandidate(candidate);
    if (m_intrinsicSizingViewportDependant && m_effectiveSizeViewportDependant && !m_listener.get()) {
        m_listener = ViewportChangeListener::create(this);
        document().mediaQueryMatcher().addViewportListener(m_listener.get());
    }
    imageLoader().updateFromElement(behavior);
}

const KURL& HTMLImageElement::sourceURL() const
{
    return cachedImage()->response().url();
}

}
