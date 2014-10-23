/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2006 Allan Sandfeld Jensen (kde@carewolf.com)
 *           (C) 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2004, 2005, 2006, 2007, 2009, 2010, 2011 Apple Inc. All rights reserved.
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

#ifndef RenderImage_h
#define RenderImage_h

#include "core/rendering/RenderImageResource.h"
#include "core/rendering/RenderReplaced.h"

namespace blink {

class RenderImage : public RenderReplaced {
public:
    RenderImage(Element*);
    virtual ~RenderImage();
    virtual void destroy() OVERRIDE;

    static RenderImage* createAnonymous(Document*);

    void setImageResource(PassOwnPtr<RenderImageResource>);

    RenderImageResource* imageResource() { return m_imageResource.get(); }
    const RenderImageResource* imageResource() const { return m_imageResource.get(); }
    ImageResource* cachedImage() const { return m_imageResource ? m_imageResource->cachedImage() : 0; }

    bool setImageSizeForAltText(ImageResource* newImage = 0);

    void updateAltText();

    void highQualityRepaintTimerFired(Timer<RenderImage>*);

    void setIsGeneratedContent(bool generated = true) { m_isGeneratedContent = generated; }

    bool isGeneratedContent() const { return m_isGeneratedContent; }

    String altText() const { return m_altText; }

    inline void setImageDevicePixelRatio(float factor) { m_imageDevicePixelRatio = factor; }
    float imageDevicePixelRatio() const { return m_imageDevicePixelRatio; }

    virtual void intrinsicSizeChanged() OVERRIDE
    {
        if (m_imageResource)
            imageChanged(m_imageResource->imagePtr());
    }

protected:
    virtual bool needsPreferredWidthsRecalculation() const OVERRIDE FINAL;
    virtual void computeIntrinsicRatioInformation(FloatSize& intrinsicSize, double& intrinsicRatio) const OVERRIDE FINAL;

    virtual void imageChanged(WrappedImagePtr, const IntRect* = 0) OVERRIDE;

    void paintIntoRect(GraphicsContext*, const LayoutRect&);
    virtual void paint(PaintInfo&, const LayoutPoint&) OVERRIDE FINAL;
    virtual void layout() OVERRIDE;
    virtual bool updateImageLoadingPriorities() OVERRIDE FINAL;

private:
    virtual const char* renderName() const OVERRIDE { return "RenderImage"; }

    virtual bool isImage() const OVERRIDE { return true; }
    virtual bool isRenderImage() const OVERRIDE FINAL { return true; }

    virtual void paintReplaced(PaintInfo&, const LayoutPoint&) OVERRIDE;

    virtual bool foregroundIsKnownToBeOpaqueInRect(const LayoutRect& localRect, unsigned maxDepthToTest) const OVERRIDE FINAL;
    virtual bool computeBackgroundIsKnownToBeObscured() OVERRIDE FINAL;

    virtual LayoutUnit minimumReplacedHeight() const OVERRIDE;

    virtual void notifyFinished(Resource*) OVERRIDE FINAL;
    virtual bool nodeAtPoint(const HitTestRequest&, HitTestResult&, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, HitTestAction) OVERRIDE FINAL;

    virtual bool boxShadowShouldBeAppliedToBackground(BackgroundBleedAvoidance, InlineFlowBox*) const OVERRIDE FINAL;

    IntSize imageSizeForError(ImageResource*) const;
    void paintInvalidationOrMarkForLayout(bool imageSizeChanged, const IntRect* = 0);
    void updateIntrinsicSizeIfNeeded(const LayoutSize&);
    // Update the size of the image to be rendered. Object-fit may cause this to be different from the CSS box's content rect.
    void updateInnerContentRect();

    void paintAreaElementFocusRing(PaintInfo&);

    // Text to display as long as the image isn't available.
    String m_altText;
    OwnPtr<RenderImageResource> m_imageResource;
    bool m_isGeneratedContent;
    float m_imageDevicePixelRatio;

    friend class RenderImageScaleObserver;
};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderImage, isRenderImage());

} // namespace blink

#endif // RenderImage_h
