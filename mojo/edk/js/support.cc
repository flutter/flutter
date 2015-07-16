// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/js/support.h"

#include "base/bind.h"
#include "gin/arguments.h"
#include "gin/converter.h"
#include "gin/function_template.h"
#include "gin/object_template_builder.h"
#include "gin/per_isolate_data.h"
#include "gin/public/wrapper_info.h"
#include "gin/wrappable.h"
#include "mojo/edk/js/handle.h"
#include "mojo/edk/js/waiting_callback.h"
#include "mojo/public/cpp/system/core.h"

namespace mojo {
namespace js {

namespace {

WaitingCallback* AsyncWait(const gin::Arguments& args,
                           gin::Handle<HandleWrapper> handle,
                           MojoHandleSignals signals,
                           v8::Handle<v8::Function> callback) {
  return WaitingCallback::Create(args.isolate(), callback, handle, signals)
             .get();
}

void CancelWait(WaitingCallback* waiting_callback) {
  waiting_callback->Cancel();
}

gin::WrapperInfo g_wrapper_info = { gin::kEmbedderNativeGin };

}  // namespace

const char Support::kModuleName[] = "mojo/public/js/support";

v8::Local<v8::Value> Support::GetModule(v8::Isolate* isolate) {
  gin::PerIsolateData* data = gin::PerIsolateData::From(isolate);
  v8::Local<v8::ObjectTemplate> templ = data->GetObjectTemplate(
      &g_wrapper_info);

  if (templ.IsEmpty()) {
    templ = gin::ObjectTemplateBuilder(isolate)
                .SetMethod("asyncWait", AsyncWait)
                .SetMethod("cancelWait", CancelWait)
                .Build();

    data->SetObjectTemplate(&g_wrapper_info, templ);
  }

  return templ->NewInstance();
}

}  // namespace js
}  // namespace mojo
