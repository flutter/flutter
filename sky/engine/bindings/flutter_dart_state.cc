// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/bindings/flutter_dart_state.h"

#include "sky/engine/bindings/mojo_services.h"
#include "sky/engine/tonic/dart_converter.h"

#ifdef OS_ANDROID
#include "sky/engine/bindings/jni/dart_jni.h"
#endif

namespace blink {

IsolateClient::~IsolateClient() {
}

FlutterDartState::FlutterDartState(IsolateClient* isolate_client,
                                   const std::string& url)
    : isolate_client_(isolate_client), url_(url) {
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
  x_handle_.Set(this, ToDart("x"));
  y_handle_.Set(this, ToDart("y"));
  dx_handle_.Set(this, ToDart("_dx"));
  dy_handle_.Set(this, ToDart("_dy"));
  value_handle_.Set(this, ToDart("_value"));

  Dart_Handle library = Dart_LookupLibrary(ToDart("dart:ui"));
  color_class_.Set(this, Dart_GetType(library, ToDart("Color"), 0, 0));
}

void FlutterDartState::set_mojo_services(
    std::unique_ptr<MojoServices> mojo_services) {
  mojo_services_ = std::move(mojo_services);
}

MojoServices* FlutterDartState::mojo_services() {
  return mojo_services_.get();
}

#ifdef OS_ANDROID
void FlutterDartState::set_jni_data(
    std::unique_ptr<DartJniIsolateData> jni_data) {
  jni_data_ = std::move(jni_data);
}

DartJniIsolateData* FlutterDartState::jni_data() {
  return jni_data_.get();
}
#endif

}  // namespace blink
