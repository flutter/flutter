// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_STREAM_TEXTURE_MANAGER_IN_PROCESS_ANDROID_H_
#define GPU_STREAM_TEXTURE_MANAGER_IN_PROCESS_ANDROID_H_

#include <map>

#include "base/memory/ref_counted.h"
#include "base/memory/weak_ptr.h"
#include "base/synchronization/lock.h"
#include "base/threading/non_thread_safe.h"

namespace gfx {
class SurfaceTexture;
}

namespace gpu {

namespace gles2 {
class TextureManager;
}

class StreamTextureManagerInProcess : public base::NonThreadSafe {
 public:
  StreamTextureManagerInProcess();
  ~StreamTextureManagerInProcess();

  uint32 CreateStreamTexture(uint32 client_texture_id,
                             gles2::TextureManager* texture_manager);

  // This method can be called from any thread.
  scoped_refptr<gfx::SurfaceTexture> GetSurfaceTexture(uint32 stream_id);

 private:
  void OnReleaseStreamTexture(uint32 stream_id);

  typedef std::map<uint32, scoped_refptr<gfx::SurfaceTexture> > TextureMap;
  TextureMap textures_;
  base::Lock map_lock_;
  uint32 next_id_;

  base::WeakPtrFactory<StreamTextureManagerInProcess> weak_factory_;
  DISALLOW_COPY_AND_ASSIGN(StreamTextureManagerInProcess);
};

}  // gpu

#endif  // GPU_STREAM_TEXTURE_MANAGER_IN_PROCESS_ANDROID_H_
