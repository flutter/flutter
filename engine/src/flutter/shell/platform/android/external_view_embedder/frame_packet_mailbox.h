// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_FRAME_PACKET_MAILBOX_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_FRAME_PACKET_MAILBOX_H_

#include <cstddef>
#include <cstdint>
#include <memory>
#include <mutex>
#include <optional>
#include <type_traits>
#include <utility>
#include <vector>

#include "flutter/display_list/geometry/dl_geometry_types.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/external_view_embedder/image_layer_pool.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"

namespace flutter {

//------------------------------------------------------------------------------
/// Move-only RAII wrapper pairing an acquired `Image` (`HybridJavaGlobalRef`)
/// with the `HybridReaderHandle` that produced it.
///
/// If |TakeImage()| is called (for example when handing the image to Java on
/// the platform thread), ownership transfers to Java. Otherwise, when an
/// |AcquiredHybridImage| is destroyed (packet superseded in the mailbox,
/// cold-start abort, `hc_epoch` mismatch, `Teardown()`, or embedder
/// destruction), `~AcquiredHybridImage()` automatically calls
/// `reader_handle_->ReleaseImage(...)` before dropping `reader_handle_`.
///
class AcquiredHybridImage final {
 public:
  AcquiredHybridImage() noexcept = default;

  AcquiredHybridImage(std::shared_ptr<HybridReaderHandle> reader_handle,
                      HybridJavaGlobalRef image) noexcept;

  ~AcquiredHybridImage();

  AcquiredHybridImage(const AcquiredHybridImage&) = delete;
  AcquiredHybridImage& operator=(const AcquiredHybridImage&) = delete;

  AcquiredHybridImage(AcquiredHybridImage&& other) noexcept;
  AcquiredHybridImage& operator=(AcquiredHybridImage&& other) noexcept;

  void Reset() noexcept;

  bool is_valid() const noexcept { return static_cast<bool>(image_); }
  explicit operator bool() const noexcept { return is_valid(); }

  const HybridJavaGlobalRef& reader() const noexcept;

  // Transfers ownership of the underlying move-only |HybridJavaGlobalRef|
  // `Image` to the caller (leaving `reader_handle_` intact until this wrapper
  // goes out of scope).
  HybridJavaGlobalRef TakeImage() noexcept { return std::move(image_); }

 private:
  std::shared_ptr<HybridReaderHandle> reader_handle_;
  HybridJavaGlobalRef image_;
};

static_assert(!std::is_copy_constructible_v<AcquiredHybridImage>);
static_assert(!std::is_copy_assignable_v<AcquiredHybridImage>);
static_assert(std::is_nothrow_move_constructible_v<AcquiredHybridImage>);
static_assert(std::is_nothrow_move_assignable_v<AcquiredHybridImage>);

//------------------------------------------------------------------------------
/// Overlay slice image and tight physical bounds paired with a platform view in
/// |FramePacket|.
///
struct OverlaySlicePacket {
  OverlaySlicePacket(int surface_id,
                     DlIRect bounds,
                     AcquiredHybridImage image) noexcept;

  ~OverlaySlicePacket() = default;

  OverlaySlicePacket(const OverlaySlicePacket&) = delete;
  OverlaySlicePacket& operator=(const OverlaySlicePacket&) = delete;
  OverlaySlicePacket(OverlaySlicePacket&&) noexcept = default;
  OverlaySlicePacket& operator=(OverlaySlicePacket&&) noexcept = default;

  int surface_id = 0;
  DlIRect bounds;
  AcquiredHybridImage image;
};

//------------------------------------------------------------------------------
/// Per-platform-view geometry, mutator stack, and optional interleaved overlay
/// slice inside |FramePacket|, ordered in exact `composition_order_`.
///
struct PlatformViewPacketEntry {
  PlatformViewPacketEntry(int64_t view_id,
                          DlIRect bounds,
                          int32_t physical_width,
                          int32_t physical_height,
                          MutatorsStack mutators_stack,
                          std::optional<OverlaySlicePacket> overlay) noexcept;

  ~PlatformViewPacketEntry() = default;

  PlatformViewPacketEntry(const PlatformViewPacketEntry&) = delete;
  PlatformViewPacketEntry& operator=(const PlatformViewPacketEntry&) = delete;
  PlatformViewPacketEntry(PlatformViewPacketEntry&&) noexcept = default;
  PlatformViewPacketEntry& operator=(PlatformViewPacketEntry&&) noexcept =
      default;

  int64_t view_id = 0;
  DlIRect bounds;
  int32_t physical_width = 0;
  int32_t physical_height = 0;
  MutatorsStack mutators_stack;
  std::optional<OverlaySlicePacket> overlay;
};

//------------------------------------------------------------------------------
/// Immutable move-only packet produced on `1.raster` and applied atomically in
/// a single Android UI thread (`main`) Looper turn.
///
struct FramePacket {
  FramePacket() = default;
  ~FramePacket() = default;

  FramePacket(const FramePacket&) = delete;
  FramePacket& operator=(const FramePacket&) = delete;
  FramePacket(FramePacket&&) noexcept = default;
  FramePacket& operator=(FramePacket&&) noexcept = default;

  uint64_t hc_epoch = 0;
  size_t trace_flow_id = 0;
  bool is_exit_frame = false;
  bool remove_background_after_traversal = false;
  AcquiredHybridImage background_image;
  std::vector<PlatformViewPacketEntry> views;
};

static_assert(!std::is_copy_constructible_v<FramePacket>);
static_assert(!std::is_copy_assignable_v<FramePacket>);

//------------------------------------------------------------------------------
/// Thread-safe single-slot latest-wins mailbox transferring |FramePacket|s from
/// `1.raster` to `main` without blocking either thread.
///
/// `mutex_` guards pointer swaps and boolean flags only; callers MUST destroy
/// superseded or discarded |FramePacket|s outside `mutex_` so JNI
/// `ReleaseHybridImage` calls never execute while holding the lock.
///
class FramePacketMailbox final {
 public:
  FramePacketMailbox() = default;
  ~FramePacketMailbox();

  // Result of |Publish|. Any `superseded_packet` should be reset by the caller
  // outside the lock; `schedule_drain` is true iff the mailbox accepted the
  // packet and transitioned `drain_scheduled_` from false to true.
  struct PublishResult {
    std::unique_ptr<FramePacket> superseded_packet;
    bool accepted = false;
    bool schedule_drain = false;
  };

  PublishResult Publish(std::unique_ptr<FramePacket> packet);

  // Atomically takes the pending packet (if any) and clears `drain_scheduled_`
  // so a subsequent |Publish| schedules a fresh drain task.
  std::unique_ptr<FramePacket> Take();

  // Used by `Teardown()`: swaps out any pending packet and resets
  // `drain_scheduled_ = false` while keeping the mailbox open (`closed_ ==
  // false`) for subsequent sessions across `Activity.onStop()`/`onStart()`,
  // view re-attachment, or Hot Restart.
  std::unique_ptr<FramePacket> ResetAndTake();

  // Used strictly by `~AndroidExternalViewEmbedder()`: permanently closes the
  // mailbox (`closed_ = true`), clears `drain_scheduled_`, and returns any
  // pending packet for immediate release.
  std::unique_ptr<FramePacket> CloseAndTake();

  bool IsClosed() const;

 private:
  mutable std::mutex mutex_;
  std::unique_ptr<FramePacket> pending_;
  bool drain_scheduled_ = false;
  bool closed_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(FramePacketMailbox);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_FRAME_PACKET_MAILBOX_H_
