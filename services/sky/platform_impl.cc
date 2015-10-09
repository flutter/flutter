// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "services/sky/platform_impl.h"

#include "base/bind.h"
#include "mojo/message_pump/message_pump_mojo.h"

namespace sky {
namespace {

scoped_ptr<base::MessagePump> CreateMessagePumpMojo() {
  return make_scoped_ptr(new mojo::common::MessagePumpMojo);
}

} // namespace

PlatformImpl::PlatformImpl()
    : ui_task_runner_(base::MessageLoop::current()->task_runner()) {
  base::Thread::Options options;
  options.message_pump_factory = base::Bind(&CreateMessagePumpMojo);

  io_thread_.reset(new base::Thread("io_thread"));
  io_thread_->StartWithOptions(options);
  io_task_runner_ = io_thread_->message_loop()->task_runner();
}

PlatformImpl::~PlatformImpl() {
}

blink::WebString PlatformImpl::defaultLocale() {
  return blink::WebString::fromUTF8("en-US");
}

base::SingleThreadTaskRunner* PlatformImpl::GetUITaskRunner() {
  return ui_task_runner_.get();
}

base::SingleThreadTaskRunner* PlatformImpl::GetIOTaskRunner() {
  return io_task_runner_.get();
}

}  // namespace sky
