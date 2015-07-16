// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/display_change_notifier.h"

#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gfx/display.h"
#include "ui/gfx/display_observer.h"

namespace gfx {

class MockDisplayObserver : public DisplayObserver {
 public:
  MockDisplayObserver()
    : display_added_(0),
      display_removed_(0),
      display_changed_(0),
      latest_metrics_change_(DisplayObserver::DISPLAY_METRIC_NONE)
  {}

  ~MockDisplayObserver() override {}

  void OnDisplayAdded(const Display& display) override { display_added_++; }

  void OnDisplayRemoved(const Display& display) override { display_removed_++; }

  void OnDisplayMetricsChanged(const Display& display,
                               uint32_t metrics) override {
    display_changed_++;
    latest_metrics_change_ = metrics;
  }

  int display_added() const {
    return display_added_;
  }

  int display_removed() const {
    return display_removed_;
  }

  int display_changed() const {
    return display_changed_;
  }

  uint32_t latest_metrics_change() const {
    return latest_metrics_change_;
  }

 protected:
  int display_added_;
  int display_removed_;
  int display_changed_;
  uint32_t latest_metrics_change_;

  DISALLOW_COPY_AND_ASSIGN(MockDisplayObserver);
};

TEST(DisplayChangeNotifierTest, AddObserver_Smoke) {
  DisplayChangeNotifier change_notifier;
  MockDisplayObserver observer;

  change_notifier.NotifyDisplaysChanged(
    std::vector<Display>(), std::vector<Display>(1, Display()));
  EXPECT_EQ(0, observer.display_added());

  change_notifier.AddObserver(&observer);
  change_notifier.NotifyDisplaysChanged(
    std::vector<Display>(), std::vector<Display>(1, Display()));
  EXPECT_EQ(1, observer.display_added());
}

TEST(DisplayChangeNotifier, RemoveObserver_Smoke) {
  DisplayChangeNotifier change_notifier;
  MockDisplayObserver observer;

  change_notifier.NotifyDisplaysChanged(
    std::vector<Display>(), std::vector<Display>(1, Display()));
  EXPECT_EQ(0, observer.display_added());

  change_notifier.AddObserver(&observer);
  change_notifier.RemoveObserver(&observer);

  change_notifier.NotifyDisplaysChanged(
    std::vector<Display>(), std::vector<Display>(1, Display()));
  EXPECT_EQ(0, observer.display_added());
}

TEST(DisplayChangeNotifierTest, RemoveObserver_Unknown) {
  DisplayChangeNotifier change_notifier;
  MockDisplayObserver observer;

  change_notifier.RemoveObserver(&observer);
  // Should not crash.
}

TEST(DisplayChangeNotifierTest, NotifyDisplaysChanged_Removed) {
  DisplayChangeNotifier change_notifier;

  // If the previous display array is empty, no removal.
  {
    MockDisplayObserver observer;
    change_notifier.AddObserver(&observer);

    std::vector<Display> old_displays, new_displays;
    new_displays.push_back(Display());

    change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
    EXPECT_EQ(0, observer.display_removed());

    change_notifier.RemoveObserver(&observer);
  }

  // If the previous and new display array are empty, no removal.
  {
    MockDisplayObserver observer;
    change_notifier.AddObserver(&observer);

    std::vector<Display> old_displays, new_displays;

    change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
    EXPECT_EQ(0, observer.display_removed());

    change_notifier.RemoveObserver(&observer);
  }

  // If the new display array is empty, there are as many removal as old
  // displays.
  {
    MockDisplayObserver observer;
    change_notifier.AddObserver(&observer);

    std::vector<Display> old_displays, new_displays;
    old_displays.push_back(Display());
    old_displays.push_back(Display());
    old_displays.push_back(Display());

    change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
    EXPECT_EQ(3, observer.display_removed());

    change_notifier.RemoveObserver(&observer);
  }

  // If displays don't use ids, as long as the new display array has one
  // element, there are no removals.
  {
    MockDisplayObserver observer;
    change_notifier.AddObserver(&observer);

    std::vector<Display> old_displays, new_displays;
    old_displays.push_back(Display());
    old_displays.push_back(Display());
    old_displays.push_back(Display());
    new_displays.push_back(Display());

    change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
    EXPECT_EQ(0, observer.display_removed());

    change_notifier.RemoveObserver(&observer);
  }

  // If displays use ids (and they are unique), ids not present in the new
  // display array will be marked as removed.
  {
    MockDisplayObserver observer;
    change_notifier.AddObserver(&observer);

    std::vector<Display> old_displays, new_displays;
    old_displays.push_back(Display(1));
    old_displays.push_back(Display(2));
    old_displays.push_back(Display(3));
    new_displays.push_back(Display(2));

    change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
    EXPECT_EQ(2, observer.display_removed());

    change_notifier.RemoveObserver(&observer);
  }
}

TEST(DisplayChangeNotifierTest, NotifyDisplaysChanged_Added) {
  DisplayChangeNotifier change_notifier;

  // If the new display array is empty, no addition.
  {
    MockDisplayObserver observer;
    change_notifier.AddObserver(&observer);

    std::vector<Display> old_displays, new_displays;
    old_displays.push_back(Display());

    change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
    EXPECT_EQ(0, observer.display_added());

    change_notifier.RemoveObserver(&observer);
  }

  // If the old and new display arrays are empty, no addition.
  {
    MockDisplayObserver observer;
    change_notifier.AddObserver(&observer);

    std::vector<Display> old_displays, new_displays;

    change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
    EXPECT_EQ(0, observer.display_added());

    change_notifier.RemoveObserver(&observer);
  }

  // If the old display array is empty, there are as many addition as new
  // displays.
  {
    MockDisplayObserver observer;
    change_notifier.AddObserver(&observer);

    std::vector<Display> old_displays, new_displays;
    new_displays.push_back(Display());
    new_displays.push_back(Display());
    new_displays.push_back(Display());

    change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
    EXPECT_EQ(3, observer.display_added());

    change_notifier.RemoveObserver(&observer);
  }

  // If displays don't use ids, as long as the old display array has one
  // element, there are no additions.
  {
    MockDisplayObserver observer;
    change_notifier.AddObserver(&observer);

    std::vector<Display> old_displays, new_displays;
    old_displays.push_back(Display());
    new_displays.push_back(Display());
    new_displays.push_back(Display());
    new_displays.push_back(Display());

    change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
    EXPECT_EQ(0, observer.display_added());

    change_notifier.RemoveObserver(&observer);
  }

  // If displays use ids (and they are unique), ids not present in the old
  // display array will be marked as added.
  {
    MockDisplayObserver observer;
    change_notifier.AddObserver(&observer);

    std::vector<Display> old_displays, new_displays;
    old_displays.push_back(Display(1));
    new_displays.push_back(Display(1));
    new_displays.push_back(Display(2));
    new_displays.push_back(Display(3));

    change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
    EXPECT_EQ(2, observer.display_added());

    change_notifier.RemoveObserver(&observer);
  }
}

TEST(DisplayChangeNotifierTest, NotifyDisplaysChanged_Changed_Smoke) {
  DisplayChangeNotifier change_notifier;

  // If the old display array is empty, no change.
  {
    MockDisplayObserver observer;
    change_notifier.AddObserver(&observer);

    std::vector<Display> old_displays, new_displays;
    new_displays.push_back(Display());

    change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
    EXPECT_EQ(0, observer.display_changed());

    change_notifier.RemoveObserver(&observer);
  }

  // If the new display array is empty, no change.
  {
    MockDisplayObserver observer;
    change_notifier.AddObserver(&observer);

    std::vector<Display> old_displays, new_displays;
    old_displays.push_back(Display());

    change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
    EXPECT_EQ(0, observer.display_changed());

    change_notifier.RemoveObserver(&observer);
  }

  // If the old and new display arrays are empty, no change.
  {
    MockDisplayObserver observer;
    change_notifier.AddObserver(&observer);

    std::vector<Display> old_displays, new_displays;

    change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
    EXPECT_EQ(0, observer.display_changed());

    change_notifier.RemoveObserver(&observer);
  }

  // If there is an intersection between old and new displays but there are no
  // metrics changes, there is no display change.
  {
    MockDisplayObserver observer;
    change_notifier.AddObserver(&observer);

    std::vector<Display> old_displays, new_displays;
    old_displays.push_back(Display(1));
    new_displays.push_back(Display(1));
    new_displays.push_back(Display(2));
    new_displays.push_back(Display(3));

    change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
    EXPECT_EQ(0, observer.display_changed());

    change_notifier.RemoveObserver(&observer);
  }
}

TEST(DisplayChangeNotifierTest, NotifyDisplaysChanged_Changed_Bounds) {
  DisplayChangeNotifier change_notifier;

  {
    MockDisplayObserver observer;
    change_notifier.AddObserver(&observer);

    std::vector<Display> old_displays, new_displays;
    old_displays.push_back(Display(1, Rect(0, 0, 200, 200)));
    new_displays.push_back(Display(1, Rect(0, 0, 200, 200)));

    change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
    EXPECT_EQ(0, observer.display_changed());

    change_notifier.RemoveObserver(&observer);
  }

  {
    MockDisplayObserver observer;
    change_notifier.AddObserver(&observer);

    std::vector<Display> old_displays, new_displays;
    old_displays.push_back(Display(1, Rect(0, 0, 200, 200)));
    new_displays.push_back(Display(1, Rect(10, 10, 300, 300)));

    change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
    EXPECT_EQ(1, observer.display_changed());
    uint32_t metrics_change = DisplayObserver::DISPLAY_METRIC_BOUNDS |
                                  DisplayObserver::DISPLAY_METRIC_WORK_AREA;
    EXPECT_EQ(metrics_change, observer.latest_metrics_change());

    change_notifier.RemoveObserver(&observer);
  }

  {
    MockDisplayObserver observer;
    change_notifier.AddObserver(&observer);

    std::vector<Display> old_displays, new_displays;
    old_displays.push_back(Display(1, Rect(0, 0, 200, 200)));
    new_displays.push_back(Display(1, Rect(0, 0, 200, 200)));
    new_displays[0].set_bounds(Rect(10, 10, 300, 300));

    change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
    EXPECT_EQ(1, observer.display_changed());
    EXPECT_EQ(DisplayObserver::DISPLAY_METRIC_BOUNDS,
              observer.latest_metrics_change());

    change_notifier.RemoveObserver(&observer);
  }
}

TEST(DisplayChangeNotifierTest, NotifyDisplaysChanged_Changed_Rotation) {
  DisplayChangeNotifier change_notifier;
  MockDisplayObserver observer;
  change_notifier.AddObserver(&observer);

  std::vector<Display> old_displays, new_displays;
  old_displays.push_back(Display(1));
  old_displays[0].SetRotationAsDegree(0);
  new_displays.push_back(Display(1));
  new_displays[0].SetRotationAsDegree(180);

  change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
  EXPECT_EQ(1, observer.display_changed());
  EXPECT_EQ(DisplayObserver::DISPLAY_METRIC_ROTATION,
            observer.latest_metrics_change());
}

TEST(DisplayChangeNotifierTest, NotifyDisplaysChanged_Changed_WorkArea) {
  DisplayChangeNotifier change_notifier;
  MockDisplayObserver observer;
  change_notifier.AddObserver(&observer);

  std::vector<Display> old_displays, new_displays;
  old_displays.push_back(Display(1));
  old_displays[0].set_work_area(Rect(0, 0, 200, 200));
  new_displays.push_back(Display(1));
  new_displays[0].set_work_area(Rect(20, 20, 300, 300));

  change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
  EXPECT_EQ(1, observer.display_changed());
  EXPECT_EQ(DisplayObserver::DISPLAY_METRIC_WORK_AREA,
            observer.latest_metrics_change());
}

TEST(DisplayChangeNotifierTest, NotifyDisplaysChanged_Changed_DSF) {
  DisplayChangeNotifier change_notifier;
  MockDisplayObserver observer;
  change_notifier.AddObserver(&observer);

  std::vector<Display> old_displays, new_displays;
  old_displays.push_back(Display(1));
  old_displays[0].set_device_scale_factor(1.f);
  new_displays.push_back(Display(1));
  new_displays[0].set_device_scale_factor(2.f);

  change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
  EXPECT_EQ(1, observer.display_changed());
  EXPECT_EQ(DisplayObserver::DISPLAY_METRIC_DEVICE_SCALE_FACTOR,
            observer.latest_metrics_change());
}

TEST(DisplayChangeNotifierTest, NotifyDisplaysChanged_Changed_Multi_Displays) {
  DisplayChangeNotifier change_notifier;
  MockDisplayObserver observer;
  change_notifier.AddObserver(&observer);

  std::vector<Display> old_displays, new_displays;
  old_displays.push_back(Display(1));
  old_displays.push_back(Display(2));
  old_displays.push_back(Display(3));
  new_displays.push_back(Display(1));
  new_displays.push_back(Display(2));
  new_displays.push_back(Display(3));

  old_displays[0].set_device_scale_factor(1.f);
  new_displays[0].set_device_scale_factor(2.f);

  old_displays[1].set_bounds(Rect(0, 0, 200, 200));
  new_displays[1].set_bounds(Rect(0, 0, 400, 400));

  old_displays[2].SetRotationAsDegree(0);
  new_displays[2].SetRotationAsDegree(90);

  change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
  EXPECT_EQ(3, observer.display_changed());
}

TEST(DisplayChangeNotifierTest, NotifyDisplaysChanged_Changed_Multi_Metrics) {
  DisplayChangeNotifier change_notifier;
  MockDisplayObserver observer;
  change_notifier.AddObserver(&observer);

  std::vector<Display> old_displays, new_displays;
  old_displays.push_back(Display(1, Rect(0, 0, 200, 200)));
  old_displays[0].set_device_scale_factor(1.f);
  old_displays[0].SetRotationAsDegree(0);

  new_displays.push_back(Display(1, Rect(100, 100, 200, 200)));
  new_displays[0].set_device_scale_factor(2.f);
  new_displays[0].SetRotationAsDegree(90);

  change_notifier.NotifyDisplaysChanged(old_displays, new_displays);
  EXPECT_EQ(1, observer.display_changed());
  uint32_t metrics = DisplayObserver::DISPLAY_METRIC_BOUNDS |
                         DisplayObserver::DISPLAY_METRIC_ROTATION |
                         DisplayObserver::DISPLAY_METRIC_WORK_AREA |
                         DisplayObserver::DISPLAY_METRIC_DEVICE_SCALE_FACTOR;
  EXPECT_EQ(metrics, observer.latest_metrics_change());
}

} // namespace gfx
