// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "services/sky/runtime_flags.h"

#include "base/logging.h"
#include "mojo/public/cpp/application/application_impl.h"

namespace sky {
namespace {

bool initialized = false;
RuntimeFlags flags;

// Load the viewer in testing mode so we can dump pixels.
const char kTesting[] = "--testing";

}  // namespace

void RuntimeFlags::Initialize(mojo::ApplicationImpl* app) {
  DCHECK(!initialized);
  flags.testing_ = app->HasArg(kTesting);
  initialized = true;
}

const RuntimeFlags& RuntimeFlags::Get() {
  DCHECK(initialized);
  return flags;
}

}  // namespace sky
