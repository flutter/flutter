// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef __SKY_SHELL_TRACING_CONTROLLER__
#define __SKY_SHELL_TRACING_CONTROLLER__

#include "base/files/file.h"
#include "base/macros.h"
#include "base/memory/ref_counted_memory.h"
#include "base/memory/weak_ptr.h"
#include "base/time/time.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "sky/shell/shell_view.h"

#include <memory>

namespace sky {
namespace shell {

class TracingController {
 public:
  TracingController();
  ~TracingController();

  void StartTracing();

  void StopTracing(const base::FilePath& path);

  // Enables tracing in base. Only use this if an instance of a tracing
  // controller cannot be obtained (can happen early in the lifecycle of the
  // process). In most cases, the |StartTracing| method on an instance of the
  // tracing controller should be used.
  static void StartBaseTracing();

  base::FilePath PictureTracingPathForCurrentTime() const;

  base::FilePath PictureTracingPathForCurrentTime(base::FilePath dir) const;

  base::FilePath TracePathForCurrentTime(base::FilePath dir) const;

  void SetDartInitialized();

  bool tracing_active() const { return tracing_active_; }

  void set_traces_base_path(const base::FilePath& base_path) {
    traces_base_path_ = base_path;
  }

  void set_picture_tracing_enabled(bool enabled) {
    picture_tracing_enabled_ = enabled;
  }

  bool picture_tracing_enabled() const { return picture_tracing_enabled_; }

 private:
  std::unique_ptr<base::File> trace_file_;
  base::FilePath traces_base_path_;
  bool picture_tracing_enabled_;
  bool dart_initialized_;
  bool tracing_active_;

  void StartDartTracing();
  void StopDartTracing();
  void StopBaseTracing();
  void FinalizeTraceFile();

  void OnBaseTraceChunk(const scoped_refptr<base::RefCountedString>& chunk,
                        bool has_more_events);
  void ManageObservatoryCallbacks(bool addOrRemove);

  base::FilePath TracePathWithExtension(base::FilePath dir,
                                        std::string extension) const;

  base::WeakPtrFactory<TracingController> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(TracingController);
};
}  // namespace shell
}  // namespace sky

#endif /* defined(__SKY_SHELL_TRACING_CONTROLLER__) */
