// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_TEXT_PARAGRAPH_BUILDER_H_
#define FLUTTER_LIB_UI_TEXT_PARAGRAPH_BUILDER_H_

#include <memory>
#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/paint.h"
#include "flutter/lib/ui/text/paragraph.h"
#include "flutter/third_party/txt/src/txt/paragraph_builder.h"
#include "third_party/tonic/typed_data/int32_list.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class Paragraph;

class ParagraphBuilder : public RefCountedDartWrappable<ParagraphBuilder> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(ParagraphBuilder);

 public:
  static fml::RefPtr<ParagraphBuilder> create(tonic::Int32List& encoded,
                                              const std::string& fontFamily,
                                              double fontSize,
                                              double lineHeight,
                                              const std::u16string& ellipsis,
                                              const std::string& locale);

  ~ParagraphBuilder() override;

  void pushStyle(tonic::Int32List& encoded,
                 const std::string& fontFamily,
                 double fontSize,
                 double letterSpacing,
                 double wordSpacing,
                 double height,
                 const std::string& locale,
                 Dart_Handle background_objects,
                 Dart_Handle background_data,
                 Dart_Handle foreground_objects,
                 Dart_Handle foreground_data,
                 Dart_Handle shadows_data);

  void pop();

  Dart_Handle addText(const std::u16string& text);

  fml::RefPtr<Paragraph> build();

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  explicit ParagraphBuilder(tonic::Int32List& encoded,
                            const std::string& fontFamily,
                            double fontSize,
                            double lineHeight,
                            const std::u16string& ellipsis,
                            const std::string& locale);

  std::unique_ptr<txt::ParagraphBuilder> m_paragraphBuilder;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_TEXT_PARAGRAPH_BUILDER_H_
