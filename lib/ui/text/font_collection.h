// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_TEXT_FONT_COLLECTION_H_
#define FLUTTER_LIB_UI_TEXT_FONT_COLLECTION_H_

#include <memory>
#include <vector>
#include "flutter/assets/zip_asset_store.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/memory/ref_ptr.h"
#include "txt/asset_data_provider.h"
#include "txt/font_collection.h"

namespace blink {

class FontCollection {
 public:
  static FontCollection& ForProcess();

  std::shared_ptr<txt::FontCollection> GetFontCollection() const;

  void RegisterFontsFromAssetStore(
      fxl::RefPtr<blink::ZipAssetStore> asset_store);

 private:
  std::shared_ptr<txt::FontCollection> collection_;

  FontCollection();

  ~FontCollection();

  FXL_DISALLOW_COPY_AND_ASSIGN(FontCollection);
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_TEXT_FONT_COLLECTION_H_
