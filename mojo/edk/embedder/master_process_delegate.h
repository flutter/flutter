// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_EMBEDDER_MASTER_PROCESS_DELEGATE_H_
#define MOJO_EDK_EMBEDDER_MASTER_PROCESS_DELEGATE_H_

#include "mojo/edk/embedder/process_delegate.h"
#include "mojo/edk/embedder/slave_info.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace embedder {

// An interface for the master process delegate (which lives in the master
// process).
class MOJO_SYSTEM_IMPL_EXPORT MasterProcessDelegate : public ProcessDelegate {
 public:
  ProcessType GetType() const override;

  // Called when contact with the slave process specified by |slave_info| has
  // been lost.
  // TODO(vtl): Obviously, there needs to be a suitable embedder API for
  // connecting to a process. What will it be? Mention that here once it exists.
  virtual void OnSlaveDisconnect(SlaveInfo slave_info) = 0;

 protected:
  MasterProcessDelegate() {}
  ~MasterProcessDelegate() override {}

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(MasterProcessDelegate);
};

inline ProcessType MasterProcessDelegate::GetType() const {
  return ProcessType::MASTER;
}

}  // namespace embedder
}  // namespace mojo

#endif  // MOJO_EDK_EMBEDDER_MASTER_PROCESS_DELEGATE_H_
