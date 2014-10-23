/*
 * Copyright (C) 2008 Apple Inc.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/css/CSSImageGeneratorValue.h"

#include "core/css/CSSCanvasValue.h"
#include "core/css/CSSCrossfadeValue.h"
#include "core/css/CSSGradientValue.h"
#include "platform/graphics/Image.h"

namespace blink {

CSSImageGeneratorValue::CSSImageGeneratorValue(ClassType classType)
    : CSSValue(classType)
{
}

CSSImageGeneratorValue::~CSSImageGeneratorValue()
{
}

void CSSImageGeneratorValue::addClient(RenderObject* renderer, const IntSize& size)
{
    ASSERT(renderer);
#if !ENABLE(OILPAN)
    ref();
#else
    if (m_clients.isEmpty()) {
        ASSERT(!m_keepAlive);
        m_keepAlive = adoptPtr(new Persistent<CSSImageGeneratorValue>(this));
    }
#endif

    if (!size.isEmpty())
        m_sizes.add(size);

    RenderObjectSizeCountMap::iterator it = m_clients.find(renderer);
    if (it == m_clients.end())
        m_clients.add(renderer, SizeAndCount(size, 1));
    else {
        SizeAndCount& sizeCount = it->value;
        ++sizeCount.count;
    }
}

void CSSImageGeneratorValue::removeClient(RenderObject* renderer)
{
    ASSERT(renderer);
    RenderObjectSizeCountMap::iterator it = m_clients.find(renderer);
    ASSERT_WITH_SECURITY_IMPLICATION(it != m_clients.end());

    IntSize removedImageSize;
    SizeAndCount& sizeCount = it->value;
    IntSize size = sizeCount.size;
    if (!size.isEmpty()) {
        m_sizes.remove(size);
        if (!m_sizes.contains(size))
            m_images.remove(size);
    }

    if (!--sizeCount.count)
        m_clients.remove(renderer);

#if !ENABLE(OILPAN)
    deref();
#else
    if (m_clients.isEmpty()) {
        ASSERT(m_keepAlive);
        m_keepAlive = nullptr;
    }
#endif
}

Image* CSSImageGeneratorValue::getImage(RenderObject* renderer, const IntSize& size)
{
    RenderObjectSizeCountMap::iterator it = m_clients.find(renderer);
    if (it != m_clients.end()) {
        SizeAndCount& sizeCount = it->value;
        IntSize oldSize = sizeCount.size;
        if (oldSize != size) {
#if !ENABLE_OILPAN
            RefPtr<CSSImageGeneratorValue> protect(this);
#endif
            removeClient(renderer);
            addClient(renderer, size);
        }
    }

    // Don't generate an image for empty sizes.
    if (size.isEmpty())
        return 0;

    // Look up the image in our cache.
    return m_images.get(size);
}

void CSSImageGeneratorValue::putImage(const IntSize& size, PassRefPtr<Image> image)
{
    m_images.add(size, image);
}

PassRefPtr<Image> CSSImageGeneratorValue::image(RenderObject* renderer, const IntSize& size)
{
    switch (classType()) {
    case CanvasClass:
        return toCSSCanvasValue(this)->image(renderer, size);
    case CrossfadeClass:
        return toCSSCrossfadeValue(this)->image(renderer, size);
    case LinearGradientClass:
        return toCSSLinearGradientValue(this)->image(renderer, size);
    case RadialGradientClass:
        return toCSSRadialGradientValue(this)->image(renderer, size);
    default:
        ASSERT_NOT_REACHED();
    }
    return nullptr;
}

bool CSSImageGeneratorValue::isFixedSize() const
{
    switch (classType()) {
    case CanvasClass:
        return toCSSCanvasValue(this)->isFixedSize();
    case CrossfadeClass:
        return toCSSCrossfadeValue(this)->isFixedSize();
    case LinearGradientClass:
        return toCSSLinearGradientValue(this)->isFixedSize();
    case RadialGradientClass:
        return toCSSRadialGradientValue(this)->isFixedSize();
    default:
        ASSERT_NOT_REACHED();
    }
    return false;
}

IntSize CSSImageGeneratorValue::fixedSize(const RenderObject* renderer)
{
    switch (classType()) {
    case CanvasClass:
        return toCSSCanvasValue(this)->fixedSize(renderer);
    case CrossfadeClass:
        return toCSSCrossfadeValue(this)->fixedSize(renderer);
    case LinearGradientClass:
        return toCSSLinearGradientValue(this)->fixedSize(renderer);
    case RadialGradientClass:
        return toCSSRadialGradientValue(this)->fixedSize(renderer);
    default:
        ASSERT_NOT_REACHED();
    }
    return IntSize();
}

bool CSSImageGeneratorValue::isPending() const
{
    switch (classType()) {
    case CrossfadeClass:
        return toCSSCrossfadeValue(this)->isPending();
    case CanvasClass:
        return toCSSCanvasValue(this)->isPending();
    case LinearGradientClass:
        return toCSSLinearGradientValue(this)->isPending();
    case RadialGradientClass:
        return toCSSRadialGradientValue(this)->isPending();
    default:
        ASSERT_NOT_REACHED();
    }
    return false;
}

bool CSSImageGeneratorValue::knownToBeOpaque(const RenderObject* renderer) const
{
    switch (classType()) {
    case CrossfadeClass:
        return toCSSCrossfadeValue(this)->knownToBeOpaque(renderer);
    case CanvasClass:
        return false;
    case LinearGradientClass:
        return toCSSLinearGradientValue(this)->knownToBeOpaque(renderer);
    case RadialGradientClass:
        return toCSSRadialGradientValue(this)->knownToBeOpaque(renderer);
    default:
        ASSERT_NOT_REACHED();
    }
    return false;
}

void CSSImageGeneratorValue::loadSubimages(ResourceFetcher* fetcher)
{
    switch (classType()) {
    case CrossfadeClass:
        toCSSCrossfadeValue(this)->loadSubimages(fetcher);
        break;
    case CanvasClass:
        toCSSCanvasValue(this)->loadSubimages(fetcher);
        break;
    case LinearGradientClass:
        toCSSLinearGradientValue(this)->loadSubimages(fetcher);
        break;
    case RadialGradientClass:
        toCSSRadialGradientValue(this)->loadSubimages(fetcher);
        break;
    default:
        ASSERT_NOT_REACHED();
    }
}

} // namespace blink
