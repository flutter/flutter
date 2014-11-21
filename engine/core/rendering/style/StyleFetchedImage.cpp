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

#include "sky/engine/config.h"
#include "sky/engine/core/rendering/style/StyleFetchedImage.h"

#include "sky/engine/core/css/CSSImageValue.h"
#include "sky/engine/core/fetch/ImageResource.h"
#include "sky/engine/core/rendering/RenderObject.h"

namespace blink {

StyleFetchedImage::StyleFetchedImage(ImageResource* image)
    : m_image(image)
{
    m_isImageResource = true;
    m_image->addClient(this);
}

StyleFetchedImage::~StyleFetchedImage()
{
    m_image->removeClient(this);
}

PassRefPtr<CSSValue> StyleFetchedImage::cssValue() const
{
    return CSSImageValue::create(m_image->url(), const_cast<StyleFetchedImage*>(this));
}

bool StyleFetchedImage::canRender(const RenderObject& renderer) const
{
    return m_image->canRender(renderer);
}

bool StyleFetchedImage::isLoaded() const
{
    return m_image->isLoaded();
}

bool StyleFetchedImage::errorOccurred() const
{
    return m_image->errorOccurred();
}

LayoutSize StyleFetchedImage::imageSize(const RenderObject* renderer) const
{
    return m_image->imageSizeForRenderer(renderer);
}

bool StyleFetchedImage::imageHasRelativeWidth() const
{
    return m_image->imageHasRelativeWidth();
}

bool StyleFetchedImage::imageHasRelativeHeight() const
{
    return m_image->imageHasRelativeHeight();
}

void StyleFetchedImage::computeIntrinsicDimensions(const RenderObject*, Length& intrinsicWidth, Length& intrinsicHeight, FloatSize& intrinsicRatio)
{
    m_image->computeIntrinsicDimensions(intrinsicWidth, intrinsicHeight, intrinsicRatio);
}

bool StyleFetchedImage::usesImageContainerSize() const
{
    return m_image->usesImageContainerSize();
}

void StyleFetchedImage::setContainerSizeForRenderer(const RenderObject* renderer, const IntSize& imageContainerSize)
{
    m_image->setContainerSizeForRenderer(renderer, imageContainerSize);
}

void StyleFetchedImage::addClient(RenderObject* renderer)
{
    m_image->addClient(renderer);
}

void StyleFetchedImage::removeClient(RenderObject* renderer)
{
    m_image->removeClient(renderer);
}

PassRefPtr<Image> StyleFetchedImage::image(RenderObject* renderer, const IntSize&) const
{
    return m_image->imageForRenderer(renderer);
}

bool StyleFetchedImage::knownToBeOpaque(const RenderObject* renderer) const
{
    return m_image->currentFrameKnownToBeOpaque(renderer);
}

}
