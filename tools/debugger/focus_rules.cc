// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/tools/debugger/focus_rules.h"

namespace sky {
namespace debugger {

FocusRules::FocusRules(mojo::WindowManagerApp* window_manager_app,
                       mojo::View* content)
    : content_(content),
      window_manager_app_(window_manager_app) {
}

FocusRules::~FocusRules() {
}

bool FocusRules::IsToplevelWindow(aura::Window* window) const {
  return mojo::WindowManagerApp::GetViewForWindow(window)->parent() == content_;
}

bool FocusRules::CanActivateWindow(aura::Window* window) const {
  return mojo::WindowManagerApp::GetViewForWindow(window)->parent() == content_;
}

bool FocusRules::CanFocusWindow(aura::Window* window) const {
  return true;
}

aura::Window* FocusRules::GetToplevelWindow(aura::Window* window) const {
  mojo::View* view = mojo::WindowManagerApp::GetViewForWindow(window);
  while (view->parent() != content_) {
    view = view->parent();
    if (!view)
      return NULL;
  }
  return window_manager_app_->GetWindowForViewId(view->id());
}

aura::Window* FocusRules::GetActivatableWindow(aura::Window* window) const {
  return GetToplevelWindow(window);
}

aura::Window* FocusRules::GetFocusableWindow(aura::Window* window) const {
  return window;
}

aura::Window* FocusRules::GetNextActivatableWindow(aura::Window* ignore) const {
  aura::Window* activatable = GetActivatableWindow(ignore);
  const aura::Window::Windows& children = activatable->parent()->children();
  for (aura::Window::Windows::const_reverse_iterator it = children.rbegin();
       it != children.rend(); ++it) {
    if (*it != ignore)
      return *it;
  }
  return NULL;
}

}  // namespace debugger
}  // namespace sky
