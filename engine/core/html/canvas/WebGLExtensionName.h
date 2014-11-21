// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_HTML_CANVAS_WEBGLEXTENSIONNAME_H_
#define SKY_ENGINE_CORE_HTML_CANVAS_WEBGLEXTENSIONNAME_H_

namespace blink {

// Extension names are needed to properly wrap instances in JavaScript objects.
enum WebGLExtensionName {
    ANGLEInstancedArraysName,
    EXTBlendMinMaxName,
    EXTFragDepthName,
    EXTShaderTextureLODName,
    EXTTextureFilterAnisotropicName,
    OESElementIndexUintName,
    OESStandardDerivativesName,
    OESTextureFloatLinearName,
    OESTextureFloatName,
    OESTextureHalfFloatLinearName,
    OESTextureHalfFloatName,
    OESVertexArrayObjectName,
    WebGLCompressedTextureATCName,
    WebGLCompressedTextureETC1Name,
    WebGLCompressedTexturePVRTCName,
    WebGLCompressedTextureS3TCName,
    WebGLDebugRendererInfoName,
    WebGLDebugShadersName,
    WebGLDepthTextureName,
    WebGLDrawBuffersName,
    WebGLLoseContextName,
    WebGLExtensionNameCount, // Must be the last entry
};

}

#endif  // SKY_ENGINE_CORE_HTML_CANVAS_WEBGLEXTENSIONNAME_H_
