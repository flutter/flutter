// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/embedded_views.h"

namespace flutter {

DisplayListEmbedderViewSlice::DisplayListEmbedderViewSlice(DlRect view_bounds) {
  builder_ = std::make_unique<DisplayListBuilder>(
      /*bounds=*/view_bounds,
      /*prepare_rtree=*/true);
}

DlCanvas* DisplayListEmbedderViewSlice::canvas() {
  return builder_ ? builder_.get() : nullptr;
}

void DisplayListEmbedderViewSlice::end_recording() {
  display_list_ = builder_->Build();
  FML_DCHECK(display_list_->has_rtree());
  builder_ = nullptr;
}

const DlRegion& DisplayListEmbedderViewSlice::getRegion() const {
  return display_list_->rtree()->region();
}

void DisplayListEmbedderViewSlice::render_into(DlCanvas* canvas) {
  canvas->DrawDisplayList(display_list_);
}

void DisplayListEmbedderViewSlice::dispatch(DlOpReceiver& receiver) {
  display_list_->Dispatch(receiver);
}

bool DisplayListEmbedderViewSlice::is_empty() {
  return display_list_->GetBounds().IsEmpty();
}

bool DisplayListEmbedderViewSlice::recording_ended() {
  return builder_ == nullptr;
}

void ExternalViewEmbedder::CollectView(int64_t view_id) {}

void ExternalViewEmbedder::SubmitFlutterView(
    int64_t flutter_view_id,
    GrDirectContext* context,
    const std::shared_ptr<impeller::AiksContext>& aiks_context,
    std::unique_ptr<SurfaceFrame> frame) {
  frame->Submit();
}

bool ExternalViewEmbedder::SupportsDynamicThreadMerging() {
  return false;
}

void ExternalViewEmbedder::Teardown() {}

void MutatorsStack::PushClipRect(const DlRect& rect) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(rect);
  vector_.push_back(element);
}

void MutatorsStack::PushClipRRect(const DlRoundRect& rrect) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(rrect);
  vector_.push_back(element);
}

void MutatorsStack::PushClipRSE(const DlRoundSuperellipse& rrect) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(rrect);
  vector_.push_back(element);
}

void MutatorsStack::PushClipPath(const DlPath& path) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(path);
  vector_.push_back(element);
}

void MutatorsStack::PushTransform(const DlMatrix& matrix) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(matrix);
  vector_.push_back(element);
}

void MutatorsStack::PushOpacity(const uint8_t& alpha) {
  std::shared_ptr<Mutator> element = std::make_shared<Mutator>(alpha);
  vector_.push_back(element);
}

void MutatorsStack::PushBackdropFilter(
    const std::shared_ptr<DlImageFilter>& filter,
    const DlRect& filter_rect) {
  std::shared_ptr<Mutator> element =
      std::make_shared<Mutator>(filter, filter_rect);
  vector_.push_back(element);
}

void MutatorsStack::PushPlatformViewClipRect(const DlRect& rect) {
  std::shared_ptr<Mutator> element =
      std::make_shared<Mutator>(BackdropClipRect(rect));
  vector_.push_back(element);
}
void MutatorsStack::PushPlatformViewClipRRect(const DlRoundRect& rrect) {
  std::shared_ptr<Mutator> element =
      std::make_shared<Mutator>(BackdropClipRRect(rrect));
  vector_.push_back(element);
}
void MutatorsStack::PushPlatformViewClipRSuperellipse(
    const DlRoundSuperellipse& rse) {
  std::shared_ptr<Mutator> element =
      std::make_shared<Mutator>(BackdropClipRSuperellipse(rse));
  vector_.push_back(element);
}
void MutatorsStack::PushPlatformViewClipPath(const DlPath& path) {
  std::shared_ptr<Mutator> element =
      std::make_shared<Mutator>(BackdropClipPath(path));
  vector_.push_back(element);
}

void MutatorsStack::Pop() {
  vector_.pop_back();
}

void MutatorsStack::PopTo(size_t stack_count) {
  while (vector_.size() > stack_count) {
    Pop();
  }
}

const std::vector<std::shared_ptr<Mutator>>::const_reverse_iterator
MutatorsStack::Top() const {
  return vector_.rend();
}

const std::vector<std::shared_ptr<Mutator>>::const_reverse_iterator
MutatorsStack::Bottom() const {
  return vector_.rbegin();
}

const std::vector<std::shared_ptr<Mutator>>::const_iterator
MutatorsStack::Begin() const {
  return vector_.begin();
}

const std::vector<std::shared_ptr<Mutator>>::const_iterator MutatorsStack::End()
    const {
  return vector_.end();
}

}  // namespace flutter
