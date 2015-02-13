/*
 * Copyright (C) 2004, 2006, 2007 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Alp Toker <alp@atoker.com>
 * Copyright (C) 2010 Torch Mobile (Beijing) Co. Ltd. All rights reserved.
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

#include "sky/engine/config.h"
#include "sky/engine/core/html/HTMLCanvasElement.h"

#include <math.h>

#include "base/bind.h"
#include "gen/sky/core/HTMLNames.h"
#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "sky/engine/bindings/exception_messages.h"
#include "sky/engine/bindings/exception_state.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/ExceptionCode.h"
#include "sky/engine/core/dom/Microtask.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/frame/Settings.h"
#include "sky/engine/core/html/ImageData.h"
#include "sky/engine/core/html/canvas/Canvas2DContextAttributes.h"
#include "sky/engine/core/html/canvas/CanvasRenderingContext2D.h"
#include "sky/engine/core/html/canvas/WebGLContextAttributes.h"
#include "sky/engine/core/html/canvas/WebGLContextEvent.h"
#include "sky/engine/core/html/canvas/WebGLRenderingContext.h"
#include "sky/engine/core/rendering/RenderHTMLCanvas.h"
#include "sky/engine/core/rendering/RenderLayer.h"
#include "sky/engine/platform/MIMETypeRegistry.h"
#include "sky/engine/platform/graphics/Canvas2DImageBufferSurface.h"
#include "sky/engine/platform/graphics/GraphicsContextStateSaver.h"
#include "sky/engine/platform/graphics/ImageBuffer.h"
#include "sky/engine/platform/graphics/UnacceleratedImageBufferSurface.h"
#include "sky/engine/platform/graphics/gpu/WebGLImageBufferSurface.h"
#include "sky/engine/platform/transforms/AffineTransform.h"
#include "sky/engine/public/platform/Platform.h"

namespace blink {

// These values come from the WhatWG spec.
static const int DefaultWidth = 300;
static const int DefaultHeight = 150;

// Firefox limits width/height to 32767 pixels, but slows down dramatically before it
// reaches that limit. We limit by area instead, giving us larger maximum dimensions,
// in exchange for a smaller maximum canvas size.
static const int MaxCanvasArea = 32768 * 8192; // Maximum canvas area in CSS pixels

//In Skia, we will also limit width/height to 32767.
static const int MaxSkiaDim = 32767; // Maximum width/height in CSS pixels.

DEFINE_EMPTY_DESTRUCTOR_WILL_BE_REMOVED(CanvasObserver);

inline HTMLCanvasElement::HTMLCanvasElement(Document& document)
    : HTMLElement(HTMLNames::canvasTag, document)
    , m_size(DefaultWidth, DefaultHeight)
    , m_ignoreReset(false)
    , m_accelerationDisabled(false)
    , m_externallyAllocatedMemory(0)
    , m_didFailToCreateImageBuffer(false)
    , m_didClearImageBuffer(false)
{
}

DEFINE_NODE_FACTORY(HTMLCanvasElement)

HTMLCanvasElement::~HTMLCanvasElement()
{
    resetDirtyRect();
#if !ENABLE(OILPAN)
    HashSet<RawPtr<CanvasObserver> >::iterator end = m_observers.end();
    for (HashSet<RawPtr<CanvasObserver> >::iterator it = m_observers.begin(); it != end; ++it)
        (*it)->canvasDestroyed(this);
    // Ensure these go away before the ImageBuffer.
    m_contextStateSaver.clear();
    m_context.clear();
#endif
}

void HTMLCanvasElement::parseAttribute(const QualifiedName& name, const AtomicString& value)
{
    if (name == HTMLNames::widthAttr || name == HTMLNames::heightAttr)
        reset();
    HTMLElement::parseAttribute(name, value);
}

RenderObject* HTMLCanvasElement::createRenderer(RenderStyle* style)
{
    return new RenderHTMLCanvas(this);
}

void HTMLCanvasElement::addObserver(CanvasObserver* observer)
{
    m_observers.add(observer);
}

void HTMLCanvasElement::removeObserver(CanvasObserver* observer)
{
    m_observers.remove(observer);
}

void HTMLCanvasElement::setHeight(int value)
{
    setIntegralAttribute(HTMLNames::heightAttr, value);
}

void HTMLCanvasElement::setWidth(int value)
{
    setIntegralAttribute(HTMLNames::widthAttr, value);
}

CanvasRenderingContext2D* HTMLCanvasElement::getContext(const String& type, CanvasContextAttributes* attrs)
{
    // A Canvas can either be "2D" or "webgl" but never both. If you request a 2D canvas and the existing
    // context is already 2D, just return that. If the existing context is WebGL, then destroy it
    // before creating a new 2D context. Vice versa when requesting a WebGL canvas. Requesting a
    // context with any other type string will destroy any existing context.
    enum ContextType {
        // Do not change assigned numbers of existing items: add new features to the end of the list.
        Context2d = 0,
        ContextExperimentalWebgl = 2,
        ContextWebgl = 3,
        ContextTypeCount,
    };

    // FIXME - The code depends on the context not going away once created, to prevent JS from
    // seeing a dangling pointer. So for now we will disallow the context from being changed
    // once it is created.
    if (type == "2d") {
        if (m_context && !m_context->is2d())
            return 0;
        if (!m_context) {
            blink::Platform::current()->histogramEnumeration("Canvas.ContextType", Context2d, ContextTypeCount);
            m_context = CanvasRenderingContext2D::create(this, static_cast<Canvas2DContextAttributes*>(attrs));
        }
        return static_cast<CanvasRenderingContext2D*>(m_context.get());
    }

    // Accept the the provisional "experimental-webgl" or official "webgl" context ID.
    // if (type == "webgl" || type == "experimental-webgl") {
    //     ContextType contextType = (type == "webgl") ? ContextWebgl : ContextExperimentalWebgl;
    //     if (!m_context) {
    //         blink::Platform::current()->histogramEnumeration("Canvas.ContextType", contextType, ContextTypeCount);
    //         m_context = WebGLRenderingContext::create(this, static_cast<WebGLContextAttributes*>(attrs));
    //         updateExternallyAllocatedMemory();
    //     } else if (!m_context->is3d()) {
    //         dispatchEvent(WebGLContextEvent::create(EventTypeNames::webglcontextcreationerror, false, true, "Canvas has an existing, non-WebGL context"));
    //         return 0;
    //     }
    //     return m_context.get();
    // }

    return nullptr;
}

void HTMLCanvasElement::didDraw(const FloatRect& rect)
{
    if (rect.isEmpty())
        return;
    clearCopiedImage();
    if (m_dirtyRect.isEmpty()) {
        m_finalizeFrameTask.Reset(base::Bind(
            &HTMLCanvasElement::finalizeFrameMicrotask, base::Unretained(this)));
        Microtask::enqueueMicrotask(m_finalizeFrameTask.callback());
    }
    m_dirtyRect.unite(rect);
}

void HTMLCanvasElement::didFinalizeFrame()
{
    if (m_dirtyRect.isEmpty())
        return;

    // Propagate the m_dirtyRect accumulated so far to the compositor
    // before restarting with a blank dirty rect.
    FloatRect srcRect(0, 0, size().width(), size().height());
    m_dirtyRect.intersect(srcRect);
    notifyObserversCanvasChanged(m_dirtyRect);
    m_finalizeFrameTask.Cancel();
    m_dirtyRect = FloatRect();
}

void HTMLCanvasElement::resetDirtyRect()
{
    if (m_dirtyRect.isEmpty())
        return;
    m_finalizeFrameTask.Cancel();
    m_dirtyRect = FloatRect();
}

void HTMLCanvasElement::finalizeFrameMicrotask()
{
    // This method gets invoked if didDraw was called earlier in the current task.
    if (is3D()) {
        didFinalizeFrame();
    } else {
        ASSERT(hasImageBuffer());
        m_imageBuffer->finalizeFrame();
    }
    ASSERT(m_finalizeFrameTask.IsCancelled());
}

void HTMLCanvasElement::notifyObserversCanvasChanged(const FloatRect& rect)
{
    HashSet<RawPtr<CanvasObserver> >::iterator end = m_observers.end();
    for (HashSet<RawPtr<CanvasObserver> >::iterator it = m_observers.begin(); it != end; ++it)
        (*it)->canvasChanged(this, rect);
}

void HTMLCanvasElement::reset()
{
    if (m_ignoreReset)
        return;

    resetDirtyRect();

    bool ok;
    bool hadImageBuffer = hasImageBuffer();

    int w = getAttribute(HTMLNames::widthAttr).toInt(&ok);
    if (!ok || w < 0)
        w = DefaultWidth;

    int h = getAttribute(HTMLNames::heightAttr).toInt(&ok);
    if (!ok || h < 0)
        h = DefaultHeight;

    if (m_contextStateSaver) {
        // Reset to the initial graphics context state.
        m_contextStateSaver->restore();
        m_contextStateSaver->save();
    }

    if (m_context && m_context->is2d())
        toCanvasRenderingContext2D(m_context.get())->reset();

    IntSize oldSize = size();
    IntSize newSize(w, h);

    // If the size of an existing buffer matches, we can just clear it instead of reallocating.
    // This optimization is only done for 2D canvases for now.
    if (hadImageBuffer && oldSize == newSize && m_context && m_context->is2d()) {
        if (!m_didClearImageBuffer)
            clearImageBuffer();
        return;
    }

    setSurfaceSize(newSize);

    if (m_context && m_context->is3d() && oldSize != size())
        toWebGLRenderingContext(m_context.get())->reshape(width(), height());

    if (RenderObject* renderer = this->renderer()) {
        if (renderer->isCanvas()) {
            if (hadImageBuffer)
                document().scheduleVisualUpdate();
        }
    }

    HashSet<RawPtr<CanvasObserver> >::iterator end = m_observers.end();
    for (HashSet<RawPtr<CanvasObserver> >::iterator it = m_observers.begin(); it != end; ++it)
        (*it)->canvasResized(this);
}

bool HTMLCanvasElement::paintsIntoCanvasBuffer() const
{
    ASSERT(m_context);
    return true;
}

void HTMLCanvasElement::paint(GraphicsContext* context, const LayoutRect& r)
{
    if (m_context) {
        if (!paintsIntoCanvasBuffer())
            return;
        m_context->paintRenderingResultsToCanvas();
    }

    if (hasImageBuffer()) {
        ImageBuffer* imageBuffer = buffer();
        if (imageBuffer) {
            CompositeOperator compositeOperator = !m_context || m_context->hasAlpha() ? CompositeSourceOver : CompositeCopy;
            if (m_presentedImage)
                context->drawImage(m_presentedImage.get(), pixelSnappedIntRect(r), compositeOperator, DoNotRespectImageOrientation);
            else
                context->drawImageBuffer(imageBuffer, pixelSnappedIntRect(r), 0, compositeOperator);
        }
    } else {
        // When alpha is false, we should draw to opaque black.
        if (m_context && !m_context->hasAlpha())
            context->fillRect(FloatRect(r), Color(0, 0, 0));
    }

    if (is3D())
        toWebGLRenderingContext(m_context.get())->markLayerComposited();
}

bool HTMLCanvasElement::is3D() const
{
    return m_context && m_context->is3d();
}

void HTMLCanvasElement::makePresentationCopy()
{
    if (!m_presentedImage) {
        // The buffer contains the last presented data, so save a copy of it.
        m_presentedImage = buffer()->copyImage(CopyBackingStore, Unscaled);
        updateExternallyAllocatedMemory();
    }
}

void HTMLCanvasElement::clearPresentationCopy()
{
    m_presentedImage.clear();
    updateExternallyAllocatedMemory();
}

void HTMLCanvasElement::setSurfaceSize(const IntSize& size)
{
    m_size = size;
    m_didFailToCreateImageBuffer = false;
    discardImageBuffer();
    clearCopiedImage();
    if (m_context && m_context->is2d()) {
        CanvasRenderingContext2D* context2d = toCanvasRenderingContext2D(m_context.get());
        if (context2d->isContextLost()) {
            context2d->restoreContext();
        }
    }
}

String HTMLCanvasElement::toEncodingMimeType(const String& mimeType)
{
    String lowercaseMimeType = mimeType.lower();

    // FIXME: Make isSupportedImageMIMETypeForEncoding threadsafe (to allow this method to be used on a worker thread).
    if (mimeType.isNull() || !MIMETypeRegistry::isSupportedImageMIMETypeForEncoding(lowercaseMimeType))
        lowercaseMimeType = "image/png";

    return lowercaseMimeType;
}

const AtomicString HTMLCanvasElement::imageSourceURL() const
{
    return AtomicString(toDataURLInternal("image/png", 0, true));
}

String HTMLCanvasElement::toDataURLInternal(const String& mimeType, const double* quality, bool isSaving) const
{
    if (m_size.isEmpty() || !buffer())
        return String("data:,");

    String encodingMimeType = toEncodingMimeType(mimeType);

    // Try to get ImageData first, as that may avoid lossy conversions.
    RefPtr<ImageData> imageData = getImageData();

    if (imageData)
        return ImageDataToDataURL(ImageDataBuffer(imageData->size(), imageData->data()), encodingMimeType, quality);

    if (m_context && m_context->is3d()) {
        toWebGLRenderingContext(m_context.get())->setSavingImage(isSaving);
        m_context->paintRenderingResultsToCanvas();
        toWebGLRenderingContext(m_context.get())->setSavingImage(false);
    }

    return buffer()->toDataURL(encodingMimeType, quality);
}

String HTMLCanvasElement::toDataURL(const String& mimeType, const double* quality, ExceptionState& exceptionState) const
{
    return toDataURLInternal(mimeType, quality);
}

PassRefPtr<ImageData> HTMLCanvasElement::getImageData() const
{
    if (!m_context || !m_context->is3d())
        return nullptr;
    return toWebGLRenderingContext(m_context.get())->paintRenderingResultsToImageData();
}

bool HTMLCanvasElement::shouldAccelerate(const IntSize& size) const
{
    if (m_context && !m_context->is2d())
        return false;

    if (m_accelerationDisabled)
        return false;

    Settings* settings = document().settings();
    if (!settings || !settings->accelerated2dCanvasEnabled())
        return false;

    // Do not use acceleration for small canvas.
    if (size.width() * size.height() < settings->minimumAccelerated2dCanvasSize())
        return false;

    if (!blink::Platform::current()->canAccelerate2dCanvas())
        return false;

    return true;
}

PassOwnPtr<ImageBufferSurface> HTMLCanvasElement::createImageBufferSurface(const IntSize& deviceSize, int* msaaSampleCount)
{
    OpacityMode opacityMode = !m_context || m_context->hasAlpha() ? NonOpaque : Opaque;

    *msaaSampleCount = 0;
    if (is3D())
        return adoptPtr(new WebGLImageBufferSurface(size(), opacityMode));

    if (shouldAccelerate(deviceSize)) {
        if (document().settings())
            *msaaSampleCount = document().settings()->accelerated2dCanvasMSAASampleCount();
        OwnPtr<ImageBufferSurface> surface = adoptPtr(new Canvas2DImageBufferSurface(size(), opacityMode, *msaaSampleCount));
        if (surface->isValid())
            return surface.release();
    }

    return adoptPtr(new UnacceleratedImageBufferSurface(size(), opacityMode));
}

void HTMLCanvasElement::createImageBuffer()
{
    createImageBufferInternal();
    if (m_didFailToCreateImageBuffer && m_context && m_context->is2d())
        toCanvasRenderingContext2D(m_context.get())->loseContext();
}

void HTMLCanvasElement::createImageBufferInternal()
{
    ASSERT(!m_imageBuffer);
    ASSERT(!m_contextStateSaver);

    m_didFailToCreateImageBuffer = true;
    m_didClearImageBuffer = true;

    IntSize deviceSize = size();
    if (deviceSize.width() * deviceSize.height() > MaxCanvasArea)
        return;

    if (deviceSize.width() > MaxSkiaDim || deviceSize.height() > MaxSkiaDim)
        return;

    if (!deviceSize.width() || !deviceSize.height())
        return;

    int msaaSampleCount;
    OwnPtr<ImageBufferSurface> surface = createImageBufferSurface(deviceSize, &msaaSampleCount);
    if (!surface->isValid())
        return;

    m_imageBuffer = ImageBuffer::create(surface.release());
    m_imageBuffer->setClient(this);

    m_didFailToCreateImageBuffer = false;

    updateExternallyAllocatedMemory();

    if (is3D()) {
        // Early out for WebGL canvases
        return;
    }

    m_imageBuffer->setClient(this);
    m_imageBuffer->context()->setShouldClampToSourceRect(false);
    m_imageBuffer->context()->disableAntialiasingOptimizationForHairlineImages();
    m_imageBuffer->context()->setImageInterpolationQuality(CanvasDefaultInterpolationQuality);
    // Enabling MSAA overrides a request to disable antialiasing. This is true regardless of whether the
    // rendering mode is accelerated or not. For consistency, we don't want to apply AA in accelerated
    // canvases but not in unaccelerated canvases.
    if (!msaaSampleCount && document().settings() && !document().settings()->antialiased2dCanvasEnabled())
        m_imageBuffer->context()->setShouldAntialias(false);
    // GraphicsContext's defaults don't always agree with the 2d canvas spec.
    // See CanvasRenderingContext2D::State::State() for more information.
    m_imageBuffer->context()->setMiterLimit(10);
    m_imageBuffer->context()->setStrokeThickness(1);
#if ENABLE(ASSERT)
    m_imageBuffer->context()->disableDestructionChecks(); // 2D canvas is allowed to leave context in an unfinalized state.
#endif
    m_contextStateSaver = adoptPtr(new GraphicsContextStateSaver(*m_imageBuffer->context()));
}

void HTMLCanvasElement::notifySurfaceInvalid()
{
    if (m_context && m_context->is2d()) {
        CanvasRenderingContext2D* context2d = toCanvasRenderingContext2D(m_context.get());
        context2d->loseContext();
    }
}

void HTMLCanvasElement::updateExternallyAllocatedMemory() const
{
    int bufferCount = 0;
    if (m_imageBuffer)
        bufferCount++;
    if (is3D())
        bufferCount += 2;
    if (m_copiedImage)
        bufferCount++;
    if (m_presentedImage)
        bufferCount++;

    Checked<intptr_t, RecordOverflow> checkedExternallyAllocatedMemory = 4 * bufferCount;
    checkedExternallyAllocatedMemory *= width();
    checkedExternallyAllocatedMemory *= height();
    intptr_t externallyAllocatedMemory;
    if (checkedExternallyAllocatedMemory.safeGet(externallyAllocatedMemory) == CheckedState::DidOverflow)
        externallyAllocatedMemory = std::numeric_limits<intptr_t>::max();

    // Subtracting two intptr_t that are known to be positive will never underflow.
    m_externallyAllocatedMemory = externallyAllocatedMemory;
}

GraphicsContext* HTMLCanvasElement::drawingContext() const
{
    return buffer() ? m_imageBuffer->context() : 0;
}

GraphicsContext* HTMLCanvasElement::existingDrawingContext() const
{
    if (!hasImageBuffer())
        return 0;

    return drawingContext();
}

ImageBuffer* HTMLCanvasElement::buffer() const
{
    if (!hasImageBuffer() && !m_didFailToCreateImageBuffer)
        const_cast<HTMLCanvasElement*>(this)->createImageBuffer();
    return m_imageBuffer.get();
}

void HTMLCanvasElement::ensureUnacceleratedImageBuffer()
{
    if ((hasImageBuffer() && !m_imageBuffer->isAccelerated()) || m_didFailToCreateImageBuffer)
        return;
    discardImageBuffer();
    OpacityMode opacityMode = !m_context || m_context->hasAlpha() ? NonOpaque : Opaque;
    m_imageBuffer = ImageBuffer::create(size(), opacityMode);
    m_didFailToCreateImageBuffer = !m_imageBuffer;
}

Image* HTMLCanvasElement::copiedImage() const
{
    if (!m_copiedImage && buffer()) {
        if (m_context && m_context->is3d()) {
            toWebGLRenderingContext(m_context.get())->setSavingImage(true);
            m_context->paintRenderingResultsToCanvas();
            toWebGLRenderingContext(m_context.get())->setSavingImage(false);
        }
        m_copiedImage = buffer()->copyImage(CopyBackingStore, Unscaled);
        updateExternallyAllocatedMemory();
    }
    return m_copiedImage.get();
}

void HTMLCanvasElement::clearImageBuffer()
{
    ASSERT(hasImageBuffer() && !m_didFailToCreateImageBuffer);
    ASSERT(!m_didClearImageBuffer);
    ASSERT(m_context);

    m_didClearImageBuffer = true;

    if (m_context->is2d()) {
        // No need to undo transforms/clip/etc. because we are called right
        // after the context is reset.
        toCanvasRenderingContext2D(m_context.get())->clearRect(0, 0, width(), height());
    }
}

void HTMLCanvasElement::discardImageBuffer()
{
    m_contextStateSaver.clear(); // uses context owned by m_imageBuffer
    m_imageBuffer.clear();
    resetDirtyRect();
    updateExternallyAllocatedMemory();
}

bool HTMLCanvasElement::hasValidImageBuffer() const
{
    return m_imageBuffer && m_imageBuffer->isSurfaceValid();
}

void HTMLCanvasElement::clearCopiedImage()
{
    if (m_copiedImage) {
        m_copiedImage.clear();
        updateExternallyAllocatedMemory();
    }
    m_didClearImageBuffer = false;
}

AffineTransform HTMLCanvasElement::baseTransform() const
{
    ASSERT(hasImageBuffer() && !m_didFailToCreateImageBuffer);
    return m_imageBuffer->baseTransform();
}

PassRefPtr<Image> HTMLCanvasElement::getSourceImageForCanvas(SourceImageMode mode, SourceImageStatus* status) const
{
    if (!width() || !height()) {
        *status = ZeroSizeCanvasSourceImageStatus;
        return nullptr;
    }

    if (!buffer()) {
        *status = InvalidSourceImageStatus;
        return nullptr;
    }

    if (mode == CopySourceImageIfVolatile) {
        *status = NormalSourceImageStatus;
        return copiedImage();
    }

    if (m_context && m_context->is3d()) {
        m_context->paintRenderingResultsToCanvas();
        *status = ExternalSourceImageStatus;
    } else {
        *status = NormalSourceImageStatus;
    }
    return m_imageBuffer->copyImage(DontCopyBackingStore, Unscaled);
}

FloatSize HTMLCanvasElement::sourceSize() const
{
    return FloatSize(width(), height());
}

}
