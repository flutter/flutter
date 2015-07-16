// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/js/handle.h"

#include "mojo/edk/js/handle_close_observer.h"

namespace mojo {
namespace js {

gin::WrapperInfo HandleWrapper::kWrapperInfo = { gin::kEmbedderNativeGin };

HandleWrapper::HandleWrapper(MojoHandle handle)
    : handle_(mojo::Handle(handle)) {
}

HandleWrapper::~HandleWrapper() {
  NotifyCloseObservers();
}

void HandleWrapper::Close() {
  NotifyCloseObservers();
  handle_.reset();
}

void HandleWrapper::AddCloseObserver(HandleCloseObserver* observer) {
  close_observers_.AddObserver(observer);
}

void HandleWrapper::RemoveCloseObserver(HandleCloseObserver* observer) {
  close_observers_.RemoveObserver(observer);
}

void HandleWrapper::NotifyCloseObservers() {
  if (!handle_.is_valid())
    return;

  FOR_EACH_OBSERVER(HandleCloseObserver, close_observers_, OnWillCloseHandle());
}

}  // namespace js
}  // namespace mojo

namespace gin {

v8::Handle<v8::Value> Converter<mojo::Handle>::ToV8(v8::Isolate* isolate,
                                                    const mojo::Handle& val) {
  if (!val.is_valid())
    return v8::Null(isolate);
  return mojo::js::HandleWrapper::Create(isolate, val.value()).ToV8();
}

bool Converter<mojo::Handle>::FromV8(v8::Isolate* isolate,
                                     v8::Handle<v8::Value> val,
                                     mojo::Handle* out) {
  if (val->IsNull()) {
    *out = mojo::Handle();
    return true;
  }

  gin::Handle<mojo::js::HandleWrapper> handle;
  if (!Converter<gin::Handle<mojo::js::HandleWrapper> >::FromV8(
      isolate, val, &handle))
    return false;

  *out = handle->get();
  return true;
}

v8::Handle<v8::Value> Converter<mojo::MessagePipeHandle>::ToV8(
    v8::Isolate* isolate, mojo::MessagePipeHandle val) {
  return Converter<mojo::Handle>::ToV8(isolate, val);
}

bool Converter<mojo::MessagePipeHandle>::FromV8(v8::Isolate* isolate,
                                                v8::Handle<v8::Value> val,
                                                mojo::MessagePipeHandle* out) {
  return Converter<mojo::Handle>::FromV8(isolate, val, out);
}


}  // namespace gin
