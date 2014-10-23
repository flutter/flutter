/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/rendering/RenderOverflow.h"

#include "platform/geometry/LayoutRect.h"

#include <gtest/gtest.h>

using namespace blink;

namespace blink {

// FIXME: Move this somewhere more generic.
void PrintTo(const LayoutRect& rect, std::ostream* os)
{
    *os << "LayoutRect("
        << rect.x().toFloat() << ", "
        << rect.y().toFloat() << ", "
        << rect.width().toFloat() << ", "
        << rect.height().toFloat() << ")";
}

} // namespace blink

namespace {

LayoutRect initialLayoutOverflow()
{
    return LayoutRect(10, 10, 80, 80);
}

LayoutRect initialVisualOverflow()
{
    return LayoutRect(0, 0, 100, 100);
}

class RenderOverflowTest : public testing::Test {
protected:
    RenderOverflowTest() : m_overflow(initialLayoutOverflow(), initialVisualOverflow()) { }
    RenderOverflow m_overflow;
};

TEST_F(RenderOverflowTest, InitialOverflowRects)
{
    EXPECT_EQ(initialLayoutOverflow(), m_overflow.layoutOverflowRect());
    EXPECT_EQ(initialVisualOverflow(), m_overflow.visualOverflowRect());
    EXPECT_TRUE(m_overflow.contentsVisualOverflowRect().isEmpty());
}

TEST_F(RenderOverflowTest, AddLayoutOverflowOutsideExpandsRect)
{
    m_overflow.addLayoutOverflow(LayoutRect(0, 10, 30, 10));
    EXPECT_EQ(LayoutRect(0, 10, 90, 80), m_overflow.layoutOverflowRect());
}

TEST_F(RenderOverflowTest, AddLayoutOverflowInsideDoesNotAffectRect)
{
    m_overflow.addLayoutOverflow(LayoutRect(50, 50, 10, 20));
    EXPECT_EQ(initialLayoutOverflow(), m_overflow.layoutOverflowRect());
}

TEST_F(RenderOverflowTest, AddLayoutOverflowEmpty)
{
    // This test documents the existing behavior so that we are aware when/if
    // it changes. It would also be reasonable for addLayoutOverflow to be
    // a no-op in this situation.
    m_overflow.addLayoutOverflow(LayoutRect(200, 200, 0, 0));
    EXPECT_EQ(LayoutRect(10, 10, 190, 190), m_overflow.layoutOverflowRect());
}

TEST_F(RenderOverflowTest, AddLayoutOverflowDoesNotAffectVisualOverflow)
{
    m_overflow.addLayoutOverflow(LayoutRect(300, 300, 300, 300));
    EXPECT_EQ(initialVisualOverflow(), m_overflow.visualOverflowRect());
}

TEST_F(RenderOverflowTest, AddLayoutOverflowDoesNotAffectContentsVisualOverflow)
{
    m_overflow.addLayoutOverflow(LayoutRect(300, 300, 300, 300));
    EXPECT_TRUE(m_overflow.contentsVisualOverflowRect().isEmpty());
}

TEST_F(RenderOverflowTest, AddVisualOverflowOutsideExpandsRect)
{
    m_overflow.addVisualOverflow(LayoutRect(150, -50, 10, 10));
    EXPECT_EQ(LayoutRect(0, -50, 160, 150), m_overflow.visualOverflowRect());
}

TEST_F(RenderOverflowTest, AddVisualOverflowInsideDoesNotAffectRect)
{
    m_overflow.addVisualOverflow(LayoutRect(0, 10, 90, 90));
    EXPECT_EQ(initialVisualOverflow(), m_overflow.visualOverflowRect());
}

TEST_F(RenderOverflowTest, AddVisualOverflowEmpty)
{
    // This test documents the existing behavior so that we are aware when/if
    // it changes. It would also be reasonable for addVisualOverflow to be
    // a no-op in this situation.
    m_overflow.addVisualOverflow(LayoutRect(200, 200, 0, 0));
    EXPECT_EQ(LayoutRect(0, 0, 200, 200), m_overflow.visualOverflowRect());
}

TEST_F(RenderOverflowTest, AddVisualOverflowDoesNotAffectLayoutOverflow)
{
    m_overflow.addVisualOverflow(LayoutRect(300, 300, 300, 300));
    EXPECT_EQ(initialLayoutOverflow(), m_overflow.layoutOverflowRect());
}

TEST_F(RenderOverflowTest, AddVisualOverflowDoesNotAffectContentsVisualOverflow)
{
    m_overflow.addVisualOverflow(LayoutRect(300, 300, 300, 300));
    EXPECT_TRUE(m_overflow.contentsVisualOverflowRect().isEmpty());
}

TEST_F(RenderOverflowTest, AddContentsVisualOverflowFirstCall)
{
    m_overflow.addContentsVisualOverflow(LayoutRect(0, 0, 10, 10));
    EXPECT_EQ(LayoutRect(0, 0, 10, 10), m_overflow.contentsVisualOverflowRect());
}

TEST_F(RenderOverflowTest, AddContentsVisualOverflowUnitesRects)
{
    m_overflow.addContentsVisualOverflow(LayoutRect(0, 0, 10, 10));
    m_overflow.addContentsVisualOverflow(LayoutRect(80, 80, 10, 10));
    EXPECT_EQ(LayoutRect(0, 0, 90, 90), m_overflow.contentsVisualOverflowRect());
}

TEST_F(RenderOverflowTest, AddContentsVisualOverflowRectWithinRect)
{
    m_overflow.addContentsVisualOverflow(LayoutRect(0, 0, 10, 10));
    m_overflow.addContentsVisualOverflow(LayoutRect(2, 2, 5, 5));
    EXPECT_EQ(LayoutRect(0, 0, 10, 10), m_overflow.contentsVisualOverflowRect());
}

TEST_F(RenderOverflowTest, AddContentsVisualOverflowEmpty)
{
    // This test documents the existing behavior so that we are aware when/if
    // it changes. It would also be reasonable for addContentsVisualOverflow to
    // expand in this situation.
    m_overflow.addContentsVisualOverflow(LayoutRect(0, 0, 10, 10));
    m_overflow.addContentsVisualOverflow(LayoutRect(20, 20, 0, 0));
    EXPECT_EQ(LayoutRect(0, 0, 10, 10), m_overflow.contentsVisualOverflowRect());
}

TEST_F(RenderOverflowTest, MoveAffectsLayoutOverflow)
{
    m_overflow.move(500, 100);
    EXPECT_EQ(LayoutRect(510, 110, 80, 80), m_overflow.layoutOverflowRect());
}

TEST_F(RenderOverflowTest, MoveAffectsVisualOverflow)
{
    m_overflow.move(500, 100);
    EXPECT_EQ(LayoutRect(500, 100, 100, 100), m_overflow.visualOverflowRect());
}

TEST_F(RenderOverflowTest, MoveAffectsContentsVisualOverflow)
{
    m_overflow.addContentsVisualOverflow(LayoutRect(0, 0, 10, 10));
    m_overflow.move(500, 100);
    EXPECT_EQ(LayoutRect(500, 100, 10, 10), m_overflow.contentsVisualOverflowRect());
}

} // namespace
