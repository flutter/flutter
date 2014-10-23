/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "platform/geometry/FloatBoxTestHelpers.h"

#include "platform/geometry/FloatBox.h"
const static float kTestEpsilon = 1e-6;

void blink::PrintTo(const FloatBox& box, ::std::ostream* os)
{
    *os << "FloatBox("
        << box.x() << ", "
        << box.y() << ", "
        << box.z() << ", "
        << box.width() << ", "
        << box.height() << ", "
        << box.depth() << ")";
}

bool blink::FloatBoxTest::ApproximatelyEqual(const float& a, const float& b)
{
    float absA = ::fabs(a);
    float absB = ::fabs(b);
    float absErr = ::fabs(a - b);
    if (a == b)
        return true;

    if (a == 0 || b == 0 || absErr < std::numeric_limits<float>::min())
        return absErr < (kTestEpsilon * std::numeric_limits<float>::min());

    return ((absErr / (absA + absB)) < kTestEpsilon);
}

bool blink::FloatBoxTest::ApproximatelyEqual(const FloatBox& a, const FloatBox& b)
{
    if (!ApproximatelyEqual(a.x(), b.x())
        || !ApproximatelyEqual(a.y(), b.y())
        || !ApproximatelyEqual(a.z(), b.z())
        || !ApproximatelyEqual(a.width(), b.width())
        || !ApproximatelyEqual(a.height(), b.height())
        || !ApproximatelyEqual(a.depth(), b.depth())) {
        return false;
    }
    return true;
}

::testing::AssertionResult blink::FloatBoxTest::AssertAlmostEqual(const char* m_expr, const char* n_expr, const FloatBox& m, const FloatBox& n)
{
    if (!ApproximatelyEqual(m, n)) {
        return ::testing::AssertionFailure() << "       Value of:" << n_expr << std::endl
            << "         Actual:" << testing::PrintToString(n) << std::endl
            << "Expected Approx:" << m_expr << std::endl
            << "       Which is:" << ::testing::PrintToString(m);
    }
    return ::testing::AssertionSuccess();
}

::testing::AssertionResult blink::FloatBoxTest::AssertContains(const char* m_expr, const char* n_expr, const FloatBox& m, const FloatBox& n)
{
    FloatBox newM = m;
    newM.expandTo(n);
    if (!ApproximatelyEqual(m, newM)) {
        return ::testing::AssertionFailure() << "        Value of:" << n_expr << std::endl
            << "          Actual:" << testing::PrintToString(n) << std::endl
            << "Not Contained in:" << m_expr << std::endl
            << "        Which is:" << ::testing::PrintToString(m);
    }
    return ::testing::AssertionSuccess();
}


