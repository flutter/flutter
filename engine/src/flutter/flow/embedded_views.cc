// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/embedded_views.h"

namespace flutter {

SkPictureEmbedderViewSlice::SkPictureEmbedderViewSlice(SkRect view_bounds) {
  auto rtree_factory = RTreeFactory();
  rtree_ = rtree_factory.getInstance();

  recorder_ = std::make_unique<SkPictureRecorder>();
  recorder_->beginRecording(view_bounds, &rtree_factory);
}

SkCanvas* SkPictureEmbedderViewSlice::canvas() {
  return recorder_->getRecordingCanvas();
}

DisplayListBuilder* SkPictureEmbedderViewSlice::builder() {
  return nullptr;
}

void SkPictureEmbedderViewSlice::end_recording() {
  picture_ = recorder_->finishRecordingAsPicture();
}

std::list<SkRect> SkPictureEmbedderViewSlice::searchNonOverlappingDrawnRects(
    const SkRect& query) const {
  return rtree_->searchNonOverlappingDrawnRects(query);
}

void SkPictureEmbedderViewSlice::render_into(SkCanvas* canvas) {
  canvas->drawPicture(picture_);
}

void SkPictureEmbedderViewSlice::render_into(DisplayListBuilder* builder) {
  builder->drawPicture(picture_, nullptr, false);
}

DisplayListEmbedderViewSlice::DisplayListEmbedderViewSlice(SkRect view_bounds) {
  recorder_ = std::make_unique<DisplayListCanvasRecorder>(view_bounds);
}

SkCanvas* DisplayListEmbedderViewSlice::canvas() {
  return recorder_ ? recorder_.get() : nullptr;
}

DisplayListBuilder* DisplayListEmbedderViewSlice::builder() {
  return recorder_ ? recorder_->builder().get() : nullptr;
}

void DisplayListEmbedderViewSlice::end_recording() {
  display_list_ = recorder_->Build();
  recorder_ = nullptr;
}

std::list<SkRect> DisplayListEmbedderViewSlice::searchNonOverlappingDrawnRects(
    const SkRect& query) const {
  return display_list_->rtree()->searchNonOverlappingDrawnRects(query);
}

void DisplayListEmbedderViewSlice::render_into(SkCanvas* canvas) {
  display_list_->RenderTo(canvas);
}

void DisplayListEmbedderViewSlice::render_into(DisplayListBuilder* builder) {
  builder->drawDisplayList(display_list_);
}

void ExternalViewEmbedder::SubmitFrame(GrDirectContext* context,
                                       std::unique_ptr<SurfaceFrame> frame) {
  frame->Submit();
};

void MutatorsStack::PushClipRect(const SkRect& rect) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(rect);
  vector_.push_back(element);
};

void MutatorsStack::PushClipRRect(const SkRRect& rrect) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(rrect);
  vector_.push_back(element);
};

void MutatorsStack::PushClipPath(const SkPath& path) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(path);
  vector_.push_back(element);
};

void MutatorsStack::PushTransform(const SkMatrix& matrix) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(matrix);
  vector_.push_back(element);
};

void MutatorsStack::PushOpacity(const int& alpha) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(alpha);
  vector_.push_back(element);
};

void MutatorsStack::PushBackdropFilter(
    const std::shared_ptr<const DlImageFilter>& filter) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(filter);
  vector_.push_back(element);
};

void MutatorsStack::Pop() {
  vector_.pop_back();
};

const std::vector<std::shared_ptr<Mutator>>::const_reverse_iterator
MutatorsStack::Top() const {
  return vector_.rend();
};

const std::vector<std::shared_ptr<Mutator>>::const_reverse_iterator
MutatorsStack::Bottom() const {
  return vector_.rbegin();
};

const std::vector<std::shared_ptr<Mutator>>::const_iterator
MutatorsStack::Begin() const {
  return vector_.begin();
};

const std::vector<std::shared_ptr<Mutator>>::const_iterator MutatorsStack::End()
    const {
  return vector_.end();
};

bool ExternalViewEmbedder::SupportsDynamicThreadMerging() {
  return false;
}

void ExternalViewEmbedder::Teardown() {}

}  // namespace flutter
