// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/external_view_embedder/frame_packet_mailbox.h"

namespace flutter {

namespace {

const HybridJavaGlobalRef& EmptyHybridJavaGlobalRef() noexcept {
  static const HybridJavaGlobalRef kEmpty;
  return kEmpty;
}

}  // namespace

AcquiredHybridImage::AcquiredHybridImage(
    std::shared_ptr<HybridReaderHandle> reader_handle,
    HybridJavaGlobalRef image) noexcept
    : reader_handle_(std::move(reader_handle)), image_(std::move(image)) {}

AcquiredHybridImage::~AcquiredHybridImage() {
  Reset();
}

AcquiredHybridImage::AcquiredHybridImage(AcquiredHybridImage&& other) noexcept
    : reader_handle_(std::move(other.reader_handle_)),
      image_(std::move(other.image_)) {}

AcquiredHybridImage& AcquiredHybridImage::operator=(
    AcquiredHybridImage&& other) noexcept {
  if (this != &other) {
    Reset();
    reader_handle_ = std::move(other.reader_handle_);
    image_ = std::move(other.image_);
  }
  return *this;
}

void AcquiredHybridImage::Reset() noexcept {
  if (image_) {
    if (reader_handle_) {
      reader_handle_->ReleaseImage(std::move(image_));
    } else {
      image_.Reset();
    }
  }
  reader_handle_.reset();
}

const HybridJavaGlobalRef& AcquiredHybridImage::reader() const noexcept {
  return reader_handle_ ? reader_handle_->reader() : EmptyHybridJavaGlobalRef();
}

OverlaySlicePacket::OverlaySlicePacket(int surface_id,
                                       DlIRect bounds,
                                       AcquiredHybridImage image) noexcept
    : surface_id(surface_id), bounds(bounds), image(std::move(image)) {}

PlatformViewPacketEntry::PlatformViewPacketEntry(
    int64_t view_id,
    DlIRect bounds,
    int32_t physical_width,
    int32_t physical_height,
    MutatorsStack mutators_stack,
    std::optional<OverlaySlicePacket> overlay) noexcept
    : view_id(view_id),
      bounds(bounds),
      physical_width(physical_width),
      physical_height(physical_height),
      mutators_stack(std::move(mutators_stack)),
      overlay(std::move(overlay)) {}

FramePacketMailbox::~FramePacketMailbox() {
  std::unique_ptr<FramePacket> leftover = CloseAndTake();
  leftover.reset();
}

FramePacketMailbox::PublishResult FramePacketMailbox::Publish(
    std::unique_ptr<FramePacket> packet) {
  PublishResult result;
  if (!packet) {
    return result;
  }

  std::unique_ptr<FramePacket> rejected_packet;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (closed_) {
      rejected_packet = std::move(packet);
    } else {
      result.superseded_packet = std::exchange(pending_, std::move(packet));
      result.accepted = true;
      if (!drain_scheduled_) {
        drain_scheduled_ = true;
        result.schedule_drain = true;
      }
    }
  }
  // If closed_, release |rejected_packet| outside |mutex_|.
  rejected_packet.reset();
  return result;
}

std::unique_ptr<FramePacket> FramePacketMailbox::Take() {
  std::lock_guard<std::mutex> lock(mutex_);
  drain_scheduled_ = false;
  return std::move(pending_);
}

std::unique_ptr<FramePacket> FramePacketMailbox::ResetAndTake() {
  std::lock_guard<std::mutex> lock(mutex_);
  drain_scheduled_ = false;
  return std::move(pending_);
}

std::unique_ptr<FramePacket> FramePacketMailbox::CloseAndTake() {
  std::lock_guard<std::mutex> lock(mutex_);
  closed_ = true;
  drain_scheduled_ = false;
  return std::move(pending_);
}

bool FramePacketMailbox::IsClosed() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return closed_;
}

}  // namespace flutter
