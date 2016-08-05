// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_TEXT_PARAGRAPH_H_
#define SKY_ENGINE_CORE_TEXT_PARAGRAPH_H_

#include "flutter/lib/ui/painting/canvas.h"
#include "lib/tonic/dart_wrappable.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/core/text/TextBox.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class Paragraph : public ftl::RefCountedThreadSafe<Paragraph>,
                  public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(Paragraph);

 public:
  static ftl::RefPtr<Paragraph> create(PassOwnPtr<RenderView> renderView) {
    return ftl::MakeRefCounted<Paragraph>(renderView);
  }

  ~Paragraph() override;

  double width();
  double height();
  double minIntrinsicWidth();
  double maxIntrinsicWidth();
  double alphabeticBaseline();
  double ideographicBaseline();

  void layout(double width);
  void paint(Canvas* canvas, double x, double y);

  std::vector<TextBox> getRectsForRange(unsigned start, unsigned end);
  Dart_Handle getPositionForOffset(double dx, double dy);
  Dart_Handle getWordBoundary(unsigned offset);

  RenderView* renderView() const { return m_renderView.get(); }

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  RenderBox* firstChildBox() const { return m_renderView->firstChildBox(); }

  int absoluteOffsetForPosition(const PositionWithAffinity& position);

  explicit Paragraph(PassOwnPtr<RenderView> renderView);

  OwnPtr<RenderView> m_renderView;
};

}  // namespace blink

#endif  // SKY_ENGINE_CORE_TEXT_PARAGRAPH_H_
