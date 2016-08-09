// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_OPEN_GL_H_
#define FLUTTER_FLOW_OPEN_GL_H_

#include "lib/ftl/build_config.h"

#if OS_IOS

#include <OpenGLES/ES2/gl.h>

#elif OS_MACOSX

#include <OpenGL/gl.h>

#elif OS_ANDROID

#include <GLES2/gl2.h>

#elif OS_LINUX

#include <GL/gl.h>

#else

#error OpenGL headers not found for this platform.

#endif

#endif  // FLUTTER_FLOW_OPEN_GL_H_
