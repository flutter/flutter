/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef MockWebGraphicsContext3D_h
#define MockWebGraphicsContext3D_h

#include "platform/PlatformExport.h"
#include "public/platform/WebGraphicsContext3D.h"

namespace blink {

// WebGraphicsContext3D base class for use in WebKit unit tests.
// All operations are no-ops (returning 0 if necessary).
class MockWebGraphicsContext3D : public WebGraphicsContext3D {
public:
    MockWebGraphicsContext3D()
        : m_nextTextureId(1)
        , m_contextLost(false)
    {
    }

    virtual void prepareTexture() { }

    virtual void postSubBufferCHROMIUM(int x, int y, int width, int height) { }

    virtual void synthesizeGLError(WGC3Denum) { }

    virtual bool isContextLost() { return m_contextLost; }

    virtual void* mapBufferSubDataCHROMIUM(WGC3Denum target, WGC3Dintptr offset, WGC3Dsizeiptr size, WGC3Denum access) { return 0; }
    virtual void unmapBufferSubDataCHROMIUM(const void*) { }
    virtual void* mapTexSubImage2DCHROMIUM(WGC3Denum target, WGC3Dint level, WGC3Dint xoffset, WGC3Dint yoffset, WGC3Dsizei width, WGC3Dsizei height, WGC3Denum format, WGC3Denum type, WGC3Denum access) { return 0; }
    virtual void unmapTexSubImage2DCHROMIUM(const void*) { }

    virtual void setVisibilityCHROMIUM(bool visible) { }

    virtual void discardFramebufferEXT(WGC3Denum target, WGC3Dsizei numAttachments, const WGC3Denum* attachments) { }
    virtual void ensureFramebufferCHROMIUM() { }

    virtual WebString getRequestableExtensionsCHROMIUM() { return WebString(); }
    virtual void requestExtensionCHROMIUM(const char*) { }

    virtual void blitFramebufferCHROMIUM(WGC3Dint srcX0, WGC3Dint srcY0, WGC3Dint srcX1, WGC3Dint srcY1, WGC3Dint dstX0, WGC3Dint dstY0, WGC3Dint dstX1, WGC3Dint dstY1, WGC3Dbitfield mask, WGC3Denum filter) { }
    virtual void renderbufferStorageMultisampleCHROMIUM(WGC3Denum target, WGC3Dsizei samples, WGC3Denum internalformat, WGC3Dsizei width, WGC3Dsizei height) { }

    virtual void activeTexture(WGC3Denum texture) { }
    virtual void attachShader(WebGLId program, WebGLId shader) { }
    virtual void bindAttribLocation(WebGLId program, WGC3Duint index, const WGC3Dchar* name) { }
    virtual void bindBuffer(WGC3Denum target, WebGLId buffer) { }
    virtual void bindFramebuffer(WGC3Denum target, WebGLId framebuffer) { }
    virtual void bindRenderbuffer(WGC3Denum target, WebGLId renderbuffer) { }
    virtual void bindTexture(WGC3Denum target, WebGLId texture) { }
    virtual void blendColor(WGC3Dclampf red, WGC3Dclampf green, WGC3Dclampf blue, WGC3Dclampf alpha) { }
    virtual void blendEquation(WGC3Denum mode) { }
    virtual void blendEquationSeparate(WGC3Denum modeRGB, WGC3Denum modeAlpha) { }
    virtual void blendFunc(WGC3Denum sfactor, WGC3Denum dfactor) { }
    virtual void blendFuncSeparate(WGC3Denum srcRGB, WGC3Denum dstRGB, WGC3Denum srcAlpha, WGC3Denum dstAlpha) { }

    virtual void bufferData(WGC3Denum target, WGC3Dsizeiptr size, const void* data, WGC3Denum usage) { }
    virtual void bufferSubData(WGC3Denum target, WGC3Dintptr offset, WGC3Dsizeiptr size, const void* data) { }

    virtual WGC3Denum checkFramebufferStatus(WGC3Denum target)
    {
        return GL_FRAMEBUFFER_COMPLETE;
    }

    virtual void clear(WGC3Dbitfield mask) { }
    virtual void clearColor(WGC3Dclampf red, WGC3Dclampf green, WGC3Dclampf blue, WGC3Dclampf alpha) { }
    virtual void clearDepth(WGC3Dclampf depth) { }
    virtual void clearStencil(WGC3Dint s) { }
    virtual void colorMask(WGC3Dboolean red, WGC3Dboolean green, WGC3Dboolean blue, WGC3Dboolean alpha) { }
    virtual void compileShader(WebGLId shader) { }

    virtual void compressedTexImage2D(WGC3Denum target, WGC3Dint level, WGC3Denum internalformat, WGC3Dsizei width, WGC3Dsizei height, WGC3Dint border, WGC3Dsizei imageSize, const void* data) { }
    virtual void compressedTexSubImage2D(WGC3Denum target, WGC3Dint level, WGC3Dint xoffset, WGC3Dint yoffset, WGC3Dsizei width, WGC3Dsizei height, WGC3Denum format, WGC3Dsizei imageSize, const void* data) { }
    virtual void copyTexImage2D(WGC3Denum target, WGC3Dint level, WGC3Denum internalformat, WGC3Dint x, WGC3Dint y, WGC3Dsizei width, WGC3Dsizei height, WGC3Dint border) { }
    virtual void copyTexSubImage2D(WGC3Denum target, WGC3Dint level, WGC3Dint xoffset, WGC3Dint yoffset, WGC3Dint x, WGC3Dint y, WGC3Dsizei width, WGC3Dsizei height) { }
    virtual void cullFace(WGC3Denum mode) { }
    virtual void depthFunc(WGC3Denum func) { }
    virtual void depthMask(WGC3Dboolean flag) { }
    virtual void depthRange(WGC3Dclampf zNear, WGC3Dclampf zFar) { }
    virtual void detachShader(WebGLId program, WebGLId shader) { }
    virtual void disable(WGC3Denum cap) { }
    virtual void disableVertexAttribArray(WGC3Duint index) { }
    virtual void drawArrays(WGC3Denum mode, WGC3Dint first, WGC3Dsizei count) { }
    virtual void drawElements(WGC3Denum mode, WGC3Dsizei count, WGC3Denum type, WGC3Dintptr offset) { }

    virtual void enable(WGC3Denum cap) { }
    virtual void enableVertexAttribArray(WGC3Duint index) { }
    virtual void finish() { }
    virtual void flush() { }
    virtual void framebufferRenderbuffer(WGC3Denum target, WGC3Denum attachment, WGC3Denum renderbuffertarget, WebGLId renderbuffer) { }
    virtual void framebufferTexture2D(WGC3Denum target, WGC3Denum attachment, WGC3Denum textarget, WebGLId texture, WGC3Dint level) { }
    virtual void frontFace(WGC3Denum mode) { }
    virtual void generateMipmap(WGC3Denum target) { }

    virtual bool getActiveAttrib(WebGLId program, WGC3Duint index, ActiveInfo&) { return false; }
    virtual bool getActiveUniform(WebGLId program, WGC3Duint index, ActiveInfo&) { return false; }
    virtual void getAttachedShaders(WebGLId program, WGC3Dsizei maxCount, WGC3Dsizei* count, WebGLId* shaders) { }
    virtual WGC3Dint getAttribLocation(WebGLId program, const WGC3Dchar* name) { return 0; }
    virtual void getBooleanv(WGC3Denum pname, WGC3Dboolean* value) { }
    virtual void getBufferParameteriv(WGC3Denum target, WGC3Denum pname, WGC3Dint* value) { }
    virtual Attributes getContextAttributes() { return m_attrs; }
    virtual WGC3Denum getError() { return 0; }
    virtual void getFloatv(WGC3Denum pname, WGC3Dfloat* value) { }
    virtual void getFramebufferAttachmentParameteriv(WGC3Denum target, WGC3Denum attachment, WGC3Denum pname, WGC3Dint* value) { }

    virtual void getIntegerv(WGC3Denum pname, WGC3Dint* value)
    {
        if (pname == GL_MAX_TEXTURE_SIZE)
            *value = 1024;
    }

    virtual void getProgramiv(WebGLId program, WGC3Denum pname, WGC3Dint* value)
    {
        if (pname == GL_LINK_STATUS)
            *value = 1;
    }

    virtual WebString getProgramInfoLog(WebGLId program) { return WebString(); }
    virtual void getRenderbufferParameteriv(WGC3Denum target, WGC3Denum pname, WGC3Dint* value) { }

    virtual void getShaderiv(WebGLId shader, WGC3Denum pname, WGC3Dint* value)
    {
        if (pname == GL_COMPILE_STATUS)
            *value = 1;
    }

    virtual WebString getShaderInfoLog(WebGLId shader) { return WebString(); }
    virtual void getShaderPrecisionFormat(WGC3Denum shadertype, WGC3Denum precisiontype, WGC3Dint* range, WGC3Dint* precision) { }
    virtual WebString getShaderSource(WebGLId shader) { return WebString(); }
    virtual WebString getString(WGC3Denum name) { return WebString(); }
    virtual void getTexParameterfv(WGC3Denum target, WGC3Denum pname, WGC3Dfloat* value) { }
    virtual void getTexParameteriv(WGC3Denum target, WGC3Denum pname, WGC3Dint* value) { }
    virtual void getUniformfv(WebGLId program, WGC3Dint location, WGC3Dfloat* value) { }
    virtual void getUniformiv(WebGLId program, WGC3Dint location, WGC3Dint* value) { }
    virtual WGC3Dint getUniformLocation(WebGLId program, const WGC3Dchar* name) { return 0; }
    virtual void getVertexAttribfv(WGC3Duint index, WGC3Denum pname, WGC3Dfloat* value) { }
    virtual void getVertexAttribiv(WGC3Duint index, WGC3Denum pname, WGC3Dint* value) { }
    virtual WGC3Dsizeiptr getVertexAttribOffset(WGC3Duint index, WGC3Denum pname) { return 0; }

    virtual void hint(WGC3Denum target, WGC3Denum mode) { }
    virtual WGC3Dboolean isBuffer(WebGLId buffer) { return false; }
    virtual WGC3Dboolean isEnabled(WGC3Denum cap) { return false; }
    virtual WGC3Dboolean isFramebuffer(WebGLId framebuffer) { return false; }
    virtual WGC3Dboolean isProgram(WebGLId program) { return false; }
    virtual WGC3Dboolean isRenderbuffer(WebGLId renderbuffer) { return false; }
    virtual WGC3Dboolean isShader(WebGLId shader) { return false; }
    virtual WGC3Dboolean isTexture(WebGLId texture) { return false; }
    virtual void lineWidth(WGC3Dfloat) { }
    virtual void linkProgram(WebGLId program) { }
    virtual void pixelStorei(WGC3Denum pname, WGC3Dint param) { }
    virtual void polygonOffset(WGC3Dfloat factor, WGC3Dfloat units) { }

    virtual void readPixels(WGC3Dint x, WGC3Dint y, WGC3Dsizei width, WGC3Dsizei height, WGC3Denum format, WGC3Denum type, void* pixels) { }

    virtual void releaseShaderCompiler() { }

    virtual void renderbufferStorage(WGC3Denum target, WGC3Denum internalformat, WGC3Dsizei width, WGC3Dsizei height) { }
    virtual void sampleCoverage(WGC3Dclampf value, WGC3Dboolean invert) { }
    virtual void scissor(WGC3Dint x, WGC3Dint y, WGC3Dsizei width, WGC3Dsizei height) { }
    virtual void shaderSource(WebGLId shader, const WGC3Dchar* string) { }
    virtual void stencilFunc(WGC3Denum func, WGC3Dint ref, WGC3Duint mask) { }
    virtual void stencilFuncSeparate(WGC3Denum face, WGC3Denum func, WGC3Dint ref, WGC3Duint mask) { }
    virtual void stencilMask(WGC3Duint mask) { }
    virtual void stencilMaskSeparate(WGC3Denum face, WGC3Duint mask) { }
    virtual void stencilOp(WGC3Denum fail, WGC3Denum zfail, WGC3Denum zpass) { }
    virtual void stencilOpSeparate(WGC3Denum face, WGC3Denum fail, WGC3Denum zfail, WGC3Denum zpass) { }

    virtual void texImage2D(WGC3Denum target, WGC3Dint level, WGC3Denum internalformat, WGC3Dsizei width, WGC3Dsizei height, WGC3Dint border, WGC3Denum format, WGC3Denum type, const void* pixels) { }

    virtual void texParameterf(WGC3Denum target, WGC3Denum pname, WGC3Dfloat param) { }
    virtual void texParameteri(WGC3Denum target, WGC3Denum pname, WGC3Dint param) { }

    virtual void texSubImage2D(WGC3Denum target, WGC3Dint level, WGC3Dint xoffset, WGC3Dint yoffset, WGC3Dsizei width, WGC3Dsizei height, WGC3Denum format, WGC3Denum type, const void* pixels) { }

    virtual void uniform1f(WGC3Dint location, WGC3Dfloat x) { }
    virtual void uniform1fv(WGC3Dint location, WGC3Dsizei count, const WGC3Dfloat* v) { }
    virtual void uniform1i(WGC3Dint location, WGC3Dint x) { }
    virtual void uniform1iv(WGC3Dint location, WGC3Dsizei count, const WGC3Dint* v) { }
    virtual void uniform2f(WGC3Dint location, WGC3Dfloat x, WGC3Dfloat y) { }
    virtual void uniform2fv(WGC3Dint location, WGC3Dsizei count, const WGC3Dfloat* v) { }
    virtual void uniform2i(WGC3Dint location, WGC3Dint x, WGC3Dint y) { }
    virtual void uniform2iv(WGC3Dint location, WGC3Dsizei count, const WGC3Dint* v) { }
    virtual void uniform3f(WGC3Dint location, WGC3Dfloat x, WGC3Dfloat y, WGC3Dfloat z) { }
    virtual void uniform3fv(WGC3Dint location, WGC3Dsizei count, const WGC3Dfloat* v) { }
    virtual void uniform3i(WGC3Dint location, WGC3Dint x, WGC3Dint y, WGC3Dint z) { }
    virtual void uniform3iv(WGC3Dint location, WGC3Dsizei count, const WGC3Dint* v) { }
    virtual void uniform4f(WGC3Dint location, WGC3Dfloat x, WGC3Dfloat y, WGC3Dfloat z, WGC3Dfloat w) { }
    virtual void uniform4fv(WGC3Dint location, WGC3Dsizei count, const WGC3Dfloat* v) { }
    virtual void uniform4i(WGC3Dint location, WGC3Dint x, WGC3Dint y, WGC3Dint z, WGC3Dint w) { }
    virtual void uniform4iv(WGC3Dint location, WGC3Dsizei count, const WGC3Dint* v) { }
    virtual void uniformMatrix2fv(WGC3Dint location, WGC3Dsizei count, WGC3Dboolean transpose, const WGC3Dfloat* value) { }
    virtual void uniformMatrix3fv(WGC3Dint location, WGC3Dsizei count, WGC3Dboolean transpose, const WGC3Dfloat* value) { }
    virtual void uniformMatrix4fv(WGC3Dint location, WGC3Dsizei count, WGC3Dboolean transpose, const WGC3Dfloat* value) { }

    virtual void useProgram(WebGLId program) { }
    virtual void validateProgram(WebGLId program) { }

    virtual void vertexAttrib1f(WGC3Duint index, WGC3Dfloat x) { }
    virtual void vertexAttrib1fv(WGC3Duint index, const WGC3Dfloat* values) { }
    virtual void vertexAttrib2f(WGC3Duint index, WGC3Dfloat x, WGC3Dfloat y) { }
    virtual void vertexAttrib2fv(WGC3Duint index, const WGC3Dfloat* values) { }
    virtual void vertexAttrib3f(WGC3Duint index, WGC3Dfloat x, WGC3Dfloat y, WGC3Dfloat z) { }
    virtual void vertexAttrib3fv(WGC3Duint index, const WGC3Dfloat* values) { }
    virtual void vertexAttrib4f(WGC3Duint index, WGC3Dfloat x, WGC3Dfloat y, WGC3Dfloat z, WGC3Dfloat w) { }
    virtual void vertexAttrib4fv(WGC3Duint index, const WGC3Dfloat* values) { }
    virtual void vertexAttribPointer(WGC3Duint index, WGC3Dint size, WGC3Denum type, WGC3Dboolean normalized, WGC3Dsizei stride, WGC3Dintptr offset) { }

    virtual void viewport(WGC3Dint x, WGC3Dint y, WGC3Dsizei width, WGC3Dsizei height) { }

    virtual void genBuffers(WGC3Dsizei count, WebGLId* ids)
    {
        for (int i = 0; i < count; ++i)
            ids[i] = 1;
    }
    virtual void genFramebuffers(WGC3Dsizei count, WebGLId* ids)
    {
        for (int i = 0; i < count; ++i)
            ids[i] = 1;
    }
    virtual void genRenderbuffers(WGC3Dsizei count, WebGLId* ids)
    {
        for (int i = 0; i < count; ++i)
            ids[i] = 1;
    }
    virtual void genTextures(WGC3Dsizei count, WebGLId* ids)
    {
        for (int i = 0; i < count; ++i)
            ids[i] = m_nextTextureId++;
    }

    virtual void deleteBuffers(WGC3Dsizei count, WebGLId* ids) { }
    virtual void deleteFramebuffers(WGC3Dsizei count, WebGLId* ids) { }
    virtual void deleteRenderbuffers(WGC3Dsizei count, WebGLId* ids) { }
    virtual void deleteTextures(WGC3Dsizei count, WebGLId* ids) { }

    virtual WebGLId createBuffer() { return 1; }
    virtual WebGLId createFramebuffer() { return 1; }
    virtual WebGLId createRenderbuffer() { return 1; }
    virtual WebGLId createTexture() { return m_nextTextureId++; }

    virtual void deleteBuffer(WebGLId) { }
    virtual void deleteFramebuffer(WebGLId) { }
    virtual void deleteRenderbuffer(WebGLId) { }
    virtual void deleteTexture(WebGLId) { }

    virtual WebGLId createProgram() { return 1; }
    virtual WebGLId createShader(WGC3Denum) { return 1; }

    virtual void deleteProgram(WebGLId) { }
    virtual void deleteShader(WebGLId) { }

    virtual void texStorage2DEXT(WGC3Denum target, WGC3Dint levels, WGC3Duint internalformat, WGC3Dint width, WGC3Dint height) { }

    virtual WebGLId createQueryEXT() { return 1; }
    virtual void deleteQueryEXT(WebGLId) { }
    virtual GLboolean isQueryEXT(WebGLId) { return true; }
    virtual void beginQueryEXT(GLenum, WebGLId) { }
    virtual void endQueryEXT(GLenum) { }
    virtual void getQueryivEXT(GLenum, GLenum, GLint*) { }
    virtual void getQueryObjectuivEXT(WebGLId, GLenum, GLuint*) { }

    virtual WebString getTranslatedShaderSourceANGLE(WebGLId) { return WebString(); }

    void fakeContextLost() { m_contextLost = true; }
protected:
    unsigned m_nextTextureId;
    bool m_contextLost;
    Attributes m_attrs;
};

} // namespace blink

#endif // MockWebGraphicsContext3D_h
