// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/unique_identifier.h"

#include <stdint.h>

#include <vector>

#include "base/strings/string_number_conversions.h"
#include "mojo/edk/embedder/platform_support.h"

namespace mojo {
namespace system {

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
  UniqueIdentifier rv;
  std::vector<uint8_t> bytes;
  if (base::HexStringToBytes(s, &bytes) && bytes.size() == sizeof(rv.data_)) {
    memcpy(rv.data_, &bytes[0], sizeof(rv.data_));
    *success = true;
  } else {
    *success = false;
  }
  return rv;
}

std::string UniqueIdentifier::ToString() const {
  // TODO(vtl): Maybe we should base-64 encode instead?
  return base::HexEncode(data_, sizeof(data_));
}

}  // namespace system
}  // namespace mojo
