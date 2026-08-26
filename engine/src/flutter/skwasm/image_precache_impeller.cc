// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/skwasm/image_precache_impeller.h"

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/effects/color_sources/dl_image_color_source.h"
#include "flutter/display_list/image/dl_image.h"
#include "flutter/display_list/utils/dl_receiver_utils.h"
#include "impeller/display_list/dl_image_impeller.h"

namespace Skwasm {

namespace {

class ImagePrecacheDispatcher : public virtual flutter::DlOpReceiver,
                                public flutter::IgnoreAttributeDispatchHelper,
                                public flutter::IgnoreClipDispatchHelper,
                                public flutter::IgnoreTransformDispatchHelper,
                                public flutter::IgnoreDrawDispatchHelper {
 public:
  explicit ImagePrecacheDispatcher(impeller::ContentContext& context)
      : context_(context) {}

  void drawImage(const sk_sp<flutter::DlImage> image,
                 const flutter::DlPoint& point,
                 flutter::DlImageSampling sampling,
                 bool render_with_attributes) override {
    Precache(image);
  }

  void drawImageRect(const sk_sp<flutter::DlImage> image,
                     const flutter::DlRect& src,
                     const flutter::DlRect& dst,
                     flutter::DlImageSampling sampling,
                     bool render_with_attributes,
                     flutter::DlSrcRectConstraint constraint =
                         flutter::DlSrcRectConstraint::kFast) override {
    Precache(image);
  }

  void drawImageNine(const sk_sp<flutter::DlImage> image,
                     const flutter::DlIRect& center,
                     const flutter::DlRect& dst,
                     flutter::DlFilterMode filter,
                     bool render_with_attributes) override {
    Precache(image);
  }

  void drawAtlas(const sk_sp<flutter::DlImage> atlas,
                 const flutter::DlRSTransform xform[],
                 const flutter::DlRect tex[],
                 const flutter::DlColor colors[],
                 int count,
                 flutter::DlBlendMode mode,
                 flutter::DlImageSampling sampling,
                 const flutter::DlRect* cull_rect,
                 bool render_with_attributes) override {
    Precache(atlas);
  }

  void setColorSource(const flutter::DlColorSource* source) override {
    if (source && source->asImage()) {
      Precache(source->asImage()->image());
    }
  }

  void drawDisplayList(const sk_sp<flutter::DisplayList> display_list,
                       flutter::DlScalar opacity) override {
    if (display_list) {
      display_list->Dispatch(*this);
    }
  }

 private:
  void Precache(const sk_sp<const flutter::DlImage>& image) {
    if (image) {
      image->asImpellerImage()->GetCachedTexture(context_);
    }
  }

  impeller::ContentContext& context_;
};

}  // namespace

// Walks the display list and eagerly resolves/caches textures for any images
// so they are not rasterized re-entrantly during the main render pass.
void PrecacheImages(const flutter::DisplayList* display_list,
                    impeller::ContentContext& context) {
  if (!display_list) {
    return;
  }
  ImagePrecacheDispatcher dispatcher(context);
  display_list->Dispatch(dispatcher);
}

}  // namespace Skwasm
