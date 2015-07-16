// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A streaming validator for UTF-8. Validation is based on the definition in
// RFC-3629. In particular, it does not reject the invalid characters rejected
// by base::IsStringUTF8().
//
// The implementation detects errors on the first possible byte.

#ifndef BASE_I18N_STREAMING_UTF8_VALIDATOR_H_
#define BASE_I18N_STREAMING_UTF8_VALIDATOR_H_

#include <string>

#include "base/basictypes.h"
#include "base/i18n/base_i18n_export.h"

namespace base {

class BASE_I18N_EXPORT StreamingUtf8Validator {
 public:
  // The validator exposes 3 states. It starts in state VALID_ENDPOINT. As it
  // processes characters it alternates between VALID_ENDPOINT and
  // VALID_MIDPOINT. If it encounters an invalid byte or UTF-8 sequence the
  // state changes permanently to INVALID.
  enum State {
    VALID_ENDPOINT,
    VALID_MIDPOINT,
    INVALID
  };

  StreamingUtf8Validator() : state_(0u) {}
  // Trivial destructor intentionally omitted.

  // Validate |size| bytes starting at |data|. If the concatenation of all calls
  // to AddBytes() since this object was constructed or reset is a valid UTF-8
  // string, returns VALID_ENDPOINT. If it could be the prefix of a valid UTF-8
  // string, returns VALID_MIDPOINT. If an invalid byte or UTF-8 sequence was
  // present, returns INVALID.
  State AddBytes(const char* data, size_t size);

  // Return the object to a freshly-constructed state so that it can be re-used.
  void Reset();

  // Validate a complete string using the same criteria. Returns true if the
  // string only contains complete, valid UTF-8 codepoints.
  static bool Validate(const std::string& string);

 private:
  // The current state of the validator. Value 0 is the initial/valid state.
  // The state is stored as an offset into |kUtf8ValidatorTables|. The special
  // state |kUtf8InvalidState| is invalid.
  uint8 state_;

  // This type could be made copyable but there is currently no use-case for
  // it.
  DISALLOW_COPY_AND_ASSIGN(StreamingUtf8Validator);
};

}  // namespace base

#endif  // BASE_I18N_STREAMING_UTF8_VALIDATOR_H_
