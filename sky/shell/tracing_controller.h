// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef __SKY_SHELL_TRACING_CONTROLLER__
#define __SKY_SHELL_TRACING_CONTROLLER__

#include "base/macros.h"
#include "base/files/file.h"

namespace sky {
namespace shell {

class TracingController {
 public:
  TracingController();
  ~TracingController();

  void StartTracing();

  void StopTracing();

  // Enables tracing in base. Only use this if an instance of a tracing
  // controller cannot be obtained (can happen early in the lifecycle of the
  // process). In most cases, the |StartTracing| method on an instance of the
  // tracing controller should be used.
  static void StartBaseTracing();

  base::FilePath PictureTracingPathForCurrentTime() const;

  base::FilePath PictureTracingPathForCurrentTime(base::FilePath dir) const;

  bool tracing_active() const { return tracing_active_; }

  void set_traces_base_path(const base::FilePath& base_path) {
    traces_base_path_ = base_path;
  }

  void set_picture_tracing_enabled(bool enabled) {
    picture_tracing_enabled_ = enabled;
  }

  bool picture_tracing_enabled() const { return picture_tracing_enabled_; }

 private:
  base::FilePath traces_base_path_;
  bool picture_tracing_enabled_;
  bool tracing_active_;

  void StopBaseTracing();

  void StartDartTracing();
  void StopDartTracing();

  base::FilePath TracePathWithExtension(base::FilePath dir,
                                        std::string extension) const;

  DISALLOW_COPY_AND_ASSIGN(TracingController);
};
}  // namespace shell
}  // namespace sky

#endif /* defined(__SKY_SHELL_TRACING_CONTROLLER__) */
