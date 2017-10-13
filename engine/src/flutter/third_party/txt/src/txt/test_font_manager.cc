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

#include "txt/test_font_manager.h"
#include "lib/fxl/logging.h"

namespace txt {

TestFontManager::TestFontManager(
    std::unique_ptr<AssetDataProvider> data_provider,
    std::string test_font_family_name)
    : AssetFontManager(std::move(data_provider)),
      test_font_family_name_(test_font_family_name) {}

TestFontManager::~TestFontManager() = default;

SkFontStyleSet* TestFontManager::onMatchFamily(const char family_name[]) const {
  return AssetFontManager::onMatchFamily(test_font_family_name_.c_str());
}

}  // namespace txt
