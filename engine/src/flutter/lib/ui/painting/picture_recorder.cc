// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/picture_recorder.h"

#include "flutter/lib/ui/painting/canvas.h"
#include "flutter/lib/ui/painting/picture.h"
#include "impeller/display_list/skia_conversions.h"  // nogncheck
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, PictureRecorder);

void PictureRecorder::Create(Dart_Handle wrapper) {
  UIDartState::ThrowIfUIOperationsProhibited();
  auto res = fml::MakeRefCounted<PictureRecorder>();
  res->AssociateWithDartWrapper(wrapper);
}

PictureRecorder::PictureRecorder() {}

PictureRecorder::~PictureRecorder() {}

DlCanvas* PictureRecorder::BeginRecording(SkRect bounds) {
#if IMPELLER_SUPPORTS_RENDERING
  if (UIDartState::Current()->IsImpellerEnabled()) {
    dl_aiks_canvas_ = std::make_shared<impeller::DlAiksCanvas>(bounds);
    return dl_aiks_canvas_.get();
  } else {
#endif  // IMPELLER_SUPPORTS_RENDERING
    builder_ = sk_make_sp<DisplayListBuilder>(bounds, /*prepare_rtree=*/true);
    return builder_.get();
#if IMPELLER_SUPPORTS_RENDERING
  }
#endif  // IMPELLER_SUPPORTS_RENDERING
}

fml::RefPtr<Picture> PictureRecorder::endRecording(Dart_Handle dart_picture) {
  if (!canvas_) {
    return nullptr;
  }
  fml::RefPtr<Picture> picture;

#if IMPELLER_SUPPORTS_RENDERING
  if (UIDartState::Current()->IsImpellerEnabled()) {
    picture = Picture::Create(dart_picture,
                              std::make_shared<impeller::Picture>(
                                  dl_aiks_canvas_->EndRecordingAsPicture()));
    dl_aiks_canvas_ = nullptr;
  } else {
#endif
    picture = Picture::Create(dart_picture, builder_->Build());
    builder_ = nullptr;
#if IMPELLER_SUPPORTS_RENDERING
  }
#endif  // IMPELLER_SUPPORTS_RENDERING

  canvas_->Invalidate();
  canvas_ = nullptr;
  ClearDartWrapper();
  return picture;
}

}  // namespace flutter
