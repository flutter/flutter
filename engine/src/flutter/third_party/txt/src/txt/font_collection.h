/*
 * Copyright 2017 Google Inc.
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

#ifndef LIB_TXT_SRC_FONT_COLLECTION_H_
#define LIB_TXT_SRC_FONT_COLLECTION_H_

#include <deque>
#include <memory>
#include <string>
#include <unordered_map>
#include "lib/ftl/macros.h"
#include "minikin/FontCollection.h"
#include "minikin/FontFamily.h"
#include "third_party/gtest/include/gtest/gtest_prod.h"
#include "third_party/skia/include/core/SkRefCnt.h"
#include "third_party/skia/include/ports/SkFontMgr.h"
#include "txt/asset_font_manager.h"

namespace txt {

class FontCollection {
 public:
  FontCollection();

  ~FontCollection();

  size_t GetFontManagersCount() const;

  void PushFront(sk_sp<SkFontMgr> skia_font_manager);

  void PushBack(sk_sp<SkFontMgr> skia_font_manager);

  std::shared_ptr<minikin::FontCollection> GetMinikinFontCollectionForFamily(
      const std::string& family);

 private:
  std::deque<sk_sp<SkFontMgr>> skia_font_managers_;
  std::unordered_map<std::string, std::shared_ptr<minikin::FontCollection>>
      font_collections_cache_;

  FTL_DISALLOW_COPY_AND_ASSIGN(FontCollection);
};

}  // namespace txt

#endif  // LIB_TXT_SRC_FONT_COLLECTION_H_
