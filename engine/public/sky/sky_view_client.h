// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_PUBLIC_SKY_SKY_VIEW_CLIENT_H_
#define SKY_ENGINE_PUBLIC_SKY_SKY_VIEW_CLIENT_H_

namespace blink {

class SkyViewClient {
 public:
  virtual void SchedulePaint() = 0;

 protected:
  virtual ~SkyViewClient();
};

} // namespace blink

#endif  // SKY_ENGINE_PUBLIC_SKY_SKY_VIEW_CLIENT_H_
