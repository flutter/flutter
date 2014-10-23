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
#include "core/css/MediaQueryMatcher.h"
#include "core/css/MediaValuesDynamic.h"
#include "core/css/parser/SizesAttributeParser.h"
#include "core/dom/Attribute.h"
#include "core/dom/NodeTraversal.h"
#include "core/fetch/ImageResource.h"
#include "core/frame/UseCounter.h"
#include "core/html/HTMLAnchorElement.h"
#include "core/html/HTMLCanvasElement.h"
#include "core/html/HTMLSourceElement.h"
#include "core/html/canvas/CanvasRenderingContext.h"
#include "core/html/parser/HTMLParserIdioms.h"
#include "core/html/parser/HTMLSrcsetParser.h"
#include "core/inspector/ConsoleMessage.h"
#include "core/rendering/RenderImage.h"
#include "platform/MIMETypeRegistry.h"
#include "platform/RuntimeEnabledFeatures.h"

namespace blink {

class HTMLImageElement::ViewportChangeListener FINAL : public MediaQueryListListener {
public:
    static RefPtrWillBeRawPtr<ViewportChangeListener> create(HTMLImageElement* element)
    {
        return adoptRefWillBeNoop(new ViewportChangeListener(element));
    }

    virtual void notifyMediaQueryChanged() OVERRIDE
    {
        if (m_element)
            m_element->notifyViewportChanged();
    }

#if !ENABLE(OILPAN)
    void clearElement() { m_element = nullptr; }
#endif
    virtual void trace(Visitor* visitor) OVERRIDE
    {
        visitor->trace(m_element);
        MediaQueryListListener::trace(visitor);
    }
private:
    explicit ViewportChangeListener(HTMLImageElement* element) : m_element(element) { }
    RawPtrWillBeMember<HTMLImageElement> m_element;
};

HTMLImageElement::HTMLImageElement(Document& document, bool createdByParser)
    : HTMLElement(HTMLNames::imgTag, document)
    , m_imageLoader(HTMLImageLoader::create(this))
    , m_compositeOperator(CompositeSourceOver)
    , m_imageDevicePixelRatio(1.0f)
    , m_elementCreatedByParser(createdByParser)
    , m_intrinsicSizingViewportDependant(false)
    , m_effectiveSizeViewportDependant(false)
{
    ScriptWrappable::init(this);
}

PassRefPtrWillBeRawPtr<HTMLImageElement> HTMLImageElement::create(Document& document)
{
    return adoptRefWillBeNoop(new HTMLImageElement(document));
}

PassRefPtrWillBeRawPtr<HTMLImageElement> HTMLImageElement::create(Document& document, bool createdByParser)
{
    return adoptRefWillBeNoop(new HTMLImageElement(document, createdByParser));
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

void HTMLImageElement::trace(Visitor* visitor)
{
    visitor->trace(m_imageLoader);
    visitor->trace(m_listener);
    HTMLElement::trace(visitor);
}

void HTMLImageElement::notifyViewportChanged()
{
    // Re-selecting the source URL in order to pick a more fitting resource
    // And update the image's intrinsic dimensions when the viewport changes.
    // Picking of a better fitting resource is UA dependant, not spec required.
    selectSourceURL(ImageLoader::UpdateSizeChanged);
}

PassRefPtrWillBeRawPtr<HTMLImageElement> HTMLImageElement::createForJSConstructor(Document& document, int width, int height)
{
    RefPtrWillBeRawPtr<HTMLImageElement> image = adoptRefWillBeNoop(new HTMLImageElement(document));
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
    if (name == HTMLNames::altAttr) {
        if (renderer() && renderer()->isImage())
            toRenderImage(renderer())->updateAltText();
    } else if (name == HTMLNames::srcAttr || name == HTMLNames::srcsetAttr || name == HTMLNames::sizesAttr) {
        selectSourceURL(ImageLoader::UpdateIgnorePreviousError);
    } else if (name == HTMLNames::usemapAttr) {
        setIsLink(!value.isNull());
    } else if (name == HTMLNames::compositeAttr) {
        blink::WebBlendMode blendOp = blink::WebBlendModeNormal;
        if (!parseCompositeAndBlendOperator(value, m_compositeOperator, blendOp))
            m_compositeOperator = CompositeSourceOver;
        else if (m_compositeOperator != CompositeSourceOver)
            UseCounter::count(document(), UseCounter::HTMLImageElementComposite);
    } else {
        HTMLElement::parseAttribute(name, value);
    }
}

const AtomicString& HTMLImageElement::altText() const
{
    // lets figure out the alt text.. magic stuff
    // http://www.w3.org/TR/1998/REC-html40-19980424/appendix/notes.html#altgen
    // also heavily discussed by Hixie on bugzilla
    const AtomicString& alt = getAttribute(HTMLNames::altAttr);
    if (!alt.isNull())
        return alt;
    // fall back to title attribute
    return getAttribute(HTMLNames::titleAttr);
}

static bool supportedImageType(const String& type)
{
    return MIMETypeRegistry::isSupportedImagePrefixedMIMEType(type);
}

// http://picture.responsiveimages.org/#update-source-set
ImageCandidate HTMLImageElement::findBestFitImageFromPictureParent()
{
    ASSERT(isMainThread());
    Node* parent = parentNode();
    if (!parent || !isHTMLPictureElement(*parent))
        return ImageCandidate();
    for (Node* child = parent->firstChild(); child; child = child->nextSibling()) {
        if (child == this)
            return ImageCandidate();

        if (!isHTMLSourceElement(*child))
            continue;

        HTMLSourceElement* source = toHTMLSourceElement(child);
        if (!source->getAttribute(HTMLNames::srcAttr).isNull())
            UseCounter::countDeprecation(document(), UseCounter::PictureSourceSrc);
        String srcset = source->getAttribute(HTMLNames::srcsetAttr);
        if (srcset.isEmpty())
            continue;
        String type = source->getAttribute(HTMLNames::typeAttr);
        if (!type.isEmpty() && !supportedImageType(type))
            continue;

        if (!source->mediaQueryMatches())
            continue;

        String sizes = source->getAttribute(HTMLNames::sizesAttr);
        if (!sizes.isNull())
            UseCounter::count(document(), UseCounter::Sizes);
        SizesAttributeParser parser = SizesAttributeParser(MediaValuesDynamic::create(document()), sizes);
        unsigned effectiveSize = parser.length();
        m_effectiveSizeViewportDependant = parser.viewportDependant();
        ImageCandidate candidate = bestFitSourceForSrcsetAttribute(document().devicePixelRatio(), effectiveSize, source->getAttribute(HTMLNames::srcsetAttr));
        if (candidate.isEmpty())
            continue;
        return candidate;
    }
    return ImageCandidate();
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

        // If we have no image at all because we have no src attribute, set
        // image height and width for the alt text instead.
        if (!imageLoader().image() && !renderImageResource->cachedImage())
            renderImage->setImageSizeForAltText();
        else
            renderImageResource->setImageResource(imageLoader().image());

    }
}

Node::InsertionNotificationRequest HTMLImageElement::insertedInto(ContainerNode* insertionPoint)
{
    if (m_listener)
        document().mediaQueryMatcher().addViewportListener(m_listener.get());

    bool imageWasModified = false;
    if (RuntimeEnabledFeatures::pictureEnabled()) {
        ImageCandidate candidate = findBestFitImageFromPictureParent();
        if (!candidate.isEmpty()) {
            setBestFitURLAndDPRFromImageCandidate(candidate);
            imageWasModified = true;
        }
    }

    // If we have been inserted from a renderer-less document,
    // our loader may have not fetched the image, so do it now.
    if ((insertionPoint->inDocument() && !imageLoader().image()) || imageWasModified)
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
            return imageLoader().image()->imageSizeForRenderer(renderer(), 1.0f).width();
    }

    if (ignorePendingStylesheets)
        document().updateLayoutIgnorePendingStylesheets();
    else
        document().updateLayout();

    RenderBox* box = renderBox();
    return box ? adjustForAbsoluteZoom(box->contentBoxRect().pixelSnappedWidth(), box) : 0;
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
            return imageLoader().image()->imageSizeForRenderer(renderer(), 1.0f).height();
    }

    if (ignorePendingStylesheets)
        document().updateLayoutIgnorePendingStylesheets();
    else
        document().updateLayout();

    RenderBox* box = renderBox();
    return box ? adjustForAbsoluteZoom(box->contentBoxRect().pixelSnappedHeight(), box) : 0;
}

int HTMLImageElement::naturalWidth() const
{
    if (!imageLoader().image())
        return 0;

    return imageLoader().image()->imageSizeForRenderer(renderer(), 1.0f, ImageResource::IntrinsicSize).width();
}

int HTMLImageElement::naturalHeight() const
{
    if (!imageLoader().image())
        return 0;

    return imageLoader().image()->imageSizeForRenderer(renderer(), 1.0f, ImageResource::IntrinsicSize).height();
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
        || attribute.name() == HTMLNames::lowsrcAttr
        || attribute.name() == HTMLNames::longdescAttr
        || (attribute.name() == HTMLNames::usemapAttr && attribute.value().string()[0] != '#')
        || HTMLElement::isURLAttribute(attribute);
}

bool HTMLImageElement::hasLegalLinkAttribute(const QualifiedName& name) const
{
    return name == HTMLNames::srcAttr || HTMLElement::hasLegalLinkAttribute(name);
}

const QualifiedName& HTMLImageElement::subResourceAttributeName() const
{
    return HTMLNames::srcAttr;
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

bool HTMLImageElement::isServerMap() const
{
    if (!hasAttribute(HTMLNames::ismapAttr))
        return false;

    const AtomicString& usemap = getAttribute(HTMLNames::usemapAttr);

    // If the usemap attribute starts with '#', it refers to a map element in the document.
    if (usemap.string()[0] == '#')
        return false;

    return document().completeURL(stripLeadingAndTrailingHTMLSpaces(usemap)).isEmpty();
}

Image* HTMLImageElement::imageContents()
{
    if (!imageLoader().imageComplete())
        return 0;

    return imageLoader().image()->image();
}

bool HTMLImageElement::isInteractiveContent() const
{
    return hasAttribute(HTMLNames::usemapAttr);
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
    LayoutSize size;
    size = image->imageSizeForRenderer(renderer(), 1.0f); // FIXME: Not sure about this.

    return size;
}

FloatSize HTMLImageElement::defaultDestinationSize() const
{
    ImageResource* image = cachedImage();
    if (!image)
        return FloatSize();
    LayoutSize size;
    size = image->imageSizeForRenderer(renderer(), 1.0f); // FIXME: Not sure about this.
    if (renderer() && renderer()->isRenderImage() && image->image() && !image->image()->hasRelativeWidth())
        size.scale(toRenderImage(renderer())->imageDevicePixelRatio());
    return size;
}

void HTMLImageElement::selectSourceURL(ImageLoader::UpdateFromElementBehavior behavior)
{
    bool foundURL = false;
    if (RuntimeEnabledFeatures::pictureEnabled()) {
        ImageCandidate candidate = findBestFitImageFromPictureParent();
        if (!candidate.isEmpty()) {
            setBestFitURLAndDPRFromImageCandidate(candidate);
            foundURL = true;
        }
    }

    if (!foundURL) {
        unsigned effectiveSize = 0;
        if (RuntimeEnabledFeatures::pictureSizesEnabled()) {
            String sizes = getAttribute(HTMLNames::sizesAttr);
            if (!sizes.isNull())
                UseCounter::count(document(), UseCounter::Sizes);
            SizesAttributeParser parser = SizesAttributeParser(MediaValuesDynamic::create(document()), sizes);
            effectiveSize = parser.length();
            m_effectiveSizeViewportDependant = parser.viewportDependant();
        }
        ImageCandidate candidate = bestFitSourceForImageAttributes(
            document().devicePixelRatio(), effectiveSize,
            getAttribute(HTMLNames::srcAttr), getAttribute(HTMLNames::srcsetAttr));
        setBestFitURLAndDPRFromImageCandidate(candidate);
    }
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
