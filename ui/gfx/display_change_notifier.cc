// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/display_change_notifier.h"

#include "ui/gfx/display.h"
#include "ui/gfx/display_observer.h"

namespace gfx {

namespace {

class DisplayComparator {
 public:
  explicit DisplayComparator(const Display& display)
    : display_id_(display.id())
  {}

  bool operator()(const Display& display) const {
    return display.id() == display_id_;
  }

 private:
  int64 display_id_;
};

} // anonymous namespace

DisplayChangeNotifier::DisplayChangeNotifier() {
}

DisplayChangeNotifier::~DisplayChangeNotifier() {
}

void DisplayChangeNotifier::AddObserver(DisplayObserver* obs) {
  observer_list_.AddObserver(obs);
}

void DisplayChangeNotifier::RemoveObserver(DisplayObserver* obs) {
  observer_list_.RemoveObserver(obs);
}

void DisplayChangeNotifier::NotifyDisplaysChanged(
    const std::vector<Display>& old_displays,
    const std::vector<Display>& new_displays) {
  // Display present in old_displays but not in new_displays has been removed.
  std::vector<Display>::const_iterator old_it = old_displays.begin();
  for (; old_it != old_displays.end(); ++old_it) {
    if (std::find_if(new_displays.begin(), new_displays.end(),
                     DisplayComparator(*old_it)) == new_displays.end()) {
      FOR_EACH_OBSERVER(DisplayObserver, observer_list_,
                        OnDisplayRemoved(*old_it));
    }
  }

  // Display present in new_displays but not in old_displays has been added.
  // Display present in both might have been modified.
  for (std::vector<Display>::const_iterator new_it =
          new_displays.begin(); new_it != new_displays.end(); ++new_it) {
    std::vector<Display>::const_iterator old_it = std::find_if(
        old_displays.begin(), old_displays.end(), DisplayComparator(*new_it));

    if (old_it == old_displays.end()) {
      FOR_EACH_OBSERVER(DisplayObserver, observer_list_,
                        OnDisplayAdded(*new_it));
      continue;
    }

    uint32_t metrics = DisplayObserver::DISPLAY_METRIC_NONE;

    if (new_it->bounds() != old_it->bounds())
      metrics |= DisplayObserver::DISPLAY_METRIC_BOUNDS;

    if (new_it->rotation() != old_it->rotation())
      metrics |= DisplayObserver::DISPLAY_METRIC_ROTATION;

    if (new_it->work_area() != old_it->work_area())
      metrics |= DisplayObserver::DISPLAY_METRIC_WORK_AREA;

    if (new_it->device_scale_factor() != old_it->device_scale_factor())
      metrics |= DisplayObserver::DISPLAY_METRIC_DEVICE_SCALE_FACTOR;

    if (metrics != DisplayObserver::DISPLAY_METRIC_NONE) {
      FOR_EACH_OBSERVER(DisplayObserver,
                        observer_list_,
                        OnDisplayMetricsChanged(*new_it, metrics));
    }
  }
}

} // namespace gfx
