// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_EMBEDDER_SLAVE_PROCESS_DELEGATE_H_
#define MOJO_EDK_EMBEDDER_SLAVE_PROCESS_DELEGATE_H_

#include "mojo/edk/embedder/process_delegate.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace embedder {

// An interface for the slave process delegate (which lives in each slave
// process).
class MOJO_SYSTEM_IMPL_EXPORT SlaveProcessDelegate : public ProcessDelegate {
 public:
  ProcessType GetType() const override;

  // Called when contact with the master process has been lost.
  // TODO(vtl): Obviously, there needs to be a suitable embedder API for
  // connecting to the master process. What will it be? Mention that here once
  // it exists.
  virtual void OnMasterDisconnect() = 0;

 protected:
  SlaveProcessDelegate() {}
  ~SlaveProcessDelegate() override {}

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(SlaveProcessDelegate);
};

inline ProcessType SlaveProcessDelegate::GetType() const {
  return ProcessType::SLAVE;
}

}  // namespace embedder
}  // namespace mojo

#endif  // MOJO_EDK_EMBEDDER_SLAVE_PROCESS_DELEGATE_H_
