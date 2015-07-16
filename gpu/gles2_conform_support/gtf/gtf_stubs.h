// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A few stubs so we don't need the actual OpenGL ES 2.0 conformance tests
// to compile the support for them.

#ifndef GPU_GLES2_CONFORM_SUPPORT_GTF_GTF_STUBS_H_
#define GPU_GLES2_CONFORM_SUPPORT_GTF_GTF_STUBS_H_

#include <GLES2/gl2.h>
#include <EGL/egl.h>
#include <EGL/eglext.h>

typedef unsigned char GTFbool;
#define GTFfalse 0
#define GTFtrue  1

int GTFMain(int argc, char** argv);

#endif  // GPU_GLES2_CONFORM_SUPPORT_GTF_GTF_STUBS_H_


