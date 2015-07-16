// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_VALIDATION_ERRORS_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_VALIDATION_ERRORS_H_

#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace internal {

enum ValidationError {
  // There is no validation error.
  VALIDATION_ERROR_NONE,
  // An object (struct or array) is not 8-byte aligned.
  VALIDATION_ERROR_MISALIGNED_OBJECT,
  // An object is not contained inside the message data, or it overlaps other
  // objects.
  VALIDATION_ERROR_ILLEGAL_MEMORY_RANGE,
  // A struct header doesn't make sense, for example:
  // - |num_bytes| is smaller than the size of the struct header.
  // - |num_bytes| and |version| don't match.
  // TODO(yzshen): Consider splitting it into two different error codes. Because
  // the former indicates someone is misbehaving badly whereas the latter could
  // be due to an inappropriately-modified .mojom file.
  VALIDATION_ERROR_UNEXPECTED_STRUCT_HEADER,
  // An array header doesn't make sense, for example:
  // - |num_bytes| is smaller than the size of the header plus the size required
  // to store |num_elements| elements.
  // - For fixed-size arrays, |num_elements| is different than the specified
  // size.
  VALIDATION_ERROR_UNEXPECTED_ARRAY_HEADER,
  // An encoded handle is illegal.
  VALIDATION_ERROR_ILLEGAL_HANDLE,
  // A non-nullable handle field is set to invalid handle.
  VALIDATION_ERROR_UNEXPECTED_INVALID_HANDLE,
  // An encoded pointer is illegal.
  VALIDATION_ERROR_ILLEGAL_POINTER,
  // A non-nullable pointer field is set to null.
  VALIDATION_ERROR_UNEXPECTED_NULL_POINTER,
  // |flags| in the message header is invalid. The flags are either
  // inconsistent with one another, inconsistent with other parts of the
  // message, or unexpected for the message receiver.  For example the
  // receiver is expecting a request message but the flags indicate that
  // the message is a response message.
  VALIDATION_ERROR_MESSAGE_HEADER_INVALID_FLAGS,
  // |flags| in the message header indicates that a request ID is required but
  // there isn't one.
  VALIDATION_ERROR_MESSAGE_HEADER_MISSING_REQUEST_ID,
  // The |name| field in a message header contains an unexpected value.
  VALIDATION_ERROR_MESSAGE_HEADER_UNKNOWN_METHOD,
  // Two parallel arrays which are supposed to represent a map have different
  // lengths.
  VALIDATION_ERROR_DIFFERENT_SIZED_ARRAYS_IN_MAP,
  // Attempted to deserialize a tagged union with an unknown tag.
  VALIDATION_ERROR_UNKNOWN_UNION_TAG
};

const char* ValidationErrorToString(ValidationError error);

void ReportValidationError(ValidationError error,
                           const char* description = nullptr);

// Only used by validation tests and when there is only one thread doing message
// validation.
class ValidationErrorObserverForTesting {
 public:
  ValidationErrorObserverForTesting();
  ~ValidationErrorObserverForTesting();

  ValidationError last_error() const { return last_error_; }
  void set_last_error(ValidationError error) { last_error_ = error; }

 private:
  ValidationError last_error_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ValidationErrorObserverForTesting);
};

// Used only by MOJO_INTERNAL_DLOG_SERIALIZATION_WARNING. Don't use it directly.
//
// The function returns true if the error is recorded (by a
// SerializationWarningObserverForTesting object), false otherwise.
bool ReportSerializationWarning(ValidationError error);

// Only used by serialization tests and when there is only one thread doing
// message serialization.
class SerializationWarningObserverForTesting {
 public:
  SerializationWarningObserverForTesting();
  ~SerializationWarningObserverForTesting();

  ValidationError last_warning() const { return last_warning_; }
  void set_last_warning(ValidationError error) { last_warning_ = error; }

 private:
  ValidationError last_warning_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(SerializationWarningObserverForTesting);
};

}  // namespace internal
}  // namespace mojo

// In debug build, logs a serialization warning if |condition| evaluates to
// true:
//   - if there is a SerializationWarningObserverForTesting object alive,
//     records |error| in it;
//   - otherwise, logs a fatal-level message.
// |error| is the validation error that will be triggered by the receiver
// of the serialzation result.
//
// In non-debug build, does nothing (not even compiling |condition|).
#define MOJO_INTERNAL_DLOG_SERIALIZATION_WARNING(                        \
    condition, error, description)                                       \
  MOJO_DLOG_IF(FATAL, (condition) && !ReportSerializationWarning(error)) \
      << "The outgoing message will trigger "                            \
      << ValidationErrorToString(error) << " at the receiving side ("    \
      << description << ").";

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_VALIDATION_ERRORS_H_
