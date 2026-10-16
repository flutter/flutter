// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_TEXT_PARAGRAPH_BUILDER_H_
#define FLUTTER_LIB_UI_TEXT_PARAGRAPH_BUILDER_H_

#include <memory>

#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/paint.h"
#include "flutter/lib/ui/text/paragraph.h"
#include "flutter/lib/ui/text/text_styles.g.h"
#include "flutter/txt/src/txt/paragraph_builder.h"

namespace flutter {

class Paragraph;

class ParagraphBuilder : public RefCountedDartWrappable<ParagraphBuilder> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(ParagraphBuilder);

 public:
  static void Create(Dart_Handle wrapper, const ParagraphStyle& in);

  ~ParagraphBuilder() override;

  void pushStyle(const TextStyle& in);

  void pop();

  Dart_Handle addText(const std::u16string& text);

  // Pushes the information required to leave an open space, where Flutter may
  // draw a custom placeholder into.
  //
  // Internally, this method adds a single object replacement character (0xFFFC)
  // and emplaces a new PlaceholderRun instance to the vector of inline
  // placeholders.
  void addPlaceholder(double width,
                      double height,
                      unsigned alignment,
                      double baseline_offset,
                      unsigned baseline);

  void build(Dart_Handle paragraph_handle);

 private:
  explicit ParagraphBuilder(const ParagraphStyle& in);

  std::unique_ptr<txt::ParagraphBuilder> m_paragraph_builder_;
  bool m_default_half_leading_ = false;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_TEXT_PARAGRAPH_BUILDER_H_
