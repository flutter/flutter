// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/flutter_embedder_native.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {
namespace android {

FlutterEmbedderNative::FlutterEmbedderNative()
    : jvm_invoker_(std::make_shared<DefaultJvmInvoker>()),
      jni_delegate_(std::make_shared<JniDelegate>(jvm_invoker_)),
      jni_router_(std::make_shared<JniRouter>(jni_delegate_, nullptr)) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::FlutterEmbedderNative");
  FML_DLOG(INFO) << "Initialized FlutterEmbedderNative with default invoker.";
}

FlutterEmbedderNative::FlutterEmbedderNative(
    std::shared_ptr<JvmInvoker> jvm_invoker,
    std::shared_ptr<LegacyJniDelegate> legacy_delegate)
    : jvm_invoker_(std::move(jvm_invoker)),
      jni_delegate_(std::make_shared<JniDelegate>(jvm_invoker_)),
      jni_router_(std::make_shared<JniRouter>(jni_delegate_,
                                              std::move(legacy_delegate))) {
  TRACE_EVENT0("flutter",
               "FlutterEmbedderNative::FlutterEmbedderNative(custom)");
  FML_DLOG(INFO) << "Initialized FlutterEmbedderNative with custom invoker.";
}

FlutterEmbedderNative::~FlutterEmbedderNative() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::~FlutterEmbedderNative");
}

bool FlutterEmbedderNative::IsQuarantineEnforced() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::IsQuarantineEnforced");
  // The quarantine enforces zero internal UI / Skia header inclusions.
  return true;
}

bool FlutterEmbedderNative::VerifyEmbedderVersion() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::VerifyEmbedderVersion");
  return FLUTTER_ENGINE_VERSION >= 1;
}

size_t FlutterEmbedderNative::GetEmbedderVersion() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::GetEmbedderVersion");
  return FLUTTER_ENGINE_VERSION;
}

bool FlutterEmbedderNative::IsEmbedderEnabled() {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::IsEmbedderEnabled");
  return JniRouter::IsEmbedderEnabled();
}

void FlutterEmbedderNative::SetEmbedderEnabled(bool enabled) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::SetEmbedderEnabled");
  JniRouter::SetEmbedderEnabled(enabled);
}

std::shared_ptr<JniRouter> FlutterEmbedderNative::CreateDefaultRouter(
    std::shared_ptr<JvmInvoker> invoker,
    std::shared_ptr<LegacyJniDelegate> legacy_delegate) {
  TRACE_EVENT0("flutter", "FlutterEmbedderNative::CreateDefaultRouter");
  auto delegate = std::make_shared<JniDelegate>(std::move(invoker));
  return std::make_shared<JniRouter>(std::move(delegate),
                                     std::move(legacy_delegate));
}

std::shared_ptr<JniRouter> FlutterEmbedderNative::GetRouter() const {
  return jni_router_;
}

std::shared_ptr<JniDelegate> FlutterEmbedderNative::GetJniDelegate() const {
  return jni_delegate_;
}

std::shared_ptr<JvmInvoker> FlutterEmbedderNative::GetJvmInvoker() const {
  return jvm_invoker_;
}

}  // namespace android
}  // namespace flutter
