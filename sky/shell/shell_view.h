// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_SHELL_VIEW_H_
#define SKY_SHELL_SHELL_VIEW_H_

#include "base/macros.h"
#include "base/memory/scoped_ptr.h"

namespace sky {
namespace shell {
class Engine;
class PlatformView;
class Rasterizer;
class Shell;

class ShellView {
 public:
  explicit ShellView(Shell& shell);
  ~ShellView();

  PlatformView* view() const { return view_.get(); }

 private:
  void CreateEngine();
  void CreatePlatformView();

  Shell& shell_;
  scoped_ptr<PlatformView> view_;
  scoped_ptr<Rasterizer> rasterizer_;
  scoped_ptr<Engine> engine_;

  DISALLOW_COPY_AND_ASSIGN(ShellView);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_SHELL_VIEW_H_
