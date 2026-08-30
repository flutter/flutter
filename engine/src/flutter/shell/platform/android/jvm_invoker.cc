// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/jvm_invoker.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {
namespace android {

DefaultJvmInvoker::DefaultJvmInvoker(
    fml::RefPtr<fml::TaskRunner> platform_task_runner)
    : attached_(true), platform_task_runner_(std::move(platform_task_runner)) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::DefaultJvmInvoker");
}

DefaultJvmInvoker::~DefaultJvmInvoker() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::~DefaultJvmInvoker");
}

bool DefaultJvmInvoker::EnsureAttachedToThread() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::EnsureAttachedToThread");
  attached_.store(true);
  return true;
}

void DefaultJvmInvoker::DetachFromThread() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::DetachFromThread");
  attached_.store(false);
}

bool DefaultJvmInvoker::HasPendingException() const {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::HasPendingException");
  return pending_exception_.load();
}

void DefaultJvmInvoker::ClearPendingException() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::ClearPendingException");
  pending_exception_.store(false);
}

bool DefaultJvmInvoker::HandlePlatformMessage(const std::string& channel,
                                              const uint8_t* message,
                                              size_t message_size,
                                              int32_t response_id,
                                              int64_t message_data) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::HandlePlatformMessage", "channel",
               channel.c_str());
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::HandlePlatformMessageResponse(int32_t response_id,
                                                      const uint8_t* data,
                                                      size_t data_size) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::HandlePlatformMessageResponse");
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::UpdateSemantics(
    const std::vector<uint8_t>& buffer,
    const std::vector<std::string>& strings,
    const std::vector<std::vector<uint8_t>>& string_attribute_args) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::UpdateSemantics");
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::UpdateCustomAccessibilityActions(
    const std::vector<uint8_t>& actions_buffer,
    const std::vector<std::string>& action_strings) {
  TRACE_EVENT0("flutter",
               "DefaultJvmInvoker::UpdateCustomAccessibilityActions");
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::SetSemanticsTreeEnabled(bool enabled) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::SetSemanticsTreeEnabled");
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::SetApplicationLocale(const std::string& locale) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::SetApplicationLocale", "locale",
               locale.c_str());
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::OnFirstFrame() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::OnFirstFrame");
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::OnPreEngineRestart() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::OnPreEngineRestart");
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::RequestDartDeferredLibrary(int loading_unit_id) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::RequestDartDeferredLibrary");
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::DecodeImage(const uint8_t* data,
                                    size_t size,
                                    int64_t generator_handle) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::DecodeImage");
  if (pending_exception_.load() || !data || size == 0) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::PushPlatformViewMutators(
    int64_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    const std::vector<uint8_t>& payload) {
  return PushPlatformViewMutators(view_id, x, y, width, height, width, height,
                                  payload);
}

bool DefaultJvmInvoker::PushPlatformViewMutators(
    int64_t view_id,
    int32_t x,
    int32_t y,
    int32_t width,
    int32_t height,
    int32_t view_width,
    int32_t view_height,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::PushPlatformViewMutators");
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::InvokeVoidMethod(const std::string& method_name,
                                         const std::string& signature,
                                         const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::InvokeVoidMethod", "method",
               method_name.c_str());
  if (pending_exception_.load()) {
    FML_LOG(WARNING) << "Ignoring InvokeVoidMethod on " << method_name
                     << " due to pending JVM exception.";
    return false;
  }
  return true;
}

bool DefaultJvmInvoker::InvokeBooleanMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::InvokeBooleanMethod", "method",
               method_name.c_str());
  if (pending_exception_.load()) {
    return false;
  }
  return true;
}

int64_t DefaultJvmInvoker::InvokeIntMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::InvokeIntMethod", "method",
               method_name.c_str());
  if (pending_exception_.load()) {
    return -1;
  }
  return 0;
}

double DefaultJvmInvoker::InvokeDoubleMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::InvokeDoubleMethod", "method",
               method_name.c_str());
  if (pending_exception_.load()) {
    return 0.0;
  }
  return 0.0;
}

std::string DefaultJvmInvoker::InvokeStringMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::InvokeStringMethod", "method",
               method_name.c_str());
  if (pending_exception_.load()) {
    return "";
  }
  return "";
}

std::vector<uint8_t> DefaultJvmInvoker::InvokeBytesMethod(
    const std::string& method_name,
    const std::string& signature,
    const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::InvokeBytesMethod", "method",
               method_name.c_str());
  if (pending_exception_.load()) {
    return {};
  }
  return {};
}

bool DefaultJvmInvoker::PostJvmTask(std::function<void()> task) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::PostJvmTask");
  if (!task) {
    return false;
  }
  if (platform_task_runner_) {
    platform_task_runner_->PostTask(std::move(task));
    return true;
  }
  FML_LOG(WARNING) << "PostJvmTask failed: no platform task runner configured.";
  return false;
}

}  // namespace android
}  // namespace flutter
