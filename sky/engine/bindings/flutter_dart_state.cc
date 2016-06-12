// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/bindings/flutter_dart_state.h"

#include "flutter/tonic/dart_converter.h"
#include "sky/engine/bindings/mojo_services.h"

#ifdef OS_ANDROID
#include "flutter/lib/jni/dart_jni.h"
#endif

namespace blink {

IsolateClient::~IsolateClient() {
}

FlutterDartState::FlutterDartState(IsolateClient* isolate_client,
                                   const std::string& url)
    : isolate_client_(isolate_client), url_(url) {
#ifdef OS_ANDROID
  jni_data_.reset(new DartJniIsolateData());
#endif
}

FlutterDartState::~FlutterDartState() {
  // We've already destroyed the isolate. Revoke any weak ptrs held by
  // DartPersistentValues so they don't try to enter the destroyed isolate to
  // clean themselves up.
  weak_factory_.InvalidateWeakPtrs();
}

FlutterDartState* FlutterDartState::CreateForChildIsolate() {
  return new FlutterDartState(isolate_client_, url_);
}

FlutterDartState* FlutterDartState::Current() {
  return static_cast<FlutterDartState*>(DartState::Current());
}

void FlutterDartState::DidSetIsolate() {
  Scope dart_scope(this);
  value_handle_.Set(this, ToDart("_value"));
}

void FlutterDartState::set_mojo_services(
    std::unique_ptr<MojoServices> mojo_services) {
  mojo_services_ = std::move(mojo_services);
}

MojoServices* FlutterDartState::mojo_services() {
  return mojo_services_.get();
}

#ifdef OS_ANDROID
DartJniIsolateData* FlutterDartState::jni_data() {
  return jni_data_.get();
}
#endif

}  // namespace blink
