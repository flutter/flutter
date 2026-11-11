// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Links the prelinked libimpeller.a into an executable that defines its own
// copies of symbols that Impeller also uses internally (Skia, HarfBuzz, ICU,
// FreeType, libpng, libjpeg). Each copy aborts when called.
//
// * If the archive exported any of these symbols, linking would fail with
//   duplicate symbols.
// * If a reference inside the archive bound to the copy in this executable
//   instead of Impeller's own, the text layout below would abort.
//
// This test does not use GoogleTest or any engine library, because those
// would bring in other copies of the same libraries.

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#include "impeller/toolkit/interop/impeller.h"
#include "impeller/toolkit/interop/static_library_link_test_font.h"
#include "unicode/uvernum.h"

#define STRINGIFY2(x) #x
#define STRINGIFY(x) STRINGIFY2(x)

// Defines a function with the given symbol name that aborts when called.
#define TRAP(id, symbol)                                                    \
  extern "C" void trap_##id() __asm__(STRINGIFY(__USER_LABEL_PREFIX__)      \
                                          symbol);                          \
  extern "C" void trap_##id() {                                             \
    std::fprintf(stderr, "Impeller called the application's %s\n", symbol); \
    std::abort();                                                           \
  }

#define ICU_SYMBOL(name) STRINGIFY(U_ICU_ENTRY_POINT_RENAME(name))

// HarfBuzz (shaping).
TRAP(hb_shape, "hb_shape")
TRAP(hb_shape_full, "hb_shape_full")
TRAP(hb_buffer_create, "hb_buffer_create")
TRAP(hb_font_create, "hb_font_create")
TRAP(hb_face_create, "hb_face_create")
TRAP(hb_blob_create, "hb_blob_create")
// ICU (line and word breaking, bidi).
TRAP(ubrk_open, ICU_SYMBOL(ubrk_open))
TRAP(ubrk_setText, ICU_SYMBOL(ubrk_setText))
TRAP(ubrk_next, ICU_SYMBOL(ubrk_next))
TRAP(ubidi_open, ICU_SYMBOL(ubidi_open))
TRAP(ubidi_setPara, ICU_SYMBOL(ubidi_setPara))
TRAP(u_charType, ICU_SYMBOL(u_charType))
// FreeType, libpng (with Skia's prefix) and libjpeg.
TRAP(FT_New_Memory_Face, "FT_New_Memory_Face")
TRAP(png_create_read_struct, "skia_png_create_read_struct")
TRAP(jpeg_read_header, "jpeg_read_header")
// Skia: SkFontMgr::makeFromData(sk_sp<SkData>, int) const and SkFont::SkFont().
TRAP(sk_font_mgr_make_from_data,
     "_ZNK9SkFontMgr12makeFromDataE5sk_spI6SkDataEi")
TRAP(sk_font_ctor_c1, "_ZN6SkFontC1Ev")
TRAP(sk_font_ctor_c2, "_ZN6SkFontC2Ev")

static int failures = 0;

#define CHECK(condition, ...) \
  do {                        \
    if (condition) {          \
      std::printf("[ OK ] "); \
    } else {                  \
      std::printf("[FAIL] "); \
      failures++;             \
    }                         \
    std::printf(__VA_ARGS__); \
    std::printf("\n");        \
  } while (0)

// Latin and Cyrillic, so that layout wraps and needs the bundled ICU data.
static const char kText[] =
    "The quick brown fox jumps over the lazy dog. "
    "\xd0\xa1\xd1\x8a\xd0\xb5\xd1\x88\xd1\x8c \xd0\xb6\xd0\xb5 "
    "\xd0\xb5\xd1\x89\xd1\x91 \xd1\x8d\xd1\x82\xd0\xb8\xd1\x85 "
    "\xd0\xbc\xd1\x8f\xd0\xb3\xd0\xba\xd0\xb8\xd1\x85 "
    "\xd1\x84\xd1\x80\xd0\xb0\xd0\xbd\xd1\x86\xd1\x83\xd0\xb7\xd1\x81\xd0\xba"
    "\xd0\xb8\xd1\x85 \xd0\xb1\xd1\x83\xd0\xbb\xd0\xbe\xd0\xba.";

int main() {
  CHECK(ImpellerGetVersion() == IMPELLER_VERSION, "version %u",
        ImpellerGetVersion());

  // Text: Skia typeface loading, HarfBuzz shaping, ICU breaking and bidi.
  ImpellerTypographyContext typography = ImpellerTypographyContextNew();
  CHECK(typography != nullptr, "create typography context");
  ImpellerMapping font = {impeller_static_library_link_test_font_data,
                          impeller_static_library_link_test_font_length,
                          nullptr};
  CHECK(ImpellerTypographyContextRegisterFont(typography, &font, nullptr,
                                              "LinkTestRoboto"),
        "register font");

  ImpellerParagraphStyle style = ImpellerParagraphStyleNew();
  ImpellerPaint paint = ImpellerPaintNew();
  ImpellerColor black = {0, 0, 0, 1, kImpellerColorSpaceSRGB};
  ImpellerPaintSetColor(paint, &black);
  ImpellerParagraphStyleSetForeground(style, paint);
  ImpellerParagraphStyleSetFontFamily(style, "LinkTestRoboto");
  ImpellerParagraphStyleSetFontSize(style, 24);

  ImpellerParagraphBuilder builder = ImpellerParagraphBuilderNew(typography);
  ImpellerParagraphBuilderPushStyle(builder, style);
  ImpellerParagraphBuilderAddText(builder,
                                  reinterpret_cast<const uint8_t*>(kText),
                                  static_cast<uint32_t>(std::strlen(kText)));
  ImpellerParagraph paragraph =
      ImpellerParagraphBuilderBuildParagraphNew(builder, 300);
  CHECK(paragraph != nullptr, "lay out paragraph");

  if (paragraph) {
    uint32_t lines = ImpellerParagraphGetLineCount(paragraph);
    float height = ImpellerParagraphGetHeight(paragraph);
    float longest = ImpellerParagraphGetLongestLineWidth(paragraph);
    float max_intrinsic = ImpellerParagraphGetMaxIntrinsicWidth(paragraph);
    CHECK(lines >= 3 && lines <= 6, "wraps to 3-6 lines at width 300 (%u)",
          lines);
    CHECK(height > lines * 24.0f && height < lines * 40.0f,
          "height is plausible (%.2f)", height);
    CHECK(longest > 150 && longest <= 300,
          "longest line is within the layout width (%.2f)", longest);
    CHECK(max_intrinsic > 600, "max intrinsic width is unwrapped (%.2f)",
          max_intrinsic);

    ImpellerRange word = {};
    ImpellerParagraphGetWordBoundary(paragraph, 6, &word);
    CHECK(word.start == 4 && word.end == 9,
          "word boundary of 'quick' is [4, 9) (got [%llu, %llu))",
          static_cast<unsigned long long>(word.start),
          static_cast<unsigned long long>(word.end));
  }

  // Paths and display lists.
  ImpellerPathBuilder path_builder = ImpellerPathBuilderNew();
  ImpellerRect oval = {10, 20, 100, 50};
  ImpellerPathBuilderAddOval(path_builder, &oval);
  ImpellerPath path =
      ImpellerPathBuilderTakePathNew(path_builder, kImpellerFillTypeNonZero);
  ImpellerRect bounds = {};
  ImpellerPathGetBounds(path, &bounds);
  CHECK(std::fabs(bounds.x - 10) < 0.01 && std::fabs(bounds.y - 20) < 0.01 &&
            std::fabs(bounds.width - 100) < 0.01 &&
            std::fabs(bounds.height - 50) < 0.01,
        "oval bounds are {10, 20, 100, 50}");

  ImpellerDisplayListBuilder dl_builder =
      ImpellerDisplayListBuilderNew(nullptr);
  ImpellerDisplayListBuilderDrawPath(dl_builder, path, paint);
  if (paragraph) {
    ImpellerPoint origin = {10, 80};
    ImpellerDisplayListBuilderDrawParagraph(dl_builder, paragraph, &origin);
  }
  ImpellerDisplayList display_list =
      ImpellerDisplayListBuilderCreateDisplayListNew(dl_builder);
  CHECK(display_list != nullptr, "build display list");

  ImpellerDisplayListRelease(display_list);
  ImpellerDisplayListBuilderRelease(dl_builder);
  ImpellerPathRelease(path);
  ImpellerPathBuilderRelease(path_builder);
  ImpellerParagraphRelease(paragraph);
  ImpellerParagraphBuilderRelease(builder);
  ImpellerPaintRelease(paint);
  ImpellerParagraphStyleRelease(style);
  ImpellerTypographyContextRelease(typography);

  std::printf(failures ? "FAILED (%d)\n" : "PASSED\n", failures);
  return failures ? EXIT_FAILURE : EXIT_SUCCESS;
}
