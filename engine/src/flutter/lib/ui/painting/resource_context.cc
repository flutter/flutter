// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/resource_context.h"

#include <mutex>

#include "lib/fxl/logging.h"

namespace blink {
namespace {

static GrContext* g_context = nullptr;
static std::mutex g_mutex;
static volatile bool g_freeze = false;

}  // namespace

ResourceContext::ResourceContext() {
  g_mutex.lock();
}

ResourceContext::~ResourceContext() {
  g_mutex.unlock();
}

void ResourceContext::Set(sk_sp<GrContext> context) {
  FXL_DCHECK(!g_context);
  g_context = context.release();
}

GrContext* ResourceContext::Get() {
  return g_freeze ? nullptr : g_context;
}

std::unique_ptr<ResourceContext> ResourceContext::Acquire() {
  return std::make_unique<ResourceContext>();
}

void ResourceContext::Freeze() {
  std::lock_guard<std::mutex> lock(g_mutex);
  g_freeze = true;
}

void ResourceContext::Unfreeze() {
  std::lock_guard<std::mutex> lock(g_mutex);
  g_freeze = false;
}

}  // namespace blink
