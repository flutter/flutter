// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "platform/fonts/GlyphBuffer.h"

#include "platform/fonts/SimpleFontData.h"
#include "wtf/PassRefPtr.h"
#include "wtf/RefPtr.h"
#include <gtest/gtest.h>

using namespace blink;

namespace {

// Minimal TestSimpleFontData implementation.
// Font has no glyphs, but that's okay.
class TestSimpleFontData : public SimpleFontData {
public:
    static PassRefPtr<TestSimpleFontData> create()
    {
        return adoptRef(new TestSimpleFontData);
    }

private:
    TestSimpleFontData() : SimpleFontData(nullptr, 10, false, false) { }

    bool fillGlyphPage(GlyphPage* pageToFill, unsigned offset, unsigned length, UChar* buffer, unsigned bufferLength) const OVERRIDE
    {
        return false;
    }
};

TEST(GlyphBufferTest, StartsEmpty)
{
    GlyphBuffer glyphBuffer;
    EXPECT_TRUE(glyphBuffer.isEmpty());
    EXPECT_EQ(0u, glyphBuffer.size());
}

TEST(GlyphBufferTest, StoresGlyphs)
{
    RefPtr<SimpleFontData> font1 = TestSimpleFontData::create();
    RefPtr<SimpleFontData> font2 = TestSimpleFontData::create();

    GlyphBuffer glyphBuffer;
    glyphBuffer.add(42, font1.get(), 10);
    glyphBuffer.add(43, font1.get(), 15);
    glyphBuffer.add(44, font2.get(), FloatSize(12, 2));

    EXPECT_FALSE(glyphBuffer.isEmpty());
    EXPECT_EQ(3u, glyphBuffer.size());

    EXPECT_EQ(42, glyphBuffer.glyphAt(0));
    EXPECT_EQ(43, glyphBuffer.glyphAt(1));
    EXPECT_EQ(44, glyphBuffer.glyphAt(2));

    const Glyph* glyphs = glyphBuffer.glyphs(0);
    EXPECT_EQ(42, glyphs[0]);
    EXPECT_EQ(43, glyphs[1]);
    EXPECT_EQ(44, glyphs[2]);
}

TEST(GlyphBufferTest, StoresAdvances)
{
    RefPtr<SimpleFontData> font1 = TestSimpleFontData::create();
    RefPtr<SimpleFontData> font2 = TestSimpleFontData::create();

    GlyphBuffer glyphBuffer;
    glyphBuffer.add(42, font1.get(), 10);
    glyphBuffer.add(43, font1.get(), 15);
    glyphBuffer.add(44, font2.get(), FloatSize(12, 2));

    EXPECT_FALSE(glyphBuffer.isEmpty());
    EXPECT_EQ(3u, glyphBuffer.size());

    EXPECT_EQ(FloatSize(10, 0), glyphBuffer.advanceAt(0));
    EXPECT_EQ(FloatSize(15, 0), glyphBuffer.advanceAt(1));
    EXPECT_EQ(FloatSize(12, 2), glyphBuffer.advanceAt(2));

    const FloatSize* advances = glyphBuffer.advances(0);
    EXPECT_EQ(FloatSize(10, 0), advances[0]);
    EXPECT_EQ(FloatSize(15, 0), advances[1]);
    EXPECT_EQ(FloatSize(12, 2), advances[2]);
}

TEST(GlyphBufferTest, StoresSimpleFontData)
{
    RefPtr<SimpleFontData> font1 = TestSimpleFontData::create();
    RefPtr<SimpleFontData> font2 = TestSimpleFontData::create();

    GlyphBuffer glyphBuffer;
    glyphBuffer.add(42, font1.get(), 10);
    glyphBuffer.add(43, font1.get(), 15);
    glyphBuffer.add(44, font2.get(), FloatSize(12, 2));

    EXPECT_FALSE(glyphBuffer.isEmpty());
    EXPECT_EQ(3u, glyphBuffer.size());

    EXPECT_EQ(font1.get(), glyphBuffer.fontDataAt(0));
    EXPECT_EQ(font1.get(), glyphBuffer.fontDataAt(1));
    EXPECT_EQ(font2.get(), glyphBuffer.fontDataAt(2));
}

TEST(GlyphBufferTest, GlyphArrayWithOffset)
{
    RefPtr<SimpleFontData> font1 = TestSimpleFontData::create();
    RefPtr<SimpleFontData> font2 = TestSimpleFontData::create();

    GlyphBuffer glyphBuffer;
    glyphBuffer.add(42, font1.get(), 10);
    glyphBuffer.add(43, font1.get(), 15);
    glyphBuffer.add(44, font2.get(), FloatSize(12, 2));

    EXPECT_FALSE(glyphBuffer.isEmpty());
    EXPECT_EQ(3u, glyphBuffer.size());

    const Glyph* glyphs = glyphBuffer.glyphs(1);
    EXPECT_EQ(43, glyphs[0]);
    EXPECT_EQ(44, glyphs[1]);
}

TEST(GlyphBufferTest, AdvanceArrayWithOffset)
{
    RefPtr<SimpleFontData> font1 = TestSimpleFontData::create();
    RefPtr<SimpleFontData> font2 = TestSimpleFontData::create();

    GlyphBuffer glyphBuffer;
    glyphBuffer.add(42, font1.get(), 10);
    glyphBuffer.add(43, font1.get(), 15);
    glyphBuffer.add(44, font2.get(), FloatSize(12, 2));

    EXPECT_FALSE(glyphBuffer.isEmpty());
    EXPECT_EQ(3u, glyphBuffer.size());

    const FloatSize* advances = glyphBuffer.advances(1);
    EXPECT_EQ(FloatSize(15, 0), advances[0]);
    EXPECT_EQ(FloatSize(12, 2), advances[1]);
}

TEST(GlyphBufferTest, Clear)
{
    RefPtr<SimpleFontData> font1 = TestSimpleFontData::create();
    RefPtr<SimpleFontData> font2 = TestSimpleFontData::create();

    GlyphBuffer glyphBuffer;
    glyphBuffer.add(42, font1.get(), 10);
    glyphBuffer.add(43, font1.get(), 15);
    glyphBuffer.add(44, font2.get(), FloatSize(12, 2));

    EXPECT_FALSE(glyphBuffer.isEmpty());
    EXPECT_EQ(3u, glyphBuffer.size());

    glyphBuffer.clear();

    EXPECT_TRUE(glyphBuffer.isEmpty());
    EXPECT_EQ(0u, glyphBuffer.size());
}

TEST(GlyphBufferTest, TracksVerticalAdvances)
{
    RefPtr<SimpleFontData> font = TestSimpleFontData::create();
    GlyphBuffer glyphBuffer;
    EXPECT_FALSE(glyphBuffer.hasVerticalAdvances());
    glyphBuffer.add(42, font.get(), 10);
    EXPECT_FALSE(glyphBuffer.hasVerticalAdvances());
    glyphBuffer.add(43, font.get(), FloatSize(15, 0));
    EXPECT_FALSE(glyphBuffer.hasVerticalAdvances());
    glyphBuffer.add(44, font.get(), FloatSize(10, 5));
    EXPECT_TRUE(glyphBuffer.hasVerticalAdvances());
    glyphBuffer.clear();
    EXPECT_FALSE(glyphBuffer.hasVerticalAdvances());
}

TEST(GlyphBufferTest, Reverse)
{
    RefPtr<SimpleFontData> font1 = TestSimpleFontData::create();
    RefPtr<SimpleFontData> font2 = TestSimpleFontData::create();

    GlyphBuffer glyphBuffer;
    glyphBuffer.add(42, font1.get(), 10);
    glyphBuffer.add(43, font1.get(), 15);
    glyphBuffer.add(44, font2.get(), FloatSize(12, 2));

    EXPECT_FALSE(glyphBuffer.isEmpty());
    EXPECT_EQ(3u, glyphBuffer.size());
    EXPECT_TRUE(glyphBuffer.hasVerticalAdvances());

    glyphBuffer.reverse();

    EXPECT_FALSE(glyphBuffer.isEmpty());
    EXPECT_EQ(3u, glyphBuffer.size());
    EXPECT_TRUE(glyphBuffer.hasVerticalAdvances());
    EXPECT_EQ(44, glyphBuffer.glyphAt(0));
    EXPECT_EQ(43, glyphBuffer.glyphAt(1));
    EXPECT_EQ(42, glyphBuffer.glyphAt(2));
    EXPECT_EQ(FloatSize(12, 2), glyphBuffer.advanceAt(0));
    EXPECT_EQ(FloatSize(15, 0), glyphBuffer.advanceAt(1));
    EXPECT_EQ(FloatSize(10, 0), glyphBuffer.advanceAt(2));
    EXPECT_EQ(font2.get(), glyphBuffer.fontDataAt(0));
    EXPECT_EQ(font1.get(), glyphBuffer.fontDataAt(1));
    EXPECT_EQ(font1.get(), glyphBuffer.fontDataAt(2));
}

TEST(GlyphBufferTest, SetAdvanceWidth)
{
    RefPtr<SimpleFontData> font1 = TestSimpleFontData::create();
    RefPtr<SimpleFontData> font2 = TestSimpleFontData::create();

    GlyphBuffer glyphBuffer;
    glyphBuffer.add(42, font1.get(), 10);
    glyphBuffer.add(43, font1.get(), 15);
    glyphBuffer.add(44, font2.get(), FloatSize(12, 2));

    glyphBuffer.setAdvanceWidth(1, 20);
    EXPECT_EQ(FloatSize(20, 0), glyphBuffer.advanceAt(1));

    glyphBuffer.setAdvanceWidth(2, 10);
    EXPECT_EQ(FloatSize(10, 2), glyphBuffer.advanceAt(2));
}

TEST(GlyphBufferTest, ExpandLastAdvance)
{
    RefPtr<SimpleFontData> font1 = TestSimpleFontData::create();
    RefPtr<SimpleFontData> font2 = TestSimpleFontData::create();

    GlyphBuffer glyphBuffer;
    glyphBuffer.add(42, font1.get(), 10);
    glyphBuffer.add(43, font1.get(), 15);
    glyphBuffer.add(44, font2.get(), FloatSize(12, 2));

    glyphBuffer.expandLastAdvance(20);
    EXPECT_EQ(FloatSize(32, 2), glyphBuffer.advanceAt(2));
}

} // namespace
