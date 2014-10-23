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

#include "core/html/canvas/WebGLTexture.h"

#include "core/html/canvas/WebGLRenderingContextBase.h"

namespace blink {

PassRefPtrWillBeRawPtr<WebGLTexture> WebGLTexture::create(WebGLRenderingContextBase* ctx)
{
    return adoptRefWillBeNoop(new WebGLTexture(ctx));
}

WebGLTexture::WebGLTexture(WebGLRenderingContextBase* ctx)
    : WebGLSharedObject(ctx)
    , m_target(0)
    , m_minFilter(GL_NEAREST_MIPMAP_LINEAR)
    , m_magFilter(GL_LINEAR)
    , m_wrapS(GL_REPEAT)
    , m_wrapT(GL_REPEAT)
    , m_isNPOT(false)
    , m_isCubeComplete(false)
    , m_isComplete(false)
    , m_needToUseBlackTexture(false)
    , m_isFloatType(false)
    , m_isHalfFloatType(false)
{
    ScriptWrappable::init(this);
    setObject(ctx->webContext()->createTexture());
}

WebGLTexture::~WebGLTexture()
{
    // Always perform detach here to ensure that platform object
    // deletion happens with Oilpan enabled. It keeps the code regular
    // to do it with or without Oilpan enabled.
    //
    // See comment in WebGLBuffer's destructor for additional
    // information on why this is done for WebGLSharedObject-derived
    // objects.
    detachAndDeleteObject();
}

void WebGLTexture::setTarget(GLenum target, GLint maxLevel)
{
    if (!object())
        return;
    // Target is finalized the first time bindTexture() is called.
    if (m_target)
        return;
    switch (target) {
    case GL_TEXTURE_2D:
        m_target = target;
        m_info.resize(1);
        m_info[0].resize(maxLevel);
        break;
    case GL_TEXTURE_CUBE_MAP:
        m_target = target;
        m_info.resize(6);
        for (int ii = 0; ii < 6; ++ii)
            m_info[ii].resize(maxLevel);
        break;
    }
}

void WebGLTexture::setParameteri(GLenum pname, GLint param)
{
    if (!object() || !m_target)
        return;
    switch (pname) {
    case GL_TEXTURE_MIN_FILTER:
        switch (param) {
        case GL_NEAREST:
        case GL_LINEAR:
        case GL_NEAREST_MIPMAP_NEAREST:
        case GL_LINEAR_MIPMAP_NEAREST:
        case GL_NEAREST_MIPMAP_LINEAR:
        case GL_LINEAR_MIPMAP_LINEAR:
            m_minFilter = param;
            break;
        }
        break;
    case GL_TEXTURE_MAG_FILTER:
        switch (param) {
        case GL_NEAREST:
        case GL_LINEAR:
            m_magFilter = param;
            break;
        }
        break;
    case GL_TEXTURE_WRAP_S:
        switch (param) {
        case GL_CLAMP_TO_EDGE:
        case GL_MIRRORED_REPEAT:
        case GL_REPEAT:
            m_wrapS = param;
            break;
        }
        break;
    case GL_TEXTURE_WRAP_T:
        switch (param) {
        case GL_CLAMP_TO_EDGE:
        case GL_MIRRORED_REPEAT:
        case GL_REPEAT:
            m_wrapT = param;
            break;
        }
        break;
    default:
        return;
    }
    update();
}

void WebGLTexture::setParameterf(GLenum pname, GLfloat param)
{
    if (!object() || !m_target)
        return;
    GLint iparam = static_cast<GLint>(param);
    setParameteri(pname, iparam);
}

void WebGLTexture::setLevelInfo(GLenum target, GLint level, GLenum internalFormat, GLsizei width, GLsizei height, GLenum type)
{
    if (!object() || !m_target)
        return;
    // We assume level, internalFormat, width, height, and type have all been
    // validated already.
    int index = mapTargetToIndex(target);
    if (index < 0)
        return;
    m_info[index][level].setInfo(internalFormat, width, height, type);
    update();
}

void WebGLTexture::generateMipmapLevelInfo()
{
    if (!object() || !m_target)
        return;
    if (!canGenerateMipmaps())
        return;
    if (!m_isComplete) {
        for (size_t ii = 0; ii < m_info.size(); ++ii) {
            const LevelInfo& info0 = m_info[ii][0];
            GLsizei width = info0.width;
            GLsizei height = info0.height;
            GLint levelCount = computeLevelCount(width, height);
            for (GLint level = 1; level < levelCount; ++level) {
                width = std::max(1, width >> 1);
                height = std::max(1, height >> 1);
                LevelInfo& info = m_info[ii][level];
                info.setInfo(info0.internalFormat, width, height, info0.type);
            }
        }
        m_isComplete = true;
    }
    m_needToUseBlackTexture = false;
}

GLenum WebGLTexture::getInternalFormat(GLenum target, GLint level) const
{
    const LevelInfo* info = getLevelInfo(target, level);
    if (!info)
        return 0;
    return info->internalFormat;
}

GLenum WebGLTexture::getType(GLenum target, GLint level) const
{
    const LevelInfo* info = getLevelInfo(target, level);
    if (!info)
        return 0;
    return info->type;
}

GLsizei WebGLTexture::getWidth(GLenum target, GLint level) const
{
    const LevelInfo* info = getLevelInfo(target, level);
    if (!info)
        return 0;
    return info->width;
}

GLsizei WebGLTexture::getHeight(GLenum target, GLint level) const
{
    const LevelInfo* info = getLevelInfo(target, level);
    if (!info)
        return 0;
    return info->height;
}

bool WebGLTexture::isValid(GLenum target, GLint level) const
{
    const LevelInfo* info = getLevelInfo(target, level);
    if (!info)
        return 0;
    return info->valid;
}

bool WebGLTexture::isNPOT(GLsizei width, GLsizei height)
{
    ASSERT(width >= 0 && height >= 0);
    if (!width || !height)
        return false;
    if ((width & (width - 1)) || (height & (height - 1)))
        return true;
    return false;
}

bool WebGLTexture::isNPOT() const
{
    if (!object())
        return false;
    return m_isNPOT;
}

bool WebGLTexture::needToUseBlackTexture(TextureExtensionFlag flag) const
{
    if (!object())
        return false;
    if (m_needToUseBlackTexture)
        return true;
    if ((m_isFloatType && !(flag & TextureFloatLinearExtensionEnabled)) || (m_isHalfFloatType && !(flag && TextureHalfFloatLinearExtensionEnabled))) {
        if (m_magFilter != GL_NEAREST || (m_minFilter != GL_NEAREST && m_minFilter != GL_NEAREST_MIPMAP_NEAREST))
            return true;
    }
    return false;
}

void WebGLTexture::deleteObjectImpl(blink::WebGraphicsContext3D* context3d, Platform3DObject object)
{
    context3d->deleteTexture(object);
}

int WebGLTexture::mapTargetToIndex(GLenum target) const
{
    if (m_target == GL_TEXTURE_2D) {
        if (target == GL_TEXTURE_2D)
            return 0;
    } else if (m_target == GL_TEXTURE_CUBE_MAP) {
        switch (target) {
        case GL_TEXTURE_CUBE_MAP_POSITIVE_X:
            return 0;
        case GL_TEXTURE_CUBE_MAP_NEGATIVE_X:
            return 1;
        case GL_TEXTURE_CUBE_MAP_POSITIVE_Y:
            return 2;
        case GL_TEXTURE_CUBE_MAP_NEGATIVE_Y:
            return 3;
        case GL_TEXTURE_CUBE_MAP_POSITIVE_Z:
            return 4;
        case GL_TEXTURE_CUBE_MAP_NEGATIVE_Z:
            return 5;
        }
    }
    return -1;
}

bool WebGLTexture::canGenerateMipmaps()
{
    if (isNPOT())
        return false;
    const LevelInfo& first = m_info[0][0];
    for (size_t ii = 0; ii < m_info.size(); ++ii) {
        const LevelInfo& info = m_info[ii][0];
        if (!info.valid
            || info.width != first.width || info.height != first.height
            || info.internalFormat != first.internalFormat || info.type != first.type
            || (m_info.size() > 1 && !m_isCubeComplete))
            return false;
    }
    return true;
}

GLint WebGLTexture::computeLevelCount(GLsizei width, GLsizei height)
{
    // return 1 + log2Floor(std::max(width, height));
    GLsizei n = std::max(width, height);
    if (n <= 0)
        return 0;
    GLint log = 0;
    GLsizei value = n;
    for (int ii = 4; ii >= 0; --ii) {
        int shift = (1 << ii);
        GLsizei x = (value >> shift);
        if (x) {
            value = x;
            log += shift;
        }
    }
    ASSERT(value == 1);
    return log + 1;
}

void WebGLTexture::update()
{
    m_isNPOT = false;
    for (size_t ii = 0; ii < m_info.size(); ++ii) {
        if (isNPOT(m_info[ii][0].width, m_info[ii][0].height)) {
            m_isNPOT = true;
            break;
        }
    }
    m_isComplete = true;
    m_isCubeComplete = true;
    const LevelInfo& first = m_info[0][0];
    GLint levelCount = computeLevelCount(first.width, first.height);
    if (levelCount < 1)
        m_isComplete = false;
    else {
        for (size_t ii = 0; ii < m_info.size() && m_isComplete; ++ii) {
            const LevelInfo& info0 = m_info[ii][0];
            if (!info0.valid
                || info0.width != first.width || info0.height != first.height
                || info0.internalFormat != first.internalFormat || info0.type != first.type
                || (m_info.size() > 1 && info0.width != info0.height)) {
                if (m_info.size() > 1)
                    m_isCubeComplete = false;
                m_isComplete = false;
                break;
            }
            GLsizei width = info0.width;
            GLsizei height = info0.height;
            for (GLint level = 1; level < levelCount; ++level) {
                width = std::max(1, width >> 1);
                height = std::max(1, height >> 1);
                const LevelInfo& info = m_info[ii][level];
                if (!info.valid
                    || info.width != width || info.height != height
                    || info.internalFormat != info0.internalFormat || info.type != info0.type) {
                    m_isComplete = false;
                    break;
                }

            }
        }
    }
    m_isFloatType = m_info[0][0].type == GL_FLOAT;
    m_isHalfFloatType = m_info[0][0].type == GL_HALF_FLOAT_OES;

    m_needToUseBlackTexture = false;
    // NPOT
    if (m_isNPOT && ((m_minFilter != GL_NEAREST && m_minFilter != GL_LINEAR)
        || m_wrapS != GL_CLAMP_TO_EDGE || m_wrapT != GL_CLAMP_TO_EDGE))
        m_needToUseBlackTexture = true;
    // If it is a Cube texture, check Cube Completeness first
    if (m_info.size() > 1 && !m_isCubeComplete)
        m_needToUseBlackTexture = true;
    // Completeness
    if (!m_isComplete && m_minFilter != GL_NEAREST && m_minFilter != GL_LINEAR)
        m_needToUseBlackTexture = true;
}

const WebGLTexture::LevelInfo* WebGLTexture::getLevelInfo(GLenum target, GLint level) const
{
    if (!object() || !m_target)
        return 0;
    int targetIndex = mapTargetToIndex(target);
    if (targetIndex < 0 || targetIndex >= static_cast<int>(m_info.size()))
        return 0;
    if (level < 0 || level >= static_cast<GLint>(m_info[targetIndex].size()))
        return 0;
    return &(m_info[targetIndex][level]);
}

}
