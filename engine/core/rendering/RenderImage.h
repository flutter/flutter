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

#ifndef SKY_ENGINE_CORE_RENDERING_RENDERIMAGE_H_
#define SKY_ENGINE_CORE_RENDERING_RENDERIMAGE_H_

#include "sky/engine/core/rendering/RenderImageResource.h"
#include "sky/engine/core/rendering/RenderReplaced.h"

namespace blink {

class RenderImage final : public RenderReplaced {
public:
    RenderImage(Element*);
    virtual ~RenderImage();
    virtual void destroy() override;

    static RenderImage* createAnonymous(Document*);

    void setImageResource(PassOwnPtr<RenderImageResource>);

    RenderImageResource* imageResource() { return m_imageResource.get(); }
    const RenderImageResource* imageResource() const { return m_imageResource.get(); }
    ImageResource* cachedImage() const { return m_imageResource ? m_imageResource->cachedImage() : 0; }

    void highQualityRepaintTimerFired(Timer<RenderImage>*);

    inline void setImageDevicePixelRatio(float factor) { m_imageDevicePixelRatio = factor; }
    float imageDevicePixelRatio() const { return m_imageDevicePixelRatio; }

    virtual void intrinsicSizeChanged() override;

private:
    virtual bool needsPreferredWidthsRecalculation() const override final;
    virtual void computeIntrinsicRatioInformation(FloatSize& intrinsicSize, double& intrinsicRatio) const override final;

    virtual void imageChanged(WrappedImagePtr, const IntRect* = 0) final;

    void paintIntoRect(GraphicsContext*, const LayoutRect&);
    virtual void paint(PaintInfo&, const LayoutPoint&) override final;
    virtual void layout() override;

    virtual const char* renderName() const override { return "RenderImage"; }

    virtual bool isImage() const override { return true; }
    virtual bool isRenderImage() const override final { return true; }

    virtual void paintReplaced(PaintInfo&, const LayoutPoint&) override;

    virtual bool foregroundIsKnownToBeOpaqueInRect(const LayoutRect& localRect, unsigned maxDepthToTest) const override final;
    virtual bool computeBackgroundIsKnownToBeObscured() override final;

    virtual LayoutUnit minimumReplacedHeight() const override;

    virtual void notifyFinished(Resource*) override final;
    virtual bool nodeAtPoint(const HitTestRequest&, HitTestResult&, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, HitTestAction) override final;

    virtual bool boxShadowShouldBeAppliedToBackground(BackgroundBleedAvoidance, InlineFlowBox*) const override final;

    void paintInvalidationOrMarkForLayout(const IntRect* = 0);
    void updateIntrinsicSizeIfNeeded(const LayoutSize& newSize);
    // Update the size of the image to be rendered. Object-fit may cause this to be different from the CSS box's content rect.
    void updateInnerContentRect();

    void paintAreaElementFocusRing(PaintInfo&);

    OwnPtr<RenderImageResource> m_imageResource;
    float m_imageDevicePixelRatio;

    friend class RenderImageScaleObserver;
};

DEFINE_RENDER_OBJECT_TYPE_CASTS(RenderImage, isRenderImage());

} // namespace blink

#endif  // SKY_ENGINE_CORE_RENDERING_RENDERIMAGE_H_
