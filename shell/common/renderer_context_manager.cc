// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "renderer_context_manager.h"

namespace flutter {

RendererContext::RendererContext() = default;

RendererContext::~RendererContext() = default;

RendererContextManager::RendererContextManager(
    std::unique_ptr<RendererContext> context,
    std::unique_ptr<RendererContext> resource_context)
    : context_(std::move(context)),
      resource_context_(std::move(resource_context)){};

RendererContextManager::~RendererContextManager() = default;

RendererContextManager::RendererContextSwitch
RendererContextManager::MakeCurrent(std::unique_ptr<RendererContext> context) {
  return RendererContextManager::RendererContextSwitch(*this,
                                                       std::move(context));
};

RendererContextManager::RendererContextSwitch
RendererContextManager::FlutterMakeCurrent() {
  return MakeCurrent(std::move(context_));
};

RendererContextManager::RendererContextSwitch
RendererContextManager::FlutterResourceMakeCurrent() {
  return MakeCurrent(std::move(resource_context_));
};

bool RendererContextManager::PushContext(
    std::unique_ptr<RendererContext> context) {
  if (current_ == nullptr) {
    current_ = std::move(context);
    return current_->SetCurrent();
  }
  stored_.push_back(std::move(current_));
  bool result = context->SetCurrent();
  current_ = std::move(context);
  return result;
};

void RendererContextManager::PopContext() {
  if (stored_.empty()) {
    current_->RemoveCurrent();
    return;
  }
  current_ = std::move(stored_.back());
  current_->SetCurrent();
  stored_.pop_back();
};

RendererContextManager::RendererContextSwitch::RendererContextSwitch(
    RendererContextManager& manager,
    std::unique_ptr<RendererContext> context)
    : manager_(manager) {
  bool result = manager_.PushContext(std::move(context));
  result_ = result;
};

RendererContextManager::RendererContextSwitch::~RendererContextSwitch() {
  manager_.PopContext();
};

bool RendererContextManager::RendererContextSwitch::GetResult() {
  return result_;
};
}  // namespace flutter
