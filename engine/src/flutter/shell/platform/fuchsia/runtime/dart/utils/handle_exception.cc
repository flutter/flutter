// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "runtime/dart/utils/handle_exception.h"

#include <fuchsia/crash/cpp/fidl.h>
#include <fuchsia/mem/cpp/fidl.h>
#include <lib/syslog/global.h>
#include <lib/zx/vmo.h>
#include <sys/types.h>
#include <third_party/tonic/converter/dart_converter.h>
#include <zircon/status.h>

#include <string>

#include "runtime/dart/utils/logging.h"

namespace {
static bool FillBuffer(const std::string& data, fuchsia::mem::Buffer* buffer) {
  uint64_t num_bytes = data.size();
  zx::vmo vmo;

  if (zx::vmo::create(num_bytes, 0u, &vmo) < 0) {
    return false;
  }

  if (num_bytes > 0) {
    if (vmo.write(data.data(), 0, num_bytes) < 0) {
      return false;
    }
  }

  buffer->vmo = std::move(vmo);
  buffer->size = num_bytes;

  return true;
}

template <typename T, size_t N>
void CopyToArray(const std::string& s, std::array<T, N>* arr) {
  const size_t max_size = arr->size();
  auto end = s.end();
  if (s.size() > max_size) {
    FX_LOGF(WARNING, LOG_TAG, "truncating '%s' to %d characters", s.c_str(),
            max_size);
    end = s.begin() + max_size;
  }
  std::copy(s.begin(), end, arr->data());
}

fuchsia::crash::ManagedRuntimeException BuildException(
    const std::string& error,
    const std::string& stack_trace) {
  // The runtime type has already been pre-pended to the error message so we
  // expect the format to be '$RuntimeType: $Message'.
  std::string error_type;
  std::string error_message;
  const size_t delimiter_pos = error.find_first_of(':');
  if (delimiter_pos == std::string::npos) {
    FX_LOGF(ERROR, LOG_TAG,
            "error parsing Dart exception: expected format '$RuntimeType: "
            "$Message', got '%s'",
            error.c_str());
    // We still need to specify a type, otherwise the stack trace does not
    // show up in the crash server UI.
    error_type = "UnknownError";
    error_message = error;
  } else {
    error_type = error.substr(0, delimiter_pos);
    error_message =
        error.substr(delimiter_pos + 2 /*to get rid of the leading ': '*/);
  }

  // Default-initialize to initialize the underlying arrays of characters with
  // 0s and null-terminate the strings.
  fuchsia::crash::GenericException exception = {};
  CopyToArray(error_type, &exception.type);
  CopyToArray(error_message, &exception.message);
  if (!FillBuffer(stack_trace, &exception.stack_trace)) {
    FX_LOG(ERROR, LOG_TAG, "Failed to convert Dart stack trace to VMO");
  }

  fuchsia::crash::ManagedRuntimeException dart_exception;
  dart_exception.set_dart(std::move(exception));
  return dart_exception;
}

}  // namespace

namespace dart_utils {

void HandleIfException(std::shared_ptr<::sys::ServiceDirectory> services,
                       const std::string& component_url,
                       Dart_Handle result) {
  if (!Dart_IsError(result) || !Dart_ErrorHasException(result)) {
    return;
  }

  const std::string error =
      tonic::StdStringFromDart(Dart_ToString(Dart_ErrorGetException(result)));
  const std::string stack_trace =
      tonic::StdStringFromDart(Dart_ToString(Dart_ErrorGetStackTrace(result)));

  return HandleException(services, component_url, error, stack_trace);
}

void HandleException(std::shared_ptr<::sys::ServiceDirectory> services,
                     const std::string& component_url,
                     const std::string& error,
                     const std::string& stack_trace) {
  fuchsia::crash::ManagedRuntimeException exception =
      BuildException(error, stack_trace);

  fuchsia::crash::AnalyzerPtr analyzer =
      services->Connect<fuchsia::crash::Analyzer>();
#ifndef NDEBUG
  if (!analyzer) {
    FX_LOG(FATAL, LOG_TAG, "Could not connect to analyzer service");
  }
#endif

  analyzer->OnManagedRuntimeException(
      component_url, std::move(exception),
      [](fuchsia::crash::Analyzer_OnManagedRuntimeException_Result result) {
        if (result.is_err()) {
          FX_LOGF(ERROR, LOG_TAG, "Failed to handle Dart exception: %d (%s)",
                  result.err(), zx_status_get_string(result.err()));
        }
      });
}

}  // namespace dart_utils
