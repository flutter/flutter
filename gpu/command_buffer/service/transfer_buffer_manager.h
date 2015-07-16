// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_TRANSFER_BUFFER_MANAGER_H_
#define GPU_COMMAND_BUFFER_SERVICE_TRANSFER_BUFFER_MANAGER_H_

#include <set>
#include <vector>

#include "base/basictypes.h"
#include "base/compiler_specific.h"
#include "base/containers/hash_tables.h"
#include "base/memory/shared_memory.h"
#include "gpu/command_buffer/common/command_buffer_shared.h"

namespace gpu {

class GPU_EXPORT TransferBufferManagerInterface {
 public:
  virtual ~TransferBufferManagerInterface();

  virtual bool RegisterTransferBuffer(int32 id,
                                      scoped_ptr<BufferBacking> buffer) = 0;
  virtual void DestroyTransferBuffer(int32 id) = 0;
  virtual scoped_refptr<Buffer> GetTransferBuffer(int32 id) = 0;
};

class GPU_EXPORT TransferBufferManager
    : public TransferBufferManagerInterface {
 public:
  TransferBufferManager();

  bool Initialize();
  bool RegisterTransferBuffer(
      int32 id,
      scoped_ptr<BufferBacking> buffer_backing) override;
  void DestroyTransferBuffer(int32 id) override;
  scoped_refptr<Buffer> GetTransferBuffer(int32 id) override;

 private:
  ~TransferBufferManager() override;

  typedef base::hash_map<int32, scoped_refptr<Buffer> > BufferMap;
  BufferMap registered_buffers_;
  size_t shared_memory_bytes_allocated_;

  DISALLOW_COPY_AND_ASSIGN(TransferBufferManager);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_TRANSFER_BUFFER_MANAGER_H_
