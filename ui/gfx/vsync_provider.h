// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GFX_VSYNC_PROVIDER_H_
#define UI_GFX_VSYNC_PROVIDER_H_

#include "base/callback.h"
#include "base/time/time.h"
#include "ui/gfx/gfx_export.h"

namespace gfx {

class GFX_EXPORT VSyncProvider {
 public:
  virtual ~VSyncProvider() {}

  typedef base::Callback<
      void(const base::TimeTicks timebase, const base::TimeDelta interval)>
      UpdateVSyncCallback;

  // Get the time of the most recent screen refresh, along with the time
  // between consecutive refreshes. The callback is called as soon as
  // the data is available: it could be immediately from this method,
  // later via a PostTask to the current MessageLoop, or never (if we have
  // no data source). We provide the strong guarantee that the callback will
  // not be called once the instance of this class is destroyed.
  virtual void GetVSyncParameters(const UpdateVSyncCallback& callback) = 0;
};

}  // namespace gfx

#endif  // UI_GFX_VSYNC_PROVIDER_H_
