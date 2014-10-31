// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_TOOLS_DEBUGGER_FOCUS_RULES_H_
#define SKY_TOOLS_DEBUGGER_FOCUS_RULES_H_

#include "mojo/services/window_manager/window_manager_app.h"
#include "ui/aura/window.h"
#include "ui/wm/core/focus_rules.h"

namespace sky {
namespace debugger {

class FocusRules : public wm::FocusRules {
 public:
  FocusRules(mojo::WindowManagerApp* window_manager_app, mojo::View* content);
  virtual ~FocusRules();

 private:
  // Overridden from wm::FocusRules:
  bool IsToplevelWindow(aura::Window* window) const override;
  bool CanActivateWindow(aura::Window* window) const override;
  bool CanFocusWindow(aura::Window* window) const override;
  aura::Window* GetToplevelWindow(aura::Window* window) const override;
  aura::Window* GetActivatableWindow(aura::Window* window) const override;
  aura::Window* GetFocusableWindow(aura::Window* window) const override;
  aura::Window* GetNextActivatableWindow(aura::Window* ignore) const override;

  mojo::View* content_;
  mojo::WindowManagerApp* window_manager_app_;

  DISALLOW_COPY_AND_ASSIGN(FocusRules);
};

}  // namespace debugger
}  // namespace sky

#endif  // SKY_TOOLS_DEBUGGER_FOCUS_RULES_H_
