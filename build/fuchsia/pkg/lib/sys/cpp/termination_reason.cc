// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "lib/sys/cpp/termination_reason.h"

#include <sstream>
#include <string>

namespace sys {

std::string TerminationReasonToString(
    fuchsia::sys::TerminationReason termination_reason) {
  switch (termination_reason) {
    case fuchsia::sys::TerminationReason::UNKNOWN:
      return "UNKNOWN";
    case fuchsia::sys::TerminationReason::EXITED:
      return "EXITED";
    case fuchsia::sys::TerminationReason::URL_INVALID:
      return "URL_INVALID";
    case fuchsia::sys::TerminationReason::PACKAGE_NOT_FOUND:
      return "PACKAGE_NOT_FOUND";
    case fuchsia::sys::TerminationReason::INTERNAL_ERROR:
      return "INTERNAL_ERROR";
    case fuchsia::sys::TerminationReason::PROCESS_CREATION_ERROR:
      return "PROCESS_CREATION_ERROR";
    case fuchsia::sys::TerminationReason::RUNNER_FAILED:
      return "RUNNER_FAILED";
    case fuchsia::sys::TerminationReason::RUNNER_TERMINATED:
      return "RUNNER_TERMINATED";
    default:
      return std::to_string(static_cast<int>(termination_reason));
  }
}

std::string HumanReadableTerminationReason(
    fuchsia::sys::TerminationReason termination_reason) {
  switch (termination_reason) {
    case fuchsia::sys::TerminationReason::EXITED:
      return "exited";
    case fuchsia::sys::TerminationReason::URL_INVALID:
      return "url invalid";
    case fuchsia::sys::TerminationReason::PACKAGE_NOT_FOUND:
      return "not found";
    case fuchsia::sys::TerminationReason::PROCESS_CREATION_ERROR:
      return "failed to spawn process";
    case fuchsia::sys::TerminationReason::RUNNER_FAILED:
      return "failed to start runner for process";
    case fuchsia::sys::TerminationReason::RUNNER_TERMINATED:
      return "runner failed to execute";
    default:
      std::ostringstream out;
      out << "failed to create component ("
          << TerminationReasonToString(termination_reason) << ")";
      return out.str();
  }
}

}  // namespace sys
