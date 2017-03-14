/*
 * Copyright (C) 2016 The Android Open Source Project
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
#include <benchmark/benchmark.h>

#include <memory>

#include <minikin/FontCollection.h>
#include <util/FontTestUtils.h>
#include <util/UnicodeUtils.h>
#include <MinikinInternal.h>

namespace minikin {

const char* SYSTEM_FONT_PATH = "/system/fonts/";
const char* SYSTEM_FONT_XML = "/system/etc/fonts.xml";

static void BM_FontCollection_hasVariationSelector(benchmark::State& state) {
    std::shared_ptr<FontCollection> collection(
            getFontCollection(SYSTEM_FONT_PATH, SYSTEM_FONT_XML));

    uint32_t baseCp = state.range(0);
    uint32_t vsCp = state.range(1);

    char titleBuffer[64];
    snprintf(titleBuffer, 64, "hasVariationSelector U+%04X,U+%04X", baseCp, vsCp);
    state.SetLabel(titleBuffer);

    while (state.KeepRunning()) {
        collection->hasVariationSelector(baseCp, vsCp);
    }
}

// TODO: Rewrite with BENCHMARK_CAPTURE for better test name.
BENCHMARK(BM_FontCollection_hasVariationSelector)
      ->ArgPair(0x2708, 0xFE0F)
      ->ArgPair(0x2708, 0xFE0E)
      ->ArgPair(0x3402, 0xE0100);

struct ItemizeTestCases {
    std::string itemizeText;
    std::string languageTag;
    std::string labelText;
} ITEMIZE_TEST_CASES[] = {
    { "'A' 'n' 'd' 'r' 'o' 'i' 'd'", "en", "English" },
    { "U+4E16", "zh-Hans", "CJK Ideograph" },
    { "U+4E16", "zh-Hans,zh-Hant,ja,en,es,pt,fr,de", "CJK Ideograph with many language fallback" },
    { "U+3402 U+E0100", "ja", "CJK Ideograph with variation selector" },
    { "'A' 'n' U+0E1A U+0E31 U+0645 U+062D U+0648", "en", "Mixture of English, Thai and Arabic" },
    { "U+2708 U+FE0E", "en", "Emoji with variation selector" },
    { "U+0031 U+FE0F U+20E3", "en", "KEYCAP" },
};

static void BM_FontCollection_itemize(benchmark::State& state) {
    std::shared_ptr<FontCollection> collection(
            getFontCollection(SYSTEM_FONT_PATH, SYSTEM_FONT_XML));

    size_t testIndex = state.range(0);
    state.SetLabel("Itemize: " + ITEMIZE_TEST_CASES[testIndex].labelText);

    uint16_t buffer[64];
    size_t utf16_length = 0;
    ParseUnicode(
            buffer, 64, ITEMIZE_TEST_CASES[testIndex].itemizeText.c_str(), &utf16_length, nullptr);
    std::vector<FontCollection::Run> result;
    FontStyle style(FontStyle::registerLanguageList(ITEMIZE_TEST_CASES[testIndex].languageTag));

    android::AutoMutex _l(gMinikinLock);
    while (state.KeepRunning()) {
        result.clear();
        collection->itemize(buffer, utf16_length, style, &result);
    }
}

// TODO: Rewrite with BENCHMARK_CAPTURE once it is available in Android.
BENCHMARK(BM_FontCollection_itemize)
    ->Arg(0)->Arg(1)->Arg(2)->Arg(3)->Arg(4)->Arg(5)->Arg(6);

}  // namespace minikin
