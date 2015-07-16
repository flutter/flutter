// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/stream_texture_manager_in_process_android.h"

#include "base/bind.h"
#include "base/callback.h"
#include "gpu/command_buffer/service/texture_manager.h"
#include "ui/gfx/geometry/size.h"
#include "ui/gl/android/surface_texture.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_image.h"

namespace gpu {

namespace {

// Simply wraps a SurfaceTexture reference as a GLImage.
class GLImageImpl : public gfx::GLImage {
 public:
  GLImageImpl(const scoped_refptr<gfx::SurfaceTexture>& surface_texture,
              const base::Closure& release_callback);

  // implement gfx::GLImage
  void Destroy(bool have_context) override;
  gfx::Size GetSize() override;
  bool BindTexImage(unsigned target) override;
  void ReleaseTexImage(unsigned target) override;
  bool CopyTexImage(unsigned target) override;
  void WillUseTexImage() override;
  void DidUseTexImage() override {}
  void WillModifyTexImage() override {}
  void DidModifyTexImage() override {}
  bool ScheduleOverlayPlane(gfx::AcceleratedWidget widget,
                            int z_order,
                            gfx::OverlayTransform transform,
                            const gfx::Rect& bounds_rect,
                            const gfx::RectF& crop_rect) override;

 private:
  ~GLImageImpl() override;

  scoped_refptr<gfx::SurfaceTexture> surface_texture_;
  base::Closure release_callback_;

  DISALLOW_COPY_AND_ASSIGN(GLImageImpl);
};

GLImageImpl::GLImageImpl(
    const scoped_refptr<gfx::SurfaceTexture>& surface_texture,
    const base::Closure& release_callback)
    : surface_texture_(surface_texture), release_callback_(release_callback) {}

GLImageImpl::~GLImageImpl() {
  release_callback_.Run();
}

void GLImageImpl::Destroy(bool have_context) {
  NOTREACHED();
}

gfx::Size GLImageImpl::GetSize() {
  return gfx::Size();
}

bool GLImageImpl::BindTexImage(unsigned target) {
  NOTREACHED();
  return false;
}

void GLImageImpl::ReleaseTexImage(unsigned target) {
  NOTREACHED();
}

bool GLImageImpl::CopyTexImage(unsigned target) {
  return false;
}

void GLImageImpl::WillUseTexImage() {
  surface_texture_->UpdateTexImage();
}

bool GLImageImpl::ScheduleOverlayPlane(gfx::AcceleratedWidget widget,
                                       int z_order,
                                       gfx::OverlayTransform transform,
                                       const gfx::Rect& bounds_rect,
                                       const gfx::RectF& crop_rect) {
  NOTREACHED();
  return false;
}

}  // anonymous namespace

StreamTextureManagerInProcess::StreamTextureManagerInProcess()
    : next_id_(1), weak_factory_(this) {}

StreamTextureManagerInProcess::~StreamTextureManagerInProcess() {
  if (!textures_.empty()) {
    LOG(WARNING) << "Undestroyed surface textures while tearing down "
                    "StreamTextureManager.";
  }
}

GLuint StreamTextureManagerInProcess::CreateStreamTexture(
    uint32 client_texture_id,
    gles2::TextureManager* texture_manager) {
  CalledOnValidThread();

  gles2::TextureRef* texture = texture_manager->GetTexture(client_texture_id);

  if (!texture || (texture->texture()->target() &&
                   texture->texture()->target() != GL_TEXTURE_EXTERNAL_OES)) {
    return 0;
  }

  scoped_refptr<gfx::SurfaceTexture> surface_texture(
      gfx::SurfaceTexture::Create(texture->service_id()));

  uint32 stream_id = next_id_++;
  base::Closure release_callback =
      base::Bind(&StreamTextureManagerInProcess::OnReleaseStreamTexture,
                 weak_factory_.GetWeakPtr(), stream_id);
  scoped_refptr<gfx::GLImage> gl_image(new GLImageImpl(surface_texture,
                                       release_callback));

  gfx::Size size = gl_image->GetSize();
  texture_manager->SetTarget(texture, GL_TEXTURE_EXTERNAL_OES);
  texture_manager->SetLevelInfo(texture,
                                GL_TEXTURE_EXTERNAL_OES,
                                0,
                                GL_RGBA,
                                size.width(),
                                size.height(),
                                1,
                                0,
                                GL_RGBA,
                                GL_UNSIGNED_BYTE,
                                true);
  texture_manager->SetLevelImage(
      texture, GL_TEXTURE_EXTERNAL_OES, 0, gl_image.get());

  {
    base::AutoLock lock(map_lock_);
    textures_[stream_id] = surface_texture;
  }

  if (next_id_ == 0)
    next_id_++;

  return stream_id;
}

void StreamTextureManagerInProcess::OnReleaseStreamTexture(uint32 stream_id) {
  CalledOnValidThread();
  base::AutoLock lock(map_lock_);
  textures_.erase(stream_id);
}

// This can get called from any thread.
scoped_refptr<gfx::SurfaceTexture>
StreamTextureManagerInProcess::GetSurfaceTexture(uint32 stream_id) {
  base::AutoLock lock(map_lock_);
  TextureMap::const_iterator it = textures_.find(stream_id);
  if (it != textures_.end())
    return it->second;

  return NULL;
}

}  // namespace gpu
