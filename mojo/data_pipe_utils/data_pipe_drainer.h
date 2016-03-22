// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_DATA_PIPE_UTILS_DATA_PIPE_DRAINER_H_
#define MOJO_DATA_PIPE_UTILS_DATA_PIPE_DRAINER_H_

#include "base/macros.h"
#include "base/memory/weak_ptr.h"
#include "mojo/message_pump/handle_watcher.h"
#include "mojo/public/cpp/system/data_pipe.h"

namespace mojo {
namespace common {

class DataPipeDrainer {
 public:
  class Client {
   public:
    virtual void OnDataAvailable(const void* data, size_t num_bytes) = 0;
    virtual void OnDataComplete() = 0;

   protected:
    virtual ~Client() {}
  };

  DataPipeDrainer(Client*, mojo::ScopedDataPipeConsumerHandle source);
  ~DataPipeDrainer();

 private:
  void ReadData();
  void WaitForData();
  void WaitComplete(MojoResult result);

  Client* client_;
  mojo::ScopedDataPipeConsumerHandle source_;
  mojo::common::HandleWatcher handle_watcher_;

  base::WeakPtrFactory<DataPipeDrainer> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(DataPipeDrainer);
};

}  // namespace common
}  // namespace mojo

#endif  // MOJO_DATA_PIPE_UTILS_DATA_PIPE_DRAINER_H_
