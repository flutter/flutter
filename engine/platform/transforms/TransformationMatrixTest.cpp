// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "platform/transforms/TransformationMatrix.h"

#include <gtest/gtest.h>

using namespace blink;
namespace {

TEST(TransformationMatrixTest, NonInvertableBlendTest)
{
    TransformationMatrix from;
    TransformationMatrix to(2.7133590938, 0.0, 0.0, 0.0, 0.0, 2.4645137761, 0.0, 0.0, 0.0, 0.0, 0.00, 0.01, 0.02, 0.03, 0.04, 0.05);
    TransformationMatrix result;

    result = to;
    result.blend(from, 0.25);
    EXPECT_TRUE(result == from);

    result = to;
    result.blend(from, 0.75);
    EXPECT_TRUE(result == to);
}

} // namespace
