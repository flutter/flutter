// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/js/threading.h"

#include "base/message_loop/message_loop.h"
#include "gin/object_template_builder.h"
#include "gin/per_isolate_data.h"
#include "mojo/edk/js/handle.h"

namespace mojo {
namespace js {

namespace {

void Quit() {
  base::MessageLoop::current()->QuitNow();
}

gin::WrapperInfo g_wrapper_info = { gin::kEmbedderNativeGin };

}  // namespace

const char Threading::kModuleName[] = "mojo/public/js/threading";

v8::Local<v8::Value> Threading::GetModule(v8::Isolate* isolate) {
  gin::PerIsolateData* data = gin::PerIsolateData::From(isolate);
  v8::Local<v8::ObjectTemplate> templ = data->GetObjectTemplate(
      &g_wrapper_info);

  if (templ.IsEmpty()) {
    templ = gin::ObjectTemplateBuilder(isolate)
        .SetMethod("quit", Quit)
        .Build();

    data->SetObjectTemplate(&g_wrapper_info, templ);
  }

  return templ->NewInstance();
}

Threading::Threading() {
}

}  // namespace js
}  // namespace mojo
