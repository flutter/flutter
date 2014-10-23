/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#ifndef WebGraphicsContext3D_h
#define WebGraphicsContext3D_h

#include "WebCommon.h"
#include "WebNonCopyable.h"
#include "WebString.h"

struct GrGLInterface;

namespace blink {

// WGC3D types match the corresponding GL types as defined in OpenGL ES 2.0
// header file gl2.h from khronos.org.
typedef char WGC3Dchar;
typedef unsigned WGC3Denum;
typedef unsigned char WGC3Dboolean;
typedef unsigned WGC3Dbitfield;
typedef signed char WGC3Dbyte;
typedef unsigned char WGC3Dubyte;
typedef short WGC3Dshort;
typedef unsigned short WGC3Dushort;
typedef int WGC3Dint;
typedef int WGC3Dsizei;
typedef unsigned WGC3Duint;
typedef float WGC3Dfloat;
typedef float WGC3Dclampf;
typedef signed long int WGC3Dintptr;
typedef signed long int WGC3Dsizeiptr;

// Typedef for server-side objects like OpenGL textures and program objects.
typedef WGC3Duint WebGLId;

// This interface abstracts the operations performed by the
// GraphicsContext3D in order to implement WebGL. Nearly all of the
// methods exposed on this interface map directly to entry points in
// the OpenGL ES 2.0 API.
class WebGraphicsContext3D : public WebNonCopyable {
public:
    // Return value from getActiveUniform and getActiveAttrib.
    struct ActiveInfo {
        WebString name;
        WGC3Denum type;
        WGC3Dint size;
    };

    // Context creation attributes.
    struct Attributes {
        Attributes()
            : alpha(true)
            , depth(true)
            , stencil(true)
            , antialias(true)
            , premultipliedAlpha(true)
            , canRecoverFromContextLoss(true)
            , noExtensions(false)
            , shareResources(true)
            , preferDiscreteGPU(false)
            , noAutomaticFlushes(false)
            , failIfMajorPerformanceCaveat(false)
            , webGL(false)
            , webGLVersion(0)
        {
        }

        bool alpha;
        bool depth;
        bool stencil;
        bool antialias;
        bool premultipliedAlpha;
        bool canRecoverFromContextLoss;
        bool noExtensions;
        bool shareResources;
        bool preferDiscreteGPU;
        bool noAutomaticFlushes;
        bool failIfMajorPerformanceCaveat;
        bool webGL;
        unsigned webGLVersion;
        // FIXME: ideally this would be a WebURL, but it is currently not
        // possible to pass a WebURL by value across the WebKit API boundary.
        // See https://bugs.webkit.org/show_bug.cgi?id=103793#c13 .
        WebString topDocumentURL;
    };

    class WebGraphicsContextLostCallback {
    public:
        virtual void onContextLost() = 0;

    protected:
        virtual ~WebGraphicsContextLostCallback() { }
    };

    class WebGraphicsErrorMessageCallback {
    public:
        virtual void onErrorMessage(const WebString&, WGC3Dint) = 0;

    protected:
        virtual ~WebGraphicsErrorMessageCallback() { }
    };

    class WebGraphicsSwapBuffersCompleteCallbackCHROMIUM {
    public:
        virtual void onSwapBuffersComplete() = 0;

    protected:
        virtual ~WebGraphicsSwapBuffersCompleteCallbackCHROMIUM() { }
    };

    // This destructor needs to be public so that using classes can destroy instances if initialization fails.
    virtual ~WebGraphicsContext3D() { }

    // Each flush or finish is assigned an unique ID. The larger
    // the ID number, the more recently the context has been flushed.
    virtual uint32_t lastFlushID() { return 0; }

    // Resizes the region into which this WebGraphicsContext3D is drawing.
    virtual void reshapeWithScaleFactor(int width, int height, float scaleFactor) { }

    // GL_CHROMIUM_setVisibility - Changes the visibility of the backbuffer
    virtual void setVisibilityCHROMIUM(bool visible) = 0;

    // GL_EXT_discard_framebuffer - makes specified attachments of currently bound framebuffer undefined.
    virtual void discardFramebufferEXT(WGC3Denum target, WGC3Dsizei numAttachments, const WGC3Denum* attachments) { }

    // GL_CHROMIUM_discard_backbuffer - controls allocation/deallocation of the back buffer.
    virtual void discardBackbufferCHROMIUM() { }
    virtual void ensureBackbufferCHROMIUM() { }

    virtual unsigned insertSyncPoint() { return 0; }
    virtual void waitSyncPoint(unsigned) { }

    // Copies the contents of the off-screen render target used by the WebGL
    // context to the corresponding texture used by the compositor.
    virtual void prepareTexture() = 0;

    // GL_CHROMIUM_post_sub_buffer - Copies part of the back buffer to the front buffer.
    virtual void postSubBufferCHROMIUM(int x, int y, int width, int height) = 0;

    // Synthesizes an OpenGL error which will be returned from a
    // later call to getError. This is used to emulate OpenGL ES
    // 2.0 behavior on the desktop and to enforce additional error
    // checking mandated by WebGL.
    //
    // Per the behavior of glGetError, this stores at most one
    // instance of any given error, and returns them from calls to
    // getError in the order they were added.
    virtual void synthesizeGLError(WGC3Denum) = 0;

    virtual bool isContextLost() = 0;

    // GL_CHROMIUM_map_sub
    virtual void* mapBufferSubDataCHROMIUM(WGC3Denum target, WGC3Dintptr offset, WGC3Dsizeiptr size, WGC3Denum access) = 0;
    virtual void unmapBufferSubDataCHROMIUM(const void*) = 0;
    virtual void* mapTexSubImage2DCHROMIUM(WGC3Denum target, WGC3Dint level, WGC3Dint xoffset, WGC3Dint yoffset, WGC3Dsizei width, WGC3Dsizei height, WGC3Denum format, WGC3Denum type, WGC3Denum access) = 0;
    virtual void unmapTexSubImage2DCHROMIUM(const void*) = 0;

    // GL_CHROMIUM_request_extension
    virtual WebString getRequestableExtensionsCHROMIUM() = 0;
    virtual void requestExtensionCHROMIUM(const char*) = 0;

    // GL_CHROMIUM_framebuffer_multisample
    virtual void blitFramebufferCHROMIUM(WGC3Dint srcX0, WGC3Dint srcY0, WGC3Dint srcX1, WGC3Dint srcY1, WGC3Dint dstX0, WGC3Dint dstY0, WGC3Dint dstX1, WGC3Dint dstY1, WGC3Dbitfield mask, WGC3Denum filter) = 0;
    virtual void renderbufferStorageMultisampleCHROMIUM(WGC3Denum target, WGC3Dsizei samples, WGC3Denum internalformat, WGC3Dsizei width, WGC3Dsizei height) = 0;

    // GL_CHROMIUM_swapbuffers_complete_callback
    virtual void setSwapBuffersCompleteCallbackCHROMIUM(WebGraphicsSwapBuffersCompleteCallbackCHROMIUM* callback) { }

    // GL_CHROMIUM_rate_limit_offscreen_context
    virtual void rateLimitOffscreenContextCHROMIUM() { }

    // GL_CHROMIUM_lose_context
    virtual void loseContextCHROMIUM(WGC3Denum current, WGC3Denum other) { }

    // The entry points below map directly to the OpenGL ES 2.0 API.
    // See: http://www.khronos.org/registry/gles/
    // and: http://www.khronos.org/opengles/sdk/docs/man/
    virtual void activeTexture(WGC3Denum texture) = 0;
    virtual void attachShader(WebGLId program, WebGLId shader) = 0;
    virtual void bindAttribLocation(WebGLId program, WGC3Duint index, const WGC3Dchar* name) = 0;
    virtual void bindBuffer(WGC3Denum target, WebGLId buffer) = 0;
    virtual void bindFramebuffer(WGC3Denum target, WebGLId framebuffer) = 0;
    virtual void bindRenderbuffer(WGC3Denum target, WebGLId renderbuffer) = 0;
    virtual void bindTexture(WGC3Denum target, WebGLId texture) = 0;
    virtual void blendColor(WGC3Dclampf red, WGC3Dclampf green, WGC3Dclampf blue, WGC3Dclampf alpha) = 0;
    virtual void blendEquation(WGC3Denum mode) = 0;
    virtual void blendEquationSeparate(WGC3Denum modeRGB, WGC3Denum modeAlpha) = 0;
    virtual void blendFunc(WGC3Denum sfactor, WGC3Denum dfactor) = 0;
    virtual void blendFuncSeparate(WGC3Denum srcRGB, WGC3Denum dstRGB, WGC3Denum srcAlpha, WGC3Denum dstAlpha) = 0;

    virtual void bufferData(WGC3Denum target, WGC3Dsizeiptr size, const void* data, WGC3Denum usage) = 0;
    virtual void bufferSubData(WGC3Denum target, WGC3Dintptr offset, WGC3Dsizeiptr size, const void* data) = 0;

    virtual WGC3Denum checkFramebufferStatus(WGC3Denum target) = 0;
    virtual void clear(WGC3Dbitfield mask) = 0;
    virtual void clearColor(WGC3Dclampf red, WGC3Dclampf green, WGC3Dclampf blue, WGC3Dclampf alpha) = 0;
    virtual void clearDepth(WGC3Dclampf depth) = 0;
    virtual void clearStencil(WGC3Dint s) = 0;
    virtual void colorMask(WGC3Dboolean red, WGC3Dboolean green, WGC3Dboolean blue, WGC3Dboolean alpha) = 0;
    virtual void compileShader(WebGLId shader) = 0;

    virtual void compressedTexImage2D(WGC3Denum target, WGC3Dint level, WGC3Denum internalformat, WGC3Dsizei width, WGC3Dsizei height, WGC3Dint border, WGC3Dsizei imageSize, const void* data) = 0;
    virtual void compressedTexSubImage2D(WGC3Denum target, WGC3Dint level, WGC3Dint xoffset, WGC3Dint yoffset, WGC3Dsizei width, WGC3Dsizei height, WGC3Denum format, WGC3Dsizei imageSize, const void* data) = 0;
    virtual void copyTexImage2D(WGC3Denum target, WGC3Dint level, WGC3Denum internalformat, WGC3Dint x, WGC3Dint y, WGC3Dsizei width, WGC3Dsizei height, WGC3Dint border) = 0;
    virtual void copyTexSubImage2D(WGC3Denum target, WGC3Dint level, WGC3Dint xoffset, WGC3Dint yoffset, WGC3Dint x, WGC3Dint y, WGC3Dsizei width, WGC3Dsizei height) = 0;
    virtual void cullFace(WGC3Denum mode) = 0;
    virtual void depthFunc(WGC3Denum func) = 0;
    virtual void depthMask(WGC3Dboolean flag) = 0;
    virtual void depthRange(WGC3Dclampf zNear, WGC3Dclampf zFar) = 0;
    virtual void detachShader(WebGLId program, WebGLId shader) = 0;
    virtual void disable(WGC3Denum cap) = 0;
    virtual void disableVertexAttribArray(WGC3Duint index) = 0;
    virtual void drawArrays(WGC3Denum mode, WGC3Dint first, WGC3Dsizei count) = 0;
    virtual void drawElements(WGC3Denum mode, WGC3Dsizei count, WGC3Denum type, WGC3Dintptr offset) = 0;

    virtual void enable(WGC3Denum cap) = 0;
    virtual void enableVertexAttribArray(WGC3Duint index) = 0;
    virtual void finish() = 0;
    virtual void flush() = 0;
    virtual void framebufferRenderbuffer(WGC3Denum target, WGC3Denum attachment, WGC3Denum renderbuffertarget, WebGLId renderbuffer) = 0;
    virtual void framebufferTexture2D(WGC3Denum target, WGC3Denum attachment, WGC3Denum textarget, WebGLId texture, WGC3Dint level) = 0;
    virtual void frontFace(WGC3Denum mode) = 0;
    virtual void generateMipmap(WGC3Denum target) = 0;

    virtual bool getActiveAttrib(WebGLId program, WGC3Duint index, ActiveInfo&) = 0;
    virtual bool getActiveUniform(WebGLId program, WGC3Duint index, ActiveInfo&) = 0;
    virtual void getAttachedShaders(WebGLId program, WGC3Dsizei maxCount, WGC3Dsizei* count, WebGLId* shaders) = 0;
    virtual WGC3Dint getAttribLocation(WebGLId program, const WGC3Dchar* name) = 0;
    virtual void getBooleanv(WGC3Denum pname, WGC3Dboolean* value) = 0;
    virtual void getBufferParameteriv(WGC3Denum target, WGC3Denum pname, WGC3Dint* value) = 0;
    virtual WGC3Denum getError() = 0;
    virtual void getFloatv(WGC3Denum pname, WGC3Dfloat* value) = 0;
    virtual void getFramebufferAttachmentParameteriv(WGC3Denum target, WGC3Denum attachment, WGC3Denum pname, WGC3Dint* value) = 0;
    virtual void getIntegerv(WGC3Denum pname, WGC3Dint* value) = 0;
    virtual void getProgramiv(WebGLId program, WGC3Denum pname, WGC3Dint* value) = 0;
    virtual WebString getProgramInfoLog(WebGLId program) = 0;
    virtual void getRenderbufferParameteriv(WGC3Denum target, WGC3Denum pname, WGC3Dint* value) = 0;
    virtual void getShaderiv(WebGLId shader, WGC3Denum pname, WGC3Dint* value) = 0;
    virtual WebString getShaderInfoLog(WebGLId shader) = 0;
    virtual void getShaderPrecisionFormat(WGC3Denum shadertype, WGC3Denum precisiontype, WGC3Dint* range, WGC3Dint* precision) = 0;
    virtual WebString getShaderSource(WebGLId shader) = 0;
    virtual WebString getString(WGC3Denum name) = 0;
    virtual void getTexParameterfv(WGC3Denum target, WGC3Denum pname, WGC3Dfloat* value) = 0;
    virtual void getTexParameteriv(WGC3Denum target, WGC3Denum pname, WGC3Dint* value) = 0;
    virtual void getUniformfv(WebGLId program, WGC3Dint location, WGC3Dfloat* value) = 0;
    virtual void getUniformiv(WebGLId program, WGC3Dint location, WGC3Dint* value) = 0;
    virtual WGC3Dint getUniformLocation(WebGLId program, const WGC3Dchar* name) = 0;
    virtual void getVertexAttribfv(WGC3Duint index, WGC3Denum pname, WGC3Dfloat* value) = 0;
    virtual void getVertexAttribiv(WGC3Duint index, WGC3Denum pname, WGC3Dint* value) = 0;
    virtual WGC3Dsizeiptr getVertexAttribOffset(WGC3Duint index, WGC3Denum pname) = 0;

    virtual void hint(WGC3Denum target, WGC3Denum mode) = 0;
    virtual WGC3Dboolean isBuffer(WebGLId buffer) = 0;
    virtual WGC3Dboolean isEnabled(WGC3Denum cap) = 0;
    virtual WGC3Dboolean isFramebuffer(WebGLId framebuffer) = 0;
    virtual WGC3Dboolean isProgram(WebGLId program) = 0;
    virtual WGC3Dboolean isRenderbuffer(WebGLId renderbuffer) = 0;
    virtual WGC3Dboolean isShader(WebGLId shader) = 0;
    virtual WGC3Dboolean isTexture(WebGLId texture) = 0;
    virtual void lineWidth(WGC3Dfloat) = 0;
    virtual void linkProgram(WebGLId program) = 0;
    virtual void pixelStorei(WGC3Denum pname, WGC3Dint param) = 0;
    virtual void polygonOffset(WGC3Dfloat factor, WGC3Dfloat units) = 0;

    virtual void readPixels(WGC3Dint x, WGC3Dint y, WGC3Dsizei width, WGC3Dsizei height, WGC3Denum format, WGC3Denum type, void* pixels) = 0;

    virtual void releaseShaderCompiler() = 0;

    virtual void renderbufferStorage(WGC3Denum target, WGC3Denum internalformat, WGC3Dsizei width, WGC3Dsizei height) = 0;
    virtual void sampleCoverage(WGC3Dclampf value, WGC3Dboolean invert) = 0;
    virtual void scissor(WGC3Dint x, WGC3Dint y, WGC3Dsizei width, WGC3Dsizei height) = 0;
    virtual void shaderSource(WebGLId shader, const WGC3Dchar* string) = 0;
    virtual void stencilFunc(WGC3Denum func, WGC3Dint ref, WGC3Duint mask) = 0;
    virtual void stencilFuncSeparate(WGC3Denum face, WGC3Denum func, WGC3Dint ref, WGC3Duint mask) = 0;
    virtual void stencilMask(WGC3Duint mask) = 0;
    virtual void stencilMaskSeparate(WGC3Denum face, WGC3Duint mask) = 0;
    virtual void stencilOp(WGC3Denum fail, WGC3Denum zfail, WGC3Denum zpass) = 0;
    virtual void stencilOpSeparate(WGC3Denum face, WGC3Denum fail, WGC3Denum zfail, WGC3Denum zpass) = 0;

    virtual void texImage2D(WGC3Denum target, WGC3Dint level, WGC3Denum internalformat, WGC3Dsizei width, WGC3Dsizei height, WGC3Dint border, WGC3Denum format, WGC3Denum type, const void* pixels) = 0;

    virtual void texParameterf(WGC3Denum target, WGC3Denum pname, WGC3Dfloat param) = 0;
    virtual void texParameteri(WGC3Denum target, WGC3Denum pname, WGC3Dint param) = 0;

    virtual void texSubImage2D(WGC3Denum target, WGC3Dint level, WGC3Dint xoffset, WGC3Dint yoffset, WGC3Dsizei width, WGC3Dsizei height, WGC3Denum format, WGC3Denum type, const void* pixels) = 0;

    virtual void uniform1f(WGC3Dint location, WGC3Dfloat x) = 0;
    virtual void uniform1fv(WGC3Dint location, WGC3Dsizei count, const WGC3Dfloat* v) = 0;
    virtual void uniform1i(WGC3Dint location, WGC3Dint x) = 0;
    virtual void uniform1iv(WGC3Dint location, WGC3Dsizei count, const WGC3Dint* v) = 0;
    virtual void uniform2f(WGC3Dint location, WGC3Dfloat x, WGC3Dfloat y) = 0;
    virtual void uniform2fv(WGC3Dint location, WGC3Dsizei count, const WGC3Dfloat* v) = 0;
    virtual void uniform2i(WGC3Dint location, WGC3Dint x, WGC3Dint y) = 0;
    virtual void uniform2iv(WGC3Dint location, WGC3Dsizei count, const WGC3Dint* v) = 0;
    virtual void uniform3f(WGC3Dint location, WGC3Dfloat x, WGC3Dfloat y, WGC3Dfloat z) = 0;
    virtual void uniform3fv(WGC3Dint location, WGC3Dsizei count, const WGC3Dfloat* v) = 0;
    virtual void uniform3i(WGC3Dint location, WGC3Dint x, WGC3Dint y, WGC3Dint z) = 0;
    virtual void uniform3iv(WGC3Dint location, WGC3Dsizei count, const WGC3Dint* v) = 0;
    virtual void uniform4f(WGC3Dint location, WGC3Dfloat x, WGC3Dfloat y, WGC3Dfloat z, WGC3Dfloat w) = 0;
    virtual void uniform4fv(WGC3Dint location, WGC3Dsizei count, const WGC3Dfloat* v) = 0;
    virtual void uniform4i(WGC3Dint location, WGC3Dint x, WGC3Dint y, WGC3Dint z, WGC3Dint w) = 0;
    virtual void uniform4iv(WGC3Dint location, WGC3Dsizei count, const WGC3Dint* v) = 0;
    virtual void uniformMatrix2fv(WGC3Dint location, WGC3Dsizei count, WGC3Dboolean transpose, const WGC3Dfloat* value) = 0;
    virtual void uniformMatrix3fv(WGC3Dint location, WGC3Dsizei count, WGC3Dboolean transpose, const WGC3Dfloat* value) = 0;
    virtual void uniformMatrix4fv(WGC3Dint location, WGC3Dsizei count, WGC3Dboolean transpose, const WGC3Dfloat* value) = 0;

    virtual void useProgram(WebGLId program) = 0;
    virtual void validateProgram(WebGLId program) = 0;

    virtual void vertexAttrib1f(WGC3Duint index, WGC3Dfloat x) = 0;
    virtual void vertexAttrib1fv(WGC3Duint index, const WGC3Dfloat* values) = 0;
    virtual void vertexAttrib2f(WGC3Duint index, WGC3Dfloat x, WGC3Dfloat y) = 0;
    virtual void vertexAttrib2fv(WGC3Duint index, const WGC3Dfloat* values) = 0;
    virtual void vertexAttrib3f(WGC3Duint index, WGC3Dfloat x, WGC3Dfloat y, WGC3Dfloat z) = 0;
    virtual void vertexAttrib3fv(WGC3Duint index, const WGC3Dfloat* values) = 0;
    virtual void vertexAttrib4f(WGC3Duint index, WGC3Dfloat x, WGC3Dfloat y, WGC3Dfloat z, WGC3Dfloat w) = 0;
    virtual void vertexAttrib4fv(WGC3Duint index, const WGC3Dfloat* values) = 0;
    virtual void vertexAttribPointer(WGC3Duint index, WGC3Dint size, WGC3Denum type, WGC3Dboolean normalized,
                                     WGC3Dsizei stride, WGC3Dintptr offset) = 0;

    virtual void viewport(WGC3Dint x, WGC3Dint y, WGC3Dsizei width, WGC3Dsizei height) = 0;

    // Support for buffer creation and deletion.
    virtual void genBuffers(WGC3Dsizei count, WebGLId* ids) { }
    virtual void genFramebuffers(WGC3Dsizei count, WebGLId* ids) { }
    virtual void genRenderbuffers(WGC3Dsizei count, WebGLId* ids) { }
    virtual void genTextures(WGC3Dsizei count, WebGLId* ids) { }

    virtual void deleteBuffers(WGC3Dsizei count, WebGLId* ids) { }
    virtual void deleteFramebuffers(WGC3Dsizei count, WebGLId* ids) { }
    virtual void deleteRenderbuffers(WGC3Dsizei count, WebGLId* ids) { }
    virtual void deleteTextures(WGC3Dsizei count, WebGLId* ids) { }

    virtual WebGLId createBuffer() = 0;
    virtual WebGLId createFramebuffer() = 0;
    virtual WebGLId createRenderbuffer() = 0;
    virtual WebGLId createTexture() = 0;

    virtual void deleteBuffer(WebGLId) = 0;
    virtual void deleteFramebuffer(WebGLId) = 0;
    virtual void deleteRenderbuffer(WebGLId) = 0;
    virtual void deleteTexture(WebGLId) = 0;

    virtual WebGLId createProgram() = 0;
    virtual WebGLId createShader(WGC3Denum) = 0;

    virtual void deleteShader(WebGLId) = 0;
    virtual void deleteProgram(WebGLId) = 0;

    virtual void setContextLostCallback(WebGraphicsContextLostCallback* callback) { }
    virtual void setErrorMessageCallback(WebGraphicsErrorMessageCallback* callback) { }
    // GL_ARB_robustness
    //
    // This entry point must provide slightly different semantics than
    // the GL_ARB_robustness extension; specifically, the lost context
    // state is sticky, rather than reported only once.
    virtual WGC3Denum getGraphicsResetStatusARB() { return 0; /* GL_NO_ERROR */ }

    virtual WebString getTranslatedShaderSourceANGLE(WebGLId shader) = 0;

    // GL_CHROMIUM_iosurface
    virtual void texImageIOSurface2DCHROMIUM(WGC3Denum target, WGC3Dint width, WGC3Dint height, WGC3Duint ioSurfaceId, WGC3Duint plane) { }

    // GL_EXT_texture_storage
    virtual void texStorage2DEXT(WGC3Denum target, WGC3Dint levels, WGC3Duint internalformat,
                                 WGC3Dint width, WGC3Dint height) { }

    // GL_EXT_occlusion_query
    virtual WebGLId createQueryEXT() { return 0; }
    virtual void deleteQueryEXT(WebGLId query) { }
    virtual WGC3Dboolean isQueryEXT(WebGLId query) { return false; }
    virtual void beginQueryEXT(WGC3Denum target, WebGLId query) { }
    virtual void endQueryEXT(WGC3Denum target) { }
    virtual void getQueryivEXT(WGC3Denum target, WGC3Denum pname, WGC3Dint* params) { }
    virtual void getQueryObjectuivEXT(WebGLId query, WGC3Denum pname, WGC3Duint* params) { }

    // GL_CHROMIUM_bind_uniform_location
    virtual void bindUniformLocationCHROMIUM(WebGLId program, WGC3Dint location, const WGC3Dchar* uniform) { }

    // GL_CHROMIUM_copy_texture
    virtual void copyTextureCHROMIUM(WGC3Denum target, WGC3Duint sourceId,
        WGC3Duint destId, WGC3Dint level, WGC3Denum internalFormat, WGC3Denum destType) { }

    // GL_CHROMIUM_shallow_flush
    virtual void shallowFlushCHROMIUM() { }
    virtual void shallowFinishCHROMIUM() { }

    // GL_CHROMIUM_texture_mailbox
    virtual void genMailboxCHROMIUM(WGC3Dbyte* mailbox) { }
    virtual void produceTextureCHROMIUM(WGC3Denum target, const WGC3Dbyte* mailbox) { }
    virtual void produceTextureDirectCHROMIUM(WebGLId texture, WGC3Denum target, const WGC3Dbyte* mailbox) { }

    virtual void consumeTextureCHROMIUM(WGC3Denum target, const WGC3Dbyte* mailbox) { }
    virtual WebGLId createAndConsumeTextureCHROMIUM(WGC3Denum target, const WGC3Dbyte* mailbox) { return 0; }

    // GL_EXT_debug_marker
    virtual void insertEventMarkerEXT(const WGC3Dchar* marker) { }
    virtual void pushGroupMarkerEXT(const WGC3Dchar* marker) { }
    virtual void popGroupMarkerEXT(void) { }

    // GL_OES_vertex_array_object
    virtual WebGLId createVertexArrayOES() { return 0; }
    virtual void deleteVertexArrayOES(WebGLId array) { }
    virtual WGC3Dboolean isVertexArrayOES(WebGLId array) { return false; }
    virtual void bindVertexArrayOES(WebGLId array) { }

    // GL_CHROMIUM_texture_from_image
    virtual void bindTexImage2DCHROMIUM(WGC3Denum target, WGC3Dint imageId) { }
    virtual void releaseTexImage2DCHROMIUM(WGC3Denum target, WGC3Dint imageId) { }

    // GL_CHROMIUM_pixel_transfer_buffer_object
    virtual void* mapBufferCHROMIUM(WGC3Denum target, WGC3Denum access) { return 0; }
    virtual WGC3Dboolean unmapBufferCHROMIUM(WGC3Denum target) { return false; }

    // GL_CHROMIUM_async_pixel_transfers
    virtual void asyncTexImage2DCHROMIUM(WGC3Denum target, WGC3Dint level, WGC3Denum internalformat, WGC3Dsizei width, WGC3Dsizei height, WGC3Dint border, WGC3Denum format, WGC3Denum type, const void* pixels) { }
    virtual void asyncTexSubImage2DCHROMIUM(WGC3Denum target, WGC3Dint level, WGC3Dint xoffset, WGC3Dint yoffset, WGC3Dsizei width, WGC3Dsizei height, WGC3Denum format, WGC3Denum type, const void* pixels) { }
    virtual void waitAsyncTexImage2DCHROMIUM(WGC3Denum) { }

    // GL_EXT_draw_buffers
    virtual void drawBuffersEXT(WGC3Dsizei n, const WGC3Denum* bufs) { }

    virtual GrGLInterface* createGrGLInterface() { return 0; }

    // GL_CHROMIUM_map_image
    virtual WGC3Duint createImageCHROMIUM(WGC3Dsizei width, WGC3Dsizei height, WGC3Denum internalformat, WGC3Denum usage) { return 0; }
    virtual void destroyImageCHROMIUM(WGC3Duint imageId) { }
    virtual void getImageParameterivCHROMIUM(WGC3Duint imageId, WGC3Denum pname, WGC3Dint* params) { }
    virtual void* mapImageCHROMIUM(WGC3Duint imageId) { return 0; }
    virtual void unmapImageCHROMIUM(WGC3Duint imageId) { }

    // GL_ANGLE_instanced_arrays
    virtual void drawArraysInstancedANGLE(WGC3Denum mode, WGC3Dint first, WGC3Dsizei count, WGC3Dsizei primcount) { }
    virtual void drawElementsInstancedANGLE(WGC3Denum mode, WGC3Dsizei count, WGC3Denum type, WGC3Dintptr offset, WGC3Dsizei primcount) { }
    virtual void vertexAttribDivisorANGLE(WGC3Duint index, WGC3Duint divisor) { }

    // GL_EXT_multisampled_render_to_texture
    virtual void framebufferTexture2DMultisampleEXT(WGC3Denum target, WGC3Denum attachment, WGC3Denum textarget, WebGLId texture, WGC3Dint level, WGC3Dsizei samples) { }
    virtual void renderbufferStorageMultisampleEXT(WGC3Denum target, WGC3Dsizei samples, WGC3Denum internalformat, WGC3Dsizei width, WGC3Dsizei height) { };
};

} // namespace blink

#endif
