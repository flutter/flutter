// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_VIEW_MANAGER_PUBLIC_CPP_VIEW_OBSERVER_H_
#define MOJO_SERVICES_VIEW_MANAGER_PUBLIC_CPP_VIEW_OBSERVER_H_

#include <vector>

#include "input_events/public/interfaces/input_events.mojom.h"
#include "view_manager/public/cpp/view.h"

namespace mojo {

class View;

// A note on -ing and -ed suffixes:
//
// -ing methods are called before changes are applied to the local view model.
// -ed methods are called after changes are applied to the local view model.
//
// If the change originated from another connection to the view manager, it's
// possible that the change has already been applied to the service-side model
// prior to being called, so for example in the case of OnViewDestroying(), it's
// possible the view has already been destroyed on the service side.

class ViewObserver {
 public:
  struct TreeChangeParams {
    TreeChangeParams();
    View* target;
    View* old_parent;
    View* new_parent;
    View* receiver;
  };

  virtual void OnTreeChanging(const TreeChangeParams& params) {}
  virtual void OnTreeChanged(const TreeChangeParams& params) {}

  virtual void OnViewReordering(View* view,
                                View* relative_view,
                                OrderDirection direction) {}
  virtual void OnViewReordered(View* view,
                               View* relative_view,
                               OrderDirection direction) {}

  virtual void OnViewDestroying(View* view) {}
  virtual void OnViewDestroyed(View* view) {}

  virtual void OnViewBoundsChanging(View* view,
                                    const Rect& old_bounds,
                                    const Rect& new_bounds) {}
  virtual void OnViewBoundsChanged(View* view,
                                   const Rect& old_bounds,
                                   const Rect& new_bounds) {}

  virtual void OnViewViewportMetricsChanged(View* view,
                                            const ViewportMetrics& old_bounds,
                                            const ViewportMetrics& new_bounds) {
  }

  virtual void OnViewCaptureChanged(View* gained_capture, View* lost_capture) {}
  virtual void OnViewFocusChanged(View* gained_focus, View* lost_focus) {}
  virtual void OnViewActivationChanged(View* gained_active, View* lost_active) {
  }

  virtual void OnViewInputEvent(View* view, const EventPtr& event) {}

  virtual void OnViewVisibilityChanging(View* view) {}
  virtual void OnViewVisibilityChanged(View* view) {}

  // Invoked when this View's shared properties have changed. This can either
  // be caused by SetSharedProperty() being called locally, or by us receiving
  // a mojo message that this property has changed. If this property has been
  // added, |old_data| is null. If this property was removed, |new_data| is
  // null.
  virtual void OnViewSharedPropertyChanged(
      View* view,
      const std::string& name,
      const std::vector<uint8_t>* old_data,
      const std::vector<uint8_t>* new_data) {}

  // Invoked when SetProperty() or ClearProperty() is called on the window.
  // |key| is either a WindowProperty<T>* (SetProperty, ClearProperty). Either
  // way, it can simply be compared for equality with the property
  // constant. |old| is the old property value, which must be cast to the
  // appropriate type before use.
  virtual void OnViewLocalPropertyChanged(
      View* view,
      const void* key,
      intptr_t old) {}

  virtual void OnViewEmbeddedAppDisconnected(View* view) {}

  // Sent when the drawn state changes. This is only sent for the root nodes
  // when embedded.
  virtual void OnViewDrawnChanging(View* view) {}
  virtual void OnViewDrawnChanged(View* view) {}

 protected:
  virtual ~ViewObserver() {}
};

}  // namespace mojo

#endif  // MOJO_SERVICES_VIEW_MANAGER_PUBLIC_CPP_VIEW_OBSERVER_H_
