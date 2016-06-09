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

// This is a test program that uses Minikin to layout and draw some text.
// At the moment, it just draws a string into /data/local/tmp/foo.pgm.

#include <stdio.h>
#include <vector>
#include <fstream>

#include <unicode/unistr.h>
#include <unicode/utf16.h>

#include <minikin/MinikinFontFreeType.h>
#include <minikin/Layout.h>

using std::vector;
using namespace minikin;

FT_Library library;  // TODO: this should not be a global

FontCollection *makeFontCollection() {
    vector<FontFamily *>typefaces;
    const char *fns[] = {
        "/system/fonts/Roboto-Regular.ttf",
        "/system/fonts/Roboto-Italic.ttf",
        "/system/fonts/Roboto-BoldItalic.ttf",
        "/system/fonts/Roboto-Light.ttf",
        "/system/fonts/Roboto-Thin.ttf",
        "/system/fonts/Roboto-Bold.ttf",
        "/system/fonts/Roboto-ThinItalic.ttf",
        "/system/fonts/Roboto-LightItalic.ttf"
    };

    FontFamily *family = new FontFamily();
    FT_Face face;
    FT_Error error;
    for (size_t i = 0; i < sizeof(fns)/sizeof(fns[0]); i++) {
        const char *fn = fns[i];
        printf("adding %s\n", fn);
        error = FT_New_Face(library, fn, 0, &face);
        if (error != 0) {
            printf("error loading %s, %d\n", fn, error);
        }
        MinikinFont *font = new MinikinFontFreeType(face);
        family->addFont(font);
    }
    typefaces.push_back(family);

#if 1
    family = new FontFamily();
    const char *fn = "/system/fonts/DroidSansDevanagari-Regular.ttf";
    error = FT_New_Face(library, fn, 0, &face);
    MinikinFont *font = new MinikinFontFreeType(face);
    family->addFont(font);
    typefaces.push_back(family);
#endif

    return new FontCollection(typefaces);
}

int runMinikinTest() {
    FT_Error error = FT_Init_FreeType(&library);
    if (error) {
        return -1;
    }
    Layout::init();

    FontCollection *collection = makeFontCollection();
    Layout layout;
    layout.setFontCollection(collection);
    const char *text = "fine world \xe0\xa4\xa8\xe0\xa4\xae\xe0\xa4\xb8\xe0\xa5\x8d\xe0\xa4\xa4\xe0\xa5\x87";
    int bidiFlags = 0;
    FontStyle fontStyle;
    MinikinPaint paint;
    paint.size = 32;
    icu::UnicodeString icuText = icu::UnicodeString::fromUTF8(text);
    layout.doLayout(icuText.getBuffer(), 0, icuText.length(), icuText.length(), bidiFlags, fontStyle, paint);
    layout.dump();
    Bitmap bitmap(250, 50);
    layout.draw(&bitmap, 10, 40, 32);
    std::ofstream o;
    o.open("/data/local/tmp/foo.pgm", std::ios::out | std::ios::binary);
    bitmap.writePnm(o);
    return 0;
}

int main() {
    return runMinikinTest();
}
