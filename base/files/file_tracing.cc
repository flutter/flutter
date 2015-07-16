// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/file_tracing.h"

#include "base/files/file.h"

namespace base {

namespace {
FileTracing::Provider* g_provider = nullptr;
}

// static
void FileTracing::SetProvider(FileTracing::Provider* provider) {
  g_provider = provider;
}

FileTracing::ScopedEnabler::ScopedEnabler() {
  if (g_provider)
    g_provider->FileTracingEnable(this);
}

FileTracing::ScopedEnabler::~ScopedEnabler() {
  if (g_provider)
    g_provider->FileTracingDisable(this);
}

FileTracing::ScopedTrace::ScopedTrace() : id_(nullptr) {}

FileTracing::ScopedTrace::~ScopedTrace() {
  if (id_ && g_provider)
    g_provider->FileTracingEventEnd(name_, id_);
}

bool FileTracing::ScopedTrace::ShouldInitialize() const {
  return g_provider && g_provider->FileTracingCategoryIsEnabled();
}

void FileTracing::ScopedTrace::Initialize(
    const char* name, File* file, int64 size) {
  if (!g_provider)
    return;

  id_ = &file->trace_enabler_;
  name_ = name;

  g_provider->FileTracingEventBegin(name_, id_, file->path_, size);
}

}  // namespace base
