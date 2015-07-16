// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_switches.h"
#include "base/basictypes.h"

namespace gfx {

const char kGLImplementationDesktopName[]     = "desktop";
const char kGLImplementationOSMesaName[]      = "osmesa";
const char kGLImplementationAppleName[]       = "apple";
const char kGLImplementationEGLName[]         = "egl";
const char kGLImplementationSwiftShaderName[] = "swiftshader";
const char kGLImplementationMockName[]        = "mock";

}  // namespace gfx

namespace switches {

// Disables use of D3D11.
const char kDisableD3D11[]                  = "disable-d3d11";

// Stop the GPU from synchronizing on the vsync before presenting.
const char kDisableGpuVsync[]               = "disable-gpu-vsync";

// Turns on GPU logging (debug build only).
const char kEnableGPUServiceLogging[]       = "enable-gpu-service-logging";

// Turns on calling TRACE for every GL call.
const char kEnableGPUServiceTracing[]       = "enable-gpu-service-tracing";

// Select which implementation of GL the GPU process should use. Options are:
//  desktop: whatever desktop OpenGL the user has installed (Linux and Mac
//           default).
//  egl: whatever EGL / GLES2 the user has installed (Windows default - actually
//       ANGLE).
//  osmesa: The OSMesa software renderer.
const char kUseGL[]                         = "use-gl";

const char kSwiftShaderPath[]               = "swiftshader-path";

// Inform Chrome that a GPU context will not be lost in power saving mode,
// screen saving mode, etc.  Note that this flag does not ensure that a GPU
// context will never be lost in any situations, say, a GPU reset.
const char kGpuNoContextLost[]              = "gpu-no-context-lost";

// Indicates whether the dual GPU switching is supported or not.
const char kSupportsDualGpus[]              = "supports-dual-gpus";

// Flag used for Linux tests: for desktop GL bindings, try to load this GL
// library first, but fall back to regular library if loading fails.
const char kTestGLLib[]                     = "test-gl-lib";

// Use hardware gpu, if available, for tests.
const char kUseGpuInTests[] = "use-gpu-in-tests";

// On Windows only: use the WARP software rasterizer in the GPU process.
const char kUseWarp[] = "use-warp";

// Enable OpenGL ES 3 APIs without proper service side validation.
const char kEnableUnsafeES3APIs[] = "enable-unsafe-es3-apis";

// Disables GL drawing operations which produce pixel output. With this
// the GL output will not be correct but tests will run faster.
const char kDisableGLDrawingForTests[] = "disable-gl-drawing-for-tests";

// Forces the use of OSMesa instead of hardware gpu.
const char kOverrideUseGLWithOSMesaForTests[] =
    "override-use-gl-with-osmesa-for-tests";

// This is the list of switches passed from this file that are passed from the
// GpuProcessHost to the GPU Process. Add your switch to this list if you need
// to read it in the GPU process, else don't add it.
const char* kGLSwitchesCopiedFromGpuProcessHost[] = {
  kDisableGpuVsync,
  kDisableD3D11,
  kEnableGPUServiceLogging,
  kEnableGPUServiceTracing,
  kEnableUnsafeES3APIs,
  kGpuNoContextLost,
  kDisableGLDrawingForTests,
  kOverrideUseGLWithOSMesaForTests,
  kUseWarp,
};
const int kGLSwitchesCopiedFromGpuProcessHostNumSwitches =
    arraysize(kGLSwitchesCopiedFromGpuProcessHost);

}  // namespace switches

