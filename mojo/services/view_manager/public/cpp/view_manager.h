// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_VIEW_MANAGER_PUBLIC_CPP_VIEW_MANAGER_H_
#define MOJO_SERVICES_VIEW_MANAGER_PUBLIC_CPP_VIEW_MANAGER_H_

#include <string>

#include "view_manager/public/cpp/types.h"

namespace mojo {
class View;

// Encapsulates a connection to the view manager service. A unique connection
// is made every time an app is embedded.
class ViewManager {
 public:
  // Returns the URL of the application that embedded this application.
  virtual const std::string& GetEmbedderURL() const = 0;

  // Returns the root of this connection.
  virtual View* GetRoot() = 0;

  // Returns a View known to this connection.
  virtual View* GetViewById(Id id) = 0;

  // Returns the focused view; null if focus is not yet known or another app is
  // focused.
  virtual View* GetFocusedView() = 0;

  // Creates and returns a new View (which is owned by the ViewManager). Views
  // are initially hidden, use SetVisible(true) to show.
  virtual View* CreateView() = 0;

 protected:
  virtual ~ViewManager() {}
};

}  // namespace mojo

#endif  // MOJO_SERVICES_VIEW_MANAGER_PUBLIC_CPP_VIEW_MANAGER_H_
