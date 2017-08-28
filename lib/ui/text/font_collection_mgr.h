// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This class creates and holds the txt::FontCollection that contains the
// Default and Custom fonts.

#ifndef FLUTTER_LIB_UI_TEXT_FONT_COLLECTION_MGR_H_
#define FLUTTER_LIB_UI_TEXT_FONT_COLLECTION_MGR_H_


#include "flutter/sky/engine/wtf/PassOwnPtr.h"
#include "flutter/third_party/txt/src/txt/font_collection.h"
#include "lib/tonic/dart_wrappable.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class FontCollectionMgr : public ftl::RefCountedThreadSafe<FontCollectionMgr>,
                          public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(FontCollectionMgr);

 public:
  static txt::FontCollection* kFontCollection;

  static void addFontDir(std::string font_dir);

  static void initializeFontCollection();

  static void initializeFontCollectionSingle(std::string font_dir);

  static void initializeFontCollectionMultiple(
      std::vector<std::string> font_dirs);

  static void RegisterNatives(tonic::DartLibraryNatives* natives);
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_TEXT_FONT_COLLECTION_MGR_H_
