// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef __SKY_SHELL_TRACING_CONTROLLER__
#define __SKY_SHELL_TRACING_CONTROLLER__

#include "base/files/file.h"
#include "base/macros.h"
#include "base/memory/ref_counted_memory.h"
#include "mojo/common/data_pipe_drainer.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "sky/shell/shell_view.h"

#include <memory>

namespace sky {
namespace shell {

class TracingController : public mojo::common::DataPipeDrainer::Client {
 public:
  TracingController();
  ~TracingController() override;

  void RegisterShellView(ShellView* view);
  void UnregisterShellView(ShellView* view);

  // Enable tracing in base as well as the dart isolates attached to the shell
  // views
  void StartTracing();

  // Stop tracing in base as well as the dart isolates attached to shell views
  // and dump the resulting trace to the specified path. Traces from various
  // sources are separated by a NULL character in the resulting file and must
  // be merged before viewing in the trace viewer
  void StopTracing(const base::FilePath& path);

 private:
  std::unique_ptr<mojo::common::DataPipeDrainer> drainer_;
  std::unique_ptr<base::File> trace_file_;
  // TODO: Currently, only the last shell view is traced. When the shell gains
  // the ability to host multiple shell views, references to each must be stored
  // instead and trace data from each serialized to the output trace.
  ShellView* view_;

  void StartDartTracing();
  void StartBaseTracing();
  void StopDartTracing();
  void StopBaseTracing();
  void OnDataAvailable(const void* data, size_t num_bytes) override;
  void OnDataComplete() override;
  static void OnBaseTraceChunk(
      const scoped_refptr<base::RefCountedString>& chunk,
      bool has_more_events);

  DISALLOW_COPY_AND_ASSIGN(TracingController);
};
}  // namespace shell
}  // namespace sky

#endif /* defined(__SKY_SHELL_TRACING_CONTROLLER__) */
