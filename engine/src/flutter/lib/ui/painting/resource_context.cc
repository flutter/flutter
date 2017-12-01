// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/resource_context.h"

#include "lib/fxl/logging.h"
#include "lib/fxl/synchronization/mutex.h"

namespace blink {
namespace {

static GrContext* g_context = nullptr;
static fxl::Mutex g_mutex;
static volatile bool g_freeze = false;

}  // namespace

ResourceContext::ResourceContext() {
  g_mutex.Lock();
}

ResourceContext::~ResourceContext() {
  g_mutex.Unlock();
}

void ResourceContext::Set(GrContext* context) {
  FXL_DCHECK(!g_context);
  g_context = context;
}

GrContext* ResourceContext::Get() {
  return g_freeze ? nullptr : g_context;
}

std::unique_ptr<ResourceContext> ResourceContext::Acquire() {
  return std::make_unique<ResourceContext>();
}

void ResourceContext::Freeze() {
  fxl::MutexLocker lock(&g_mutex);
  g_freeze = true;
}

void ResourceContext::Unfreeze() {
  fxl::MutexLocker lock(&g_mutex);
  g_freeze = false;
}

}  // namespace blink
