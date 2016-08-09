// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_GLU_DRAIN_DATA_PIPE_JOB_H_
#define FLUTTER_GLU_DRAIN_DATA_PIPE_JOB_H_

#include <functional>
#include <memory>
#include <vector>

#include "lib/ftl/macros.h"
#include "mojo/public/cpp/system/data_pipe.h"

namespace glue {

class DrainDataPipeJob {
 public:
  using ResultCallback = std::function<void(std::vector<char>)>;

  DrainDataPipeJob(mojo::ScopedDataPipeConsumerHandle handle,
                   const ResultCallback& callback);
  ~DrainDataPipeJob();

 private:
  class JobImpl;

  std::unique_ptr<JobImpl> impl_;

  FTL_DISALLOW_COPY_AND_ASSIGN(DrainDataPipeJob);
};

}  // namespace glue

#endif  // FLUTTER_GLU_DRAIN_DATA_PIPE_JOB_H_
