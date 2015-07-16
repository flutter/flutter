// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_IMAGE_H_
#define UI_GL_GL_IMAGE_H_

#include "base/memory/ref_counted.h"
#include "ui/gfx/geometry/rect.h"
#include "ui/gfx/geometry/rect_f.h"
#include "ui/gfx/geometry/size.h"
#include "ui/gfx/native_widget_types.h"
#include "ui/gfx/overlay_transform.h"
#include "ui/gl/gl_export.h"

namespace gfx {

// Encapsulates an image that can be bound to a texture, hiding platform
// specific management.
class GL_EXPORT GLImage : public base::RefCounted<GLImage> {
 public:
  GLImage() {}

  // Destroys the image.
  virtual void Destroy(bool have_context) = 0;

  // Get the size of the image.
  virtual gfx::Size GetSize() = 0;

  // Bind image to texture currently bound to |target|.
  virtual bool BindTexImage(unsigned target) = 0;

  // Release image from texture currently bound to |target|.
  virtual void ReleaseTexImage(unsigned target) = 0;

  // Copy image to texture currently bound to |target|.
  virtual bool CopyTexImage(unsigned target) = 0;

  // Called before the texture is used for drawing.
  virtual void WillUseTexImage() = 0;

  // Called after the texture has been used for drawing.
  virtual void DidUseTexImage() = 0;

  // Called before the texture image data will be modified.
  virtual void WillModifyTexImage() = 0;

  // Called after the texture image data has been modified.
  virtual void DidModifyTexImage() = 0;

  // Schedule image as an overlay plane to be shown at swap time for |widget|.
  virtual bool ScheduleOverlayPlane(gfx::AcceleratedWidget widget,
                                    int z_order,
                                    OverlayTransform transform,
                                    const Rect& bounds_rect,
                                    const RectF& crop_rect) = 0;

 protected:
  virtual ~GLImage() {}

 private:
  friend class base::RefCounted<GLImage>;

  DISALLOW_COPY_AND_ASSIGN(GLImage);
};

}  // namespace gfx

#endif  // UI_GL_GL_IMAGE_H_
