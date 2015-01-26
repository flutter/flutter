/*
 * Copyright (c) 2010, Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/config.h"

#include "sky/engine/platform/graphics/gpu/DrawingBuffer.h"

#include <algorithm>
#include "gen/sky/platform/RuntimeEnabledFeatures.h"
#include "sky/engine/platform/TraceEvent.h"
#include "sky/engine/platform/graphics/ImageBuffer.h"
#include "sky/engine/platform/graphics/gpu/Extensions3DUtil.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/public/platform/WebExternalBitmap.h"
#include "sky/engine/public/platform/WebExternalTextureLayer.h"
#include "sky/engine/public/platform/WebGraphicsContext3D.h"
#include "sky/engine/public/platform/WebGraphicsContext3DProvider.h"
#ifndef NDEBUG
#include "sky/engine/wtf/RefCountedLeakCounter.h"
#endif

namespace blink {

namespace {
// Global resource ceiling (expressed in terms of pixels) for DrawingBuffer creation and resize.
// When this limit is set, DrawingBuffer::create() and DrawingBuffer::reset() calls that would
// exceed the global cap will instead clear the buffer.
const int s_maximumResourceUsePixels = 16 * 1024 * 1024;
int s_currentResourceUsePixels = 0;
const float s_resourceAdjustedRatio = 0.5;

const bool s_allowContextEvictionOnCreate = true;
const int s_maxScaleAttempts = 3;

DEFINE_DEBUG_ONLY_GLOBAL(WTF::RefCountedLeakCounter, drawingBufferCounter, ("DrawingBuffer"));

class ScopedTextureUnit0BindingRestorer {
public:
    ScopedTextureUnit0BindingRestorer(WebGraphicsContext3D* context, GLenum activeTextureUnit, Platform3DObject textureUnitZeroId)
        : m_context(context)
        , m_oldActiveTextureUnit(activeTextureUnit)
        , m_oldTextureUnitZeroId(textureUnitZeroId)
    {
        m_context->activeTexture(GL_TEXTURE0);
    }
    ~ScopedTextureUnit0BindingRestorer()
    {
        m_context->bindTexture(GL_TEXTURE_2D, m_oldTextureUnitZeroId);
        m_context->activeTexture(m_oldActiveTextureUnit);
    }

private:
    WebGraphicsContext3D* m_context;
    GLenum m_oldActiveTextureUnit;
    Platform3DObject m_oldTextureUnitZeroId;
};

} // namespace

PassRefPtr<DrawingBuffer> DrawingBuffer::create(PassOwnPtr<WebGraphicsContext3D> context, const IntSize& size, PreserveDrawingBuffer preserve, WebGraphicsContext3D::Attributes requestedAttributes, PassRefPtr<ContextEvictionManager> contextEvictionManager)
{
    ASSERT(context);
    OwnPtr<Extensions3DUtil> extensionsUtil = Extensions3DUtil::create(context.get());
    if (!extensionsUtil) {
        // This might be the first time we notice that the WebGraphicsContext3D is lost.
        return nullptr;
    }
    bool multisampleSupported = extensionsUtil->supportsExtension("GL_CHROMIUM_framebuffer_multisample")
        && extensionsUtil->supportsExtension("GL_OES_rgb8_rgba8");
    if (multisampleSupported) {
        extensionsUtil->ensureExtensionEnabled("GL_CHROMIUM_framebuffer_multisample");
        extensionsUtil->ensureExtensionEnabled("GL_OES_rgb8_rgba8");
    }
    bool packedDepthStencilSupported = extensionsUtil->supportsExtension("GL_OES_packed_depth_stencil");
    if (packedDepthStencilSupported)
        extensionsUtil->ensureExtensionEnabled("GL_OES_packed_depth_stencil");

    RefPtr<DrawingBuffer> drawingBuffer = adoptRef(new DrawingBuffer(context, extensionsUtil.release(), multisampleSupported, packedDepthStencilSupported, preserve, requestedAttributes, contextEvictionManager));
    if (!drawingBuffer->initialize(size)) {
        drawingBuffer->beginDestruction();
        return PassRefPtr<DrawingBuffer>();
    }
    return drawingBuffer.release();
}

DrawingBuffer::DrawingBuffer(PassOwnPtr<WebGraphicsContext3D> context,
    PassOwnPtr<Extensions3DUtil> extensionsUtil,
    bool multisampleExtensionSupported,
    bool packedDepthStencilExtensionSupported,
    PreserveDrawingBuffer preserve,
    WebGraphicsContext3D::Attributes requestedAttributes,
    PassRefPtr<ContextEvictionManager> contextEvictionManager)
    : m_preserveDrawingBuffer(preserve)
    , m_scissorEnabled(false)
    , m_texture2DBinding(0)
    , m_framebufferBinding(0)
    , m_activeTextureUnit(GL_TEXTURE0)
    , m_context(context)
    , m_extensionsUtil(extensionsUtil)
    , m_size(-1, -1)
    , m_requestedAttributes(requestedAttributes)
    , m_multisampleExtensionSupported(multisampleExtensionSupported)
    , m_packedDepthStencilExtensionSupported(packedDepthStencilExtensionSupported)
    , m_fbo(0)
    , m_depthStencilBuffer(0)
    , m_depthBuffer(0)
    , m_stencilBuffer(0)
    , m_multisampleFBO(0)
    , m_multisampleColorBuffer(0)
    , m_contentsChanged(true)
    , m_contentsChangeCommitted(false)
    , m_layerComposited(false)
    , m_multisampleMode(None)
    , m_internalColorFormat(0)
    , m_colorFormat(0)
    , m_internalRenderbufferFormat(0)
    , m_maxTextureSize(0)
    , m_sampleCount(0)
    , m_packAlignment(4)
    , m_destructionInProgress(false)
    , m_isHidden(false)
    , m_contextEvictionManager(contextEvictionManager)
{
    // Used by browser tests to detect the use of a DrawingBuffer.
    TRACE_EVENT_INSTANT0("test_gpu", "DrawingBufferCreation", TRACE_EVENT_SCOPE_NAME_PROCESS);
#ifndef NDEBUG
    drawingBufferCounter.increment();
#endif
}

DrawingBuffer::~DrawingBuffer()
{
    ASSERT(m_destructionInProgress);
    ASSERT(m_textureMailboxes.isEmpty());
    m_layer.clear();
    m_context.clear();
#ifndef NDEBUG
    drawingBufferCounter.decrement();
#endif
}

void DrawingBuffer::markContentsChanged()
{
    m_contentsChanged = true;
    m_contentsChangeCommitted = false;
    m_layerComposited = false;
}

bool DrawingBuffer::layerComposited() const
{
    return m_layerComposited;
}

void DrawingBuffer::markLayerComposited()
{
    m_layerComposited = true;
}

WebGraphicsContext3D* DrawingBuffer::context()
{
    return m_context.get();
}

void DrawingBuffer::setIsHidden(bool hidden)
{
    if (m_isHidden == hidden)
        return;
    m_isHidden = hidden;
    if (m_isHidden)
        freeRecycledMailboxes();
}

void DrawingBuffer::freeRecycledMailboxes()
{
    if (m_recycledMailboxQueue.isEmpty())
        return;
    while (!m_recycledMailboxQueue.isEmpty())
        deleteMailbox(m_recycledMailboxQueue.takeLast());
}

bool DrawingBuffer::prepareMailbox(WebExternalTextureMailbox* outMailbox, WebExternalBitmap* bitmap)
{
    ASSERT(!m_isHidden);
    if (!m_contentsChanged)
        return false;

    if (m_destructionInProgress) {
        // It can be hit in the following sequence.
        // 1. WebGL draws something.
        // 2. The compositor begins the frame.
        // 3. Javascript makes a context lost using WEBGL_lose_context extension.
        // 4. Here.
        return false;
    }

    // Resolve the multisampled buffer into m_colorBuffer texture.
    if (m_multisampleMode != None)
        commit();

    if (bitmap) {
        bitmap->setSize(size());

        unsigned char* pixels = bitmap->pixels();
        bool needPremultiply = m_actualAttributes.alpha && !m_actualAttributes.premultipliedAlpha;
        WebGLImageConversion::AlphaOp op = needPremultiply ? WebGLImageConversion::AlphaDoPremultiply : WebGLImageConversion::AlphaDoNothing;
        if (pixels)
            readBackFramebuffer(pixels, size().width(), size().height(), ReadbackSkia, op);
    }

    // We must restore the texture binding since creating new textures,
    // consuming and producing mailboxes changes it.
    ScopedTextureUnit0BindingRestorer restorer(m_context.get(), m_activeTextureUnit, m_texture2DBinding);

    // First try to recycle an old buffer.
    RefPtr<MailboxInfo> frontColorBufferMailbox = recycledMailbox();

    // No buffer available to recycle, create a new one.
    if (!frontColorBufferMailbox) {
        TextureInfo newTexture;
        newTexture.textureId = createColorTexture();
        allocateTextureMemory(&newTexture, m_size);
        // Bad things happened, abandon ship.
        if (!newTexture.textureId)
            return false;

        frontColorBufferMailbox = createNewMailbox(newTexture);
    }

    if (m_preserveDrawingBuffer == Discard) {
        std::swap(frontColorBufferMailbox->textureInfo, m_colorBuffer);
        // It appears safe to overwrite the context's framebuffer binding in the Discard case since there will always be a
        // WebGLRenderingContext::clearIfComposited() call made before the next draw call which restores the framebuffer binding.
        // If this stops being true at some point, we should track the current framebuffer binding in the DrawingBuffer and restore
        // it after attaching the new back buffer here.
        m_context->bindFramebuffer(GL_FRAMEBUFFER, m_fbo);
        if (m_multisampleMode == ImplicitResolve)
            m_context->framebufferTexture2DMultisampleEXT(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, m_colorBuffer.textureId, 0, m_sampleCount);
        else
            m_context->framebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, m_colorBuffer.textureId, 0);
    } else {
        m_context->copyTextureCHROMIUM(GL_TEXTURE_2D, m_colorBuffer.textureId, frontColorBufferMailbox->textureInfo.textureId, 0, GL_RGBA, GL_UNSIGNED_BYTE);
    }

    if (m_multisampleMode != None && !m_framebufferBinding)
        bind();
    else
        restoreFramebufferBinding();

    m_contentsChanged = false;

    m_context->produceTextureDirectCHROMIUM(frontColorBufferMailbox->textureInfo.textureId, GL_TEXTURE_2D, frontColorBufferMailbox->mailbox.name);
    m_context->flush();
    frontColorBufferMailbox->mailbox.syncPoint = m_context->insertSyncPoint();
    frontColorBufferMailbox->mailbox.allowOverlay = frontColorBufferMailbox->textureInfo.imageId != 0;
    markLayerComposited();

    // set m_parentDrawingBuffer to make sure 'this' stays alive as long as it has live mailboxes
    ASSERT(!frontColorBufferMailbox->m_parentDrawingBuffer);
    frontColorBufferMailbox->m_parentDrawingBuffer = this;
    *outMailbox = frontColorBufferMailbox->mailbox;
    m_frontColorBuffer = frontColorBufferMailbox->textureInfo;
    return true;
}

void DrawingBuffer::mailboxReleased(const WebExternalTextureMailbox& mailbox, bool lostResource)
{
    if (m_destructionInProgress || m_context->isContextLost() || lostResource || m_isHidden) {
        mailboxReleasedWithoutRecycling(mailbox);
        return;
    }

    for (size_t i = 0; i < m_textureMailboxes.size(); i++) {
        RefPtr<MailboxInfo> mailboxInfo = m_textureMailboxes[i];
        if (nameEquals(mailboxInfo->mailbox, mailbox)) {
            mailboxInfo->mailbox.syncPoint = mailbox.syncPoint;
            ASSERT(mailboxInfo->m_parentDrawingBuffer.get() == this);
            mailboxInfo->m_parentDrawingBuffer.clear();
            m_recycledMailboxQueue.prepend(mailboxInfo->mailbox);
            return;
        }
    }
    ASSERT_NOT_REACHED();
}

void DrawingBuffer::mailboxReleasedWithoutRecycling(const WebExternalTextureMailbox& mailbox)
{
    ASSERT(m_textureMailboxes.size());
    // Ensure not to call the destructor until deleteMailbox() is completed.
    RefPtr<DrawingBuffer> self = this;
    deleteMailbox(mailbox);
}

PassRefPtr<DrawingBuffer::MailboxInfo> DrawingBuffer::recycledMailbox()
{
    if (m_recycledMailboxQueue.isEmpty())
        return PassRefPtr<MailboxInfo>();

    WebExternalTextureMailbox mailbox;
    while (!m_recycledMailboxQueue.isEmpty()) {
        mailbox = m_recycledMailboxQueue.takeLast();
        // Never have more than one mailbox in the released state.
        if (!m_recycledMailboxQueue.isEmpty())
            deleteMailbox(mailbox);
    }

    RefPtr<MailboxInfo> mailboxInfo;
    for (size_t i = 0; i < m_textureMailboxes.size(); i++) {
        if (nameEquals(m_textureMailboxes[i]->mailbox, mailbox)) {
            mailboxInfo = m_textureMailboxes[i];
            break;
        }
    }
    ASSERT(mailboxInfo);

    if (mailboxInfo->mailbox.syncPoint) {
        m_context->waitSyncPoint(mailboxInfo->mailbox.syncPoint);
        mailboxInfo->mailbox.syncPoint = 0;
    }

    if (mailboxInfo->size != m_size) {
        m_context->bindTexture(GL_TEXTURE_2D, mailboxInfo->textureInfo.textureId);
        allocateTextureMemory(&mailboxInfo->textureInfo, m_size);
        mailboxInfo->size = m_size;
    }

    return mailboxInfo.release();
}

PassRefPtr<DrawingBuffer::MailboxInfo> DrawingBuffer::createNewMailbox(const TextureInfo& info)
{
    RefPtr<MailboxInfo> returnMailbox = adoptRef(new MailboxInfo());
    m_context->genMailboxCHROMIUM(returnMailbox->mailbox.name);
    returnMailbox->textureInfo = info;
    returnMailbox->size = m_size;
    m_textureMailboxes.append(returnMailbox);
    return returnMailbox.release();
}

void DrawingBuffer::deleteMailbox(const WebExternalTextureMailbox& mailbox)
{
    for (size_t i = 0; i < m_textureMailboxes.size(); i++) {
        if (nameEquals(m_textureMailboxes[i]->mailbox, mailbox)) {
            if (mailbox.syncPoint)
                m_context->waitSyncPoint(mailbox.syncPoint);

            deleteChromiumImageForTexture(&m_textureMailboxes[i]->textureInfo);

            m_context->deleteTexture(m_textureMailboxes[i]->textureInfo.textureId);
            m_textureMailboxes.remove(i);
            return;
        }
    }
    ASSERT_NOT_REACHED();
}

bool DrawingBuffer::initialize(const IntSize& size)
{
    if (m_context->isContextLost()) {
        // Need to try to restore the context again later.
        return false;
    }

    if (m_requestedAttributes.alpha) {
        m_internalColorFormat = GL_RGBA;
        m_colorFormat = GL_RGBA;
        m_internalRenderbufferFormat = GL_RGBA8_OES;
    } else {
        m_internalColorFormat = GL_RGB;
        m_colorFormat = GL_RGB;
        m_internalRenderbufferFormat = GL_RGB8_OES;
    }

    m_context->getIntegerv(GL_MAX_TEXTURE_SIZE, &m_maxTextureSize);

    int maxSampleCount = 0;
    m_multisampleMode = None;
    if (m_requestedAttributes.antialias && m_multisampleExtensionSupported) {
        m_context->getIntegerv(GL_MAX_SAMPLES_ANGLE, &maxSampleCount);
        m_multisampleMode = ExplicitResolve;
        if (m_extensionsUtil->supportsExtension("GL_EXT_multisampled_render_to_texture"))
            m_multisampleMode = ImplicitResolve;
    }
    m_sampleCount = std::min(4, maxSampleCount);

    m_fbo = m_context->createFramebuffer();

    m_context->bindFramebuffer(GL_FRAMEBUFFER, m_fbo);
    m_colorBuffer.textureId = createColorTexture();
    if (m_multisampleMode == ImplicitResolve)
        m_context->framebufferTexture2DMultisampleEXT(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, m_colorBuffer.textureId, 0, m_sampleCount);
    else
        m_context->framebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, m_colorBuffer.textureId, 0);
    createSecondaryBuffers();
    // We first try to initialize everything with the requested attributes.
    if (!reset(size))
        return false;
    // If that succeeds, we then see what we actually got and update our actual attributes to reflect that.
    m_actualAttributes = m_requestedAttributes;
    if (m_requestedAttributes.alpha) {
        WGC3Dint alphaBits = 0;
        m_context->getIntegerv(GL_ALPHA_BITS, &alphaBits);
        m_actualAttributes.alpha = alphaBits > 0;
    }
    if (m_requestedAttributes.depth) {
        WGC3Dint depthBits = 0;
        m_context->getIntegerv(GL_DEPTH_BITS, &depthBits);
        m_actualAttributes.depth = depthBits > 0;
    }
    if (m_requestedAttributes.stencil) {
        WGC3Dint stencilBits = 0;
        m_context->getIntegerv(GL_STENCIL_BITS, &stencilBits);
        m_actualAttributes.stencil = stencilBits > 0;
    }
    m_actualAttributes.antialias = multisample();
    return true;
}

bool DrawingBuffer::copyToPlatformTexture(WebGraphicsContext3D* context, Platform3DObject texture, GLenum internalFormat, GLenum destType, GLint level, bool premultiplyAlpha, bool flipY, bool fromFrontBuffer)
{
    GLint textureId = m_colorBuffer.textureId;
    if (fromFrontBuffer && m_frontColorBuffer.textureId)
        textureId = m_frontColorBuffer.textureId;

    if (m_contentsChanged) {
        if (m_multisampleMode != None) {
            commit();
            if (!m_framebufferBinding)
                bind();
            else
                restoreFramebufferBinding();
        }
        m_context->flush();
    }

    if (!Extensions3DUtil::canUseCopyTextureCHROMIUM(internalFormat, destType, level))
        return false;

    // Contexts may be in a different share group. We must transfer the texture through a mailbox first
    RefPtr<MailboxInfo> bufferMailbox = adoptRef(new MailboxInfo());
    m_context->genMailboxCHROMIUM(bufferMailbox->mailbox.name);
    m_context->produceTextureDirectCHROMIUM(textureId, GL_TEXTURE_2D, bufferMailbox->mailbox.name);
    m_context->flush();

    bufferMailbox->mailbox.syncPoint = m_context->insertSyncPoint();

    context->waitSyncPoint(bufferMailbox->mailbox.syncPoint);
    Platform3DObject sourceTexture = context->createAndConsumeTextureCHROMIUM(GL_TEXTURE_2D, bufferMailbox->mailbox.name);

    bool unpackPremultiplyAlphaNeeded = false;
    bool unpackUnpremultiplyAlphaNeeded = false;
    if (m_actualAttributes.alpha && m_actualAttributes.premultipliedAlpha && !premultiplyAlpha)
        unpackUnpremultiplyAlphaNeeded = true;
    else if (m_actualAttributes.alpha && !m_actualAttributes.premultipliedAlpha && premultiplyAlpha)
        unpackPremultiplyAlphaNeeded = true;

    context->pixelStorei(GC3D_UNPACK_UNPREMULTIPLY_ALPHA_CHROMIUM, unpackUnpremultiplyAlphaNeeded);
    context->pixelStorei(GC3D_UNPACK_PREMULTIPLY_ALPHA_CHROMIUM, unpackPremultiplyAlphaNeeded);
    context->pixelStorei(GC3D_UNPACK_FLIP_Y_CHROMIUM, flipY);
    context->copyTextureCHROMIUM(GL_TEXTURE_2D, sourceTexture, texture, level, internalFormat, destType);
    context->pixelStorei(GC3D_UNPACK_FLIP_Y_CHROMIUM, false);
    context->pixelStorei(GC3D_UNPACK_UNPREMULTIPLY_ALPHA_CHROMIUM, false);
    context->pixelStorei(GC3D_UNPACK_PREMULTIPLY_ALPHA_CHROMIUM, false);

    context->deleteTexture(sourceTexture);

    context->flush();
    m_context->waitSyncPoint(context->insertSyncPoint());

    return true;
}

Platform3DObject DrawingBuffer::framebuffer() const
{
    return m_fbo;
}

WebLayer* DrawingBuffer::platformLayer()
{
    if (!m_layer) {
        m_layer = nullptr;
        CRASH(); // No compositor.

        m_layer->setOpaque(!m_actualAttributes.alpha);
        m_layer->setBlendBackgroundColor(m_actualAttributes.alpha);
        m_layer->setPremultipliedAlpha(m_actualAttributes.premultipliedAlpha);
    }

    return m_layer->layer();
}

void DrawingBuffer::paintCompositedResultsToCanvas(ImageBuffer* imageBuffer)
{
    if (m_context->getGraphicsResetStatusARB() != GL_NO_ERROR)
        return;

    if (!imageBuffer)
        return;
    Platform3DObject tex = imageBuffer->getBackingTexture();
    if (tex) {
        RefPtr<MailboxInfo> bufferMailbox = adoptRef(new MailboxInfo());
        m_context->genMailboxCHROMIUM(bufferMailbox->mailbox.name);
        m_context->produceTextureDirectCHROMIUM(m_frontColorBuffer.textureId, GL_TEXTURE_2D, bufferMailbox->mailbox.name);
        m_context->flush();

        bufferMailbox->mailbox.syncPoint = m_context->insertSyncPoint();
        OwnPtr<WebGraphicsContext3DProvider> provider =
            adoptPtr(Platform::current()->createSharedOffscreenGraphicsContext3DProvider());
        if (!provider)
            return;
        WebGraphicsContext3D* context = provider->context3d();
        if (!context)
            return;

        context->waitSyncPoint(bufferMailbox->mailbox.syncPoint);
        Platform3DObject sourceTexture = context->createAndConsumeTextureCHROMIUM(GL_TEXTURE_2D, bufferMailbox->mailbox.name);
        context->copyTextureCHROMIUM(GL_TEXTURE_2D, sourceTexture,
            tex, 0, GL_RGBA, GL_UNSIGNED_BYTE);
        context->deleteTexture(sourceTexture);
        context->flush();
        m_context->waitSyncPoint(context->insertSyncPoint());
        return;
    }

    Platform3DObject framebuffer = m_context->createFramebuffer();
    m_context->bindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    // We don't need to bind a copy of m_frontColorBuffer since the texture parameters are untouched.
    m_context->framebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, m_frontColorBuffer.textureId, 0);

    paintFramebufferToCanvas(framebuffer, size().width(), size().height(), !m_actualAttributes.premultipliedAlpha, imageBuffer);
    m_context->deleteFramebuffer(framebuffer);
    // Since we're using the same context as WebGL, we have to restore any state we change (in this case, just the framebuffer binding).
    restoreFramebufferBinding();
}

void DrawingBuffer::clearPlatformLayer()
{
    if (m_layer)
        m_layer->clearTexture();

    m_context->flush();
}

void DrawingBuffer::beginDestruction()
{
    ASSERT(!m_destructionInProgress);
    m_destructionInProgress = true;

    clearPlatformLayer();

    while (!m_recycledMailboxQueue.isEmpty())
        deleteMailbox(m_recycledMailboxQueue.takeLast());

    if (m_multisampleFBO)
        m_context->deleteFramebuffer(m_multisampleFBO);

    if (m_fbo)
        m_context->deleteFramebuffer(m_fbo);

    if (m_multisampleColorBuffer)
        m_context->deleteRenderbuffer(m_multisampleColorBuffer);

    if (m_depthStencilBuffer)
        m_context->deleteRenderbuffer(m_depthStencilBuffer);

    if (m_depthBuffer)
        m_context->deleteRenderbuffer(m_depthBuffer);

    if (m_stencilBuffer)
        m_context->deleteRenderbuffer(m_stencilBuffer);

    if (m_colorBuffer.textureId) {
        deleteChromiumImageForTexture(&m_colorBuffer);
        m_context->deleteTexture(m_colorBuffer.textureId);
    }

    setSize(IntSize());

    m_colorBuffer = TextureInfo();
    m_frontColorBuffer = TextureInfo();
    m_multisampleColorBuffer = 0;
    m_depthStencilBuffer = 0;
    m_depthBuffer = 0;
    m_stencilBuffer = 0;
    m_multisampleFBO = 0;
    m_fbo = 0;
    m_contextEvictionManager.clear();
}

unsigned DrawingBuffer::createColorTexture()
{
    unsigned offscreenColorTexture = m_context->createTexture();
    if (!offscreenColorTexture)
        return 0;

    m_context->bindTexture(GL_TEXTURE_2D, offscreenColorTexture);
    m_context->texParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    m_context->texParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    m_context->texParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    m_context->texParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    return offscreenColorTexture;
}

void DrawingBuffer::createSecondaryBuffers()
{
    // create a multisample FBO
    if (m_multisampleMode == ExplicitResolve) {
        m_multisampleFBO = m_context->createFramebuffer();
        m_context->bindFramebuffer(GL_FRAMEBUFFER, m_multisampleFBO);
        m_multisampleColorBuffer = m_context->createRenderbuffer();
    }
}

bool DrawingBuffer::resizeFramebuffer(const IntSize& size)
{
    // resize regular FBO
    m_context->bindFramebuffer(GL_FRAMEBUFFER, m_fbo);

    m_context->bindTexture(GL_TEXTURE_2D, m_colorBuffer.textureId);

    allocateTextureMemory(&m_colorBuffer, size);

    if (m_multisampleMode == ImplicitResolve)
        m_context->framebufferTexture2DMultisampleEXT(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, m_colorBuffer.textureId, 0, m_sampleCount);
    else
        m_context->framebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, m_colorBuffer.textureId, 0);

    m_context->bindTexture(GL_TEXTURE_2D, 0);

    if (m_multisampleMode != ExplicitResolve)
        resizeDepthStencil(size);
    if (m_context->checkFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        return false;

    return true;
}

bool DrawingBuffer::resizeMultisampleFramebuffer(const IntSize& size)
{
    if (m_multisampleMode == ExplicitResolve) {
        m_context->bindFramebuffer(GL_FRAMEBUFFER, m_multisampleFBO);

        m_context->bindRenderbuffer(GL_RENDERBUFFER, m_multisampleColorBuffer);
        m_context->renderbufferStorageMultisampleCHROMIUM(GL_RENDERBUFFER, m_sampleCount, m_internalRenderbufferFormat, size.width(), size.height());

        if (m_context->getError() == GL_OUT_OF_MEMORY)
            return false;

        m_context->framebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, m_multisampleColorBuffer);
        resizeDepthStencil(size);
        if (m_context->checkFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
            return false;
    }

    return true;
}

void DrawingBuffer::resizeDepthStencil(const IntSize& size)
{
    if (!m_requestedAttributes.depth && !m_requestedAttributes.stencil)
        return;

    if (m_packedDepthStencilExtensionSupported) {
        if (!m_depthStencilBuffer)
            m_depthStencilBuffer = m_context->createRenderbuffer();
        m_context->bindRenderbuffer(GL_RENDERBUFFER, m_depthStencilBuffer);
        if (m_multisampleMode == ImplicitResolve)
            m_context->renderbufferStorageMultisampleEXT(GL_RENDERBUFFER, m_sampleCount, GL_DEPTH24_STENCIL8_OES, size.width(), size.height());
        else if (m_multisampleMode == ExplicitResolve)
            m_context->renderbufferStorageMultisampleCHROMIUM(GL_RENDERBUFFER, m_sampleCount, GL_DEPTH24_STENCIL8_OES, size.width(), size.height());
        else
            m_context->renderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8_OES, size.width(), size.height());
        m_context->framebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, m_depthStencilBuffer);
        m_context->framebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, m_depthStencilBuffer);
    } else {
        if (m_requestedAttributes.depth) {
            if (!m_depthBuffer)
                m_depthBuffer = m_context->createRenderbuffer();
            m_context->bindRenderbuffer(GL_RENDERBUFFER, m_depthBuffer);
            if (m_multisampleMode == ImplicitResolve)
                m_context->renderbufferStorageMultisampleEXT(GL_RENDERBUFFER, m_sampleCount, GL_DEPTH_COMPONENT16, size.width(), size.height());
            else if (m_multisampleMode == ExplicitResolve)
                m_context->renderbufferStorageMultisampleCHROMIUM(GL_RENDERBUFFER, m_sampleCount, GL_DEPTH_COMPONENT16, size.width(), size.height());
            else
                m_context->renderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, size.width(), size.height());
            m_context->framebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, m_depthBuffer);
        }
        if (m_requestedAttributes.stencil) {
            if (!m_stencilBuffer)
                m_stencilBuffer = m_context->createRenderbuffer();
            m_context->bindRenderbuffer(GL_RENDERBUFFER, m_stencilBuffer);
            if (m_multisampleMode == ImplicitResolve)
                m_context->renderbufferStorageMultisampleEXT(GL_RENDERBUFFER, m_sampleCount, GL_STENCIL_INDEX8, size.width(), size.height());
            else if (m_multisampleMode == ExplicitResolve)
                m_context->renderbufferStorageMultisampleCHROMIUM(GL_RENDERBUFFER, m_sampleCount, GL_STENCIL_INDEX8, size.width(), size.height());
            else
                m_context->renderbufferStorage(GL_RENDERBUFFER, GL_STENCIL_INDEX8, size.width(), size.height());
            m_context->framebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, m_stencilBuffer);
        }
    }
    m_context->bindRenderbuffer(GL_RENDERBUFFER, 0);
}



void DrawingBuffer::clearFramebuffers(GLbitfield clearMask)
{
    // We will clear the multisample FBO, but we also need to clear the non-multisampled buffer.
    if (m_multisampleFBO) {
        m_context->bindFramebuffer(GL_FRAMEBUFFER, m_fbo);
        m_context->clear(GL_COLOR_BUFFER_BIT);
    }

    m_context->bindFramebuffer(GL_FRAMEBUFFER, m_multisampleFBO ? m_multisampleFBO : m_fbo);
    m_context->clear(clearMask);
}

void DrawingBuffer::setSize(const IntSize& size)
{
    if (m_size == size)
        return;

    s_currentResourceUsePixels += pixelDelta(size, m_size);
    m_size = size;
}

int DrawingBuffer::pixelDelta(const IntSize& newSize, const IntSize& curSize)
{
    return (std::max(0, newSize.width()) * std::max(0, newSize.height())) - (std::max(0, curSize.width()) * std::max(0, curSize.height()));
}

IntSize DrawingBuffer::adjustSize(const IntSize& desiredSize, const IntSize& curSize, int maxTextureSize)
{
    IntSize adjustedSize = desiredSize;

    // Clamp if the desired size is greater than the maximum texture size for the device.
    if (adjustedSize.height() > maxTextureSize)
        adjustedSize.setHeight(maxTextureSize);

    if (adjustedSize.width() > maxTextureSize)
        adjustedSize.setWidth(maxTextureSize);

    // Try progressively smaller sizes until we find a size that fits or reach a scale limit.
    int scaleAttempts = 0;
    while ((s_currentResourceUsePixels + pixelDelta(adjustedSize, curSize)) > s_maximumResourceUsePixels) {
        scaleAttempts++;
        if (scaleAttempts > s_maxScaleAttempts)
            return IntSize();

        adjustedSize.scale(s_resourceAdjustedRatio);

        if (adjustedSize.isEmpty())
            return IntSize();
    }

    return adjustedSize;
}

IntSize DrawingBuffer::adjustSizeWithContextEviction(const IntSize& size, bool& evictContext)
{
    IntSize adjustedSize = adjustSize(size, m_size, m_maxTextureSize);
    if (!adjustedSize.isEmpty()) {
        evictContext = false;
        return adjustedSize; // Buffer fits without evicting a context.
    }

    // Speculatively adjust the pixel budget to see if the buffer would fit should the oldest context be evicted.
    IntSize oldestSize = m_contextEvictionManager->oldestContextSize();
    int pixelDelta = oldestSize.width() * oldestSize.height();

    s_currentResourceUsePixels -= pixelDelta;
    adjustedSize = adjustSize(size, m_size, m_maxTextureSize);
    s_currentResourceUsePixels += pixelDelta;

    evictContext = !adjustedSize.isEmpty();
    return adjustedSize;
}

bool DrawingBuffer::reset(const IntSize& newSize)
{
    ASSERT(!newSize.isEmpty());
    IntSize adjustedSize;
    bool evictContext = false;
    bool isNewContext = m_size.isEmpty();
    if (s_allowContextEvictionOnCreate && isNewContext)
        adjustedSize = adjustSizeWithContextEviction(newSize, evictContext);
    else
        adjustedSize = adjustSize(newSize, m_size, m_maxTextureSize);

    if (adjustedSize.isEmpty())
        return false;

    if (evictContext)
        m_contextEvictionManager->forciblyLoseOldestContext("WARNING: WebGL contexts have exceeded the maximum allowed backbuffer area. Oldest context will be lost.");

    if (adjustedSize != m_size) {
        do {
            // resize multisample FBO
            if (!resizeMultisampleFramebuffer(adjustedSize) || !resizeFramebuffer(adjustedSize)) {
                adjustedSize.scale(s_resourceAdjustedRatio);
                continue;
            }
            break;
        } while (!adjustedSize.isEmpty());

        setSize(adjustedSize);

        if (adjustedSize.isEmpty())
            return false;
    }

    m_context->disable(GL_SCISSOR_TEST);
    m_context->clearColor(0, 0, 0, 0);
    m_context->colorMask(true, true, true, true);

    GLbitfield clearMask = GL_COLOR_BUFFER_BIT;
    if (m_actualAttributes.depth) {
        m_context->clearDepth(1.0f);
        clearMask |= GL_DEPTH_BUFFER_BIT;
        m_context->depthMask(true);
    }
    if (m_actualAttributes.stencil) {
        m_context->clearStencil(0);
        clearMask |= GL_STENCIL_BUFFER_BIT;
        m_context->stencilMaskSeparate(GL_FRONT, 0xFFFFFFFF);
    }

    clearFramebuffers(clearMask);
    return true;
}

void DrawingBuffer::commit(long x, long y, long width, long height)
{
    if (width < 0)
        width = m_size.width();
    if (height < 0)
        height = m_size.height();

    if (m_multisampleFBO && !m_contentsChangeCommitted) {
        m_context->bindFramebuffer(GL_READ_FRAMEBUFFER_ANGLE, m_multisampleFBO);
        m_context->bindFramebuffer(GL_DRAW_FRAMEBUFFER_ANGLE, m_fbo);

        if (m_scissorEnabled)
            m_context->disable(GL_SCISSOR_TEST);

        // Use NEAREST, because there is no scale performed during the blit.
        m_context->blitFramebufferCHROMIUM(x, y, width, height, x, y, width, height, GL_COLOR_BUFFER_BIT, GL_NEAREST);

        if (m_scissorEnabled)
            m_context->enable(GL_SCISSOR_TEST);
    }

    m_context->bindFramebuffer(GL_FRAMEBUFFER, m_fbo);
    m_contentsChangeCommitted = true;
}

void DrawingBuffer::restoreFramebufferBinding()
{
    if (!m_framebufferBinding)
        return;

    m_context->bindFramebuffer(GL_FRAMEBUFFER, m_framebufferBinding);
}

bool DrawingBuffer::multisample() const
{
    return m_multisampleMode != None;
}

void DrawingBuffer::bind()
{
    m_context->bindFramebuffer(GL_FRAMEBUFFER, m_multisampleFBO ? m_multisampleFBO : m_fbo);
}

void DrawingBuffer::setPackAlignment(GLint param)
{
    m_packAlignment = param;
}

void DrawingBuffer::paintRenderingResultsToCanvas(ImageBuffer* imageBuffer)
{
    paintFramebufferToCanvas(framebuffer(), size().width(), size().height(), !m_actualAttributes.premultipliedAlpha, imageBuffer);
}

PassRefPtr<Uint8ClampedArray> DrawingBuffer::paintRenderingResultsToImageData(int& width, int& height)
{
    if (m_actualAttributes.premultipliedAlpha)
        return nullptr;

    width = size().width();
    height = size().height();

    Checked<int, RecordOverflow> dataSize = 4;
    dataSize *= width;
    dataSize *= height;
    if (dataSize.hasOverflowed())
        return nullptr;

    RefPtr<Uint8ClampedArray> pixels = Uint8ClampedArray::createUninitialized(width * height * 4);

    m_context->bindFramebuffer(GL_FRAMEBUFFER, framebuffer());
    readBackFramebuffer(pixels->data(), width, height, ReadbackRGBA, WebGLImageConversion::AlphaDoNothing);
    flipVertically(pixels->data(), width, height);

    return pixels.release();
}

void DrawingBuffer::paintFramebufferToCanvas(int framebuffer, int width, int height, bool premultiplyAlpha, ImageBuffer* imageBuffer)
{
    unsigned char* pixels = 0;

    const SkBitmap& canvasBitmap = imageBuffer->bitmap();
    const SkBitmap* readbackBitmap = 0;
    ASSERT(canvasBitmap.colorType() == kN32_SkColorType);
    if (canvasBitmap.width() == width && canvasBitmap.height() == height) {
        // This is the fastest and most common case. We read back
        // directly into the canvas's backing store.
        readbackBitmap = &canvasBitmap;
        m_resizingBitmap.reset();
    } else {
        // We need to allocate a temporary bitmap for reading back the
        // pixel data. We will then use Skia to rescale this bitmap to
        // the size of the canvas's backing store.
        if (m_resizingBitmap.width() != width || m_resizingBitmap.height() != height)
            m_resizingBitmap.allocN32Pixels(width, height);
        readbackBitmap = &m_resizingBitmap;
    }

    // Read back the frame buffer.
    SkAutoLockPixels bitmapLock(*readbackBitmap);
    pixels = static_cast<unsigned char*>(readbackBitmap->getPixels());

    m_context->bindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    readBackFramebuffer(pixels, width, height, ReadbackSkia, premultiplyAlpha ? WebGLImageConversion::AlphaDoPremultiply : WebGLImageConversion::AlphaDoNothing);
    flipVertically(pixels, width, height);

    readbackBitmap->notifyPixelsChanged();
    if (m_resizingBitmap.readyToDraw()) {
        // We need to draw the resizing bitmap into the canvas's backing store.
        SkCanvas canvas(canvasBitmap);
        SkRect dst;
        dst.set(SkIntToScalar(0), SkIntToScalar(0), SkIntToScalar(canvasBitmap.width()), SkIntToScalar(canvasBitmap.height()));
        canvas.drawBitmapRect(m_resizingBitmap, 0, dst);
    }
}

void DrawingBuffer::readBackFramebuffer(unsigned char* pixels, int width, int height, ReadbackOrder readbackOrder, WebGLImageConversion::AlphaOp op)
{
    if (m_packAlignment > 4)
        m_context->pixelStorei(GL_PACK_ALIGNMENT, 1);
    m_context->readPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    if (m_packAlignment > 4)
        m_context->pixelStorei(GL_PACK_ALIGNMENT, m_packAlignment);

    size_t bufferSize = 4 * width * height;

    if (readbackOrder == ReadbackSkia) {
#if (SK_R32_SHIFT == 16) && !SK_B32_SHIFT
        // Swizzle red and blue channels to match SkBitmap's byte ordering.
        // TODO(kbr): expose GL_BGRA as extension.
        for (size_t i = 0; i < bufferSize; i += 4) {
            std::swap(pixels[i], pixels[i + 2]);
        }
#endif
    }

    if (op == WebGLImageConversion::AlphaDoPremultiply) {
        for (size_t i = 0; i < bufferSize; i += 4) {
            pixels[i + 0] = std::min(255, pixels[i + 0] * pixels[i + 3] / 255);
            pixels[i + 1] = std::min(255, pixels[i + 1] * pixels[i + 3] / 255);
            pixels[i + 2] = std::min(255, pixels[i + 2] * pixels[i + 3] / 255);
        }
    } else if (op != WebGLImageConversion::AlphaDoNothing) {
        ASSERT_NOT_REACHED();
    }
}

void DrawingBuffer::flipVertically(uint8_t* framebuffer, int width, int height)
{
    m_scanline.resize(width * 4);
    uint8* scanline = &m_scanline[0];
    unsigned rowBytes = width * 4;
    unsigned count = height / 2;
    for (unsigned i = 0; i < count; i++) {
        uint8* rowA = framebuffer + i * rowBytes;
        uint8* rowB = framebuffer + (height - i - 1) * rowBytes;
        memcpy(scanline, rowB, rowBytes);
        memcpy(rowB, rowA, rowBytes);
        memcpy(rowA, scanline, rowBytes);
    }
}

void DrawingBuffer::texImage2DResourceSafe(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, GLint unpackAlignment)
{
    ASSERT(unpackAlignment == 1 || unpackAlignment == 2 || unpackAlignment == 4 || unpackAlignment == 8);
    m_context->texImage2D(target, level, internalformat, width, height, border, format, type, 0);
}

void DrawingBuffer::allocateTextureMemory(TextureInfo* info, const IntSize& size)
{
    if (RuntimeEnabledFeatures::webGLImageChromiumEnabled()) {
        deleteChromiumImageForTexture(info);

        info->imageId = m_context->createImageCHROMIUM(size.width(), size.height(), GL_RGBA8_OES, GC3D_IMAGE_SCANOUT_CHROMIUM);
        if (info->imageId) {
            m_context->bindTexImage2DCHROMIUM(GL_TEXTURE_2D, info->imageId);
            return;
        }
    }

    texImage2DResourceSafe(GL_TEXTURE_2D, 0, m_internalColorFormat, size.width(), size.height(), 0, m_colorFormat, GL_UNSIGNED_BYTE);
}

void DrawingBuffer::deleteChromiumImageForTexture(TextureInfo* info)
{
    if (info->imageId) {
        m_context->releaseTexImage2DCHROMIUM(GL_TEXTURE_2D, info->imageId);
        m_context->destroyImageCHROMIUM(info->imageId);
        info->imageId = 0;
    }
}

} // namespace blink
