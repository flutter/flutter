// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/at_exit.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/message_loop/message_loop.h"
#if defined(OS_MACOSX)
#include "base/mac/scoped_nsautorelease_pool.h"
#endif
#include "base/test/launcher/unit_test_launcher.h"
#include "base/test/test_suite.h"
#include "gpu/command_buffer/client/gles2_lib.h"
#include "gpu/config/gpu_util.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "ui/gl/gl_surface.h"

#if defined(OS_ANDROID)
#include "base/android/jni_android.h"
#include "ui/gl/android/gl_jni_registrar.h"
#endif

namespace {

int RunHelper(base::TestSuite* testSuite) {
  base::MessageLoopForIO message_loop;
  return testSuite->Run();
}

}  // namespace

int main(int argc, char** argv) {
#if defined(OS_ANDROID)
  ui::gl::android::RegisterJni(base::android::AttachCurrentThread());
#endif
  base::TestSuite test_suite(argc, argv);
  base::CommandLine::Init(argc, argv);
#if defined(OS_MACOSX)
  base::mac::ScopedNSAutoreleasePool pool;
#endif
  gfx::GLSurface::InitializeOneOff();
  ::gles2::Initialize();
  gpu::ApplyGpuDriverBugWorkarounds(base::CommandLine::ForCurrentProcess());
  testing::InitGoogleMock(&argc, argv);
  return base::LaunchUnitTestsSerially(
      argc,
      argv,
      base::Bind(&RunHelper, base::Unretained(&test_suite)));
}
