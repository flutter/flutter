// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/core/sampler_descriptor.h"

namespace impeller {
namespace testing {

TEST(SamplerDescriptorTest, ToKeyIncludesAllFields) {
  SamplerDescriptor a;
  SamplerDescriptor b;
  EXPECT_EQ(SamplerDescriptor::ToKey(a), SamplerDescriptor::ToKey(b));

  b.min_filter = MinMagFilter::kLinear;
  EXPECT_NE(SamplerDescriptor::ToKey(a), SamplerDescriptor::ToKey(b));
  b = SamplerDescriptor{};

  b.mag_filter = MinMagFilter::kLinear;
  EXPECT_NE(SamplerDescriptor::ToKey(a), SamplerDescriptor::ToKey(b));
  b = SamplerDescriptor{};

  b.mip_filter = MipFilter::kLinear;
  EXPECT_NE(SamplerDescriptor::ToKey(a), SamplerDescriptor::ToKey(b));
  b = SamplerDescriptor{};

  b.width_address_mode = SamplerAddressMode::kRepeat;
  EXPECT_NE(SamplerDescriptor::ToKey(a), SamplerDescriptor::ToKey(b));
  b = SamplerDescriptor{};

  b.height_address_mode = SamplerAddressMode::kRepeat;
  EXPECT_NE(SamplerDescriptor::ToKey(a), SamplerDescriptor::ToKey(b));
  b = SamplerDescriptor{};

  b.depth_address_mode = SamplerAddressMode::kRepeat;
  EXPECT_NE(SamplerDescriptor::ToKey(a), SamplerDescriptor::ToKey(b));
  b = SamplerDescriptor{};

  b.max_anisotropy = 16;
  EXPECT_NE(SamplerDescriptor::ToKey(a), SamplerDescriptor::ToKey(b));
  b.max_anisotropy = 1;
  EXPECT_EQ(SamplerDescriptor::ToKey(a), SamplerDescriptor::ToKey(b));
}

}  // namespace testing
}  // namespace impeller
