// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_JS_MOJO_RUNNER_DELEGATE_H_
#define MOJO_EDK_JS_MOJO_RUNNER_DELEGATE_H_

#include "base/macros.h"
#include "gin/modules/module_runner_delegate.h"
#include "mojo/public/c/system/core.h"

namespace mojo {
namespace js {

class MojoRunnerDelegate : public gin::ModuleRunnerDelegate {
 public:
  MojoRunnerDelegate();
  ~MojoRunnerDelegate() override;

  void Start(gin::Runner* runner, MojoHandle pipe, const std::string& module);

 private:
  // From ModuleRunnerDelegate:
  void UnhandledException(gin::ShellRunner* runner,
                          gin::TryCatch& try_catch) override;

  DISALLOW_COPY_AND_ASSIGN(MojoRunnerDelegate);
};

}  // namespace js
}  // namespace mojo

#endif  // MOJO_EDK_JS_MOJO_RUNNER_DELEGATE_H_
