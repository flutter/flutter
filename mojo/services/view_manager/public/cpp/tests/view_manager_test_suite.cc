// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/services/view_manager/public/cpp/tests/view_manager_test_suite.h"

#include "base/i18n/icu_util.h"

#if defined(USE_X11)
#include "ui/gfx/x/x11_connection.h"
#endif

namespace mojo {

ViewManagerTestSuite::ViewManagerTestSuite(int argc, char** argv)
    : TestSuite(argc, argv) {}

ViewManagerTestSuite::~ViewManagerTestSuite() {
}

void ViewManagerTestSuite::Initialize() {
#if defined(USE_X11)
  // Each test ends up creating a new thread for the native viewport service.
  // In other words we'll use X on different threads, so tell it that.
  gfx::InitializeThreadedX11();
#endif

  base::TestSuite::Initialize();

  // base::TestSuite and ViewsInit both try to load icu. That's ok for tests.
  base::i18n::AllowMultipleInitializeCallsForTesting();
}

}  // namespace mojo
