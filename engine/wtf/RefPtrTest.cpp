// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "wtf/RefPtr.h"

#include "wtf/text/StringImpl.h"
#include <gtest/gtest.h>

namespace {

TEST(RefPtrTest, Basic)
{
    RefPtr<StringImpl> string;
    EXPECT_TRUE(!string);
    string = StringImpl::create("test");
    EXPECT_TRUE(!!string);
    string.clear();
    EXPECT_TRUE(!string);
}

#if COMPILER_SUPPORTS(CXX_RVALUE_REFERENCES)
TEST(RefPtrTest, MoveAssignmentOperator)
{
    RefPtr<StringImpl> a = StringImpl::create("a");
    RefPtr<StringImpl> b = StringImpl::create("b");
    // FIXME: Instead of explicitly casting to RefPtr<StringImpl>&& here, we should use std::move, but that
    // requires us to have a standard library that supports move semantics.
    b = static_cast<RefPtr<StringImpl>&&>(a);
    EXPECT_TRUE(!!b);
    EXPECT_TRUE(!a);
}
#endif

}
