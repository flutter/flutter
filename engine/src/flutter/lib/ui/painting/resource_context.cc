// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/resource_context.h"

#include "lib/fxl/logging.h"

namespace blink {
namespace {

static GrContext* g_context = nullptr;

}  // namespace

void ResourceContext::Set(GrContext* context) {
  FXL_DCHECK(!g_context);
  g_context = context;
}

GrContext* ResourceContext::Get() {
  return g_context;
}

}  // namespace blink
