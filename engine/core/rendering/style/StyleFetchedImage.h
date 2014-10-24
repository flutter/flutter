/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2005, 2006, 2007, 2008 Apple Inc. All rights reserved.
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

#ifndef StyleFetchedImage_h
#define StyleFetchedImage_h

#include "core/fetch/ImageResourceClient.h"
#include "core/fetch/ResourcePtr.h"
#include "core/rendering/style/StyleImage.h"

namespace blink {

class ImageResource;

class StyleFetchedImage final : public StyleImage, private ImageResourceClient {
    WTF_MAKE_FAST_ALLOCATED;
public:
    static PassRefPtr<StyleFetchedImage> create(ImageResource* image) { return adoptRef(new StyleFetchedImage(image)); }
    virtual ~StyleFetchedImage();

    virtual WrappedImagePtr data() const override { return m_image.get(); }

    virtual PassRefPtrWillBeRawPtr<CSSValue> cssValue() const override;

    virtual bool canRender(const RenderObject&, float multiplier) const override;
    virtual bool isLoaded() const override;
    virtual bool errorOccurred() const override;
    virtual LayoutSize imageSize(const RenderObject*, float multiplier) const override;
    virtual bool imageHasRelativeWidth() const override;
    virtual bool imageHasRelativeHeight() const override;
    virtual void computeIntrinsicDimensions(const RenderObject*, Length& intrinsicWidth, Length& intrinsicHeight, FloatSize& intrinsicRatio) override;
    virtual bool usesImageContainerSize() const override;
    virtual void setContainerSizeForRenderer(const RenderObject*, const IntSize&, float) override;
    virtual void addClient(RenderObject*) override;
    virtual void removeClient(RenderObject*) override;
    virtual PassRefPtr<Image> image(RenderObject*, const IntSize&) const override;
    virtual bool knownToBeOpaque(const RenderObject*) const override;
    virtual ImageResource* cachedImage() const override { return m_image.get(); }

private:
    explicit StyleFetchedImage(ImageResource*);

    ResourcePtr<ImageResource> m_image;
};

DEFINE_STYLE_IMAGE_TYPE_CASTS(StyleFetchedImage, isImageResource());

}
#endif
