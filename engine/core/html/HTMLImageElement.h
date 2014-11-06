/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2004, 2008, 2010 Apple Inc. All rights reserved.
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
 *
 */

#ifndef HTMLImageElement_h
#define HTMLImageElement_h

#include "core/html/HTMLElement.h"
#include "core/html/HTMLImageLoader.h"
#include "core/html/canvas/CanvasImageSource.h"
#include "platform/graphics/GraphicsTypes.h"
#include "wtf/WeakPtr.h"

namespace blink {

class ImageCandidate;
class MediaQueryList;

class HTMLImageElement final : public HTMLElement, public CanvasImageSource {
    DEFINE_WRAPPERTYPEINFO();
public:
    class ViewportChangeListener;

    static PassRefPtr<HTMLImageElement> create(Document&);
    static PassRefPtr<HTMLImageElement> create(Document&, bool createdByParser);
    static PassRefPtr<HTMLImageElement> createForJSConstructor(Document&, int width, int height);

    virtual ~HTMLImageElement();
    virtual void trace(Visitor*) override;

    int width(bool ignorePendingStylesheets = false);
    int height(bool ignorePendingStylesheets = false);

    int naturalWidth() const;
    int naturalHeight() const;
    const String& currentSrc() const;

    bool isServerMap() const;

    const AtomicString& altText() const;

    CompositeOperator compositeOperator() const { return m_compositeOperator; }

    ImageResource* cachedImage() const { return imageLoader().image(); }
    void setImageResource(ImageResource* i) { imageLoader().setImage(i); };

    void setHeight(int);

    KURL src() const;
    void setSrc(const String&);

    void setWidth(int);

    int x() const;
    int y() const;

    bool complete() const;

    bool hasPendingActivity() const { return imageLoader().hasPendingActivity(); }

    virtual bool canContainRangeEndPoint() const override { return false; }

    void addClient(ImageLoaderClient* client) { imageLoader().addClient(client); }
    void removeClient(ImageLoaderClient* client) { imageLoader().removeClient(client); }

    virtual const AtomicString imageSourceURL() const override;

    // CanvasImageSourceImplementations
    virtual PassRefPtr<Image> getSourceImageForCanvas(SourceImageMode, SourceImageStatus*) const;
    virtual FloatSize sourceSize() const override;
    virtual FloatSize defaultDestinationSize() const override;
    virtual const KURL& sourceURL() const override;

protected:
    explicit HTMLImageElement(Document&, bool createdByParser = false);

    virtual void didMoveToNewDocument(Document& oldDocument) override;

private:
    virtual void parseAttribute(const QualifiedName&, const AtomicString&) override;

    void selectSourceURL(ImageLoader::UpdateFromElementBehavior);

    virtual void attach(const AttachContext& = AttachContext()) override;
    virtual RenderObject* createRenderer(RenderStyle*) override;

    virtual bool canStartSelection() const override;

    virtual bool isURLAttribute(const Attribute&) const override;

    virtual InsertionNotificationRequest insertedInto(ContainerNode*) override;
    virtual void removedFrom(ContainerNode*) override;
    virtual Image* imageContents() override;

    void setBestFitURLAndDPRFromImageCandidate(const ImageCandidate&);
    HTMLImageLoader& imageLoader() const { return *m_imageLoader; }
    void notifyViewportChanged();
    void createMediaQueryListIfDoesNotExist();

    OwnPtr<HTMLImageLoader> m_imageLoader;
    RefPtr<ViewportChangeListener> m_listener;
    CompositeOperator m_compositeOperator;
    AtomicString m_bestFitImageURL;
    float m_imageDevicePixelRatio;
    unsigned m_elementCreatedByParser : 1;
    // Intrinsic sizing is viewport dependant if the 'w' descriptor was used for the picked resource.
    unsigned m_intrinsicSizingViewportDependant : 1;
    // Effective size is viewport dependant if the sizes attribute's effective size used v* length units.
    unsigned m_effectiveSizeViewportDependant : 1;
};

} // namespace blink

#endif // HTMLImageElement_h
