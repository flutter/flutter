// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TONIC_DART_SNAPSHOT_LOADER_H_
#define FLUTTER_TONIC_DART_SNAPSHOT_LOADER_H_

#include <vector>

#include "dart/runtime/include/dart_api.h"
#include "glue/drain_data_pipe_job.h"
#include "lib/ftl/functional/closure.h"
#include "lib/ftl/macros.h"
#include "lib/tonic/dart_state.h"

namespace blink {

class DartSnapshotLoader {
 public:
  explicit DartSnapshotLoader(tonic::DartState* dart_state);
  ~DartSnapshotLoader();

  void LoadSnapshot(mojo::ScopedDataPipeConsumerHandle pipe,
                    const ftl::Closure& callback);

 private:
  ftl::WeakPtr<tonic::DartState> dart_state_;
  std::unique_ptr<glue::DrainDataPipeJob> drainer_;

  FTL_DISALLOW_COPY_AND_ASSIGN(DartSnapshotLoader);
};

}  // namespace blink

#endif  // FLUTTER_TONIC_DART_SNAPSHOT_LOADER_H_
