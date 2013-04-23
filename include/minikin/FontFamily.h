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

namespace android {

// FontStyle represents all style information needed to select an actual font
// from a collection. The implementation is packed into a single 32-bit word
// so it can be efficiently copied, embedded in other objects, etc.
class FontStyle {
public:
    FontStyle(int weight = 4, bool italic = false) {
        bits = (weight & kWeightMask) | (italic ? kItalicMask : 0);
    }
    int getWeight() { return bits & kWeightMask; }
    bool getItalic() { return (bits & kItalicMask) != 0; }
    bool operator==(const FontStyle other) { return bits == other.bits; }
    // TODO: language, variant
private:
    static const int kWeightMask = 0xf;
    static const int kItalicMask = 16;
    uint32_t bits;
};

class FontFamily {
public:
    // Add font to family, extracting style information from the font
    bool addFont(FT_Face typeface);

    void addFont(FT_Face typeface, FontStyle style);
    FT_Face getClosestMatch(FontStyle style) const;

    // API's for enumerating the fonts in a family. These don't guarantee any particular order
    size_t getNumFonts() const;
    FT_Face getFont(size_t index) const;
    FontStyle getStyle(size_t index) const;
private:
    class Font {
    public:
        Font(FT_Face typeface, FontStyle style) :
            typeface(typeface), style(style) { }
        FT_Face typeface;
        FontStyle style;
    };
    std::vector<Font> mFonts;
};

}  // namespace android

#endif  // MINIKIN_FONT_FAMILY_H
