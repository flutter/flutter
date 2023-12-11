// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstdint>
#include <optional>
#include <tuple>

namespace flutter {

using ProductVersion =
    std::tuple<int32_t /* major */, int32_t /* minor */, int32_t /* patch */>;

std::optional<ProductVersion> ProductVersionFromSystemVersionPList();

bool IsEncodedVersionLessThanOrSame(uint32_t encoded_lhs, ProductVersion rhs);

}  // namespace flutter
