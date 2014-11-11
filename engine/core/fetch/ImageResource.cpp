/*
    Copyright (C) 1998 Lars Knoll (knoll@mpi-hd.mpg.de)
    Copyright (C) 2001 Dirk Mueller (mueller@kde.org)
    Copyright (C) 2002 Waldo Bastian (bastian@kde.org)
    Copyright (C) 2006 Samuel Weinig (sam.weinig@gmail.com)
    Copyright (C) 2004, 2005, 2006, 2007 Apple Inc. All rights reserved.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.
*/

#include "config.h"
#include "core/fetch/ImageResource.h"

#include "core/fetch/ImageResourceClient.h"
#include "core/fetch/MemoryCache.h"
#include "core/fetch/ResourceClient.h"
#include "core/fetch/ResourceClientWalker.h"
#include "core/fetch/ResourceFetcher.h"
#include "core/frame/FrameView.h"
#include "core/rendering/RenderObject.h"
#include "platform/Logging.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/SharedBuffer.h"
#include "platform/TraceEvent.h"
#include "platform/graphics/BitmapImage.h"
#include "wtf/CurrentTime.h"
#include "wtf/StdLibExtras.h"

namespace blink {

ImageResource::ImageResource(const ResourceRequest& resourceRequest)
    : Resource(resourceRequest, Image)
    , m_devicePixelRatioHeaderValue(1.0)
    , m_image(nullptr)
    , m_loadingMultipartContent(false)
    , m_hasDevicePixelRatioHeaderValue(false)
{
    WTF_LOG(Timers, "new ImageResource(ResourceRequest) %p", this);
    setStatus(Unknown);
    setCustomAcceptHeader();
}

ImageResource::ImageResource(blink::Image* image)
    : Resource(ResourceRequest(""), Image)
    , m_image(image)
{
    WTF_LOG(Timers, "new ImageResource(Image) %p", this);
    setStatus(Cached);
    setLoading(false);
    setCustomAcceptHeader();
}

ImageResource::ImageResource(const ResourceRequest& resourceRequest, blink::Image* image)
    : Resource(resourceRequest, Image)
    , m_image(image)
{
    WTF_LOG(Timers, "new ImageResource(ResourceRequest, Image) %p", this);
    setStatus(Cached);
    setLoading(false);
    setCustomAcceptHeader();
}

ImageResource::~ImageResource()
{
    WTF_LOG(Timers, "~ImageResource %p", this);
    clearImage();
}

void ImageResource::load(ResourceFetcher* fetcher, const ResourceLoaderOptions& options)
{
    if (!fetcher || fetcher->autoLoadImages())
        Resource::load(fetcher, options);
    else
        setLoading(false);
}

void ImageResource::didAddClient(ResourceClient* c)
{
    if (m_data && !m_image && !errorOccurred()) {
        createImage();
        m_image->setData(m_data, true);
    }

    ASSERT(c->resourceClientType() == ImageResourceClient::expectedType());
    if (m_image && !m_image->isNull())
        static_cast<ImageResourceClient*>(c)->imageChanged(this);

    Resource::didAddClient(c);
}

void ImageResource::didRemoveClient(ResourceClient* c)
{
    ASSERT(c);
    ASSERT(c->resourceClientType() == ImageResourceClient::expectedType());

    m_pendingContainerSizeRequests.remove(static_cast<ImageResourceClient*>(c));

    Resource::didRemoveClient(c);
}

void ImageResource::switchClientsToRevalidatedResource()
{
    ASSERT(resourceToRevalidate());
    ASSERT(resourceToRevalidate()->isImage());
    // Pending container size requests need to be transferred to the revalidated resource.
    if (!m_pendingContainerSizeRequests.isEmpty()) {
        // A copy of pending size requests is needed as they are deleted during Resource::switchClientsToRevalidateResouce().
        ContainerSizeRequests switchContainerSizeRequests;
        for (ContainerSizeRequests::iterator it = m_pendingContainerSizeRequests.begin(); it != m_pendingContainerSizeRequests.end(); ++it)
            switchContainerSizeRequests.set(it->key, it->value);
        Resource::switchClientsToRevalidatedResource();
        ImageResource* revalidatedImageResource = toImageResource(resourceToRevalidate());
        for (ContainerSizeRequests::iterator it = switchContainerSizeRequests.begin(); it != switchContainerSizeRequests.end(); ++it)
            revalidatedImageResource->setContainerSizeForRenderer(it->key, it->value);
        return;
    }

    Resource::switchClientsToRevalidatedResource();
}

bool ImageResource::isSafeToUnlock() const
{
    // Note that |m_image| holds a reference to |m_data| in addition to the one held by the Resource parent class.
    return !m_image || (m_image->hasOneRef() && m_data->refCount() == 2);
}

void ImageResource::destroyDecodedDataIfPossible()
{
    if (!hasClients() && !isLoading() && (!m_image || (m_image->hasOneRef() && m_image->isBitmapImage()))) {
        m_image = nullptr;
        setDecodedSize(0);
    } else if (m_image && !errorOccurred()) {
        m_image->destroyDecodedData(true);
    }
}

void ImageResource::allClientsRemoved()
{
    m_pendingContainerSizeRequests.clear();
    if (m_image && !errorOccurred())
        m_image->resetAnimation();
    Resource::allClientsRemoved();
}

pair<blink::Image*, float> ImageResource::brokenImage(float deviceScaleFactor)
{
    if (deviceScaleFactor >= 2) {
        DEFINE_STATIC_REF(blink::Image, brokenImageHiRes, (blink::Image::loadPlatformResource("missingImage@2x")));
        return std::make_pair(brokenImageHiRes, 2);
    }

    DEFINE_STATIC_REF(blink::Image, brokenImageLoRes, (blink::Image::loadPlatformResource("missingImage")));
    return std::make_pair(brokenImageLoRes, 1);
}

bool ImageResource::willPaintBrokenImage() const
{
    return errorOccurred();
}

blink::Image* ImageResource::image()
{
    ASSERT(!isPurgeable());

    if (errorOccurred()) {
        // Returning the 1x broken image is non-ideal, but we cannot reliably access the appropriate
        // deviceScaleFactor from here. It is critical that callers use ImageResource::brokenImage()
        // when they need the real, deviceScaleFactor-appropriate broken image icon.
        return brokenImage(1).first;
    }

    if (m_image)
        return m_image.get();

    return blink::Image::nullImage();
}

blink::Image* ImageResource::imageForRenderer(const RenderObject* renderer)
{
    ASSERT(!isPurgeable());

    if (errorOccurred()) {
        // Returning the 1x broken image is non-ideal, but we cannot reliably access the appropriate
        // deviceScaleFactor from here. It is critical that callers use ImageResource::brokenImage()
        // when they need the real, deviceScaleFactor-appropriate broken image icon.
        return brokenImage(1).first;
    }

    if (!m_image)
        return blink::Image::nullImage();

    return m_image.get();
}

void ImageResource::setContainerSizeForRenderer(const ImageResourceClient* renderer, const IntSize& containerSize)
{
    if (containerSize.isEmpty())
        return;
    ASSERT(renderer);
    if (!m_image) {
        m_pendingContainerSizeRequests.set(renderer, containerSize);
        return;
    }

    m_image->setContainerSize(containerSize);
}

bool ImageResource::usesImageContainerSize() const
{
    if (m_image)
        return m_image->usesContainerSize();

    return false;
}

bool ImageResource::imageHasRelativeWidth() const
{
    if (m_image)
        return m_image->hasRelativeWidth();

    return false;
}

bool ImageResource::imageHasRelativeHeight() const
{
    if (m_image)
        return m_image->hasRelativeHeight();

    return false;
}

LayoutSize ImageResource::imageSizeForRenderer(const RenderObject* renderer, SizeType sizeType)
{
    ASSERT(!isPurgeable());

    if (!m_image)
        return IntSize();

    if (m_image->isBitmapImage() && (renderer && renderer->shouldRespectImageOrientation() == RespectImageOrientation))
        return toBitmapImage(m_image.get())->sizeRespectingOrientation();

    return m_image->size();
}

void ImageResource::computeIntrinsicDimensions(Length& intrinsicWidth, Length& intrinsicHeight, FloatSize& intrinsicRatio)
{
    if (m_image)
        m_image->computeIntrinsicDimensions(intrinsicWidth, intrinsicHeight, intrinsicRatio);
}

void ImageResource::notifyObservers(const IntRect* changeRect)
{
    ResourceClientWalker<ImageResourceClient> w(m_clients);
    while (ImageResourceClient* c = w.next())
        c->imageChanged(this, changeRect);
}

void ImageResource::clear()
{
    prune();
    clearImage();
    m_pendingContainerSizeRequests.clear();
    setEncodedSize(0);
}

void ImageResource::setCustomAcceptHeader()
{
    DEFINE_STATIC_LOCAL(const AtomicString, acceptWebP, ("image/webp,*/*;q=0.8", AtomicString::ConstructFromLiteral));
    setAccept(acceptWebP);
}

inline void ImageResource::createImage()
{
    // Create the image if it doesn't yet exist.
    if (m_image)
        return;

    m_image = BitmapImage::create(this);

    if (m_image) {
        // Send queued container size requests.
        if (m_image->usesContainerSize()) {
            for (ContainerSizeRequests::iterator it = m_pendingContainerSizeRequests.begin(); it != m_pendingContainerSizeRequests.end(); ++it)
                setContainerSizeForRenderer(it->key, it->value);
        }
        m_pendingContainerSizeRequests.clear();
    }
}

inline void ImageResource::clearImage()
{
    // If our Image has an observer, it's always us so we need to clear the back pointer
    // before dropping our reference.
    if (m_image)
        m_image->setImageObserver(0);
    m_image.clear();
}

void ImageResource::appendData(const char* data, int length)
{
    Resource::appendData(data, length);
    if (!m_loadingMultipartContent)
        updateImage(false);
}

void ImageResource::updateImage(bool allDataReceived)
{
    TRACE_EVENT0("blink", "ImageResource::updateImage");

    if (m_data)
        createImage();

    bool sizeAvailable = false;

    // Have the image update its data from its internal buffer.
    // It will not do anything now, but will delay decoding until
    // queried for info (like size or specific image frames).
    if (m_image)
        sizeAvailable = m_image->setData(m_data, allDataReceived);

    // Go ahead and tell our observers to try to draw if we have either
    // received all the data or the size is known. Each chunk from the
    // network causes observers to repaint, which will force that chunk
    // to decode.
    if (sizeAvailable || allDataReceived) {
        if (!m_image || m_image->isNull()) {
            error(errorOccurred() ? status() : DecodeError);
            if (memoryCache()->contains(this))
                memoryCache()->remove(this);
            return;
        }

        // It would be nice to only redraw the decoded band of the image, but with the current design
        // (decoding delayed until painting) that seems hard.
        notifyObservers();
    }
}

void ImageResource::finishOnePart()
{
    if (m_loadingMultipartContent)
        clear();
    updateImage(true);
    if (m_loadingMultipartContent)
        m_data.clear();
    Resource::finishOnePart();
}

void ImageResource::error(Resource::Status status)
{
    clear();
    Resource::error(status);
    notifyObservers();
}

void ImageResource::responseReceived(const ResourceResponse& response)
{
    if (m_loadingMultipartContent && m_data)
        finishOnePart();
    else if (response.isMultipart())
        m_loadingMultipartContent = true;
    if (RuntimeEnabledFeatures::clientHintsDprEnabled()) {
        m_devicePixelRatioHeaderValue = response.httpHeaderField("DPR").toFloat(&m_hasDevicePixelRatioHeaderValue);
        if (!m_hasDevicePixelRatioHeaderValue || m_devicePixelRatioHeaderValue <= 0.0) {
            m_devicePixelRatioHeaderValue = 1.0;
            m_hasDevicePixelRatioHeaderValue = false;
        }
    }
    Resource::responseReceived(response);
}

void ImageResource::decodedSizeChanged(const blink::Image* image, int delta)
{
    if (!image || image != m_image)
        return;

    setDecodedSize(decodedSize() + delta);
}

void ImageResource::didDraw(const blink::Image* image)
{
    if (!image || image != m_image)
        return;
    Resource::didAccessDecodedData();
}

bool ImageResource::shouldPauseAnimation(const blink::Image* image)
{
    if (!image || image != m_image)
        return false;

    ResourceClientWalker<ImageResourceClient> w(m_clients);
    while (ImageResourceClient* c = w.next()) {
        if (c->willRenderImage(this))
            return false;
    }

    return true;
}

void ImageResource::animationAdvanced(const blink::Image* image)
{
    if (!image || image != m_image)
        return;
    notifyObservers();
}

void ImageResource::changedInRect(const blink::Image* image, const IntRect& rect)
{
    if (!image || image != m_image)
        return;
    notifyObservers(&rect);
}

bool ImageResource::currentFrameKnownToBeOpaque(const RenderObject* renderer)
{
    blink::Image* image = imageForRenderer(renderer);
    if (image->isBitmapImage())
        image->nativeImageForCurrentFrame(); // force decode
    return image->currentFrameKnownToBeOpaque();
}

} // namespace blink
