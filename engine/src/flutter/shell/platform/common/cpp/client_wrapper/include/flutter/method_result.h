// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_METHOD_RESULT_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_METHOD_RESULT_H_

#include <string>

namespace flutter {

// Encapsulates a result returned from a MethodCall. Only one method should be
// called on any given instance.
template <typename T>
class MethodResult {
 public:
  MethodResult() = default;

  virtual ~MethodResult() = default;

  // Prevent copying.
  MethodResult(MethodResult const&) = delete;
  MethodResult& operator=(MethodResult const&) = delete;

  // Sends a success response, indicating that the call completed successfully.
  // An optional value can be provided as part of the success message.
  void Success(const T* result = nullptr) { SuccessInternal(result); }

  // Sends an error response, indicating that the call was understood but
  // handling failed in some way. A string error code must be provided, and in
  // addition an optional user-readable error_message and/or details object can
  // be included.
  void Error(const std::string& error_code,
             const std::string& error_message = "",
             const T* error_details = nullptr) {
    ErrorInternal(error_code, error_message, error_details);
  }

  // Sends a not-implemented response, indicating that the method either was not
  // recognized, or has not been implemented.
  void NotImplemented() { NotImplementedInternal(); }

 protected:
  // Implementation of the public interface, to be provided by subclasses.
  virtual void SuccessInternal(const T* result) = 0;

  // Implementation of the public interface, to be provided by subclasses.
  virtual void ErrorInternal(const std::string& error_code,
                             const std::string& error_message,
                             const T* error_details) = 0;

  // Implementation of the public interface, to be provided by subclasses.
  virtual void NotImplementedInternal() = 0;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_INCLUDE_FLUTTER_METHOD_RESULT_H_
