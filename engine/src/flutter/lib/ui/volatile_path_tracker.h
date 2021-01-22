// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_VOLATILE_PATH_TRACKER_H_
#define FLUTTER_LIB_VOLATILE_PATH_TRACKER_H_

#include <deque>
#include <mutex>
#include <set>

#include "flutter/fml/macros.h"
#include "flutter/fml/task_runner.h"
#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/core/SkPath.h"

namespace flutter {

/// A cache for paths drawn from dart:ui.
///
/// Whenever a flutter::CanvasPath is created, it must Insert an entry into
/// this cache. Whenever a frame is drawn, the shell must call OnFrame. The
/// cache will flip the volatility bit on the SkPath and remove it from the
/// cache. If the Dart object is released, Erase must be called to avoid
/// tracking a path that is no longer referenced in Dart code.
///
/// Enabling this cache may cause difficult to predict minor pixel differences
/// when paths are rendered. If deterministic rendering is needed, e.g. for a
/// screen diffing test, this class will not cache any paths and will
/// automatically set the volatility of the path to false.
class VolatilePathTracker {
 public:
  /// The fields of this struct must only accessed on the UI task runner.
  struct TrackedPath {
    bool tracking_volatility = false;
    int frame_count = 0;
    SkPath path;
  };

  VolatilePathTracker(fml::RefPtr<fml::TaskRunner> ui_task_runner,
                      bool enabled);

  static constexpr int kFramesOfVolatility = 2;

  // Starts tracking a path.
  // Must be called from the UI task runner.
  //
  // Callers should only insert paths that are currently volatile.
  void Insert(std::shared_ptr<TrackedPath> path);

  // Removes a path from tracking.
  //
  // May be called from any thread.
  void Erase(std::shared_ptr<TrackedPath> path);

  // Called by the shell at the end of a frame after notifying Dart about idle
  // time.
  //
  // This method will flip the volatility bit to false for any paths that have
  // survived the |kFramesOfVolatility|.
  //
  // Must be called from the UI task runner.
  void OnFrame();

  bool enabled() const { return enabled_; }

 private:
  fml::RefPtr<fml::TaskRunner> ui_task_runner_;
  std::atomic_bool needs_drain_ = false;
  std::mutex paths_to_remove_mutex_;
  std::deque<std::shared_ptr<TrackedPath>> paths_to_remove_;
  std::set<std::shared_ptr<TrackedPath>> paths_;
  bool enabled_ = true;

  void Drain();

  FML_DISALLOW_COPY_AND_ASSIGN(VolatilePathTracker);
};

}  // namespace flutter

#endif  // FLUTTER_LIB_VOLATILE_PATH_TRACKER_H_
