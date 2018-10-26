// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
#ifndef FLUTTER_FLOW_EMBEDDED_VIEWS_H_
#define FLUTTER_FLOW_EMBEDDED_VIEWS_H_

#include "flutter/fml/memory/ref_counted.h"
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

  // Must be called on the UI thread.
  virtual void CompositeEmbeddedView(int view_id,
                                     const EmbeddedViewParams& params) {}

  virtual ~ExternalViewEmbedder() = default;

  FML_DISALLOW_COPY_AND_ASSIGN(ExternalViewEmbedder);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_EMBEDDED_VIEWS_H_
