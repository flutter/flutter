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
#include "core/html/canvas/WebGLRenderingContextBase.h"

#include "bindings/core/v8/ExceptionMessages.h"
#include "bindings/core/v8/ExceptionState.h"
#include "core/dom/ExceptionCode.h"
#include "core/fetch/ImageResource.h"
#include "core/frame/LocalFrame.h"
#include "core/frame/Settings.h"
#include "core/html/HTMLCanvasElement.h"
#include "core/html/HTMLImageElement.h"
#include "core/html/HTMLVideoElement.h"
#include "core/html/ImageData.h"
#include "core/html/canvas/ANGLEInstancedArrays.h"
#include "core/html/canvas/EXTBlendMinMax.h"
#include "core/html/canvas/EXTFragDepth.h"
#include "core/html/canvas/EXTShaderTextureLOD.h"
#include "core/html/canvas/EXTTextureFilterAnisotropic.h"
#include "core/html/canvas/OESElementIndexUint.h"
#include "core/html/canvas/OESStandardDerivatives.h"
#include "core/html/canvas/OESTextureFloat.h"
#include "core/html/canvas/OESTextureFloatLinear.h"
#include "core/html/canvas/OESTextureHalfFloat.h"
#include "core/html/canvas/OESTextureHalfFloatLinear.h"
#include "core/html/canvas/OESVertexArrayObject.h"
#include "core/html/canvas/WebGLActiveInfo.h"
#include "core/html/canvas/WebGLBuffer.h"
#include "core/html/canvas/WebGLCompressedTextureATC.h"
#include "core/html/canvas/WebGLCompressedTextureETC1.h"
#include "core/html/canvas/WebGLCompressedTexturePVRTC.h"
#include "core/html/canvas/WebGLCompressedTextureS3TC.h"
#include "core/html/canvas/WebGLContextAttributes.h"
#include "core/html/canvas/WebGLContextEvent.h"
#include "core/html/canvas/WebGLContextGroup.h"
#include "core/html/canvas/WebGLDebugRendererInfo.h"
#include "core/html/canvas/WebGLDebugShaders.h"
#include "core/html/canvas/WebGLDepthTexture.h"
#include "core/html/canvas/WebGLDrawBuffers.h"
#include "core/html/canvas/WebGLFramebuffer.h"
#include "core/html/canvas/WebGLLoseContext.h"
#include "core/html/canvas/WebGLProgram.h"
#include "core/html/canvas/WebGLRenderbuffer.h"
#include "core/html/canvas/WebGLShader.h"
#include "core/html/canvas/WebGLShaderPrecisionFormat.h"
#include "core/html/canvas/WebGLSharedWebGraphicsContext3D.h"
#include "core/html/canvas/WebGLTexture.h"
#include "core/html/canvas/WebGLUniformLocation.h"
#include "core/inspector/ConsoleMessage.h"
#include "core/loader/FrameLoaderClient.h"
#include "core/rendering/RenderBox.h"
#include "platform/CheckedInt.h"
#include "platform/NotImplemented.h"
#include "platform/RuntimeEnabledFeatures.h"
#include "platform/geometry/IntSize.h"
#include "platform/graphics/GraphicsContext.h"
#include "platform/graphics/UnacceleratedImageBufferSurface.h"
#include "platform/graphics/gpu/DrawingBuffer.h"
#include "public/platform/Platform.h"

#include "wtf/PassOwnPtr.h"
#include "wtf/Uint32Array.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

const double secondsBetweenRestoreAttempts = 1.0;
const int maxGLErrorsAllowedToConsole = 256;
const unsigned maxGLActiveContexts = 16;

// FIXME: Oilpan: static vectors to heap allocated WebGLRenderingContextBase objects
// are kept here. This relies on the WebGLRenderingContextBase finalization to
// explicitly retire themselves from these vectors, but it'd be preferable if
// the references were traced as per usual.
Vector<WebGLRenderingContextBase*>& WebGLRenderingContextBase::activeContexts()
{
    DEFINE_STATIC_LOCAL(Vector<WebGLRenderingContextBase*>, activeContexts, ());
    return activeContexts;
}

Vector<WebGLRenderingContextBase*>& WebGLRenderingContextBase::forciblyEvictedContexts()
{
    DEFINE_STATIC_LOCAL(Vector<WebGLRenderingContextBase*>, forciblyEvictedContexts, ());
    return forciblyEvictedContexts;
}

void WebGLRenderingContextBase::forciblyLoseOldestContext(const String& reason)
{
    size_t candidateID = oldestContextIndex();
    if (candidateID >= activeContexts().size())
        return;

    WebGLRenderingContextBase* candidate = activeContexts()[candidateID];

    // This context could belong to a dead page and the last JavaScript reference has already
    // been lost. Garbage collection might be triggered in the middle of this function, for
    // example, printWarningToConsole() causes an upcall to JavaScript.
    // Must make sure that the context is not deleted until the call stack unwinds.
    RefPtrWillBeRawPtr<WebGLRenderingContextBase> protect(candidate);

    candidate->printWarningToConsole(reason);

    // This will call deactivateContext once the context has actually been lost.
    candidate->forceLostContext(WebGLRenderingContextBase::SyntheticLostContext, WebGLRenderingContextBase::WhenAvailable);
}

size_t WebGLRenderingContextBase::oldestContextIndex()
{
    if (!activeContexts().size())
        return maxGLActiveContexts;

    WebGLRenderingContextBase* candidate = activeContexts().first();
    ASSERT(!candidate->isContextLost());
    size_t candidateID = 0;
    for (size_t ii = 1; ii < activeContexts().size(); ++ii) {
        WebGLRenderingContextBase* context = activeContexts()[ii];
        ASSERT(!context->isContextLost());
        if (context->webContext()->lastFlushID() < candidate->webContext()->lastFlushID()) {
            candidate = context;
            candidateID = ii;
        }
    }

    return candidateID;
}

IntSize WebGLRenderingContextBase::oldestContextSize()
{
    IntSize size;

    size_t candidateID = oldestContextIndex();
    if (candidateID < activeContexts().size()) {
        WebGLRenderingContextBase* candidate = activeContexts()[candidateID];
        size.setWidth(candidate->drawingBufferWidth());
        size.setHeight(candidate->drawingBufferHeight());
    }

    return size;
}

void WebGLRenderingContextBase::activateContext(WebGLRenderingContextBase* context)
{
    unsigned removedContexts = 0;
    while (activeContexts().size() >= maxGLActiveContexts && removedContexts < maxGLActiveContexts) {
        forciblyLoseOldestContext("WARNING: Too many active WebGL contexts. Oldest context will be lost.");
        removedContexts++;
    }

    ASSERT(!context->isContextLost());
    if (!activeContexts().contains(context))
        activeContexts().append(context);
}

void WebGLRenderingContextBase::deactivateContext(WebGLRenderingContextBase* context)
{
    size_t position = activeContexts().find(context);
    if (position != WTF::kNotFound)
        activeContexts().remove(position);
}

void WebGLRenderingContextBase::addToEvictedList(WebGLRenderingContextBase* context)
{
    if (!forciblyEvictedContexts().contains(context))
        forciblyEvictedContexts().append(context);
}

void WebGLRenderingContextBase::removeFromEvictedList(WebGLRenderingContextBase* context)
{
    size_t position = forciblyEvictedContexts().find(context);
    if (position != WTF::kNotFound)
        forciblyEvictedContexts().remove(position);
}

void WebGLRenderingContextBase::willDestroyContext(WebGLRenderingContextBase* context)
{
    removeFromEvictedList(context);
    deactivateContext(context);

    // Try to re-enable the oldest inactive contexts.
    while(activeContexts().size() < maxGLActiveContexts && forciblyEvictedContexts().size()) {
        WebGLRenderingContextBase* evictedContext = forciblyEvictedContexts().first();
        if (!evictedContext->m_restoreAllowed) {
            forciblyEvictedContexts().remove(0);
            continue;
        }

        IntSize desiredSize = DrawingBuffer::adjustSize(evictedContext->clampedCanvasSize(), IntSize(), evictedContext->m_maxTextureSize);

        // If there's room in the pixel budget for this context, restore it.
        if (!desiredSize.isEmpty()) {
            forciblyEvictedContexts().remove(0);
            evictedContext->forceRestoreContext();
        }
        break;
    }
}

class WebGLRenderingContextEvictionManager : public ContextEvictionManager {
public:
    void forciblyLoseOldestContext(const String& reason) {
        WebGLRenderingContextBase::forciblyLoseOldestContext(reason);
    };
    IntSize oldestContextSize() {
        return WebGLRenderingContextBase::oldestContextSize();
    };
};

namespace {

    class ScopedDrawingBufferBinder {
        STACK_ALLOCATED();
    public:
        ScopedDrawingBufferBinder(DrawingBuffer* drawingBuffer, WebGLFramebuffer* framebufferBinding)
            : m_drawingBuffer(drawingBuffer)
            , m_framebufferBinding(framebufferBinding)
        {
            // Commit DrawingBuffer if needed (e.g., for multisampling)
            if (!m_framebufferBinding && m_drawingBuffer)
                m_drawingBuffer->commit();
        }

        ~ScopedDrawingBufferBinder()
        {
            // Restore DrawingBuffer if needed
            if (!m_framebufferBinding && m_drawingBuffer)
                m_drawingBuffer->bind();
        }

    private:
        DrawingBuffer* m_drawingBuffer;
        RawPtrWillBeMember<WebGLFramebuffer> m_framebufferBinding;
    };

    Platform3DObject objectOrZero(WebGLObject* object)
    {
        return object ? object->object() : 0;
    }

    GLint clamp(GLint value, GLint min, GLint max)
    {
        if (value < min)
            value = min;
        if (value > max)
            value = max;
        return value;
    }

    // Return true if a character belongs to the ASCII subset as defined in
    // GLSL ES 1.0 spec section 3.1.
    bool validateCharacter(unsigned char c)
    {
        // Printing characters are valid except " $ ` @ \ ' DEL.
        if (c >= 32 && c <= 126
            && c != '"' && c != '$' && c != '`' && c != '@' && c != '\\' && c != '\'')
            return true;
        // Horizontal tab, line feed, vertical tab, form feed, carriage return
        // are also valid.
        if (c >= 9 && c <= 13)
            return true;
        return false;
    }

    bool isPrefixReserved(const String& name)
    {
        if (name.startsWith("gl_") || name.startsWith("webgl_") || name.startsWith("_webgl_"))
            return true;
        return false;
    }

    // Strips comments from shader text. This allows non-ASCII characters
    // to be used in comments without potentially breaking OpenGL
    // implementations not expecting characters outside the GLSL ES set.
    class StripComments {
    public:
        StripComments(const String& str)
            : m_parseState(BeginningOfLine)
            , m_sourceString(str)
            , m_length(str.length())
            , m_position(0)
        {
            parse();
        }

        String result()
        {
            return m_builder.toString();
        }

    private:
        bool hasMoreCharacters() const
        {
            return (m_position < m_length);
        }

        void parse()
        {
            while (hasMoreCharacters()) {
                process(current());
                // process() might advance the position.
                if (hasMoreCharacters())
                    advance();
            }
        }

        void process(UChar);

        bool peek(UChar& character) const
        {
            if (m_position + 1 >= m_length)
                return false;
            character = m_sourceString[m_position + 1];
            return true;
        }

        UChar current()
        {
            ASSERT_WITH_SECURITY_IMPLICATION(m_position < m_length);
            return m_sourceString[m_position];
        }

        void advance()
        {
            ++m_position;
        }

        static bool isNewline(UChar character)
        {
            // Don't attempt to canonicalize newline related characters.
            return (character == '\n' || character == '\r');
        }

        void emit(UChar character)
        {
            m_builder.append(character);
        }

        enum ParseState {
            // Have not seen an ASCII non-whitespace character yet on
            // this line. Possible that we might see a preprocessor
            // directive.
            BeginningOfLine,

            // Have seen at least one ASCII non-whitespace character
            // on this line.
            MiddleOfLine,

            // Handling a preprocessor directive. Passes through all
            // characters up to the end of the line. Disables comment
            // processing.
            InPreprocessorDirective,

            // Handling a single-line comment. The comment text is
            // replaced with a single space.
            InSingleLineComment,

            // Handling a multi-line comment. Newlines are passed
            // through to preserve line numbers.
            InMultiLineComment
        };

        ParseState m_parseState;
        String m_sourceString;
        unsigned m_length;
        unsigned m_position;
        StringBuilder m_builder;
    };

    void StripComments::process(UChar c)
    {
        if (isNewline(c)) {
            // No matter what state we are in, pass through newlines
            // so we preserve line numbers.
            emit(c);

            if (m_parseState != InMultiLineComment)
                m_parseState = BeginningOfLine;

            return;
        }

        UChar temp = 0;
        switch (m_parseState) {
        case BeginningOfLine:
            if (WTF::isASCIISpace(c)) {
                emit(c);
                break;
            }

            if (c == '#') {
                m_parseState = InPreprocessorDirective;
                emit(c);
                break;
            }

            // Transition to normal state and re-handle character.
            m_parseState = MiddleOfLine;
            process(c);
            break;

        case MiddleOfLine:
            if (c == '/' && peek(temp)) {
                if (temp == '/') {
                    m_parseState = InSingleLineComment;
                    emit(' ');
                    advance();
                    break;
                }

                if (temp == '*') {
                    m_parseState = InMultiLineComment;
                    // Emit the comment start in case the user has
                    // an unclosed comment and we want to later
                    // signal an error.
                    emit('/');
                    emit('*');
                    advance();
                    break;
                }
            }

            emit(c);
            break;

        case InPreprocessorDirective:
            // No matter what the character is, just pass it
            // through. Do not parse comments in this state. This
            // might not be the right thing to do long term, but it
            // should handle the #error preprocessor directive.
            emit(c);
            break;

        case InSingleLineComment:
            // The newline code at the top of this function takes care
            // of resetting our state when we get out of the
            // single-line comment. Swallow all other characters.
            break;

        case InMultiLineComment:
            if (c == '*' && peek(temp) && temp == '/') {
                emit('*');
                emit('/');
                m_parseState = MiddleOfLine;
                advance();
                break;
            }

            // Swallow all other characters. Unclear whether we may
            // want or need to just emit a space per character to try
            // to preserve column numbers for debugging purposes.
            break;
        }
    }
} // namespace anonymous

class ScopedTexture2DRestorer {
    STACK_ALLOCATED();
public:
    explicit ScopedTexture2DRestorer(WebGLRenderingContextBase* context)
        : m_context(context)
    {
    }

    ~ScopedTexture2DRestorer()
    {
        m_context->restoreCurrentTexture2D();
    }

private:
    RawPtrWillBeMember<WebGLRenderingContextBase> m_context;
};

class WebGLRenderingContextLostCallback final : public NoBaseWillBeGarbageCollectedFinalized<WebGLRenderingContextLostCallback>, public blink::WebGraphicsContext3D::WebGraphicsContextLostCallback {
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
public:
    static PassOwnPtrWillBeRawPtr<WebGLRenderingContextLostCallback> create(WebGLRenderingContextBase* context)
    {
        return adoptPtrWillBeNoop(new WebGLRenderingContextLostCallback(context));
    }

    virtual ~WebGLRenderingContextLostCallback() { }

    virtual void onContextLost() { m_context->forceLostContext(WebGLRenderingContextBase::RealLostContext, WebGLRenderingContextBase::Auto); }

    void trace(Visitor* visitor)
    {
        visitor->trace(m_context);
    }

private:
    explicit WebGLRenderingContextLostCallback(WebGLRenderingContextBase* context)
        : m_context(context) { }

    RawPtrWillBeMember<WebGLRenderingContextBase> m_context;
};

class WebGLRenderingContextErrorMessageCallback final : public NoBaseWillBeGarbageCollectedFinalized<WebGLRenderingContextErrorMessageCallback>, public blink::WebGraphicsContext3D::WebGraphicsErrorMessageCallback {
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
public:
    static PassOwnPtrWillBeRawPtr<WebGLRenderingContextErrorMessageCallback> create(WebGLRenderingContextBase* context)
    {
        return adoptPtrWillBeNoop(new WebGLRenderingContextErrorMessageCallback(context));
    }

    virtual ~WebGLRenderingContextErrorMessageCallback() { }

    virtual void onErrorMessage(const blink::WebString& message, blink::WGC3Dint)
    {
        if (m_context->m_synthesizedErrorsToConsole)
            m_context->printGLErrorToConsole(message);
    }

    void trace(Visitor* visitor)
    {
        visitor->trace(m_context);
    }

private:
    explicit WebGLRenderingContextErrorMessageCallback(WebGLRenderingContextBase* context)
        : m_context(context) { }

    RawPtrWillBeMember<WebGLRenderingContextBase> m_context;
};

WebGLRenderingContextBase::WebGLRenderingContextBase(HTMLCanvasElement* passedCanvas, PassOwnPtr<blink::WebGraphicsContext3D> context, WebGLContextAttributes* requestedAttributes)
    : CanvasRenderingContext(passedCanvas)
    , ActiveDOMObject(&passedCanvas->document())
    , m_contextLostMode(NotLostContext)
    , m_autoRecoveryMethod(Manual)
    , m_dispatchContextLostEventTimer(this, &WebGLRenderingContextBase::dispatchContextLostEvent)
    , m_restoreAllowed(false)
    , m_restoreTimer(this, &WebGLRenderingContextBase::maybeRestoreContext)
    , m_generatedImageCache(4)
    , m_requestedAttributes(requestedAttributes->clone())
    , m_synthesizedErrorsToConsole(true)
    , m_numGLErrorsToConsoleAllowed(maxGLErrorsAllowedToConsole)
    , m_multisamplingAllowed(false)
    , m_multisamplingObserverRegistered(false)
    , m_onePlusMaxNonDefaultTextureUnit(0)
    , m_savingImage(false)
{
    ASSERT(context);

    m_contextGroup = WebGLContextGroup::create();
    m_contextGroup->addContext(this);

    m_maxViewportDims[0] = m_maxViewportDims[1] = 0;
    context->getIntegerv(GL_MAX_VIEWPORT_DIMS, m_maxViewportDims);

    RefPtr<DrawingBuffer> buffer = createDrawingBuffer(context);
    if (!buffer)
        return;

#if ENABLE(OILPAN)
    m_sharedWebGraphicsContext3D = WebGLSharedWebGraphicsContext3D::create(buffer.release());
#else
    m_drawingBuffer = buffer.release();
#endif

    drawingBuffer()->bind();
    setupFlags();
    initializeNewContext();
}

PassRefPtr<DrawingBuffer> WebGLRenderingContextBase::createDrawingBuffer(PassOwnPtr<blink::WebGraphicsContext3D> context)
{
    RefPtr<WebGLRenderingContextEvictionManager> contextEvictionManager = adoptRef(new WebGLRenderingContextEvictionManager());

    blink::WebGraphicsContext3D::Attributes attrs;
    attrs.alpha = m_requestedAttributes->alpha();
    attrs.depth = m_requestedAttributes->depth();
    attrs.stencil = m_requestedAttributes->stencil();
    attrs.antialias = m_requestedAttributes->antialias();
    attrs.premultipliedAlpha = m_requestedAttributes->premultipliedAlpha();
    DrawingBuffer::PreserveDrawingBuffer preserve = m_requestedAttributes->preserveDrawingBuffer() ? DrawingBuffer::Preserve : DrawingBuffer::Discard;
    return DrawingBuffer::create(context, clampedCanvasSize(), preserve, attrs, contextEvictionManager.release());
}

void WebGLRenderingContextBase::initializeNewContext()
{
    ASSERT(!isContextLost());
    m_needsUpdate = true;
    m_markedCanvasDirty = false;
    m_activeTextureUnit = 0;
    m_packAlignment = 4;
    m_unpackAlignment = 4;
    m_unpackFlipY = false;
    m_unpackPremultiplyAlpha = false;
    m_unpackColorspaceConversion = GC3D_BROWSER_DEFAULT_WEBGL;
    m_boundArrayBuffer = nullptr;
    m_currentProgram = nullptr;
    m_framebufferBinding = nullptr;
    m_renderbufferBinding = nullptr;
    m_depthMask = true;
    m_stencilEnabled = false;
    m_stencilMask = 0xFFFFFFFF;
    m_stencilMaskBack = 0xFFFFFFFF;
    m_stencilFuncRef = 0;
    m_stencilFuncRefBack = 0;
    m_stencilFuncMask = 0xFFFFFFFF;
    m_stencilFuncMaskBack = 0xFFFFFFFF;
    m_layerCleared = false;
    m_numGLErrorsToConsoleAllowed = maxGLErrorsAllowedToConsole;

    m_clearColor[0] = m_clearColor[1] = m_clearColor[2] = m_clearColor[3] = 0;
    m_scissorEnabled = false;
    m_clearDepth = 1;
    m_clearStencil = 0;
    m_colorMask[0] = m_colorMask[1] = m_colorMask[2] = m_colorMask[3] = true;

    GLint numCombinedTextureImageUnits = 0;
    webContext()->getIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, &numCombinedTextureImageUnits);
    m_textureUnits.clear();
    m_textureUnits.resize(numCombinedTextureImageUnits);

    GLint numVertexAttribs = 0;
    webContext()->getIntegerv(GL_MAX_VERTEX_ATTRIBS, &numVertexAttribs);
    m_maxVertexAttribs = numVertexAttribs;

    m_maxTextureSize = 0;
    webContext()->getIntegerv(GL_MAX_TEXTURE_SIZE, &m_maxTextureSize);
    m_maxTextureLevel = WebGLTexture::computeLevelCount(m_maxTextureSize, m_maxTextureSize);
    m_maxCubeMapTextureSize = 0;
    webContext()->getIntegerv(GL_MAX_CUBE_MAP_TEXTURE_SIZE, &m_maxCubeMapTextureSize);
    m_maxCubeMapTextureLevel = WebGLTexture::computeLevelCount(m_maxCubeMapTextureSize, m_maxCubeMapTextureSize);
    m_maxRenderbufferSize = 0;
    webContext()->getIntegerv(GL_MAX_RENDERBUFFER_SIZE, &m_maxRenderbufferSize);

    // These two values from EXT_draw_buffers are lazily queried.
    m_maxDrawBuffers = 0;
    m_maxColorAttachments = 0;

    m_backDrawBuffer = GL_BACK;

    m_defaultVertexArrayObject = WebGLVertexArrayObjectOES::create(this, WebGLVertexArrayObjectOES::VaoTypeDefault);
    addContextObject(m_defaultVertexArrayObject.get());
    m_boundVertexArrayObject = m_defaultVertexArrayObject;

    m_vertexAttribValue.resize(m_maxVertexAttribs);

    createFallbackBlackTextures1x1();

    webContext()->viewport(0, 0, drawingBufferWidth(), drawingBufferHeight());
    webContext()->scissor(0, 0, drawingBufferWidth(), drawingBufferHeight());

    m_contextLostCallbackAdapter = WebGLRenderingContextLostCallback::create(this);
    m_errorMessageCallbackAdapter = WebGLRenderingContextErrorMessageCallback::create(this);

    webContext()->setContextLostCallback(m_contextLostCallbackAdapter.get());
    webContext()->setErrorMessageCallback(m_errorMessageCallbackAdapter.get());

    // This ensures that the context has a valid "lastFlushID" and won't be mistakenly identified as the "least recently used" context.
    webContext()->flush();

    for (int i = 0; i < WebGLExtensionNameCount; ++i)
        m_extensionEnabled[i] = false;

    activateContext(this);
}

void WebGLRenderingContextBase::setupFlags()
{
    ASSERT(drawingBuffer());
    if (Page* p = canvas()->document().page()) {
        m_synthesizedErrorsToConsole = p->settings().webGLErrorsToConsoleEnabled();

        if (!m_multisamplingObserverRegistered && m_requestedAttributes->antialias()) {
            m_multisamplingAllowed = drawingBuffer()->multisample();
            p->addMultisamplingChangedObserver(this);
            m_multisamplingObserverRegistered = true;
        }
    }

    m_isGLES2NPOTStrict = !extensionsUtil()->isExtensionEnabled("GL_OES_texture_npot");
    m_isDepthStencilSupported = extensionsUtil()->isExtensionEnabled("GL_OES_packed_depth_stencil");
}

void WebGLRenderingContextBase::addCompressedTextureFormat(GLenum format)
{
    if (!m_compressedTextureFormats.contains(format))
        m_compressedTextureFormats.append(format);
}

void WebGLRenderingContextBase::removeAllCompressedTextureFormats()
{
    m_compressedTextureFormats.clear();
}

// Helper function for V8 bindings to identify what version of WebGL a CanvasRenderingContext supports.
unsigned WebGLRenderingContextBase::getWebGLVersion(const CanvasRenderingContext* context)
{
    if (!context->is3d())
        return 0;
    return static_cast<const WebGLRenderingContextBase*>(context)->version();
}

WebGLRenderingContextBase::~WebGLRenderingContextBase()
{
#if !ENABLE(OILPAN)
    // Remove all references to WebGLObjects so if they are the last reference
    // they will be freed before the last context is removed from the context group.
    m_boundArrayBuffer = nullptr;
    m_defaultVertexArrayObject = nullptr;
    m_boundVertexArrayObject = nullptr;
    m_vertexAttrib0Buffer = nullptr;
    m_currentProgram = nullptr;
    m_framebufferBinding = nullptr;
    m_renderbufferBinding = nullptr;

    for (size_t i = 0; i < m_textureUnits.size(); ++i) {
        m_textureUnits[i].m_texture2DBinding = nullptr;
        m_textureUnits[i].m_textureCubeMapBinding = nullptr;
    }

    m_blackTexture2D = nullptr;
    m_blackTextureCubeMap = nullptr;

    detachAndRemoveAllObjects();

    // Release all extensions now.
    m_extensions.clear();
#endif

    // Context must be removed from the group prior to the destruction of the
    // WebGraphicsContext3D, otherwise shared objects may not be properly deleted.
    m_contextGroup->removeContext(this);

    destroyContext();

#if !ENABLE(OILPAN)
    if (m_multisamplingObserverRegistered)
        if (Page* page = canvas()->document().page())
            page->removeMultisamplingChangedObserver(this);
#endif

    willDestroyContext(this);
}

void WebGLRenderingContextBase::destroyContext()
{
    if (!drawingBuffer())
        return;

    m_extensionsUtil.clear();

    webContext()->setContextLostCallback(0);
    webContext()->setErrorMessageCallback(0);

    ASSERT(drawingBuffer());
#if ENABLE(OILPAN)
    // The DrawingBuffer ref pointers are cleared, but the
    // WebGLSharedWebGraphicsContext3D object will hold onto the
    // DrawingBuffer for as long as needed (== until all
    // context objects have been finalized), at which point
    // DrawingBuffer destruction happens.
    m_sharedWebGraphicsContext3D.clear();
#else
    m_drawingBuffer->beginDestruction();
    m_drawingBuffer.clear();
#endif
}

void WebGLRenderingContextBase::markContextChanged(ContentChangeType changeType)
{
    if (m_framebufferBinding || isContextLost())
        return;

    drawingBuffer()->markContentsChanged();

    m_layerCleared = false;
    RenderBox* renderBox = canvas()->renderBox();
    if (renderBox && renderBox->hasAcceleratedCompositing()) {
        m_markedCanvasDirty = true;
        canvas()->clearCopiedImage();
        renderBox->contentChanged(changeType);
    } else {
        if (!m_markedCanvasDirty) {
            m_markedCanvasDirty = true;
            canvas()->didDraw(FloatRect(FloatPoint(0, 0), clampedCanvasSize()));
        }
    }
}

bool WebGLRenderingContextBase::clearIfComposited(GLbitfield mask)
{
    if (isContextLost())
        return false;

    if (!drawingBuffer()->layerComposited() || m_layerCleared
        || m_requestedAttributes->preserveDrawingBuffer() || (mask && m_framebufferBinding))
        return false;

    RefPtrWillBeRawPtr<WebGLContextAttributes> contextAttributes = getContextAttributes();

    // Determine if it's possible to combine the clear the user asked for and this clear.
    bool combinedClear = mask && !m_scissorEnabled;

    webContext()->disable(GL_SCISSOR_TEST);
    if (combinedClear && (mask & GL_COLOR_BUFFER_BIT)) {
        webContext()->clearColor(m_colorMask[0] ? m_clearColor[0] : 0,
            m_colorMask[1] ? m_clearColor[1] : 0,
            m_colorMask[2] ? m_clearColor[2] : 0,
            m_colorMask[3] ? m_clearColor[3] : 0);
    } else {
        webContext()->clearColor(0, 0, 0, 0);
    }
    webContext()->colorMask(true, true, true, true);
    GLbitfield clearMask = GL_COLOR_BUFFER_BIT;
    if (contextAttributes->depth()) {
        if (!combinedClear || !m_depthMask || !(mask & GL_DEPTH_BUFFER_BIT))
            webContext()->clearDepth(1.0f);
        clearMask |= GL_DEPTH_BUFFER_BIT;
        webContext()->depthMask(true);
    }
    if (contextAttributes->stencil()) {
        if (combinedClear && (mask & GL_STENCIL_BUFFER_BIT))
            webContext()->clearStencil(m_clearStencil & m_stencilMask);
        else
            webContext()->clearStencil(0);
        clearMask |= GL_STENCIL_BUFFER_BIT;
        webContext()->stencilMaskSeparate(GL_FRONT, 0xFFFFFFFF);
    }

    drawingBuffer()->clearFramebuffers(clearMask);

    restoreStateAfterClear();
    if (m_framebufferBinding)
        webContext()->bindFramebuffer(GL_FRAMEBUFFER, objectOrZero(m_framebufferBinding.get()));
    m_layerCleared = true;

    return combinedClear;
}

void WebGLRenderingContextBase::restoreStateAfterClear()
{
    if (isContextLost())
        return;

    // Restore the state that the context set.
    if (m_scissorEnabled)
        webContext()->enable(GL_SCISSOR_TEST);
    webContext()->clearColor(m_clearColor[0], m_clearColor[1],
        m_clearColor[2], m_clearColor[3]);
    webContext()->colorMask(m_colorMask[0], m_colorMask[1],
        m_colorMask[2], m_colorMask[3]);
    webContext()->clearDepth(m_clearDepth);
    webContext()->clearStencil(m_clearStencil);
    webContext()->stencilMaskSeparate(GL_FRONT, m_stencilMask);
    webContext()->depthMask(m_depthMask);
}

void WebGLRenderingContextBase::markLayerComposited()
{
    if (!isContextLost())
        drawingBuffer()->markLayerComposited();
}

void WebGLRenderingContextBase::setIsHidden(bool hidden)
{
    if (!isContextLost())
        drawingBuffer()->setIsHidden(hidden);
}

void WebGLRenderingContextBase::paintRenderingResultsToCanvas()
{
    if (isContextLost()) {
        canvas()->clearPresentationCopy();
        return;
    }

    // Until the canvas is written to by the application, the clear that
    // happened after it was composited should be ignored by the compositor.
    if (drawingBuffer()->layerComposited() && !m_requestedAttributes->preserveDrawingBuffer()) {
        drawingBuffer()->paintCompositedResultsToCanvas(canvas()->buffer());

        canvas()->makePresentationCopy();
    } else
        canvas()->clearPresentationCopy();

    clearIfComposited();

    if (!m_markedCanvasDirty && !m_layerCleared)
        return;

    canvas()->clearCopiedImage();
    m_markedCanvasDirty = false;

    ScopedTexture2DRestorer restorer(this);

    drawingBuffer()->commit();
    if (!(canvas()->buffer())->copyRenderingResultsFromDrawingBuffer(drawingBuffer(), m_savingImage)) {
        canvas()->ensureUnacceleratedImageBuffer();
        if (canvas()->hasImageBuffer())
            drawingBuffer()->paintRenderingResultsToCanvas(canvas()->buffer());
    }

    if (m_framebufferBinding)
        webContext()->bindFramebuffer(GL_FRAMEBUFFER, objectOrZero(m_framebufferBinding.get()));
    else
        drawingBuffer()->bind();
}

PassRefPtrWillBeRawPtr<ImageData> WebGLRenderingContextBase::paintRenderingResultsToImageData()
{
    if (isContextLost())
        return nullptr;

    clearIfComposited();
    drawingBuffer()->commit();
    int width, height;
    RefPtr<Uint8ClampedArray> imageDataPixels = drawingBuffer()->paintRenderingResultsToImageData(width, height);
    if (!imageDataPixels)
        return nullptr;

    if (m_framebufferBinding)
        webContext()->bindFramebuffer(GL_FRAMEBUFFER, objectOrZero(m_framebufferBinding.get()));
    else
        drawingBuffer()->bind();

    return ImageData::create(IntSize(width, height), imageDataPixels);
}

void WebGLRenderingContextBase::reshape(int width, int height)
{
    if (isContextLost())
        return;

    // This is an approximation because at WebGLRenderingContextBase level we don't
    // know if the underlying FBO uses textures or renderbuffers.
    GLint maxSize = std::min(m_maxTextureSize, m_maxRenderbufferSize);
    // Limit drawing buffer size to 4k to avoid memory exhaustion.
    const int sizeUpperLimit = 4096;
    maxSize = std::min(maxSize, sizeUpperLimit);
    GLint maxWidth = std::min(maxSize, m_maxViewportDims[0]);
    GLint maxHeight = std::min(maxSize, m_maxViewportDims[1]);
    width = clamp(width, 1, maxWidth);
    height = clamp(height, 1, maxHeight);

    if (m_needsUpdate) {
        RenderBox* renderBox = canvas()->renderBox();
        if (renderBox && renderBox->hasAcceleratedCompositing())
            renderBox->contentChanged(CanvasChanged);
        m_needsUpdate = false;
    }

    // We don't have to mark the canvas as dirty, since the newly created image buffer will also start off
    // clear (and this matches what reshape will do).
    drawingBuffer()->reset(IntSize(width, height));
    restoreStateAfterClear();

    webContext()->bindTexture(GL_TEXTURE_2D, objectOrZero(m_textureUnits[m_activeTextureUnit].m_texture2DBinding.get()));
    webContext()->bindRenderbuffer(GL_RENDERBUFFER, objectOrZero(m_renderbufferBinding.get()));
    if (m_framebufferBinding)
        webContext()->bindFramebuffer(GL_FRAMEBUFFER, objectOrZero(m_framebufferBinding.get()));
}

int WebGLRenderingContextBase::drawingBufferWidth() const
{
    return isContextLost() ? 0 : drawingBuffer()->size().width();
}

int WebGLRenderingContextBase::drawingBufferHeight() const
{
    return isContextLost() ? 0 : drawingBuffer()->size().height();
}

unsigned WebGLRenderingContextBase::sizeInBytes(GLenum type)
{
    switch (type) {
    case GL_BYTE:
        return sizeof(GLbyte);
    case GL_UNSIGNED_BYTE:
        return sizeof(GLubyte);
    case GL_SHORT:
        return sizeof(GLshort);
    case GL_UNSIGNED_SHORT:
        return sizeof(GLushort);
    case GL_INT:
        return sizeof(GLint);
    case GL_UNSIGNED_INT:
        return sizeof(GLuint);
    case GL_FLOAT:
        return sizeof(GLfloat);
    }
    ASSERT_NOT_REACHED();
    return 0;
}

void WebGLRenderingContextBase::activeTexture(GLenum texture)
{
    if (isContextLost())
        return;
    if (texture - GL_TEXTURE0 >= m_textureUnits.size()) {
        synthesizeGLError(GL_INVALID_ENUM, "activeTexture", "texture unit out of range");
        return;
    }
    m_activeTextureUnit = texture - GL_TEXTURE0;
    webContext()->activeTexture(texture);

    drawingBuffer()->setActiveTextureUnit(texture);

}

void WebGLRenderingContextBase::attachShader(WebGLProgram* program, WebGLShader* shader)
{
    if (isContextLost() || !validateWebGLObject("attachShader", program) || !validateWebGLObject("attachShader", shader))
        return;
    if (!program->attachShader(shader)) {
        synthesizeGLError(GL_INVALID_OPERATION, "attachShader", "shader attachment already has shader");
        return;
    }
    webContext()->attachShader(objectOrZero(program), objectOrZero(shader));
    shader->onAttached();
}

void WebGLRenderingContextBase::bindAttribLocation(WebGLProgram* program, GLuint index, const String& name)
{
    if (isContextLost() || !validateWebGLObject("bindAttribLocation", program))
        return;
    if (!validateLocationLength("bindAttribLocation", name))
        return;
    if (!validateString("bindAttribLocation", name))
        return;
    if (isPrefixReserved(name)) {
        synthesizeGLError(GL_INVALID_OPERATION, "bindAttribLocation", "reserved prefix");
        return;
    }
    if (index >= m_maxVertexAttribs) {
        synthesizeGLError(GL_INVALID_VALUE, "bindAttribLocation", "index out of range");
        return;
    }
    webContext()->bindAttribLocation(objectOrZero(program), index, name.utf8().data());
}

bool WebGLRenderingContextBase::checkObjectToBeBound(const char* functionName, WebGLObject* object, bool& deleted)
{
    deleted = false;
    if (isContextLost())
        return false;
    if (object) {
        if (!object->validate(contextGroup(), this)) {
            synthesizeGLError(GL_INVALID_OPERATION, functionName, "object not from this context");
            return false;
        }
        deleted = !object->object();
    }
    return true;
}

void WebGLRenderingContextBase::bindBuffer(GLenum target, WebGLBuffer* buffer)
{
    bool deleted;
    if (!checkObjectToBeBound("bindBuffer", buffer, deleted))
        return;
    if (deleted)
        buffer = 0;
    if (buffer && buffer->getTarget() && buffer->getTarget() != target) {
        synthesizeGLError(GL_INVALID_OPERATION, "bindBuffer", "buffers can not be used with multiple targets");
        return;
    }
    if (target == GL_ARRAY_BUFFER)
        m_boundArrayBuffer = buffer;
    else if (target == GL_ELEMENT_ARRAY_BUFFER)
        m_boundVertexArrayObject->setElementArrayBuffer(buffer);
    else {
        synthesizeGLError(GL_INVALID_ENUM, "bindBuffer", "invalid target");
        return;
    }

    webContext()->bindBuffer(target, objectOrZero(buffer));
    if (buffer)
        buffer->setTarget(target);
}

void WebGLRenderingContextBase::bindFramebuffer(GLenum target, WebGLFramebuffer* buffer)
{
    bool deleted;
    if (!checkObjectToBeBound("bindFramebuffer", buffer, deleted))
        return;
    if (deleted)
        buffer = 0;
    if (target != GL_FRAMEBUFFER) {
        synthesizeGLError(GL_INVALID_ENUM, "bindFramebuffer", "invalid target");
        return;
    }
    m_framebufferBinding = buffer;
    drawingBuffer()->setFramebufferBinding(objectOrZero(m_framebufferBinding.get()));
    if (!m_framebufferBinding) {
        // Instead of binding fb 0, bind the drawing buffer.
        drawingBuffer()->bind();
    } else {
        webContext()->bindFramebuffer(target, objectOrZero(buffer));
    }
    if (buffer)
        buffer->setHasEverBeenBound();
    applyStencilTest();
}

void WebGLRenderingContextBase::bindRenderbuffer(GLenum target, WebGLRenderbuffer* renderBuffer)
{
    bool deleted;
    if (!checkObjectToBeBound("bindRenderbuffer", renderBuffer, deleted))
        return;
    if (deleted)
        renderBuffer = 0;
    if (target != GL_RENDERBUFFER) {
        synthesizeGLError(GL_INVALID_ENUM, "bindRenderbuffer", "invalid target");
        return;
    }
    m_renderbufferBinding = renderBuffer;
    webContext()->bindRenderbuffer(target, objectOrZero(renderBuffer));
    if (renderBuffer)
        renderBuffer->setHasEverBeenBound();
}

void WebGLRenderingContextBase::bindTexture(GLenum target, WebGLTexture* texture)
{
    bool deleted;
    if (!checkObjectToBeBound("bindTexture", texture, deleted))
        return;
    if (deleted)
        texture = 0;
    if (texture && texture->getTarget() && texture->getTarget() != target) {
        synthesizeGLError(GL_INVALID_OPERATION, "bindTexture", "textures can not be used with multiple targets");
        return;
    }
    GLint maxLevel = 0;
    if (target == GL_TEXTURE_2D) {
        m_textureUnits[m_activeTextureUnit].m_texture2DBinding = texture;
        maxLevel = m_maxTextureLevel;

        if (!m_activeTextureUnit)
            drawingBuffer()->setTexture2DBinding(objectOrZero(texture));

    } else if (target == GL_TEXTURE_CUBE_MAP) {
        m_textureUnits[m_activeTextureUnit].m_textureCubeMapBinding = texture;
        maxLevel = m_maxCubeMapTextureLevel;
    } else {
        synthesizeGLError(GL_INVALID_ENUM, "bindTexture", "invalid target");
        return;
    }

    webContext()->bindTexture(target, objectOrZero(texture));
    if (texture) {
        texture->setTarget(target, maxLevel);
        m_onePlusMaxNonDefaultTextureUnit = max(m_activeTextureUnit + 1, m_onePlusMaxNonDefaultTextureUnit);
    } else {
        // If the disabled index is the current maximum, trace backwards to find the new max enabled texture index
        if (m_onePlusMaxNonDefaultTextureUnit == m_activeTextureUnit + 1) {
            findNewMaxNonDefaultTextureUnit();
        }
    }

    // Note: previously we used to automatically set the TEXTURE_WRAP_R
    // repeat mode to CLAMP_TO_EDGE for cube map textures, because OpenGL
    // ES 2.0 doesn't expose this flag (a bug in the specification) and
    // otherwise the application has no control over the seams in this
    // dimension. However, it appears that supporting this properly on all
    // platforms is fairly involved (will require a HashMap from texture ID
    // in all ports), and we have not had any complaints, so the logic has
    // been removed.

}

void WebGLRenderingContextBase::blendColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha)
{
    if (isContextLost())
        return;
    webContext()->blendColor(red, green, blue, alpha);
}

void WebGLRenderingContextBase::blendEquation(GLenum mode)
{
    if (isContextLost() || !validateBlendEquation("blendEquation", mode))
        return;
    webContext()->blendEquation(mode);
}

void WebGLRenderingContextBase::blendEquationSeparate(GLenum modeRGB, GLenum modeAlpha)
{
    if (isContextLost() || !validateBlendEquation("blendEquationSeparate", modeRGB) || !validateBlendEquation("blendEquationSeparate", modeAlpha))
        return;
    webContext()->blendEquationSeparate(modeRGB, modeAlpha);
}


void WebGLRenderingContextBase::blendFunc(GLenum sfactor, GLenum dfactor)
{
    if (isContextLost() || !validateBlendFuncFactors("blendFunc", sfactor, dfactor))
        return;
    webContext()->blendFunc(sfactor, dfactor);
}

void WebGLRenderingContextBase::blendFuncSeparate(GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha)
{
    // Note: Alpha does not have the same restrictions as RGB.
    if (isContextLost() || !validateBlendFuncFactors("blendFuncSeparate", srcRGB, dstRGB))
        return;
    webContext()->blendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
}

void WebGLRenderingContextBase::bufferDataImpl(GLenum target, long long size, const void* data, GLenum usage)
{
    WebGLBuffer* buffer = validateBufferDataTarget("bufferData", target);
    if (!buffer)
        return;

    switch (usage) {
    case GL_STREAM_DRAW:
    case GL_STATIC_DRAW:
    case GL_DYNAMIC_DRAW:
        break;
    default:
        synthesizeGLError(GL_INVALID_ENUM, "bufferData", "invalid usage");
        return;
    }

    if (!validateValueFitNonNegInt32("bufferData", "size", size))
        return;

    webContext()->bufferData(target, static_cast<GLsizeiptr>(size), data, usage);
}

void WebGLRenderingContextBase::bufferData(GLenum target, long long size, GLenum usage)
{
    if (isContextLost())
        return;
    if (!size) {
        synthesizeGLError(GL_INVALID_VALUE, "bufferData", "size == 0");
        return;
    }
    bufferDataImpl(target, size, 0, usage);
}

void WebGLRenderingContextBase::bufferData(GLenum target, ArrayBuffer* data, GLenum usage)
{
    if (isContextLost())
        return;
    if (!data) {
        synthesizeGLError(GL_INVALID_VALUE, "bufferData", "no data");
        return;
    }
    bufferDataImpl(target, data->byteLength(), data->data(), usage);
}

void WebGLRenderingContextBase::bufferData(GLenum target, ArrayBufferView* data, GLenum usage)
{
    if (isContextLost())
        return;
    if (!data) {
        synthesizeGLError(GL_INVALID_VALUE, "bufferData", "no data");
        return;
    }
    bufferDataImpl(target, data->byteLength(), data->baseAddress(), usage);
}

void WebGLRenderingContextBase::bufferSubDataImpl(GLenum target, long long offset, GLsizeiptr size, const void* data)
{
    WebGLBuffer* buffer = validateBufferDataTarget("bufferSubData", target);
    if (!buffer)
        return;
    if (!validateValueFitNonNegInt32("bufferSubData", "offset", offset))
        return;
    if (!data)
        return;

    webContext()->bufferSubData(target, static_cast<GLintptr>(offset), size, data);
}

void WebGLRenderingContextBase::bufferSubData(GLenum target, long long offset, ArrayBuffer* data)
{
    if (isContextLost())
        return;
    if (!data)
        return;
    bufferSubDataImpl(target, offset, data->byteLength(), data->data());
}

void WebGLRenderingContextBase::bufferSubData(GLenum target, long long offset, ArrayBufferView* data)
{
    if (isContextLost())
        return;
    if (!data)
        return;
    bufferSubDataImpl(target, offset, data->byteLength(), data->baseAddress());
}

GLenum WebGLRenderingContextBase::checkFramebufferStatus(GLenum target)
{
    if (isContextLost())
        return GL_FRAMEBUFFER_UNSUPPORTED;
    if (target != GL_FRAMEBUFFER) {
        synthesizeGLError(GL_INVALID_ENUM, "checkFramebufferStatus", "invalid target");
        return 0;
    }
    if (!m_framebufferBinding || !m_framebufferBinding->object())
        return GL_FRAMEBUFFER_COMPLETE;
    const char* reason = "framebuffer incomplete";
    GLenum result = m_framebufferBinding->checkStatus(&reason);
    if (result != GL_FRAMEBUFFER_COMPLETE) {
        emitGLWarning("checkFramebufferStatus", reason);
        return result;
    }
    result = webContext()->checkFramebufferStatus(target);
    return result;
}

void WebGLRenderingContextBase::clear(GLbitfield mask)
{
    if (isContextLost())
        return;
    if (mask & ~(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT)) {
        synthesizeGLError(GL_INVALID_VALUE, "clear", "invalid mask");
        return;
    }
    const char* reason = "framebuffer incomplete";
    if (m_framebufferBinding && !m_framebufferBinding->onAccess(webContext(), &reason)) {
        synthesizeGLError(GL_INVALID_FRAMEBUFFER_OPERATION, "clear", reason);
        return;
    }
    if (!clearIfComposited(mask))
        webContext()->clear(mask);
    markContextChanged(CanvasChanged);
}

void WebGLRenderingContextBase::clearColor(GLfloat r, GLfloat g, GLfloat b, GLfloat a)
{
    if (isContextLost())
        return;
    if (std::isnan(r))
        r = 0;
    if (std::isnan(g))
        g = 0;
    if (std::isnan(b))
        b = 0;
    if (std::isnan(a))
        a = 1;
    m_clearColor[0] = r;
    m_clearColor[1] = g;
    m_clearColor[2] = b;
    m_clearColor[3] = a;
    webContext()->clearColor(r, g, b, a);
}

void WebGLRenderingContextBase::clearDepth(GLfloat depth)
{
    if (isContextLost())
        return;
    m_clearDepth = depth;
    webContext()->clearDepth(depth);
}

void WebGLRenderingContextBase::clearStencil(GLint s)
{
    if (isContextLost())
        return;
    m_clearStencil = s;
    webContext()->clearStencil(s);
}

void WebGLRenderingContextBase::colorMask(GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha)
{
    if (isContextLost())
        return;
    m_colorMask[0] = red;
    m_colorMask[1] = green;
    m_colorMask[2] = blue;
    m_colorMask[3] = alpha;
    webContext()->colorMask(red, green, blue, alpha);
}

void WebGLRenderingContextBase::compileShader(WebGLShader* shader)
{
    if (isContextLost() || !validateWebGLObject("compileShader", shader))
        return;
    webContext()->compileShader(objectOrZero(shader));
}

void WebGLRenderingContextBase::compressedTexImage2D(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, ArrayBufferView* data)
{
    if (isContextLost())
        return;
    if (!validateTexFuncLevel("compressedTexImage2D", target, level))
        return;

    if (!validateCompressedTexFormat(internalformat)) {
        synthesizeGLError(GL_INVALID_ENUM, "compressedTexImage2D", "invalid internalformat");
        return;
    }
    if (border) {
        synthesizeGLError(GL_INVALID_VALUE, "compressedTexImage2D", "border not 0");
        return;
    }
    if (!validateCompressedTexDimensions("compressedTexImage2D", NotTexSubImage2D, target, level, width, height, internalformat))
        return;
    if (!validateCompressedTexFuncData("compressedTexImage2D", width, height, internalformat, data))
        return;

    WebGLTexture* tex = validateTextureBinding("compressedTexImage2D", target, true);
    if (!tex)
        return;
    if (!isGLES2NPOTStrict()) {
        if (level && WebGLTexture::isNPOT(width, height)) {
            synthesizeGLError(GL_INVALID_VALUE, "compressedTexImage2D", "level > 0 not power of 2");
            return;
        }
    }
    webContext()->compressedTexImage2D(target, level, internalformat, width, height,
        border, data->byteLength(), data->baseAddress());
    tex->setLevelInfo(target, level, internalformat, width, height, GL_UNSIGNED_BYTE);
}

void WebGLRenderingContextBase::compressedTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, ArrayBufferView* data)
{
    if (isContextLost())
        return;
    if (!validateTexFuncLevel("compressedTexSubImage2D", target, level))
        return;
    if (!validateCompressedTexFormat(format)) {
        synthesizeGLError(GL_INVALID_ENUM, "compressedTexSubImage2D", "invalid format");
        return;
    }
    if (!validateCompressedTexFuncData("compressedTexSubImage2D", width, height, format, data))
        return;

    WebGLTexture* tex = validateTextureBinding("compressedTexSubImage2D", target, true);
    if (!tex)
        return;

    if (format != tex->getInternalFormat(target, level)) {
        synthesizeGLError(GL_INVALID_OPERATION, "compressedTexSubImage2D", "format does not match texture format");
        return;
    }

    if (!validateCompressedTexSubDimensions("compressedTexSubImage2D", target, level, xoffset, yoffset, width, height, format, tex))
        return;

    webContext()->compressedTexSubImage2D(target, level, xoffset, yoffset,
        width, height, format, data->byteLength(), data->baseAddress());
}

bool WebGLRenderingContextBase::validateSettableTexFormat(const char* functionName, GLenum format)
{
    if (WebGLImageConversion::getClearBitsByFormat(format) & (GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT)) {
        synthesizeGLError(GL_INVALID_OPERATION, functionName, "format can not be set, only rendered to");
        return false;
    }
    return true;
}

void WebGLRenderingContextBase::copyTexImage2D(GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border)
{
    if (isContextLost())
        return;
    if (!validateTexFuncParameters("copyTexImage2D", NotTexSubImage2D, target, level, internalformat, width, height, border, internalformat, GL_UNSIGNED_BYTE))
        return;
    if (!validateSettableTexFormat("copyTexImage2D", internalformat))
        return;
    WebGLTexture* tex = validateTextureBinding("copyTexImage2D", target, true);
    if (!tex)
        return;
    if (!isTexInternalFormatColorBufferCombinationValid(internalformat, boundFramebufferColorFormat())) {
        synthesizeGLError(GL_INVALID_OPERATION, "copyTexImage2D", "framebuffer is incompatible format");
        return;
    }
    if (!isGLES2NPOTStrict() && level && WebGLTexture::isNPOT(width, height)) {
        synthesizeGLError(GL_INVALID_VALUE, "copyTexImage2D", "level > 0 not power of 2");
        return;
    }
    const char* reason = "framebuffer incomplete";
    if (m_framebufferBinding && !m_framebufferBinding->onAccess(webContext(), &reason)) {
        synthesizeGLError(GL_INVALID_FRAMEBUFFER_OPERATION, "copyTexImage2D", reason);
        return;
    }
    clearIfComposited();
    ScopedDrawingBufferBinder binder(drawingBuffer(), m_framebufferBinding.get());
    webContext()->copyTexImage2D(target, level, internalformat, x, y, width, height, border);
    // FIXME: if the framebuffer is not complete, none of the below should be executed.
    tex->setLevelInfo(target, level, internalformat, width, height, GL_UNSIGNED_BYTE);
}

void WebGLRenderingContextBase::copyTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height)
{
    if (isContextLost())
        return;
    if (!validateTexFuncLevel("copyTexSubImage2D", target, level))
        return;
    WebGLTexture* tex = validateTextureBinding("copyTexSubImage2D", target, true);
    if (!tex)
        return;
    if (!validateSize("copyTexSubImage2D", xoffset, yoffset) || !validateSize("copyTexSubImage2D", width, height))
        return;
    // Before checking if it is in the range, check if overflow happens first.
    Checked<GLint, RecordOverflow> maxX = xoffset;
    maxX += width;
    Checked<GLint, RecordOverflow> maxY = yoffset;
    maxY += height;
    if (maxX.hasOverflowed() || maxY.hasOverflowed()) {
        synthesizeGLError(GL_INVALID_VALUE, "copyTexSubImage2D", "bad dimensions");
        return;
    }
    if (maxX.unsafeGet() > tex->getWidth(target, level) || maxY.unsafeGet() > tex->getHeight(target, level)) {
        synthesizeGLError(GL_INVALID_VALUE, "copyTexSubImage2D", "rectangle out of range");
        return;
    }
    GLenum internalformat = tex->getInternalFormat(target, level);
    if (!validateSettableTexFormat("copyTexSubImage2D", internalformat))
        return;
    if (!isTexInternalFormatColorBufferCombinationValid(internalformat, boundFramebufferColorFormat())) {
        synthesizeGLError(GL_INVALID_OPERATION, "copyTexSubImage2D", "framebuffer is incompatible format");
        return;
    }
    const char* reason = "framebuffer incomplete";
    if (m_framebufferBinding && !m_framebufferBinding->onAccess(webContext(), &reason)) {
        synthesizeGLError(GL_INVALID_FRAMEBUFFER_OPERATION, "copyTexSubImage2D", reason);
        return;
    }
    clearIfComposited();
    ScopedDrawingBufferBinder binder(drawingBuffer(), m_framebufferBinding.get());
    webContext()->copyTexSubImage2D(target, level, xoffset, yoffset, x, y, width, height);
}

PassRefPtrWillBeRawPtr<WebGLBuffer> WebGLRenderingContextBase::createBuffer()
{
    if (isContextLost())
        return nullptr;
    RefPtrWillBeRawPtr<WebGLBuffer> o = WebGLBuffer::create(this);
    addSharedObject(o.get());
    return o.release();
}

PassRefPtrWillBeRawPtr<WebGLFramebuffer> WebGLRenderingContextBase::createFramebuffer()
{
    if (isContextLost())
        return nullptr;
    RefPtrWillBeRawPtr<WebGLFramebuffer> o = WebGLFramebuffer::create(this);
    addContextObject(o.get());
    return o.release();
}

PassRefPtrWillBeRawPtr<WebGLTexture> WebGLRenderingContextBase::createTexture()
{
    if (isContextLost())
        return nullptr;
    RefPtrWillBeRawPtr<WebGLTexture> o = WebGLTexture::create(this);
    addSharedObject(o.get());
    return o.release();
}

PassRefPtrWillBeRawPtr<WebGLProgram> WebGLRenderingContextBase::createProgram()
{
    if (isContextLost())
        return nullptr;
    RefPtrWillBeRawPtr<WebGLProgram> o = WebGLProgram::create(this);
    addSharedObject(o.get());
    return o.release();
}

PassRefPtrWillBeRawPtr<WebGLRenderbuffer> WebGLRenderingContextBase::createRenderbuffer()
{
    if (isContextLost())
        return nullptr;
    RefPtrWillBeRawPtr<WebGLRenderbuffer> o = WebGLRenderbuffer::create(this);
    addSharedObject(o.get());
    return o.release();
}

WebGLRenderbuffer* WebGLRenderingContextBase::ensureEmulatedStencilBuffer(GLenum target, WebGLRenderbuffer* renderbuffer)
{
    if (isContextLost())
        return 0;
    if (!renderbuffer->emulatedStencilBuffer()) {
        renderbuffer->setEmulatedStencilBuffer(createRenderbuffer());
        webContext()->bindRenderbuffer(target, objectOrZero(renderbuffer->emulatedStencilBuffer()));
        webContext()->bindRenderbuffer(target, objectOrZero(m_renderbufferBinding.get()));
    }
    return renderbuffer->emulatedStencilBuffer();
}

PassRefPtrWillBeRawPtr<WebGLShader> WebGLRenderingContextBase::createShader(GLenum type)
{
    if (isContextLost())
        return nullptr;
    if (type != GL_VERTEX_SHADER && type != GL_FRAGMENT_SHADER) {
        synthesizeGLError(GL_INVALID_ENUM, "createShader", "invalid shader type");
        return nullptr;
    }

    RefPtrWillBeRawPtr<WebGLShader> o = WebGLShader::create(this, type);
    addSharedObject(o.get());
    return o.release();
}

void WebGLRenderingContextBase::cullFace(GLenum mode)
{
    if (isContextLost())
        return;
    switch (mode) {
    case GL_FRONT_AND_BACK:
    case GL_FRONT:
    case GL_BACK:
        break;
    default:
        synthesizeGLError(GL_INVALID_ENUM, "cullFace", "invalid mode");
        return;
    }
    webContext()->cullFace(mode);
}

bool WebGLRenderingContextBase::deleteObject(WebGLObject* object)
{
    if (isContextLost() || !object)
        return false;
    if (!object->validate(contextGroup(), this)) {
        synthesizeGLError(GL_INVALID_OPERATION, "delete", "object does not belong to this context");
        return false;
    }
    if (object->object()) {
        // We need to pass in context here because we want
        // things in this context unbound.
        object->deleteObject(webContext());
    }
    return true;
}

void WebGLRenderingContextBase::deleteBuffer(WebGLBuffer* buffer)
{
    if (!deleteObject(buffer))
        return;
    if (m_boundArrayBuffer == buffer)
        m_boundArrayBuffer = nullptr;

    m_boundVertexArrayObject->unbindBuffer(buffer);
}

void WebGLRenderingContextBase::deleteFramebuffer(WebGLFramebuffer* framebuffer)
{
    if (!deleteObject(framebuffer))
        return;
    if (framebuffer == m_framebufferBinding) {
        m_framebufferBinding = nullptr;
        drawingBuffer()->setFramebufferBinding(0);
        // Have to call bindFramebuffer here to bind back to internal fbo.
        drawingBuffer()->bind();
    }
}

void WebGLRenderingContextBase::deleteProgram(WebGLProgram* program)
{
    deleteObject(program);
    // We don't reset m_currentProgram to 0 here because the deletion of the
    // current program is delayed.
}

void WebGLRenderingContextBase::deleteRenderbuffer(WebGLRenderbuffer* renderbuffer)
{
    if (!deleteObject(renderbuffer))
        return;
    if (renderbuffer == m_renderbufferBinding)
        m_renderbufferBinding = nullptr;
    if (m_framebufferBinding)
        m_framebufferBinding->removeAttachmentFromBoundFramebuffer(renderbuffer);
}

void WebGLRenderingContextBase::deleteShader(WebGLShader* shader)
{
    deleteObject(shader);
}

void WebGLRenderingContextBase::deleteTexture(WebGLTexture* texture)
{
    if (!deleteObject(texture))
        return;

    int maxBoundTextureIndex = -1;
    for (size_t i = 0; i < m_onePlusMaxNonDefaultTextureUnit; ++i) {
        if (texture == m_textureUnits[i].m_texture2DBinding) {
            m_textureUnits[i].m_texture2DBinding = nullptr;
            maxBoundTextureIndex = i;
            if (!i)
                drawingBuffer()->setTexture2DBinding(0);
        }
        if (texture == m_textureUnits[i].m_textureCubeMapBinding) {
            m_textureUnits[i].m_textureCubeMapBinding = nullptr;
            maxBoundTextureIndex = i;
        }
    }
    if (m_framebufferBinding)
        m_framebufferBinding->removeAttachmentFromBoundFramebuffer(texture);

    // If the deleted was bound to the the current maximum index, trace backwards to find the new max texture index
    if (m_onePlusMaxNonDefaultTextureUnit == static_cast<unsigned long>(maxBoundTextureIndex + 1)) {
        findNewMaxNonDefaultTextureUnit();
    }
}

void WebGLRenderingContextBase::depthFunc(GLenum func)
{
    if (isContextLost())
        return;
    if (!validateStencilOrDepthFunc("depthFunc", func))
        return;
    webContext()->depthFunc(func);
}

void WebGLRenderingContextBase::depthMask(GLboolean flag)
{
    if (isContextLost())
        return;
    m_depthMask = flag;
    webContext()->depthMask(flag);
}

void WebGLRenderingContextBase::depthRange(GLfloat zNear, GLfloat zFar)
{
    if (isContextLost())
        return;
    if (zNear > zFar) {
        synthesizeGLError(GL_INVALID_OPERATION, "depthRange", "zNear > zFar");
        return;
    }
    webContext()->depthRange(zNear, zFar);
}

void WebGLRenderingContextBase::detachShader(WebGLProgram* program, WebGLShader* shader)
{
    if (isContextLost() || !validateWebGLObject("detachShader", program) || !validateWebGLObject("detachShader", shader))
        return;
    if (!program->detachShader(shader)) {
        synthesizeGLError(GL_INVALID_OPERATION, "detachShader", "shader not attached");
        return;
    }
    webContext()->detachShader(objectOrZero(program), objectOrZero(shader));
    shader->onDetached(webContext());
}

void WebGLRenderingContextBase::disable(GLenum cap)
{
    if (isContextLost() || !validateCapability("disable", cap))
        return;
    if (cap == GL_STENCIL_TEST) {
        m_stencilEnabled = false;
        applyStencilTest();
        return;
    }
    if (cap == GL_SCISSOR_TEST) {
        m_scissorEnabled = false;
        drawingBuffer()->setScissorEnabled(m_scissorEnabled);
    }
    webContext()->disable(cap);
}

void WebGLRenderingContextBase::disableVertexAttribArray(GLuint index)
{
    if (isContextLost())
        return;
    if (index >= m_maxVertexAttribs) {
        synthesizeGLError(GL_INVALID_VALUE, "disableVertexAttribArray", "index out of range");
        return;
    }

    WebGLVertexArrayObjectOES::VertexAttribState& state = m_boundVertexArrayObject->getVertexAttribState(index);
    state.enabled = false;

    webContext()->disableVertexAttribArray(index);
}

bool WebGLRenderingContextBase::validateRenderingState(const char* functionName)
{
    if (!m_currentProgram) {
        synthesizeGLError(GL_INVALID_OPERATION, functionName, "no valid shader program in use");
        return false;
    }

    return true;
}

bool WebGLRenderingContextBase::validateWebGLObject(const char* functionName, WebGLObject* object)
{
    if (!object || !object->object()) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "no object or object deleted");
        return false;
    }
    if (!object->validate(contextGroup(), this)) {
        synthesizeGLError(GL_INVALID_OPERATION, functionName, "object does not belong to this context");
        return false;
    }
    return true;
}

void WebGLRenderingContextBase::drawArrays(GLenum mode, GLint first, GLsizei count)
{
    if (!validateDrawArrays("drawArrays", mode, first, count))
        return;

    clearIfComposited();

    handleTextureCompleteness("drawArrays", true);
    webContext()->drawArrays(mode, first, count);
    handleTextureCompleteness("drawArrays", false);
    markContextChanged(CanvasChanged);
}

void WebGLRenderingContextBase::drawElements(GLenum mode, GLsizei count, GLenum type, long long offset)
{
    if (!validateDrawElements("drawElements", mode, count, type, offset))
        return;

    clearIfComposited();

    handleTextureCompleteness("drawElements", true);
    webContext()->drawElements(mode, count, type, static_cast<GLintptr>(offset));
    handleTextureCompleteness("drawElements", false);
    markContextChanged(CanvasChanged);
}

void WebGLRenderingContextBase::drawArraysInstancedANGLE(GLenum mode, GLint first, GLsizei count, GLsizei primcount)
{
    if (!validateDrawArrays("drawArraysInstancedANGLE", mode, first, count))
        return;

    if (!validateDrawInstanced("drawArraysInstancedANGLE", primcount))
        return;

    clearIfComposited();

    handleTextureCompleteness("drawArraysInstancedANGLE", true);
    webContext()->drawArraysInstancedANGLE(mode, first, count, primcount);
    handleTextureCompleteness("drawArraysInstancedANGLE", false);
    markContextChanged(CanvasChanged);
}

void WebGLRenderingContextBase::drawElementsInstancedANGLE(GLenum mode, GLsizei count, GLenum type, long long offset, GLsizei primcount)
{
    if (!validateDrawElements("drawElementsInstancedANGLE", mode, count, type, offset))
        return;

    if (!validateDrawInstanced("drawElementsInstancedANGLE", primcount))
        return;

    clearIfComposited();

    handleTextureCompleteness("drawElementsInstancedANGLE", true);
    webContext()->drawElementsInstancedANGLE(mode, count, type, static_cast<GLintptr>(offset), primcount);
    handleTextureCompleteness("drawElementsInstancedANGLE", false);
    markContextChanged(CanvasChanged);
}

void WebGLRenderingContextBase::enable(GLenum cap)
{
    if (isContextLost() || !validateCapability("enable", cap))
        return;
    if (cap == GL_STENCIL_TEST) {
        m_stencilEnabled = true;
        applyStencilTest();
        return;
    }
    if (cap == GL_SCISSOR_TEST) {
        m_scissorEnabled = true;
        drawingBuffer()->setScissorEnabled(m_scissorEnabled);
    }
    webContext()->enable(cap);
}

void WebGLRenderingContextBase::enableVertexAttribArray(GLuint index)
{
    if (isContextLost())
        return;
    if (index >= m_maxVertexAttribs) {
        synthesizeGLError(GL_INVALID_VALUE, "enableVertexAttribArray", "index out of range");
        return;
    }

    WebGLVertexArrayObjectOES::VertexAttribState& state = m_boundVertexArrayObject->getVertexAttribState(index);
    state.enabled = true;

    webContext()->enableVertexAttribArray(index);
}

void WebGLRenderingContextBase::finish()
{
    if (isContextLost())
        return;
    webContext()->flush(); // Intentionally a flush, not a finish.
}

void WebGLRenderingContextBase::flush()
{
    if (isContextLost())
        return;
    webContext()->flush();
}

void WebGLRenderingContextBase::framebufferRenderbuffer(GLenum target, GLenum attachment, GLenum renderbuffertarget, WebGLRenderbuffer* buffer)
{
    if (isContextLost() || !validateFramebufferFuncParameters("framebufferRenderbuffer", target, attachment))
        return;
    if (renderbuffertarget != GL_RENDERBUFFER) {
        synthesizeGLError(GL_INVALID_ENUM, "framebufferRenderbuffer", "invalid target");
        return;
    }
    if (buffer && !buffer->validate(contextGroup(), this)) {
        synthesizeGLError(GL_INVALID_OPERATION, "framebufferRenderbuffer", "no buffer or buffer not from this context");
        return;
    }
    // Don't allow the default framebuffer to be mutated; all current
    // implementations use an FBO internally in place of the default
    // FBO.
    if (!m_framebufferBinding || !m_framebufferBinding->object()) {
        synthesizeGLError(GL_INVALID_OPERATION, "framebufferRenderbuffer", "no framebuffer bound");
        return;
    }
    Platform3DObject bufferObject = objectOrZero(buffer);
    switch (attachment) {
    case GC3D_DEPTH_STENCIL_ATTACHMENT_WEBGL:
        if (isDepthStencilSupported() || !buffer) {
            webContext()->framebufferRenderbuffer(target, GL_DEPTH_ATTACHMENT, renderbuffertarget, bufferObject);
            webContext()->framebufferRenderbuffer(target, GL_STENCIL_ATTACHMENT, renderbuffertarget, bufferObject);
        } else {
            WebGLRenderbuffer* emulatedStencilBuffer = ensureEmulatedStencilBuffer(renderbuffertarget, buffer);
            if (!emulatedStencilBuffer) {
                synthesizeGLError(GL_OUT_OF_MEMORY, "framebufferRenderbuffer", "out of memory");
                return;
            }
            webContext()->framebufferRenderbuffer(target, GL_DEPTH_ATTACHMENT, renderbuffertarget, bufferObject);
            webContext()->framebufferRenderbuffer(target, GL_STENCIL_ATTACHMENT, renderbuffertarget, objectOrZero(emulatedStencilBuffer));
        }
        break;
    default:
        webContext()->framebufferRenderbuffer(target, attachment, renderbuffertarget, bufferObject);
    }
    m_framebufferBinding->setAttachmentForBoundFramebuffer(attachment, buffer);
    applyStencilTest();
}

void WebGLRenderingContextBase::framebufferTexture2D(GLenum target, GLenum attachment, GLenum textarget, WebGLTexture* texture, GLint level)
{
    if (isContextLost() || !validateFramebufferFuncParameters("framebufferTexture2D", target, attachment))
        return;
    if (level) {
        synthesizeGLError(GL_INVALID_VALUE, "framebufferTexture2D", "level not 0");
        return;
    }
    if (texture && !texture->validate(contextGroup(), this)) {
        synthesizeGLError(GL_INVALID_OPERATION, "framebufferTexture2D", "no texture or texture not from this context");
        return;
    }
    // Don't allow the default framebuffer to be mutated; all current
    // implementations use an FBO internally in place of the default
    // FBO.
    if (!m_framebufferBinding || !m_framebufferBinding->object()) {
        synthesizeGLError(GL_INVALID_OPERATION, "framebufferTexture2D", "no framebuffer bound");
        return;
    }
    Platform3DObject textureObject = objectOrZero(texture);
    switch (attachment) {
    case GC3D_DEPTH_STENCIL_ATTACHMENT_WEBGL:
        webContext()->framebufferTexture2D(target, GL_DEPTH_ATTACHMENT, textarget, textureObject, level);
        webContext()->framebufferTexture2D(target, GL_STENCIL_ATTACHMENT, textarget, textureObject, level);
        break;
    case GL_DEPTH_ATTACHMENT:
        webContext()->framebufferTexture2D(target, attachment, textarget, textureObject, level);
        break;
    case GL_STENCIL_ATTACHMENT:
        webContext()->framebufferTexture2D(target, attachment, textarget, textureObject, level);
        break;
    default:
        webContext()->framebufferTexture2D(target, attachment, textarget, textureObject, level);
    }
    m_framebufferBinding->setAttachmentForBoundFramebuffer(attachment, textarget, texture, level);
    applyStencilTest();
}

void WebGLRenderingContextBase::frontFace(GLenum mode)
{
    if (isContextLost())
        return;
    switch (mode) {
    case GL_CW:
    case GL_CCW:
        break;
    default:
        synthesizeGLError(GL_INVALID_ENUM, "frontFace", "invalid mode");
        return;
    }
    webContext()->frontFace(mode);
}

void WebGLRenderingContextBase::generateMipmap(GLenum target)
{
    if (isContextLost())
        return;
    WebGLTexture* tex = validateTextureBinding("generateMipmap", target, false);
    if (!tex)
        return;
    if (!tex->canGenerateMipmaps()) {
        synthesizeGLError(GL_INVALID_OPERATION, "generateMipmap", "level 0 not power of 2 or not all the same size");
        return;
    }
    if (!validateSettableTexFormat("generateMipmap", tex->getInternalFormat(target, 0)))
        return;

    // generateMipmap won't work properly if minFilter is not NEAREST_MIPMAP_LINEAR
    // on Mac.  Remove the hack once this driver bug is fixed.
#if OS(MACOSX)
    bool needToResetMinFilter = false;
    if (tex->getMinFilter() != GL_NEAREST_MIPMAP_LINEAR) {
        webContext()->texParameteri(target, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_LINEAR);
        needToResetMinFilter = true;
    }
#endif
    webContext()->generateMipmap(target);
#if OS(MACOSX)
    if (needToResetMinFilter)
        webContext()->texParameteri(target, GL_TEXTURE_MIN_FILTER, tex->getMinFilter());
#endif
    tex->generateMipmapLevelInfo();
}

PassRefPtrWillBeRawPtr<WebGLActiveInfo> WebGLRenderingContextBase::getActiveAttrib(WebGLProgram* program, GLuint index)
{
    if (isContextLost() || !validateWebGLObject("getActiveAttrib", program))
        return nullptr;
    blink::WebGraphicsContext3D::ActiveInfo info;
    if (!webContext()->getActiveAttrib(objectOrZero(program), index, info))
        return nullptr;
    return WebGLActiveInfo::create(info.name, info.type, info.size);
}

PassRefPtrWillBeRawPtr<WebGLActiveInfo> WebGLRenderingContextBase::getActiveUniform(WebGLProgram* program, GLuint index)
{
    if (isContextLost() || !validateWebGLObject("getActiveUniform", program))
        return nullptr;
    blink::WebGraphicsContext3D::ActiveInfo info;
    if (!webContext()->getActiveUniform(objectOrZero(program), index, info))
        return nullptr;
    return WebGLActiveInfo::create(info.name, info.type, info.size);
}

Nullable<WillBeHeapVector<RefPtrWillBeMember<WebGLShader> > > WebGLRenderingContextBase::getAttachedShaders(WebGLProgram* program)
{
    if (isContextLost() || !validateWebGLObject("getAttachedShaders", program))
        return Nullable<WillBeHeapVector<RefPtrWillBeMember<WebGLShader> > >();

    WillBeHeapVector<RefPtrWillBeMember<WebGLShader> > shaderObjects;
    const GLenum shaderType[] = {
        GL_VERTEX_SHADER,
        GL_FRAGMENT_SHADER
    };
    for (unsigned i = 0; i < sizeof(shaderType) / sizeof(GLenum); ++i) {
        WebGLShader* shader = program->getAttachedShader(shaderType[i]);
        if (shader)
            shaderObjects.append(shader);
    }
    return shaderObjects;
}

GLint WebGLRenderingContextBase::getAttribLocation(WebGLProgram* program, const String& name)
{
    if (isContextLost() || !validateWebGLObject("getAttribLocation", program))
        return -1;
    if (!validateLocationLength("getAttribLocation", name))
        return -1;
    if (!validateString("getAttribLocation", name))
        return -1;
    if (isPrefixReserved(name))
        return -1;
    if (!program->linkStatus()) {
        synthesizeGLError(GL_INVALID_OPERATION, "getAttribLocation", "program not linked");
        return 0;
    }
    return webContext()->getAttribLocation(objectOrZero(program), name.utf8().data());
}

WebGLGetInfo WebGLRenderingContextBase::getBufferParameter(GLenum target, GLenum pname)
{
    if (isContextLost())
        return WebGLGetInfo();
    if (target != GL_ARRAY_BUFFER && target != GL_ELEMENT_ARRAY_BUFFER) {
        synthesizeGLError(GL_INVALID_ENUM, "getBufferParameter", "invalid target");
        return WebGLGetInfo();
    }

    if (pname != GL_BUFFER_SIZE && pname != GL_BUFFER_USAGE) {
        synthesizeGLError(GL_INVALID_ENUM, "getBufferParameter", "invalid parameter name");
        return WebGLGetInfo();
    }

    GLint value = 0;
    webContext()->getBufferParameteriv(target, pname, &value);
    if (pname == GL_BUFFER_SIZE)
        return WebGLGetInfo(value);
    return WebGLGetInfo(static_cast<unsigned>(value));
}

PassRefPtrWillBeRawPtr<WebGLContextAttributes> WebGLRenderingContextBase::getContextAttributes()
{
    if (isContextLost())
        return nullptr;
    // We always need to return a new WebGLContextAttributes object to
    // prevent the user from mutating any cached version.
    blink::WebGraphicsContext3D::Attributes attrs = drawingBuffer()->getActualAttributes();
    RefPtrWillBeRawPtr<WebGLContextAttributes> attributes = m_requestedAttributes->clone();
    // Some requested attributes may not be honored, so we need to query the underlying
    // context/drawing buffer and adjust accordingly.
    if (m_requestedAttributes->depth() && !attrs.depth)
        attributes->setDepth(false);
    if (m_requestedAttributes->stencil() && !attrs.stencil)
        attributes->setStencil(false);
    attributes->setAntialias(drawingBuffer()->multisample());
    return attributes.release();
}

GLenum WebGLRenderingContextBase::getError()
{
    if (m_lostContextErrors.size()) {
        GLenum err = m_lostContextErrors.first();
        m_lostContextErrors.remove(0);
        return err;
    }

    if (isContextLost())
        return GL_NO_ERROR;

    return webContext()->getError();
}

const char* const* WebGLRenderingContextBase::ExtensionTracker::prefixes() const
{
    static const char* const unprefixed[] = { "", 0, };
    return m_prefixes ? m_prefixes : unprefixed;
}

bool WebGLRenderingContextBase::ExtensionTracker::matchesNameWithPrefixes(const String& name) const
{
    const char* const* prefixSet = prefixes();
    for (; *prefixSet; ++prefixSet) {
        String prefixedName = String(*prefixSet) + extensionName();
        if (equalIgnoringCase(prefixedName, name)) {
            return true;
        }
    }
    return false;
}

bool WebGLRenderingContextBase::extensionSupportedAndAllowed(const ExtensionTracker* tracker)
{
    if (tracker->draft() && !RuntimeEnabledFeatures::webGLDraftExtensionsEnabled())
        return false;
    if (!tracker->supported(this))
        return false;
    return true;
}


PassRefPtrWillBeRawPtr<WebGLExtension> WebGLRenderingContextBase::getExtension(const String& name)
{
    if (isContextLost())
        return nullptr;

    for (size_t i = 0; i < m_extensions.size(); ++i) {
        ExtensionTracker* tracker = m_extensions[i].get();
        if (tracker->matchesNameWithPrefixes(name)) {
            if (!extensionSupportedAndAllowed(tracker))
                return nullptr;

            RefPtrWillBeRawPtr<WebGLExtension> extension = tracker->getExtension(this);
            if (extension)
                m_extensionEnabled[extension->name()] = true;
            return extension.release();
        }
    }

    return nullptr;
}

WebGLGetInfo WebGLRenderingContextBase::getFramebufferAttachmentParameter(GLenum target, GLenum attachment, GLenum pname)
{
    if (isContextLost() || !validateFramebufferFuncParameters("getFramebufferAttachmentParameter", target, attachment))
        return WebGLGetInfo();

    if (!m_framebufferBinding || !m_framebufferBinding->object()) {
        synthesizeGLError(GL_INVALID_OPERATION, "getFramebufferAttachmentParameter", "no framebuffer bound");
        return WebGLGetInfo();
    }

    WebGLSharedObject* object = m_framebufferBinding->getAttachmentObject(attachment);
    if (!object) {
        if (pname == GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE)
            return WebGLGetInfo(GL_NONE);
        // OpenGL ES 2.0 specifies INVALID_ENUM in this case, while desktop GL
        // specifies INVALID_OPERATION.
        synthesizeGLError(GL_INVALID_ENUM, "getFramebufferAttachmentParameter", "invalid parameter name");
        return WebGLGetInfo();
    }

    ASSERT(object->isTexture() || object->isRenderbuffer());
    if (object->isTexture()) {
        switch (pname) {
        case GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE:
            return WebGLGetInfo(GL_TEXTURE);
        case GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME:
            return WebGLGetInfo(PassRefPtrWillBeRawPtr<WebGLTexture>(static_cast<WebGLTexture*>(object)));
        case GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL:
        case GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE:
            {
                GLint value = 0;
                webContext()->getFramebufferAttachmentParameteriv(target, attachment, pname, &value);
                return WebGLGetInfo(value);
            }
        default:
            synthesizeGLError(GL_INVALID_ENUM, "getFramebufferAttachmentParameter", "invalid parameter name for texture attachment");
            return WebGLGetInfo();
        }
    } else {
        switch (pname) {
        case GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE:
            return WebGLGetInfo(GL_RENDERBUFFER);
        case GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME:
            return WebGLGetInfo(PassRefPtrWillBeRawPtr<WebGLRenderbuffer>(static_cast<WebGLRenderbuffer*>(object)));
        default:
            synthesizeGLError(GL_INVALID_ENUM, "getFramebufferAttachmentParameter", "invalid parameter name for renderbuffer attachment");
            return WebGLGetInfo();
        }
    }
}

WebGLGetInfo WebGLRenderingContextBase::getParameter(GLenum pname)
{
    if (isContextLost())
        return WebGLGetInfo();
    const int intZero = 0;
    switch (pname) {
    case GL_ACTIVE_TEXTURE:
        return getUnsignedIntParameter(pname);
    case GL_ALIASED_LINE_WIDTH_RANGE:
        return getWebGLFloatArrayParameter(pname);
    case GL_ALIASED_POINT_SIZE_RANGE:
        return getWebGLFloatArrayParameter(pname);
    case GL_ALPHA_BITS:
        return getIntParameter(pname);
    case GL_ARRAY_BUFFER_BINDING:
        return WebGLGetInfo(PassRefPtrWillBeRawPtr<WebGLBuffer>(m_boundArrayBuffer.get()));
    case GL_BLEND:
        return getBooleanParameter(pname);
    case GL_BLEND_COLOR:
        return getWebGLFloatArrayParameter(pname);
    case GL_BLEND_DST_ALPHA:
        return getUnsignedIntParameter(pname);
    case GL_BLEND_DST_RGB:
        return getUnsignedIntParameter(pname);
    case GL_BLEND_EQUATION_ALPHA:
        return getUnsignedIntParameter(pname);
    case GL_BLEND_EQUATION_RGB:
        return getUnsignedIntParameter(pname);
    case GL_BLEND_SRC_ALPHA:
        return getUnsignedIntParameter(pname);
    case GL_BLEND_SRC_RGB:
        return getUnsignedIntParameter(pname);
    case GL_BLUE_BITS:
        return getIntParameter(pname);
    case GL_COLOR_CLEAR_VALUE:
        return getWebGLFloatArrayParameter(pname);
    case GL_COLOR_WRITEMASK:
        return getBooleanArrayParameter(pname);
    case GL_COMPRESSED_TEXTURE_FORMATS:
        return WebGLGetInfo(Uint32Array::create(m_compressedTextureFormats.data(), m_compressedTextureFormats.size()));
    case GL_CULL_FACE:
        return getBooleanParameter(pname);
    case GL_CULL_FACE_MODE:
        return getUnsignedIntParameter(pname);
    case GL_CURRENT_PROGRAM:
        return WebGLGetInfo(PassRefPtrWillBeRawPtr<WebGLProgram>(m_currentProgram.get()));
    case GL_DEPTH_BITS:
        if (!m_framebufferBinding && !m_requestedAttributes->depth())
            return WebGLGetInfo(intZero);
        return getIntParameter(pname);
    case GL_DEPTH_CLEAR_VALUE:
        return getFloatParameter(pname);
    case GL_DEPTH_FUNC:
        return getUnsignedIntParameter(pname);
    case GL_DEPTH_RANGE:
        return getWebGLFloatArrayParameter(pname);
    case GL_DEPTH_TEST:
        return getBooleanParameter(pname);
    case GL_DEPTH_WRITEMASK:
        return getBooleanParameter(pname);
    case GL_DITHER:
        return getBooleanParameter(pname);
    case GL_ELEMENT_ARRAY_BUFFER_BINDING:
        return WebGLGetInfo(PassRefPtrWillBeRawPtr<WebGLBuffer>(m_boundVertexArrayObject->boundElementArrayBuffer()));
    case GL_FRAMEBUFFER_BINDING:
        return WebGLGetInfo(PassRefPtrWillBeRawPtr<WebGLFramebuffer>(m_framebufferBinding.get()));
    case GL_FRONT_FACE:
        return getUnsignedIntParameter(pname);
    case GL_GENERATE_MIPMAP_HINT:
        return getUnsignedIntParameter(pname);
    case GL_GREEN_BITS:
        return getIntParameter(pname);
    case GL_IMPLEMENTATION_COLOR_READ_FORMAT:
        return getIntParameter(pname);
    case GL_IMPLEMENTATION_COLOR_READ_TYPE:
        return getIntParameter(pname);
    case GL_LINE_WIDTH:
        return getFloatParameter(pname);
    case GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS:
        return getIntParameter(pname);
    case GL_MAX_CUBE_MAP_TEXTURE_SIZE:
        return getIntParameter(pname);
    case GL_MAX_FRAGMENT_UNIFORM_VECTORS:
        return getIntParameter(pname);
    case GL_MAX_RENDERBUFFER_SIZE:
        return getIntParameter(pname);
    case GL_MAX_TEXTURE_IMAGE_UNITS:
        return getIntParameter(pname);
    case GL_MAX_TEXTURE_SIZE:
        return getIntParameter(pname);
    case GL_MAX_VARYING_VECTORS:
        return getIntParameter(pname);
    case GL_MAX_VERTEX_ATTRIBS:
        return getIntParameter(pname);
    case GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS:
        return getIntParameter(pname);
    case GL_MAX_VERTEX_UNIFORM_VECTORS:
        return getIntParameter(pname);
    case GL_MAX_VIEWPORT_DIMS:
        return getWebGLIntArrayParameter(pname);
    case GL_NUM_SHADER_BINARY_FORMATS:
        // FIXME: should we always return 0 for this?
        return getIntParameter(pname);
    case GL_PACK_ALIGNMENT:
        return getIntParameter(pname);
    case GL_POLYGON_OFFSET_FACTOR:
        return getFloatParameter(pname);
    case GL_POLYGON_OFFSET_FILL:
        return getBooleanParameter(pname);
    case GL_POLYGON_OFFSET_UNITS:
        return getFloatParameter(pname);
    case GL_RED_BITS:
        return getIntParameter(pname);
    case GL_RENDERBUFFER_BINDING:
        return WebGLGetInfo(PassRefPtrWillBeRawPtr<WebGLRenderbuffer>(m_renderbufferBinding.get()));
    case GL_RENDERER:
        return WebGLGetInfo(String("WebKit WebGL"));
    case GL_SAMPLE_BUFFERS:
        return getIntParameter(pname);
    case GL_SAMPLE_COVERAGE_INVERT:
        return getBooleanParameter(pname);
    case GL_SAMPLE_COVERAGE_VALUE:
        return getFloatParameter(pname);
    case GL_SAMPLES:
        return getIntParameter(pname);
    case GL_SCISSOR_BOX:
        return getWebGLIntArrayParameter(pname);
    case GL_SCISSOR_TEST:
        return getBooleanParameter(pname);
    case GL_SHADING_LANGUAGE_VERSION:
        return WebGLGetInfo("WebGL GLSL ES 1.0 (" + String(webContext()->getString(GL_SHADING_LANGUAGE_VERSION)) + ")");
    case GL_STENCIL_BACK_FAIL:
        return getUnsignedIntParameter(pname);
    case GL_STENCIL_BACK_FUNC:
        return getUnsignedIntParameter(pname);
    case GL_STENCIL_BACK_PASS_DEPTH_FAIL:
        return getUnsignedIntParameter(pname);
    case GL_STENCIL_BACK_PASS_DEPTH_PASS:
        return getUnsignedIntParameter(pname);
    case GL_STENCIL_BACK_REF:
        return getIntParameter(pname);
    case GL_STENCIL_BACK_VALUE_MASK:
        return getUnsignedIntParameter(pname);
    case GL_STENCIL_BACK_WRITEMASK:
        return getUnsignedIntParameter(pname);
    case GL_STENCIL_BITS:
        if (!m_framebufferBinding && !m_requestedAttributes->stencil())
            return WebGLGetInfo(intZero);
        return getIntParameter(pname);
    case GL_STENCIL_CLEAR_VALUE:
        return getIntParameter(pname);
    case GL_STENCIL_FAIL:
        return getUnsignedIntParameter(pname);
    case GL_STENCIL_FUNC:
        return getUnsignedIntParameter(pname);
    case GL_STENCIL_PASS_DEPTH_FAIL:
        return getUnsignedIntParameter(pname);
    case GL_STENCIL_PASS_DEPTH_PASS:
        return getUnsignedIntParameter(pname);
    case GL_STENCIL_REF:
        return getIntParameter(pname);
    case GL_STENCIL_TEST:
        return getBooleanParameter(pname);
    case GL_STENCIL_VALUE_MASK:
        return getUnsignedIntParameter(pname);
    case GL_STENCIL_WRITEMASK:
        return getUnsignedIntParameter(pname);
    case GL_SUBPIXEL_BITS:
        return getIntParameter(pname);
    case GL_TEXTURE_BINDING_2D:
        return WebGLGetInfo(PassRefPtrWillBeRawPtr<WebGLTexture>(m_textureUnits[m_activeTextureUnit].m_texture2DBinding.get()));
    case GL_TEXTURE_BINDING_CUBE_MAP:
        return WebGLGetInfo(PassRefPtrWillBeRawPtr<WebGLTexture>(m_textureUnits[m_activeTextureUnit].m_textureCubeMapBinding.get()));
    case GL_UNPACK_ALIGNMENT:
        return getIntParameter(pname);
    case GC3D_UNPACK_FLIP_Y_WEBGL:
        return WebGLGetInfo(m_unpackFlipY);
    case GC3D_UNPACK_PREMULTIPLY_ALPHA_WEBGL:
        return WebGLGetInfo(m_unpackPremultiplyAlpha);
    case GC3D_UNPACK_COLORSPACE_CONVERSION_WEBGL:
        return WebGLGetInfo(m_unpackColorspaceConversion);
    case GL_VENDOR:
        return WebGLGetInfo(String("WebKit"));
    case GL_VERSION:
        return WebGLGetInfo("WebGL 1.0 (" + String(webContext()->getString(GL_VERSION)) + ")");
    case GL_VIEWPORT:
        return getWebGLIntArrayParameter(pname);
    case GL_FRAGMENT_SHADER_DERIVATIVE_HINT_OES: // OES_standard_derivatives
        if (extensionEnabled(OESStandardDerivativesName))
            return getUnsignedIntParameter(GL_FRAGMENT_SHADER_DERIVATIVE_HINT_OES);
        synthesizeGLError(GL_INVALID_ENUM, "getParameter", "invalid parameter name, OES_standard_derivatives not enabled");
        return WebGLGetInfo();
    case WebGLDebugRendererInfo::UNMASKED_RENDERER_WEBGL:
        if (extensionEnabled(WebGLDebugRendererInfoName))
            return WebGLGetInfo(webContext()->getString(GL_RENDERER));
        synthesizeGLError(GL_INVALID_ENUM, "getParameter", "invalid parameter name, WEBGL_debug_renderer_info not enabled");
        return WebGLGetInfo();
    case WebGLDebugRendererInfo::UNMASKED_VENDOR_WEBGL:
        if (extensionEnabled(WebGLDebugRendererInfoName))
            return WebGLGetInfo(webContext()->getString(GL_VENDOR));
        synthesizeGLError(GL_INVALID_ENUM, "getParameter", "invalid parameter name, WEBGL_debug_renderer_info not enabled");
        return WebGLGetInfo();
    case GL_VERTEX_ARRAY_BINDING_OES: // OES_vertex_array_object
        if (extensionEnabled(OESVertexArrayObjectName)) {
            if (!m_boundVertexArrayObject->isDefaultObject())
                return WebGLGetInfo(PassRefPtrWillBeRawPtr<WebGLVertexArrayObjectOES>(m_boundVertexArrayObject.get()));
            return WebGLGetInfo();
        }
        synthesizeGLError(GL_INVALID_ENUM, "getParameter", "invalid parameter name, OES_vertex_array_object not enabled");
        return WebGLGetInfo();
    case GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT: // EXT_texture_filter_anisotropic
        if (extensionEnabled(EXTTextureFilterAnisotropicName))
            return getUnsignedIntParameter(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT);
        synthesizeGLError(GL_INVALID_ENUM, "getParameter", "invalid parameter name, EXT_texture_filter_anisotropic not enabled");
        return WebGLGetInfo();
    case GL_MAX_COLOR_ATTACHMENTS_EXT: // EXT_draw_buffers BEGIN
        if (extensionEnabled(WebGLDrawBuffersName))
            return WebGLGetInfo(maxColorAttachments());
        synthesizeGLError(GL_INVALID_ENUM, "getParameter", "invalid parameter name, WEBGL_draw_buffers not enabled");
        return WebGLGetInfo();
    case GL_MAX_DRAW_BUFFERS_EXT:
        if (extensionEnabled(WebGLDrawBuffersName))
            return WebGLGetInfo(maxDrawBuffers());
        synthesizeGLError(GL_INVALID_ENUM, "getParameter", "invalid parameter name, WEBGL_draw_buffers not enabled");
        return WebGLGetInfo();
    default:
        if (extensionEnabled(WebGLDrawBuffersName)
            && pname >= GL_DRAW_BUFFER0_EXT
            && pname < static_cast<GLenum>(GL_DRAW_BUFFER0_EXT + maxDrawBuffers())) {
            GLint value = GL_NONE;
            if (m_framebufferBinding)
                value = m_framebufferBinding->getDrawBuffer(pname);
            else // emulated backbuffer
                value = m_backDrawBuffer;
            return WebGLGetInfo(value);
        }
        synthesizeGLError(GL_INVALID_ENUM, "getParameter", "invalid parameter name");
        return WebGLGetInfo();
    }
}

WebGLGetInfo WebGLRenderingContextBase::getProgramParameter(WebGLProgram* program, GLenum pname)
{
    if (isContextLost() || !validateWebGLObject("getProgramParameter", program))
        return WebGLGetInfo();

    GLint value = 0;
    switch (pname) {
    case GL_DELETE_STATUS:
        return WebGLGetInfo(program->isDeleted());
    case GL_VALIDATE_STATUS:
        webContext()->getProgramiv(objectOrZero(program), pname, &value);
        return WebGLGetInfo(static_cast<bool>(value));
    case GL_LINK_STATUS:
        return WebGLGetInfo(program->linkStatus());
    case GL_ATTACHED_SHADERS:
    case GL_ACTIVE_ATTRIBUTES:
    case GL_ACTIVE_UNIFORMS:
        webContext()->getProgramiv(objectOrZero(program), pname, &value);
        return WebGLGetInfo(value);
    default:
        synthesizeGLError(GL_INVALID_ENUM, "getProgramParameter", "invalid parameter name");
        return WebGLGetInfo();
    }
}

String WebGLRenderingContextBase::getProgramInfoLog(WebGLProgram* program)
{
    if (isContextLost())
        return String();
    if (!validateWebGLObject("getProgramInfoLog", program))
        return "";
    return ensureNotNull(webContext()->getProgramInfoLog(objectOrZero(program)));
}

WebGLGetInfo WebGLRenderingContextBase::getRenderbufferParameter(GLenum target, GLenum pname)
{
    if (isContextLost())
        return WebGLGetInfo();
    if (target != GL_RENDERBUFFER) {
        synthesizeGLError(GL_INVALID_ENUM, "getRenderbufferParameter", "invalid target");
        return WebGLGetInfo();
    }
    if (!m_renderbufferBinding || !m_renderbufferBinding->object()) {
        synthesizeGLError(GL_INVALID_OPERATION, "getRenderbufferParameter", "no renderbuffer bound");
        return WebGLGetInfo();
    }

    GLint value = 0;
    switch (pname) {
    case GL_RENDERBUFFER_WIDTH:
    case GL_RENDERBUFFER_HEIGHT:
    case GL_RENDERBUFFER_RED_SIZE:
    case GL_RENDERBUFFER_GREEN_SIZE:
    case GL_RENDERBUFFER_BLUE_SIZE:
    case GL_RENDERBUFFER_ALPHA_SIZE:
    case GL_RENDERBUFFER_DEPTH_SIZE:
        webContext()->getRenderbufferParameteriv(target, pname, &value);
        return WebGLGetInfo(value);
    case GL_RENDERBUFFER_STENCIL_SIZE:
        if (m_renderbufferBinding->emulatedStencilBuffer()) {
            webContext()->bindRenderbuffer(target, objectOrZero(m_renderbufferBinding->emulatedStencilBuffer()));
            webContext()->getRenderbufferParameteriv(target, pname, &value);
            webContext()->bindRenderbuffer(target, objectOrZero(m_renderbufferBinding.get()));
        } else {
            webContext()->getRenderbufferParameteriv(target, pname, &value);
        }
        return WebGLGetInfo(value);
    case GL_RENDERBUFFER_INTERNAL_FORMAT:
        return WebGLGetInfo(m_renderbufferBinding->internalFormat());
    default:
        synthesizeGLError(GL_INVALID_ENUM, "getRenderbufferParameter", "invalid parameter name");
        return WebGLGetInfo();
    }
}

WebGLGetInfo WebGLRenderingContextBase::getShaderParameter(WebGLShader* shader, GLenum pname)
{
    if (isContextLost() || !validateWebGLObject("getShaderParameter", shader))
        return WebGLGetInfo();
    GLint value = 0;
    switch (pname) {
    case GL_DELETE_STATUS:
        return WebGLGetInfo(shader->isDeleted());
    case GL_COMPILE_STATUS:
        webContext()->getShaderiv(objectOrZero(shader), pname, &value);
        return WebGLGetInfo(static_cast<bool>(value));
    case GL_SHADER_TYPE:
        webContext()->getShaderiv(objectOrZero(shader), pname, &value);
        return WebGLGetInfo(static_cast<unsigned>(value));
    default:
        synthesizeGLError(GL_INVALID_ENUM, "getShaderParameter", "invalid parameter name");
        return WebGLGetInfo();
    }
}

String WebGLRenderingContextBase::getShaderInfoLog(WebGLShader* shader)
{
    if (isContextLost())
        return String();
    if (!validateWebGLObject("getShaderInfoLog", shader))
        return "";
    return ensureNotNull(webContext()->getShaderInfoLog(objectOrZero(shader)));
}

PassRefPtrWillBeRawPtr<WebGLShaderPrecisionFormat> WebGLRenderingContextBase::getShaderPrecisionFormat(GLenum shaderType, GLenum precisionType)
{
    if (isContextLost())
        return nullptr;
    switch (shaderType) {
    case GL_VERTEX_SHADER:
    case GL_FRAGMENT_SHADER:
        break;
    default:
        synthesizeGLError(GL_INVALID_ENUM, "getShaderPrecisionFormat", "invalid shader type");
        return nullptr;
    }
    switch (precisionType) {
    case GL_LOW_FLOAT:
    case GL_MEDIUM_FLOAT:
    case GL_HIGH_FLOAT:
    case GL_LOW_INT:
    case GL_MEDIUM_INT:
    case GL_HIGH_INT:
        break;
    default:
        synthesizeGLError(GL_INVALID_ENUM, "getShaderPrecisionFormat", "invalid precision type");
        return nullptr;
    }

    GLint range[2] = {0, 0};
    GLint precision = 0;
    webContext()->getShaderPrecisionFormat(shaderType, precisionType, range, &precision);
    return WebGLShaderPrecisionFormat::create(range[0], range[1], precision);
}

String WebGLRenderingContextBase::getShaderSource(WebGLShader* shader)
{
    if (isContextLost())
        return String();
    if (!validateWebGLObject("getShaderSource", shader))
        return "";
    return ensureNotNull(shader->source());
}

Nullable<Vector<String> > WebGLRenderingContextBase::getSupportedExtensions()
{
    if (isContextLost())
        return Nullable<Vector<String> >();

    Vector<String> result;

    for (size_t i = 0; i < m_extensions.size(); ++i) {
        ExtensionTracker* tracker = m_extensions[i].get();
        if (extensionSupportedAndAllowed(tracker)) {
            const char* const* prefixes = tracker->prefixes();
            for (; *prefixes; ++prefixes) {
                String prefixedName = String(*prefixes) + tracker->extensionName();
                result.append(prefixedName);
            }
        }
    }

    return result;
}

WebGLGetInfo WebGLRenderingContextBase::getTexParameter(GLenum target, GLenum pname)
{
    if (isContextLost())
        return WebGLGetInfo();
    WebGLTexture* tex = validateTextureBinding("getTexParameter", target, false);
    if (!tex)
        return WebGLGetInfo();
    switch (pname) {
    case GL_TEXTURE_MAG_FILTER:
    case GL_TEXTURE_MIN_FILTER:
    case GL_TEXTURE_WRAP_S:
    case GL_TEXTURE_WRAP_T:
        {
            GLint value = 0;
            webContext()->getTexParameteriv(target, pname, &value);
            return WebGLGetInfo(static_cast<unsigned>(value));
        }
    case GL_TEXTURE_MAX_ANISOTROPY_EXT: // EXT_texture_filter_anisotropic
        if (extensionEnabled(EXTTextureFilterAnisotropicName)) {
            GLfloat value = 0.f;
            webContext()->getTexParameterfv(target, pname, &value);
            return WebGLGetInfo(value);
        }
        synthesizeGLError(GL_INVALID_ENUM, "getTexParameter", "invalid parameter name, EXT_texture_filter_anisotropic not enabled");
        return WebGLGetInfo();
    default:
        synthesizeGLError(GL_INVALID_ENUM, "getTexParameter", "invalid parameter name");
        return WebGLGetInfo();
    }
}

WebGLGetInfo WebGLRenderingContextBase::getUniform(WebGLProgram* program, const WebGLUniformLocation* uniformLocation)
{
    if (isContextLost() || !validateWebGLObject("getUniform", program))
        return WebGLGetInfo();
    if (!uniformLocation || uniformLocation->program() != program) {
        synthesizeGLError(GL_INVALID_OPERATION, "getUniform", "no uniformlocation or not valid for this program");
        return WebGLGetInfo();
    }
    GLint location = uniformLocation->location();

    // FIXME: make this more efficient using WebGLUniformLocation and caching types in it
    GLint activeUniforms = 0;
    webContext()->getProgramiv(objectOrZero(program), GL_ACTIVE_UNIFORMS, &activeUniforms);
    for (GLint i = 0; i < activeUniforms; i++) {
        blink::WebGraphicsContext3D::ActiveInfo info;
        if (!webContext()->getActiveUniform(objectOrZero(program), i, info))
            return WebGLGetInfo();
        String name = info.name;
        StringBuilder nameBuilder;
        // Strip "[0]" from the name if it's an array.
        if (info.size > 1 && name.endsWith("[0]"))
            info.name = name.left(name.length() - 3);
        // If it's an array, we need to iterate through each element, appending "[index]" to the name.
        for (GLint index = 0; index < info.size; ++index) {
            nameBuilder.clear();
            nameBuilder.append(info.name);
            if (info.size > 1 && index >= 1) {
                nameBuilder.append('[');
                nameBuilder.append(String::number(index));
                nameBuilder.append(']');
            }
            // Now need to look this up by name again to find its location
            GLint loc = webContext()->getUniformLocation(objectOrZero(program), nameBuilder.toString().utf8().data());
            if (loc == location) {
                // Found it. Use the type in the ActiveInfo to determine the return type.
                GLenum baseType;
                unsigned length;
                switch (info.type) {
                case GL_BOOL:
                    baseType = GL_BOOL;
                    length = 1;
                    break;
                case GL_BOOL_VEC2:
                    baseType = GL_BOOL;
                    length = 2;
                    break;
                case GL_BOOL_VEC3:
                    baseType = GL_BOOL;
                    length = 3;
                    break;
                case GL_BOOL_VEC4:
                    baseType = GL_BOOL;
                    length = 4;
                    break;
                case GL_INT:
                    baseType = GL_INT;
                    length = 1;
                    break;
                case GL_INT_VEC2:
                    baseType = GL_INT;
                    length = 2;
                    break;
                case GL_INT_VEC3:
                    baseType = GL_INT;
                    length = 3;
                    break;
                case GL_INT_VEC4:
                    baseType = GL_INT;
                    length = 4;
                    break;
                case GL_FLOAT:
                    baseType = GL_FLOAT;
                    length = 1;
                    break;
                case GL_FLOAT_VEC2:
                    baseType = GL_FLOAT;
                    length = 2;
                    break;
                case GL_FLOAT_VEC3:
                    baseType = GL_FLOAT;
                    length = 3;
                    break;
                case GL_FLOAT_VEC4:
                    baseType = GL_FLOAT;
                    length = 4;
                    break;
                case GL_FLOAT_MAT2:
                    baseType = GL_FLOAT;
                    length = 4;
                    break;
                case GL_FLOAT_MAT3:
                    baseType = GL_FLOAT;
                    length = 9;
                    break;
                case GL_FLOAT_MAT4:
                    baseType = GL_FLOAT;
                    length = 16;
                    break;
                case GL_SAMPLER_2D:
                case GL_SAMPLER_CUBE:
                    baseType = GL_INT;
                    length = 1;
                    break;
                default:
                    // Can't handle this type
                    synthesizeGLError(GL_INVALID_VALUE, "getUniform", "unhandled type");
                    return WebGLGetInfo();
                }
                switch (baseType) {
                case GL_FLOAT: {
                    GLfloat value[16] = {0};
                    webContext()->getUniformfv(objectOrZero(program), location, value);
                    if (length == 1)
                        return WebGLGetInfo(value[0]);
                    return WebGLGetInfo(Float32Array::create(value, length));
                }
                case GL_INT: {
                    GLint value[4] = {0};
                    webContext()->getUniformiv(objectOrZero(program), location, value);
                    if (length == 1)
                        return WebGLGetInfo(value[0]);
                    return WebGLGetInfo(Int32Array::create(value, length));
                }
                case GL_BOOL: {
                    GLint value[4] = {0};
                    webContext()->getUniformiv(objectOrZero(program), location, value);
                    if (length > 1) {
                        bool boolValue[16] = {0};
                        for (unsigned j = 0; j < length; j++)
                            boolValue[j] = static_cast<bool>(value[j]);
                        return WebGLGetInfo(boolValue, length);
                    }
                    return WebGLGetInfo(static_cast<bool>(value[0]));
                }
                default:
                    notImplemented();
                }
            }
        }
    }
    // If we get here, something went wrong in our unfortunately complex logic above
    synthesizeGLError(GL_INVALID_VALUE, "getUniform", "unknown error");
    return WebGLGetInfo();
}

PassRefPtrWillBeRawPtr<WebGLUniformLocation> WebGLRenderingContextBase::getUniformLocation(WebGLProgram* program, const String& name)
{
    if (isContextLost() || !validateWebGLObject("getUniformLocation", program))
        return nullptr;
    if (!validateLocationLength("getUniformLocation", name))
        return nullptr;
    if (!validateString("getUniformLocation", name))
        return nullptr;
    if (isPrefixReserved(name))
        return nullptr;
    if (!program->linkStatus()) {
        synthesizeGLError(GL_INVALID_OPERATION, "getUniformLocation", "program not linked");
        return nullptr;
    }
    GLint uniformLocation = webContext()->getUniformLocation(objectOrZero(program), name.utf8().data());
    if (uniformLocation == -1)
        return nullptr;
    return WebGLUniformLocation::create(program, uniformLocation);
}

WebGLGetInfo WebGLRenderingContextBase::getVertexAttrib(GLuint index, GLenum pname)
{
    if (isContextLost())
        return WebGLGetInfo();
    if (index >= m_maxVertexAttribs) {
        synthesizeGLError(GL_INVALID_VALUE, "getVertexAttrib", "index out of range");
        return WebGLGetInfo();
    }
    const WebGLVertexArrayObjectOES::VertexAttribState& state = m_boundVertexArrayObject->getVertexAttribState(index);

    if (extensionEnabled(ANGLEInstancedArraysName) && pname == GL_VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE)
        return WebGLGetInfo(state.divisor);

    switch (pname) {
    case GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING:
        if (!state.bufferBinding || !state.bufferBinding->object())
            return WebGLGetInfo();
        return WebGLGetInfo(PassRefPtrWillBeRawPtr<WebGLBuffer>(state.bufferBinding.get()));
    case GL_VERTEX_ATTRIB_ARRAY_ENABLED:
        return WebGLGetInfo(state.enabled);
    case GL_VERTEX_ATTRIB_ARRAY_NORMALIZED:
        return WebGLGetInfo(state.normalized);
    case GL_VERTEX_ATTRIB_ARRAY_SIZE:
        return WebGLGetInfo(state.size);
    case GL_VERTEX_ATTRIB_ARRAY_STRIDE:
        return WebGLGetInfo(state.originalStride);
    case GL_VERTEX_ATTRIB_ARRAY_TYPE:
        return WebGLGetInfo(state.type);
    case GL_CURRENT_VERTEX_ATTRIB:
        return WebGLGetInfo(Float32Array::create(m_vertexAttribValue[index].value, 4));
    default:
        synthesizeGLError(GL_INVALID_ENUM, "getVertexAttrib", "invalid parameter name");
        return WebGLGetInfo();
    }
}

long long WebGLRenderingContextBase::getVertexAttribOffset(GLuint index, GLenum pname)
{
    if (isContextLost())
        return 0;
    if (pname != GL_VERTEX_ATTRIB_ARRAY_POINTER) {
        synthesizeGLError(GL_INVALID_ENUM, "getVertexAttribOffset", "invalid parameter name");
        return 0;
    }
    GLsizeiptr result = webContext()->getVertexAttribOffset(index, pname);
    return static_cast<long long>(result);
}

void WebGLRenderingContextBase::hint(GLenum target, GLenum mode)
{
    if (isContextLost())
        return;
    bool isValid = false;
    switch (target) {
    case GL_GENERATE_MIPMAP_HINT:
        isValid = true;
        break;
    case GL_FRAGMENT_SHADER_DERIVATIVE_HINT_OES: // OES_standard_derivatives
        if (extensionEnabled(OESStandardDerivativesName))
            isValid = true;
        break;
    }
    if (!isValid) {
        synthesizeGLError(GL_INVALID_ENUM, "hint", "invalid target");
        return;
    }
    webContext()->hint(target, mode);
}

GLboolean WebGLRenderingContextBase::isBuffer(WebGLBuffer* buffer)
{
    if (!buffer || isContextLost())
        return 0;

    if (!buffer->hasEverBeenBound())
        return 0;

    return webContext()->isBuffer(buffer->object());
}

bool WebGLRenderingContextBase::isContextLost() const
{
    return m_contextLostMode != NotLostContext;
}

GLboolean WebGLRenderingContextBase::isEnabled(GLenum cap)
{
    if (isContextLost() || !validateCapability("isEnabled", cap))
        return 0;
    if (cap == GL_STENCIL_TEST)
        return m_stencilEnabled;
    return webContext()->isEnabled(cap);
}

GLboolean WebGLRenderingContextBase::isFramebuffer(WebGLFramebuffer* framebuffer)
{
    if (!framebuffer || isContextLost())
        return 0;

    if (!framebuffer->hasEverBeenBound())
        return 0;

    return webContext()->isFramebuffer(framebuffer->object());
}

GLboolean WebGLRenderingContextBase::isProgram(WebGLProgram* program)
{
    if (!program || isContextLost())
        return 0;

    return webContext()->isProgram(program->object());
}

GLboolean WebGLRenderingContextBase::isRenderbuffer(WebGLRenderbuffer* renderbuffer)
{
    if (!renderbuffer || isContextLost())
        return 0;

    if (!renderbuffer->hasEverBeenBound())
        return 0;

    return webContext()->isRenderbuffer(renderbuffer->object());
}

GLboolean WebGLRenderingContextBase::isShader(WebGLShader* shader)
{
    if (!shader || isContextLost())
        return 0;

    return webContext()->isShader(shader->object());
}

GLboolean WebGLRenderingContextBase::isTexture(WebGLTexture* texture)
{
    if (!texture || isContextLost())
        return 0;

    if (!texture->hasEverBeenBound())
        return 0;

    return webContext()->isTexture(texture->object());
}

void WebGLRenderingContextBase::lineWidth(GLfloat width)
{
    if (isContextLost())
        return;
    webContext()->lineWidth(width);
}

void WebGLRenderingContextBase::linkProgram(WebGLProgram* program)
{
    if (isContextLost() || !validateWebGLObject("linkProgram", program))
        return;

    webContext()->linkProgram(objectOrZero(program));
    program->increaseLinkCount();
}

void WebGLRenderingContextBase::pixelStorei(GLenum pname, GLint param)
{
    if (isContextLost())
        return;
    switch (pname) {
    case GC3D_UNPACK_FLIP_Y_WEBGL:
        m_unpackFlipY = param;
        break;
    case GC3D_UNPACK_PREMULTIPLY_ALPHA_WEBGL:
        m_unpackPremultiplyAlpha = param;
        break;
    case GC3D_UNPACK_COLORSPACE_CONVERSION_WEBGL:
        if (static_cast<GLenum>(param) == GC3D_BROWSER_DEFAULT_WEBGL || param == GL_NONE) {
            m_unpackColorspaceConversion = static_cast<GLenum>(param);
        } else {
            synthesizeGLError(GL_INVALID_VALUE, "pixelStorei", "invalid parameter for UNPACK_COLORSPACE_CONVERSION_WEBGL");
            return;
        }
        break;
    case GL_PACK_ALIGNMENT:
    case GL_UNPACK_ALIGNMENT:
        if (param == 1 || param == 2 || param == 4 || param == 8) {
            if (pname == GL_PACK_ALIGNMENT) {
                m_packAlignment = param;
                drawingBuffer()->setPackAlignment(param);
            } else { // GL_UNPACK_ALIGNMENT:
                m_unpackAlignment = param;
            }
            webContext()->pixelStorei(pname, param);
        } else {
            synthesizeGLError(GL_INVALID_VALUE, "pixelStorei", "invalid parameter for alignment");
            return;
        }
        break;
    default:
        synthesizeGLError(GL_INVALID_ENUM, "pixelStorei", "invalid parameter name");
        return;
    }
}

void WebGLRenderingContextBase::polygonOffset(GLfloat factor, GLfloat units)
{
    if (isContextLost())
        return;
    webContext()->polygonOffset(factor, units);
}

void WebGLRenderingContextBase::readPixels(GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, ArrayBufferView* pixels)
{
    if (isContextLost())
        return;
    // Validate input parameters.
    if (!pixels) {
        synthesizeGLError(GL_INVALID_VALUE, "readPixels", "no destination ArrayBufferView");
        return;
    }
    switch (format) {
    case GL_ALPHA:
    case GL_RGB:
    case GL_RGBA:
        break;
    default:
        synthesizeGLError(GL_INVALID_ENUM, "readPixels", "invalid format");
        return;
    }

    ArrayBufferView::ViewType expectedViewType;

    switch (type) {
    case GL_UNSIGNED_BYTE:
        expectedViewType = ArrayBufferView::TypeUint8;
        break;
    case GL_UNSIGNED_SHORT_5_6_5:
    case GL_UNSIGNED_SHORT_4_4_4_4:
    case GL_UNSIGNED_SHORT_5_5_5_1:
        expectedViewType = ArrayBufferView::TypeUint16;
        break;
    case GL_FLOAT:
        expectedViewType = ArrayBufferView::TypeFloat32;
        break;
    case GL_HALF_FLOAT_OES:
        expectedViewType = ArrayBufferView::TypeUint16;
        break;
    default:
        synthesizeGLError(GL_INVALID_ENUM, "readPixels", "invalid type");
        return;
    }
    if (format != GL_RGBA || type != GL_UNSIGNED_BYTE) {
        // Check against the implementation color read format and type.
        blink::WGC3Dint implFormat = 0, implType = 0;
        webContext()->getIntegerv(GL_IMPLEMENTATION_COLOR_READ_FORMAT, &implFormat);
        webContext()->getIntegerv(GL_IMPLEMENTATION_COLOR_READ_TYPE, &implType);
        if (!implFormat || !implType || format != static_cast<GLenum>(implFormat) || type != static_cast<GLenum>(implType)) {
            synthesizeGLError(GL_INVALID_OPERATION, "readPixels", "format/type not RGBA/UNSIGNED_BYTE or implementation-defined values");
            return;
        }
    }
    // Validate array type against pixel type.
    if (pixels->type() != expectedViewType) {
        synthesizeGLError(GL_INVALID_OPERATION, "readPixels", "ArrayBufferView was the wrong type for the pixel format");
        return;
    }
    const char* reason = "framebuffer incomplete";
    if (m_framebufferBinding && !m_framebufferBinding->onAccess(webContext(), &reason)) {
        synthesizeGLError(GL_INVALID_FRAMEBUFFER_OPERATION, "readPixels", reason);
        return;
    }
    // Calculate array size, taking into consideration of PACK_ALIGNMENT.
    unsigned totalBytesRequired = 0;
    unsigned padding = 0;
    GLenum error = WebGLImageConversion::computeImageSizeInBytes(format, type, width, height, m_packAlignment, &totalBytesRequired, &padding);
    if (error != GL_NO_ERROR) {
        synthesizeGLError(error, "readPixels", "invalid dimensions");
        return;
    }
    if (pixels->byteLength() < totalBytesRequired) {
        synthesizeGLError(GL_INVALID_OPERATION, "readPixels", "ArrayBufferView not large enough for dimensions");
        return;
    }

    clearIfComposited();
    void* data = pixels->baseAddress();

    {
        ScopedDrawingBufferBinder binder(drawingBuffer(), m_framebufferBinding.get());
        webContext()->readPixels(x, y, width, height, format, type, data);
    }

#if OS(MACOSX)
    // FIXME: remove this section when GL driver bug on Mac is fixed, i.e.,
    // when alpha is off, readPixels should set alpha to 255 instead of 0.
    if (!m_framebufferBinding && !drawingBuffer()->getActualAttributes().alpha) {
        unsigned char* pixels = reinterpret_cast<unsigned char*>(data);
        for (GLsizei iy = 0; iy < height; ++iy) {
            for (GLsizei ix = 0; ix < width; ++ix) {
                pixels[3] = 255;
                pixels += 4;
            }
            pixels += padding;
        }
    }
#endif
}

void WebGLRenderingContextBase::renderbufferStorage(GLenum target, GLenum internalformat, GLsizei width, GLsizei height)
{
    if (isContextLost())
        return;
    if (target != GL_RENDERBUFFER) {
        synthesizeGLError(GL_INVALID_ENUM, "renderbufferStorage", "invalid target");
        return;
    }
    if (!m_renderbufferBinding || !m_renderbufferBinding->object()) {
        synthesizeGLError(GL_INVALID_OPERATION, "renderbufferStorage", "no bound renderbuffer");
        return;
    }
    if (!validateSize("renderbufferStorage", width, height))
        return;
    switch (internalformat) {
    case GL_DEPTH_COMPONENT16:
    case GL_RGBA4:
    case GL_RGB5_A1:
    case GL_RGB565:
    case GL_STENCIL_INDEX8:
        webContext()->renderbufferStorage(target, internalformat, width, height);
        m_renderbufferBinding->setInternalFormat(internalformat);
        m_renderbufferBinding->setSize(width, height);
        m_renderbufferBinding->deleteEmulatedStencilBuffer(webContext());
        break;
    case GL_DEPTH_STENCIL_OES:
        if (isDepthStencilSupported()) {
            webContext()->renderbufferStorage(target, GL_DEPTH24_STENCIL8_OES, width, height);
        } else {
            WebGLRenderbuffer* emulatedStencilBuffer = ensureEmulatedStencilBuffer(target, m_renderbufferBinding.get());
            if (!emulatedStencilBuffer) {
                synthesizeGLError(GL_OUT_OF_MEMORY, "renderbufferStorage", "out of memory");
                return;
            }
            webContext()->renderbufferStorage(target, GL_DEPTH_COMPONENT16, width, height);
            webContext()->bindRenderbuffer(target, objectOrZero(emulatedStencilBuffer));
            webContext()->renderbufferStorage(target, GL_STENCIL_INDEX8, width, height);
            webContext()->bindRenderbuffer(target, objectOrZero(m_renderbufferBinding.get()));
            emulatedStencilBuffer->setSize(width, height);
            emulatedStencilBuffer->setInternalFormat(GL_STENCIL_INDEX8);
        }
        m_renderbufferBinding->setSize(width, height);
        m_renderbufferBinding->setInternalFormat(internalformat);
        break;
    default:
        synthesizeGLError(GL_INVALID_ENUM, "renderbufferStorage", "invalid internalformat");
        return;
    }
    applyStencilTest();
}

void WebGLRenderingContextBase::sampleCoverage(GLfloat value, GLboolean invert)
{
    if (isContextLost())
        return;
    webContext()->sampleCoverage(value, invert);
}

void WebGLRenderingContextBase::scissor(GLint x, GLint y, GLsizei width, GLsizei height)
{
    if (isContextLost())
        return;
    if (!validateSize("scissor", width, height))
        return;
    webContext()->scissor(x, y, width, height);
}

void WebGLRenderingContextBase::shaderSource(WebGLShader* shader, const String& string)
{
    if (isContextLost() || !validateWebGLObject("shaderSource", shader))
        return;
    String stringWithoutComments = StripComments(string).result();
    if (!validateString("shaderSource", stringWithoutComments))
        return;
    shader->setSource(string);
    webContext()->shaderSource(objectOrZero(shader), stringWithoutComments.utf8().data());
}

void WebGLRenderingContextBase::stencilFunc(GLenum func, GLint ref, GLuint mask)
{
    if (isContextLost())
        return;
    if (!validateStencilOrDepthFunc("stencilFunc", func))
        return;
    m_stencilFuncRef = ref;
    m_stencilFuncRefBack = ref;
    m_stencilFuncMask = mask;
    m_stencilFuncMaskBack = mask;
    webContext()->stencilFunc(func, ref, mask);
}

void WebGLRenderingContextBase::stencilFuncSeparate(GLenum face, GLenum func, GLint ref, GLuint mask)
{
    if (isContextLost())
        return;
    if (!validateStencilOrDepthFunc("stencilFuncSeparate", func))
        return;
    switch (face) {
    case GL_FRONT_AND_BACK:
        m_stencilFuncRef = ref;
        m_stencilFuncRefBack = ref;
        m_stencilFuncMask = mask;
        m_stencilFuncMaskBack = mask;
        break;
    case GL_FRONT:
        m_stencilFuncRef = ref;
        m_stencilFuncMask = mask;
        break;
    case GL_BACK:
        m_stencilFuncRefBack = ref;
        m_stencilFuncMaskBack = mask;
        break;
    default:
        synthesizeGLError(GL_INVALID_ENUM, "stencilFuncSeparate", "invalid face");
        return;
    }
    webContext()->stencilFuncSeparate(face, func, ref, mask);
}

void WebGLRenderingContextBase::stencilMask(GLuint mask)
{
    if (isContextLost())
        return;
    m_stencilMask = mask;
    m_stencilMaskBack = mask;
    webContext()->stencilMask(mask);
}

void WebGLRenderingContextBase::stencilMaskSeparate(GLenum face, GLuint mask)
{
    if (isContextLost())
        return;
    switch (face) {
    case GL_FRONT_AND_BACK:
        m_stencilMask = mask;
        m_stencilMaskBack = mask;
        break;
    case GL_FRONT:
        m_stencilMask = mask;
        break;
    case GL_BACK:
        m_stencilMaskBack = mask;
        break;
    default:
        synthesizeGLError(GL_INVALID_ENUM, "stencilMaskSeparate", "invalid face");
        return;
    }
    webContext()->stencilMaskSeparate(face, mask);
}

void WebGLRenderingContextBase::stencilOp(GLenum fail, GLenum zfail, GLenum zpass)
{
    if (isContextLost())
        return;
    webContext()->stencilOp(fail, zfail, zpass);
}

void WebGLRenderingContextBase::stencilOpSeparate(GLenum face, GLenum fail, GLenum zfail, GLenum zpass)
{
    if (isContextLost())
        return;
    webContext()->stencilOpSeparate(face, fail, zfail, zpass);
}

GLenum WebGLRenderingContextBase::convertTexInternalFormat(GLenum internalformat, GLenum type)
{
    // Convert to sized internal formats that are renderable with GL_CHROMIUM_color_buffer_float_rgb(a).
    if (type == GL_FLOAT && internalformat == GL_RGBA
        && extensionsUtil()->isExtensionEnabled("GL_CHROMIUM_color_buffer_float_rgba"))
        return GL_RGBA32F_EXT;
    if (type == GL_FLOAT && internalformat == GL_RGB
        && extensionsUtil()->isExtensionEnabled("GL_CHROMIUM_color_buffer_float_rgb"))
        return GL_RGB32F_EXT;
    return internalformat;
}

void WebGLRenderingContextBase::texImage2DBase(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const void* pixels, ExceptionState& exceptionState)
{
    // All calling functions check isContextLost, so a duplicate check is not needed here.
    // FIXME: Handle errors.
    WebGLTexture* tex = validateTextureBinding("texImage2D", target, true);
    ASSERT(validateTexFuncParameters("texImage2D", NotTexSubImage2D, target, level, internalformat, width, height, border, format, type));
    ASSERT(tex);
    ASSERT(!level || !WebGLTexture::isNPOT(width, height));
    ASSERT(!pixels || validateSettableTexFormat("texImage2D", internalformat));
    webContext()->texImage2D(target, level, convertTexInternalFormat(internalformat, type), width, height, border, format, type, pixels);
    tex->setLevelInfo(target, level, internalformat, width, height, type);
}

void WebGLRenderingContextBase::texImage2DImpl(GLenum target, GLint level, GLenum internalformat, GLenum format, GLenum type, Image* image, WebGLImageConversion::ImageHtmlDomSource domSource, bool flipY, bool premultiplyAlpha, ExceptionState& exceptionState)
{
    // All calling functions check isContextLost, so a duplicate check is not needed here.
    Vector<uint8_t> data;
    WebGLImageConversion::ImageExtractor imageExtractor(image, domSource, premultiplyAlpha, m_unpackColorspaceConversion == GL_NONE);
    if (!imageExtractor.extractSucceeded()) {
        synthesizeGLError(GL_INVALID_VALUE, "texImage2D", "bad image data");
        return;
    }
    WebGLImageConversion::DataFormat sourceDataFormat = imageExtractor.imageSourceFormat();
    WebGLImageConversion::AlphaOp alphaOp = imageExtractor.imageAlphaOp();
    const void* imagePixelData = imageExtractor.imagePixelData();

    bool needConversion = true;
    if (type == GL_UNSIGNED_BYTE && sourceDataFormat == WebGLImageConversion::DataFormatRGBA8 && format == GL_RGBA && alphaOp == WebGLImageConversion::AlphaDoNothing && !flipY)
        needConversion = false;
    else {
        if (!WebGLImageConversion::packImageData(image, imagePixelData, format, type, flipY, alphaOp, sourceDataFormat, imageExtractor.imageWidth(), imageExtractor.imageHeight(), imageExtractor.imageSourceUnpackAlignment(), data)) {
            synthesizeGLError(GL_INVALID_VALUE, "texImage2D", "packImage error");
            return;
        }
    }

    if (m_unpackAlignment != 1)
        webContext()->pixelStorei(GL_UNPACK_ALIGNMENT, 1);
    texImage2DBase(target, level, internalformat, imageExtractor.imageWidth(), imageExtractor.imageHeight(), 0, format, type, needConversion ? data.data() : imagePixelData, exceptionState);
    if (m_unpackAlignment != 1)
        webContext()->pixelStorei(GL_UNPACK_ALIGNMENT, m_unpackAlignment);
}

bool WebGLRenderingContextBase::validateTexFunc(const char* functionName, TexFuncValidationFunctionType functionType, TexFuncValidationSourceType sourceType, GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, GLint xoffset, GLint yoffset)
{
    if (!validateTexFuncParameters(functionName, functionType, target, level, internalformat, width, height, border, format, type))
        return false;

    WebGLTexture* texture = validateTextureBinding(functionName, target, true);
    if (!texture)
        return false;

    if (functionType == NotTexSubImage2D) {
        if (level && WebGLTexture::isNPOT(width, height)) {
            synthesizeGLError(GL_INVALID_VALUE, functionName, "level > 0 not power of 2");
            return false;
        }
        // For SourceArrayBufferView, function validateTexFuncData() would handle whether to validate the SettableTexFormat
        // by checking if the ArrayBufferView is null or not.
        if (sourceType != SourceArrayBufferView) {
            if (!validateSettableTexFormat(functionName, format))
                return false;
        }
    } else {
        if (!validateSettableTexFormat(functionName, format))
            return false;
        if (!validateSize(functionName, xoffset, yoffset))
            return false;
        // Before checking if it is in the range, check if overflow happens first.
        if (xoffset + width < 0 || yoffset + height < 0) {
            synthesizeGLError(GL_INVALID_VALUE, functionName, "bad dimensions");
            return false;
        }
        if (xoffset + width > texture->getWidth(target, level) || yoffset + height > texture->getHeight(target, level)) {
            synthesizeGLError(GL_INVALID_VALUE, functionName, "dimensions out of range");
            return false;
        }
        if (texture->getInternalFormat(target, level) != format || texture->getType(target, level) != type) {
            synthesizeGLError(GL_INVALID_OPERATION, functionName, "type and format do not match texture");
            return false;
        }
    }

    return true;
}

bool WebGLRenderingContextBase::validateValueFitNonNegInt32(const char* functionName, const char* paramName, long long value)
{
    if (value < 0) {
        String errorMsg = String(paramName) + " < 0";
        synthesizeGLError(GL_INVALID_VALUE, functionName, errorMsg.ascii().data());
        return false;
    }
    if (value > static_cast<long long>(std::numeric_limits<int>::max())) {
        String errorMsg = String(paramName) + " more than 32-bit";
        synthesizeGLError(GL_INVALID_OPERATION, functionName, errorMsg.ascii().data());
        return false;
    }
    return true;
}

PassRefPtr<Image> WebGLRenderingContextBase::drawImageIntoBuffer(Image* image, int width, int height, const char* functionName)
{
    IntSize size(width, height);
    ImageBuffer* buf = m_generatedImageCache.imageBuffer(size);
    if (!buf) {
        synthesizeGLError(GL_OUT_OF_MEMORY, functionName, "out of memory");
        return nullptr;
    }

    IntRect srcRect(IntPoint(), image->size());
    IntRect destRect(0, 0, size.width(), size.height());
    buf->context()->drawImage(image, destRect, srcRect);
    return buf->copyImage(ImageBuffer::fastCopyImageMode());
}

void WebGLRenderingContextBase::texImage2D(GLenum target, GLint level, GLenum internalformat,
    GLsizei width, GLsizei height, GLint border,
    GLenum format, GLenum type, ArrayBufferView* pixels, ExceptionState& exceptionState)
{
    if (isContextLost() || !validateTexFuncData("texImage2D", level, width, height, format, type, pixels, NullAllowed)
        || !validateTexFunc("texImage2D", NotTexSubImage2D, SourceArrayBufferView, target, level, internalformat, width, height, border, format, type, 0, 0))
        return;
    void* data = pixels ? pixels->baseAddress() : 0;
    Vector<uint8_t> tempData;
    bool changeUnpackAlignment = false;
    if (data && (m_unpackFlipY || m_unpackPremultiplyAlpha)) {
        if (!WebGLImageConversion::extractTextureData(width, height, format, type, m_unpackAlignment, m_unpackFlipY, m_unpackPremultiplyAlpha, data, tempData))
            return;
        data = tempData.data();
        changeUnpackAlignment = true;
    }
    if (changeUnpackAlignment)
        webContext()->pixelStorei(GL_UNPACK_ALIGNMENT, 1);
    texImage2DBase(target, level, internalformat, width, height, border, format, type, data, exceptionState);
    if (changeUnpackAlignment)
        webContext()->pixelStorei(GL_UNPACK_ALIGNMENT, m_unpackAlignment);
}

void WebGLRenderingContextBase::texImage2D(GLenum target, GLint level, GLenum internalformat,
    GLenum format, GLenum type, ImageData* pixels, ExceptionState& exceptionState)
{
    if (isContextLost() || !pixels || !validateTexFunc("texImage2D", NotTexSubImage2D, SourceImageData, target, level, internalformat, pixels->width(), pixels->height(), 0, format, type, 0, 0))
        return;
    Vector<uint8_t> data;
    bool needConversion = true;
    // The data from ImageData is always of format RGBA8.
    // No conversion is needed if destination format is RGBA and type is USIGNED_BYTE and no Flip or Premultiply operation is required.
    if (!m_unpackFlipY && !m_unpackPremultiplyAlpha && format == GL_RGBA && type == GL_UNSIGNED_BYTE)
        needConversion = false;
    else {
        if (!WebGLImageConversion::extractImageData(pixels->data()->data(), pixels->size(), format, type, m_unpackFlipY, m_unpackPremultiplyAlpha, data)) {
            synthesizeGLError(GL_INVALID_VALUE, "texImage2D", "bad image data");
            return;
        }
    }
    if (m_unpackAlignment != 1)
        webContext()->pixelStorei(GL_UNPACK_ALIGNMENT, 1);
    texImage2DBase(target, level, internalformat, pixels->width(), pixels->height(), 0, format, type, needConversion ? data.data() : pixels->data()->data(), exceptionState);
    if (m_unpackAlignment != 1)
        webContext()->pixelStorei(GL_UNPACK_ALIGNMENT, m_unpackAlignment);
}

void WebGLRenderingContextBase::texImage2D(GLenum target, GLint level, GLenum internalformat,
    GLenum format, GLenum type, HTMLImageElement* image, ExceptionState& exceptionState)
{
    if (isContextLost() || !validateHTMLImageElement("texImage2D", image, exceptionState))
        return;

    RefPtr<Image> imageForRender = image->cachedImage()->imageForRenderer(image->renderer());
    if (!imageForRender || !validateTexFunc("texImage2D", NotTexSubImage2D, SourceHTMLImageElement, target, level, internalformat, imageForRender->width(), imageForRender->height(), 0, format, type, 0, 0))
        return;

    texImage2DImpl(target, level, internalformat, format, type, imageForRender.get(), WebGLImageConversion::HtmlDomImage, m_unpackFlipY, m_unpackPremultiplyAlpha, exceptionState);
}

void WebGLRenderingContextBase::texImage2D(GLenum target, GLint level, GLenum internalformat,
    GLenum format, GLenum type, HTMLCanvasElement* canvas, ExceptionState& exceptionState)
{
    if (isContextLost() || !validateHTMLCanvasElement("texImage2D", canvas, exceptionState) || !validateTexFunc("texImage2D", NotTexSubImage2D, SourceHTMLCanvasElement, target, level, internalformat, canvas->width(), canvas->height(), 0, format, type, 0, 0))
        return;

    WebGLTexture* texture = validateTextureBinding("texImage2D", target, true);

    // If possible, copy from the canvas element directly to the texture
    // via the GPU, without a read-back to system memory.
    if (GL_TEXTURE_2D == target && texture) {
        ScopedTexture2DRestorer restorer(this);

        if (!canvas->is3D()) {
            ImageBuffer* buffer = canvas->buffer();
            if (buffer && buffer->copyToPlatformTexture(webContext(), texture->object(), internalformat, type,
                level, m_unpackPremultiplyAlpha, m_unpackFlipY)) {
                texture->setLevelInfo(target, level, internalformat, canvas->width(), canvas->height(), type);
                return;
            }
        } else {
            WebGLRenderingContextBase* gl = toWebGLRenderingContextBase(canvas->renderingContext());
            ScopedTexture2DRestorer restorer(gl);
            if (gl && gl->drawingBuffer()->copyToPlatformTexture(webContext(), texture->object(), internalformat, type,
                level, m_unpackPremultiplyAlpha, m_unpackFlipY)) {
                texture->setLevelInfo(target, level, internalformat, canvas->width(), canvas->height(), type);
                return;
            }
        }
    }

    RefPtrWillBeRawPtr<ImageData> imageData = canvas->getImageData();
    if (imageData)
        texImage2D(target, level, internalformat, format, type, imageData.get(), exceptionState);
    else
        texImage2DImpl(target, level, internalformat, format, type, canvas->copiedImage(), WebGLImageConversion::HtmlDomCanvas, m_unpackFlipY, m_unpackPremultiplyAlpha, exceptionState);
}

PassRefPtr<Image> WebGLRenderingContextBase::videoFrameToImage(HTMLVideoElement* video, BackingStoreCopy backingStoreCopy)
{
    IntSize size(video->videoWidth(), video->videoHeight());
    ImageBuffer* buf = m_generatedImageCache.imageBuffer(size);
    if (!buf) {
        synthesizeGLError(GL_OUT_OF_MEMORY, "texImage2D", "out of memory");
        return nullptr;
    }
    IntRect destRect(0, 0, size.width(), size.height());
    // FIXME: Turn this into a GPU-GPU texture copy instead of CPU readback.
    video->paintCurrentFrameInContext(buf->context(), destRect);
    return buf->copyImage(backingStoreCopy);
}

void WebGLRenderingContextBase::texImage2D(GLenum target, GLint level, GLenum internalformat,
    GLenum format, GLenum type, HTMLVideoElement* video, ExceptionState& exceptionState)
{
    if (isContextLost() || !validateHTMLVideoElement("texImage2D", video, exceptionState)
        || !validateTexFunc("texImage2D", NotTexSubImage2D, SourceHTMLVideoElement, target, level, internalformat, video->videoWidth(), video->videoHeight(), 0, format, type, 0, 0))
        return;

    // Go through the fast path doing a GPU-GPU textures copy without a readback to system memory if possible.
    // Otherwise, it will fall back to the normal SW path.
    WebGLTexture* texture = validateTextureBinding("texImage2D", target, true);
    if (GL_TEXTURE_2D == target && texture) {
        if (video->copyVideoTextureToPlatformTexture(webContext(), texture->object(), level, internalformat, type, m_unpackPremultiplyAlpha, m_unpackFlipY)) {
            texture->setLevelInfo(target, level, internalformat, video->videoWidth(), video->videoHeight(), type);
            return;
        }
    }

    // Normal pure SW path.
    RefPtr<Image> image = videoFrameToImage(video, ImageBuffer::fastCopyImageMode());
    if (!image)
        return;
    texImage2DImpl(target, level, internalformat, format, type, image.get(), WebGLImageConversion::HtmlDomVideo, m_unpackFlipY, m_unpackPremultiplyAlpha, exceptionState);
}

void WebGLRenderingContextBase::texParameter(GLenum target, GLenum pname, GLfloat paramf, GLint parami, bool isFloat)
{
    if (isContextLost())
        return;
    WebGLTexture* tex = validateTextureBinding("texParameter", target, false);
    if (!tex)
        return;
    switch (pname) {
    case GL_TEXTURE_MIN_FILTER:
    case GL_TEXTURE_MAG_FILTER:
        break;
    case GL_TEXTURE_WRAP_S:
    case GL_TEXTURE_WRAP_T:
        if ((isFloat && paramf != GL_CLAMP_TO_EDGE && paramf != GL_MIRRORED_REPEAT && paramf != GL_REPEAT)
            || (!isFloat && parami != GL_CLAMP_TO_EDGE && parami != GL_MIRRORED_REPEAT && parami != GL_REPEAT)) {
            synthesizeGLError(GL_INVALID_ENUM, "texParameter", "invalid parameter");
            return;
        }
        break;
    case GL_TEXTURE_MAX_ANISOTROPY_EXT: // EXT_texture_filter_anisotropic
        if (!extensionEnabled(EXTTextureFilterAnisotropicName)) {
            synthesizeGLError(GL_INVALID_ENUM, "texParameter", "invalid parameter, EXT_texture_filter_anisotropic not enabled");
            return;
        }
        break;
    default:
        synthesizeGLError(GL_INVALID_ENUM, "texParameter", "invalid parameter name");
        return;
    }
    if (isFloat) {
        tex->setParameterf(pname, paramf);
        webContext()->texParameterf(target, pname, paramf);
    } else {
        tex->setParameteri(pname, parami);
        webContext()->texParameteri(target, pname, parami);
    }
}

void WebGLRenderingContextBase::texParameterf(GLenum target, GLenum pname, GLfloat param)
{
    texParameter(target, pname, param, 0, true);
}

void WebGLRenderingContextBase::texParameteri(GLenum target, GLenum pname, GLint param)
{
    texParameter(target, pname, 0, param, false);
}

void WebGLRenderingContextBase::texSubImage2DBase(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const void* pixels, ExceptionState& exceptionState)
{
    // FIXME: Handle errors.
    ASSERT(!isContextLost());
    ASSERT(validateTexFuncParameters("texSubImage2D", TexSubImage2D, target, level, format, width, height, 0, format, type));
    ASSERT(validateSize("texSubImage2D", xoffset, yoffset));
    ASSERT(validateSettableTexFormat("texSubImage2D", format));
    WebGLTexture* tex = validateTextureBinding("texSubImage2D", target, true);
    if (!tex) {
        ASSERT_NOT_REACHED();
        return;
    }
    ASSERT((xoffset + width) >= 0);
    ASSERT((yoffset + height) >= 0);
    ASSERT(tex->getWidth(target, level) >= (xoffset + width));
    ASSERT(tex->getHeight(target, level) >= (yoffset + height));
    ASSERT(tex->getInternalFormat(target, level) == format);
    ASSERT(tex->getType(target, level) == type);
    webContext()->texSubImage2D(target, level, xoffset, yoffset, width, height, format, type, pixels);
}

void WebGLRenderingContextBase::texSubImage2DImpl(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLenum format, GLenum type, Image* image, WebGLImageConversion::ImageHtmlDomSource domSource, bool flipY, bool premultiplyAlpha, ExceptionState& exceptionState)
{
    // All calling functions check isContextLost, so a duplicate check is not needed here.
    Vector<uint8_t> data;
    WebGLImageConversion::ImageExtractor imageExtractor(image, domSource, premultiplyAlpha, m_unpackColorspaceConversion == GL_NONE);
    if (!imageExtractor.extractSucceeded()) {
        synthesizeGLError(GL_INVALID_VALUE, "texSubImage2D", "bad image");
        return;
    }
    WebGLImageConversion::DataFormat sourceDataFormat = imageExtractor.imageSourceFormat();
    WebGLImageConversion::AlphaOp alphaOp = imageExtractor.imageAlphaOp();
    const void* imagePixelData = imageExtractor.imagePixelData();

    bool needConversion = true;
    if (type == GL_UNSIGNED_BYTE && sourceDataFormat == WebGLImageConversion::DataFormatRGBA8 && format == GL_RGBA && alphaOp == WebGLImageConversion::AlphaDoNothing && !flipY)
        needConversion = false;
    else {
        if (!WebGLImageConversion::packImageData(image, imagePixelData, format, type, flipY, alphaOp, sourceDataFormat, imageExtractor.imageWidth(), imageExtractor.imageHeight(), imageExtractor.imageSourceUnpackAlignment(), data)) {
            synthesizeGLError(GL_INVALID_VALUE, "texSubImage2D", "bad image data");
            return;
        }
    }

    if (m_unpackAlignment != 1)
        webContext()->pixelStorei(GL_UNPACK_ALIGNMENT, 1);
    texSubImage2DBase(target, level, xoffset, yoffset, imageExtractor.imageWidth(), imageExtractor.imageHeight(), format, type,  needConversion ? data.data() : imagePixelData, exceptionState);
    if (m_unpackAlignment != 1)
        webContext()->pixelStorei(GL_UNPACK_ALIGNMENT, m_unpackAlignment);
}

void WebGLRenderingContextBase::texSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset,
    GLsizei width, GLsizei height,
    GLenum format, GLenum type, ArrayBufferView* pixels, ExceptionState& exceptionState)
{
    if (isContextLost() || !validateTexFuncData("texSubImage2D", level, width, height, format, type, pixels, NullNotAllowed)
        || !validateTexFunc("texSubImage2D", TexSubImage2D, SourceArrayBufferView, target, level, format, width, height, 0, format, type, xoffset, yoffset))
        return;
    void* data = pixels->baseAddress();
    Vector<uint8_t> tempData;
    bool changeUnpackAlignment = false;
    if (data && (m_unpackFlipY || m_unpackPremultiplyAlpha)) {
        if (!WebGLImageConversion::extractTextureData(width, height, format, type,
                                           m_unpackAlignment,
                                           m_unpackFlipY, m_unpackPremultiplyAlpha,
                                           data,
                                           tempData))
            return;
        data = tempData.data();
        changeUnpackAlignment = true;
    }
    if (changeUnpackAlignment)
        webContext()->pixelStorei(GL_UNPACK_ALIGNMENT, 1);
    texSubImage2DBase(target, level, xoffset, yoffset, width, height, format, type, data, exceptionState);
    if (changeUnpackAlignment)
        webContext()->pixelStorei(GL_UNPACK_ALIGNMENT, m_unpackAlignment);
}

void WebGLRenderingContextBase::texSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset,
    GLenum format, GLenum type, ImageData* pixels, ExceptionState& exceptionState)
{
    if (isContextLost() || !pixels || !validateTexFunc("texSubImage2D", TexSubImage2D, SourceImageData, target, level, format,  pixels->width(), pixels->height(), 0, format, type, xoffset, yoffset))
        return;

    Vector<uint8_t> data;
    bool needConversion = true;
    // The data from ImageData is always of format RGBA8.
    // No conversion is needed if destination format is RGBA and type is USIGNED_BYTE and no Flip or Premultiply operation is required.
    if (format == GL_RGBA && type == GL_UNSIGNED_BYTE && !m_unpackFlipY && !m_unpackPremultiplyAlpha)
        needConversion = false;
    else {
        if (!WebGLImageConversion::extractImageData(pixels->data()->data(), pixels->size(), format, type, m_unpackFlipY, m_unpackPremultiplyAlpha, data)) {
            synthesizeGLError(GL_INVALID_VALUE, "texSubImage2D", "bad image data");
            return;
        }
    }
    if (m_unpackAlignment != 1)
        webContext()->pixelStorei(GL_UNPACK_ALIGNMENT, 1);
    texSubImage2DBase(target, level, xoffset, yoffset, pixels->width(), pixels->height(), format, type, needConversion ? data.data() : pixels->data()->data(), exceptionState);
    if (m_unpackAlignment != 1)
        webContext()->pixelStorei(GL_UNPACK_ALIGNMENT, m_unpackAlignment);
}

void WebGLRenderingContextBase::texSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset,
    GLenum format, GLenum type, HTMLImageElement* image, ExceptionState& exceptionState)
{
    if (isContextLost() || !validateHTMLImageElement("texSubImage2D", image, exceptionState))
        return;

    RefPtr<Image> imageForRender = image->cachedImage()->imageForRenderer(image->renderer());
    if (!imageForRender || !validateTexFunc("texSubImage2D", TexSubImage2D, SourceHTMLImageElement, target, level, format, imageForRender->width(), imageForRender->height(), 0, format, type, xoffset, yoffset))
        return;

    texSubImage2DImpl(target, level, xoffset, yoffset, format, type, imageForRender.get(), WebGLImageConversion::HtmlDomImage, m_unpackFlipY, m_unpackPremultiplyAlpha, exceptionState);
}

void WebGLRenderingContextBase::texSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset,
    GLenum format, GLenum type, HTMLCanvasElement* canvas, ExceptionState& exceptionState)
{
    if (isContextLost() || !validateHTMLCanvasElement("texSubImage2D", canvas, exceptionState)
        || !validateTexFunc("texSubImage2D", TexSubImage2D, SourceHTMLCanvasElement, target, level, format, canvas->width(), canvas->height(), 0, format, type, xoffset, yoffset))
        return;

    RefPtrWillBeRawPtr<ImageData> imageData = canvas->getImageData();
    if (imageData)
        texSubImage2D(target, level, xoffset, yoffset, format, type, imageData.get(), exceptionState);
    else
        texSubImage2DImpl(target, level, xoffset, yoffset, format, type, canvas->copiedImage(), WebGLImageConversion::HtmlDomCanvas, m_unpackFlipY, m_unpackPremultiplyAlpha, exceptionState);
}

void WebGLRenderingContextBase::texSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset,
    GLenum format, GLenum type, HTMLVideoElement* video, ExceptionState& exceptionState)
{
    if (isContextLost() || !validateHTMLVideoElement("texSubImage2D", video, exceptionState)
        || !validateTexFunc("texSubImage2D", TexSubImage2D, SourceHTMLVideoElement, target, level, format, video->videoWidth(), video->videoHeight(), 0, format, type, xoffset, yoffset))
        return;

    RefPtr<Image> image = videoFrameToImage(video, ImageBuffer::fastCopyImageMode());
    if (!image)
        return;
    texSubImage2DImpl(target, level, xoffset, yoffset, format, type, image.get(), WebGLImageConversion::HtmlDomVideo, m_unpackFlipY, m_unpackPremultiplyAlpha, exceptionState);
}

void WebGLRenderingContextBase::uniform1f(const WebGLUniformLocation* location, GLfloat x)
{
    if (isContextLost() || !location)
        return;

    if (location->program() != m_currentProgram) {
        synthesizeGLError(GL_INVALID_OPERATION, "uniform1f", "location not for current program");
        return;
    }

    webContext()->uniform1f(location->location(), x);
}

void WebGLRenderingContextBase::uniform1fv(const WebGLUniformLocation* location, Float32Array* v)
{
    if (isContextLost() || !validateUniformParameters("uniform1fv", location, v, 1))
        return;

    webContext()->uniform1fv(location->location(), v->length(), v->data());
}

void WebGLRenderingContextBase::uniform1fv(const WebGLUniformLocation* location, GLfloat* v, GLsizei size)
{
    if (isContextLost() || !validateUniformParameters("uniform1fv", location, v, size, 1))
        return;

    webContext()->uniform1fv(location->location(), size, v);
}

void WebGLRenderingContextBase::uniform1i(const WebGLUniformLocation* location, GLint x)
{
    if (isContextLost() || !location)
        return;

    if (location->program() != m_currentProgram) {
        synthesizeGLError(GL_INVALID_OPERATION, "uniform1i", "location not for current program");
        return;
    }

    webContext()->uniform1i(location->location(), x);
}

void WebGLRenderingContextBase::uniform1iv(const WebGLUniformLocation* location, Int32Array* v)
{
    if (isContextLost() || !validateUniformParameters("uniform1iv", location, v, 1))
        return;

    webContext()->uniform1iv(location->location(), v->length(), v->data());
}

void WebGLRenderingContextBase::uniform1iv(const WebGLUniformLocation* location, GLint* v, GLsizei size)
{
    if (isContextLost() || !validateUniformParameters("uniform1iv", location, v, size, 1))
        return;

    webContext()->uniform1iv(location->location(), size, v);
}

void WebGLRenderingContextBase::uniform2f(const WebGLUniformLocation* location, GLfloat x, GLfloat y)
{
    if (isContextLost() || !location)
        return;

    if (location->program() != m_currentProgram) {
        synthesizeGLError(GL_INVALID_OPERATION, "uniform2f", "location not for current program");
        return;
    }

    webContext()->uniform2f(location->location(), x, y);
}

void WebGLRenderingContextBase::uniform2fv(const WebGLUniformLocation* location, Float32Array* v)
{
    if (isContextLost() || !validateUniformParameters("uniform2fv", location, v, 2))
        return;

    webContext()->uniform2fv(location->location(), v->length() >> 1, v->data());
}

void WebGLRenderingContextBase::uniform2fv(const WebGLUniformLocation* location, GLfloat* v, GLsizei size)
{
    if (isContextLost() || !validateUniformParameters("uniform2fv", location, v, size, 2))
        return;

    webContext()->uniform2fv(location->location(), size >> 1, v);
}

void WebGLRenderingContextBase::uniform2i(const WebGLUniformLocation* location, GLint x, GLint y)
{
    if (isContextLost() || !location)
        return;

    if (location->program() != m_currentProgram) {
        synthesizeGLError(GL_INVALID_OPERATION, "uniform2i", "location not for current program");
        return;
    }

    webContext()->uniform2i(location->location(), x, y);
}

void WebGLRenderingContextBase::uniform2iv(const WebGLUniformLocation* location, Int32Array* v)
{
    if (isContextLost() || !validateUniformParameters("uniform2iv", location, v, 2))
        return;

    webContext()->uniform2iv(location->location(), v->length() >> 1, v->data());
}

void WebGLRenderingContextBase::uniform2iv(const WebGLUniformLocation* location, GLint* v, GLsizei size)
{
    if (isContextLost() || !validateUniformParameters("uniform2iv", location, v, size, 2))
        return;

    webContext()->uniform2iv(location->location(), size >> 1, v);
}

void WebGLRenderingContextBase::uniform3f(const WebGLUniformLocation* location, GLfloat x, GLfloat y, GLfloat z)
{
    if (isContextLost() || !location)
        return;

    if (location->program() != m_currentProgram) {
        synthesizeGLError(GL_INVALID_OPERATION, "uniform3f", "location not for current program");
        return;
    }

    webContext()->uniform3f(location->location(), x, y, z);
}

void WebGLRenderingContextBase::uniform3fv(const WebGLUniformLocation* location, Float32Array* v)
{
    if (isContextLost() || !validateUniformParameters("uniform3fv", location, v, 3))
        return;

    webContext()->uniform3fv(location->location(), v->length() / 3, v->data());
}

void WebGLRenderingContextBase::uniform3fv(const WebGLUniformLocation* location, GLfloat* v, GLsizei size)
{
    if (isContextLost() || !validateUniformParameters("uniform3fv", location, v, size, 3))
        return;

    webContext()->uniform3fv(location->location(), size / 3, v);
}

void WebGLRenderingContextBase::uniform3i(const WebGLUniformLocation* location, GLint x, GLint y, GLint z)
{
    if (isContextLost() || !location)
        return;

    if (location->program() != m_currentProgram) {
        synthesizeGLError(GL_INVALID_OPERATION, "uniform3i", "location not for current program");
        return;
    }

    webContext()->uniform3i(location->location(), x, y, z);
}

void WebGLRenderingContextBase::uniform3iv(const WebGLUniformLocation* location, Int32Array* v)
{
    if (isContextLost() || !validateUniformParameters("uniform3iv", location, v, 3))
        return;

    webContext()->uniform3iv(location->location(), v->length() / 3, v->data());
}

void WebGLRenderingContextBase::uniform3iv(const WebGLUniformLocation* location, GLint* v, GLsizei size)
{
    if (isContextLost() || !validateUniformParameters("uniform3iv", location, v, size, 3))
        return;

    webContext()->uniform3iv(location->location(), size / 3, v);
}

void WebGLRenderingContextBase::uniform4f(const WebGLUniformLocation* location, GLfloat x, GLfloat y, GLfloat z, GLfloat w)
{
    if (isContextLost() || !location)
        return;

    if (location->program() != m_currentProgram) {
        synthesizeGLError(GL_INVALID_OPERATION, "uniform4f", "location not for current program");
        return;
    }

    webContext()->uniform4f(location->location(), x, y, z, w);
}

void WebGLRenderingContextBase::uniform4fv(const WebGLUniformLocation* location, Float32Array* v)
{
    if (isContextLost() || !validateUniformParameters("uniform4fv", location, v, 4))
        return;

    webContext()->uniform4fv(location->location(), v->length() >> 2, v->data());
}

void WebGLRenderingContextBase::uniform4fv(const WebGLUniformLocation* location, GLfloat* v, GLsizei size)
{
    if (isContextLost() || !validateUniformParameters("uniform4fv", location, v, size, 4))
        return;

    webContext()->uniform4fv(location->location(), size >> 2, v);
}

void WebGLRenderingContextBase::uniform4i(const WebGLUniformLocation* location, GLint x, GLint y, GLint z, GLint w)
{
    if (isContextLost() || !location)
        return;

    if (location->program() != m_currentProgram) {
        synthesizeGLError(GL_INVALID_OPERATION, "uniform4i", "location not for current program");
        return;
    }

    webContext()->uniform4i(location->location(), x, y, z, w);
}

void WebGLRenderingContextBase::uniform4iv(const WebGLUniformLocation* location, Int32Array* v)
{
    if (isContextLost() || !validateUniformParameters("uniform4iv", location, v, 4))
        return;

    webContext()->uniform4iv(location->location(), v->length() >> 2, v->data());
}

void WebGLRenderingContextBase::uniform4iv(const WebGLUniformLocation* location, GLint* v, GLsizei size)
{
    if (isContextLost() || !validateUniformParameters("uniform4iv", location, v, size, 4))
        return;

    webContext()->uniform4iv(location->location(), size >> 2, v);
}

void WebGLRenderingContextBase::uniformMatrix2fv(const WebGLUniformLocation* location, GLboolean transpose, Float32Array* v)
{
    if (isContextLost() || !validateUniformMatrixParameters("uniformMatrix2fv", location, transpose, v, 4))
        return;
    webContext()->uniformMatrix2fv(location->location(), v->length() >> 2, transpose, v->data());
}

void WebGLRenderingContextBase::uniformMatrix2fv(const WebGLUniformLocation* location, GLboolean transpose, GLfloat* v, GLsizei size)
{
    if (isContextLost() || !validateUniformMatrixParameters("uniformMatrix2fv", location, transpose, v, size, 4))
        return;
    webContext()->uniformMatrix2fv(location->location(), size >> 2, transpose, v);
}

void WebGLRenderingContextBase::uniformMatrix3fv(const WebGLUniformLocation* location, GLboolean transpose, Float32Array* v)
{
    if (isContextLost() || !validateUniformMatrixParameters("uniformMatrix3fv", location, transpose, v, 9))
        return;
    webContext()->uniformMatrix3fv(location->location(), v->length() / 9, transpose, v->data());
}

void WebGLRenderingContextBase::uniformMatrix3fv(const WebGLUniformLocation* location, GLboolean transpose, GLfloat* v, GLsizei size)
{
    if (isContextLost() || !validateUniformMatrixParameters("uniformMatrix3fv", location, transpose, v, size, 9))
        return;
    webContext()->uniformMatrix3fv(location->location(), size / 9, transpose, v);
}

void WebGLRenderingContextBase::uniformMatrix4fv(const WebGLUniformLocation* location, GLboolean transpose, Float32Array* v)
{
    if (isContextLost() || !validateUniformMatrixParameters("uniformMatrix4fv", location, transpose, v, 16))
        return;
    webContext()->uniformMatrix4fv(location->location(), v->length() >> 4, transpose, v->data());
}

void WebGLRenderingContextBase::uniformMatrix4fv(const WebGLUniformLocation* location, GLboolean transpose, GLfloat* v, GLsizei size)
{
    if (isContextLost() || !validateUniformMatrixParameters("uniformMatrix4fv", location, transpose, v, size, 16))
        return;
    webContext()->uniformMatrix4fv(location->location(), size >> 4, transpose, v);
}

void WebGLRenderingContextBase::useProgram(WebGLProgram* program)
{
    bool deleted;
    if (!checkObjectToBeBound("useProgram", program, deleted))
        return;
    if (deleted)
        program = 0;
    if (program && !program->linkStatus()) {
        synthesizeGLError(GL_INVALID_OPERATION, "useProgram", "program not valid");
        return;
    }
    if (m_currentProgram != program) {
        if (m_currentProgram)
            m_currentProgram->onDetached(webContext());
        m_currentProgram = program;
        webContext()->useProgram(objectOrZero(program));
        if (program)
            program->onAttached();
    }
}

void WebGLRenderingContextBase::validateProgram(WebGLProgram* program)
{
    if (isContextLost() || !validateWebGLObject("validateProgram", program))
        return;
    webContext()->validateProgram(objectOrZero(program));
}

void WebGLRenderingContextBase::vertexAttrib1f(GLuint index, GLfloat v0)
{
    vertexAttribfImpl("vertexAttrib1f", index, 1, v0, 0.0f, 0.0f, 1.0f);
}

void WebGLRenderingContextBase::vertexAttrib1fv(GLuint index, Float32Array* v)
{
    vertexAttribfvImpl("vertexAttrib1fv", index, v, 1);
}

void WebGLRenderingContextBase::vertexAttrib1fv(GLuint index, GLfloat* v, GLsizei size)
{
    vertexAttribfvImpl("vertexAttrib1fv", index, v, size, 1);
}

void WebGLRenderingContextBase::vertexAttrib2f(GLuint index, GLfloat v0, GLfloat v1)
{
    vertexAttribfImpl("vertexAttrib2f", index, 2, v0, v1, 0.0f, 1.0f);
}

void WebGLRenderingContextBase::vertexAttrib2fv(GLuint index, Float32Array* v)
{
    vertexAttribfvImpl("vertexAttrib2fv", index, v, 2);
}

void WebGLRenderingContextBase::vertexAttrib2fv(GLuint index, GLfloat* v, GLsizei size)
{
    vertexAttribfvImpl("vertexAttrib2fv", index, v, size, 2);
}

void WebGLRenderingContextBase::vertexAttrib3f(GLuint index, GLfloat v0, GLfloat v1, GLfloat v2)
{
    vertexAttribfImpl("vertexAttrib3f", index, 3, v0, v1, v2, 1.0f);
}

void WebGLRenderingContextBase::vertexAttrib3fv(GLuint index, Float32Array* v)
{
    vertexAttribfvImpl("vertexAttrib3fv", index, v, 3);
}

void WebGLRenderingContextBase::vertexAttrib3fv(GLuint index, GLfloat* v, GLsizei size)
{
    vertexAttribfvImpl("vertexAttrib3fv", index, v, size, 3);
}

void WebGLRenderingContextBase::vertexAttrib4f(GLuint index, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3)
{
    vertexAttribfImpl("vertexAttrib4f", index, 4, v0, v1, v2, v3);
}

void WebGLRenderingContextBase::vertexAttrib4fv(GLuint index, Float32Array* v)
{
    vertexAttribfvImpl("vertexAttrib4fv", index, v, 4);
}

void WebGLRenderingContextBase::vertexAttrib4fv(GLuint index, GLfloat* v, GLsizei size)
{
    vertexAttribfvImpl("vertexAttrib4fv", index, v, size, 4);
}

void WebGLRenderingContextBase::vertexAttribPointer(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, long long offset)
{
    if (isContextLost())
        return;
    switch (type) {
    case GL_BYTE:
    case GL_UNSIGNED_BYTE:
    case GL_SHORT:
    case GL_UNSIGNED_SHORT:
    case GL_FLOAT:
        break;
    default:
        synthesizeGLError(GL_INVALID_ENUM, "vertexAttribPointer", "invalid type");
        return;
    }
    if (index >= m_maxVertexAttribs) {
        synthesizeGLError(GL_INVALID_VALUE, "vertexAttribPointer", "index out of range");
        return;
    }
    if (size < 1 || size > 4 || stride < 0 || stride > 255) {
        synthesizeGLError(GL_INVALID_VALUE, "vertexAttribPointer", "bad size or stride");
        return;
    }
    if (!validateValueFitNonNegInt32("vertexAttribPointer", "offset", offset))
        return;
    if (!m_boundArrayBuffer) {
        synthesizeGLError(GL_INVALID_OPERATION, "vertexAttribPointer", "no bound ARRAY_BUFFER");
        return;
    }
    unsigned typeSize = sizeInBytes(type);
    ASSERT((typeSize & (typeSize - 1)) == 0); // Ensure that the value is POT.
    if ((stride & (typeSize - 1)) || (static_cast<GLintptr>(offset) & (typeSize - 1))) {
        synthesizeGLError(GL_INVALID_OPERATION, "vertexAttribPointer", "stride or offset not valid for type");
        return;
    }
    GLsizei bytesPerElement = size * typeSize;

    m_boundVertexArrayObject->setVertexAttribState(index, bytesPerElement, size, type, normalized, stride, static_cast<GLintptr>(offset), m_boundArrayBuffer);
    webContext()->vertexAttribPointer(index, size, type, normalized, stride, static_cast<GLintptr>(offset));
}

void WebGLRenderingContextBase::vertexAttribDivisorANGLE(GLuint index, GLuint divisor)
{
    if (isContextLost())
        return;

    if (index >= m_maxVertexAttribs) {
        synthesizeGLError(GL_INVALID_VALUE, "vertexAttribDivisorANGLE", "index out of range");
        return;
    }

    m_boundVertexArrayObject->setVertexAttribDivisor(index, divisor);
    webContext()->vertexAttribDivisorANGLE(index, divisor);
}

void WebGLRenderingContextBase::viewport(GLint x, GLint y, GLsizei width, GLsizei height)
{
    if (isContextLost())
        return;
    if (!validateSize("viewport", width, height))
        return;
    webContext()->viewport(x, y, width, height);
}

void WebGLRenderingContextBase::forceLostContext(LostContextMode mode, AutoRecoveryMethod autoRecoveryMethod)
{
    if (isContextLost()) {
        synthesizeGLError(GL_INVALID_OPERATION, "loseContext", "context already lost");
        return;
    }

    m_contextGroup->loseContextGroup(mode, autoRecoveryMethod);
}

void WebGLRenderingContextBase::loseContextImpl(WebGLRenderingContextBase::LostContextMode mode, AutoRecoveryMethod autoRecoveryMethod)
{
    if (isContextLost())
        return;

    m_contextLostMode = mode;
    ASSERT(m_contextLostMode != NotLostContext);
    m_autoRecoveryMethod = autoRecoveryMethod;

    if (mode == RealLostContext) {
        // Inform the embedder that a lost context was received. In response, the embedder might
        // decide to take action such as asking the user for permission to use WebGL again.
        if (LocalFrame* frame = canvas()->document().frame())
            frame->loaderClient()->didLoseWebGLContext(webContext()->getGraphicsResetStatusARB());
    }

    // Make absolutely sure we do not refer to an already-deleted texture or framebuffer.
    drawingBuffer()->setTexture2DBinding(0);
    drawingBuffer()->setFramebufferBinding(0);

    detachAndRemoveAllObjects();

    // Lose all the extensions.
    for (size_t i = 0; i < m_extensions.size(); ++i) {
        ExtensionTracker* tracker = m_extensions[i].get();
        tracker->loseExtension();
    }

    for (size_t i = 0; i < WebGLExtensionNameCount; ++i)
        m_extensionEnabled[i] = false;

    removeAllCompressedTextureFormats();

    if (mode != RealLostContext)
        destroyContext();

    ConsoleDisplayPreference display = (mode == RealLostContext) ? DisplayInConsole: DontDisplayInConsole;
    synthesizeGLError(GC3D_CONTEXT_LOST_WEBGL, "loseContext", "context lost", display);

    // Don't allow restoration unless the context lost event has both been
    // dispatched and its default behavior prevented.
    m_restoreAllowed = false;
    deactivateContext(this);
    if (m_autoRecoveryMethod == WhenAvailable)
        addToEvictedList(this);

    // Always defer the dispatch of the context lost event, to implement
    // the spec behavior of queueing a task.
    m_dispatchContextLostEventTimer.startOneShot(0, FROM_HERE);
}

void WebGLRenderingContextBase::forceRestoreContext()
{
    if (!isContextLost()) {
        synthesizeGLError(GL_INVALID_OPERATION, "restoreContext", "context not lost");
        return;
    }

    if (!m_restoreAllowed) {
        if (m_contextLostMode == WebGLLoseContextLostContext)
            synthesizeGLError(GL_INVALID_OPERATION, "restoreContext", "context restoration not allowed");
        return;
    }

    if (!m_restoreTimer.isActive())
        m_restoreTimer.startOneShot(0, FROM_HERE);
}

blink::WebLayer* WebGLRenderingContextBase::platformLayer() const
{
    return isContextLost() ? 0 : drawingBuffer()->platformLayer();
}

Extensions3DUtil* WebGLRenderingContextBase::extensionsUtil()
{
    ASSERT(!isContextLost());
    if (!m_extensionsUtil)
        m_extensionsUtil = Extensions3DUtil::create(webContext());
    return m_extensionsUtil.get();
}

void WebGLRenderingContextBase::removeSharedObject(WebGLSharedObject* object)
{
    m_contextGroup->removeObject(object);
}

void WebGLRenderingContextBase::addSharedObject(WebGLSharedObject* object)
{
    ASSERT(!isContextLost());
    m_contextGroup->addObject(object);
}

void WebGLRenderingContextBase::removeContextObject(WebGLContextObject* object)
{
    m_contextObjects.remove(object);
}

void WebGLRenderingContextBase::addContextObject(WebGLContextObject* object)
{
    ASSERT(!isContextLost());
    m_contextObjects.add(object);
}

void WebGLRenderingContextBase::detachAndRemoveAllObjects()
{
    while (m_contextObjects.size() > 0) {
        WillBeHeapHashSet<RawPtrWillBeWeakMember<WebGLContextObject> >::iterator it = m_contextObjects.begin();
        (*it)->detachContext();
    }
}

bool WebGLRenderingContextBase::hasPendingActivity() const
{
    return false;
}

void WebGLRenderingContextBase::stop()
{
    if (!isContextLost()) {
        // Never attempt to restore the context because the page is being torn down.
        forceLostContext(SyntheticLostContext, Manual);
    }
}

WebGLGetInfo WebGLRenderingContextBase::getBooleanParameter(GLenum pname)
{
    GLboolean value = 0;
    if (!isContextLost())
        webContext()->getBooleanv(pname, &value);
    return WebGLGetInfo(static_cast<bool>(value));
}

WebGLGetInfo WebGLRenderingContextBase::getBooleanArrayParameter(GLenum pname)
{
    if (pname != GL_COLOR_WRITEMASK) {
        notImplemented();
        return WebGLGetInfo(0, 0);
    }
    GLboolean value[4] = {0};
    if (!isContextLost())
        webContext()->getBooleanv(pname, value);
    bool boolValue[4];
    for (int ii = 0; ii < 4; ++ii)
        boolValue[ii] = static_cast<bool>(value[ii]);
    return WebGLGetInfo(boolValue, 4);
}

WebGLGetInfo WebGLRenderingContextBase::getFloatParameter(GLenum pname)
{
    GLfloat value = 0;
    if (!isContextLost())
        webContext()->getFloatv(pname, &value);
    return WebGLGetInfo(value);
}

WebGLGetInfo WebGLRenderingContextBase::getIntParameter(GLenum pname)
{
    GLint value = 0;
    if (!isContextLost())
        webContext()->getIntegerv(pname, &value);
    return WebGLGetInfo(value);
}

WebGLGetInfo WebGLRenderingContextBase::getUnsignedIntParameter(GLenum pname)
{
    GLint value = 0;
    if (!isContextLost())
        webContext()->getIntegerv(pname, &value);
    return WebGLGetInfo(static_cast<unsigned>(value));
}

WebGLGetInfo WebGLRenderingContextBase::getWebGLFloatArrayParameter(GLenum pname)
{
    GLfloat value[4] = {0};
    if (!isContextLost())
        webContext()->getFloatv(pname, value);
    unsigned length = 0;
    switch (pname) {
    case GL_ALIASED_POINT_SIZE_RANGE:
    case GL_ALIASED_LINE_WIDTH_RANGE:
    case GL_DEPTH_RANGE:
        length = 2;
        break;
    case GL_BLEND_COLOR:
    case GL_COLOR_CLEAR_VALUE:
        length = 4;
        break;
    default:
        notImplemented();
    }
    return WebGLGetInfo(Float32Array::create(value, length));
}

WebGLGetInfo WebGLRenderingContextBase::getWebGLIntArrayParameter(GLenum pname)
{
    GLint value[4] = {0};
    if (!isContextLost())
        webContext()->getIntegerv(pname, value);
    unsigned length = 0;
    switch (pname) {
    case GL_MAX_VIEWPORT_DIMS:
        length = 2;
        break;
    case GL_SCISSOR_BOX:
    case GL_VIEWPORT:
        length = 4;
        break;
    default:
        notImplemented();
    }
    return WebGLGetInfo(Int32Array::create(value, length));
}

void WebGLRenderingContextBase::handleTextureCompleteness(const char* functionName, bool prepareToDraw)
{
    // All calling functions check isContextLost, so a duplicate check is not needed here.
    bool resetActiveUnit = false;
    WebGLTexture::TextureExtensionFlag flag = static_cast<WebGLTexture::TextureExtensionFlag>((extensionEnabled(OESTextureFloatLinearName) ? WebGLTexture::TextureFloatLinearExtensionEnabled : 0)
        | (extensionEnabled(OESTextureHalfFloatLinearName) ? WebGLTexture::TextureHalfFloatLinearExtensionEnabled : 0));
    for (unsigned ii = 0; ii < m_onePlusMaxNonDefaultTextureUnit; ++ii) {
        if ((m_textureUnits[ii].m_texture2DBinding.get() && m_textureUnits[ii].m_texture2DBinding->needToUseBlackTexture(flag))
            || (m_textureUnits[ii].m_textureCubeMapBinding.get() && m_textureUnits[ii].m_textureCubeMapBinding->needToUseBlackTexture(flag))) {
            if (ii != m_activeTextureUnit) {
                webContext()->activeTexture(GL_TEXTURE0 + ii);
                resetActiveUnit = true;
            } else if (resetActiveUnit) {
                webContext()->activeTexture(GL_TEXTURE0 + ii);
                resetActiveUnit = false;
            }
            WebGLTexture* tex2D;
            WebGLTexture* texCubeMap;
            if (prepareToDraw) {
                String msg(String("texture bound to texture unit ") + String::number(ii)
                    + " is not renderable. It maybe non-power-of-2 and have incompatible texture filtering or is not 'texture complete'."
                    + " Or the texture is Float or Half Float type with linear filtering while OES_float_linear or OES_half_float_linear extension is not enabled.");
                emitGLWarning(functionName, msg.utf8().data());
                tex2D = m_blackTexture2D.get();
                texCubeMap = m_blackTextureCubeMap.get();
            } else {
                tex2D = m_textureUnits[ii].m_texture2DBinding.get();
                texCubeMap = m_textureUnits[ii].m_textureCubeMapBinding.get();
            }
            if (m_textureUnits[ii].m_texture2DBinding && m_textureUnits[ii].m_texture2DBinding->needToUseBlackTexture(flag))
                webContext()->bindTexture(GL_TEXTURE_2D, objectOrZero(tex2D));
            if (m_textureUnits[ii].m_textureCubeMapBinding && m_textureUnits[ii].m_textureCubeMapBinding->needToUseBlackTexture(flag))
                webContext()->bindTexture(GL_TEXTURE_CUBE_MAP, objectOrZero(texCubeMap));
        }
    }
    if (resetActiveUnit)
        webContext()->activeTexture(GL_TEXTURE0 + m_activeTextureUnit);
}

void WebGLRenderingContextBase::createFallbackBlackTextures1x1()
{
    // All calling functions check isContextLost, so a duplicate check is not needed here.
    unsigned char black[] = {0, 0, 0, 255};
    m_blackTexture2D = createTexture();
    webContext()->bindTexture(GL_TEXTURE_2D, m_blackTexture2D->object());
    webContext()->texImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1,
        0, GL_RGBA, GL_UNSIGNED_BYTE, black);
    webContext()->bindTexture(GL_TEXTURE_2D, 0);
    m_blackTextureCubeMap = createTexture();
    webContext()->bindTexture(GL_TEXTURE_CUBE_MAP, m_blackTextureCubeMap->object());
    webContext()->texImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, 0, GL_RGBA, 1, 1,
        0, GL_RGBA, GL_UNSIGNED_BYTE, black);
    webContext()->texImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 0, GL_RGBA, 1, 1,
        0, GL_RGBA, GL_UNSIGNED_BYTE, black);
    webContext()->texImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, 0, GL_RGBA, 1, 1,
        0, GL_RGBA, GL_UNSIGNED_BYTE, black);
    webContext()->texImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, 0, GL_RGBA, 1, 1,
        0, GL_RGBA, GL_UNSIGNED_BYTE, black);
    webContext()->texImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, 0, GL_RGBA, 1, 1,
        0, GL_RGBA, GL_UNSIGNED_BYTE, black);
    webContext()->texImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, 0, GL_RGBA, 1, 1,
        0, GL_RGBA, GL_UNSIGNED_BYTE, black);
    webContext()->bindTexture(GL_TEXTURE_CUBE_MAP, 0);
}

bool WebGLRenderingContextBase::isTexInternalFormatColorBufferCombinationValid(GLenum texInternalFormat, GLenum colorBufferFormat)
{
    unsigned need = WebGLImageConversion::getChannelBitsByFormat(texInternalFormat);
    unsigned have = WebGLImageConversion::getChannelBitsByFormat(colorBufferFormat);
    return (need & have) == need;
}

GLenum WebGLRenderingContextBase::boundFramebufferColorFormat()
{
    if (m_framebufferBinding && m_framebufferBinding->object())
        return m_framebufferBinding->colorBufferFormat();
    if (m_requestedAttributes->alpha())
        return GL_RGBA;
    return GL_RGB;
}

WebGLTexture* WebGLRenderingContextBase::validateTextureBinding(const char* functionName, GLenum target, bool useSixEnumsForCubeMap)
{
    WebGLTexture* tex = 0;
    switch (target) {
    case GL_TEXTURE_2D:
        tex = m_textureUnits[m_activeTextureUnit].m_texture2DBinding.get();
        break;
    case GL_TEXTURE_CUBE_MAP_POSITIVE_X:
    case GL_TEXTURE_CUBE_MAP_NEGATIVE_X:
    case GL_TEXTURE_CUBE_MAP_POSITIVE_Y:
    case GL_TEXTURE_CUBE_MAP_NEGATIVE_Y:
    case GL_TEXTURE_CUBE_MAP_POSITIVE_Z:
    case GL_TEXTURE_CUBE_MAP_NEGATIVE_Z:
        if (!useSixEnumsForCubeMap) {
            synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid texture target");
            return 0;
        }
        tex = m_textureUnits[m_activeTextureUnit].m_textureCubeMapBinding.get();
        break;
    case GL_TEXTURE_CUBE_MAP:
        if (useSixEnumsForCubeMap) {
            synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid texture target");
            return 0;
        }
        tex = m_textureUnits[m_activeTextureUnit].m_textureCubeMapBinding.get();
        break;
    default:
        synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid texture target");
        return 0;
    }
    if (!tex)
        synthesizeGLError(GL_INVALID_OPERATION, functionName, "no texture");
    return tex;
}

bool WebGLRenderingContextBase::validateLocationLength(const char* functionName, const String& string)
{
    const unsigned maxWebGLLocationLength = 256;
    if (string.length() > maxWebGLLocationLength) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "location length > 256");
        return false;
    }
    return true;
}

bool WebGLRenderingContextBase::validateSize(const char* functionName, GLint x, GLint y)
{
    if (x < 0 || y < 0) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "size < 0");
        return false;
    }
    return true;
}

bool WebGLRenderingContextBase::validateString(const char* functionName, const String& string)
{
    for (size_t i = 0; i < string.length(); ++i) {
        if (!validateCharacter(string[i])) {
            synthesizeGLError(GL_INVALID_VALUE, functionName, "string not ASCII");
            return false;
        }
    }
    return true;
}

bool WebGLRenderingContextBase::validateTexFuncFormatAndType(const char* functionName, GLenum format, GLenum type, GLint level)
{
    switch (format) {
    case GL_ALPHA:
    case GL_LUMINANCE:
    case GL_LUMINANCE_ALPHA:
    case GL_RGB:
    case GL_RGBA:
        break;
    case GL_DEPTH_STENCIL_OES:
    case GL_DEPTH_COMPONENT:
        if (extensionEnabled(WebGLDepthTextureName))
            break;
        synthesizeGLError(GL_INVALID_ENUM, functionName, "depth texture formats not enabled");
        return false;
    default:
        synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid texture format");
        return false;
    }

    switch (type) {
    case GL_UNSIGNED_BYTE:
    case GL_UNSIGNED_SHORT_5_6_5:
    case GL_UNSIGNED_SHORT_4_4_4_4:
    case GL_UNSIGNED_SHORT_5_5_5_1:
        break;
    case GL_FLOAT:
        if (extensionEnabled(OESTextureFloatName))
            break;
        synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid texture type");
        return false;
    case GL_HALF_FLOAT_OES:
        if (extensionEnabled(OESTextureHalfFloatName))
            break;
        synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid texture type");
        return false;
    case GL_UNSIGNED_INT:
    case GL_UNSIGNED_INT_24_8_OES:
    case GL_UNSIGNED_SHORT:
        if (extensionEnabled(WebGLDepthTextureName))
            break;
        synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid texture type");
        return false;
    default:
        synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid texture type");
        return false;
    }

    // Verify that the combination of format and type is supported.
    switch (format) {
    case GL_ALPHA:
    case GL_LUMINANCE:
    case GL_LUMINANCE_ALPHA:
        if (type != GL_UNSIGNED_BYTE
            && type != GL_FLOAT
            && type != GL_HALF_FLOAT_OES) {
            synthesizeGLError(GL_INVALID_OPERATION, functionName, "invalid type for format");
            return false;
        }
        break;
    case GL_RGB:
        if (type != GL_UNSIGNED_BYTE
            && type != GL_UNSIGNED_SHORT_5_6_5
            && type != GL_FLOAT
            && type != GL_HALF_FLOAT_OES) {
            synthesizeGLError(GL_INVALID_OPERATION, functionName, "invalid type for RGB format");
            return false;
        }
        break;
    case GL_RGBA:
        if (type != GL_UNSIGNED_BYTE
            && type != GL_UNSIGNED_SHORT_4_4_4_4
            && type != GL_UNSIGNED_SHORT_5_5_5_1
            && type != GL_FLOAT
            && type != GL_HALF_FLOAT_OES) {
            synthesizeGLError(GL_INVALID_OPERATION, functionName, "invalid type for RGBA format");
            return false;
        }
        break;
    case GL_DEPTH_COMPONENT:
        if (!extensionEnabled(WebGLDepthTextureName)) {
            synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid format. DEPTH_COMPONENT not enabled");
            return false;
        }
        if (type != GL_UNSIGNED_SHORT
            && type != GL_UNSIGNED_INT) {
            synthesizeGLError(GL_INVALID_OPERATION, functionName, "invalid type for DEPTH_COMPONENT format");
            return false;
        }
        if (level > 0) {
            synthesizeGLError(GL_INVALID_OPERATION, functionName, "level must be 0 for DEPTH_COMPONENT format");
            return false;
        }
        break;
    case GL_DEPTH_STENCIL_OES:
        if (!extensionEnabled(WebGLDepthTextureName)) {
            synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid format. DEPTH_STENCIL not enabled");
            return false;
        }
        if (type != GL_UNSIGNED_INT_24_8_OES) {
            synthesizeGLError(GL_INVALID_OPERATION, functionName, "invalid type for DEPTH_STENCIL format");
            return false;
        }
        if (level > 0) {
            synthesizeGLError(GL_INVALID_OPERATION, functionName, "level must be 0 for DEPTH_STENCIL format");
            return false;
        }
        break;
    default:
        ASSERT_NOT_REACHED();
    }

    return true;
}

bool WebGLRenderingContextBase::validateTexFuncLevel(const char* functionName, GLenum target, GLint level)
{
    if (level < 0) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "level < 0");
        return false;
    }
    switch (target) {
    case GL_TEXTURE_2D:
        if (level >= m_maxTextureLevel) {
            synthesizeGLError(GL_INVALID_VALUE, functionName, "level out of range");
            return false;
        }
        break;
    case GL_TEXTURE_CUBE_MAP_POSITIVE_X:
    case GL_TEXTURE_CUBE_MAP_NEGATIVE_X:
    case GL_TEXTURE_CUBE_MAP_POSITIVE_Y:
    case GL_TEXTURE_CUBE_MAP_NEGATIVE_Y:
    case GL_TEXTURE_CUBE_MAP_POSITIVE_Z:
    case GL_TEXTURE_CUBE_MAP_NEGATIVE_Z:
        if (level >= m_maxCubeMapTextureLevel) {
            synthesizeGLError(GL_INVALID_VALUE, functionName, "level out of range");
            return false;
        }
        break;
    }
    // This function only checks if level is legal, so we return true and don't
    // generate INVALID_ENUM if target is illegal.
    return true;
}

bool WebGLRenderingContextBase::validateTexFuncDimensions(const char* functionName, TexFuncValidationFunctionType functionType,
    GLenum target, GLint level, GLsizei width, GLsizei height)
{
    if (width < 0 || height < 0) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "width or height < 0");
        return false;
    }

    switch (target) {
    case GL_TEXTURE_2D:
        if (width > (m_maxTextureSize >> level) || height > (m_maxTextureSize >> level)) {
            synthesizeGLError(GL_INVALID_VALUE, functionName, "width or height out of range");
            return false;
        }
        break;
    case GL_TEXTURE_CUBE_MAP_POSITIVE_X:
    case GL_TEXTURE_CUBE_MAP_NEGATIVE_X:
    case GL_TEXTURE_CUBE_MAP_POSITIVE_Y:
    case GL_TEXTURE_CUBE_MAP_NEGATIVE_Y:
    case GL_TEXTURE_CUBE_MAP_POSITIVE_Z:
    case GL_TEXTURE_CUBE_MAP_NEGATIVE_Z:
        if (functionType != TexSubImage2D && width != height) {
            synthesizeGLError(GL_INVALID_VALUE, functionName, "width != height for cube map");
            return false;
        }
        // No need to check height here. For texImage width == height.
        // For texSubImage that will be checked when checking yoffset + height is in range.
        if (width > (m_maxCubeMapTextureSize >> level)) {
            synthesizeGLError(GL_INVALID_VALUE, functionName, "width or height out of range for cube map");
            return false;
        }
        break;
    default:
        synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid target");
        return false;
    }
    return true;
}

bool WebGLRenderingContextBase::validateTexFuncParameters(const char* functionName, TexFuncValidationFunctionType functionType, GLenum target,
    GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type)
{
    // We absolutely have to validate the format and type combination.
    // The texImage2D entry points taking HTMLImage, etc. will produce
    // temporary data based on this combination, so it must be legal.
    if (!validateTexFuncFormatAndType(functionName, format, type, level) || !validateTexFuncLevel(functionName, target, level))
        return false;

    if (!validateTexFuncDimensions(functionName, functionType, target, level, width, height))
        return false;

    if (format != internalformat) {
        synthesizeGLError(GL_INVALID_OPERATION, functionName, "format != internalformat");
        return false;
    }

    if (border) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "border != 0");
        return false;
    }

    return true;
}

bool WebGLRenderingContextBase::validateTexFuncData(const char* functionName, GLint level, GLsizei width, GLsizei height, GLenum format, GLenum type, ArrayBufferView* pixels, NullDisposition disposition)
{
    // All calling functions check isContextLost, so a duplicate check is not needed here.
    if (!pixels) {
        if (disposition == NullAllowed)
            return true;
        synthesizeGLError(GL_INVALID_VALUE, functionName, "no pixels");
        return false;
    }

    if (!validateTexFuncFormatAndType(functionName, format, type, level))
        return false;
    if (!validateSettableTexFormat(functionName, format))
        return false;

    switch (type) {
    case GL_UNSIGNED_BYTE:
        if (pixels->type() != ArrayBufferView::TypeUint8) {
            synthesizeGLError(GL_INVALID_OPERATION, functionName, "type UNSIGNED_BYTE but ArrayBufferView not Uint8Array");
            return false;
        }
        break;
    case GL_UNSIGNED_SHORT_5_6_5:
    case GL_UNSIGNED_SHORT_4_4_4_4:
    case GL_UNSIGNED_SHORT_5_5_5_1:
        if (pixels->type() != ArrayBufferView::TypeUint16) {
            synthesizeGLError(GL_INVALID_OPERATION, functionName, "type UNSIGNED_SHORT but ArrayBufferView not Uint16Array");
            return false;
        }
        break;
    case GL_FLOAT: // OES_texture_float
        if (pixels->type() != ArrayBufferView::TypeFloat32) {
            synthesizeGLError(GL_INVALID_OPERATION, functionName, "type FLOAT but ArrayBufferView not Float32Array");
            return false;
        }
        break;
    case GL_HALF_FLOAT_OES: // OES_texture_half_float
        // As per the specification, ArrayBufferView should be null or a Uint16Array when
        // OES_texture_half_float is enabled.
        if (pixels && pixels->type() != ArrayBufferView::TypeUint16) {
            synthesizeGLError(GL_INVALID_OPERATION, functionName, "type HALF_FLOAT_OES but ArrayBufferView is not NULL and not Uint16Array");
            return false;
        }
        break;
    default:
        ASSERT_NOT_REACHED();
    }

    unsigned totalBytesRequired;
    GLenum error = WebGLImageConversion::computeImageSizeInBytes(format, type, width, height, m_unpackAlignment, &totalBytesRequired, 0);
    if (error != GL_NO_ERROR) {
        synthesizeGLError(error, functionName, "invalid texture dimensions");
        return false;
    }
    if (pixels->byteLength() < totalBytesRequired) {
        if (m_unpackAlignment != 1) {
            error = WebGLImageConversion::computeImageSizeInBytes(format, type, width, height, 1, &totalBytesRequired, 0);
            if (pixels->byteLength() == totalBytesRequired) {
                synthesizeGLError(GL_INVALID_OPERATION, functionName, "ArrayBufferView not big enough for request with UNPACK_ALIGNMENT > 1");
                return false;
            }
        }
        synthesizeGLError(GL_INVALID_OPERATION, functionName, "ArrayBufferView not big enough for request");
        return false;
    }
    return true;
}

bool WebGLRenderingContextBase::validateCompressedTexFormat(GLenum format)
{
    return m_compressedTextureFormats.contains(format);
}

bool WebGLRenderingContextBase::validateCompressedTexFuncData(const char* functionName, GLsizei width, GLsizei height, GLenum format, ArrayBufferView* pixels)
{
    if (!pixels) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "no pixels");
        return false;
    }
    if (width < 0 || height < 0) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "width or height < 0");
        return false;
    }

    unsigned bytesRequired = 0;

    switch (format) {
    case GL_COMPRESSED_RGB_S3TC_DXT1_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT1_EXT:
        {
            const int kBlockWidth = 4;
            const int kBlockHeight = 4;
            const int kBlockSize = 8;
            int numBlocksAcross = (width + kBlockWidth - 1) / kBlockWidth;
            int numBlocksDown = (height + kBlockHeight - 1) / kBlockHeight;
            int numBlocks = numBlocksAcross * numBlocksDown;
            bytesRequired = numBlocks * kBlockSize;
        }
        break;
    case GL_COMPRESSED_RGBA_S3TC_DXT3_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT5_EXT:
        {
            const int kBlockWidth = 4;
            const int kBlockHeight = 4;
            const int kBlockSize = 16;
            int numBlocksAcross = (width + kBlockWidth - 1) / kBlockWidth;
            int numBlocksDown = (height + kBlockHeight - 1) / kBlockHeight;
            int numBlocks = numBlocksAcross * numBlocksDown;
            bytesRequired = numBlocks * kBlockSize;
        }
        break;
    case GC3D_COMPRESSED_ATC_RGB_AMD:
    case GL_ETC1_RGB8_OES:
        {
            bytesRequired = floor(static_cast<double>((width + 3) / 4)) * floor(static_cast<double>((height + 3) / 4)) * 8;
        }
        break;
    case GC3D_COMPRESSED_ATC_RGBA_EXPLICIT_ALPHA_AMD:
    case GC3D_COMPRESSED_ATC_RGBA_INTERPOLATED_ALPHA_AMD:
        {
            bytesRequired = floor(static_cast<double>((width + 3) / 4)) * floor(static_cast<double>((height + 3) / 4)) * 16;
        }
        break;
    case GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG:
    case GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG:
        {
            bytesRequired = (max(width, 8) * max(height, 8) * 4 + 7) / 8;
        }
        break;
    case GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG:
    case GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG:
        {
            bytesRequired = (max(width, 16) * max(height, 8) * 2 + 7) / 8;
        }
        break;
    default:
        synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid format");
        return false;
    }

    if (pixels->byteLength() != bytesRequired) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "length of ArrayBufferView is not correct for dimensions");
        return false;
    }

    return true;
}

bool WebGLRenderingContextBase::validateCompressedTexDimensions(const char* functionName, TexFuncValidationFunctionType functionType, GLenum target, GLint level, GLsizei width, GLsizei height, GLenum format)
{
    if (!validateTexFuncDimensions(functionName, functionType, target, level, width, height))
        return false;

    bool widthValid = false;
    bool heightValid = false;

    switch (format) {
    case GC3D_COMPRESSED_ATC_RGB_AMD:
    case GC3D_COMPRESSED_ATC_RGBA_EXPLICIT_ALPHA_AMD:
    case GC3D_COMPRESSED_ATC_RGBA_INTERPOLATED_ALPHA_AMD:
    case GL_COMPRESSED_RGB_S3TC_DXT1_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT1_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT3_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT5_EXT: {
        const int kBlockWidth = 4;
        const int kBlockHeight = 4;
        widthValid = (level && width == 1) || (level && width == 2) || !(width % kBlockWidth);
        heightValid = (level && height == 1) || (level && height == 2) || !(height % kBlockHeight);
        break;
    }
    case GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG:
    case GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG:
    case GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG:
    case GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG: {
        // Must be a power of two
        widthValid = (width & (width - 1)) == 0;
        heightValid = (height & (height - 1)) == 0;
        break;
    }
    case GL_ETC1_RGB8_OES: {
        widthValid = true;
        heightValid = true;
        break;
    }
    default:
        return false;
    }

    if (!widthValid || !heightValid) {
        synthesizeGLError(GL_INVALID_OPERATION, functionName, "width or height invalid for level");
        return false;
    }

    return true;
}

bool WebGLRenderingContextBase::validateCompressedTexSubDimensions(const char* functionName, GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, WebGLTexture* tex)
{
    if (xoffset < 0 || yoffset < 0) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "xoffset or yoffset < 0");
        return false;
    }

    switch (format) {
    case GL_COMPRESSED_RGB_S3TC_DXT1_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT1_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT3_EXT:
    case GL_COMPRESSED_RGBA_S3TC_DXT5_EXT: {
        const int kBlockWidth = 4;
        const int kBlockHeight = 4;
        if ((xoffset % kBlockWidth) || (yoffset % kBlockHeight)) {
            synthesizeGLError(GL_INVALID_OPERATION, functionName, "xoffset or yoffset not multiple of 4");
            return false;
        }
        if (width - xoffset > tex->getWidth(target, level)
            || height - yoffset > tex->getHeight(target, level)) {
            synthesizeGLError(GL_INVALID_OPERATION, functionName, "dimensions out of range");
            return false;
        }
        return validateCompressedTexDimensions(functionName, TexSubImage2D, target, level, width, height, format);
    }
    case GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG:
    case GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG:
    case GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG:
    case GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG: {
        if ((xoffset != 0) || (yoffset != 0)) {
            synthesizeGLError(GL_INVALID_OPERATION, functionName, "xoffset and yoffset must be zero");
            return false;
        }
        if (width != tex->getWidth(target, level)
            || height != tex->getHeight(target, level)) {
            synthesizeGLError(GL_INVALID_OPERATION, functionName, "dimensions must match existing level");
            return false;
        }
        return validateCompressedTexDimensions(functionName, TexSubImage2D, target, level, width, height, format);
    }
    case GC3D_COMPRESSED_ATC_RGB_AMD:
    case GC3D_COMPRESSED_ATC_RGBA_EXPLICIT_ALPHA_AMD:
    case GC3D_COMPRESSED_ATC_RGBA_INTERPOLATED_ALPHA_AMD:
    case GL_ETC1_RGB8_OES: {
        synthesizeGLError(GL_INVALID_OPERATION, functionName, "unable to update sub-images with this format");
        return false;
    }
    default:
        return false;
    }
}

bool WebGLRenderingContextBase::validateDrawMode(const char* functionName, GLenum mode)
{
    switch (mode) {
    case GL_POINTS:
    case GL_LINE_STRIP:
    case GL_LINE_LOOP:
    case GL_LINES:
    case GL_TRIANGLE_STRIP:
    case GL_TRIANGLE_FAN:
    case GL_TRIANGLES:
        return true;
    default:
        synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid draw mode");
        return false;
    }
}

bool WebGLRenderingContextBase::validateStencilSettings(const char* functionName)
{
    if (m_stencilMask != m_stencilMaskBack || m_stencilFuncRef != m_stencilFuncRefBack || m_stencilFuncMask != m_stencilFuncMaskBack) {
        synthesizeGLError(GL_INVALID_OPERATION, functionName, "front and back stencils settings do not match");
        return false;
    }
    return true;
}

bool WebGLRenderingContextBase::validateStencilOrDepthFunc(const char* functionName, GLenum func)
{
    switch (func) {
    case GL_NEVER:
    case GL_LESS:
    case GL_LEQUAL:
    case GL_GREATER:
    case GL_GEQUAL:
    case GL_EQUAL:
    case GL_NOTEQUAL:
    case GL_ALWAYS:
        return true;
    default:
        synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid function");
        return false;
    }
}

void WebGLRenderingContextBase::printGLErrorToConsole(const String& message)
{
    if (!m_numGLErrorsToConsoleAllowed)
        return;

    --m_numGLErrorsToConsoleAllowed;
    printWarningToConsole(message);

    if (!m_numGLErrorsToConsoleAllowed)
        printWarningToConsole("WebGL: too many errors, no more errors will be reported to the console for this context.");

    return;
}

void WebGLRenderingContextBase::printWarningToConsole(const String& message)
{
    if (!canvas())
        return;
    canvas()->document().addConsoleMessage(ConsoleMessage::create(RenderingMessageSource, WarningMessageLevel, message));
}

bool WebGLRenderingContextBase::validateFramebufferFuncParameters(const char* functionName, GLenum target, GLenum attachment)
{
    if (target != GL_FRAMEBUFFER) {
        synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid target");
        return false;
    }
    switch (attachment) {
    case GL_COLOR_ATTACHMENT0:
    case GL_DEPTH_ATTACHMENT:
    case GL_STENCIL_ATTACHMENT:
    case GC3D_DEPTH_STENCIL_ATTACHMENT_WEBGL:
        break;
    default:
        if (extensionEnabled(WebGLDrawBuffersName)
            && attachment > GL_COLOR_ATTACHMENT0
            && attachment < static_cast<GLenum>(GL_COLOR_ATTACHMENT0 + maxColorAttachments()))
            break;
        synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid attachment");
        return false;
    }
    return true;
}

bool WebGLRenderingContextBase::validateBlendEquation(const char* functionName, GLenum mode)
{
    switch (mode) {
    case GL_FUNC_ADD:
    case GL_FUNC_SUBTRACT:
    case GL_FUNC_REVERSE_SUBTRACT:
        return true;
    case GL_MIN_EXT:
    case GL_MAX_EXT:
        if (extensionEnabled(EXTBlendMinMaxName))
            return true;
        synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid mode");
        return false;
    default:
        synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid mode");
        return false;
    }
}

bool WebGLRenderingContextBase::validateBlendFuncFactors(const char* functionName, GLenum src, GLenum dst)
{
    if (((src == GL_CONSTANT_COLOR || src == GL_ONE_MINUS_CONSTANT_COLOR)
        && (dst == GL_CONSTANT_ALPHA || dst == GL_ONE_MINUS_CONSTANT_ALPHA))
        || ((dst == GL_CONSTANT_COLOR || dst == GL_ONE_MINUS_CONSTANT_COLOR)
        && (src == GL_CONSTANT_ALPHA || src == GL_ONE_MINUS_CONSTANT_ALPHA))) {
        synthesizeGLError(GL_INVALID_OPERATION, functionName, "incompatible src and dst");
        return false;
    }
    return true;
}

bool WebGLRenderingContextBase::validateCapability(const char* functionName, GLenum cap)
{
    switch (cap) {
    case GL_BLEND:
    case GL_CULL_FACE:
    case GL_DEPTH_TEST:
    case GL_DITHER:
    case GL_POLYGON_OFFSET_FILL:
    case GL_SAMPLE_ALPHA_TO_COVERAGE:
    case GL_SAMPLE_COVERAGE:
    case GL_SCISSOR_TEST:
    case GL_STENCIL_TEST:
        return true;
    default:
        synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid capability");
        return false;
    }
}

bool WebGLRenderingContextBase::validateUniformParameters(const char* functionName, const WebGLUniformLocation* location, Float32Array* v, GLsizei requiredMinSize)
{
    if (!v) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "no array");
        return false;
    }
    return validateUniformMatrixParameters(functionName, location, false, v->data(), v->length(), requiredMinSize);
}

bool WebGLRenderingContextBase::validateUniformParameters(const char* functionName, const WebGLUniformLocation* location, Int32Array* v, GLsizei requiredMinSize)
{
    if (!v) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "no array");
        return false;
    }
    return validateUniformMatrixParameters(functionName, location, false, v->data(), v->length(), requiredMinSize);
}

bool WebGLRenderingContextBase::validateUniformParameters(const char* functionName, const WebGLUniformLocation* location, void* v, GLsizei size, GLsizei requiredMinSize)
{
    return validateUniformMatrixParameters(functionName, location, false, v, size, requiredMinSize);
}

bool WebGLRenderingContextBase::validateUniformMatrixParameters(const char* functionName, const WebGLUniformLocation* location, GLboolean transpose, Float32Array* v, GLsizei requiredMinSize)
{
    if (!v) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "no array");
        return false;
    }
    return validateUniformMatrixParameters(functionName, location, transpose, v->data(), v->length(), requiredMinSize);
}

bool WebGLRenderingContextBase::validateUniformMatrixParameters(const char* functionName, const WebGLUniformLocation* location, GLboolean transpose, void* v, GLsizei size, GLsizei requiredMinSize)
{
    if (!location)
        return false;
    if (location->program() != m_currentProgram) {
        synthesizeGLError(GL_INVALID_OPERATION, functionName, "location is not from current program");
        return false;
    }
    if (!v) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "no array");
        return false;
    }
    if (transpose) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "transpose not FALSE");
        return false;
    }
    if (size < requiredMinSize || (size % requiredMinSize)) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "invalid size");
        return false;
    }
    return true;
}

WebGLBuffer* WebGLRenderingContextBase::validateBufferDataTarget(const char* functionName, GLenum target)
{
    WebGLBuffer* buffer = 0;
    switch (target) {
    case GL_ELEMENT_ARRAY_BUFFER:
        buffer = m_boundVertexArrayObject->boundElementArrayBuffer().get();
        break;
    case GL_ARRAY_BUFFER:
        buffer = m_boundArrayBuffer.get();
        break;
    default:
        synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid target");
        return 0;
    }
    if (!buffer) {
        synthesizeGLError(GL_INVALID_OPERATION, functionName, "no buffer");
        return 0;
    }
    return buffer;
}

bool WebGLRenderingContextBase::validateHTMLImageElement(const char* functionName, HTMLImageElement* image, ExceptionState& exceptionState)
{
    if (!image || !image->cachedImage()) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "no image");
        return false;
    }
    const KURL& url = image->cachedImage()->response().url();
    if (url.isNull() || url.isEmpty() || !url.isValid()) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "invalid image");
        return false;
    }

    return true;
}

bool WebGLRenderingContextBase::validateHTMLCanvasElement(const char* functionName, HTMLCanvasElement* canvas, ExceptionState& exceptionState)
{
    if (!canvas || !canvas->buffer()) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "no canvas");
        return false;
    }
    return true;
}

bool WebGLRenderingContextBase::validateHTMLVideoElement(const char* functionName, HTMLVideoElement* video, ExceptionState& exceptionState)
{
    if (!video || !video->videoWidth() || !video->videoHeight()) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "no video");
        return false;
    }
    return true;
}

bool WebGLRenderingContextBase::validateDrawArrays(const char* functionName, GLenum mode, GLint first, GLsizei count)
{
    if (isContextLost() || !validateDrawMode(functionName, mode))
        return false;

    if (!validateStencilSettings(functionName))
        return false;

    if (first < 0 || count < 0) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "first or count < 0");
        return false;
    }

    if (!count) {
        markContextChanged(CanvasChanged);
        return false;
    }

    if (!validateRenderingState(functionName)) {
        return false;
    }

    const char* reason = "framebuffer incomplete";
    if (m_framebufferBinding && !m_framebufferBinding->onAccess(webContext(), &reason)) {
        synthesizeGLError(GL_INVALID_FRAMEBUFFER_OPERATION, functionName, reason);
        return false;
    }

    return true;
}

bool WebGLRenderingContextBase::validateDrawElements(const char* functionName, GLenum mode, GLsizei count, GLenum type, long long offset)
{
    if (isContextLost() || !validateDrawMode(functionName, mode))
        return false;

    if (!validateStencilSettings(functionName))
        return false;

    switch (type) {
    case GL_UNSIGNED_BYTE:
    case GL_UNSIGNED_SHORT:
        break;
    case GL_UNSIGNED_INT:
        if (extensionEnabled(OESElementIndexUintName))
            break;
        synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid type");
        return false;
    default:
        synthesizeGLError(GL_INVALID_ENUM, functionName, "invalid type");
        return false;
    }

    if (count < 0) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "count < 0");
        return false;
    }
    if (!validateValueFitNonNegInt32(functionName, "offset", offset))
        return false;

    if (!count) {
        markContextChanged(CanvasChanged);
        return false;
    }

    if (!m_boundVertexArrayObject->boundElementArrayBuffer()) {
        synthesizeGLError(GL_INVALID_OPERATION, functionName, "no ELEMENT_ARRAY_BUFFER bound");
        return false;
    }

    if (!validateRenderingState(functionName)) {
        return false;
    }

    const char* reason = "framebuffer incomplete";
    if (m_framebufferBinding && !m_framebufferBinding->onAccess(webContext(), &reason)) {
        synthesizeGLError(GL_INVALID_FRAMEBUFFER_OPERATION, functionName, reason);
        return false;
    }

    return true;
}

// Helper function to validate draw*Instanced calls
bool WebGLRenderingContextBase::validateDrawInstanced(const char* functionName, GLsizei primcount)
{
    if (primcount < 0) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "primcount < 0");
        return false;
    }

    return true;
}

void WebGLRenderingContextBase::vertexAttribfImpl(const char* functionName, GLuint index, GLsizei expectedSize, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3)
{
    if (isContextLost())
        return;
    if (index >= m_maxVertexAttribs) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "index out of range");
        return;
    }
    // In GL, we skip setting vertexAttrib0 values.
    switch (expectedSize) {
    case 1:
        webContext()->vertexAttrib1f(index, v0);
        break;
    case 2:
        webContext()->vertexAttrib2f(index, v0, v1);
        break;
    case 3:
        webContext()->vertexAttrib3f(index, v0, v1, v2);
        break;
    case 4:
        webContext()->vertexAttrib4f(index, v0, v1, v2, v3);
        break;
    }
    VertexAttribValue& attribValue = m_vertexAttribValue[index];
    attribValue.value[0] = v0;
    attribValue.value[1] = v1;
    attribValue.value[2] = v2;
    attribValue.value[3] = v3;
}

void WebGLRenderingContextBase::vertexAttribfvImpl(const char* functionName, GLuint index, Float32Array* v, GLsizei expectedSize)
{
    if (isContextLost())
        return;
    if (!v) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "no array");
        return;
    }
    vertexAttribfvImpl(functionName, index, v->data(), v->length(), expectedSize);
}

void WebGLRenderingContextBase::vertexAttribfvImpl(const char* functionName, GLuint index, GLfloat* v, GLsizei size, GLsizei expectedSize)
{
    if (isContextLost())
        return;
    if (!v) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "no array");
        return;
    }
    if (size < expectedSize) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "invalid size");
        return;
    }
    if (index >= m_maxVertexAttribs) {
        synthesizeGLError(GL_INVALID_VALUE, functionName, "index out of range");
        return;
    }
    // In GL, we skip setting vertexAttrib0 values.
    switch (expectedSize) {
    case 1:
        webContext()->vertexAttrib1fv(index, v);
        break;
    case 2:
        webContext()->vertexAttrib2fv(index, v);
        break;
    case 3:
        webContext()->vertexAttrib3fv(index, v);
        break;
    case 4:
        webContext()->vertexAttrib4fv(index, v);
        break;
    }
    VertexAttribValue& attribValue = m_vertexAttribValue[index];
    attribValue.initValue();
    for (int ii = 0; ii < expectedSize; ++ii)
        attribValue.value[ii] = v[ii];
}

void WebGLRenderingContextBase::dispatchContextLostEvent(Timer<WebGLRenderingContextBase>*)
{
    RefPtrWillBeRawPtr<WebGLContextEvent> event = WebGLContextEvent::create(EventTypeNames::webglcontextlost, false, true, "");
    canvas()->dispatchEvent(event);
    m_restoreAllowed = event->defaultPrevented();
    if (m_restoreAllowed) {
        if (m_autoRecoveryMethod == Auto)
            m_restoreTimer.startOneShot(0, FROM_HERE);
    }
}

void WebGLRenderingContextBase::maybeRestoreContext(Timer<WebGLRenderingContextBase>*)
{
    ASSERT(isContextLost());

    // The rendering context is not restored unless the default behavior of the
    // webglcontextlost event was prevented earlier.
    //
    // Because of the way m_restoreTimer is set up for real vs. synthetic lost
    // context events, we don't have to worry about this test short-circuiting
    // the retry loop for real context lost events.
    if (!m_restoreAllowed)
        return;

    LocalFrame* frame = canvas()->document().frame();
    if (!frame)
        return;

    Settings* settings = frame->settings();

    // If the context was lost due to RealLostContext, we need to destroy the old DrawingBuffer before creating new DrawingBuffer to ensure resource budget enough.
    if (drawingBuffer()) {
#if ENABLE(OILPAN)
        m_sharedWebGraphicsContext3D->dispose();
#else
        m_drawingBuffer->beginDestruction();
        m_drawingBuffer.clear();
#endif
    }

    blink::WebGraphicsContext3D::Attributes attributes = m_requestedAttributes->attributes(canvas()->document().topDocument().url().string(), settings, version());
    OwnPtr<blink::WebGraphicsContext3D> context = adoptPtr(blink::Platform::current()->createOffscreenGraphicsContext3D(attributes, 0));
    RefPtr<DrawingBuffer> buffer;
    if (context) {
        // Construct a new drawing buffer with the new WebGraphicsContext3D.
        buffer = createDrawingBuffer(context.release());
        // If DrawingBuffer::create() fails to allocate a fbo, |drawingBuffer| is set to null.
    }
    if (!buffer) {
        if (m_contextLostMode == RealLostContext) {
            m_restoreTimer.startOneShot(secondsBetweenRestoreAttempts, FROM_HERE);
        } else {
            // This likely shouldn't happen but is the best way to report it to the WebGL app.
            synthesizeGLError(GL_INVALID_OPERATION, "", "error restoring context");
        }
        return;
    }

#if ENABLE(OILPAN)
    if (m_sharedWebGraphicsContext3D)
        m_sharedWebGraphicsContext3D->update(buffer.release());
    else
        m_sharedWebGraphicsContext3D = WebGLSharedWebGraphicsContext3D::create(buffer.release());
#else
    m_drawingBuffer = buffer.release();
#endif

    drawingBuffer()->bind();
    m_lostContextErrors.clear();
    m_contextLostMode = NotLostContext;
    m_autoRecoveryMethod = Manual;
    m_restoreAllowed = false;
    removeFromEvictedList(this);

    setupFlags();
    initializeNewContext();
    markContextChanged(CanvasContextChanged);
    canvas()->dispatchEvent(WebGLContextEvent::create(EventTypeNames::webglcontextrestored, false, true, ""));
}

String WebGLRenderingContextBase::ensureNotNull(const String& text) const
{
    if (text.isNull())
        return WTF::emptyString();
    return text;
}

WebGLRenderingContextBase::LRUImageBufferCache::LRUImageBufferCache(int capacity)
    : m_buffers(adoptArrayPtr(new OwnPtr<ImageBuffer>[capacity]))
    , m_capacity(capacity)
{
}

ImageBuffer* WebGLRenderingContextBase::LRUImageBufferCache::imageBuffer(const IntSize& size)
{
    int i;
    for (i = 0; i < m_capacity; ++i) {
        ImageBuffer* buf = m_buffers[i].get();
        if (!buf)
            break;
        if (buf->size() != size)
            continue;
        bubbleToFront(i);
        return buf;
    }

    OwnPtr<ImageBuffer> temp(ImageBuffer::create(size));
    if (!temp)
        return 0;
    i = std::min(m_capacity - 1, i);
    m_buffers[i] = temp.release();

    ImageBuffer* buf = m_buffers[i].get();
    bubbleToFront(i);
    return buf;
}

void WebGLRenderingContextBase::LRUImageBufferCache::bubbleToFront(int idx)
{
    for (int i = idx; i > 0; --i)
        m_buffers[i].swap(m_buffers[i-1]);
}

namespace {

    String GetErrorString(GLenum error)
    {
        switch (error) {
        case GL_INVALID_ENUM:
            return "INVALID_ENUM";
        case GL_INVALID_VALUE:
            return "INVALID_VALUE";
        case GL_INVALID_OPERATION:
            return "INVALID_OPERATION";
        case GL_OUT_OF_MEMORY:
            return "OUT_OF_MEMORY";
        case GL_INVALID_FRAMEBUFFER_OPERATION:
            return "INVALID_FRAMEBUFFER_OPERATION";
        case GC3D_CONTEXT_LOST_WEBGL:
            return "CONTEXT_LOST_WEBGL";
        default:
            return String::format("WebGL ERROR(0x%04X)", error);
        }
    }

} // namespace anonymous

void WebGLRenderingContextBase::synthesizeGLError(GLenum error, const char* functionName, const char* description, ConsoleDisplayPreference display)
{
    String errorType = GetErrorString(error);
    if (m_synthesizedErrorsToConsole && display == DisplayInConsole) {
        String message = String("WebGL: ") + errorType +  ": " + String(functionName) + ": " + String(description);
        printGLErrorToConsole(message);
    }
    if (!isContextLost())
        webContext()->synthesizeGLError(error);
    else {
        if (m_lostContextErrors.find(error) == WTF::kNotFound)
            m_lostContextErrors.append(error);
    }
}

void WebGLRenderingContextBase::emitGLWarning(const char* functionName, const char* description)
{
    if (m_synthesizedErrorsToConsole) {
        String message = String("WebGL: ") + String(functionName) + ": " + String(description);
        printGLErrorToConsole(message);
    }
}

void WebGLRenderingContextBase::applyStencilTest()
{
    bool haveStencilBuffer = false;

    if (m_framebufferBinding)
        haveStencilBuffer = m_framebufferBinding->hasStencilBuffer();
    else {
        RefPtrWillBeRawPtr<WebGLContextAttributes> attributes = getContextAttributes();
        haveStencilBuffer = attributes->stencil();
    }
    enableOrDisable(GL_STENCIL_TEST,
                    m_stencilEnabled && haveStencilBuffer);
}

void WebGLRenderingContextBase::enableOrDisable(GLenum capability, bool enable)
{
    if (isContextLost())
        return;
    if (enable)
        webContext()->enable(capability);
    else
        webContext()->disable(capability);
}

IntSize WebGLRenderingContextBase::clampedCanvasSize()
{
    return IntSize(clamp(canvas()->width(), 1, m_maxViewportDims[0]),
                   clamp(canvas()->height(), 1, m_maxViewportDims[1]));
}

GLint WebGLRenderingContextBase::maxDrawBuffers()
{
    if (isContextLost() || !extensionEnabled(WebGLDrawBuffersName))
        return 0;
    if (!m_maxDrawBuffers)
        webContext()->getIntegerv(GL_MAX_DRAW_BUFFERS_EXT, &m_maxDrawBuffers);
    if (!m_maxColorAttachments)
        webContext()->getIntegerv(GL_MAX_COLOR_ATTACHMENTS_EXT, &m_maxColorAttachments);
    // WEBGL_draw_buffers requires MAX_COLOR_ATTACHMENTS >= MAX_DRAW_BUFFERS.
    return std::min(m_maxDrawBuffers, m_maxColorAttachments);
}

GLint WebGLRenderingContextBase::maxColorAttachments()
{
    if (isContextLost() || !extensionEnabled(WebGLDrawBuffersName))
        return 0;
    if (!m_maxColorAttachments)
        webContext()->getIntegerv(GL_MAX_COLOR_ATTACHMENTS_EXT, &m_maxColorAttachments);
    return m_maxColorAttachments;
}

void WebGLRenderingContextBase::setBackDrawBuffer(GLenum buf)
{
    m_backDrawBuffer = buf;
}

void WebGLRenderingContextBase::restoreCurrentFramebuffer()
{
    bindFramebuffer(GL_FRAMEBUFFER, m_framebufferBinding.get());
}

void WebGLRenderingContextBase::restoreCurrentTexture2D()
{
    bindTexture(GL_TEXTURE_2D, m_textureUnits[m_activeTextureUnit].m_texture2DBinding.get());
}

void WebGLRenderingContextBase::multisamplingChanged(bool enabled)
{
    if (m_multisamplingAllowed != enabled) {
        m_multisamplingAllowed = enabled;
        forceLostContext(WebGLRenderingContextBase::SyntheticLostContext, WebGLRenderingContextBase::Auto);
    }
}

void WebGLRenderingContextBase::findNewMaxNonDefaultTextureUnit()
{
    // Trace backwards from the current max to find the new max non-default texture unit
    int startIndex = m_onePlusMaxNonDefaultTextureUnit - 1;
    for (int i = startIndex; i >= 0; --i) {
        if (m_textureUnits[i].m_texture2DBinding
            || m_textureUnits[i].m_textureCubeMapBinding) {
            m_onePlusMaxNonDefaultTextureUnit = i + 1;
            return;
        }
    }
    m_onePlusMaxNonDefaultTextureUnit = 0;
}

void WebGLRenderingContextBase::TextureUnitState::trace(Visitor* visitor)
{
    visitor->trace(m_texture2DBinding);
    visitor->trace(m_textureCubeMapBinding);
}

void WebGLRenderingContextBase::trace(Visitor* visitor)
{
#if ENABLE(OILPAN)
    visitor->trace(m_contextObjects);
#endif
    visitor->trace(m_contextLostCallbackAdapter);
    visitor->trace(m_errorMessageCallbackAdapter);
    visitor->trace(m_boundArrayBuffer);
    visitor->trace(m_defaultVertexArrayObject);
    visitor->trace(m_boundVertexArrayObject);
    visitor->trace(m_vertexAttrib0Buffer);
    visitor->trace(m_currentProgram);
    visitor->trace(m_framebufferBinding);
    visitor->trace(m_renderbufferBinding);
    visitor->trace(m_textureUnits);
    visitor->trace(m_blackTexture2D);
    visitor->trace(m_blackTextureCubeMap);
    visitor->trace(m_requestedAttributes);
    visitor->trace(m_extensions);
    CanvasRenderingContext::trace(visitor);
}

#if ENABLE(OILPAN)
PassRefPtr<WebGLSharedWebGraphicsContext3D> WebGLRenderingContextBase::sharedWebGraphicsContext3D() const
{
    return m_sharedWebGraphicsContext3D;
}

DrawingBuffer* WebGLRenderingContextBase::drawingBuffer() const
{
    return m_sharedWebGraphicsContext3D ? m_sharedWebGraphicsContext3D->drawingBuffer() : 0;
}
#else
DrawingBuffer* WebGLRenderingContextBase::drawingBuffer() const
{
    return m_drawingBuffer.get();
}
#endif

} // namespace blink
