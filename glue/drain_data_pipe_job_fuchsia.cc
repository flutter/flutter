// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/glue/drain_data_pipe_job.h"

#include <utility>

#include "lib/mtl/data_pipe/data_pipe_drainer.h"

using mtl::DataPipeDrainer;

namespace glue {

class DrainDataPipeJob::JobImpl : public DataPipeDrainer::Client {
 public:
  explicit JobImpl(mojo::ScopedDataPipeConsumerHandle handle,
                   const ResultCallback& callback)
      : callback_(callback), drainer_(this) {
    drainer_.Start(std::move(handle));
  }

 private:
  // mojo::common::DataPipeDrainer::Client
  void OnDataAvailable(const void* data, size_t num_bytes) override {
    const uint8_t* bytes = static_cast<const uint8_t*>(data);
    buffer_.insert(buffer_.end(), bytes, bytes + num_bytes);
  }

  void OnDataComplete() override { callback_(std::move(buffer_)); }

  std::vector<uint8_t> buffer_;
  ResultCallback callback_;
  DataPipeDrainer drainer_;

  FTL_DISALLOW_COPY_AND_ASSIGN(JobImpl);
};

DrainDataPipeJob::DrainDataPipeJob(mojo::ScopedDataPipeConsumerHandle handle,
                                   const ResultCallback& callback)
    : impl_(new JobImpl(std::move(handle), callback)) {}

DrainDataPipeJob::~DrainDataPipeJob() {}

}  // namespace glue
