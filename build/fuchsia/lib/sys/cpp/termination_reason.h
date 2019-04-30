// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(FIDL-549): Delete this class.

#ifndef LIB_SYS_CPP_TERMINATION_REASON_H_
#define LIB_SYS_CPP_TERMINATION_REASON_H_

#include <fuchsia/sys/cpp/fidl.h>
#include <string>

namespace sys {

std::string TerminationReasonToString(
    fuchsia::sys::TerminationReason termination_reason);

std::string HumanReadableTerminationReason(
    fuchsia::sys::TerminationReason termination_reason);

}  // namespace sys

#endif  // LIB_SYS_CPP_TERMINATION_REASON_H_
