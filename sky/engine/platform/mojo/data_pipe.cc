// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/platform/mojo/data_pipe.h"

#include <memory>

#include "base/bind.h"
#include "mojo/data_pipe_utils/data_pipe_drainer.h"
#include "sky/engine/platform/mojo/data_pipe.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/wtf/RefPtr.h"

namespace blink {
namespace {

class DrainJob : public mojo::common::DataPipeDrainer::Client {
 public:
  explicit DrainJob(base::Callback<void(PassRefPtr<SharedBuffer>)> callback)
    : callback_(callback) {
  }

  void Start(mojo::ScopedDataPipeConsumerHandle handle) {
    buffer_ = SharedBuffer::create();
    drainer_.reset(new mojo::common::DataPipeDrainer(this, handle.Pass()));
  }

 private:
  // mojo::common::DataPipeDrainer::Client
  void OnDataAvailable(const void* data, size_t num_bytes) override {
    buffer_->append(static_cast<const char*>(data), num_bytes);
  }

  void OnDataComplete() override {
    Platform::current()->GetUITaskRunner()->PostTask(FROM_HERE,
      base::Bind(callback_, buffer_.release()));
    delete this;
  }

  base::Callback<void(PassRefPtr<SharedBuffer>)> callback_;
  RefPtr<SharedBuffer> buffer_;
  std::unique_ptr<mojo::common::DataPipeDrainer> drainer_;

  DISALLOW_COPY_AND_ASSIGN(DrainJob);
};

} // namespace


void DrainDataPipeInBackground(
    mojo::ScopedDataPipeConsumerHandle handle,
    base::Callback<void(PassRefPtr<SharedBuffer>)> callback) {
  DrainJob* job = new DrainJob(callback);
  Platform::current()->GetIOTaskRunner()->PostTask(FROM_HERE,
    base::Bind(&DrainJob::Start, base::Unretained(job), base::Passed(&handle)));
}

}  // namespace blink
