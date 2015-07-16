// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_SYNC_CONTROL_VSYNC_PROVIDER_H_
#define UI_GL_SYNC_CONTROL_VSYNC_PROVIDER_H_

#include <queue>

#include "ui/gfx/vsync_provider.h"

namespace gfx {

// Base class for providers based on extensions like GLX_OML_sync_control and
// EGL_CHROMIUM_sync_control.
class SyncControlVSyncProvider : public VSyncProvider {
 public:
  SyncControlVSyncProvider();
  ~SyncControlVSyncProvider() override;

  void GetVSyncParameters(const UpdateVSyncCallback& callback) override;

 protected:
  virtual bool GetSyncValues(int64* system_time,
                             int64* media_stream_counter,
                             int64* swap_buffer_counter) = 0;

  virtual bool GetMscRate(int32* numerator, int32* denominator) = 0;

 private:
  base::TimeTicks last_timebase_;
  uint64 last_media_stream_counter_;
  base::TimeDelta last_good_interval_;
  bool invalid_msc_;

  // A short history of the last few computed intervals.
  // We use this to filter out the noise in the computation resulting
  // from configuration change (monitor reconfiguration, moving windows
  // between monitors, suspend and resume, etc.).
  std::queue<base::TimeDelta> last_computed_intervals_;

  DISALLOW_COPY_AND_ASSIGN(SyncControlVSyncProvider);
};

}  // namespace gfx

#endif  // UI_GL_SYNC_CONTROL_VSYNC_PROVIDER_H_
