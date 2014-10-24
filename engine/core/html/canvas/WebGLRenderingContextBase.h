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

#ifndef WebGLRenderingContextBase_h
#define WebGLRenderingContextBase_h

#include "bindings/core/v8/Nullable.h"
#include "core/dom/ActiveDOMObject.h"
#include "core/html/canvas/CanvasRenderingContext.h"
#include "core/html/canvas/WebGLExtensionName.h"
#include "core/html/canvas/WebGLGetInfo.h"
#include "core/page/Page.h"
#include "core/rendering/RenderBoxModelObject.h"
#include "platform/Timer.h"
#include "platform/graphics/GraphicsTypes3D.h"
#include "platform/graphics/ImageBuffer.h"
#include "platform/graphics/gpu/DrawingBuffer.h"
#include "platform/graphics/gpu/Extensions3DUtil.h"
#include "platform/graphics/gpu/WebGLImageConversion.h"
#include "public/platform/WebGraphicsContext3D.h"
#include "wtf/Float32Array.h"
#include "wtf/Int32Array.h"
#include "wtf/OwnPtr.h"
#include "wtf/text/WTFString.h"

namespace blink {
class WebLayer;
}

namespace blink {

class ANGLEInstancedArrays;
class EXTBlendMinMax;
class EXTFragDepth;
class EXTShaderTextureLOD;
class EXTTextureFilterAnisotropic;
class ExceptionState;
class HTMLImageElement;
class HTMLVideoElement;
class ImageBuffer;
class ImageData;
class IntSize;
class OESElementIndexUint;
class OESStandardDerivatives;
class OESTextureFloat;
class OESTextureFloatLinear;
class OESTextureHalfFloat;
class OESTextureHalfFloatLinear;
class OESVertexArrayObject;
class WebGLActiveInfo;
class WebGLBuffer;
class WebGLCompressedTextureATC;
class WebGLCompressedTextureETC1;
class WebGLCompressedTexturePVRTC;
class WebGLCompressedTextureS3TC;
class WebGLContextAttributes;
class WebGLContextGroup;
class WebGLContextObject;
class WebGLDebugRendererInfo;
class WebGLDebugShaders;
class WebGLDepthTexture;
class WebGLDrawBuffers;
class WebGLExtension;
class WebGLFramebuffer;
class WebGLLoseContext;
class WebGLObject;
class WebGLProgram;
class WebGLRenderbuffer;
class WebGLShader;
class WebGLShaderPrecisionFormat;
class WebGLSharedObject;
class WebGLSharedWebGraphicsContext3D;
class WebGLTexture;
class WebGLUniformLocation;
class WebGLVertexArrayObjectOES;

class WebGLRenderingContextLostCallback;
class WebGLRenderingContextErrorMessageCallback;

class WebGLRenderingContextBase: public CanvasRenderingContext, public ActiveDOMObject, public Page::MultisamplingChangedObserver {
    WILL_BE_USING_GARBAGE_COLLECTED_MIXIN(WebGLRenderingContextBase);
public:
    virtual ~WebGLRenderingContextBase();

    virtual unsigned version() const = 0;
    virtual String contextName() const = 0;
    virtual void registerContextExtensions() = 0;

    static unsigned getWebGLVersion(const CanvasRenderingContext*);

    int drawingBufferWidth() const;
    int drawingBufferHeight() const;

    void activeTexture(GLenum texture);
    void attachShader(WebGLProgram*, WebGLShader*);
    void bindAttribLocation(WebGLProgram*, GLuint index, const String& name);
    void bindBuffer(GLenum target, WebGLBuffer*);
    void bindFramebuffer(GLenum target, WebGLFramebuffer*);
    void bindRenderbuffer(GLenum target, WebGLRenderbuffer*);
    void bindTexture(GLenum target, WebGLTexture*);
    void blendColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
    void blendEquation(GLenum mode);
    void blendEquationSeparate(GLenum modeRGB, GLenum modeAlpha);
    void blendFunc(GLenum sfactor, GLenum dfactor);
    void blendFuncSeparate(GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha);

    void bufferData(GLenum target, long long size, GLenum usage);
    void bufferData(GLenum target, ArrayBuffer* data, GLenum usage);
    void bufferData(GLenum target, ArrayBufferView* data, GLenum usage);
    void bufferSubData(GLenum target, long long offset, ArrayBuffer* data);
    void bufferSubData(GLenum target, long long offset, ArrayBufferView* data);

    GLenum checkFramebufferStatus(GLenum target);
    void clear(GLbitfield mask);
    void clearColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
    void clearDepth(GLfloat);
    void clearStencil(GLint);
    void colorMask(GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha);
    void compileShader(WebGLShader*);

    void compressedTexImage2D(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, ArrayBufferView* data);
    void compressedTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, ArrayBufferView* data);

    void copyTexImage2D(GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border);
    void copyTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height);

    PassRefPtrWillBeRawPtr<WebGLBuffer> createBuffer();
    PassRefPtrWillBeRawPtr<WebGLFramebuffer> createFramebuffer();
    PassRefPtrWillBeRawPtr<WebGLProgram> createProgram();
    PassRefPtrWillBeRawPtr<WebGLRenderbuffer> createRenderbuffer();
    PassRefPtrWillBeRawPtr<WebGLShader> createShader(GLenum type);
    PassRefPtrWillBeRawPtr<WebGLTexture> createTexture();

    void cullFace(GLenum mode);

    void deleteBuffer(WebGLBuffer*);
    void deleteFramebuffer(WebGLFramebuffer*);
    void deleteProgram(WebGLProgram*);
    void deleteRenderbuffer(WebGLRenderbuffer*);
    void deleteShader(WebGLShader*);
    void deleteTexture(WebGLTexture*);

    void depthFunc(GLenum);
    void depthMask(GLboolean);
    void depthRange(GLfloat zNear, GLfloat zFar);
    void detachShader(WebGLProgram*, WebGLShader*);
    void disable(GLenum cap);
    void disableVertexAttribArray(GLuint index);
    void drawArrays(GLenum mode, GLint first, GLsizei count);
    void drawElements(GLenum mode, GLsizei count, GLenum type, long long offset);

    void drawArraysInstancedANGLE(GLenum mode, GLint first, GLsizei count, GLsizei primcount);
    void drawElementsInstancedANGLE(GLenum mode, GLsizei count, GLenum type, long long offset, GLsizei primcount);

    void enable(GLenum cap);
    void enableVertexAttribArray(GLuint index);
    void finish();
    void flush();
    void framebufferRenderbuffer(GLenum target, GLenum attachment, GLenum renderbuffertarget, WebGLRenderbuffer*);
    void framebufferTexture2D(GLenum target, GLenum attachment, GLenum textarget, WebGLTexture*, GLint level);
    void frontFace(GLenum mode);
    void generateMipmap(GLenum target);

    PassRefPtrWillBeRawPtr<WebGLActiveInfo> getActiveAttrib(WebGLProgram*, GLuint index);
    PassRefPtrWillBeRawPtr<WebGLActiveInfo> getActiveUniform(WebGLProgram*, GLuint index);
    bool getAttachedShaders(WebGLProgram*, WillBeHeapVector<RefPtrWillBeMember<WebGLShader> >&);
    Nullable<WillBeHeapVector<RefPtrWillBeMember<WebGLShader> > > getAttachedShaders(WebGLProgram*);
    GLint getAttribLocation(WebGLProgram*, const String& name);
    WebGLGetInfo getBufferParameter(GLenum target, GLenum pname);
    PassRefPtrWillBeRawPtr<WebGLContextAttributes> getContextAttributes();
    GLenum getError();
    PassRefPtrWillBeRawPtr<WebGLExtension> getExtension(const String& name);
    WebGLGetInfo getFramebufferAttachmentParameter(GLenum target, GLenum attachment, GLenum pname);
    WebGLGetInfo getParameter(GLenum pname);
    WebGLGetInfo getProgramParameter(WebGLProgram*, GLenum pname);
    String getProgramInfoLog(WebGLProgram*);
    WebGLGetInfo getRenderbufferParameter(GLenum target, GLenum pname);
    WebGLGetInfo getShaderParameter(WebGLShader*, GLenum pname);
    String getShaderInfoLog(WebGLShader*);
    PassRefPtrWillBeRawPtr<WebGLShaderPrecisionFormat> getShaderPrecisionFormat(GLenum shaderType, GLenum precisionType);
    String getShaderSource(WebGLShader*);
    Nullable<Vector<String> > getSupportedExtensions();
    WebGLGetInfo getTexParameter(GLenum target, GLenum pname);
    WebGLGetInfo getUniform(WebGLProgram*, const WebGLUniformLocation*);
    PassRefPtrWillBeRawPtr<WebGLUniformLocation> getUniformLocation(WebGLProgram*, const String&);
    WebGLGetInfo getVertexAttrib(GLuint index, GLenum pname);
    long long getVertexAttribOffset(GLuint index, GLenum pname);

    void hint(GLenum target, GLenum mode);
    GLboolean isBuffer(WebGLBuffer*);
    bool isContextLost() const;
    GLboolean isEnabled(GLenum cap);
    GLboolean isFramebuffer(WebGLFramebuffer*);
    GLboolean isProgram(WebGLProgram*);
    GLboolean isRenderbuffer(WebGLRenderbuffer*);
    GLboolean isShader(WebGLShader*);
    GLboolean isTexture(WebGLTexture*);

    void lineWidth(GLfloat);
    void linkProgram(WebGLProgram*);
    void pixelStorei(GLenum pname, GLint param);
    void polygonOffset(GLfloat factor, GLfloat units);
    void readPixels(GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, ArrayBufferView* pixels);
    void renderbufferStorage(GLenum target, GLenum internalformat, GLsizei width, GLsizei height);
    void sampleCoverage(GLfloat value, GLboolean invert);
    void scissor(GLint x, GLint y, GLsizei width, GLsizei height);
    void shaderSource(WebGLShader*, const String&);
    void stencilFunc(GLenum func, GLint ref, GLuint mask);
    void stencilFuncSeparate(GLenum face, GLenum func, GLint ref, GLuint mask);
    void stencilMask(GLuint);
    void stencilMaskSeparate(GLenum face, GLuint mask);
    void stencilOp(GLenum fail, GLenum zfail, GLenum zpass);
    void stencilOpSeparate(GLenum face, GLenum fail, GLenum zfail, GLenum zpass);

    void texImage2D(GLenum target, GLint level, GLenum internalformat,
        GLsizei width, GLsizei height, GLint border,
        GLenum format, GLenum type, ArrayBufferView*, ExceptionState&);
    void texImage2D(GLenum target, GLint level, GLenum internalformat,
        GLenum format, GLenum type, ImageData*, ExceptionState&);
    void texImage2D(GLenum target, GLint level, GLenum internalformat,
        GLenum format, GLenum type, HTMLImageElement*, ExceptionState&);
    void texImage2D(GLenum target, GLint level, GLenum internalformat,
        GLenum format, GLenum type, HTMLCanvasElement*, ExceptionState&);
    void texImage2D(GLenum target, GLint level, GLenum internalformat,
        GLenum format, GLenum type, HTMLVideoElement*, ExceptionState&);

    void texParameterf(GLenum target, GLenum pname, GLfloat param);
    void texParameteri(GLenum target, GLenum pname, GLint param);

    void texSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset,
        GLsizei width, GLsizei height,
        GLenum format, GLenum type, ArrayBufferView*, ExceptionState&);
    void texSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset,
        GLenum format, GLenum type, ImageData*, ExceptionState&);
    void texSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset,
        GLenum format, GLenum type, HTMLImageElement*, ExceptionState&);
    void texSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset,
        GLenum format, GLenum type, HTMLCanvasElement*, ExceptionState&);
    void texSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset,
        GLenum format, GLenum type, HTMLVideoElement*, ExceptionState&);

    void uniform1f(const WebGLUniformLocation*, GLfloat x);
    void uniform1fv(const WebGLUniformLocation*, Float32Array* v);
    void uniform1fv(const WebGLUniformLocation*, GLfloat* v, GLsizei);
    void uniform1i(const WebGLUniformLocation*, GLint x);
    void uniform1iv(const WebGLUniformLocation*, Int32Array* v);
    void uniform1iv(const WebGLUniformLocation*, GLint* v, GLsizei);
    void uniform2f(const WebGLUniformLocation*, GLfloat x, GLfloat y);
    void uniform2fv(const WebGLUniformLocation*, Float32Array* v);
    void uniform2fv(const WebGLUniformLocation*, GLfloat* v, GLsizei);
    void uniform2i(const WebGLUniformLocation*, GLint x, GLint y);
    void uniform2iv(const WebGLUniformLocation*, Int32Array* v);
    void uniform2iv(const WebGLUniformLocation*, GLint* v, GLsizei);
    void uniform3f(const WebGLUniformLocation*, GLfloat x, GLfloat y, GLfloat z);
    void uniform3fv(const WebGLUniformLocation*, Float32Array* v);
    void uniform3fv(const WebGLUniformLocation*, GLfloat* v, GLsizei);
    void uniform3i(const WebGLUniformLocation*, GLint x, GLint y, GLint z);
    void uniform3iv(const WebGLUniformLocation*, Int32Array* v);
    void uniform3iv(const WebGLUniformLocation*, GLint* v, GLsizei);
    void uniform4f(const WebGLUniformLocation*, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
    void uniform4fv(const WebGLUniformLocation*, Float32Array* v);
    void uniform4fv(const WebGLUniformLocation*, GLfloat* v, GLsizei);
    void uniform4i(const WebGLUniformLocation*, GLint x, GLint y, GLint z, GLint w);
    void uniform4iv(const WebGLUniformLocation*, Int32Array* v);
    void uniform4iv(const WebGLUniformLocation*, GLint* v, GLsizei);
    void uniformMatrix2fv(const WebGLUniformLocation*, GLboolean transpose, Float32Array* value);
    void uniformMatrix2fv(const WebGLUniformLocation*, GLboolean transpose, GLfloat* value, GLsizei);
    void uniformMatrix3fv(const WebGLUniformLocation*, GLboolean transpose, Float32Array* value);
    void uniformMatrix3fv(const WebGLUniformLocation*, GLboolean transpose, GLfloat* value, GLsizei);
    void uniformMatrix4fv(const WebGLUniformLocation*, GLboolean transpose, Float32Array* value);
    void uniformMatrix4fv(const WebGLUniformLocation*, GLboolean transpose, GLfloat* value, GLsizei);

    void useProgram(WebGLProgram*);
    void validateProgram(WebGLProgram*);

    void vertexAttrib1f(GLuint index, GLfloat x);
    void vertexAttrib1fv(GLuint index, Float32Array* values);
    void vertexAttrib1fv(GLuint index, GLfloat* values, GLsizei);
    void vertexAttrib2f(GLuint index, GLfloat x, GLfloat y);
    void vertexAttrib2fv(GLuint index, Float32Array* values);
    void vertexAttrib2fv(GLuint index, GLfloat* values, GLsizei);
    void vertexAttrib3f(GLuint index, GLfloat x, GLfloat y, GLfloat z);
    void vertexAttrib3fv(GLuint index, Float32Array* values);
    void vertexAttrib3fv(GLuint index, GLfloat* values, GLsizei);
    void vertexAttrib4f(GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
    void vertexAttrib4fv(GLuint index, Float32Array* values);
    void vertexAttrib4fv(GLuint index, GLfloat* values, GLsizei);
    void vertexAttribPointer(GLuint index, GLint size, GLenum type, GLboolean normalized,
        GLsizei stride, long long offset);

    void vertexAttribDivisorANGLE(GLuint index, GLuint divisor);

    void viewport(GLint x, GLint y, GLsizei width, GLsizei height);

    // WEBGL_lose_context support
    enum LostContextMode {
        NotLostContext,

        // Lost context occurred at the graphics system level.
        RealLostContext,

        // Lost context provoked by WEBGL_lose_context.
        WebGLLoseContextLostContext,

        // Lost context occurred due to internal implementation reasons.
        SyntheticLostContext,
    };
    enum AutoRecoveryMethod {
        // Don't restore automatically.
        Manual,

        // Restore when resources are available.
        WhenAvailable,

        // Restore as soon as possible.
        Auto
    };
    void forceLostContext(LostContextMode, AutoRecoveryMethod);
    void forceRestoreContext();
    void loseContextImpl(LostContextMode, AutoRecoveryMethod);

    blink::WebGraphicsContext3D* webContext() const { return drawingBuffer()->context(); }
    WebGLContextGroup* contextGroup() const { return m_contextGroup.get(); }
    Extensions3DUtil* extensionsUtil();

    void reshape(int width, int height);

    void markLayerComposited();
    PassRefPtrWillBeRawPtr<ImageData> paintRenderingResultsToImageData();

    void removeSharedObject(WebGLSharedObject*);
    void removeContextObject(WebGLContextObject*);

    unsigned maxVertexAttribs() const { return m_maxVertexAttribs; }

    // ActiveDOMObject notifications
    virtual bool hasPendingActivity() const override;
    virtual void stop() override;

    void setSavingImage(bool isSaving) { m_savingImage = isSaving; }

    virtual void trace(Visitor*) override;

    class TextureUnitState {
        ALLOW_ONLY_INLINE_ALLOCATION();
    public:
        RefPtrWillBeMember<WebGLTexture> m_texture2DBinding;
        RefPtrWillBeMember<WebGLTexture> m_textureCubeMapBinding;

        void trace(Visitor*);
    };

protected:
    friend class WebGLDrawBuffers;
    friend class WebGLFramebuffer;
    friend class WebGLObject;
    friend class WebGLContextObject;
    friend class OESVertexArrayObject;
    friend class WebGLDebugShaders;
    friend class WebGLCompressedTextureATC;
    friend class WebGLCompressedTextureETC1;
    friend class WebGLCompressedTexturePVRTC;
    friend class WebGLCompressedTextureS3TC;
    friend class WebGLRenderingContextErrorMessageCallback;
    friend class WebGLVertexArrayObjectOES;
    friend class ScopedTexture2DRestorer;

    WebGLRenderingContextBase(HTMLCanvasElement*, PassOwnPtr<blink::WebGraphicsContext3D>, WebGLContextAttributes*);
    PassRefPtr<DrawingBuffer> createDrawingBuffer(PassOwnPtr<blink::WebGraphicsContext3D>);
    void initializeNewContext();
    void setupFlags();

#if ENABLE(OILPAN)
    PassRefPtr<WebGLSharedWebGraphicsContext3D> sharedWebGraphicsContext3D() const;
#endif

    // CanvasRenderingContext implementation.
    virtual bool is3d() const override { return true; }
    virtual bool isAccelerated() const override { return true; }
    virtual void setIsHidden(bool) override;
    virtual void paintRenderingResultsToCanvas() override;
    virtual blink::WebLayer* platformLayer() const override;

    void addSharedObject(WebGLSharedObject*);
    void addContextObject(WebGLContextObject*);
    void detachAndRemoveAllObjects();

    void destroyContext();
    void markContextChanged(ContentChangeType);

    // Query if the GL implementation is NPOT strict.
    bool isGLES2NPOTStrict() { return m_isGLES2NPOTStrict; }
    // Query if depth_stencil buffer is supported.
    bool isDepthStencilSupported() { return m_isDepthStencilSupported; }

    // Helper to return the size in bytes of OpenGL data types
    // like GL_FLOAT, GL_INT, etc.
    unsigned sizeInBytes(GLenum type);

    // Check if each enabled vertex attribute is bound to a buffer.
    bool validateRenderingState(const char*);

    bool validateWebGLObject(const char*, WebGLObject*);

    // Adds a compressed texture format.
    void addCompressedTextureFormat(GLenum);
    void removeAllCompressedTextureFormats();

    PassRefPtr<Image> drawImageIntoBuffer(Image*, int width, int height, const char* functionName);

    PassRefPtr<Image> videoFrameToImage(HTMLVideoElement*, BackingStoreCopy);

    WebGLRenderbuffer* ensureEmulatedStencilBuffer(GLenum target, WebGLRenderbuffer*);

    // Structure for rendering to a DrawingBuffer, instead of directly
    // to the back-buffer of m_context.
#if ENABLE(OILPAN)
    RefPtr<WebGLSharedWebGraphicsContext3D> m_sharedWebGraphicsContext3D;
#else
    RefPtr<DrawingBuffer> m_drawingBuffer;
#endif
    DrawingBuffer* drawingBuffer() const;

    RefPtr<WebGLContextGroup> m_contextGroup;

    LostContextMode m_contextLostMode;
    AutoRecoveryMethod m_autoRecoveryMethod;
    // Dispatches a context lost event once it is determined that one is needed.
    // This is used for synthetic, WEBGL_lose_context and real context losses. For real ones, it's
    // likely that there's no JavaScript on the stack, but that might be dependent
    // on how exactly the platform discovers that the context was lost. For better
    // portability we always defer the dispatch of the event.
    Timer<WebGLRenderingContextBase> m_dispatchContextLostEventTimer;
    bool m_restoreAllowed;
    Timer<WebGLRenderingContextBase> m_restoreTimer;

    bool m_needsUpdate;
    bool m_markedCanvasDirty;
    WillBeHeapHashSet<RawPtrWillBeWeakMember<WebGLContextObject> > m_contextObjects;

    OwnPtrWillBeMember<WebGLRenderingContextLostCallback> m_contextLostCallbackAdapter;
    OwnPtrWillBeMember<WebGLRenderingContextErrorMessageCallback> m_errorMessageCallbackAdapter;

    // List of bound VBO's. Used to maintain info about sizes for ARRAY_BUFFER and stored values for ELEMENT_ARRAY_BUFFER
    RefPtrWillBeMember<WebGLBuffer> m_boundArrayBuffer;

    RefPtrWillBeMember<WebGLVertexArrayObjectOES> m_defaultVertexArrayObject;
    RefPtrWillBeMember<WebGLVertexArrayObjectOES> m_boundVertexArrayObject;
    void setBoundVertexArrayObject(PassRefPtrWillBeRawPtr<WebGLVertexArrayObjectOES> arrayObject)
    {
        if (arrayObject)
            m_boundVertexArrayObject = arrayObject;
        else
            m_boundVertexArrayObject = m_defaultVertexArrayObject;
    }

    class VertexAttribValue {
    public:
        VertexAttribValue()
        {
            initValue();
        }

        void initValue()
        {
            value[0] = 0.0f;
            value[1] = 0.0f;
            value[2] = 0.0f;
            value[3] = 1.0f;
        }

        GLfloat value[4];
    };
    Vector<VertexAttribValue> m_vertexAttribValue;
    unsigned m_maxVertexAttribs;
    RefPtrWillBeMember<WebGLBuffer> m_vertexAttrib0Buffer;
    long m_vertexAttrib0BufferSize;
    GLfloat m_vertexAttrib0BufferValue[4];
    bool m_forceAttrib0BufferRefill;
    bool m_vertexAttrib0UsedBefore;

    RefPtrWillBeMember<WebGLProgram> m_currentProgram;
    RefPtrWillBeMember<WebGLFramebuffer> m_framebufferBinding;
    RefPtrWillBeMember<WebGLRenderbuffer> m_renderbufferBinding;

    WillBeHeapVector<TextureUnitState> m_textureUnits;
    unsigned long m_activeTextureUnit;

    RefPtrWillBeMember<WebGLTexture> m_blackTexture2D;
    RefPtrWillBeMember<WebGLTexture> m_blackTextureCubeMap;

    Vector<GLenum> m_compressedTextureFormats;

    // Fixed-size cache of reusable image buffers for video texImage2D calls.
    class LRUImageBufferCache {
    public:
        LRUImageBufferCache(int capacity);
        // The pointer returned is owned by the image buffer map.
        ImageBuffer* imageBuffer(const IntSize& size);
    private:
        void bubbleToFront(int idx);
        OwnPtr<OwnPtr<ImageBuffer>[]> m_buffers;
        int m_capacity;
    };
    LRUImageBufferCache m_generatedImageCache;

    GLint m_maxTextureSize;
    GLint m_maxCubeMapTextureSize;
    GLint m_maxRenderbufferSize;
    GLint m_maxViewportDims[2];
    GLint m_maxTextureLevel;
    GLint m_maxCubeMapTextureLevel;

    GLint m_maxDrawBuffers;
    GLint m_maxColorAttachments;
    GLenum m_backDrawBuffer;
    bool m_drawBuffersWebGLRequirementsChecked;
    bool m_drawBuffersSupported;

    GLint m_packAlignment;
    GLint m_unpackAlignment;
    bool m_unpackFlipY;
    bool m_unpackPremultiplyAlpha;
    GLenum m_unpackColorspaceConversion;
    RefPtrWillBeMember<WebGLContextAttributes> m_requestedAttributes;

    bool m_layerCleared;
    GLfloat m_clearColor[4];
    bool m_scissorEnabled;
    GLfloat m_clearDepth;
    GLint m_clearStencil;
    GLboolean m_colorMask[4];
    GLboolean m_depthMask;

    bool m_stencilEnabled;
    GLuint m_stencilMask, m_stencilMaskBack;
    GLint m_stencilFuncRef, m_stencilFuncRefBack; // Note that these are the user specified values, not the internal clamped value.
    GLuint m_stencilFuncMask, m_stencilFuncMaskBack;

    bool m_isGLES2NPOTStrict;
    bool m_isDepthStencilSupported;

    bool m_synthesizedErrorsToConsole;
    int m_numGLErrorsToConsoleAllowed;

    bool m_multisamplingAllowed;
    bool m_multisamplingObserverRegistered;

    unsigned long m_onePlusMaxNonDefaultTextureUnit;

    OwnPtr<Extensions3DUtil> m_extensionsUtil;

    bool m_savingImage;

    enum ExtensionFlags {
        ApprovedExtension               = 0x00,
        // Extension that is behind the draft extensions runtime flag:
        DraftExtension                  = 0x01,
    };

    class ExtensionTracker : public NoBaseWillBeGarbageCollected<ExtensionTracker> {
    public:
        ExtensionTracker(ExtensionFlags flags, const char* const* prefixes)
            : m_draft(flags & DraftExtension)
            , m_prefixes(prefixes)
        {
        }

#if !ENABLE(OILPAN)
        virtual ~ExtensionTracker()
        {
        }
#endif

        bool draft() const
        {
            return m_draft;
        }

        const char* const* prefixes() const;
        bool matchesNameWithPrefixes(const String&) const;

        virtual PassRefPtrWillBeRawPtr<WebGLExtension> getExtension(WebGLRenderingContextBase*) = 0;
        virtual bool supported(WebGLRenderingContextBase*) const = 0;
        virtual const char* extensionName() const = 0;
        virtual void loseExtension() = 0;

        virtual void trace(Visitor*) { }

    private:
        bool m_draft;
        const char* const* m_prefixes;
    };

    template <typename T>
    class TypedExtensionTracker final : public ExtensionTracker {
    public:
        static PassOwnPtrWillBeRawPtr<TypedExtensionTracker<T> > create(RefPtrWillBeMember<T>& extensionField, ExtensionFlags flags, const char* const* prefixes)
        {
            return adoptPtrWillBeNoop(new TypedExtensionTracker<T>(extensionField, flags, prefixes));
        }

#if !ENABLE(OILPAN)
        virtual ~TypedExtensionTracker()
        {
            if (m_extension) {
                m_extension->lose(true);
                m_extension = nullptr;
            }
        }
#endif

        virtual PassRefPtrWillBeRawPtr<WebGLExtension> getExtension(WebGLRenderingContextBase* context) override
        {
            if (!m_extension) {
                m_extension = T::create(context);
                m_extensionField = m_extension;
            }

            return m_extension;
        }

        virtual bool supported(WebGLRenderingContextBase* context) const override
        {
            return T::supported(context);
        }

        virtual const char* extensionName() const override
        {
            return T::extensionName();
        }

        virtual void loseExtension() override
        {
            if (m_extension) {
                m_extension->lose(false);
                if (m_extension->isLost())
                    m_extension = nullptr;
            }
        }

        virtual void trace(Visitor* visitor) override
        {
            visitor->trace(m_extension);
            ExtensionTracker::trace(visitor);
        }

    private:
        TypedExtensionTracker(RefPtrWillBeMember<T>& extensionField, ExtensionFlags flags, const char* const* prefixes)
            : ExtensionTracker(flags, prefixes)
            , m_extensionField(extensionField)
        {
        }

        RefPtrWillBeMember<T>& m_extensionField;
        // ExtensionTracker holds it's own reference to the extension to ensure
        // that it is not deleted before this object's destructor is called
        RefPtrWillBeMember<T> m_extension;
    };

    bool m_extensionEnabled[WebGLExtensionNameCount];
    WillBeHeapVector<OwnPtrWillBeMember<ExtensionTracker> > m_extensions;

    template <typename T>
    void registerExtension(RefPtrWillBeMember<T>& extensionPtr, ExtensionFlags flags = ApprovedExtension, const char* const* prefixes = 0)
    {
        m_extensions.append(TypedExtensionTracker<T>::create(extensionPtr, flags, prefixes));
    }

    bool extensionSupportedAndAllowed(const ExtensionTracker*);

    inline bool extensionEnabled(WebGLExtensionName name)
    {
        return m_extensionEnabled[name];
    }

    // Errors raised by synthesizeGLError() while the context is lost.
    Vector<GLenum> m_lostContextErrors;

    // Helpers for getParameter and others
    WebGLGetInfo getBooleanParameter(GLenum);
    WebGLGetInfo getBooleanArrayParameter(GLenum);
    WebGLGetInfo getFloatParameter(GLenum);
    WebGLGetInfo getIntParameter(GLenum);
    WebGLGetInfo getUnsignedIntParameter(GLenum);
    WebGLGetInfo getWebGLFloatArrayParameter(GLenum);
    WebGLGetInfo getWebGLIntArrayParameter(GLenum);

    // Clear the backbuffer if it was composited since the last operation.
    // clearMask is set to the bitfield of any clear that would happen anyway at this time
    // and the function returns true if that clear is now unnecessary.
    bool clearIfComposited(GLbitfield clearMask = 0);

    // Helper to restore state that clearing the framebuffer may destroy.
    void restoreStateAfterClear();

    // Convert texture internal format.
    GLenum convertTexInternalFormat(GLenum internalformat, GLenum type);

    void texImage2DBase(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const void* pixels, ExceptionState&);
    void texImage2DImpl(GLenum target, GLint level, GLenum internalformat, GLenum format, GLenum type, Image*, WebGLImageConversion::ImageHtmlDomSource, bool flipY, bool premultiplyAlpha, ExceptionState&);
    void texSubImage2DBase(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const void* pixels, ExceptionState&);
    void texSubImage2DImpl(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLenum format, GLenum type, Image*, WebGLImageConversion::ImageHtmlDomSource, bool flipY, bool premultiplyAlpha, ExceptionState&);

    void handleTextureCompleteness(const char*, bool);
    void createFallbackBlackTextures1x1();

    // Helper function for copyTex{Sub}Image, check whether the internalformat
    // and the color buffer format of the current bound framebuffer combination
    // is valid.
    bool isTexInternalFormatColorBufferCombinationValid(GLenum texInternalFormat, GLenum colorBufferFormat);

    // Helper function to get the bound framebuffer's color buffer format.
    GLenum boundFramebufferColorFormat();

    // Helper function to verify limits on the length of uniform and attribute locations.
    bool validateLocationLength(const char* functionName, const String&);

    // Helper function to check if size is non-negative.
    // Generate GL error and return false for negative inputs; otherwise, return true.
    bool validateSize(const char* functionName, GLint x, GLint y);

    // Helper function to check if all characters in the string belong to the
    // ASCII subset as defined in GLSL ES 1.0 spec section 3.1.
    bool validateString(const char* functionName, const String&);

    // Helper function to check target and texture bound to the target.
    // Generate GL errors and return 0 if target is invalid or texture bound is
    // null.  Otherwise, return the texture bound to the target.
    WebGLTexture* validateTextureBinding(const char* functionName, GLenum target, bool useSixEnumsForCubeMap);

    // Helper function to check input format/type for functions {copy}Tex{Sub}Image.
    // Generates GL error and returns false if parameters are invalid.
    bool validateTexFuncFormatAndType(const char* functionName, GLenum format, GLenum type, GLint level);

    // Helper function to check input level for functions {copy}Tex{Sub}Image.
    // Generates GL error and returns false if level is invalid.
    bool validateTexFuncLevel(const char* functionName, GLenum target, GLint level);

    // Helper function to check if a 64-bit value is non-negative and can fit into a 32-bit integer.
    // Generates GL error and returns false if not.
    bool validateValueFitNonNegInt32(const char* functionName, const char* paramName, long long value);

    enum TexFuncValidationFunctionType {
        NotTexSubImage2D,
        TexSubImage2D,
    };

    enum TexFuncValidationSourceType {
        SourceArrayBufferView,
        SourceImageData,
        SourceHTMLImageElement,
        SourceHTMLCanvasElement,
        SourceHTMLVideoElement,
    };

    // Helper function for tex{Sub}Image2D to check if the input format/type/level/target/width/height/border/xoffset/yoffset are valid.
    // Otherwise, it would return quickly without doing other work.
    bool validateTexFunc(const char* functionName, TexFuncValidationFunctionType, TexFuncValidationSourceType, GLenum target, GLint level, GLenum internalformat, GLsizei width,
        GLsizei height, GLint border, GLenum format, GLenum type, GLint xoffset, GLint yoffset);

    // Helper function to check input width and height for functions {copy, compressed}Tex{Sub}Image.
    // Generates GL error and returns false if width or height is invalid.
    bool validateTexFuncDimensions(const char* functionName, TexFuncValidationFunctionType, GLenum target, GLint level, GLsizei width, GLsizei height);

    // Helper function to check input parameters for functions {copy}Tex{Sub}Image.
    // Generates GL error and returns false if parameters are invalid.
    bool validateTexFuncParameters(const char* functionName, TexFuncValidationFunctionType, GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type);

    enum NullDisposition {
        NullAllowed,
        NullNotAllowed
    };

    // Helper function to validate that the given ArrayBufferView
    // is of the correct type and contains enough data for the texImage call.
    // Generates GL error and returns false if parameters are invalid.
    bool validateTexFuncData(const char* functionName, GLint level, GLsizei width, GLsizei height, GLenum format, GLenum type, ArrayBufferView* pixels, NullDisposition);

    // Helper function to validate a given texture format is settable as in
    // you can supply data to texImage2D, or call texImage2D, copyTexImage2D and
    // copyTexSubImage2D.
    // Generates GL error and returns false if the format is not settable.
    bool validateSettableTexFormat(const char* functionName, GLenum format);

    // Helper function to validate compressed texture data is correct size
    // for the given format and dimensions.
    bool validateCompressedTexFuncData(const char* functionName, GLsizei width, GLsizei height, GLenum format, ArrayBufferView* pixels);

    // Helper function for validating compressed texture formats.
    bool validateCompressedTexFormat(GLenum format);

    // Helper function to validate compressed texture dimensions are valid for
    // the given format.
    bool validateCompressedTexDimensions(const char* functionName, TexFuncValidationFunctionType, GLenum target, GLint level, GLsizei width, GLsizei height, GLenum format);

    // Helper function to validate compressed texture dimensions are valid for
    // the given format.
    bool validateCompressedTexSubDimensions(const char* functionName, GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, WebGLTexture*);

    // Helper function to validate mode for draw{Arrays/Elements}.
    bool validateDrawMode(const char* functionName, GLenum);

    // Helper function to validate if front/back stencilMask and stencilFunc settings are the same.
    bool validateStencilSettings(const char* functionName);

    // Helper function to validate stencil or depth func.
    bool validateStencilOrDepthFunc(const char* functionName, GLenum);

    // Helper function for texParameterf and texParameteri.
    void texParameter(GLenum target, GLenum pname, GLfloat parami, GLint paramf, bool isFloat);

    // Helper function to print GL errors to console.
    void printGLErrorToConsole(const String&);

    // Helper function to print warnings to console. Currently
    // used only to warn about use of obsolete functions.
    void printWarningToConsole(const String&);

    // Helper function to validate input parameters for framebuffer functions.
    // Generate GL error if parameters are illegal.
    bool validateFramebufferFuncParameters(const char* functionName, GLenum target, GLenum attachment);

    // Helper function to validate blend equation mode.
    bool validateBlendEquation(const char* functionName, GLenum);

    // Helper function to validate blend func factors.
    bool validateBlendFuncFactors(const char* functionName, GLenum src, GLenum dst);

    // Helper function to validate a GL capability.
    bool validateCapability(const char* functionName, GLenum);

    // Helper function to validate input parameters for uniform functions.
    bool validateUniformParameters(const char* functionName, const WebGLUniformLocation*, Float32Array*, GLsizei mod);
    bool validateUniformParameters(const char* functionName, const WebGLUniformLocation*, Int32Array*, GLsizei mod);
    bool validateUniformParameters(const char* functionName, const WebGLUniformLocation*, void*, GLsizei, GLsizei mod);
    bool validateUniformMatrixParameters(const char* functionName, const WebGLUniformLocation*, GLboolean transpose, Float32Array*, GLsizei mod);
    bool validateUniformMatrixParameters(const char* functionName, const WebGLUniformLocation*, GLboolean transpose, void*, GLsizei, GLsizei mod);

    // Helper function to validate the target for bufferData.
    // Return the current bound buffer to target, or 0 if the target is invalid.
    WebGLBuffer* validateBufferDataTarget(const char* functionName, GLenum target);

    // Helper function for tex{Sub}Image2D to make sure image is ready and wouldn't taint Origin.
    bool validateHTMLImageElement(const char* functionName, HTMLImageElement*, ExceptionState&);

    // Helper function for tex{Sub}Image2D to make sure canvas is ready and wouldn't taint Origin.
    bool validateHTMLCanvasElement(const char* functionName, HTMLCanvasElement*, ExceptionState&);

    // Helper function for tex{Sub}Image2D to make sure video is ready wouldn't taint Origin.
    bool validateHTMLVideoElement(const char* functionName, HTMLVideoElement*, ExceptionState&);

    // Helper function to validate drawArrays(Instanced) calls
    bool validateDrawArrays(const char* functionName, GLenum mode, GLint first, GLsizei count);

    // Helper function to validate drawElements(Instanced) calls
    bool validateDrawElements(const char* functionName, GLenum mode, GLsizei count, GLenum type, long long offset);

    // Helper function to validate draw*Instanced calls
    bool validateDrawInstanced(const char* functionName, GLsizei primcount);

    // Helper functions for vertexAttribNf{v}.
    void vertexAttribfImpl(const char* functionName, GLuint index, GLsizei expectedSize, GLfloat, GLfloat, GLfloat, GLfloat);
    void vertexAttribfvImpl(const char* functionName, GLuint index, Float32Array*, GLsizei expectedSize);
    void vertexAttribfvImpl(const char* functionName, GLuint index, GLfloat*, GLsizei, GLsizei expectedSize);

    // Helper functions to bufferData() and bufferSubData().
    void bufferDataImpl(GLenum target, long long size, const void* data, GLenum usage);
    void bufferSubDataImpl(GLenum target, long long offset, GLsizeiptr size, const void* data);

    // Helper function for delete* (deleteBuffer, deleteProgram, etc) functions.
    // Return false if caller should return without further processing.
    bool deleteObject(WebGLObject*);

    // Helper function for bind* (bindBuffer, bindTexture, etc) and useProgram.
    // If the object has already been deleted, set deleted to true upon return.
    // Return false if caller should return without further processing.
    bool checkObjectToBeBound(const char* functionName, WebGLObject*, bool& deleted);

    void dispatchContextLostEvent(Timer<WebGLRenderingContextBase>*);
    // Helper for restoration after context lost.
    void maybeRestoreContext(Timer<WebGLRenderingContextBase>*);

    enum ConsoleDisplayPreference {
        DisplayInConsole,
        DontDisplayInConsole
    };

    // Wrapper for WebGraphicsContext3D::synthesizeGLError that sends a message
    // to the JavaScript console.
    void synthesizeGLError(GLenum, const char* functionName, const char* description, ConsoleDisplayPreference = DisplayInConsole);
    void emitGLWarning(const char* function, const char* reason);

    String ensureNotNull(const String&) const;

    // Enable or disable stencil test based on user setting and
    // whether the current FBO has a stencil buffer.
    void applyStencilTest();

    // Helper for enabling or disabling a capability.
    void enableOrDisable(GLenum capability, bool enable);

    // Clamp the width and height to GL_MAX_VIEWPORT_DIMS.
    IntSize clampedCanvasSize();

    // First time called, if EXT_draw_buffers is supported, query the value; otherwise return 0.
    // Later, return the cached value.
    GLint maxDrawBuffers();
    GLint maxColorAttachments();

    void setBackDrawBuffer(GLenum);

    void restoreCurrentFramebuffer();
    void restoreCurrentTexture2D();

    virtual void multisamplingChanged(bool) override;

    void findNewMaxNonDefaultTextureUnit();

    friend class WebGLStateRestorer;
    friend class WebGLRenderingContextEvictionManager;

    static Vector<WebGLRenderingContextBase*>& activeContexts();
    static Vector<WebGLRenderingContextBase*>& forciblyEvictedContexts();

    static void activateContext(WebGLRenderingContextBase*);
    static void deactivateContext(WebGLRenderingContextBase*);
    static void addToEvictedList(WebGLRenderingContextBase*);
    static void removeFromEvictedList(WebGLRenderingContextBase*);
    static void willDestroyContext(WebGLRenderingContextBase*);
    static void forciblyLoseOldestContext(const String& reason);
    // Return the least recently used context's position in the active context vector.
    // If the vector is empty, return the maximum allowed active context number.
    static size_t oldestContextIndex();
    static IntSize oldestContextSize();
};

DEFINE_TYPE_CASTS(WebGLRenderingContextBase, CanvasRenderingContext, context, context->is3d(), context.is3d());

} // namespace blink

WTF_ALLOW_MOVE_INIT_AND_COMPARE_WITH_MEM_FUNCTIONS(blink::WebGLRenderingContextBase::TextureUnitState);

#endif // WebGLRenderingContextBase_h
