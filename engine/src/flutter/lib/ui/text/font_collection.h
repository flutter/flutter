// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_TEXT_FONT_COLLECTION_H_
#define FLUTTER_LIB_UI_TEXT_FONT_COLLECTION_H_

#include <memory>
#include <vector>

#include "flutter/assets/asset_manager.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "txt/font_collection.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace flutter {

class FontCollection {
 public:
  FontCollection();

  ~FontCollection();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

  std::shared_ptr<txt::FontCollection> GetFontCollection() const;

  void SetupDefaultFontManager(uint32_t font_initialization_data);

  void RegisterFonts(std::shared_ptr<AssetManager> asset_manager);

  void RegisterTestFonts();

  void LoadFontFromList(const uint8_t* font_data,
                        int length,
                        std::string family_name);

 private:
  std::shared_ptr<txt::FontCollection> collection_;
  sk_sp<txt::DynamicFontManager> dynamic_font_manager_;

  FML_DISALLOW_COPY_AND_ASSIGN(FontCollection);
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_TEXT_FONT_COLLECTION_H_
