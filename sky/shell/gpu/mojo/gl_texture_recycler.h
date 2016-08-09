// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_GPU_GL_RENDERER_H_
#define SKY_SHELL_GPU_GL_RENDERER_H_

#include <deque>
#include <memory>

#include "base/memory/ref_counted.h"
#include "lib/ftl/functional/closure.h"
#include "lib/ftl/macros.h"
#include "lib/ftl/memory/weak_ptr.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/services/gfx/composition/interfaces/resources.mojom.h"

namespace mojo {
class GLContext;
class GLTexture;
class Size;
}  // namespace mojo

namespace sky {
namespace shell {

// Provides support for rendering GL commands into a pool of textures
// and producing scene resources for them.
// TODO(abarth): Move to //mojo/gpu and reconcile with mojo::ui::GLRenderer.
class GLTextureRecycler {
 public:
  GLTextureRecycler(scoped_refptr<mojo::GLContext> gl_context,
                    uint32_t max_recycled_textures = 3u);
  ~GLTextureRecycler();

  // Obtains a texture of the specified size.
  // Returns a nullptr if the GLContext was destroyed.
  std::unique_ptr<mojo::GLTexture> GetTexture(const mojo::Size& requested_size);

  // Takes ownership of the specified texture, issues GL commands to
  // produce a mailbox texture, and returns its resource pointer.
  // The caller should add the resource to its scene.
  // Returns a nullptr if the GLContext was destroyed.
  mojo::gfx::composition::ResourcePtr BindTextureResource(
      std::unique_ptr<mojo::GLTexture> texture);

 private:
  using GLRecycledTextureInfo =
      std::pair<std::unique_ptr<mojo::GLTexture>, uint32_t>;

  // TODO(jeffbrown): Avoid creating new callbacks each time, perhaps by
  // migrating to image pipes.
  class GLTextureReleaser : mojo::gfx::composition::MailboxTextureCallback {
   public:
    GLTextureReleaser(const ftl::WeakPtr<GLTextureRecycler>& provider,
                      GLRecycledTextureInfo info);
    ~GLTextureReleaser() override;

    mojo::gfx::composition::MailboxTextureCallbackPtr StrongBind();

   private:
    void OnMailboxTextureReleased() override;
    void Release(bool recyclable);

    ftl::WeakPtr<GLTextureRecycler> provider_;
    GLRecycledTextureInfo texture_info_;
    mojo::StrongBinding<mojo::gfx::composition::MailboxTextureCallback>
        binding_;
  };

  void ReleaseTexture(GLRecycledTextureInfo texture_info, bool recyclable);

  scoped_refptr<mojo::GLContext> gl_context_;
  const uint32_t max_recycled_textures_;

  std::deque<GLRecycledTextureInfo> recycled_textures_;
  uint32_t bound_textures_ = 0u;

  ftl::WeakPtrFactory<GLTextureRecycler> weak_factory_;

  FTL_DISALLOW_COPY_AND_ASSIGN(GLTextureRecycler);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_GPU_GL_RENDERER_H_
