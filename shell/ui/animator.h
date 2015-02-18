// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_UI_ANIMATOR_H_
#define SKY_SHELL_UI_ANIMATOR_H_

#include "base/memory/weak_ptr.h"
#include "sky/shell/ui/engine.h"

namespace sky {
namespace shell {

class Animator {
 public:
  explicit Animator(const Engine::Config& config, Engine* engine);
  ~Animator();

  void RequestFrame();

 private:
  void BeginFrame();
  void OnFrameComplete();

  Engine::Config config_;
  Engine* engine_;
  bool engine_requested_frame_;
  bool frame_in_progress_;

  base::WeakPtrFactory<Animator> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(Animator);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_UI_ANIMATOR_H_
