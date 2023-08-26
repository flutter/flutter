// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_PICTURE_RECORDER_H_
#define FLUTTER_LIB_UI_PAINTING_PICTURE_RECORDER_H_

#include <variant>

#include "flutter/display_list/display_list_builder.h"
#include "flutter/lib/ui/dart_wrapper.h"

#if IMPELLER_SUPPORTS_RENDERING
#include "impeller/display_list/dl_aiks_canvas.h"  // nogncheck
#else   // IMPELLER_SUPPORTS_RENDERING
namespace impeller {
class DlAiksCanvas;
}  // namespace impeller
#endif  // !IMPELLER_SUPPORTS_RENDERING

namespace flutter {
class Canvas;
class Picture;

class PictureRecorder : public RefCountedDartWrappable<PictureRecorder> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(PictureRecorder);

 public:
  static void Create(Dart_Handle wrapper);

  ~PictureRecorder() override;

  DlCanvas* BeginRecording(SkRect bounds);
  fml::RefPtr<Picture> endRecording(Dart_Handle dart_picture);

  void set_canvas(fml::RefPtr<Canvas> canvas) { canvas_ = std::move(canvas); }

 private:
  PictureRecorder();

  std::shared_ptr<impeller::DlAiksCanvas> dl_aiks_canvas_;
  sk_sp<DisplayListBuilder> builder_;

  fml::RefPtr<Canvas> canvas_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_PICTURE_RECORDER_H_
