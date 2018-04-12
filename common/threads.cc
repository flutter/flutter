// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/common/threads.h"

#include <utility>

namespace blink {
namespace {

Threads* g_threads = nullptr;

}  // namespace

Threads::Threads() {}

Threads::Threads(fxl::RefPtr<fxl::TaskRunner> platform,
                 fxl::RefPtr<fxl::TaskRunner> gpu,
                 fxl::RefPtr<fxl::TaskRunner> ui,
                 fxl::RefPtr<fxl::TaskRunner> io)
    : platform_(std::move(platform)),
      gpu_(std::move(gpu)),
      ui_(std::move(ui)),
      io_(std::move(io)) {}

Threads::~Threads() {}

const fxl::RefPtr<fxl::TaskRunner>& Threads::Platform() {
  return Get().platform_;
}

const fxl::RefPtr<fxl::TaskRunner>& Threads::Gpu() {
  return Get().gpu_;
}

const fxl::RefPtr<fxl::TaskRunner>& Threads::UI() {
  return Get().ui_;
}

const fxl::RefPtr<fxl::TaskRunner>& Threads::IO() {
  return Get().io_;
}

const Threads& Threads::Get() {
  FXL_CHECK(g_threads);
  return *g_threads;
}

void Threads::Set(const Threads& threads) {
  FXL_CHECK(!g_threads);
  g_threads = new Threads();
  *g_threads = threads;
}

}  // namespace blink
