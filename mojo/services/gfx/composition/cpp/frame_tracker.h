// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_SERVICES_GFX_COMPOSITION_CPP_SCHEDULING_H_
#define MOJO_SERVICES_GFX_COMPOSITION_CPP_SCHEDULING_H_

#include "mojo/services/gfx/composition/interfaces/scheduling.mojom.h"

namespace mojo {
namespace gfx {
namespace composition {

// Tracks frame scheduling information.
class FrameTracker {
 public:
  FrameTracker();
  ~FrameTracker();

  // Returns the number of frames that have been tracked.
  uint64_t frame_count() const { return frame_count_; }

  // Returns the current frame info.
  // This value is not meaningful when |frame_count()| is zero.
  const mojo::gfx::composition::FrameInfo& frame_info() const {
    return frame_info_;
  }

  // Clears the frame tracker's state such that the next update will be
  // treated as if it were the first.
  void Clear();

  // Updates |frame_info()| with new frame scheduling information
  // from |raw_frame_info| and applies compensation for lag.
  //
  // |now| should come from a recent call to |mojo::GetTimeTicksNow()|.
  //
  // Whenever an application receives new frame scheduling information from the
  // system, it should call this function before using it.
  //
  // Returns the time delta between the previous frame and the current frame
  // in microseconds, or 0 if this is the first frame.
  uint64_t Update(const mojo::gfx::composition::FrameInfo& raw_frame_info,
                  MojoTimeTicks now);

 private:
  uint64_t frame_count_ = 0u;
  mojo::gfx::composition::FrameInfo frame_info_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(FrameTracker);
};

}  // namespace composition
}  // namespace gfx
}  // namespace mojo

#endif  // MOJO_SERVICES_GFX_COMPOSITION_CPP_SCHEDULING_H_
