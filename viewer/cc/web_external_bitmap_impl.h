// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_VIEWER_CC_WEB_EXTERNAL_BITMAP_IMPL_H_
#define SKY_VIEWER_CC_WEB_EXTERNAL_BITMAP_IMPL_H_

#include "base/bind.h"
#include "base/memory/scoped_ptr.h"
#include "sky/viewer/cc/sky_viewer_cc_export.h"
#include "sky/engine/public/platform/WebExternalBitmap.h"

namespace base {
class SharedMemory;
}

namespace sky_viewer_cc {

typedef scoped_ptr<base::SharedMemory>(*SharedMemoryAllocationFunction)(size_t);

// Sets the function that this will use to allocate shared memory.
SKY_VIEWER_CC_EXPORT void SetSharedMemoryAllocationFunction(
    SharedMemoryAllocationFunction);

class WebExternalBitmapImpl : public blink::WebExternalBitmap {
 public:
  SKY_VIEWER_CC_EXPORT explicit WebExternalBitmapImpl();
  virtual ~WebExternalBitmapImpl();

  // blink::WebExternalBitmap implementation.
  virtual blink::WebSize size() override;
  virtual void setSize(blink::WebSize size) override;
  virtual uint8* pixels() override;

  base::SharedMemory* shared_memory() { return shared_memory_.get(); }

 private:
  scoped_ptr<base::SharedMemory> shared_memory_;
  blink::WebSize size_;

  DISALLOW_COPY_AND_ASSIGN(WebExternalBitmapImpl);
};

}  // namespace sky_viewer_cc

#endif  // SKY_VIEWER_CC_WEB_EXTERNAL_BITMAP_IMPL_H_
