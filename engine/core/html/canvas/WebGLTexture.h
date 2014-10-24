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

#ifndef WebGLTexture_h
#define WebGLTexture_h

#include "bindings/core/v8/ScriptWrappable.h"
#include "core/html/canvas/WebGLSharedObject.h"
#include "wtf/PassRefPtr.h"
#include "wtf/Vector.h"

namespace blink {

class WebGLTexture final : public WebGLSharedObject, public ScriptWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    enum TextureExtensionFlag {
        NoTextureExtensionEnabled = 0,
        TextureFloatLinearExtensionEnabled = 1 << 0,
        TextureHalfFloatLinearExtensionEnabled = 1 << 1
    };
    virtual ~WebGLTexture();

    static PassRefPtrWillBeRawPtr<WebGLTexture> create(WebGLRenderingContextBase*);

    void setTarget(GLenum target, GLint maxLevel);
    void setParameteri(GLenum pname, GLint param);
    void setParameterf(GLenum pname, GLfloat param);

    GLenum getTarget() const { return m_target; }

    int getMinFilter() const { return m_minFilter; }

    void setLevelInfo(GLenum target, GLint level, GLenum internalFormat, GLsizei width, GLsizei height, GLenum type);

    bool canGenerateMipmaps();
    // Generate all level information.
    void generateMipmapLevelInfo();

    GLenum getInternalFormat(GLenum target, GLint level) const;
    GLenum getType(GLenum target, GLint level) const;
    GLsizei getWidth(GLenum target, GLint level) const;
    GLsizei getHeight(GLenum target, GLint level) const;
    bool isValid(GLenum target, GLint level) const;

    // Whether width/height is NotPowerOfTwo.
    static bool isNPOT(GLsizei, GLsizei);

    bool isNPOT() const;
    // Determine if texture sampling should always return [0, 0, 0, 1] (OpenGL ES 2.0 Sec 3.8.2).
    bool needToUseBlackTexture(TextureExtensionFlag) const;

    bool hasEverBeenBound() const { return object() && m_target; }

    static GLint computeLevelCount(GLsizei width, GLsizei height);

protected:
    explicit WebGLTexture(WebGLRenderingContextBase*);

    virtual void deleteObjectImpl(blink::WebGraphicsContext3D*, Platform3DObject) override;

private:
    class LevelInfo {
    public:
        LevelInfo()
            : valid(false)
            , internalFormat(0)
            , width(0)
            , height(0)
            , type(0)
        {
        }

        void setInfo(GLenum internalFmt, GLsizei w, GLsizei h, GLenum tp)
        {
            valid = true;
            internalFormat = internalFmt;
            width = w;
            height = h;
            type = tp;
        }

        bool valid;
        GLenum internalFormat;
        GLsizei width;
        GLsizei height;
        GLenum type;
    };

    virtual bool isTexture() const override { return true; }

    void update();

    int mapTargetToIndex(GLenum) const;

    const LevelInfo* getLevelInfo(GLenum target, GLint level) const;

    GLenum m_target;

    GLenum m_minFilter;
    GLenum m_magFilter;
    GLenum m_wrapS;
    GLenum m_wrapT;

    Vector<Vector<LevelInfo> > m_info;

    bool m_isNPOT;
    bool m_isCubeComplete;
    bool m_isComplete;
    bool m_needToUseBlackTexture;
    bool m_isFloatType;
    bool m_isHalfFloatType;
};

} // namespace blink

#endif // WebGLTexture_h
