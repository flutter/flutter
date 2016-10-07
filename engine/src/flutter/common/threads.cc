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

Threads::Threads(ftl::RefPtr<ftl::TaskRunner> platform,
                 ftl::RefPtr<ftl::TaskRunner> gpu,
                 ftl::RefPtr<ftl::TaskRunner> ui,
                 ftl::RefPtr<ftl::TaskRunner> io)
    : platform_(std::move(platform)),
      gpu_(std::move(gpu)),
      ui_(std::move(ui)),
      io_(std::move(io)) {}

Threads::~Threads() {}

const ftl::RefPtr<ftl::TaskRunner>& Threads::Gpu() {
  return Get().gpu_;
}

const ftl::RefPtr<ftl::TaskRunner>& Threads::UI() {
  return Get().ui_;
}

const ftl::RefPtr<ftl::TaskRunner>& Threads::IO() {
  return Get().io_;
}

const Threads& Threads::Get() {
  FTL_CHECK(g_threads);
  return *g_threads;
}

void Threads::Set(const Threads& threads) {
  FTL_CHECK(!g_threads);
  g_threads = new Threads();
  *g_threads = threads;
}

}  // namespace blink
