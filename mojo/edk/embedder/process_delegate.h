// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_EMBEDDER_PROCESS_DELEGATE_H_
#define MOJO_EDK_EMBEDDER_PROCESS_DELEGATE_H_

#include "mojo/edk/embedder/process_type.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace embedder {

// An interface for process delegates.
class MOJO_SYSTEM_IMPL_EXPORT ProcessDelegate {
 public:
  virtual ProcessType GetType() const;

  // Called when |ShutdownIPCSupport()| has "completed". Note that this is NOT
  // called if |ShutdownIPCSupportOnIOThread()| is used instead.
  virtual void OnShutdownComplete() = 0;

 protected:
  ProcessDelegate() {}
  virtual ~ProcessDelegate() {}

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(ProcessDelegate);
};

inline ProcessType ProcessDelegate::GetType() const {
  return ProcessType::NONE;
}

}  // namespace embedder
}  // namespace mojo

#endif  // MOJO_EDK_EMBEDDER_PROCESS_DELEGATE_H_
