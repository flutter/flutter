// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/unique_identifier.h"

#include "mojo/edk/embedder/platform_support.h"

namespace mojo {
namespace system {

namespace {

bool CapitalizedHexDigitToNumber(char c, unsigned char* number) {
  if (c >= '0' && c <= '9')
    *number = static_cast<unsigned char>(c - '0');
  else if (c >= 'A' && c <= 'F')
    *number = static_cast<unsigned char>(c - 'A' + 10);
  else
    return false;
  return true;
}

}  // namespace

// static
UniqueIdentifier UniqueIdentifier::Generate(
    embedder::PlatformSupport* platform_support) {
  UniqueIdentifier rv;
  platform_support->GetCryptoRandomBytes(rv.data_, sizeof(rv.data_));
  return rv;
}

// static
UniqueIdentifier UniqueIdentifier::FromString(const std::string& s,
                                              bool* success) {
  if (s.size() != 2 * sizeof(UniqueIdentifier::data_)) {
    *success = false;
    return UniqueIdentifier();
  }

  UniqueIdentifier rv;
  for (size_t i = 0; i < sizeof(rv.data_); i++) {
    unsigned char high_digit;
    unsigned char low_digit;
    // Note: |ToString()| always produces capitalized hex digits, so we should
    // never get 'a' through 'f'.
    if (!CapitalizedHexDigitToNumber(s[2 * i], &high_digit) ||
        !CapitalizedHexDigitToNumber(s[2 * i + 1], &low_digit)) {
      *success = false;
      return UniqueIdentifier();
    }
    rv.data_[i] = (high_digit << 4) | low_digit;
  }

  *success = true;
  return rv;
}

std::string UniqueIdentifier::ToString() const {
  // Currently, we encode as hexadecimal (using capitalized digits).
  // TODO(vtl): Maybe we should base-64 encode instead?
  static const char kHexDigits[] = "0123456789ABCDEF";
  std::string rv(sizeof(data_) * 2, '\0');
  for (size_t i = 0; i < sizeof(data_); i++) {
    rv[2 * i] = kHexDigits[data_[i] >> 4];
    rv[2 * i + 1] = kHexDigits[data_[i] & 0xf];
  }
  return rv;
}

}  // namespace system
}  // namespace mojo
