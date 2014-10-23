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

#ifndef DrawingBuffer_h
#define DrawingBuffer_h

#include "platform/PlatformExport.h"
#include "platform/geometry/IntSize.h"
#include "platform/graphics/GraphicsTypes3D.h"
#include "platform/graphics/gpu/WebGLImageConversion.h"
#include "public/platform/WebExternalTextureLayerClient.h"
#include "public/platform/WebExternalTextureMailbox.h"
#include "public/platform/WebGraphicsContext3D.h"
#include "third_party/khronos/GLES2/gl2.h"
#include "third_party/khronos/GLES2/gl2ext.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "wtf/Deque.h"
#include "wtf/Noncopyable.h"
#include "wtf/OwnPtr.h"
#include "wtf/PassOwnPtr.h"

namespace blink {

class Extensions3DUtil;
class ImageBuffer;
class WebExternalBitmap;
class WebExternalTextureLayer;
class WebGraphicsContext3D;
class WebLayer;

// Abstract interface to allow basic context eviction management
class PLATFORM_EXPORT ContextEvictionManager : public RefCounted<ContextEvictionManager> {
public:
    virtual ~ContextEvictionManager() {};

    virtual void forciblyLoseOldestContext(const String& reason) = 0;
    virtual IntSize oldestContextSize() = 0;
};

// Manages a rendering target (framebuffer + attachment) for a canvas.  Can publish its rendering
// results to a WebLayer for compositing.
class PLATFORM_EXPORT DrawingBuffer : public RefCounted<DrawingBuffer>, public WebExternalTextureLayerClient  {
    // If we used CHROMIUM_image as the backing storage for our buffers,
    // we need to know the mapping from texture id to image.
    struct TextureInfo {
        Platform3DObject textureId;
        WGC3Duint imageId;

        TextureInfo()
            : textureId(0)
            , imageId(0)
        {
        }
    };

    struct MailboxInfo : public RefCounted<MailboxInfo> {
        WebExternalTextureMailbox mailbox;
        TextureInfo textureInfo;
        IntSize size;
        // This keeps the parent drawing buffer alive as long as the compositor is
        // referring to one of the mailboxes DrawingBuffer produced. The parent drawing buffer is
        // cleared when the compositor returns the mailbox. See mailboxReleased().
        RefPtr<DrawingBuffer> m_parentDrawingBuffer;
    };
public:
    enum PreserveDrawingBuffer {
        Preserve,
        Discard
    };

    static PassRefPtr<DrawingBuffer> create(PassOwnPtr<WebGraphicsContext3D>, const IntSize&, PreserveDrawingBuffer, WebGraphicsContext3D::Attributes requestedAttributes, PassRefPtr<ContextEvictionManager>);

    virtual ~DrawingBuffer();

    // Destruction will be completed after all mailboxes are released.
    void beginDestruction();

    // Issues a glClear() on all framebuffers associated with this DrawingBuffer. The caller is responsible for
    // making the context current and setting the clear values and masks. Modifies the framebuffer binding.
    void clearFramebuffers(GLbitfield clearMask);

    // Given the desired buffer size, provides the largest dimensions that will fit in the pixel budget.
    static IntSize adjustSize(const IntSize& desiredSize, const IntSize& curSize, int maxTextureSize);
    bool reset(const IntSize&);
    void bind();
    IntSize size() const { return m_size; }

    // Copies the multisample color buffer to the normal color buffer and leaves m_fbo bound.
    void commit(long x = 0, long y = 0, long width = -1, long height = -1);

    // commit should copy the full multisample buffer, and not respect the
    // current scissor bounds. Track the state of the scissor test so that it
    // can be disabled during calls to commit.
    void setScissorEnabled(bool scissorEnabled) { m_scissorEnabled = scissorEnabled; }

    // The DrawingBuffer needs to track the texture bound to texture unit 0.
    // The bound texture is tracked to avoid costly queries during rendering.
    void setTexture2DBinding(Platform3DObject texture) { m_texture2DBinding = texture; }

    // The DrawingBuffer needs to track the currently bound framebuffer so it
    // restore the binding when needed.
    void setFramebufferBinding(Platform3DObject fbo) { m_framebufferBinding = fbo; }

    // Track the currently active texture unit. Texture unit 0 is used as host for a scratch
    // texture.
    void setActiveTextureUnit(GLint textureUnit) { m_activeTextureUnit = textureUnit; }

    bool multisample() const;

    Platform3DObject framebuffer() const;

    void markContentsChanged();
    void markLayerComposited();
    bool layerComposited() const;
    void setIsHidden(bool);

    WebLayer* platformLayer();
    void paintCompositedResultsToCanvas(ImageBuffer*);

    WebGraphicsContext3D* context();

    // Returns the actual context attributes for this drawing buffer which may differ from the
    // requested context attributes due to implementation limits.
    WebGraphicsContext3D::Attributes getActualAttributes() const { return m_actualAttributes; }

    // WebExternalTextureLayerClient implementation.
    virtual bool prepareMailbox(WebExternalTextureMailbox*, WebExternalBitmap*) OVERRIDE;
    virtual void mailboxReleased(const WebExternalTextureMailbox&, bool lostResource = false) OVERRIDE;

    // Destroys the TEXTURE_2D binding for the owned context
    bool copyToPlatformTexture(WebGraphicsContext3D*, Platform3DObject texture, GLenum internalFormat,
        GLenum destType, GLint level, bool premultiplyAlpha, bool flipY, bool fromFrontBuffer = false);

    void setPackAlignment(GLint param);

    void paintRenderingResultsToCanvas(ImageBuffer*);
    PassRefPtr<Uint8ClampedArray> paintRenderingResultsToImageData(int&, int&);

protected: // For unittests
    DrawingBuffer(
        PassOwnPtr<WebGraphicsContext3D>,
        PassOwnPtr<Extensions3DUtil>,
        bool multisampleExtensionSupported,
        bool packedDepthStencilExtensionSupported,
        PreserveDrawingBuffer,
        WebGraphicsContext3D::Attributes requestedAttributes,
        PassRefPtr<ContextEvictionManager>);

    bool initialize(const IntSize&);

private:
    void mailboxReleasedWithoutRecycling(const WebExternalTextureMailbox&);

    unsigned createColorTexture();
    // Create the depth/stencil and multisample buffers, if needed.
    void createSecondaryBuffers();
    bool resizeFramebuffer(const IntSize&);
    bool resizeMultisampleFramebuffer(const IntSize&);
    void resizeDepthStencil(const IntSize&);

    // Bind to the m_framebufferBinding if it's not 0.
    void restoreFramebufferBinding();

    void clearPlatformLayer();

    PassRefPtr<MailboxInfo> recycledMailbox();
    PassRefPtr<MailboxInfo> createNewMailbox(const TextureInfo&);
    void deleteMailbox(const WebExternalTextureMailbox&);
    void freeRecycledMailboxes();

    // Updates the current size of the buffer, ensuring that s_currentResourceUsePixels is updated.
    void setSize(const IntSize& size);

    // Calculates the difference in pixels between the current buffer size and the proposed size.
    static int pixelDelta(const IntSize& newSize, const IntSize& curSize);

    // Given the desired buffer size, provides the largest dimensions that will fit in the pixel budget
    // Returns true if the buffer will only fit if the oldest WebGL context is forcibly lost
    IntSize adjustSizeWithContextEviction(const IntSize&, bool& evictContext);

    void paintFramebufferToCanvas(int framebuffer, int width, int height, bool premultiplyAlpha, ImageBuffer*);

    // This is the order of bytes to use when doing a readback.
    enum ReadbackOrder {
        ReadbackRGBA,
        ReadbackSkia
    };

    // Helper function which does a readback from the currently-bound
    // framebuffer into a buffer of a certain size with 4-byte pixels.
    void readBackFramebuffer(unsigned char* pixels, int width, int height, ReadbackOrder, WebGLImageConversion::AlphaOp);

    // Helper function to flip a bitmap vertically.
    void flipVertically(uint8_t* data, int width, int height);

    // Helper to texImage2D with pixel==0 case: pixels are initialized to 0.
    // By default, alignment is 4, the OpenGL default setting.
    void texImage2DResourceSafe(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, GLint alignment = 4);
    // Allocate buffer storage to be sent to compositor using either texImage2D or CHROMIUM_image based on available support.
    void allocateTextureMemory(TextureInfo*, const IntSize&);
    void deleteChromiumImageForTexture(TextureInfo*);

    PreserveDrawingBuffer m_preserveDrawingBuffer;
    bool m_scissorEnabled;
    Platform3DObject m_texture2DBinding;
    Platform3DObject m_framebufferBinding;
    GLenum m_activeTextureUnit;

    OwnPtr<WebGraphicsContext3D> m_context;
    OwnPtr<Extensions3DUtil> m_extensionsUtil;
    IntSize m_size;
    WebGraphicsContext3D::Attributes m_requestedAttributes;
    bool m_multisampleExtensionSupported;
    bool m_packedDepthStencilExtensionSupported;
    Platform3DObject m_fbo;
    // DrawingBuffer's output is double-buffered. m_colorBuffer is the back buffer.
    TextureInfo m_colorBuffer;
    TextureInfo m_frontColorBuffer;

    // This is used when we have OES_packed_depth_stencil.
    Platform3DObject m_depthStencilBuffer;

    // These are used when we don't.
    Platform3DObject m_depthBuffer;
    Platform3DObject m_stencilBuffer;

    // For multisampling.
    Platform3DObject m_multisampleFBO;
    Platform3DObject m_multisampleColorBuffer;

    // True if our contents have been modified since the last presentation of this buffer.
    bool m_contentsChanged;

    // True if commit() has been called since the last time markContentsChanged() had been called.
    bool m_contentsChangeCommitted;
    bool m_layerComposited;

    enum MultisampleMode {
        None,
        ImplicitResolve,
        ExplicitResolve,
    };

    MultisampleMode m_multisampleMode;

    WebGraphicsContext3D::Attributes m_actualAttributes;
    unsigned m_internalColorFormat;
    unsigned m_colorFormat;
    unsigned m_internalRenderbufferFormat;
    int m_maxTextureSize;
    int m_sampleCount;
    int m_packAlignment;
    bool m_destructionInProgress;
    bool m_isHidden;

    OwnPtr<WebExternalTextureLayer> m_layer;

    // All of the mailboxes that this DrawingBuffer has ever created.
    Vector<RefPtr<MailboxInfo> > m_textureMailboxes;
    // Mailboxes that were released by the compositor can be used again by this DrawingBuffer.
    Deque<WebExternalTextureMailbox> m_recycledMailboxQueue;

    RefPtr<ContextEvictionManager> m_contextEvictionManager;

    // If the width and height of the Canvas's backing store don't
    // match those that we were given in the most recent call to
    // reshape(), then we need an intermediate bitmap to read back the
    // frame buffer into. This seems to happen when CSS styles are
    // used to resize the Canvas.
    SkBitmap m_resizingBitmap;

    // Used to flip a bitmap vertically.
    Vector<uint8_t> m_scanline;
};

} // namespace blink

#endif // DrawingBuffer_h
