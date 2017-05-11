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

#include <memory>
#include <string>
#include <vector>

#include "lib/ftl/macros.h"
#include "lib/txt/include/minikin/FontCollection.h"
#include "lib/txt/include/minikin/FontFamily.h"

namespace txt {

class FontProvider {
 public:
  static FontProvider& GetDefault();

  FontProvider();

  ~FontProvider();

  std::shared_ptr<minikin::FontCollection> GetFontCollectionForFamily(
      const std::string& family);

 private:
  // TODO(chinmaygarde): Caches go here.
  FTL_DISALLOW_COPY_AND_ASSIGN(FontProvider);
};

}  // namespace txt

#endif  // LIB_TXT_SRC_FONT_COLLECTION_H_
