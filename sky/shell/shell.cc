// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/shell.h"

#include <memory>

#include "base/bind.h"
#include "base/command_line.h"
#include "base/i18n/icu_util.h"
#include "base/lazy_instance.h"
#include "base/memory/discardable_memory.h"
#include "base/memory/discardable_memory_allocator.h"
#include "base/single_thread_task_runner.h"
#include "base/trace_event/trace_event.h"
#include "mojo/message_pump/message_pump_mojo.h"
#include "sky/engine/public/platform/sky_settings.h"
#include "sky/shell/switches.h"
#include "sky/shell/ui/engine.h"

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

Shell::Shell() {
  DCHECK(!g_shell);

  base::Thread::Options options;
  options.message_pump_factory = base::Bind(&CreateMessagePumpMojo);

  gpu_thread_.reset(new base::Thread("gpu_thread"));
  gpu_thread_->StartWithOptions(options);
  gpu_task_runner_ = gpu_thread_->message_loop()->task_runner();

  ui_thread_.reset(new base::Thread("ui_thread"));
  ui_thread_->StartWithOptions(options);
  ui_task_runner_ = ui_thread_->message_loop()->task_runner();

  io_thread_.reset(new base::Thread("io_thread"));
  io_thread_->StartWithOptions(options);
  io_task_runner_ = io_thread_->message_loop()->task_runner();
}

Shell::~Shell() {
}

void Shell::InitStandalone() {
  TRACE_EVENT0("flutter", "Shell::InitStandalone");
  CHECK(base::i18n::InitializeICU());

  base::CommandLine& command_line = *base::CommandLine::ForCurrentProcess();

  blink::SkySettings settings;
  settings.enable_observatory =
      !command_line.HasSwitch(switches::kNonInteractive);
  settings.enable_dart_checked_mode =
      command_line.HasSwitch(switches::kEnableCheckedMode);
  blink::SkySettings::Set(settings);

  Init();

  if (command_line.HasSwitch(switches::kTraceStartup))
    Shared().tracing_controller().StartTracing();
}

void Shell::Init() {
  base::DiscardableMemoryAllocator::SetInstance(&g_discardable.Get());
  DCHECK(!g_shell);
  g_shell = new Shell();
  g_shell->ui_task_runner()->PostTask(FROM_HERE, base::Bind(&Engine::Init));
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
