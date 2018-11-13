// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_TEXT_PARAGRAPH_H_
#define FLUTTER_LIB_UI_TEXT_PARAGRAPH_H_

#include "flutter/fml/message_loop.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/canvas.h"
#include "flutter/lib/ui/text/paragraph_impl.h"
#include "flutter/lib/ui/text/paragraph_impl_txt.h"
#include "flutter/lib/ui/text/text_box.h"
#include "flutter/third_party/txt/src/txt/paragraph.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class Paragraph : public RefCountedDartWrappable<Paragraph> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(Paragraph);

 public:
  static fml::RefPtr<Paragraph> Create(
      std::unique_ptr<txt::Paragraph> paragraph) {
    return fml::MakeRefCounted<Paragraph>(std::move(paragraph));
  }

  ~Paragraph() override;

  double width();
  double height();
  double minIntrinsicWidth();
  double maxIntrinsicWidth();
  double alphabeticBaseline();
  double ideographicBaseline();
  bool didExceedMaxLines();

  void layout(double width);
  void paint(Canvas* canvas, double x, double y);

  std::vector<TextBox> getRectsForRange(unsigned start,
                                        unsigned end,
                                        unsigned boxHeightStyle,
                                        unsigned boxWidthStyle);
  Dart_Handle getPositionForOffset(double dx, double dy);
  Dart_Handle getWordBoundary(unsigned offset);

  size_t GetAllocationSize() override;

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  std::unique_ptr<ParagraphImpl> m_paragraphImpl;

  explicit Paragraph(std::unique_ptr<txt::Paragraph> paragraph);
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_TEXT_PARAGRAPH_H_
