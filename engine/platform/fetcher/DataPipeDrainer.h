// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PLATFORM_FETCHER_DATAPIPEDRAINER_H_
#define SKY_ENGINE_PLATFORM_FETCHER_DATAPIPEDRAINER_H_

#include "base/memory/weak_ptr.h"
#include "mojo/common/handle_watcher.h"
#include "mojo/public/cpp/system/core.h"

namespace blink {

class DataPipeDrainer {
 public:
  class Client {
   public:
    virtual void OnDataAvailable(const void* data, size_t num_bytes) = 0;
    virtual void OnDataComplete() = 0;

   protected:
    virtual ~Client() { }
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

}  // namespace blink

#endif  // SKY_ENGINE_PLATFORM_FETCHER_DATAPIPEDRAINER_H_
