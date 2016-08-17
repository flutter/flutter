// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_TEXT_PARAGRAPH_STUB_H_
#define FLUTTER_LIB_UI_TEXT_PARAGRAPH_STUB_H_

#include "flutter/lib/ui/painting/canvas.h"
#include "lib/tonic/dart_wrappable.h"

namespace tonic {
class DartLibraryNatives;
}  // namespace tonic

namespace blink {

class Paragraph : public ftl::RefCountedThreadSafe<Paragraph>,
                  public tonic::DartWrappable {
  DEFINE_WRAPPERTYPEINFO();
  FRIEND_MAKE_REF_COUNTED(Paragraph);

 public:
  static ftl::RefPtr<Paragraph> create() {
    return ftl::MakeRefCounted<Paragraph>();
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

  void getRectsForRange(unsigned start, unsigned end);
  Dart_Handle getPositionForOffset(double dx, double dy);
  Dart_Handle getWordBoundary(unsigned offset);

  static void RegisterNatives(tonic::DartLibraryNatives* natives);

 private:
  Paragraph();
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_TEXT_PARAGRAPH_STUB_H_
