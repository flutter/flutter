/*
 * Copyright 2014 Google Inc.
 *
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */


#include "gl/GrGLInterface.h"
#include "gl/GrGLAssembleInterface.h"
#include "gl/GrGLUtil.h"

#include "GLFW/glfw3.h"

static GrGLFuncPtr glfw_get(void* ctx, const char name[]) {
    SkASSERT(nullptr == ctx);
    SkASSERT(glfwGetCurrentContext());
    return glfwGetProcAddress(name);
}

const GrGLInterface* GrGLCreateNativeInterface() {
    if (nullptr == glfwGetCurrentContext()) {
        return nullptr;
    }

    return GrGLAssembleInterface(nullptr, glfw_get);
}
