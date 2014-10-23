/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/graphics/filters/FilterOperations.h"

#include <gtest/gtest.h>

using namespace blink;

namespace {

TEST(FilterOperationsTest, getOutsetsBlur)
{
    FilterOperations ops;
    ops.operations().append(BlurFilterOperation::create(Length(20.0, Fixed)));
    EXPECT_TRUE(ops.hasOutsets());
    FilterOutsets outsets = ops.outsets();
    EXPECT_EQ(57, outsets.top());
    EXPECT_EQ(57, outsets.right());
    EXPECT_EQ(57, outsets.bottom());
    EXPECT_EQ(57, outsets.left());
}

TEST(FilterOperationsTest, getOutsetsDropShadow)
{
    FilterOperations ops;
    ops.operations().append(DropShadowFilterOperation::create(IntPoint(3, 8), 20, Color(1, 2, 3)));
    EXPECT_TRUE(ops.hasOutsets());
    FilterOutsets outsets = ops.outsets();
    EXPECT_EQ(49, outsets.top());
    EXPECT_EQ(60, outsets.right());
    EXPECT_EQ(65, outsets.bottom());
    EXPECT_EQ(54, outsets.left());
}

}

