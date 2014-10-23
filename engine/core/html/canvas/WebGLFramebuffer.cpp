/*
 * Copyright (C) 2009 Apple Inc. All rights reserved.
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

#include "core/html/canvas/WebGLFramebuffer.h"

#include "core/html/canvas/WebGLRenderingContextBase.h"
#include "platform/NotImplemented.h"

namespace blink {

namespace {

    Platform3DObject objectOrZero(WebGLObject* object)
    {
        return object ? object->object() : 0;
    }

    class WebGLRenderbufferAttachment FINAL : public WebGLFramebuffer::WebGLAttachment {
    public:
        static PassRefPtrWillBeRawPtr<WebGLFramebuffer::WebGLAttachment> create(WebGLRenderbuffer*);

        virtual void trace(Visitor*) OVERRIDE;

    private:
        explicit WebGLRenderbufferAttachment(WebGLRenderbuffer*);
        WebGLRenderbufferAttachment() { }

        virtual GLsizei width() const OVERRIDE;
        virtual GLsizei height() const OVERRIDE;
        virtual GLenum format() const OVERRIDE;
        virtual GLenum type() const OVERRIDE;
        virtual WebGLSharedObject* object() const OVERRIDE;
        virtual bool isSharedObject(WebGLSharedObject*) const OVERRIDE;
        virtual bool valid() const OVERRIDE;
        virtual void onDetached(blink::WebGraphicsContext3D*) OVERRIDE;
        virtual void attach(blink::WebGraphicsContext3D*, GLenum attachment) OVERRIDE;
        virtual void unattach(blink::WebGraphicsContext3D*, GLenum attachment) OVERRIDE;

        RefPtrWillBeMember<WebGLRenderbuffer> m_renderbuffer;
    };

    PassRefPtrWillBeRawPtr<WebGLFramebuffer::WebGLAttachment> WebGLRenderbufferAttachment::create(WebGLRenderbuffer* renderbuffer)
    {
        return adoptRefWillBeNoop(new WebGLRenderbufferAttachment(renderbuffer));
    }

    void WebGLRenderbufferAttachment::trace(Visitor* visitor)
    {
        visitor->trace(m_renderbuffer);
        WebGLFramebuffer::WebGLAttachment::trace(visitor);
    }

    WebGLRenderbufferAttachment::WebGLRenderbufferAttachment(WebGLRenderbuffer* renderbuffer)
        : m_renderbuffer(renderbuffer)
    {
    }

    GLsizei WebGLRenderbufferAttachment::width() const
    {
        return m_renderbuffer->width();
    }

    GLsizei WebGLRenderbufferAttachment::height() const
    {
        return m_renderbuffer->height();
    }

    GLenum WebGLRenderbufferAttachment::format() const
    {
        GLenum format = m_renderbuffer->internalFormat();
        if (format == GL_DEPTH_STENCIL_OES
            && m_renderbuffer->emulatedStencilBuffer()
            && m_renderbuffer->emulatedStencilBuffer()->internalFormat() != GL_STENCIL_INDEX8) {
            return 0;
        }
        return format;
    }

    WebGLSharedObject* WebGLRenderbufferAttachment::object() const
    {
        return m_renderbuffer->object() ? m_renderbuffer.get() : 0;
    }

    bool WebGLRenderbufferAttachment::isSharedObject(WebGLSharedObject* object) const
    {
        return object == m_renderbuffer;
    }

    bool WebGLRenderbufferAttachment::valid() const
    {
        return m_renderbuffer->object();
    }

    void WebGLRenderbufferAttachment::onDetached(blink::WebGraphicsContext3D* context)
    {
        m_renderbuffer->onDetached(context);
    }

    void WebGLRenderbufferAttachment::attach(blink::WebGraphicsContext3D* context, GLenum attachment)
    {
        Platform3DObject object = objectOrZero(m_renderbuffer.get());
        if (attachment == GC3D_DEPTH_STENCIL_ATTACHMENT_WEBGL && m_renderbuffer->emulatedStencilBuffer()) {
            context->framebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, object);
            context->framebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, objectOrZero(m_renderbuffer->emulatedStencilBuffer()));
        } else {
            context->framebufferRenderbuffer(GL_FRAMEBUFFER, attachment, GL_RENDERBUFFER, object);
        }
    }

    void WebGLRenderbufferAttachment::unattach(blink::WebGraphicsContext3D* context, GLenum attachment)
    {
        if (attachment == GC3D_DEPTH_STENCIL_ATTACHMENT_WEBGL) {
            context->framebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, 0);
            context->framebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, 0);
        } else {
            context->framebufferRenderbuffer(GL_FRAMEBUFFER, attachment, GL_RENDERBUFFER, 0);
        }
    }

    GLenum WebGLRenderbufferAttachment::type() const
    {
        notImplemented();
        return 0;
    }

    class WebGLTextureAttachment FINAL : public WebGLFramebuffer::WebGLAttachment {
    public:
        static PassRefPtrWillBeRawPtr<WebGLFramebuffer::WebGLAttachment> create(WebGLTexture*, GLenum target, GLint level);

        virtual void trace(Visitor*) OVERRIDE;

    private:
        WebGLTextureAttachment(WebGLTexture*, GLenum target, GLint level);
        WebGLTextureAttachment() { }

        virtual GLsizei width() const OVERRIDE;
        virtual GLsizei height() const OVERRIDE;
        virtual GLenum format() const OVERRIDE;
        virtual GLenum type() const OVERRIDE;
        virtual WebGLSharedObject* object() const OVERRIDE;
        virtual bool isSharedObject(WebGLSharedObject*) const OVERRIDE;
        virtual bool valid() const OVERRIDE;
        virtual void onDetached(blink::WebGraphicsContext3D*) OVERRIDE;
        virtual void attach(blink::WebGraphicsContext3D*, GLenum attachment) OVERRIDE;
        virtual void unattach(blink::WebGraphicsContext3D*, GLenum attachment) OVERRIDE;

        RefPtrWillBeMember<WebGLTexture> m_texture;
        GLenum m_target;
        GLint m_level;
    };

    PassRefPtrWillBeRawPtr<WebGLFramebuffer::WebGLAttachment> WebGLTextureAttachment::create(WebGLTexture* texture, GLenum target, GLint level)
    {
        return adoptRefWillBeNoop(new WebGLTextureAttachment(texture, target, level));
    }

    void WebGLTextureAttachment::trace(Visitor* visitor)
    {
        visitor->trace(m_texture);
        WebGLFramebuffer::WebGLAttachment::trace(visitor);
    }

    WebGLTextureAttachment::WebGLTextureAttachment(WebGLTexture* texture, GLenum target, GLint level)
        : m_texture(texture)
        , m_target(target)
        , m_level(level)
    {
    }

    GLsizei WebGLTextureAttachment::width() const
    {
        return m_texture->getWidth(m_target, m_level);
    }

    GLsizei WebGLTextureAttachment::height() const
    {
        return m_texture->getHeight(m_target, m_level);
    }

    GLenum WebGLTextureAttachment::format() const
    {
        return m_texture->getInternalFormat(m_target, m_level);
    }

    WebGLSharedObject* WebGLTextureAttachment::object() const
    {
        return m_texture->object() ? m_texture.get() : 0;
    }

    bool WebGLTextureAttachment::isSharedObject(WebGLSharedObject* object) const
    {
        return object == m_texture;
    }

    bool WebGLTextureAttachment::valid() const
    {
        return m_texture->object();
    }

    void WebGLTextureAttachment::onDetached(blink::WebGraphicsContext3D* context)
    {
        m_texture->onDetached(context);
    }

    void WebGLTextureAttachment::attach(blink::WebGraphicsContext3D* context, GLenum attachment)
    {
        Platform3DObject object = objectOrZero(m_texture.get());
        context->framebufferTexture2D(GL_FRAMEBUFFER, attachment, m_target, object, m_level);
    }

    void WebGLTextureAttachment::unattach(blink::WebGraphicsContext3D* context, GLenum attachment)
    {
        if (attachment == GC3D_DEPTH_STENCIL_ATTACHMENT_WEBGL) {
            context->framebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, m_target, 0, m_level);
            context->framebufferTexture2D(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, m_target, 0, m_level);
        } else {
            context->framebufferTexture2D(GL_FRAMEBUFFER, attachment, m_target, 0, m_level);
        }
    }

    GLenum WebGLTextureAttachment::type() const
    {
        return m_texture->getType(m_target, m_level);
    }

    bool isColorRenderable(GLenum internalformat)
    {
        switch (internalformat) {
        case GL_RGBA4:
        case GL_RGB5_A1:
        case GL_RGB565:
            return true;
        default:
            return false;
        }
    }

} // anonymous namespace

WebGLFramebuffer::WebGLAttachment::WebGLAttachment()
{
}

WebGLFramebuffer::WebGLAttachment::~WebGLAttachment()
{
}

PassRefPtrWillBeRawPtr<WebGLFramebuffer> WebGLFramebuffer::create(WebGLRenderingContextBase* ctx)
{
    return adoptRefWillBeNoop(new WebGLFramebuffer(ctx));
}

WebGLFramebuffer::WebGLFramebuffer(WebGLRenderingContextBase* ctx)
    : WebGLContextObject(ctx)
    , m_hasEverBeenBound(false)
{
    ScriptWrappable::init(this);
    setObject(ctx->webContext()->createFramebuffer());
}

WebGLFramebuffer::~WebGLFramebuffer()
{
    // Delete the platform framebuffer resource. Explicit detachment
    // is for the benefit of Oilpan, where the framebuffer object
    // isn't detached when it and the WebGLRenderingContextBase object
    // it is registered with are both finalized. Without Oilpan, the
    // object will have been detached.
    //
    // To keep the code regular, the trivial detach()ment is always
    // performed.
    detachAndDeleteObject();
}

void WebGLFramebuffer::setAttachmentForBoundFramebuffer(GLenum attachment, GLenum texTarget, WebGLTexture* texture, GLint level)
{
    ASSERT(isBound());
    removeAttachmentFromBoundFramebuffer(attachment);
    if (!object())
        return;
    if (texture && texture->object()) {
        m_attachments.add(attachment, WebGLTextureAttachment::create(texture, texTarget, level));
        drawBuffersIfNecessary(false);
        texture->onAttached();
    }
}

void WebGLFramebuffer::setAttachmentForBoundFramebuffer(GLenum attachment, WebGLRenderbuffer* renderbuffer)
{
    ASSERT(isBound());
    removeAttachmentFromBoundFramebuffer(attachment);
    if (!object())
        return;
    if (renderbuffer && renderbuffer->object()) {
        m_attachments.add(attachment, WebGLRenderbufferAttachment::create(renderbuffer));
        drawBuffersIfNecessary(false);
        renderbuffer->onAttached();
    }
}

void WebGLFramebuffer::attach(GLenum attachment, GLenum attachmentPoint)
{
    ASSERT(isBound());
    WebGLAttachment* attachmentObject = getAttachment(attachment);
    if (attachmentObject)
        attachmentObject->attach(context()->webContext(), attachmentPoint);
}

WebGLSharedObject* WebGLFramebuffer::getAttachmentObject(GLenum attachment) const
{
    if (!object())
        return 0;
    WebGLAttachment* attachmentObject = getAttachment(attachment);
    return attachmentObject ? attachmentObject->object() : 0;
}

bool WebGLFramebuffer::isAttachmentComplete(WebGLAttachment* attachedObject, GLenum attachment, const char** reason) const
{
    ASSERT(attachedObject && attachedObject->valid());
    ASSERT(reason);

    GLenum internalformat = attachedObject->format();
    WebGLSharedObject* object = attachedObject->object();
    ASSERT(object && (object->isTexture() || object->isRenderbuffer()));

    if (attachment == GL_DEPTH_ATTACHMENT) {
        if (object->isRenderbuffer()) {
            if (internalformat != GL_DEPTH_COMPONENT16) {
                *reason = "the internalformat of the attached renderbuffer is not DEPTH_COMPONENT16";
                return false;
            }
        } else if (object->isTexture()) {
            GLenum type = attachedObject->type();
            if (!(context()->extensionEnabled(WebGLDepthTextureName) && internalformat == GL_DEPTH_COMPONENT
                && (type == GL_UNSIGNED_SHORT || type == GL_UNSIGNED_INT))) {
                *reason = "the attached texture is not a depth texture";
                return false;
            }
        }
    } else if (attachment == GL_STENCIL_ATTACHMENT) {
        // Depend on the underlying GL drivers to check stencil textures
        // and check renderbuffer type here only.
        if (object->isRenderbuffer()) {
            if (internalformat != GL_STENCIL_INDEX8) {
                *reason = "the internalformat of the attached renderbuffer is not STENCIL_INDEX8";
                return false;
            }
        }
    } else if (attachment == GC3D_DEPTH_STENCIL_ATTACHMENT_WEBGL) {
        if (object->isRenderbuffer()) {
            if (internalformat != GL_DEPTH_STENCIL_OES) {
                *reason = "the internalformat of the attached renderbuffer is not DEPTH_STENCIL";
                return false;
            }
        } else if (object->isTexture()) {
            GLenum type = attachedObject->type();
            if (!(context()->extensionEnabled(WebGLDepthTextureName) && internalformat == GL_DEPTH_STENCIL_OES
                && type == GL_UNSIGNED_INT_24_8_OES)) {
                *reason = "the attached texture is not a DEPTH_STENCIL texture";
                return false;
            }
        }
    } else if (attachment == GL_COLOR_ATTACHMENT0
        || (context()->extensionEnabled(WebGLDrawBuffersName) && attachment > GL_COLOR_ATTACHMENT0
            && attachment < static_cast<GLenum>(GL_COLOR_ATTACHMENT0 + context()->maxColorAttachments()))) {
        if (object->isRenderbuffer()) {
            if (!isColorRenderable(internalformat)) {
                *reason = "the internalformat of the attached renderbuffer is not color-renderable";
                return false;
            }
        } else if (object->isTexture()) {
            GLenum type = attachedObject->type();
            if (internalformat != GL_RGBA && internalformat != GL_RGB) {
                *reason = "the internalformat of the attached texture is not color-renderable";
                return false;
            }
            // TODO: WEBGL_color_buffer_float and EXT_color_buffer_half_float extensions have not been implemented in
            // WebGL yet. It would be better to depend on the underlying GL drivers to check on rendering to floating point textures
            // and add the check back to WebGL when above two extensions are implemented.
            // Assume UNSIGNED_BYTE is renderable here without the need to explicitly check if GL_OES_rgb8_rgba8 extension is supported.
            if (type != GL_UNSIGNED_BYTE
                && type != GL_UNSIGNED_SHORT_5_6_5
                && type != GL_UNSIGNED_SHORT_4_4_4_4
                && type != GL_UNSIGNED_SHORT_5_5_5_1
                && !(type == GL_FLOAT && context()->extensionEnabled(OESTextureFloatName))
                && !(type == GL_HALF_FLOAT_OES && context()->extensionEnabled(OESTextureHalfFloatName))) {
                *reason = "unsupported type: The attached texture is not supported to be rendered to";
                return false;
            }
        }
    } else {
        *reason = "unknown framebuffer attachment point";
        return false;
    }

    if (!attachedObject->width() || !attachedObject->height()) {
        *reason = "attachment has a 0 dimension";
        return false;
    }
    return true;
}

WebGLFramebuffer::WebGLAttachment* WebGLFramebuffer::getAttachment(GLenum attachment) const
{
    const AttachmentMap::const_iterator it = m_attachments.find(attachment);
    return (it != m_attachments.end()) ? it->value.get() : 0;
}

void WebGLFramebuffer::removeAttachmentFromBoundFramebuffer(GLenum attachment)
{
    ASSERT(isBound());
    if (!object())
        return;

    WebGLAttachment* attachmentObject = getAttachment(attachment);
    if (attachmentObject) {
        attachmentObject->onDetached(context()->webContext());
        m_attachments.remove(attachment);
        drawBuffersIfNecessary(false);
        switch (attachment) {
        case GC3D_DEPTH_STENCIL_ATTACHMENT_WEBGL:
            attach(GL_DEPTH_ATTACHMENT, GL_DEPTH_ATTACHMENT);
            attach(GL_STENCIL_ATTACHMENT, GL_STENCIL_ATTACHMENT);
            break;
        case GL_DEPTH_ATTACHMENT:
            attach(GC3D_DEPTH_STENCIL_ATTACHMENT_WEBGL, GL_DEPTH_ATTACHMENT);
            break;
        case GL_STENCIL_ATTACHMENT:
            attach(GC3D_DEPTH_STENCIL_ATTACHMENT_WEBGL, GL_STENCIL_ATTACHMENT);
            break;
        }
    }
}

void WebGLFramebuffer::removeAttachmentFromBoundFramebuffer(WebGLSharedObject* attachment)
{
    ASSERT(isBound());
    if (!object())
        return;
    if (!attachment)
        return;

    bool checkMore = true;
    while (checkMore) {
        checkMore = false;
        for (AttachmentMap::iterator it = m_attachments.begin(); it != m_attachments.end(); ++it) {
            WebGLAttachment* attachmentObject = it->value.get();
            if (attachmentObject->isSharedObject(attachment)) {
                GLenum attachmentType = it->key;
                attachmentObject->unattach(context()->webContext(), attachmentType);
                removeAttachmentFromBoundFramebuffer(attachmentType);
                checkMore = true;
                break;
            }
        }
    }
}

GLenum WebGLFramebuffer::colorBufferFormat() const
{
    if (!object())
        return 0;
    WebGLAttachment* attachment = getAttachment(GL_COLOR_ATTACHMENT0);
    if (!attachment)
        return 0;
    return attachment->format();
}

GLenum WebGLFramebuffer::checkStatus(const char** reason) const
{
    unsigned count = 0;
    GLsizei width = 0, height = 0;
    bool haveDepth = false;
    bool haveStencil = false;
    bool haveDepthStencil = false;
    for (AttachmentMap::const_iterator it = m_attachments.begin(); it != m_attachments.end(); ++it) {
        WebGLAttachment* attachment = it->value.get();
        if (!isAttachmentComplete(attachment, it->key, reason))
            return GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT;
        if (!attachment->valid()) {
            *reason = "attachment is not valid";
            return GL_FRAMEBUFFER_UNSUPPORTED;
        }
        if (!attachment->format()) {
            *reason = "attachment is an unsupported format";
            return GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT;
        }
        switch (it->key) {
        case GL_DEPTH_ATTACHMENT:
            haveDepth = true;
            break;
        case GL_STENCIL_ATTACHMENT:
            haveStencil = true;
            break;
        case GC3D_DEPTH_STENCIL_ATTACHMENT_WEBGL:
            haveDepthStencil = true;
            break;
        }
        if (!count) {
            width = attachment->width();
            height = attachment->height();
        } else {
            if (width != attachment->width() || height != attachment->height()) {
                *reason = "attachments do not have the same dimensions";
                return GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS;
            }
        }
        ++count;
    }
    if (!count) {
        *reason = "no attachments";
        return GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT;
    }
    if (!width || !height) {
        *reason = "framebuffer has a 0 dimension";
        return GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT;
    }
    // WebGL specific: no conflicting DEPTH/STENCIL/DEPTH_STENCIL attachments.
    if ((haveDepthStencil && (haveDepth || haveStencil)) || (haveDepth && haveStencil)) {
        *reason = "conflicting DEPTH/STENCIL/DEPTH_STENCIL attachments";
        return GL_FRAMEBUFFER_UNSUPPORTED;
    }
    return GL_FRAMEBUFFER_COMPLETE;
}

bool WebGLFramebuffer::onAccess(blink::WebGraphicsContext3D* context3d, const char** reason)
{
    if (checkStatus(reason) != GL_FRAMEBUFFER_COMPLETE)
        return false;
    return true;
}

bool WebGLFramebuffer::hasStencilBuffer() const
{
    WebGLAttachment* attachment = getAttachment(GL_STENCIL_ATTACHMENT);
    if (!attachment)
        attachment = getAttachment(GC3D_DEPTH_STENCIL_ATTACHMENT_WEBGL);
    return attachment && attachment->valid();
}

void WebGLFramebuffer::deleteObjectImpl(blink::WebGraphicsContext3D* context3d, Platform3DObject object)
{
#if !ENABLE(OILPAN)
    // With Oilpan, both the AttachmentMap and its WebGLAttachment objects are
    // GCed objects and cannot be accessed, as they may have been finalized
    // already during the same GC sweep.
    //
    // The WebGLAttachment-derived classes instead handle detachment
    // on their own when finalizing, so the explicit notification is
    // not needed.
    for (AttachmentMap::iterator it = m_attachments.begin(); it != m_attachments.end(); ++it)
        it->value->onDetached(context3d);
#endif

    context3d->deleteFramebuffer(object);
}

bool WebGLFramebuffer::isBound() const
{
    return (context()->m_framebufferBinding.get() == this);
}

void WebGLFramebuffer::drawBuffers(const Vector<GLenum>& bufs)
{
    m_drawBuffers = bufs;
    m_filteredDrawBuffers.resize(m_drawBuffers.size());
    for (size_t i = 0; i < m_filteredDrawBuffers.size(); ++i)
        m_filteredDrawBuffers[i] = GL_NONE;
    drawBuffersIfNecessary(true);
}

void WebGLFramebuffer::drawBuffersIfNecessary(bool force)
{
    if (!context()->extensionEnabled(WebGLDrawBuffersName))
        return;
    bool reset = force;
    // This filtering works around graphics driver bugs on Mac OS X.
    for (size_t i = 0; i < m_drawBuffers.size(); ++i) {
        if (m_drawBuffers[i] != GL_NONE && getAttachment(m_drawBuffers[i])) {
            if (m_filteredDrawBuffers[i] != m_drawBuffers[i]) {
                m_filteredDrawBuffers[i] = m_drawBuffers[i];
                reset = true;
            }
        } else {
            if (m_filteredDrawBuffers[i] != GL_NONE) {
                m_filteredDrawBuffers[i] = GL_NONE;
                reset = true;
            }
        }
    }
    if (reset) {
        context()->webContext()->drawBuffersEXT(
            m_filteredDrawBuffers.size(), m_filteredDrawBuffers.data());
    }
}

GLenum WebGLFramebuffer::getDrawBuffer(GLenum drawBuffer)
{
    int index = static_cast<int>(drawBuffer - GL_DRAW_BUFFER0_EXT);
    ASSERT(index >= 0);
    if (index < static_cast<int>(m_drawBuffers.size()))
        return m_drawBuffers[index];
    if (drawBuffer == GL_DRAW_BUFFER0_EXT)
        return GL_COLOR_ATTACHMENT0;
    return GL_NONE;
}

void WebGLFramebuffer::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_attachments);
#endif
    WebGLContextObject::trace(visitor);
}

}
