// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/picture_recorder.h"

#include "flutter/display_list/display_list.h"
#include "flutter/lib/ui/painting/canvas.h"
#include "flutter/lib/ui/painting/picture.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

namespace flutter {

static void PictureRecorder_constructor(Dart_NativeArguments args) {
  UIDartState::ThrowIfUIOperationsProhibited();
  DartCallConstructor(&PictureRecorder::Create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, PictureRecorder);

#define FOR_EACH_BINDING(V) V(PictureRecorder, endRecording)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void PictureRecorder::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register(
      {{"PictureRecorder_constructor", PictureRecorder_constructor, 1, true},
       FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

fml::RefPtr<PictureRecorder> PictureRecorder::Create() {
  return fml::MakeRefCounted<PictureRecorder>();
}

PictureRecorder::PictureRecorder() {}

PictureRecorder::~PictureRecorder() {}

SkCanvas* PictureRecorder::BeginRecording(SkRect bounds) {
  display_list_recorder_ = sk_make_sp<DisplayListCanvasRecorder>(bounds);
  return display_list_recorder_.get();
}

fml::RefPtr<Picture> PictureRecorder::endRecording(Dart_Handle dart_picture) {
  if (!canvas_) {
    return nullptr;
  }

  fml::RefPtr<Picture> picture;

  picture = Picture::Create(dart_picture, UIDartState::CreateGPUObject(
                                              display_list_recorder_->Build()));
  display_list_recorder_ = nullptr;

  canvas_->Invalidate();
  canvas_ = nullptr;
  ClearDartWrapper();
  return picture;
}

}  // namespace flutter
