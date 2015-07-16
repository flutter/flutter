// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "native_viewport/public/cpp/args.h"

namespace mojo {

// Instead of using the system GL implementation, use OSMesa.
const char kUseOSMesa[] = "--use-osmesa";
// Loads an app from the specified directory and launches it.
// Force gl to be initialized in test mode.
const char kUseTestConfig[] = "--use-test-config";
// Create native viewport in headless mode.
const char kUseHeadlessConfig[] = "--use-headless-config";

}  // namespace mojo
