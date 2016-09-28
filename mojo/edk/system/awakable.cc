// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/awakable.h"

#include "base/logging.h"

namespace mojo {
namespace system {

// static
MojoResult Awakable::MojoResultForAwakeReason(AwakeReason reason) {
  switch (reason) {
    case AwakeReason::CANCELLED:
      return MOJO_RESULT_CANCELLED;
    case AwakeReason::SATISFIED:
      return MOJO_RESULT_OK;
    case AwakeReason::UNSATISFIABLE:
      return MOJO_RESULT_FAILED_PRECONDITION;
    case AwakeReason::INITIALIZE:
      break;
    case AwakeReason::CHANGED:
      break;
  }
  NOTREACHED();
  return MOJO_RESULT_INTERNAL;
}

}  // namespace system
}  // namespace mojo
