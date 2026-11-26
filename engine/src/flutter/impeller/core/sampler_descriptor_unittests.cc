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

// Every field the key holds survives a round trip through it. Each field
// takes a different value where it can, so a swapped pair is caught too.
TEST(SamplerDescriptorTest, FromKeyInvertsToKey) {
  SamplerDescriptor a;
  a.min_filter = MinMagFilter::kLinear;
  a.mag_filter = MinMagFilter::kNearest;
  a.mip_filter = MipFilter::kLinear;
  a.width_address_mode = SamplerAddressMode::kRepeat;
  a.height_address_mode = SamplerAddressMode::kMirror;
  a.depth_address_mode = SamplerAddressMode::kDecal;
  a.max_anisotropy = 16;

  const uint64_t key = SamplerDescriptor::ToKey(a);
  const SamplerDescriptor b = SamplerDescriptor::FromKey(key);
  EXPECT_EQ(b.min_filter, a.min_filter);
  EXPECT_EQ(b.mag_filter, a.mag_filter);
  EXPECT_EQ(b.mip_filter, a.mip_filter);
  EXPECT_EQ(b.width_address_mode, a.width_address_mode);
  EXPECT_EQ(b.height_address_mode, a.height_address_mode);
  EXPECT_EQ(b.depth_address_mode, a.depth_address_mode);
  EXPECT_EQ(b.max_anisotropy, a.max_anisotropy);
  EXPECT_EQ(SamplerDescriptor::ToKey(b), key);

  // The default descriptor round trips as well.
  const SamplerDescriptor c =
      SamplerDescriptor::FromKey(SamplerDescriptor::ToKey(SamplerDescriptor{}));
  EXPECT_EQ(SamplerDescriptor::ToKey(c),
            SamplerDescriptor::ToKey(SamplerDescriptor{}));
}

}  // namespace testing
}  // namespace impeller
