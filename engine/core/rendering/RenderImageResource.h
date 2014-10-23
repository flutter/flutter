/*
 * Copyright (C) 1999 Lars Knoll <knoll@kde.org>
 * Copyright (C) 1999 Antti Koivisto <koivisto@kde.org>
 * Copyright (C) 2006 Allan Sandfeld Jensen <kde@carewolf.com>
 * Copyright (C) 2006 Samuel Weinig <sam.weinig@gmail.com>
 * Copyright (C) 2004, 2005, 2006, 2007, 2009, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Patrick Gansterer <paroga@paroga.com>
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

#ifndef RenderImageResource_h
#define RenderImageResource_h

#include "core/fetch/ImageResource.h"
#include "core/fetch/ResourcePtr.h"
#include "core/rendering/style/StyleImage.h"

namespace blink {

class RenderObject;

class RenderImageResource {
    WTF_MAKE_NONCOPYABLE(RenderImageResource); WTF_MAKE_FAST_ALLOCATED;
public:
    virtual ~RenderImageResource();

    static PassOwnPtr<RenderImageResource> create()
    {
        return adoptPtr(new RenderImageResource);
    }

    virtual void initialize(RenderObject*);
    virtual void shutdown();

    void setImageResource(ImageResource*);
    ImageResource* cachedImage() const { return m_cachedImage.get(); }
    virtual bool hasImage() const { return m_cachedImage; }

    void resetAnimation();

    virtual PassRefPtr<Image> image(int /* width */ = 0, int /* height */ = 0) const
    {
        return m_cachedImage ? m_cachedImage->imageForRenderer(m_renderer) : Image::nullImage();
    }
    virtual bool errorOccurred() const { return m_cachedImage && m_cachedImage->errorOccurred(); }

    virtual void setContainerSizeForRenderer(const IntSize&);
    virtual bool usesImageContainerSize() const { return m_cachedImage ? m_cachedImage->usesImageContainerSize() : false; }
    virtual bool imageHasRelativeWidth() const { return m_cachedImage ? m_cachedImage->imageHasRelativeWidth() : false; }
    virtual bool imageHasRelativeHeight() const { return m_cachedImage ? m_cachedImage->imageHasRelativeHeight() : false; }

    virtual LayoutSize imageSize(float multiplier) const { return getImageSize(multiplier, ImageResource::NormalSize); }
    virtual LayoutSize intrinsicSize(float multiplier) const { return getImageSize(multiplier, ImageResource::IntrinsicSize); }

    virtual WrappedImagePtr imagePtr() const { return m_cachedImage.get(); }

protected:
    RenderImageResource();
    RenderObject* m_renderer;
    ResourcePtr<ImageResource> m_cachedImage;

private:
    LayoutSize getImageSize(float multiplier, ImageResource::SizeType) const;
};

} // namespace blink

#endif // RenderImage_h
