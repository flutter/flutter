/*
 * Copyright (C) 2015 The Android Open Source Project
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

#define LOG_TAG "Minikin"

#include "MinikinFontForTest.h"

#include <minikin/MinikinFont.h>

#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <string>

#include <log/log.h>

namespace minikin {

static int uniqueId = 0;  // TODO: make thread safe if necessary.

MinikinFontForTest::MinikinFontForTest(
    const std::string& font_path,
    int index,
    const std::vector<FontVariation>& variations)
    : MinikinFont(uniqueId++),
      mFontPath(font_path),
      mVariations(variations),
      mFontIndex(index) {
  int fd = open(font_path.c_str(), O_RDONLY);
  LOG_ALWAYS_FATAL_IF(fd == -1);
  struct stat st = {};
  LOG_ALWAYS_FATAL_IF(fstat(fd, &st) != 0);
  mFontSize = st.st_size;
  mFontData = mmap(NULL, mFontSize, PROT_READ, MAP_SHARED, fd, 0);
  LOG_ALWAYS_FATAL_IF(mFontData == nullptr);
  close(fd);
}

MinikinFontForTest::~MinikinFontForTest() {
  munmap(mFontData, mFontSize);
}

float MinikinFontForTest::GetHorizontalAdvance(
    uint32_t /* glyph_id */,
    const MinikinPaint& /* paint */) const {
  // TODO: Make mock value configurable if necessary.
  return 10.0f;
}

void MinikinFontForTest::GetBounds(MinikinRect* bounds,
                                   uint32_t /* glyph_id */,
                                   const MinikinPaint& /* paint */) const {
  // TODO: Make mock values configurable if necessary.
  bounds->mLeft = 0.0f;
  bounds->mTop = 0.0f;
  bounds->mRight = 10.0f;
  bounds->mBottom = 10.0f;
}

std::shared_ptr<MinikinFont> MinikinFontForTest::createFontWithVariation(
    const std::vector<FontVariation>& variations) const {
  return std::shared_ptr<MinikinFont>(
      new MinikinFontForTest(mFontPath, mFontIndex, variations));
}

}  // namespace minikin
