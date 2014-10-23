// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_SCRIPT_SCRIPT_RUNNER_H_
#define SKY_VIEWER_SCRIPT_SCRIPT_RUNNER_H_

#include "gin/runner.h"

namespace blink {
class WebFrame;
}

namespace sky {

class ScriptRunner : public gin::Runner {
 public:
  ScriptRunner(blink::WebFrame*, v8::Handle<v8::Context> context);
  ~ScriptRunner();

  virtual void Run(const std::string& source,
                   const std::string& resource_name) override;
  virtual v8::Handle<v8::Value> Call(v8::Handle<v8::Function> function,
                                     v8::Handle<v8::Value> receiver,
                                     int argc,
                                     v8::Handle<v8::Value> argv[]) override;
  virtual gin::ContextHolder* GetContextHolder() override;

 private:
  blink::WebFrame* frame_;
  gin::ContextHolder* context_holder_;

  DISALLOW_COPY_AND_ASSIGN(ScriptRunner);
};

}  // namespace sky

#endif  // SKY_VIEWER_SCRIPT_SCRIPT_RUNNER_H_
