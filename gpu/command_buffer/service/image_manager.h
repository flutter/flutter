// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_IMAGE_MANAGER_H_
#define GPU_COMMAND_BUFFER_SERVICE_IMAGE_MANAGER_H_

#include "base/basictypes.h"
#include "base/containers/hash_tables.h"
#include "base/memory/ref_counted.h"
#include "gpu/gpu_export.h"

namespace gfx {
class GLImage;
}

namespace gpu {
namespace gles2 {

// This class keeps track of the images and their state.
class GPU_EXPORT ImageManager {
 public:
  ImageManager();
  ~ImageManager();

  void Destroy(bool have_context);
  void AddImage(gfx::GLImage* image, int32 service_id);
  void RemoveImage(int32 service_id);
  gfx::GLImage* LookupImage(int32 service_id);

 private:
  typedef base::hash_map<int32, scoped_refptr<gfx::GLImage> > GLImageMap;
  GLImageMap images_;

  DISALLOW_COPY_AND_ASSIGN(ImageManager);
};

}  // namespage gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_IMAGE_MANAGER_H_
