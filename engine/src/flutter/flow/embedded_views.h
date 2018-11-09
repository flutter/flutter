// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
#ifndef FLUTTER_FLOW_EMBEDDED_VIEWS_H_
#define FLUTTER_FLOW_EMBEDDED_VIEWS_H_

#include <vector>

#include "flutter/fml/memory/ref_counted.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkSize.h"

namespace flow {

class EmbeddedViewParams {
 public:
  SkPoint offsetPixels;
  SkSize sizePoints;
};

// This is only used on iOS when running in a non headless mode,
// in this case ViewEmbedded is a reference to the
// FlutterPlatformViewsController which is owned by FlutterViewController.
class ExternalViewEmbedder {
 public:
  ExternalViewEmbedder() = default;

  virtual void BeginFrame(SkISize frame_size) = 0;

  virtual void PrerollCompositeEmbeddedView(int view_id) = 0;

  virtual std::vector<SkCanvas*> GetCurrentCanvases() = 0;

  // Must be called on the UI thread.
  virtual SkCanvas* CompositeEmbeddedView(int view_id,
                                          const EmbeddedViewParams& params) = 0;

  virtual bool SubmitFrame(GrContext* context) { return false; };

  virtual ~ExternalViewEmbedder() = default;

  FML_DISALLOW_COPY_AND_ASSIGN(ExternalViewEmbedder);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_EMBEDDED_VIEWS_H_
