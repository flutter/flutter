// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_JS_DRAIN_DATA_H_
#define MOJO_EDK_JS_DRAIN_DATA_H_

#include "base/memory/scoped_vector.h"
#include "gin/runner.h"
#include "mojo/public/c/environment/async_waiter.h"
#include "mojo/public/cpp/system/core.h"
#include "v8/include/v8.h"

namespace mojo {
namespace js {

// This class is the implementation of the Mojo JavaScript core module's
// drainData() method. It is not intended to be used directly. The caller
// allocates a DrainData on the heap and returns GetPromise() to JS. The
// implementation deletes itself after reading as much data as possible
// and rejecting or resolving the Promise.

class DrainData {
 public:
  // Starts waiting for data on the specified data pipe consumer handle.
  // See WaitForData(). The constructor does not block.
  DrainData(v8::Isolate* isolate, mojo::Handle handle);

  // Returns a Promise that will be settled when no more data can be read.
  // Should be called just once on a newly allocated DrainData object.
  v8::Handle<v8::Value> GetPromise();

 private:
  ~DrainData();

  // Registers an "async waiter" that calls DataReady() via WaitCompleted().
  void WaitForData();
  static void WaitCompleted(void* self, MojoResult result) {
    static_cast<DrainData*>(self)->DataReady(result);
  }

  // Use ReadData() to read whatever is availble now on handle_ and save
  // it in data_buffers_.
  void DataReady(MojoResult result);
  MojoResult ReadData();

  // When the remote data pipe handle is closed, or an error occurs, deliver
  // all of the buffered data to the JS Promise and then delete this.
  void DeliverData(MojoResult result);

  using DataBuffer = std::vector<char>;

  v8::Isolate* isolate_;
  ScopedDataPipeConsumerHandle handle_;
  MojoAsyncWaitID wait_id_;
  base::WeakPtr<gin::Runner> runner_;
  v8::UniquePersistent<v8::Promise::Resolver> resolver_;
  ScopedVector<DataBuffer> data_buffers_;
};

}  // namespace js
}  // namespace mojo

#endif  // MOJO_EDK_JS_DRAIN_DATA_H_
