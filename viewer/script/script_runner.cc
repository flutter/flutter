// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/script/script_runner.h"

#include "gin/per_context_data.h"
#include "gin/try_catch.h"
#include "sky/engine/public/web/WebFrame.h"
#include "sky/engine/public/web/WebScriptSource.h"
#include "sky/engine/public/web/WebView.h"
#include "v8/include/v8.h"
#include <iostream>

namespace sky {

ScriptRunner::ScriptRunner(blink::WebFrame* frame,
                           v8::Handle<v8::Context> context)
    : frame_(frame),
      context_holder_(nullptr) {
  gin::PerContextData* context_data = gin::PerContextData::From(context);
  context_data->set_runner(this);
  context_holder_ = context_data->context_holder();
}

ScriptRunner::~ScriptRunner() {
}

void ScriptRunner::Run(const std::string& source,
                       const std::string& resource_name) {
  gin::TryCatch try_catch;
  frame_->executeScript(blink::WebScriptSource(
      blink::WebString::fromUTF8(source),
      GURL("internal-resouce:" + resource_name)));
  // FIXME: We should really log to the console rather than to INFO.
  if (try_catch.HasCaught())
    std::cout << try_catch.GetStackTrace();
}

v8::Handle<v8::Value> ScriptRunner::Call(v8::Handle<v8::Function> function,
                                         v8::Handle<v8::Value> receiver,
                                         int argc,
                                         v8::Handle<v8::Value> argv[]) {
  gin::TryCatch try_catch;
  v8::Handle<v8::Value> result = frame_->callFunctionEvenIfScriptDisabled(
      function, receiver, argc, argv);
  if (try_catch.HasCaught())
    std::cout << try_catch.GetStackTrace();
  return result;
}

gin::ContextHolder* ScriptRunner::GetContextHolder() {
  return context_holder_;
}

}  // namespace sky
