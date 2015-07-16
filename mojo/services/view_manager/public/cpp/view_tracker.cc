// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "view_manager/public/cpp/view_tracker.h"

namespace mojo {

ViewTracker::ViewTracker() {
}

ViewTracker::~ViewTracker() {
  for (Views::iterator i = views_.begin(); i != views_.end(); ++i)
    (*i)->RemoveObserver(this);
}

void ViewTracker::Add(View* view) {
  if (views_.count(view))
    return;

  view->AddObserver(this);
  views_.insert(view);
}

void ViewTracker::Remove(View* view) {
  if (views_.count(view)) {
    views_.erase(view);
    view->RemoveObserver(this);
  }
}

bool ViewTracker::Contains(View* view) {
  return views_.count(view) > 0;
}

void ViewTracker::OnViewDestroying(View* view) {
  DCHECK_GT(views_.count(view), 0u);
  Remove(view);
}

}  // namespace mojo
