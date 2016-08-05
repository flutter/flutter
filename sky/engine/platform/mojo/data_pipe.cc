// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/platform/mojo/data_pipe.h"

#include <memory>

#include "lib/ftl/macros.h"
#include "mojo/data_pipe_utils/data_pipe_drainer.h"
#include "sky/engine/platform/mojo/data_pipe.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/wtf/RefPtr.h"

using mojo::common::DataPipeDrainer;

namespace blink {
namespace {

class DrainJob : public DataPipeDrainer::Client {
 public:
  explicit DrainJob(std::function<void(PassRefPtr<SharedBuffer>)> callback)
      : callback_(callback) {}

  void Start(mojo::ScopedDataPipeConsumerHandle handle) {
    buffer_ = SharedBuffer::create();
    drainer_.reset(new DataPipeDrainer(this, handle.Pass()));
  }

 private:
  // mojo::common::DataPipeDrainer::Client
  void OnDataAvailable(const void* data, size_t num_bytes) override {
    buffer_->append(static_cast<const char*>(data), num_bytes);
  }

  void OnDataComplete() override {
    RefPtr<SharedBuffer> buffer = buffer_.release();
    std::function<void(PassRefPtr<SharedBuffer>)> callback = callback_;

    delete this;

    callback(buffer);
  }

  std::function<void(PassRefPtr<SharedBuffer>)> callback_;
  RefPtr<SharedBuffer> buffer_;
  std::unique_ptr<mojo::common::DataPipeDrainer> drainer_;

  FTL_DISALLOW_COPY_AND_ASSIGN(DrainJob);
};

}  // namespace

void DrainDataPipe(mojo::ScopedDataPipeConsumerHandle handle,
                   std::function<void(PassRefPtr<SharedBuffer>)> callback) {
  (new DrainJob(callback))->Start(handle.Pass());
}

}  // namespace blink
