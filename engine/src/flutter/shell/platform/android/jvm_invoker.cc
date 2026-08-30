// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/jvm_invoker.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {
namespace android {

DefaultJvmInvoker::DefaultJvmInvoker() : attached_(true) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::DefaultJvmInvoker");
}

DefaultJvmInvoker::~DefaultJvmInvoker() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::~DefaultJvmInvoker");
}

bool DefaultJvmInvoker::EnsureAttachedToThread() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::EnsureAttachedToThread");
  attached_ = true;
  return true;
}

void DefaultJvmInvoker::DetachFromThread() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::DetachFromThread");
  attached_ = false;
}

bool DefaultJvmInvoker::HasPendingException() const {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::HasPendingException");
  return pending_exception_;
}

void DefaultJvmInvoker::ClearPendingException() {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::ClearPendingException");
  pending_exception_ = false;
}

bool DefaultJvmInvoker::InvokeVoidMethod(const std::string& method_name,
                                         const std::string& signature,
                                         const std::vector<uint8_t>& payload) {
  TRACE_EVENT1("flutter", "DefaultJvmInvoker::InvokeVoidMethod", "method",
               method_name.c_str());
  if (pending_exception_) {
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
  if (pending_exception_) {
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
  if (pending_exception_) {
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
  if (pending_exception_) {
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
  if (pending_exception_) {
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
  if (pending_exception_) {
    return {};
  }
  return {};
}

bool DefaultJvmInvoker::PostJvmTask(std::function<void()> task) {
  TRACE_EVENT0("flutter", "DefaultJvmInvoker::PostJvmTask");
  if (task) {
    task();
    return true;
  }
  return false;
}

}  // namespace android
}  // namespace flutter
