/*
 * Copyright (C) 2013 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef MINIKIN_FONT_FAMILY_H
#define MINIKIN_FONT_FAMILY_H

#include <vector>
#include <string>
#include <hb.h>

#include <utils/TypeHelpers.h>

#include <minikin/MinikinRefCounted.h>
#include <minikin/SparseBitSet.h>

namespace android {

class MinikinFont;

// FontLanguage is a compact representation of a bcp-47 language tag. It
// does not capture all possible information, only what directly affects
// font rendering.
class FontLanguage {
    friend class FontStyle;
public:
    FontLanguage() : mBits(0) { }

    // Parse from string
    FontLanguage(const char* buf, size_t size);

    bool operator==(const FontLanguage other) const {
        return mBits != kUnsupportedLanguage && mBits == other.mBits;
    }
    operator bool() const { return mBits != 0; }

    std::string getString() const;

    // 0 = no match, 1 = language matches, 2 = language and script match
    int match(const FontLanguage other) const;

private:
    explicit FontLanguage(uint32_t bits) : mBits(bits) { }

    uint32_t bits() const { return mBits; }

    static const uint32_t kUnsupportedLanguage = 0xFFFFFFFFu;
    static const uint32_t kBaseLangMask = 0xFFFFFFu;
    static const uint32_t kScriptMask = (1u << 26) - (1u << 24);
    static const uint32_t kHansFlag = 1u << 24;
    static const uint32_t kHantFlag = 1u << 25;
    uint32_t mBits;
};

// FontStyle represents all style information needed to select an actual font
// from a collection. The implementation is packed into a single 32-bit word
// so it can be efficiently copied, embedded in other objects, etc.
class FontStyle {
public:
    FontStyle(int weight = 4, bool italic = false) {
        bits = (weight & kWeightMask) | (italic ? kItalicMask : 0);
    }
    FontStyle(FontLanguage lang, int variant = 0, int weight = 4, bool italic = false) {
        bits = (weight & kWeightMask) | (italic ? kItalicMask : 0)
                | (variant << kVariantShift) | (lang.bits() << kLangShift);
    }
    int getWeight() const { return bits & kWeightMask; }
    bool getItalic() const { return (bits & kItalicMask) != 0; }
    int getVariant() const { return (bits >> kVariantShift) & kVariantMask; }
    FontLanguage getLanguage() const { return FontLanguage(bits >> kLangShift); }

    bool operator==(const FontStyle other) const { return bits == other.bits; }

    hash_t hash() const { return bits; }
private:
    static const uint32_t kWeightMask = (1 << 4) - 1;
    static const uint32_t kItalicMask = 1 << 4;
    static const int kVariantShift = 5;
    static const uint32_t kVariantMask = (1 << 2) - 1;
    static const int kLangShift = 7;
    uint32_t bits;
};

enum FontVariant {
    VARIANT_DEFAULT = 0,
    VARIANT_COMPACT = 1,
    VARIANT_ELEGANT = 2,
};

inline hash_t hash_type(const FontStyle &style) {
    return style.hash();
}

// attributes representing transforms (fake bold, fake italic) to match styles
class FontFakery {
public:
    FontFakery() : mFakeBold(false), mFakeItalic(false) { }
    FontFakery(bool fakeBold, bool fakeItalic) : mFakeBold(fakeBold), mFakeItalic(fakeItalic) { }
    // TODO: want to support graded fake bolding
    bool isFakeBold() { return mFakeBold; }
    bool isFakeItalic() { return mFakeItalic; }
private:
    bool mFakeBold;
    bool mFakeItalic;
};

struct FakedFont {
    // ownership is the enclosing FontCollection
    MinikinFont* font;
    FontFakery fakery;
};

class FontFamily : public MinikinRefCounted {
public:
    FontFamily() : mHbFont(nullptr) { }

    FontFamily(FontLanguage lang, int variant) : mLang(lang), mVariant(variant), mHbFont(nullptr) {
    }

    ~FontFamily();

    // Add font to family, extracting style information from the font
    bool addFont(MinikinFont* typeface);

    void addFont(MinikinFont* typeface, FontStyle style);
    FakedFont getClosestMatch(FontStyle style) const;

    FontLanguage lang() const { return mLang; }
    int variant() const { return mVariant; }

    // API's for enumerating the fonts in a family. These don't guarantee any particular order
    size_t getNumFonts() const;
    MinikinFont* getFont(size_t index) const;
    FontStyle getStyle(size_t index) const;

    // Get Unicode coverage. Lifetime of returned bitset is same as receiver. May return nullptr on
    // error.
    const SparseBitSet* getCoverage();

    // Returns true if the font has a glyph for the code point and variation selector pair.
    // Caller should acquire a lock before calling the method.
    bool hasVariationSelector(uint32_t codepoint, uint32_t variationSelector);

    // Purges cached mHbFont.
    // hb_font_t keeps a reference to hb_face_t which is managed by HbFaceCache. Thus,
    // it is good to purge hb_font_t once it is no longer necessary.
    // Caller should acquire a lock before calling the method.
    void purgeHbFontCache();
private:
    void addFontLocked(MinikinFont* typeface, FontStyle style);

    class Font {
    public:
        Font(MinikinFont* typeface, FontStyle style) :
            typeface(typeface), style(style) { }
        MinikinFont* typeface;
        FontStyle style;
    };
    FontLanguage mLang;
    int mVariant;
    std::vector<Font> mFonts;

    SparseBitSet mCoverage;
    bool mCoverageValid;

    hb_font_t* mHbFont;
};

}  // namespace android

#endif  // MINIKIN_FONT_FAMILY_H
