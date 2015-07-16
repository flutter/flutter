// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "view_manager/public/cpp/view_manager_delegate.h"

namespace mojo {

bool ViewManagerDelegate::OnPerformAction(View* view,
                                          const std::string& action) {
  return false;
}

}  // namespace mojo
