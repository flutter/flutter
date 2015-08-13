// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/shell.h"

#include "base/bind.h"
#include "base/i18n/icu_util.h"
#include "base/lazy_instance.h"
#include "base/memory/discardable_memory.h"
#include "base/memory/discardable_memory_allocator.h"
#include "base/single_thread_task_runner.h"
#include "mojo/common/message_pump_mojo.h"
#include "mojo/edk/embedder/embedder.h"
#include "mojo/edk/embedder/simple_platform_support.h"
#include "sky/shell/ui/engine.h"
#include "ui/gl/gl_surface.h"

namespace sky {
namespace shell {
namespace {

static Shell* g_shell = nullptr;

scoped_ptr<base::MessagePump> CreateMessagePumpMojo() {
  return make_scoped_ptr(new mojo::common::MessagePumpMojo);
}

class NonDiscardableMemory : public base::DiscardableMemory {
 public:
  explicit NonDiscardableMemory(size_t size) : data_(new uint8_t[size]) {}
  bool Lock() override { return false; }
  void Unlock() override {}
  void* data() const override { return data_.get(); }

 private:
  scoped_ptr<uint8_t[]> data_;
};

class NonDiscardableMemoryAllocator : public base::DiscardableMemoryAllocator {
 public:
  scoped_ptr<base::DiscardableMemory> AllocateLockedDiscardableMemory(
      size_t size) override {
    return make_scoped_ptr(new NonDiscardableMemory(size));
  }
};

base::LazyInstance<NonDiscardableMemoryAllocator> g_discardable;

}  // namespace

Shell::Shell(scoped_ptr<ServiceProviderContext> service_provider_context)
    : service_provider_context_(service_provider_context.Pass()) {
  DCHECK(!g_shell);
  mojo::embedder::Init(scoped_ptr<mojo::embedder::PlatformSupport>(
      new mojo::embedder::SimplePlatformSupport()));

  base::Thread::Options options;
  options.message_pump_factory = base::Bind(&CreateMessagePumpMojo);

  gpu_thread_.reset(new base::Thread("gpu_thread"));
  gpu_thread_->StartWithOptions(options);

  ui_thread_.reset(new base::Thread("ui_thread"));
  ui_thread_->StartWithOptions(options);

  ui_task_runner()->PostTask(FROM_HERE, base::Bind(&Engine::Init));
}

Shell::~Shell() {
}

void Shell::Init(scoped_ptr<ServiceProviderContext> service_provider_context) {
  CHECK(base::i18n::InitializeICU());
#if !defined(OS_LINUX)
  CHECK(gfx::GLSurface::InitializeOneOff());
#endif
  base::DiscardableMemoryAllocator::SetInstance(&g_discardable.Get());

  g_shell = new Shell(service_provider_context.Pass());
}

Shell& Shell::Shared() {
  DCHECK(g_shell);
  return *g_shell;
}

TracingController& Shell::tracing_controller() {
  return tracing_controller_;
}

}  // namespace shell
}  // namespace sky
